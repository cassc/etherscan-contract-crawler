/**
 *Submitted for verification at Etherscan.io on 2020-11-10
*/

pragma solidity ^0.6.12;

interface Callable {
	function tokenCallback(address _from, uint256 _tokens, bytes calldata _data) external returns (bool);
}

interface Router {
	function WETH() external pure returns (address);
	function swapExactETHForTokens(uint256 _amountOutMin, address[] calldata _path, address _to, uint256 _deadline) external payable returns (uint256[] memory);
}

interface SURF {
	function balanceOf(address) external view returns (uint256);
	function transfer(address, uint256) external returns (bool);
	function transferFrom(address, address, uint256) external returns (bool);
}

contract WhirlpoolManager {

	uint256 constant private BOARD_DIVIDENDS_PERCENT = 10;

	struct Info {
		address whirlpool;
		address boardDividends;
		SURF surf;
		SURF3d s3d;
	}
	Info private info;

	constructor(address _surf, address _whirlpool, address _boardDividends) public {
		info.whirlpool = _whirlpool;
		info.boardDividends = _boardDividends;
		info.surf = SURF(_surf);
		info.s3d = SURF3d(msg.sender);
	}

	receive() external payable {}

	function deposit() external {
		uint256 _balance = address(this).balance;
		if (_balance > 0) {
			info.s3d.deposit{value: _balance}();
		}
	}

	function release() external {
		if (info.s3d.dividendsOf(address(this)) > 0) {
			info.s3d.withdraw();
		}
		uint256 _balance = info.surf.balanceOf(address(this));
		if (_balance > 0) {
			uint256 _boardDividends = _balance * BOARD_DIVIDENDS_PERCENT / 100;
			info.surf.transfer(info.boardDividends, _boardDividends); // Send 10% of divs to SURF Board holders
			info.surf.transfer(address(info.surf), _boardDividends); // Burn 10% of divs by sending them to the SURF token contract
			info.surf.transfer(info.whirlpool, _balance - _boardDividends - _boardDividends); // Send 80% of divs to the Whirlpool
		}
	}
}

contract SURF3d {

	uint256 constant private FLOAT_SCALAR = 2**64;
	uint256 constant private BUY_TAX = 15;
	uint256 constant private SELL_TAX = 15;
	uint256 constant private STARTING_PRICE = 1e17;
	uint256 constant private INCREMENT = 1e12;

	string constant public name = "SURF3d";
	string constant public symbol = "S3D";
	uint8 constant public decimals = 18;

	struct User {
		uint256 balance;
		mapping(address => uint256) allowance;
		int256 scaledPayout;
	}

	struct Info {
		uint256 totalSupply;
		mapping(address => User) users;
		uint256 scaledSurfPerToken;
		uint256 openingBlock;
		address whirlpool;
		address deployer;
		Router router;
		SURF surf;
	}
	Info private info;

	WhirlpoolManager public whirlpoolManager;


	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);
	event Buy(address indexed buyer, uint256 amountSpent, uint256 tokensReceived);
	event Sell(address indexed seller, uint256 tokensSpent, uint256 amountReceived);
	event Withdraw(address indexed user, uint256 amount);
	event Reinvest(address indexed user, uint256 amount);


	constructor(address _surf, address _whirlpool, address _boardDividends) public {
		info.router = Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
		info.surf = SURF(_surf);
		info.whirlpool = _whirlpool;
		info.deployer = msg.sender;
		whirlpoolManager = new WhirlpoolManager(_surf, _whirlpool, _boardDividends);
	}

	function setOpeningBlock(uint256 _openingBlock, uint256 _firstBuyAmount) external {
		require(info.openingBlock == 0 && msg.sender == info.deployer);
		require(_openingBlock >= block.number + 500);
		if (_firstBuyAmount > 0) {
			buyFor(_firstBuyAmount, address(whirlpoolManager));
		}
		info.openingBlock = _openingBlock;
	}

	receive() external payable {
		if (msg.sender == tx.origin) {
			deposit();
		}
	}

	function deposit() public payable returns (uint256) {
		return depositFor(msg.sender);
	}

	function depositFor(address _user) public payable returns (uint256) {
		require(msg.value > 0);
		return _deposit(msg.value, _user);
	}

	function buy(uint256 _amount) external returns (uint256) {
		return buyFor(_amount, msg.sender);
	}

	function buyFor(uint256 _amount, address _user) public returns (uint256) {
		require(_amount > 0);
		uint256 _balanceBefore = info.surf.balanceOf(address(this));
		info.surf.transferFrom(msg.sender, address(this), _amount);
		uint256 _amountReceived = info.surf.balanceOf(address(this)) - _balanceBefore;
		return _buy(_amountReceived, _user);
	}

	function tokenCallback(address _from, uint256 _tokens, bytes calldata) external returns (bool) {
		require(msg.sender == address(info.surf));
		require(_tokens > 0);
		_buy(_tokens, _from);
		return true;
	}

	function sell(uint256 _tokens) external returns (uint256) {
		require(balanceOf(msg.sender) >= _tokens);
		return _sell(_tokens);
	}

	function withdraw() external returns (uint256) {
		uint256 _dividends = dividendsOf(msg.sender);
		require(_dividends > 0);
		info.users[msg.sender].scaledPayout += int256(_dividends * FLOAT_SCALAR);
		info.surf.transfer(msg.sender, _dividends);
		emit Withdraw(msg.sender, _dividends);
		return _dividends;
	}

	function reinvest() external returns (uint256) {
		uint256 _dividends = dividendsOf(msg.sender);
		require(_dividends > 0);
		info.users[msg.sender].scaledPayout += int256(_dividends * FLOAT_SCALAR);
		emit Reinvest(msg.sender, _dividends);
		return _buy(_dividends, msg.sender);
	}

	function transfer(address _to, uint256 _tokens) external returns (bool) {
		return _transfer(msg.sender, _to, _tokens);
	}

	function approve(address _spender, uint256 _tokens) external returns (bool) {
		info.users[msg.sender].allowance[_spender] = _tokens;
		emit Approval(msg.sender, _spender, _tokens);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool) {
		require(info.users[_from].allowance[msg.sender] >= _tokens);
		info.users[_from].allowance[msg.sender] -= _tokens;
		return _transfer(_from, _to, _tokens);
	}

	function transferAndCall(address _to, uint256 _tokens, bytes calldata _data) external returns (bool) {
		_transfer(msg.sender, _to, _tokens);
		uint32 _size;
		assembly {
			_size := extcodesize(_to)
		}
		if (_size > 0) {
			require(Callable(_to).tokenCallback(msg.sender, _tokens, _data));
		}
		return true;
	}


	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}

	function currentPrices() public view returns (uint256 truePrice, uint256 buyPrice, uint256 sellPrice) {
		truePrice = STARTING_PRICE + INCREMENT * totalSupply() / 1e18;
		buyPrice = truePrice * 100 / (100 - BUY_TAX);
		sellPrice = truePrice * (100 - SELL_TAX) / 100;
	}

	function balanceOf(address _user) public view returns (uint256) {
		return info.users[_user].balance;
	}

	function dividendsOf(address _user) public view returns (uint256) {
		return uint256(int256(info.scaledSurfPerToken * balanceOf(_user)) - info.users[_user].scaledPayout) / FLOAT_SCALAR;
	}

	function allInfoFor(address _user) external view returns (uint256 contractBalance, uint256 totalTokenSupply, uint256 truePrice, uint256 buyPrice, uint256 sellPrice, uint256 openingBlock, uint256 currentBlock, uint256 userETH, uint256 userSURF, uint256 userBalance, uint256 userDividends, uint256 userLiquidValue) {
		contractBalance = info.surf.balanceOf(address(this));
		totalTokenSupply = totalSupply();
		(truePrice, buyPrice, sellPrice) = currentPrices();
		openingBlock = info.openingBlock;
		currentBlock = block.number;
		userETH = _user.balance;
		userSURF = info.surf.balanceOf(_user);
		userBalance = balanceOf(_user);
		userDividends = dividendsOf(_user);
		userLiquidValue = calculateResult(userBalance, false, false) + userDividends;
	}

	function allowance(address _user, address _spender) external view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

	function calculateResult(uint256 _amount, bool _buy, bool _inverse) public view returns (uint256) {
		uint256 _buyPrice;
		uint256 _sellPrice;
		( , _buyPrice, _sellPrice) = currentPrices();
		uint256 _rate = (_buy ? _buyPrice : _sellPrice);
		uint256 _increment = INCREMENT * (_buy ? 100 : (100 - SELL_TAX)) / (_buy ? (100 - BUY_TAX) : 100);
		if ((_buy && !_inverse) || (!_buy && _inverse)) {
			if (_inverse) {
				return (2 * _rate - _sqrt(4 * _rate * _rate + _increment * _increment - 4 * _rate * _increment - 8 * _amount * _increment) - _increment) * 1e18 / (2 * _increment);
			} else {
				return (_sqrt((_increment + 2 * _rate) * (_increment + 2 * _rate) + 8 * _amount * _increment) - _increment - 2 * _rate) * 1e18 / (2 * _increment);
			}
		} else {
			if (_inverse) {
				return (_rate * _amount + (_increment * (_amount + 1e18) / 2e18) * _amount) / 1e18;
			} else {
				return (_rate * _amount - (_increment * (_amount + 1e18) / 2e18) * _amount) / 1e18;
			}
		}
	}


	function _transfer(address _from, address _to, uint256 _tokens) internal returns (bool) {
		require(info.users[_from].balance >= _tokens);
		info.users[_from].balance -= _tokens;
		info.users[_from].scaledPayout -= int256(_tokens * info.scaledSurfPerToken);
		info.users[_to].balance += _tokens;
		info.users[_to].scaledPayout += int256(_tokens * info.scaledSurfPerToken);
		emit Transfer(_from, _to, _tokens);
		return true;
	}

	function _deposit(uint256 _value, address _user) internal returns (uint256) {
		uint256 _balanceBefore = info.surf.balanceOf(address(this));
		address[] memory _poolPath = new address[](2);
		_poolPath[0] = info.router.WETH();
		_poolPath[1] = address(info.surf);
		info.router.swapExactETHForTokens{value: _value}(0, _poolPath, address(this), block.timestamp + 5 minutes);
		uint256 _amount = info.surf.balanceOf(address(this)) - _balanceBefore;
		return _buy(_amount, _user);
	}

	function _buy(uint256 _amount, address _user) internal returns (uint256 tokens) {
		require((info.openingBlock == 0 && msg.sender == info.deployer) || (info.openingBlock != 0 && block.number >= info.openingBlock));
		uint256 _tax = _amount * BUY_TAX / 100;
		tokens = calculateResult(_amount, true, false);
		info.totalSupply += tokens;
		info.users[_user].balance += tokens;
		info.users[_user].scaledPayout += int256(tokens * info.scaledSurfPerToken);
		info.scaledSurfPerToken += _tax * FLOAT_SCALAR / info.totalSupply;
		emit Transfer(address(0x0), _user, tokens);
		emit Buy(_user, _amount, tokens);
	}

	function _sell(uint256 _tokens) internal returns (uint256 amount) {
		require(info.users[msg.sender].balance >= _tokens);
		amount = calculateResult(_tokens, false, false);
		uint256 _tax = amount * SELL_TAX / (100 - SELL_TAX);
		info.totalSupply -= _tokens;
		info.users[msg.sender].balance -= _tokens;
		info.users[msg.sender].scaledPayout -= int256(_tokens * info.scaledSurfPerToken);
		info.scaledSurfPerToken += _tax * FLOAT_SCALAR / info.totalSupply;
		info.surf.transfer(msg.sender, amount);
		emit Transfer(msg.sender, address(0x0), _tokens);
		emit Sell(msg.sender, _tokens, amount);
	}

	function _sqrt(uint256 _n) internal pure returns (uint256 result) {
		uint256 _tmp = (_n + 1) / 2;
		result = _n;
		while (_tmp < result) {
			result = _tmp;
			_tmp = (_n / _tmp + _tmp) / 2;
		}
	}
}