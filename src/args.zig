const std = @import("std");

// filter options, I want to support domains like those used in Odoo and normal args like -l or --help
// operators: =, !=, !, >, <, >=, <=, |, &, like/ilike(contains), not like/not ilike, in/not in. Odoo has more but I am trying to finish this project
// Timestamp, pid, level, database, library, ip, body, http code, SQL queries, SQL time, Python time
// Probably won't do regex sry that sounds hard
//
// regular args include them all together like this -lfs 
// -l limit default will probably be 20 if not provided this is not a log viewer i'm not printing all these bitches
// -f filter implies you are gonna have a domain
// -h, --help help will list the args
// -s sort implies you will include something to sort by maybe ("asc", "python_time")?
// -e includes additonal lines like for tracebacks and things, normal log entires don't typically have extra lines
// 
// I think the verbose args -- will be for easier defaults for those who don't wanna write filters and what not
//
// --error Just prints the error logs
// --slow_sql Prints the 20 slowest sql logs
// --slow_python Prints the 20 slowest python logs
// --sql Prints 20 most sql queries
// --common Prints most common requests and how often they appeared in the logs (searches by body field)

pub const CommandLineArgs = struct {
    //lotta optionals
    args = ?[]const u8,
    verbose_arg = ?VerboseArgs,
    domain = ?Domain,
    sort_params = ?SortParams,

    pub fn init()
    
pub const VerboseArbgs = enum { error, slow_sql, slow_python, sql, common };


pub fn interpret_args(args_input: CommandLineArgs) !void {
    if (args_input.verbose_arg != null) {
        parse_verbose_arg(*args_input);
    } else {
        if (args_input.args != null) {
        parse_args(
        }
    }
}
    

pub fn parse_verbose_arg(args_input: *CommandLineArgs) {
}

pub fn parse_input(input: []const u8) CommandLineArgs {
}
