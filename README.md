# Unreal Engine CI/CD Tool for GitLab

Rudimentary GitLab CI/CD pipeline for Unreal Engine projects. It can fetch and revert commits from your GitLab repository / instance, build your project, package builds into .7z archives, and upload and publish them to your GitLab repository / instance.

**AI WAS HEAVILY USED TO MAKE THIS**

### Usage
Run `tool.ps1` and select the option you want to run.

### Options
- Run CI/CD -- Fetch latest changes from Git, build the project, archive into a .7z, and publish to GitLab.
- Build Project -- Build the Unreal project.
- Publish Latest Build -- Upload latest build to GitLab and publish as release.
- Pull Latest Commits -- Fetch changes from Git.
- Revert To Previous Commit -- Reverts project repo to the previous commit.
- Quit -- Quits the tool.

You can run every option in the tool directly from the command line without launching and making a selection manually, this is most useful in automated deployments:

- Run CI/CD -- `cicd`
- Build Project -- `build`
- Publish Latest Build -- `publish`
- Pull Latest Commits -- `pull`
- Revert To Previous Commit -- `revert`

(EX: `.\tool.ps1 revert build publish`)

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
| `PROJECT_NAME`     | Name of the Unreal Engine project (must match the name of the `.uproject` file for your project).                                                                             |
| `BUILD_DIRECTORY`  | Directory where builds should be output to.                                                                                                                                     |
| `REPO_DIRECTORY`   | Directory where the Git repository is stored.                                                                                                                                   |
| `UE_INSTALLATION`  | Directory where Unreal Engine is installed (EX: `C:\Program Files\Epic Games\UE_5.6`)                                                                                                                              |

### Contact
If you need help or encounter a problem, please make an issue or contact me on discord @dirkkane
