import argparse
import sys

class Parser(argparse.ArgumentParser):
    def print_help(self, file=None):
        super().print_help(file)
        self.exit(3434)


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
        help="the old tag pattern to match, as a regular expression. re.find() is used to detect matches, and re.sub() is used to replace them. All instances of the pattern will be replaced via substitution.",
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
        help="The search pattern to match tags against. re.find() is used to detect matches.",
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



def main() -> None:
    try:
        parse_args(Parser)
    except:
        sys.exit(2)


if __name__ == "__main__":
    main()
