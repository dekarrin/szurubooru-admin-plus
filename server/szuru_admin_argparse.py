import argparse
import sys
import os

def parse_args(parser_class=argparse.ArgumentParser):
    parser_top = parser_class(
        description="Collection of CLI commands for an administrator to use",
        epilog="Look at README.md for more info",
    )

    subparsers = parser_top.add_subparsers(dest="subcommand", help="sub-command help")
    subparsers.required = True

    change_password_parser = subparsers.add_parser(
        "change-password",
        help="change the password of a user",
    )
    change_password_parser.add_argument(
        "username",
        metavar="<username>",
        help="the username or email of the user whose password to change",
    )

    subparsers.add_parser(
        "check-all-audio",
        help="check the audio flags of all posts, "
        "noting discrepancies, without modifying posts",
    )

    subparsers.add_parser(
        "reset-filenames",
        help="reset and rename the content and thumbnail "
        "filenames in case of a lost/changed secret key",
    )

    rename_tags_parser = subparsers.add_parser(
        'rename-tags',
        help="Rename tags with regular expressions.",
    )

    rename_tags_parser.add_argument(
        "pattern",
        help="the old tag pattern to match, as a regular expression. re.search() is used to detect matches, and re.sub() is used to replace them. All instances of the pattern will be replaced via substitution.",
    )
    rename_tags_parser.add_argument(
        "replacement",
        help="The replacement text for the matched tags. Use backslashes and numbers to refer to capture groups in the pattern.",
    )
    rename_tags_parser.add_argument(
        "--category",
        "-c",
        help="The category of tags to limit the renaming to. If not specified, all tags are considered candidates for renaming.",
    )
    rename_tags_parser.add_argument(
        "--preserve",
        "-p",
        action="store_true",
        help="Preserve the changed tag as an alias on the newly-named one.",
    )
    rename_tags_parser.add_argument(
        "--apply",
        "-a",
        action="store_true",
        help="Actually apply the changes. If not specified, only a simulation is run and no changes are made.",
    )
    rename_tags_parser.add_argument(
        '--verbose',
        '-v',
        action='store_true',
        help="Enable verbose output",
    )

    move_tags_parser = subparsers.add_parser(
        'move-tags',
        help="Move tags to a new category based on a search pattern.",
    )
    move_tags_parser.add_argument(
        "search",
        help="The search pattern to match tags against. re.search() is used to detect matches.",
    )
    move_tags_parser.add_argument(
        "new_category",
        help="The new category to move matching tags to",
    )
    move_tags_parser.add_argument(
        "--category",
        "-c",
        help="The category to move tags from. If not specified, all categories are considered.",
    )
    move_tags_parser.add_argument(
        "--apply",
        "-a",
        action="store_true",
        help="Actually apply the changes. If not specified, only a simulation is run and no changes are made.",
    )
    move_tags_parser.add_argument(
        '--verbose',
        '-v',
        action='store_true',
        help="Enable verbose output",
    )

    resync_parser = subparsers.add_parser(
        'resync',
        help="Reload a post's content from its file on disk.",
    )
    resync_parser.add_argument(
        "id",
        nargs='+',
        type=int,
        help="The ID(s) of the post(s) to resync."
    )
    resync_parser.add_argument(
        '--verbose',
        '-v',
        action='store_true',
        help='Enable verbose output',
    )

    tag_parser = subparsers.add_parser(
        'tag',
        help="Mass tag or untag posts matching a search pattern.",
        aliases=['mass-tag'],
    )
    tag_parser.add_argument(
        "search",
        help="The search expression to match posts against, in szurubooru tag-search syntax.",
    )
    tag_parser.add_argument(
        'tags',
        nargs='*',
        help="The tags to add or remove from matching posts.",
    )
    tag_parser.add_argument(
        "--delete",
        "-d",
        action="store_true",
        help="Remove the given tags from matching posts instead of adding them.",
    )
    tag_parser.add_argument(
        "--imply",
        "-i",
        action="store_true",
        help="Also add/remove all tags implied by the given tags.",
    )
    tag_parser.add_argument(
        "--category",
        "-c",
        help="The category that new tags are created in. If not specified, they are created in the default category.",
    )
    tag_parser.add_argument(
        '--apply',
        '-a',
        action='store_true',
        help="Actually apply the changes. If not specified, only a simulation is run and no changes are made.",
    )
    tag_parser.add_argument(
        '--verbose',
        '-v',
        action='store_true',
        help='Enable verbose output',
    )

    return parser_top.parse_args()


_preparse_help_exit_code = 3
_preparse_parse_exit_code = 2


class PreParser(argparse.ArgumentParser):
    """
    PreParser is a specialization of ArgumentParser that returns custom exit
    codes on exit conditions. If there is an error, _preparse_parse_exit_code is
    used (default 2), and if help output is requested, _preparse_help_exit_code
    is used (default 3).

    PreParser's constructor takes the same args as ArgumentParser and uses them
    as it does, with one exception: 'exit_on_error' is effectively always set to
    true regardless of what user passes in; PreParser ignores it and mutates it
    and the exit_on_error property for its own error handling.
    """
    def __init__(self, **kwargs):
        kwargs['exit_on_error'] = True
        super().__init__(**kwargs)
    
    def print_help(self, file=None):
        super().print_help(file)
        self.exit(_preparse_help_exit_code)

    def error(self, message):
        self.print_usage(sys.stderr)
        args = {'prog': self.prog, 'message': message}
        self.exit(_preparse_parse_exit_code, ('%(prog)s: error: %(message)s\n') % args)


def main() -> None:
    """
    Perform parsing of CLI options intended for the szuru-admin script, without
    performing any actual operations.

    Depending on the result of parsing, the exit code will be different. If help
    is shown, the value of envvar SZURU_PREPARSE_HELP_STATUS is returned (default 3).
    If a parse error occurs, the value of envvar SZURU_PREPARSE_ERROR_STATUS is
    returned (default 2).
    """
    global _preparse_help_exit_code, _preparse_parse_exit_code

    _preparse_help_exit_code = int(os.getenv('SZURU_PREPARSE_HELP_STATUS', str(_preparse_help_exit_code)))
    _preparse_parse_exit_code = int(os.getenv('SZURU_PREPARSE_ERROR_STATUS', str(_preparse_parse_exit_code)))

    # explicitly do not try to catch exceptions; if something goes wrong, we
    # want it to be shown exactly as it would in the real program.
    parse_args(PreParser)


if __name__ == "__main__":
    main()
