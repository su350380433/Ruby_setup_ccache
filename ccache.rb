#!/usr/bin/ruby
# coding: utf-8

require 'xcodeproj'

def setup_env
    if !system "which ccache >/dev/null"
      puts "ccache 未安装"
      
      if !system "which brew >/dev/null"
        puts "brew 未安装"
        return
      end
      if !system "brew install ccache"
        puts "ccache 安装失败，请手动安装"
        return
      end
      puts "ccache 已自动安装"
    end
    
    ENV['WORKSPACE'] = File.dirname(__FILE__)
    puts "ENV['WORKSPACE'] = #{ENV['WORKSPACE']}"
    Dir.chdir ENV['WORKSPACE'] do
        result = Dir['*.xcodeproj'].first
        ENV['XCODEPROJ'] = result
        
        result_xcworkspace = Dir['*.xcworkspace'].first
        ENV['XCWORKSPACE'] = result_xcworkspace
    end
    
    ENV["ccache_path"] = File.join(ENV['WORKSPACE'], "ccache")
    ENV["cc_path"] = File.join(ENV["ccache_path"], "ccache-clang")
    ENV["cxx_path"] = File.join(ENV["ccache_path"], "ccache-clang++")
    
    if !File.file?(ENV["cc_path"]) || !File.file?(ENV["cxx_path"])
        puts "ccache-clang/clang++ 文件不存在"
        return
    end
end

def get_main_project
    xcodeproj_path = File.join(ENV['WORKSPACE'], ENV['XCODEPROJ'])
    Xcodeproj::Project.open(xcodeproj_path)
end

def get_main_workspace
    xcworkspace_path = File.join(ENV['WORKSPACE'], ENV['XCWORKSPACE'])
end

def set_ccache_for_project(project, cc_path, cxx_path, enable_ccache)
  if !project || !cc_path || !cxx_path
    return
  end

  puts "enable #{File.basename(project.path)}..."
  
  project.build_configurations.each do |x|
     x.build_settings['CC'] = enable_ccache ? cc_path : ""
     x.build_settings['CXX'] = enable_ccache ? cxx_path : ""
     x.build_settings['CLANG_ENABLE_MODULES'] = enable_ccache ? false : true
  end
  project.save
end

def setup_ccache(enable_ccache)
    if enable_ccache
         puts "正在启用 ccache..."
     else
         puts "正在关闭 ccache..."
     end
    
    setup_env
    
    if ENV['WORKSPACE']
      path = get_main_workspace
      workspace = Xcodeproj::Workspace.new_from_xcworkspace(path)
      workspace.file_references.each do |ref|
        xcodeproj_path = File.join(ENV['WORKSPACE'], ref.path)
        project = Xcodeproj::Project.open(xcodeproj_path)
        set_ccache_for_project(
          project, ENV["cc_path"], ENV["cxx_path"], enable_ccache
        )
      end
    else
      set_ccache_for_project(get_main_project, ENV["cc_path"], ENV["cxx_path"], enable_ccache)
    end

end
#post install  钩子
post_install do |installer_representation|
    setup_ccache true
end
