// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;
import "./modules/Configable.sol";
import "./modules/ConfigNames.sol";
import "./libraries/SafeMath.sol";
import "./libraries/TransferHelper.sol";

interface IONXSupplyToken {
	function mint(address account, uint256 amount) external;
	function burn(address account, uint256 amount) external;
	function approve(address spender, uint256 amount) external;
}

interface IWETH {
	function deposit() external payable;
	function withdraw(uint256) external;
}

interface IONXPool {
	function deposit(uint _amountDeposit, address _from) external;
	function withdraw(uint _amountWithdraw, address _from) external returns(uint, uint);
	function borrow(uint _amountCollateral, uint _repayAmount, uint _expectBorrow, address _from) external;
	function repay(uint _amountCollateral, address _from) external returns(uint, uint);
	function liquidation(address _user, address _from) external returns (uint);
	function reinvest(address _from) external returns(uint);

	function setCollateralStrategy(address _collateralStrategy, address _supplyStrategy) external;
	function supplys(address user) external view returns(uint,uint,uint,uint,uint);
	function borrows(address user) external view returns(uint,uint,uint,uint,uint);
	function getPoolCapacity() external view returns (uint);
	function supplyToken() external view returns (address);
	function interestPerBorrow() external view returns(uint);
	function interestPerSupply() external view returns(uint);
	function lastInterestUpdate() external view returns(uint);
	function getInterests() external view returns(uint, uint);
	function totalBorrow() external view returns(uint);
	function remainSupply() external view returns(uint);
	function liquidationPerSupply() external view returns(uint);
	function totalLiquidationSupplyAmount() external view returns(uint);
	function totalLiquidation() external view returns(uint);
}

interface IONXFactory {
    function getPool(address _lendToken, address _collateralToken) external view returns (address);
    function countPools() external view returns(uint);
    function allPools(uint index) external view returns (address);
}

contract ONXPlatform is Configable {
	using SafeMath for uint256;
	uint256 private unlocked;
	address public payoutAddress;
	address public onxSupplyToken;
	modifier lock() {
		require(unlocked == 1, "Locked");
		unlocked = 0;
		_;
		unlocked = 1;
	}

	receive() external payable {}

	function initialize(address _payoutAddress, address _onxSupplyToken) external initializer {
		Configable.__config_initialize();
		unlocked = 1;
		payoutAddress = _payoutAddress;
		onxSupplyToken = _onxSupplyToken;
	}

	function deposit(address _lendToken, address _collateralToken, uint256 _amountDeposit) external lock {
		require(IConfig(config).getValue(ConfigNames.DEPOSIT_ENABLE) == 1, "NOT ENABLE NOW");
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");
		TransferHelper.safeTransferFrom(_lendToken, msg.sender, pool, _amountDeposit);
		if(onxSupplyToken != address(0) && _amountDeposit > 0)
		{
			IONXSupplyToken(onxSupplyToken).mint(address(this), _amountDeposit);
			TransferHelper.safeTransfer(onxSupplyToken, pool, _amountDeposit);
		}
		IONXPool(pool).deposit(_amountDeposit, msg.sender);
	}

	function depositETH(address _lendToken, address _collateralToken) external payable lock {
		require(_lendToken == IConfig(config).WETH(), "INVALID WETH POOL");
		require(IConfig(config).getValue(ConfigNames.DEPOSIT_ENABLE) == 1, "NOT ENABLE NOW");
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");
		IWETH(IConfig(config).WETH()).deposit{value: msg.value}();
		TransferHelper.safeTransfer(_lendToken, pool, msg.value);
		if(onxSupplyToken != address(0) && msg.value > 0)
		{
			IONXSupplyToken(onxSupplyToken).mint(address(this), msg.value);
			TransferHelper.safeTransfer(onxSupplyToken, pool, msg.value);
		}
		IONXPool(pool).deposit(msg.value, msg.sender);
	}

	function withdraw(address _lendToken, address _collateralToken, uint256 _amountWithdraw) external lock {
		require(IConfig(config).getValue(ConfigNames.WITHDRAW_ENABLE) == 1, "NOT ENABLE NOW");
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");
		(uint256 withdrawSupplyAmount, uint256 withdrawLiquidationAmount) =
			IONXPool(pool).withdraw(_amountWithdraw, msg.sender);
		if (withdrawSupplyAmount > 0) {
			_innerTransfer(_lendToken, msg.sender, withdrawSupplyAmount);
			if(onxSupplyToken != address(0) && _amountWithdraw > 0) {
				IONXSupplyToken(onxSupplyToken).burn(address(this), _amountWithdraw);
			}
		}
		if (withdrawLiquidationAmount > 0) _innerTransfer(_collateralToken, msg.sender, withdrawLiquidationAmount);
	}

	function borrow(address _lendToken, address _collateralToken, uint256 _amountCollateral, uint256 _expectBorrow) external lock {
		require(IConfig(config).getValue(ConfigNames.BORROW_ENABLE) == 1, "NOT ENABLE NOW");
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");
		if (_amountCollateral > 0) {
			TransferHelper.safeTransferFrom(_collateralToken, msg.sender, pool, _amountCollateral);
		}

		(, uint256 borrowAmountCollateral, , , ) = IONXPool(pool).borrows(msg.sender);
		uint256 repayAmount = getRepayAmount(_lendToken, _collateralToken, borrowAmountCollateral, msg.sender);
		IONXPool(pool).borrow(_amountCollateral, repayAmount, _expectBorrow, msg.sender);
		if (_expectBorrow > 0) _innerTransfer(_lendToken, msg.sender, _expectBorrow);
	}

	function borrowTokenWithETH(address _lendToken, address _collateralToken, uint256 _expectBorrow) external payable lock {
		require(_collateralToken == IConfig(config).WETH(), "INVALID WETH POOL");
		require(IConfig(config).getValue(ConfigNames.BORROW_ENABLE) == 1, "NOT ENABLE NOW");
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");
        
		if (msg.value > 0) {
			IWETH(IConfig(config).WETH()).deposit{value: msg.value}();
			TransferHelper.safeTransfer(_collateralToken, pool, msg.value);
		}

		(, uint256 borrowAmountCollateral, , , ) = IONXPool(pool).borrows(msg.sender);
		uint256 repayAmount = getRepayAmount(_lendToken, _collateralToken, borrowAmountCollateral, msg.sender);
		IONXPool(pool).borrow(msg.value, repayAmount, _expectBorrow, msg.sender);
		if (_expectBorrow > 0) _innerTransfer(_lendToken, msg.sender, _expectBorrow);
	}

	function repay(address _lendToken, address _collateralToken, uint256 _amountCollateral) external lock {
		require(IConfig(config).getValue(ConfigNames.REPAY_ENABLE) == 1, "NOT ENABLE NOW");
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");
		uint256 repayAmount = getRepayAmount(_lendToken, _collateralToken, _amountCollateral, msg.sender);
		if (repayAmount > 0) {
			TransferHelper.safeTransferFrom(_lendToken, msg.sender, pool, repayAmount);
		}

		(, uint256 payoutInterest) = IONXPool(pool).repay(_amountCollateral, msg.sender);
		if (payoutInterest > 0) {
			_innerTransfer(_lendToken, payoutAddress, payoutInterest);
		}
		_innerTransfer(_collateralToken, msg.sender, _amountCollateral);
	}

	function repayETH(address _lendToken, address _collateralToken, uint256 _amountCollateral) external payable lock {
		require(IConfig(config).getValue(ConfigNames.REPAY_ENABLE) == 1, "NOT ENABLE NOW");
		require(_lendToken == IConfig(config).WETH(), "INVALID WETH POOL");

		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");
		uint256 repayAmount = getRepayAmount(_lendToken, _collateralToken, _amountCollateral, msg.sender);
		require(repayAmount <= msg.value, "INVALID VALUE");
		if (repayAmount > 0) {
			IWETH(IConfig(config).WETH()).deposit{value: repayAmount}();
			TransferHelper.safeTransfer(_lendToken, pool, repayAmount);
		}

		(, uint256 payoutInterest) = IONXPool(pool).repay(_amountCollateral, msg.sender);
		if (payoutInterest > 0) {
			_innerTransfer(_lendToken, payoutAddress, payoutInterest);
		}
		_innerTransfer(_collateralToken, msg.sender, _amountCollateral);
		if (msg.value > repayAmount) TransferHelper.safeTransferETH(msg.sender, msg.value.sub(repayAmount));
	}

	function liquidation(address _lendToken, address _collateralToken, address _user) external lock {
		require(IConfig(config).getValue(ConfigNames.LIQUIDATION_ENABLE) == 1, "NOT ENABLE NOW");
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");
		IONXPool(pool).liquidation(_user, msg.sender);
	}

	function reinvest(address _lendToken, address _collateralToken) external lock {
		require(IConfig(config).getValue(ConfigNames.REINVEST_ENABLE) == 1, "NOT ENABLE NOW");
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");
		IONXPool(pool).reinvest(msg.sender);
	}

	function _innerTransfer(
		address _token,
		address _to,
		uint256 _amount
	) internal {
		if (_token == IConfig(config).WETH()) {
			IWETH(_token).withdraw(_amount);
			TransferHelper.safeTransferETH(_to, _amount);
		} else {
			TransferHelper.safeTransfer(_token, _to, _amount);
		}
	}

	function getRepayAmount(address _lendToken, address _collateralToken, uint256 amountCollateral, address from) public view returns (uint256 repayAmount) {
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");

		(, uint256 borrowAmountCollateral, uint256 interestSettled, uint256 amountBorrow, uint256 borrowInterests) =
			IONXPool(pool).borrows(from);
		(, uint256 borrowInterestPerBlock) = IONXPool(pool).getInterests();
		uint256 _interestPerBorrow =
			IONXPool(pool).interestPerBorrow().add(
				borrowInterestPerBlock.mul(block.number - IONXPool(pool).lastInterestUpdate())
			);
		uint256 repayInterest =
			borrowAmountCollateral == 0 
			? 0 
			: borrowInterests.add(_interestPerBorrow.mul(amountBorrow).div(1e18).sub(interestSettled)).mul(amountCollateral).div(borrowAmountCollateral);
		repayAmount = borrowAmountCollateral == 0
			? 0
			: amountBorrow.mul(amountCollateral).div(borrowAmountCollateral).add(repayInterest);
	}

	function getMaximumBorrowAmount(address _lendToken, address _collateralToken, uint256 amountCollateral) external view returns (uint256 amountBorrow) {
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");

		uint256 pledgeAmount = IConfig(config).convertTokenAmount(_collateralToken, _lendToken, amountCollateral);
		uint256 pledgeRate = IConfig(config).getPoolValue(pool, ConfigNames.POOL_PLEDGE_RATE);
		amountBorrow = pledgeAmount.mul(pledgeRate).div(1e18);
	}

	function getLiquidationAmount(address _lendToken, address _collateralToken, address from) public view returns (uint256 liquidationAmount) {
        	address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
	        require(pool != address(0), "POOL NOT EXIST");

		(uint256 amountSupply, , uint256 liquidationSettled, , uint256 supplyLiquidation) =
			IONXPool(pool).supplys(from);
		liquidationAmount = supplyLiquidation.add(
			IONXPool(pool).liquidationPerSupply().mul(amountSupply).div(1e18).sub(liquidationSettled)
		);
	}

	function getInterestAmount(address _lendToken, address _collateralToken, address from) public view returns (uint256 interestAmount) {
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");

		uint256 totalBorrow = IONXPool(pool).totalBorrow();
		uint256 totalSupply = totalBorrow + IONXPool(pool).remainSupply();
		(uint256 amountSupply, uint256 interestSettled, , uint256 interests, ) = IONXPool(pool).supplys(from);
		(uint256 supplyInterestPerBlock,) = IONXPool(pool).getInterests();
		uint256 _interestPerSupply =
			IONXPool(pool).interestPerSupply().add(
				totalSupply == 0
					? 0
					: supplyInterestPerBlock
						.mul(block.number - IONXPool(pool).lastInterestUpdate())
						.mul(IONXPool(pool).totalBorrow())
						.div(totalSupply)
			);
		interestAmount = interests.add(_interestPerSupply.mul(amountSupply).div(1e18).sub(interestSettled));
	}

	function getWithdrawAmount(address _lendToken, address _collateralToken, address from)
		external
		view
		returns (
			uint256 withdrawAmount,
			uint256 interestAmount,
			uint256 liquidationAmount
		)
	{
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");

		uint256 _totalInterest = getInterestAmount(_lendToken, _collateralToken, from);
		liquidationAmount = getLiquidationAmount(_lendToken, _collateralToken, from);
		interestAmount = _totalInterest;
		uint256 totalLiquidation = IONXPool(pool).totalLiquidation();
		uint256 withdrawLiquidationSupplyAmount =
			totalLiquidation == 0
				? 0
				: liquidationAmount.mul(IONXPool(pool).totalLiquidationSupplyAmount()).div(totalLiquidation);
		(uint256 amountSupply, , , , ) = IONXPool(pool).supplys(from);
		if (withdrawLiquidationSupplyAmount > amountSupply.add(interestAmount)) withdrawAmount = 0;
		else withdrawAmount = amountSupply.add(interestAmount).sub(withdrawLiquidationSupplyAmount);
	}

	function updatePoolParameter(address _lendToken, address _collateralToken, bytes32 _key, uint256 _value) external onlyOwner {
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");
		IConfig(config).setPoolValue(pool, _key, _value);
	}

	function setCollateralStrategy(address _lendToken, address _collateralToken, address _collateralStrategy, address _supplyStrategy) external onlyOwner
	{
		address pool = IONXFactory(IConfig(config).factory()).getPool(_lendToken, _collateralToken);
		require(pool != address(0), "POOL NOT EXIST");
		IONXPool(pool).setCollateralStrategy(_collateralStrategy, _supplyStrategy);
	}

	function setPayoutAddress(address _payoutAddress) external onlyOwner {
		payoutAddress = _payoutAddress;
	}
}