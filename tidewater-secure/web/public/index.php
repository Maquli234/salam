<?php
declare(strict_types=1);

// Application code lives outside the web root
define('APP_DIR', dirname(__DIR__) . '/app');
$routes = require APP_DIR . '/routes.php';

// Allow-list routing: user input is only ever used as an array key,
// never as part of a file path.
$key = $_GET['page'] ?? 'home';
if (!is_string($key) || !array_key_exists($key, $routes)) {
    http_response_code(404);
    $key  = '404';
    $file = '404.php';
} else {
    $file = $routes[$key]['file'];
}
$current = $key;

require APP_DIR . '/includes/header.php';
require APP_DIR . '/pages/' . $file;
require APP_DIR . '/includes/footer.php';
