let project_name = variable::get("project_name");
let plugin_name = variable::get("plugin_name");
let content = format!("PROJECT_NAME={}\nPLUGIN_NAME={}\n", project_name, plugin_name);
let mut env_file = std::fs::open_file(".env", "w");
std::io::write(env_file, &content);