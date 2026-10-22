<section class="page narrow">
  <h1>Contact the support desk</h1>
  <?php if ($_SERVER['REQUEST_METHOD'] === 'POST'): ?>
    <p class="notice">Thanks. A support engineer will reply within one business day.</p>
  <?php else: ?>
  <form method="post" action="/index.php?page=contact">
    <label>Your name <input name="name" required></label>
    <label>Company <input name="company"></label>
    <label>How can we help? <textarea name="msg" rows="5" required></textarea></label>
    <button class="btn" type="submit">Send message</button>
  </form>
  <?php endif; ?>
</section>
