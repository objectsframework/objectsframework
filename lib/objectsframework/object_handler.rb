module ObjectsFramework
  class ObjectHandler
    # DEPRACTED: do not override the ObjectHandler class anymore use object hooks
    # This event will never be used again
    def self.finished(klass,request,response,context)
      # Nothing
    end

    def self.run_methods(request,response,context)
      path = request.path
      parts = path.split("/")
      if(path == "/" && !context.config[:root].nil?)
        klass = Object.const_get(context.config[:root]).new

        Hooks.fire("object.before_execute", klass)

        klass.set_instance_variables(request,response).send(request.request_method.downcase!+"_"+context.config[:index_method])
        return
      end

      begin
        klass = Object.const_get(parts[1].capitalize).new.set_instance_variables(request,response)

        Hooks.fire("object.before_execute", klass)

        if(parts[3].nil?)
          if(path[path.length-1] == "/" || parts.length == 2)
            klass.send(request.request_method.downcase!+"_index");
          else
            klass.send(request.request_method.downcase!+"_"+parts[2])
          end
        else
          klass.send(request.request_method.downcase!+"_"+parts[2],*parts[3..parts.length])
        end
      rescue Exception => e
        begin
          obj = Object.const_get(context.config[:root]).new.set_instance_variables(request,response)
          Hooks.fire("object.before_execute", obj)
          obj.send(request.request_method.downcase!+"_"+parts[1])
          return
        rescue

        end
        response.status =  404
        notfound_response(response,e)
      end

    end

    def self.notfound_response(response,e)
      response.write "<h1>404 Not Found</h1><hr/><i>Ruby Rack Server powered by ObjectsFramework <br/><pre>#{e.to_s}</pre></i>"
    end
  end
end
