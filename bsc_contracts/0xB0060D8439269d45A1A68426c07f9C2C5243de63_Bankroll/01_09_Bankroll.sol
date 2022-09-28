// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BankrollShare is IERC20, Ownable {
	using SafeERC20 for IERC20;

	string public symbol = "";
	string public name = "";
	IERC20 public immutable token;
	uint8 public immutable decimals;
	uint256 public override totalSupply;
	uint256 private constant LOCK_TIME = 24 hours;

	struct UserBalances {
		uint256 balance;
		uint256 lockedUntil;
	}

	event WithdrawUnderlying(address indexed recipient, uint256 amount);
	/// @notice owner > balance mapping.
	mapping(address => UserBalances) public users;
	/// @notice owner > spender > allowance mapping.
	mapping(address => mapping(address => uint256)) public override allowance;

	constructor(
		address token_,
		string memory name_,
		string memory symbol_
	) public {
		token = IERC20(token_);
		name = name_;
		symbol = symbol_;
		decimals = IERC20Metadata(token_).decimals();
	}

	/* onlyOwner which is always the Bankroll Contract */
	function withdrawUnderlying(address recipient, uint256 amount)
		external
		onlyOwner
	{
		token.safeTransfer(recipient, amount);

		emit WithdrawUnderlying(recipient,amount);
	}


	function balanceOf(address user)
		external
		view
		override
		returns (uint256 balance)
	{
		return users[user].balance;
	}

	function lockedUntil(address user) external view returns (uint256 timestamp) {
		UserBalances memory fromUser = users[user];
		return fromUser.lockedUntil;
	}

	function _transfer(
		address from,
		address to,
		uint256 shares
	) internal {
		require(to != address(0), "To Zero address");
		require(from != address(0), "From Zero address");

		UserBalances memory fromUser = users[from];
		require(block.timestamp >= fromUser.lockedUntil, "Locked");

		if (shares != 0) {
			require(fromUser.balance >= shares, "Low balance");
			if (from != to) {
				UserBalances memory toUser = users[to];
				users[from].balance = fromUser.balance - shares;
				users[to].balance = toUser.balance + shares;
			}
		}
		emit Transfer(from, to, shares);
	}

	function _useAllowance(address from, uint256 shares) internal {
		if (_msgSender() == from) {
			return;
		}
		uint256 spenderAllowance = allowance[from][_msgSender()];
		// If allowance is infinite, don't decrease it to save on gas (breaks with EIP-20).
		if (spenderAllowance != type(uint256).max) {
			require(spenderAllowance >= shares, "Low allowance");
			allowance[from][_msgSender()] = spenderAllowance - shares; // Underflow is checked
		}

		
		emit Approval(_msgSender(), from, spenderAllowance - shares);
	}

	/// @notice Transfers `shares` tokens from `msg.sender` to `to`.
	/// @param to The address to move the tokens.
	/// @param shares of the tokens to move.
	/// @return (bool) Returns True if succeeded.
	function transfer(address to, uint256 shares)
		external
		override
		returns (bool)
	{
		_transfer(_msgSender(), to, shares);
		return true;
	}

	/// @notice Transfers `shares` tokens from `from` to `to`. Caller needs approval for `from`.
	/// @param from Address to draw tokens from.
	/// @param to The address to move the tokens.
	/// @param shares The token shares to move.
	/// @return (bool) Returns True if succeeded.
	function transferFrom(
		address from,
		address to,
		uint256 shares
	) external override returns (bool) {
		_useAllowance(from, shares);
		_transfer(from, to, shares);
		return true;
	}

	/// @notice Approves `amount` from sender to be spend by `spender`.
	/// @param spender Address of the party that can draw from msg.sender's account.
	/// @param amount The maximum collective amount that `spender` can draw.
	/// @return (bool) Returns True if approved.
	function approve(address spender, uint256 amount)
		external
		override
		returns (bool)
	{
		allowance[_msgSender()][spender] = amount;
		emit Approval(_msgSender(), spender, amount);
		return true;
	}

	function mint(address recipient, uint256 amount) external onlyOwner {
		require(recipient != address(0), "Zero address");
		UserBalances memory user = users[recipient];

		user.balance += amount;
		user.lockedUntil = (block.timestamp + LOCK_TIME);
		users[recipient] = user;
		totalSupply += amount;

		emit Transfer(address(0), recipient, amount);
	}

	function _burn(address from, uint256 amount) internal {
		require(from != address(0), "Zero address");
		UserBalances memory user = users[from];
		require(block.timestamp >= user.lockedUntil, "Locked");

		users[from].balance = user.balance - amount;
		totalSupply -= amount;

		emit Transfer(from, address(0), amount);
	}

	function burnFrom(address from, uint256 amount) external {
		_useAllowance(from, amount);
		_burn(from, amount);
	}
}

/*
	Bankroll has pools for each whitelisted token (whitelisted managed by owner,later timelock from multisig)
	Each pool emits tokens on deposit, which represent the share of the underlying asset (ETH pool emits brETH)
	Pool gets filled/empties based on game performance;
*/
contract Bankroll is Ownable, ReentrancyGuard {
	using SafeERC20 for IERC20;

	event Withdraw(
		address indexed user,
		address token,
		uint256 shares,
		uint256 receivedUnderlying
	);

	event Deposit(
		address indexed user,
		address token,
		uint256 amount,
		uint256 receivedShares
	);

	event ReserveDebt(address indexed game, address token, uint256 amount);

	event ClearDebt(address indexed game, address token, uint256 amount);

	event PayDebt(
		address indexed game,
		address indexed recipient,
		address token,
		uint256 amount
	);
	event MaxWinChanged(uint256 oldMax,uint256 newMax);
	event UpdateGameLimit(address indexed gameAddress,uint256 limit);
	event UpdateWhitelist(address indexed contractAddress, bool state);

	event AddPool(address indexed asset, address indexed poolToken);
	event RemovePool(address indexed asset, address indexed poolToken);


	event UpdateGuardian(address indexed guardianAddress, bool state);
	event EmergencyHaltGame(address indexed gameAddress);

	/* Tokens whitelisted */
	mapping(address => bool) public whitelistedTokens;

	/* Asset -> Share Pool */
	mapping(address => BankrollShare) public pools;
	/* Asset -> Debt Amount */
	mapping(address => uint256) public debtPools;

	uint256 public maxWin = 2500; // 25%;

	/* Guardian Roles */
	mapping(address => bool) public whitelistGuardians;

	/* Whitelisted contracts to request debt (games) */
	mapping(address => bool) public whitelistContracts;

	/* Keep track of the balance's the games withdraw */
	uint256 private immutable creationDate;
	
	/* game -> limit */
	mapping(address => uint256) public dailyGameLimits;
	/* game -> token -> day -> used amount */
	mapping(address => mapping(address => mapping(uint256 => uint256))) public dailyGameStats;

	constructor() {
		creationDate = block.timestamp;
	}
	
	/// @notice returns day index since contract deployment
	function getDay() public view returns (uint256) {
		if (block.timestamp < creationDate) return 0;
		uint256 delta = block.timestamp - creationDate;
		uint256 day = delta / 1 days;
		return day;
	}

	/// @notice check if a contract is whitelisted
	/// @param game game address
	/// @param token token address
	/// @param amount amount amount to withdraw
	/// @return bool true/false if is within limit
	function isWithinLimit(address game,address token,uint256 amount) private view returns (bool) {
		uint256 limit = dailyGameLimits[game];
		if (limit == 0) return true; /* In case of disabled limit */
		uint256 needed = dailyGameStats[game][token][getDay()] + amount;
		uint256 reserve_limit = reserves(token) * limit / 10000;
		if (needed <= reserve_limit) {
			return true;
		}
		return false;
	}


	/// @notice sets the newLimit percentage in bps. 10000 = 100%, 0 = disabled
	/// @param a game address
	/// @param newLimit new value to set it to
	function setDailyGameLimit(address a, uint256 newLimit) external onlyOwner {
		require(newLimit >= 0, "BR:invalid new limit, below 0");
		require(newLimit <= 10000, "BR:invalid new limit, exceeds 10000");

		dailyGameLimits[a] = newLimit;
		emit UpdateGameLimit(a,newLimit);
	}

	/* only guardians */
	modifier onlyGuardian() {
		require(
			whitelistGuardians[_msgSender()],
			"BR:Only Guardian Addresses can call this"
		);
		_;
	}

	/// @notice instantly disables a game
	/// @param game game to disable
	function emergencyHaltGame(address game) external onlyGuardian {
		require(game != address(0), "BR:emergencyHaltGame game address is 0");

		whitelistContracts[game] = false;
		emit EmergencyHaltGame(game);
	}

	/// @notice change guardian state for address
	/// @param user address to change
	/// @param to value to set
	function setGuardian(address user, bool to) external onlyOwner {
		whitelistGuardians[user] = to;
		emit UpdateGuardian(user, to);
	}


	/// @notice check if a contract is whitelisted
	/// @param check contract to check
	/// @return bool true/false if whitelisted
	function isWhitelisted(address check) public view returns (bool) {
		return whitelistContracts[check];
	}

	/* only games/trusted contracts */
	modifier onlyGames() {
		require(
			isWhitelisted(_msgSender()),
			"BR:Only Whitelisted Games can call this"
		);
		_;
	}

	/// @notice set contract whitelist state
	/// @param a contract to update
	/// @param to value to set
	function setWhitelist(address a, bool to) external onlyOwner {
		whitelistContracts[a] = to;

		/* Set default limit for new games */
		dailyGameLimits[a] = 1500; // 15%

		emit UpdateWhitelist(a, to);
	}


	/// @notice sets the maxWin percentage in bps. 10000 = 100%
	/// @param newMax new value to set it to
	function setMaxWin(uint256 newMax) external onlyOwner {
		require(newMax > 0, "BR:invalid new max win");
		require(newMax <= 10000, "BR:invalid new max win, exceeds 10000");


		emit MaxWinChanged(maxWin, newMax);
		maxWin = newMax;
	}

	/* only if there is a pool for the asset */
	modifier hasBankrollPool(address token) {
		require(hasPool(token), "BR:No Pool for Token");
		_;
	}

	/// @notice hasPool
	/// @param token token to check if there is a pool for
	/// @return bool true/false if there is a pool
	function hasPool(address token) public view returns (bool) {
		return whitelistedTokens[token];
	}

	/// @notice remove a bankroll pool, doesnt destroy the contract so emergencyWithdraw is still possible.
	/// @param token `token` pool to remove
	function removePool(address token) external onlyOwner {
		require(hasPool(token), "BR:pool does not exists");
		whitelistedTokens[token] = false;

		emit RemovePool(token, address(pools[token]));
	}

	/// @notice add a bankroll pool & whitelist it
	/// @param token creates a bankroll pool for `token`
	function addPool(address token) external onlyOwner {
		require(hasPool(token) == false, "BR:pool already exists");
		whitelistedTokens[token] = true;
		if (address(pools[token]) == address(0x0)) {
			pools[token] = new BankrollShare(
				token,
				string(abi.encodePacked("br", IERC20Metadata(token).symbol())),
				string(abi.encodePacked("br", IERC20Metadata(token).symbol()))
			);
		}

		emit AddPool(token, address(pools[token]));
	}

	/// @notice returns reserves of `token` in the bankroll pool
	/// @param token the non wrapped token
	/// @return reserves token balance of the contract
	function reserves(address token) public view returns (uint256) {
		//return IERC20(token).balanceOf(address(this));
		return IERC20(token).balanceOf(address(pools[token]));
	}

	/* Returns the users balance of a brToken (i.e a fetch with USDC token returns the brUSDC balance of user) */
	/// @notice get balance of the br`token` for `user`
	/// @param token the non wrapped token
	/// @param user user to check
	/// @return balance amount of brToken the user has
	function balanceOf(address token, address user)
		external
		view
		returns (uint256)
	{
		BankrollShare shareToken = pools[token];
		return shareToken.balanceOf(user);
	}


	/// @notice withdraw `token` and `shares` from a bankroll pool
	/// @param token the target token
	/// @param shares brShares to withdraw
	function _withdraw(IERC20 token, uint256 shares)
		private
	{
		BankrollShare shareToken = pools[address(token)];
		require(shares > 0, "BR:shares == 0");

		require(
			shareToken.balanceOf(_msgSender()) >= shares,
			"BR:insufficent balance"
		);

		uint256 amount = (shares * reserves(address(token))) /
			shareToken.totalSupply();

		if (amount >= reserves(address(token))) {
			amount = reserves(address(token));
		}

		require(
			(reserves(address(token)) - amount) >= debtPools[address(token)],
			"BR: remaining reserves less than debt"
		);

		shareToken.burnFrom(_msgSender(), shares);
		shareToken.withdrawUnderlying(_msgSender(), amount);

		emit Withdraw(_msgSender(), address(token), shares, amount);
	}


	/// @notice emergency withdraw whole br`token` balance from a bankroll pool
	/// @param token the target token
	function emergencyWithdraw(IERC20 token) external nonReentrant {
		BankrollShare shareToken = pools[address(token)];
		uint256 poolBalance = shareToken.balanceOf(_msgSender());
		require(poolBalance > 0, "BR:invalid amount");

		_withdraw(token, poolBalance);
	}

	/// @notice withdraw
	/// @param token the target token
	/// @param shares amount of shares to withdraw
	function withdraw(IERC20 token,uint256 shares) external hasBankrollPool(address(token)) nonReentrant {
		_withdraw(token, shares);
	}

	/// @notice deposit `token` and `amount` into a bankroll pool
	/// @param token the target token
	/// @param amount amount to deposit
	function deposit(IERC20 token, uint256 amount)
		external
		hasBankrollPool(address(token))
		nonReentrant
	{
		BankrollShare shareToken = pools[address(token)];

		require(amount > 0, "BR:amount == 0");
		require(token.balanceOf(_msgSender()) >= amount, "insufficient balance");

		/* Calculate ratio to mint brTokens in */
		uint256 totalSupply = shareToken.totalSupply();
		uint256 shares = totalSupply == 0
			? amount
			: (amount * totalSupply) / reserves(address(token));


		/* Send to Pool Contract */
		token.safeTransferFrom(_msgSender(), address(shareToken), amount);
		/* Mint brToken */
		shareToken.mint(_msgSender(), shares);

		emit Deposit(_msgSender(), address(token), amount, shares);
	}

	/// @notice get the max amount of a pool that can be won.
	/// @param token the target token
	/// @return maxWin maximum winnable
	function getMaxWin(address token) public view returns (uint256) {
		return (reserves(token) * maxWin) / 10000;
	}

	/// @notice clear `token` `amount` debt
	/// @param token the target token
	/// @param amount amount to remove from the debtPool
	function clearDebt(address token, uint256 amount)
		external
		hasBankrollPool(token)
		onlyGames
	{
		require(debtPools[token] >= amount, "BR:debt is smaller then amount");

		debtPools[token] -= amount;

		emit ClearDebt(_msgSender(), token, amount);
	}

	/// @notice pays reserved `token` `amount` to `recipient`.
	/// @param recipient recipient
	/// @param token the target token
	/// @param amount amount that needs to be sent
	function payDebt(
		address recipient,
		address token,
		uint256 amount
	) external 
		onlyGames 
		hasBankrollPool(token) 
	{
		require(debtPools[token] >= amount, "BR:debt pool lt amount");
		require(reserves(token) >= amount, "BR:reserve lt amount");

		/* Check if the amount is within the game's limit */
		require(isWithinLimit(_msgSender(),token,amount), "BR:amount outside of daily limit");
		dailyGameStats[_msgSender()][token][getDay()] += amount;

		debtPools[token] -= amount;
		pools[token].withdrawUnderlying(recipient, amount);

		emit PayDebt(_msgSender(), recipient, token, amount);
	}

	/// @notice Reserves `token` `amount` for a game.
	/// @param token the target token
	/// @param amount Amount the bankroll needs to reserve in case of a win for the user
	function reserveDebt(
		address token, 
		uint256 amount
	) external
		onlyGames
		hasBankrollPool(token)
	{
		require(getMaxWin(token) >= amount, "BR:amount exceeds maxWin");

		require(
			reserves(token) >= debtPools[token] + amount,
			"BR:reserve lt debt + amount"
		);

		debtPools[token] += amount;
		emit ReserveDebt(_msgSender(), token, amount);
	}
}