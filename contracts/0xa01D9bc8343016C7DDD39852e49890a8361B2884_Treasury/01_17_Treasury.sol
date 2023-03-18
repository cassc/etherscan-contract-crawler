pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interface/ICurve.sol";
import "./interface/AggregatorInterface.sol";
import "./interface/IVault.sol";

contract Treasury is AccessControl {
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

	bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
	bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
	bytes32 public constant WTBTPOOL_ROLE = keccak256("WTBTPOOL_ROLE");

	// used to mint stbt
	address public mpMintPool;
	// used to redeem stbt
	address public mpRedeemPool;
	// vault address
	IVault public vault;
	// stbt address
	IERC20 public stbt;
	// underlying token address
	IERC20 public underlying;
	// STBT curve pool
	// Mainnet: 0x892D701d94a43bDBCB5eA28891DaCA2Fa22A690b
	ICurve curvePool;

	// mint threshold for underlying token
	uint256 public mintThreshold;
	// redeem threshold for STBT
	uint256 public redeemThreshold;
	// convert a amount from underlying token to stbt
	uint256 public basis;
	// target price
	int256 public targetPrice;
	// recovery fund wallet
	address public recovery;
	// priceFeed be using check USDC is pegged
	AggregatorInterface public priceFeed;
	// coins , [DAI, USDC, USDT]
	// see https://etherscan.io/address/0x892D701d94a43bDBCB5eA28891DaCA2Fa22A690b#code
	address[3] coins;

	constructor(
		address _admin,
		address _mpMintPool,
		address _mpRedeemPool,
		address _stbt,
		address _underlying,
		address _recovery,
		address _priceFeed,
		address[3] memory _coins
	) {
		require(_admin != address(0), "!_admin");
		_setupRole(DEFAULT_ADMIN_ROLE, _admin);
		_setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
		_setRoleAdmin(MANAGER_ROLE, ADMIN_ROLE);

		_setupRole(ADMIN_ROLE, _admin);
		_setupRole(MANAGER_ROLE, _admin);

		require(_mpMintPool != address(0), "!_mpMintPool");
		require(_mpRedeemPool != address(0), "!_mpRedeemPool");
		require(_stbt != address(0), "!_stbt");
		require(_underlying != address(0), "!_underlying");
		require(_recovery != address(0), "!_recovery");
		require(_priceFeed != address(0), "!_priceFeed");
		mpMintPool = _mpMintPool;
		mpRedeemPool = _mpRedeemPool;
		recovery = _recovery;
		stbt = IERC20(_stbt);
		underlying = IERC20(_underlying);
		priceFeed = AggregatorInterface(_priceFeed);

		uint256 underlyingDecimals = ERC20(_underlying).decimals();

		basis = 10 ** (uint256(ERC20(_stbt).decimals() - underlyingDecimals));
		coins = _coins;
	}

	/**
	 * @dev to set the vault address
	 * @param _vault the address of vault
	 */
	function setVault(address _vault) external onlyRole(ADMIN_ROLE) {
		require(_vault != address(0), "!_vault");
		vault = IVault(_vault);
	}

	/**
	 * @dev to set the mint pool
	 * @param _mintPool the address of mint pool
	 */
	function setMintPool(address _mintPool) external onlyRole(ADMIN_ROLE) {
		require(_mintPool != address(0), "!_mintPool");
		mpMintPool = _mintPool;
	}

	/**
	 * @dev to set the redeem pool
	 * @param _redeemPool the address of redeem pool
	 */
	function setRedeemPool(address _redeemPool) external onlyRole(ADMIN_ROLE) {
		require(_redeemPool != address(0), "!_redeemPool");
		mpRedeemPool = _redeemPool;
	}

	/**
	 * @dev to set the stbt curve pool
	 * @param _curvePool the address of curve pool
	 */
	function setCurvePool(address _curvePool) external onlyRole(ADMIN_ROLE) {
		require(_curvePool != address(0), "!_curvePool");
		curvePool = ICurve(_curvePool);
	}

	/**
	 * @dev to set the mint threshold
	 * @param amount the amount of mint threshold
	 */
	function setMintThreshold(uint256 amount) external onlyRole(MANAGER_ROLE) {
		mintThreshold = amount;
	}

	/**
	 * @dev to set the redeem threshold
	 * @param amount the amount of redeem threshold
	 */
	function setRedeemThreshold(uint256 amount) external onlyRole(MANAGER_ROLE) {
		redeemThreshold = amount;
	}

	/**
	 * @dev to set the price
	 * @param _targetPrice the target price of usdc
	 */
	function setPegPrice(int256 _targetPrice) external onlyRole(MANAGER_ROLE) {
		targetPrice = _targetPrice;
	}

	/**
	 * @dev convert underlying amount to stbt
	 */
	function getSTBTbyUnderlyingAmount(uint256 amount) public view returns (uint256) {
		return amount.mul(basis);
	}

	/**
	 * @dev get the exchange amount out from curve
	 * @param amount amount of cToken
	 * @param j token of index for curve pool
	 */
	function getRedeemAmountOutFromCurve(uint256 amount, int128 j) public view returns (uint256) {
		uint256 stbtAmount = amount.mul(basis);
		// From stbt to others
		return curvePool.get_dy_underlying(0, j, stbtAmount);
	}

	/// @notice get price feed answer
	/// @return The answer of price from priceFeed
	function latestAnswer() public view returns (int256) {
		return priceFeed.latestAnswer();
	}

	/**
	 * @dev if over than mint threshold, transfer all balance of underlying to mpMintPool
	 */
	function mintSTBT() external onlyRole(WTBTPOOL_ROLE) {
		require(priceFeed.latestAnswer() >= targetPrice, "depeg");
		uint256 balance = underlying.balanceOf(address(this));
		if (balance >= mintThreshold) {
			underlying.safeTransfer(mpMintPool, balance);
		}
	}

	/**
	 * @dev Transfer a give amout of stbt to matrixport's mint pool
	 * @param amount the amout of underlying token
	 */
	function redeemSTBT(uint256 amount) external onlyRole(WTBTPOOL_ROLE) {
		// convert to stbt amount
		uint256 stbtAmount = amount.mul(basis);
		require(priceFeed.latestAnswer() >= targetPrice, "depeg");
		require(stbtAmount >= redeemThreshold, "less than redeemThreshold");
		stbt.safeTransfer(address(vault), stbtAmount);
		vault.redeemSTBT(mpRedeemPool, stbtAmount);
	}

	/**
	 * @dev Transfer a give amout of stbt to matrixport's mint pool
	 * @param amount the amout of underlying token
	 * @param j token of index for curve pool
	 * @param minReturn the minimum amount of return
	 * @param receiver used to receive token
	 * @param feeRate redeem fee rate
	 * @param feeCoefficient redeem fee rate coefficient
	 * @param feeCollector fee collector
	 */
	function redeemSTBTByCurveWithFee(
		uint256 amount,
		int128 j,
		uint256 minReturn,
		address receiver,
		uint256 feeRate,
		uint256 feeCoefficient,
		address feeCollector
	) external onlyRole(WTBTPOOL_ROLE) {
		// convert to stbt amount
		uint256 stbtAmount = amount.mul(basis);
		// From stbt to others
		uint256 dy = curvePool.get_dy_underlying(0, j, stbtAmount);
		require(dy >= minReturn, "!minReturn");
		stbt.approve(address(curvePool), stbtAmount);
		curvePool.exchange_underlying(0, j, stbtAmount, dy);
		IERC20 targetToken = IERC20(coins[uint256(int256(j - 1))]);

		uint256 feeAmount = dy.mul(feeRate).div(feeCoefficient);
		uint256 amountAfterFee = dy.sub(feeAmount);
		targetToken.safeTransfer(receiver, amountAfterFee);
		targetToken.safeTransfer(feeCollector, feeAmount);
	}

	/**
	 * @dev Transfer all balance of stbt to matrixport's redeem pool
	 */
	function redeemAllSTBT() external onlyRole(WTBTPOOL_ROLE) {
		uint256 balance = stbt.balanceOf(address(this));
		require(balance >= redeemThreshold, "less than redeemThreshold");
		stbt.safeTransfer(mpRedeemPool, balance);
	}

	/**
	 * @dev claim manager fee with stbt
	 * @param target Used to receive
	 * @param amountToTarget Amount of underlying to transfer
	 */
	function claimManagementFee(
		address target,
		uint256 amountToTarget
	) external onlyRole(WTBTPOOL_ROLE) {
		uint256 stbtAmount = amountToTarget.mul(basis);
		stbt.safeTransfer(target, stbtAmount);
	}

	/**
	 * @dev Allows to recovery any ERC20 token
	 * @param tokenAddress Address of the token to recovery
	 * @param amountToRecover Amount of collateral to transfer
	 */
	function recoverERC20(
		address tokenAddress,
		uint256 amountToRecover
	) external onlyRole(ADMIN_ROLE) {
		IERC20(tokenAddress).safeTransfer(recovery, amountToRecover);
	}
}