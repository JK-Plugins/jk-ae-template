// 1. placeholderから値を取得
let project_name = variable::get("project_name");
let plugin_name = variable::get("plugin_name");

// 2. .envファイルに書き込む文字列を準備
let content = format!("PROJECT_NAME={}\nPLUGIN_NAME={}\n", project_name, plugin_name);

// 3. .envファイルを新規作成して書き込む
// "w"モードで開くと、ファイルが存在すれば内容が上書きされる
let mut env_file = std::fs::open_file(".env", "w")?;

// 4. ファイルに内容を書き出す
std::io::write(env_file, &content);