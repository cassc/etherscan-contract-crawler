// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;
import "./libraries/TransferHelper.sol";
import "./libraries/SafeMath.sol";
import "./modules/Configable.sol";
import "./modules/ConfigNames.sol";
import "./modules/BaseMintField.sol";
import "./libraries/Configurable.sol";

interface IONXStrategy {
	function invest(address user, uint256 amount) external;
	function withdraw(address user, uint256 amount) external;
	function liquidation(address user) external;
	function claim(address user, uint256 amount, uint256 total) external;
	function query() external view returns (uint256);
	function mint() external;
	function interestToken() external view returns (address);
	function farmToken() external view returns (address);
}

contract ONXPool is BaseMintField, Configurable {
	using SafeMath for uint256;

	address public factory;
	address public supplyToken;
	address public collateralToken;

	// SupplyStruct
	bytes32 constant _amountSupply_SS = "SS#amountSupply";
	bytes32 constant _interestSettled_SS = "SS#interestSettled";
	bytes32 constant _liquidationSettled_SS = "SS#liquidationSettled";
	bytes32 constant _interests_SS = "SS#interests";
	bytes32 constant _liquidation_SS = "SS#liquidation";

	// BorrowStruct
	bytes32 constant _index_BS = "BS#index";
	bytes32 constant _amountCollateral_BS = "BS#amountCollateral";
	bytes32 constant _interestSettled_BS = "BS#interestSettled";
	bytes32 constant _amountBorrow_BS = "BS#amountBorrow";
	bytes32 constant _interests_BS = "BS#interests";

	// LiquidationStruct
	bytes32 constant _amountCollateral_LS = "LS#amountCollateral";
	bytes32 constant _liquidationAmount_LS = "LS#liquidationAmount";
	bytes32 constant _timestamp_LS = "LS#timestamp";
	bytes32 constant _length_LS = "LS#length";

	address[] public borrowerList;
	uint256 public numberBorrowers;

	mapping(address => uint256) public liquidationHistoryLength;

	uint256 public interestPerSupply;
	uint256 public liquidationPerSupply;
	uint256 public interestPerBorrow;

	uint256 public totalLiquidation;
	uint256 public totalLiquidationSupplyAmount;

	uint256 public totalStake;
	uint256 public totalBorrow;
	uint256 public totalPledge;

	uint256 public remainSupply;

	uint256 public lastInterestUpdate;

	address public collateralStrategy;
	address public supplyStrategy;

	uint256 public payoutRatio;

	event Deposit(address indexed _user, uint256 _amount, uint256 _collateralAmount);
	event Withdraw(address indexed _user, uint256 _supplyAmount, uint256 _collateralAmount, uint256 _interestAmount);
	event Borrow(address indexed _user, uint256 _supplyAmount, uint256 _collateralAmount);
	event Repay(address indexed _user, uint256 _supplyAmount, uint256 _collateralAmount, uint256 _interestAmount);
	event Liquidation(
		address indexed _liquidator,
		address indexed _user,
		uint256 _supplyAmount,
		uint256 _collateralAmount
	);
	event Reinvest(address indexed _user, uint256 _reinvestAmount);

	function initialize(address _factory) external initializer
	{
		owner = _factory;
		factory = _factory;
	}

	function setCollateralStrategy(address _collateralStrategy, address _supplyStrategy) external onlyPlatform
	{
		collateralStrategy = _collateralStrategy;
		supplyStrategy = _supplyStrategy;
	}

	function init(address _supplyToken, address _collateralToken) external onlyFactory {
		supplyToken = _supplyToken;
		collateralToken = _collateralToken;

		lastInterestUpdate = block.number;
	}

	function updateInterests(bool isPayout) internal {
		uint256 totalSupply = totalBorrow + remainSupply;
		(uint256 supplyInterestPerBlock, uint256 borrowInterestPerBlock) = getInterests();

		interestPerSupply = interestPerSupply.add(
			totalSupply == 0
			? 0
			: supplyInterestPerBlock.mul(block.number - lastInterestUpdate).mul(totalBorrow).div(totalSupply)
		);
		interestPerBorrow = interestPerBorrow.add(borrowInterestPerBlock.mul(block.number - lastInterestUpdate));
		lastInterestUpdate = block.number;

		if (isPayout == true) {
			payoutRatio = borrowInterestPerBlock == 0
				? 0
				: (borrowInterestPerBlock.sub(supplyInterestPerBlock)).mul(1e18).div(borrowInterestPerBlock);
		}
	}

	function getInterests() public view returns (uint256 supplyInterestPerBlock, uint256 borrowInterestPerBlock) {
		uint256 totalSupply = totalBorrow + remainSupply;
		uint256 baseInterests = IConfig(config).getPoolValue(address(this), ConfigNames.POOL_BASE_INTERESTS);
		uint256 marketFrenzy = IConfig(config).getPoolValue(address(this), ConfigNames.POOL_MARKET_FRENZY);
		uint256 aDay = IConfig(config).DAY();
		borrowInterestPerBlock = totalSupply == 0
		? 0
		: baseInterests.add(totalBorrow.mul(marketFrenzy).div(totalSupply)).div(365 * aDay);

		if (supplyToken == IConfig(config).WETH()) {
			baseInterests = 0;
		}
		
		supplyInterestPerBlock = totalSupply == 0
		? 0
		: baseInterests.add(totalBorrow.mul(marketFrenzy).div(totalSupply)).div(365 * aDay);
	}

	function updateLiquidation(uint256 _liquidation) internal {
		uint256 totalSupply = totalBorrow + remainSupply;
		liquidationPerSupply = liquidationPerSupply.add(totalSupply == 0 ? 0 : _liquidation.mul(1e18).div(totalSupply));
	}

	function deposit(uint256 amountDeposit, address from) public onlyPlatform {
		require(amountDeposit > 0, "ONX: INVALID AMOUNT");
		uint256 amountIn = IERC20(supplyToken).balanceOf(address(this)).sub(remainSupply);
		require(amountIn >= amountDeposit, "ONX: INVALID AMOUNT");

		updateInterests(false);

		uint256 addLiquidation =
		liquidationPerSupply.mul(getConfig(_amountSupply_SS, from)).div(1e18).sub(getConfig(_liquidationSettled_SS, from));

		_setConfig(_interests_SS, from, getConfig(_interests_SS, from).add(
				interestPerSupply.mul(getConfig(_amountSupply_SS, from)).div(1e18).sub(getConfig(_interestSettled_SS, from))
			));

		_setConfig(_liquidation_SS, from, getConfig(_liquidation_SS, from).add(addLiquidation));

		_setConfig(_amountSupply_SS, from, getConfig(_amountSupply_SS, from).add(amountDeposit));
		remainSupply = remainSupply.add(amountDeposit);

		totalStake = totalStake.add(amountDeposit);

		if(supplyStrategy != address(0) &&
			address(IERC20(IONXStrategy(supplyStrategy).farmToken())) != address(0) &&
			amountDeposit > 0)
		{
			IERC20(IONXStrategy(supplyStrategy).farmToken()).approve(supplyStrategy, amountDeposit);
			IONXStrategy(supplyStrategy).invest(from, amountDeposit);
		}

		_increaseLenderProductivity(from, amountDeposit);

		_setConfig(_interestSettled_SS, from, interestPerSupply.mul(getConfig(_amountSupply_SS, from)).div(1e18));
		_setConfig(_liquidationSettled_SS, from, liquidationPerSupply.mul(getConfig(_amountSupply_SS, from)).div(1e18));
		emit Deposit(from, amountDeposit, addLiquidation);
	}

	function reinvest(address from) public onlyPlatform returns (uint256 reinvestAmount) {
		updateInterests(false);

		uint256 addLiquidation =
		liquidationPerSupply.mul(getConfig(_amountSupply_SS, from)).div(1e18).sub(getConfig(_liquidationSettled_SS, from));

		_setConfig(_interests_SS, from, getConfig(_interests_SS, from).add(
				interestPerSupply.mul(getConfig(_amountSupply_SS, from)).div(1e18).sub(getConfig(_interestSettled_SS, from))
			));

		_setConfig(_liquidation_SS, from, getConfig(_liquidation_SS, from).add(addLiquidation));

		reinvestAmount = getConfig(_interests_SS, from);

		_setConfig(_amountSupply_SS, from, getConfig(_amountSupply_SS, from).add(reinvestAmount));

		totalStake = totalStake.add(reinvestAmount);

		_setConfig(_interests_SS, from, 0);

		_setConfig(_interestSettled_SS, from, getConfig(_amountSupply_SS, from) == 0
			? 0
			: interestPerSupply.mul(getConfig(_amountSupply_SS, from)).div(1e18));

		_setConfig(_liquidationSettled_SS, from, getConfig(_amountSupply_SS, from) == 0
			? 0
			: liquidationPerSupply.mul(getConfig(_amountSupply_SS, from)).div(1e18));

		if (reinvestAmount > 0) {
			_increaseLenderProductivity(from, reinvestAmount);
		}

		emit Reinvest(from, reinvestAmount);
	}

	function withdraw(uint256 amountWithdraw, address from)
	public
	onlyPlatform
	returns (uint256 withdrawSupplyAmount, uint256 withdrawLiquidation)
	{
		require(amountWithdraw > 0, "ONX: INVALID AMOUNT TO WITHDRAW");
		require(amountWithdraw <= getConfig(_amountSupply_SS, from), "ONX: NOT ENOUGH BALANCE");

		updateInterests(false);

		uint256 addLiquidation =
		liquidationPerSupply.mul(getConfig(_amountSupply_SS, from)).div(1e18).sub(getConfig(_liquidationSettled_SS, from));

		_setConfig(_interests_SS, from, getConfig(_interests_SS, from).add(
				interestPerSupply.mul(getConfig(_amountSupply_SS, from)).div(1e18).sub(getConfig(_interestSettled_SS, from))
			));

		_setConfig(_liquidation_SS, from, getConfig(_liquidation_SS, from).add(addLiquidation));

		withdrawLiquidation = getConfig(_liquidation_SS, from).mul(amountWithdraw).div(getConfig(_amountSupply_SS, from));
		uint256 withdrawInterest = getConfig(_interests_SS, from).mul(amountWithdraw).div(getConfig(_amountSupply_SS, from));

		uint256 withdrawLiquidationSupplyAmount =
		totalLiquidation == 0 ? 0 : withdrawLiquidation.mul(totalLiquidationSupplyAmount).div(totalLiquidation);

		if (withdrawLiquidationSupplyAmount < amountWithdraw.add(withdrawInterest))
			withdrawSupplyAmount = amountWithdraw.add(withdrawInterest).sub(withdrawLiquidationSupplyAmount);

		require(withdrawSupplyAmount <= remainSupply, "ONX: NOT ENOUGH POOL BALANCE");
		require(withdrawLiquidation <= totalLiquidation, "ONX: NOT ENOUGH LIQUIDATION");

		remainSupply = remainSupply.sub(withdrawSupplyAmount);
		totalLiquidation = totalLiquidation.sub(withdrawLiquidation);
		totalLiquidationSupplyAmount = totalLiquidationSupplyAmount.sub(withdrawLiquidationSupplyAmount);
		totalPledge = totalPledge.sub(withdrawLiquidation);

		if(supplyStrategy != address(0) &&
		address(IERC20(IONXStrategy(supplyStrategy).farmToken())) != address(0) &&
		amountWithdraw > 0)
		{			
			IONXStrategy(supplyStrategy).withdraw(from, amountWithdraw);
			TransferHelper.safeTransfer(IONXStrategy(supplyStrategy).farmToken(), msg.sender, amountWithdraw);
		}

		_setConfig(_interests_SS, from, getConfig(_interests_SS, from).sub(withdrawInterest));
		_setConfig(_liquidation_SS, from, getConfig(_liquidation_SS, from).sub(withdrawLiquidation));
		_setConfig(_amountSupply_SS, from, getConfig(_amountSupply_SS, from).sub(amountWithdraw));

		totalStake = totalStake.sub(amountWithdraw);

		_setConfig(_interestSettled_SS, from, getConfig(_amountSupply_SS, from) == 0
			? 0
			: interestPerSupply.mul(getConfig(_amountSupply_SS, from)).div(1e18));

		_setConfig(_liquidationSettled_SS, from, getConfig(_amountSupply_SS, from) == 0
			? 0
			: liquidationPerSupply.mul(getConfig(_amountSupply_SS, from)).div(1e18));

		if (withdrawSupplyAmount > 0) {
			TransferHelper.safeTransfer(supplyToken, msg.sender, withdrawSupplyAmount);
		}

		_decreaseLenderProductivity(from, amountWithdraw);

		if (withdrawLiquidation > 0) {
			if(collateralStrategy != address(0))
			{
				IONXStrategy(collateralStrategy).claim(from, withdrawLiquidation, totalLiquidation.add(withdrawLiquidation));
			}
			TransferHelper.safeTransfer(collateralToken, msg.sender, withdrawLiquidation);
		}

		emit Withdraw(from, withdrawSupplyAmount, withdrawLiquidation, withdrawInterest);
	}

	function borrow(
		uint256 amountCollateral,
		uint256 repayAmount,
		uint256 expectBorrow,
		address from
	) public onlyPlatform {
		uint256 amountIn = IERC20(collateralToken).balanceOf(address(this));
		if(collateralStrategy == address(0))
		{
			amountIn = amountIn.sub(totalPledge);
		}

		require(amountCollateral <= amountIn , "ONX: INVALID AMOUNT");

		updateInterests(false);

		uint256 pledgeRate = IConfig(config).getPoolValue(address(this), ConfigNames.POOL_PLEDGE_RATE);
		uint256 maxAmount =
		IConfig(config).convertTokenAmount(
			collateralToken,
			supplyToken,
			getConfig(_amountCollateral_BS, from).add(amountCollateral)
		);

		uint256 maximumBorrow = maxAmount.mul(pledgeRate).div(1e18);
		// uint repayAmount = getRepayAmount(getConfig(_amountCollateral_BS, from), from);

		require(repayAmount + expectBorrow <= maximumBorrow, "ONX: EXCEED MAX ALLOWED");
		require(expectBorrow <= remainSupply, "ONX: INVALID BORROW");

		totalBorrow = totalBorrow.add(expectBorrow);
		totalPledge = totalPledge.add(amountCollateral);
		remainSupply = remainSupply.sub(expectBorrow);

		if(collateralStrategy != address(0) && amountCollateral > 0)
		{
			IERC20(IONXStrategy(collateralStrategy).farmToken()).approve(collateralStrategy, amountCollateral);
			IONXStrategy(collateralStrategy).invest(from, amountCollateral);
		}

		if (getConfig(_index_BS, from) == 0) {
			borrowerList.push(from);
			_setConfig(_index_BS, from, borrowerList.length);
			numberBorrowers++;
		}

		_setConfig(_interests_BS, from, getConfig(_interests_BS, from).add(
				interestPerBorrow.mul(getConfig(_amountBorrow_BS, from)).div(1e18).sub(getConfig(_interestSettled_BS, from))
			));
		_setConfig(_amountCollateral_BS, from, getConfig(_amountCollateral_BS, from).add(amountCollateral));
		_setConfig(_amountBorrow_BS, from, getConfig(_amountBorrow_BS, from).add(expectBorrow));
		_setConfig(_interestSettled_BS, from, interestPerBorrow.mul(getConfig(_amountBorrow_BS, from)).div(1e18));

		if (expectBorrow > 0) {
			TransferHelper.safeTransfer(supplyToken, msg.sender, expectBorrow);
			_increaseBorrowerProductivity(from, expectBorrow);
		}

		emit Borrow(from, expectBorrow, amountCollateral);
	}

	function repay(uint256 amountCollateral, address from)
	public
	onlyPlatform
	returns (uint256 repayAmount, uint256 payoutInterest)
	{
		require(amountCollateral <= getConfig(_amountCollateral_BS, from), "ONX: NOT ENOUGH COLLATERAL");
		require(amountCollateral > 0, "ONX: INVALID AMOUNT TO REPAY");

		uint256 amountIn = IERC20(supplyToken).balanceOf(address(this)).sub(remainSupply);

		updateInterests(true);

		_setConfig(_interests_BS, from, getConfig(_interests_BS, from).add(
				interestPerBorrow.mul(getConfig(_amountBorrow_BS, from)).div(1e18).sub(getConfig(_interestSettled_BS, from))
			));

		repayAmount = getConfig(_amountBorrow_BS, from).mul(amountCollateral).div(getConfig(_amountCollateral_BS, from));
		uint256 repayInterest = getConfig(_interests_BS, from).mul(amountCollateral).div(getConfig(_amountCollateral_BS, from));

		payoutInterest = 0;
		if (supplyToken == IConfig(config).WETH()) {
			payoutInterest = repayInterest.mul(payoutRatio).div(1e18);
		}		

		totalPledge = totalPledge.sub(amountCollateral);
		totalBorrow = totalBorrow.sub(repayAmount);

		_setConfig(_amountCollateral_BS, from, getConfig(_amountCollateral_BS, from).sub(amountCollateral));
		_setConfig(_amountBorrow_BS, from, getConfig(_amountBorrow_BS, from).sub(repayAmount));
		_setConfig(_interests_BS, from, getConfig(_interests_BS, from).sub(repayInterest));
		_setConfig(_interestSettled_BS, from, getConfig(_amountBorrow_BS, from) == 0
			? 0
			: interestPerBorrow.mul(getConfig(_amountBorrow_BS, from)).div(1e18));

		remainSupply = remainSupply.add(repayAmount.add(repayInterest.sub(payoutInterest)));

		if(collateralStrategy != address(0))
		{
			IONXStrategy(collateralStrategy).withdraw(from, amountCollateral);
		}
		TransferHelper.safeTransfer(collateralToken, msg.sender, amountCollateral);
		require(amountIn >= repayAmount.add(repayInterest), "ONX: INVALID AMOUNT TO REPAY");

		if (payoutInterest > 0) {
			TransferHelper.safeTransfer(supplyToken, msg.sender, payoutInterest);
		}

		if (repayAmount > 0) {
			_decreaseBorrowerProductivity(from, repayAmount);
		}

		emit Repay(from, repayAmount, amountCollateral, repayInterest);
	}

	function liquidation(address _user, address from) public onlyPlatform returns (uint256 borrowAmount) {
		require(getConfig(_amountSupply_SS, from) > 0, "ONX: ONLY SUPPLIER");

		updateInterests(false);

		_setConfig(_interests_BS, _user, getConfig(_interests_BS, _user).add(
				interestPerBorrow.mul(getConfig(_amountBorrow_BS, _user)).div(1e18).sub(getConfig(_interestSettled_BS, _user))
			));

		uint256 liquidationRate = IConfig(config).getPoolValue(address(this), ConfigNames.POOL_LIQUIDATION_RATE);

		////// Used pool price for liquidation limit check
		////// uint pledgePrice = IConfig(config).getPoolValue(address(this), ConfigNames.POOL_PRICE);
		////// uint collateralValue = getConfig(_amountCollateral_BS, _user).mul(pledgePrice).div(1e18);

		////// Need to set token price for liquidation
		uint256 collateralValue =
		IConfig(config).convertTokenAmount(collateralToken, supplyToken, getConfig(_amountCollateral_BS, _user));

		uint256 expectedRepay = getConfig(_amountBorrow_BS, _user).add(getConfig(_interests_BS, _user));

		require(expectedRepay >= collateralValue.mul(liquidationRate).div(1e18), "ONX: NOT LIQUIDABLE");

		updateLiquidation(getConfig(_amountCollateral_BS, _user));

		totalLiquidation = totalLiquidation.add(getConfig(_amountCollateral_BS, _user));
		totalLiquidationSupplyAmount = totalLiquidationSupplyAmount.add(expectedRepay);
		totalBorrow = totalBorrow.sub(getConfig(_amountBorrow_BS, _user));

		borrowAmount = getConfig(_amountBorrow_BS, _user);

		uint256 length = getConfig(_length_LS, _user);
		uint256 id = uint256(_user) ^ length;

		_setConfig(_amountCollateral_LS, id, getConfig(_amountCollateral_BS, _user));
		_setConfig(_liquidationAmount_LS, id, expectedRepay);
		_setConfig(_timestamp_LS, id, block.timestamp);

		_setConfig(_length_LS, _user, length + 1);

		liquidationHistoryLength[_user]++;
		if(collateralStrategy != address(0))
		{
			IONXStrategy(collateralStrategy).liquidation(_user);
		}

		emit Liquidation(from, _user, getConfig(_amountBorrow_BS, _user), getConfig(_amountCollateral_BS, _user));

		_setConfig(_amountCollateral_BS, _user, 0);
		_setConfig(_amountBorrow_BS, _user, 0);
		_setConfig(_interests_BS, _user, 0);
		_setConfig(_interestSettled_BS, _user, 0);

		if (borrowAmount > 0) {
			_decreaseBorrowerProductivity(_user, borrowAmount);
		}
	}

	function getPoolCapacity() external view returns (uint256) {
		return totalStake.add(totalBorrow);
	}

	function supplys(address user) external view returns (
		uint256 amountSupply,
		uint256 interestSettled,
		uint256 liquidationSettled,
		uint256 interests,
		uint256 _liquidation
	) {
		amountSupply = getConfig(_amountSupply_SS, user);
		interestSettled = getConfig(_interestSettled_SS, user);
		liquidationSettled = getConfig(_liquidationSettled_SS, user);
		interests = getConfig(_interests_SS, user);
		_liquidation = getConfig(_liquidation_SS, user);
	}

	function borrows(address user) external view returns(
		uint256 index,
		uint256 amountCollateral,
		uint256 interestSettled,
		uint256 amountBorrow,
		uint256 interests
	) {
		index = getConfig(_index_BS, user);
		amountCollateral = getConfig(_amountCollateral_BS, user);
		interestSettled = getConfig(_interestSettled_BS, user);
		amountBorrow = getConfig(_amountBorrow_BS, user);
		interests = getConfig(_interests_BS, user);
	}

	function liquidationHistory(address user, uint256 index) external view returns (
		uint256 amountCollateral,
		uint256 liquidationAmount,
		uint256 timestamp
	) {
		uint256 id = uint256(user) ^ index;

		amountCollateral = getConfig(_amountCollateral_LS, id);
		liquidationAmount = getConfig(_liquidationAmount_LS, id);
		timestamp = getConfig(_timestamp_LS, id);
	}

	function mint() external {
		_mintLender();
		_mintBorrower();
	}
}