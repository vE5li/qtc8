#functions {

    shego {

        generate_colors function() {
            set operating_system := system_name()
            if operating_system == $"linux" || operating_system == $"ios" {
                set &root:colors := ${ black "\e[30m" red "\e[31m" green "\e[32m" yellow "\e[33m" blue "\e[34m" magenta "\e[35m" cyan "\e[36m" white "\e[37m" none "\e[0m" }
            } else {
                set &root:colors := ${ black "" red "" green "" yellow "" blue "" magenta "" cyan "" white "" none "" }
            }
        }

        process_arguments function(command_lookup, arguments) {
            set configuration := ${}
            set count := length(arguments)
            set index := $1
            set set := $[]

            iterate command_lookup as key, entry {
                set configuration := insert(configuration, key, entry:default)
            }

            while index <= count {
                set argument := arguments[index]
                set found := $!false

                iterate command_lookup as key, entry {
                    if argument == entry:flag || argument == entry:long {
                        if entry:once && ?contains(set, key) {
                            error(key ~ $" flag may only be set once")
                        }

                        if ?string(entry:default) {
                            ensure(count > index, key ~ $" flag expected argument")
                            set index := index + $1
                            set configuration := overwrite(configuration, key, arguments[index])
                        } else {
                            set inverted := not(entry:default)
                            set configuration := overwrite(configuration, key, inverted)
                        }

                        set set := append(set, key)
                        set index := index + $1
                        set found := $!true
                        break
                    }
                }

                if not(found) {
                    print_line($"invalid flag " ~ argument)
                    set configuration:help := $!true
                    break
                }
            }

            iterate command_lookup as key, entry {
                if ?not_contains(set, key) {
                    set value := environment(entry:environment)

                    if value != $#none {
                        if ?string(entry:default) {
                            set configuration := overwrite(configuration, key, value)
                        } else {
                            set boolean := call($shego:boolean_from_string, value, entry:environment)
                            set configuration := overwrite(configuration, key, boolean)
                        }
                    }
                }
            }

            iterate command_lookup as key, entry {
                if ?string(entry:default) {
                    if entry:default:-1 == $'/' {
                        set directory := call($shego:append_separator, configuration[key], $'/')
                        set configuration := overwrite(configuration, key, directory)
                    }
                }
            }

            return configuration
        }

        boolean_from_string function(value, variable) {
            if value == $"true" || value == $"TRUE" {
                return $!true
            } else value == $"false" || value == $"FALSE" {
                return $!false
            } else {
                error($"invalid value \"" ~ value ~ $"\" for environment variable " ~ variable ~ $"; valid values are \"true\", \"TRUE\", \"false\"and \"FALSE\"")
            }
        }

        append_separator function(source, separator) {
            if source:-1 == separator {
                return source
            }
            return source ~ separator
        }

        tag function(color: string, content) {
            return $"[ " ~ color ~ content ~ &root:colors:none ~ $" ]"
        }

        instance_info function(instance) {
            set type := type(instance)
            set data := serialize(instance)
            return &root:colors:cyan ~ type ~ $' ' ~ &root:colors:blue ~ data ~ &root:colors:none
        }

        print_color function(color: string, sender, [messages]) {
            set tag := call($shego:tag, color, sender)
            set parameters := push(messages, $' ', tag)
            invoke($#print_line, parameters)
        }

        print_debug function([messages]) {
            if &root:debug {
                set parameters := push(messages, $"debug", &root:colors:magenta)
                call_list($shego:print_color, parameters)
            }
        }

        print_pass function(pass: literal, [messages]) {
            set tag := call($shego:tag, &root:colors:magenta, pass)
            set parameters := push(messages, $' ', tag)
            call_list($shego:print_debug, parameters)
        }

        print_error function([messages]) {
            set parameters := push(messages, $"error", &root:colors:red)
            call_list($shego:print_color, parameters)
        }

        print_warning function([messages]) {
            set parameters := push(messages, $"warning", &root:colors:yellow)
            call_list($shego:print_color, parameters)
        }

        print_success function([messages]) {
            set parameters := push(messages, $"success", &root:colors:green)
            call_list($shego:print_color, parameters)
        }

        print_clean function([messages]) {
            set parameters := push(messages, $"clean", &root:colors:yellow)
            call_list($shego:print_color, parameters)
        }

        print_build function([messages]) {
            set parameters := push(messages, $"build", &root:colors:cyan)
            call_list($shego:print_color, parameters)
        }

        print_lucky function() {
            set color := &root:colors:magenta
            set length := length(&root:lucky)
            set choice := random($1, length)
            set message := &root:lucky[choice]

            set message := replace(message, $"{black}", &root:colors:black)
            set message := replace(message, $"{red}", &root:colors:red)
            set message := replace(message, $"{green}", &root:colors:green)
            set message := replace(message, $"{yellow}", &root:colors:yellow)
            set message := replace(message, $"{blue}", &root:colors:blue)
            set message := replace(message, $"{magenta}", &root:colors:magenta)
            set message := replace(message, $"{cyan}", &root:colors:cyan)
            set message := replace(message, $"{white}", &root:colors:white)
            set message := replace(message, $"{none}", &root:colors:none)

            call($shego:print_color, color, $"lucky", message)
        }

        base_directory function(path: string) {
            if ?not_contains(path, $'/') {
                return $""
            }

            set last_position := position(path, $'/')[$-1]
            set directory := slice(path, $1, last_position)
            return directory
        }

        write_create function(path: string, content) {

            if ?contains(path, $'/') {
                set last_position := position(path, $'/')[$-1]
                set directory := slice(path, $1, last_position)
                system($"bash", $"-c", $"mkdir -p " ~ directory)
            }

            system($"bash", $"-c", $"touch " ~ path)
            write_file(path, content)
        }
    }

    #tokenizer function(message, position) {
        @ print position
        set error_tag := call($shego:tag, &root:colors:red, $"error")
        print_line(error_tag ~ $' ' ~ message)
    }

    #tag function(tag, message) {

        if ?not_present(&root, $debug) {
            return message
        } else &root:debug != $!true {
            return message
        }

        if ?keyword(tag) {
            set tag := call($shego:tag, &root:colors:magenta, tag)
        } else {
            set tag := call($shego:tag, &root:colors:cyan, tag)
        }

        return tag ~ $' ' ~ message
    }

    #message function(message) {
        set tag := call($shego:tag, &root:colors:red, $"error")
        return tag ~ $' ' ~ message
    }

    #unregistered_character function(character) {
        return $"unregistered character " ~ character
    }
}

lucky [
    "it finally compiled, huh?"
    "{red}Exception in thread \"main\" java.lang.ArithmaticException: / by zero{none}"
    "42"
    "{yellow}R {red}A {magenta}I {blue}N {cyan}B {green}O {white}W{none}"
]
