pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./tools/DomainAware.sol";
import "./interface/ITreasury.sol";
import "./interface/IVault.sol";

import "hardhat/console.sol";

contract wTBTPoolV2Permission is
	DomainAware,
	AccessControlUpgradeable,
	ERC20Upgradeable,
	PausableUpgradeable,
	ReentrancyGuardUpgradeable
{
	using SafeMathUpgradeable for uint256;
	using SafeERC20Upgradeable for IERC20Upgradeable;

	bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
	bytes32 public constant POOL_MANAGER_ROLE = keccak256("POOL_MANAGER_ROLE");
	bytes32 public constant APR_MANAGER_ROLE = keccak256("APR_MANAGER_ROLE");

	// It's used to calculate the interest base.
	uint256 public constant APR_COEFFICIENT = 10 ** 8;
	// Used to calculate the fee base.
	uint256 public constant FEE_COEFFICIENT = 10 ** 8;

	// This token's decimals is 18, USDC's decimals is 6, so the INITIAL_CTOKEN_TO_UNDERLYING is 10**(18-6)
	uint256 public INITIAL_CTOKEN_TO_UNDERLYING;

	mapping(address => uint256) public cTokenBalances;

	uint256 public cTokenTotalSupply;
	uint256 public totalUnderlying;
	uint256 public lastCheckpoint;
	uint256 public capitalLowerBound;
	IERC20Upgradeable public underlyingToken;
	// Vault, used to pay USDC to user when redeem cToken and manager fee.
	IVault public vault;
	// Treasury, used to receive USDC from user when mint cToken.
	ITreasury public treasury;
	// Fee Collector, used to receive fee when mint or redeem.
	address public feeCollector;
	// Manager fee collector, used to receive manager fee.
	address public managementFeeCollector;

	// redeemFeeRate: 0.1% => 100000 (10 ** 5)
	// redeemFeeRate: 10% => 10000000 (10 ** 7)
	// redeemFeeRate: 100% => 100000000 (10 ** 8)
	// It's used when call redeemUnderlyingToken method.
	uint256 public redeemFeeRate;
	uint256 public redeemMPFeeRate;

	// mintFeeRate: 0.1% => 100000 (10 ** 5)
	// mintFeeRate: 10% => 10000000 (10 ** 7)
	// mintFeeRate: 100% => 100000000 (10 ** 8)
	// It's used when call mint method.
	uint256 public mintFeeRate;
	uint256 public mintInterestCostFeeRate;

	// It's used when call realizeReward.
	uint256 public managementFeeRate;

	// Pending redeems, value is the USDC amount, user can claim whenever the vault has enough USDC.
	mapping(address => uint256) public pendingRedeems;

	// TODO: Can omit this, and calculate it from event.
	uint256 public totalPendingRedeems;
	// the claimable manager fee for protocol
	uint256 public totalUnclaimManagementFee;

	// targetAPR: 0.1% => 100000 (10 ** 5)
	// targetAPR: 10% => 10000000 (10 ** 7)
	// targetAPR: 100% => 100000000 (10 ** 8)
	uint256 public targetAPR;

	uint256 public maxAPR;

	// Max fee rates can't over then 1%
	uint256 public constant maxMintFeeRate = 10 ** 6;
	uint256 public constant maxRedeemFeeRate = 10 ** 6;

	// redeem index.
	uint256 public redeemIndex;
	// the time for redeem from bill.
	uint256 public processPeriod;

	struct RedeemDetail {
		uint256 id;
		uint256 timestamp;
		address user;
		uint256 underlyingAmount;
		uint256 redeemAmountAfterFee;
		uint256 MPFee;
		uint256 protocolFee;
		// False not redeem, or True.
		bool isDone;
	}

	// Mapping from redeem index to RedeemDetail.
	mapping(uint256 => RedeemDetail) public redeemDetails;

	event RedeemRequested(
		uint256 id,
		uint256 timestamp,
		address indexed user,
		uint256 cTokenAmount,
		uint256 underlyingAmount,
		uint256 redeemAmountAfterFee,
		uint256 MPFee,
		uint256 protocolFee
	);

	event RedeemUnderlyingToken(address indexed user, uint256 amount, uint256 fee, uint256 id);
	event FlashRedeem(address indexed user, int128 j, uint256 amount);

	// Treasury: When user mint cToken, treasury will receive USDC.
	// Vault: When user redeem cToken, vault will pay USDC.
	// So should transfer money from treasury to vault, and let vault approve 10**70 to TBTPoolV2 Contract.
	function initialize(
		string memory name,
		string memory symbol,
		address admin,
		IERC20Upgradeable _underlyingToken,
		uint256 _capitalLowerBound,
		address _treasury,
		address _vault,
		address _feeCollector,
		address _managementFeeCollector
	) public initializer {
		__AccessControl_init();
		__ERC20_init(name, symbol);
		__Pausable_init();
		__ReentrancyGuard_init();
		__DomainAware_init();

		require(admin != address(0), "103");
		// TODO: revisit.
		_setupRole(DEFAULT_ADMIN_ROLE, admin);
		_setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
		_setRoleAdmin(POOL_MANAGER_ROLE, ADMIN_ROLE);
		_setRoleAdmin(APR_MANAGER_ROLE, ADMIN_ROLE);

		_setupRole(ADMIN_ROLE, admin);
		_setupRole(POOL_MANAGER_ROLE, admin);
		_setupRole(APR_MANAGER_ROLE, admin);

		underlyingToken = _underlyingToken;

		uint256 underlyingDecimals = ERC20(address(underlyingToken)).decimals();

		INITIAL_CTOKEN_TO_UNDERLYING = 10 ** (uint256(decimals() - underlyingDecimals));

		lastCheckpoint = block.timestamp;
		capitalLowerBound = _capitalLowerBound;

		require(_vault != address(0), "109");
		require(_treasury != address(0), "109");
		require(_feeCollector != address(0), "109");
		require(_managementFeeCollector != address(0), "109");

		vault = IVault(_vault);
		treasury = ITreasury(_treasury);
		feeCollector = _feeCollector;
		managementFeeCollector = _managementFeeCollector;

		// const, reduce risk for now.
		// It's 6%.
		maxAPR = 6 * 10 ** 6;

		// default 3 days
		processPeriod = 3 days;
	}

	/* -------------------------------------------------------------------------- */
	/*                                Admin Settings                               */
	/* -------------------------------------------------------------------------- */

	/**
	 * @dev to set the vault
	 * @param _vault the address of vault
	 */
	function setVault(address _vault) external onlyRole(ADMIN_ROLE) {
		require(_vault != address(0), "109");
		vault = IVault(_vault);
	}

	/**
	 * @dev to set the treasury
	 * @param _treasury the address of treasury
	 */
	function setTreasury(address _treasury) external onlyRole(ADMIN_ROLE) {
		require(_treasury != address(0), "109");
		treasury = ITreasury(_treasury);
	}

	/**
	 * @dev to set the collector of fee
	 * @param _feeCollector the address of collector
	 */
	function setFeeCollector(address _feeCollector) external onlyRole(ADMIN_ROLE) {
		require(_feeCollector != address(0), "109");
		feeCollector = _feeCollector;
	}

	/**
	 * @dev to set the collector of manager fee
	 * @param _managementFeeCollector the address of manager collector
	 */
	function setManagementFeeCollector(address _managementFeeCollector) external onlyRole(ADMIN_ROLE) {
		require(_managementFeeCollector != address(0), "109");
		managementFeeCollector = _managementFeeCollector;
	}

	/* -------------------------------------------------------------------------- */
	/*                                Pool Settings                               */
	/* -------------------------------------------------------------------------- */

	// Pause the contract. Revert if already paused.
	function pause() external onlyRole(POOL_MANAGER_ROLE) {
		PausableUpgradeable._pause();
	}

	// Unpause the contract. Revert if already unpaused.
	function unpause() external onlyRole(POOL_MANAGER_ROLE) {
		PausableUpgradeable._unpause();
	}

	/**
	 * @dev to set APR
	 * @param _targetAPR the amount of APR. it should be multiply 10**6
	 */
	function setTargetAPR(uint256 _targetAPR) external onlyRole(APR_MANAGER_ROLE) realizeReward {
		require(_targetAPR <= maxAPR, "target apr should be less than max apr");
		targetAPR = _targetAPR;
	}

	/**
	 * @dev to set the period of processing
	 * @param _processPeriod the period of processing. it's second.
	 */
	function setProcessPeriod(uint256 _processPeriod) external onlyRole(POOL_MANAGER_ROLE) {
		processPeriod = _processPeriod;
	}

	/**
	 * @dev to set the capital lower bound
	 * @param _capitalLowerBound the capital lower bound. If lower bound is $1m USDC, the value should be 1,000,000 * 10**6
	 */
	function setCapitalLowerBound(uint256 _capitalLowerBound) external onlyRole(POOL_MANAGER_ROLE) {
		capitalLowerBound = _capitalLowerBound;
	}

	/**
	 * @dev to set the rate of mint fee
	 * @param _mintFeeRate the rate. it should be multiply 10**6
	 */
	function setMintFeeRate(uint256 _mintFeeRate) external onlyRole(POOL_MANAGER_ROLE) {
		require(_mintFeeRate <= maxMintFeeRate, "Mint fee rate should be less than 1%");
		mintFeeRate = _mintFeeRate;
	}

	/**
	 * @dev to set the rate of interest cost mint fee
	 * @param _mintInterestCostFeeRate the rate. it should be multiply 10**6
	 */
	function setMintInterestCostFeeRate(uint256 _mintInterestCostFeeRate) external onlyRole(POOL_MANAGER_ROLE) {
		require(_mintInterestCostFeeRate <= maxMintFeeRate, "Mint fee rate should be less than 1%");
		mintInterestCostFeeRate = _mintInterestCostFeeRate;
	}

	/**
	 * @dev to set the rate of redeem fee
	 * @param _redeemFeeRate the rate. it should be multiply 10**6
	 */
	function setRedeemFeeRate(uint256 _redeemFeeRate) external onlyRole(POOL_MANAGER_ROLE) {
		require(_redeemFeeRate <= maxRedeemFeeRate, "redeem fee rate should be less than 1%");
		redeemFeeRate = _redeemFeeRate;
	}

	/**
	 * @dev to set the rate of MP redeem fee
	 * @param _redeemMPFeeRate the rate. it should be multiply 10**6
	 */
	function setRedeemMPFeeRate(uint256 _redeemMPFeeRate) external onlyRole(POOL_MANAGER_ROLE) {
		require(_redeemMPFeeRate <= maxRedeemFeeRate, "redeem fee rate should be less than 1%");
		redeemMPFeeRate = _redeemMPFeeRate;
	}

	/**
	 * @dev to set the rate of manager fee
	 * @param _managementFeeRate the rate. it should be multiply 10**6
	 */
	function setManagementFeeRate(
		uint256 _managementFeeRate
	) external onlyRole(POOL_MANAGER_ROLE) realizeReward {
		require(_managementFeeRate <= FEE_COEFFICIENT, "manager fee rate should be less than 100%");
		managementFeeRate = _managementFeeRate;
	}

	/* -------------------------- End of Pool Settings -------------------------- */

	/* -------------------------------------------------------------------------- */
	/*                                   Getters                                  */
	/* -------------------------------------------------------------------------- */

	/**
	 * @dev get total underly token amount
	 */
	function getTotalUnderlying() public view returns (uint256) {
		// need include manager fee
		uint256 totalInterest = getRPS().mul(block.timestamp.sub(lastCheckpoint));
		uint256 managerIncome = totalInterest.mul(managementFeeRate).div(FEE_COEFFICIENT);
		return totalUnderlying.add(totalInterest).sub(managerIncome);
	}
	
	/**
	 * @dev get pending manager fee
	 */
	function getPendingManagementFee() public view returns (uint256) {
		// need include manager fee
		uint256 totalInterest = getRPS().mul(block.timestamp.sub(lastCheckpoint));
		return totalInterest.mul(managementFeeRate).div(FEE_COEFFICIENT);
	}

	/**
	 * @dev get amount of cToken by underlying
	 * @param _underlyingAmount the amount of underlying
	 */
	function getCTokenByUnderlying(uint256 _underlyingAmount) public view returns (uint256) {
		if (cTokenTotalSupply == 0) {
			return 0;
		} else {
			return _underlyingAmount.mul(cTokenTotalSupply).div(getTotalUnderlying());
		}
	}

	/**
	 * @dev get amount of underlying by cToken
	 * @param _cTokenAmount the amount of cToken
	 */
	function getUnderlyingByCToken(uint256 _cTokenAmount) public view returns (uint256) {
		if (cTokenTotalSupply == 0) {
			return 0;
		} else {
			return _cTokenAmount.mul(getTotalUnderlying()).div(cTokenTotalSupply);
		}
	}

	/**
	 * @dev get the multiplier of inital
	 */
	function getInitalCtokenToUnderlying() public view returns (uint256) {
		return INITIAL_CTOKEN_TO_UNDERLYING;
	}

	/**
	 * @dev the exchange rate of cToken
	 */
	function pricePerToken() external view returns (uint256) {
		return getUnderlyingByCToken(1 ether);
	}

	/**
	 * @dev revolutions per second
	 */
	function getRPS() public view returns (uint256) {
		// TODO: If use totalUnderlying, then the interest also incurs interest, do we want to switch to principal?
		return targetAPR.mul(totalUnderlying).div(365 days).div(APR_COEFFICIENT);
	}

	/**
	 * @dev get the pending redeem from a give address
	 * @param account target address
	 */
	function getPendingRedeem(address account) public view returns (uint256) {
		return pendingRedeems[account];
	}

	/**
	 * @dev get the amount of flash redeem from a give amount of wtbt
	 * @param amount amount of cToken
	 * @param j token of index for curve pool
	 */
	function getFlashRedeemAmountOut(uint256 amount, int128 j) public view returns (uint256) {
		uint256 underlyingAmount = amount.mul(getTotalUnderlying()).div(cTokenTotalSupply);
		return treasury.getRedeemAmountOutFromCurve(underlyingAmount, j);
	}

	/* ----------------------------- End of Getters ----------------------------- */

	/* -------------------------------------------------------------------------- */
	/*                                 Core Logic                                 */
	/* -------------------------------------------------------------------------- */

	modifier realizeReward() {
		if (cTokenTotalSupply != 0) {
			uint256 totalInterest = getRPS().mul(block.timestamp.sub(lastCheckpoint));
			uint256 managerIncome = totalInterest.mul(managementFeeRate).div(FEE_COEFFICIENT);
			totalUnderlying = totalUnderlying.add(totalInterest).sub(managerIncome);
			totalUnclaimManagementFee = totalUnclaimManagementFee.add(managerIncome);
		}
		lastCheckpoint = block.timestamp;
		_;
	}

	/**
	 * @dev claim protocol's manager fee
	 */
	function claimManagementFee() external realizeReward nonReentrant onlyRole(POOL_MANAGER_ROLE) {
		treasury.claimManagementFee(managementFeeCollector, totalUnclaimManagementFee);
		totalUnclaimManagementFee = 0;
	}

	/**
	 * @dev mint wTBT
	 * @param amount the amount of underlying token, 1 USDC = 10**6
	 */
	function mint(uint256 amount) external {
		_mintFor(amount, msg.sender);
	}

	/**
	 * @dev mint wTBT
	 * @param amount the amount of underlying token, 1 USDC = 10**6
	 * @param receiver the address be used to receive tbt
	 */
	function mintFor(uint256 amount, address receiver) external {
		_mintFor(amount, receiver);
	}

	/**
	 * @dev mint wTBT
	 * @param amount the amount of underlying token, 1 USDC = 10**6
	 * @param receiver the address be used to receive tbt
	 */
	function _mintFor(
		uint256 amount,
		address receiver
	) internal whenNotPaused realizeReward nonReentrant {
		underlyingToken.safeTransferFrom(msg.sender, address(treasury), amount);
		treasury.mintSTBT();

		// Prepaid fees while waiting for STBT
		uint256 interestCost = amount.mul(mintInterestCostFeeRate).div(FEE_COEFFICIENT);
		amount = amount.sub(interestCost);

		uint256 cTokenAmount;
		if (cTokenTotalSupply == 0 || totalUnderlying == 0) {
			cTokenAmount = amount.mul(INITIAL_CTOKEN_TO_UNDERLYING);
		} else {
			cTokenAmount = amount.mul(cTokenTotalSupply).div(totalUnderlying);
		}

		// calculate fee with wtbt
		uint256 feeAmount = cTokenAmount.mul(mintFeeRate).div(FEE_COEFFICIENT);
		uint256 amountAfterFee = cTokenAmount.sub(feeAmount);

		_mint(receiver, amountAfterFee);

		if (feeAmount != 0) {
			_mint(feeCollector, feeAmount);
		}

		totalUnderlying = totalUnderlying.add(amount);
	}

	/**
	 * @dev redeem wTBT
	 * @param amount the amount of cToken, 1 cToken = 10**18, which eaquals to 1 USDC (if not interest).
	 */
	function redeem(uint256 amount) external whenNotPaused realizeReward nonReentrant {
		require(amount <= cTokenBalances[msg.sender], "100");
		require(totalUnderlying >= 0, "101");
		require(cTokenTotalSupply > 0, "104");

		uint256 underlyingAmount = amount.mul(totalUnderlying).div(cTokenTotalSupply);

		require(totalUnderlying.sub(underlyingAmount) >= capitalLowerBound, "102");

		_burn(msg.sender, amount);
		totalUnderlying = totalUnderlying.sub(underlyingAmount);

		treasury.redeemSTBT(underlyingAmount);

		uint256 redeemFeeAmount = underlyingAmount.mul(redeemFeeRate).div(FEE_COEFFICIENT);
		uint256 redeemMPFeeAmount = underlyingAmount.mul(redeemMPFeeRate).div(FEE_COEFFICIENT);
		uint256 amountAfterFee = underlyingAmount.sub(redeemFeeAmount).sub(redeemMPFeeAmount);

		redeemIndex++;
		redeemDetails[redeemIndex] = RedeemDetail({
			id: redeemIndex,
			timestamp: block.timestamp,
			user: msg.sender,
			underlyingAmount: underlyingAmount,
			redeemAmountAfterFee: amountAfterFee,
			MPFee: redeemMPFeeAmount,
			protocolFee: redeemFeeAmount,
			isDone: false
		});

		// Instead of transferring underlying token to user, we record the pending redeem amount.
		pendingRedeems[msg.sender] = pendingRedeems[msg.sender].add(amountAfterFee);

		totalPendingRedeems = totalPendingRedeems.add(amountAfterFee);

		emit RedeemRequested(redeemIndex, block.timestamp, msg.sender, amount, underlyingAmount, amountAfterFee, redeemMPFeeAmount, redeemFeeAmount);
	}

	/**
	 * @dev redeem wTBT by Curve
	 * @param amount the amount of cToken, 1 cToken = 10**18, which eaquals to 1 USDC (if not interest).
	 * @param j token of index for curve pool
	 * @param minReturn the minimum amount of return
	 */
	function flashRedeem(
		uint256 amount,
		int128 j,
		uint256 minReturn
	) external whenNotPaused realizeReward nonReentrant {
		require(amount <= cTokenBalances[msg.sender], "100");
		require(totalUnderlying >= 0, "101");
		require(cTokenTotalSupply > 0, "104");

		uint256 underlyingAmount = amount.mul(totalUnderlying).div(cTokenTotalSupply);

		require(totalUnderlying.sub(underlyingAmount) >= capitalLowerBound, "102");

		_burn(msg.sender, amount);
		totalUnderlying = totalUnderlying.sub(underlyingAmount);
		treasury.redeemSTBTByCurveWithFee(
			underlyingAmount,
			j,
			minReturn,
			msg.sender,
			redeemFeeRate,
			FEE_COEFFICIENT,
			feeCollector
		);

		emit FlashRedeem(msg.sender, j, underlyingAmount);
	}

	/**
	 * @dev redeem underlying token
	 * @param _id the id of redeem details
	 */
	function redeemUnderlyingTokenById(uint256 _id) external whenNotPaused nonReentrant {
		require(redeemDetails[_id].user == msg.sender, "105");
		require(redeemDetails[_id].isDone == false, "106");
		require(redeemDetails[_id].timestamp + processPeriod <= block.timestamp, "108");

		uint256 redeemAmountAfterFee = redeemDetails[_id].redeemAmountAfterFee;
		uint256 protocolFee = redeemDetails[_id].protocolFee;

		redeemDetails[_id].isDone = true;

		pendingRedeems[msg.sender] = pendingRedeems[msg.sender].sub(redeemAmountAfterFee);
		totalPendingRedeems = totalPendingRedeems.sub(redeemAmountAfterFee);

		// the MP fee had been charge.
		vault.withdrawToUser(msg.sender, redeemAmountAfterFee);
		vault.withdrawToUser(feeCollector, protocolFee);

		emit RedeemUnderlyingToken(msg.sender, redeemAmountAfterFee, protocolFee, _id);
	}

	/* ---------------------------- End of Core Logic --------------------------- */

	/* -------------------------------------------------------------------------- */
	/*                                Partial ERC20                               */
	/* -------------------------------------------------------------------------- */

	function decimals() public pure override returns (uint8) {
		return 18;
	}

	function totalSupply() public view override returns (uint256) {
		return cTokenTotalSupply;
	}

	function balanceOf(address _owner) public view override returns (uint256 balance) {
		return cTokenBalances[_owner];
	}

	function _transfer(address from, address to, uint256 amount) internal override {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");

		uint256 fromBalance = cTokenBalances[from];
		require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
		unchecked {
			cTokenBalances[from] = fromBalance - amount;
			// Overflow not possible: the sum of all balances is capped by totalSupply,
			// and the sum is preserved by decrementing then incrementing.
			cTokenBalances[to] += amount;
		}

		emit Transfer(from, to, amount);
	}

	function transfer(address to, uint256 amount) public override returns (bool) {
		address owner = _msgSender();
		_transfer(owner, to, amount);
		return true;
	}

	function allowance(address owner, address spender) public view override returns (uint256) {
		return super.allowance(owner, spender);
	}

	function approve(address spender, uint256 amount) public override returns (bool) {
		return super.approve(spender, amount);
	}

	function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
		address spender = _msgSender();
		_spendAllowance(from, spender, amount);
		_transfer(from, to, amount);
		return true;
	}

	function _burn(address account, uint256 amount) internal override {
		require(account != address(0), "ERC20: burn from the zero address");

		_beforeTokenTransfer(account, address(0), amount);

		uint256 accountBalance = cTokenBalances[account];
		require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
		unchecked {
			cTokenBalances[account] = accountBalance - amount;
			// Overflow not possible: amount <= accountBalance <= totalSupply.
			cTokenTotalSupply -= amount;
		}

		emit Transfer(account, address(0), amount);

		_afterTokenTransfer(account, address(0), amount);
	}

	function _mint(address account, uint256 amount) internal override {
		require(account != address(0), "ERC20: mint to the zero address");

		_beforeTokenTransfer(address(0), account, amount);

		cTokenTotalSupply += amount;
		unchecked {
			// Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
			cTokenBalances[account] += amount;
		}
		emit Transfer(address(0), account, amount);

		_afterTokenTransfer(address(0), account, amount);
	}

	/* -------------------------- End of Partial ERC20 -------------------------- */

	/* -------------------------------------------------------------------------- */
	/*                                Domain Aware                                */
	/* -------------------------------------------------------------------------- */

	function domainName() public view override returns (string memory) {
		return name();
	}

	function domainVersion() public view override returns (string memory) {
		return "1";
	}

	/* --------------------------- End of Domain Aware -------------------------- */
}