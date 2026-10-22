<?php
$siteName = 'Tidewater IT Services';
?><!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title><?php echo htmlspecialchars($siteName, ENT_QUOTES, 'UTF-8'); ?></title>
<link rel="stylesheet" href="/assets/style.css">
</head>
<body>
<header class="top">
  <a class="brand" href="/index.php?page=home">Tidewater<span>IT</span></a>
  <nav>
    <?php foreach ($routes as $k => $r): if (!$r['nav']) { continue; } ?>
      <a href="/index.php?page=<?php echo htmlspecialchars($k, ENT_QUOTES, 'UTF-8'); ?>"<?php echo ($current === $k) ? ' aria-current="page"' : ''; ?>><?php echo htmlspecialchars($r['label'], ENT_QUOTES, 'UTF-8'); ?></a>
    <?php endforeach; ?>
  </nav>
</header>
<main>
