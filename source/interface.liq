#functions {

    #interface {

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
                            set boolean := call($#interface:boolean_from_string, value, entry:environment)
                            set configuration := overwrite(configuration, key, boolean)
                        }
                    }
                }
            }

            iterate command_lookup as key, entry {
                if ?string(entry:default) {
                    if entry:default:-1 == $'/' {
                        set directory := call($#interface:append_separator, configuration[key], $'/')
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
    }
}
