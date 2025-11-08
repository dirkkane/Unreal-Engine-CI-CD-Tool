# Unreal Engine CI/CD Tool for GitLab

Rudimentary GitLab CI/CD pipeline for Unreal Engine projects. It can fetch and revert commits from your GitLab repository / instance, build your project, package builds into .7z archives, and upload and publish them to your GitLab repository / instance.

Make sure you have a working editor for the project. Also double check the build command on line 5 of `build_game.bat` and make sure the paths to your Unreal Engine binaries are correct. (They're specific to my machine rn, generally they should be the same for most people but you never know.)
You may also want to replace line 5 in `build_game.bat` with your own build command if the one provided is not sufficient for your project.

I vibe coded the hell out of this tool so there's always the possibility for issues.

Eventually I want to rewrite this entire thing in Powershell Core or some other language so it'll be cross platform.

Special thanks to JeBobs for letting me use his tool Bullet as a base.

### Usage
Run `tool.bat` and select the option you want to run.

### Options
- Run CI/CD -- Fetch latest changes from Git, build the project, archive into a .7z, and publish to GitLab.
- Build Project -- Build the Unreal project.
- Pull Latest Commits -- Fetch changes from Git.
- Revert To Previous Commit -- Reverts project repo to the previous commit.
- Quit -- Quits the tool.

You can run every option in the tool directly from the command line without launching and making a selection manually, this is most useful in automated deployments:

- Run CI/CD -- `RunCI`
- Build Project -- `Build`
- Pull Latest Commits -- `PullChanges`
- Revert To Previous Commit -- `RevertCommit`
- Quit -- `Quit`

(EX: `tool.bat RevertCommit Build Quit`)

**If you want the tool to exit after running directly from command line, always add the `Quit` option at the end of your arguments to prevent it from landing back at the menu.**

### Dependencies
jq - Command line json parsing tool (must be added to path) <br/>
7zip - God's chosen file archiver

### .env Variables
Fill in the variables in .env with the corresponding values:
| Variable           | Description                                                                                                                                                                    |
|--------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `TOKEN`            | GitLab repo access token. Must have permission to access the API, push to the package registry, and create releases.                                                                                                                        |
| `TOKEN_USERNAME`   | Arbitrary username assigned to the token.                                                                                                                                       |
| `GITLAB_PRIVATE_IP`| The local network IP of the GitLab instance. If you are outside the network GitLab is hosted on or using gitlab.com, set this to the same as `GITLAB_PUBLIC_IP`. This option is just for faster uploads if you are on the same network.                                   |
| `GITLAB_PUBLIC_IP` | Public IP or hostname of the GitLab instance. If your GitLab instance has no publicly accessible domain or IP, set this to the same as `GITLAB_PRIVATE_IP`                                                                                                                                   |
| `GIT_GROUP_NAME`   | Name of the user or group that owns the GitLab project.                                                                                                                         |
| `GIT_PROJECT_ID`   | ID of the GitLab project.                                                                                                                                                       |
| `GIT_PROJECT_NAME` | Name of the GitLab project.                                                                                                                                                     |
| `PROJECT_NAME`     | Name of the Unreal Engine project (should match the name of the `.uproject` file for your project).                                                                             |
| `BUILD_DIRECTORY`  | Directory where builds should be output to.                                                                                                                                     |
| `REPO_DIRECTORY`   | Directory where the Git repository is stored.                                                                                                                                   |

### Contact
If you need help or encounter a problem, please make an issue or contact me on discord @dirkkane
