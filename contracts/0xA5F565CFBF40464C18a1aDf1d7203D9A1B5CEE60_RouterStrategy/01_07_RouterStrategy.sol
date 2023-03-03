// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {BaseStrategy} from "BaseStrategy.sol";
import {SafeERC20,SafeMath,IERC20,Address} from "SafeERC20.sol";
import "Math.sol";

interface ILossChecker {
    function check_loss(uint, uint) external view returns (uint);
}

interface ISharesHelper {
    function sharesToAmount(address, uint) external view returns (uint);
    function amountToShares(address, uint) external view returns (uint);
}

interface IVault is IERC20 {
    function token() external view returns (address);
    function decimals() external view returns (uint256);
    function deposit() external;
    function withdraw(
        uint256 amount,
        address account,
        uint256 maxLoss
    ) external returns (uint256);
}

contract RouterStrategy is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    string internal strategyName;
    IVault public yVault;
    ILossChecker public constant lossChecker = ILossChecker(0x6b6003d4Bc320Ed25E8E2be49600EC1006676239);
    uint256 public feeLossTolerance;
    uint256 public maxLoss;
    bool internal isOriginal = true;
    ISharesHelper public constant sharesHelper = 
        ISharesHelper(0x444443bae5bB8640677A8cdF94CB8879Fec948Ec); // CREATE2 generated address, deployable to all chains

    constructor(
        address _vault,
        address _yVault,
        string memory _strategyName
    ) public BaseStrategy(_vault) {
        _initializeThis(_yVault, _strategyName);
    }

    event Cloned(address indexed clone);

    function cloneRouter(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        address _yVault,
        string memory _strategyName
    ) external virtual returns (address newStrategy) {
        require(isOriginal);
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(address(this));
        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(
                clone_code,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(
                add(clone_code, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            newStrategy := create(0, clone_code, 0x37)
        }

        RouterStrategy(newStrategy).initialize(
            _vault,
            _strategist,
            _rewards,
            _keeper,
            _yVault,
            _strategyName
        );

        emit Cloned(newStrategy);
    }

    function initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        address _yVault,
        string memory _strategyName
    ) public {
        _initialize(_vault, _strategist, _rewards, _keeper);
        require(address(yVault) == address(0));
        _initializeThis(_yVault, _strategyName);
    }

    function _initializeThis(address _yVault, string memory _strategyName)
        internal
    {
        yVault = IVault(_yVault);
        strategyName = _strategyName;
        IERC20(address(want)).approve(_yVault, uint256(-1));
    }

    function name() external view override returns (string memory) {
        return strategyName;
    }

    function estimatedTotalAssets()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return balanceOfWant().add(valueOfInvestment());
    }

    function prepareReturn(uint256 _debtOutstanding)
        internal
        virtual
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        uint256 _totalDebt = vault.strategies(address(this)).totalDebt;
        uint256 _totalAsset = estimatedTotalAssets();

        // Estimate the profit we have so far
        if (_totalDebt < _totalAsset) {
            _profit = _totalAsset.sub(_totalDebt);
        }

        // We take profit and debt
        uint256 _amountFreed;
        (_amountFreed, _loss) = liquidatePosition(
            _debtOutstanding.add(_profit)
        );
        _debtPayment = Math.min(_debtOutstanding, _amountFreed);

        if (_loss > _profit) {
            // Example:
            // debtOutstanding 100, profit 40, _amountFreed 100, _loss 50
            // loss should be 10, (50-40)
            // profit should endup in 0
            _loss = _loss.sub(_profit);
            _profit = 0;
        } else {
            // Example:
            // debtOutstanding 100, profit 50, _amountFreed 140, _loss 10
            // _profit should be 40, (50 profit - 10 loss)
            // loss should end up in be 0
            _profit = _profit.sub(_loss);
            _loss = 0;
        }

        uint expectedLoss = lossChecker.check_loss(_profit, _loss);
        require(feeLossTolerance >= expectedLoss, "LossyWithFees");
    }

    function adjustPosition(uint256 _debtOutstanding)
        internal
        virtual
        override
    {
        if (emergencyExit) {
            return;
        }

        uint256 balance = balanceOfWant();
        if (balance > 0) {
            yVault.deposit();
        }
    }

    function liquidatePosition(uint256 _amountNeeded)
        internal
        virtual
        override
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        uint256 balance = balanceOfWant();
        if (balance >= _amountNeeded) {
            return (_amountNeeded, 0);
        }

        uint256 toWithdraw = _amountNeeded.sub(balance);
        _withdrawFromYVault(toWithdraw);

        uint256 looseWant = balanceOfWant();
        if (_amountNeeded > looseWant) {
            _liquidatedAmount = looseWant;
            _loss = _amountNeeded.sub(looseWant);
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function _withdrawFromYVault(uint256 _amount) internal {
        if (_amount == 0) {
            return;
        }

        uint256 _balanceOfYShares = yVault.balanceOf(address(this));
        uint256 sharesToWithdraw =
            Math.min(_investmentTokenToYShares(_amount), _balanceOfYShares);

        if (sharesToWithdraw == 0) {
            return;
        }

        yVault.withdraw(sharesToWithdraw, address(this), maxLoss);
    }

    function prepareMigration(address _newStrategy) internal virtual override {
        IERC20(yVault).safeTransfer(
            _newStrategy,
            IERC20(yVault).balanceOf(address(this))
        );
    }

    function protectedTokens()
        internal
        view
        override
        returns (address[] memory ret)
    {
        ret = new address[](1);
        ret[0] = address(yVault);
    }

    function setMaxLoss(uint256 _maxLoss) public onlyAuthorized {
        maxLoss = _maxLoss;
    }

    function setFeeLossTolerance(uint256 _tolerance) public onlyAuthorized {
        feeLossTolerance = _tolerance;
    }

    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function _investmentTokenToYShares(uint256 amount)
        internal
        view
        returns (uint256)
    {
        return sharesHelper.amountToShares(address(yVault), amount);
    }

    function valueOfInvestment() public view virtual returns (uint256) {
        return sharesHelper.sharesToAmount(address(yVault), yVault.balanceOf(address(this)));
    }
}