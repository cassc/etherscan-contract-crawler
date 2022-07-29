//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../LinearPool.sol";

contract FeesAndRulePool is LinearPool, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using SafeCastUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    address public _treasury;
    uint64 public _treasuryFee;

    uint64 public constant MAX_FEE = 1000;

    bool public feeDepositEnabled;
    bool public feeUnstakeEnabled;

    event FeeDeposit(uint256 amount, uint256 tresuryFee);

    event FeeWithdraw(uint256 amount, uint256 tresuryFee);

    event UpdateFeeAndStatus(
        bool depositStatus,
        bool unstakeStatus,
        uint64 fee,
        address treasury
    );

    function __FeesAndRulePool_init(address treasuryPool, IERC20 _acceptedToken)
        public
        initializer
    {
        __LinearPool_init(_acceptedToken);
        _setTreasury(treasuryPool);
        _setFees(100);
        feeDepositEnabled = false;
        feeUnstakeEnabled = false;
    }

    function updateFeeAndStatus(
        bool _depositStatus,
        bool _unstakeStatus,
        uint64 _fee,
        address treasury
    ) external onlyOwner {
        feeDepositEnabled = _depositStatus;
        feeUnstakeEnabled = _unstakeStatus;
        _setFees(_fee);
        _setTreasury(treasury);
        emit UpdateFeeAndStatus(_depositStatus, _unstakeStatus, _fee, treasury);
    }

    function _setFees(uint64 treasury) private {
        require(
            treasury >= 100 && treasury <= MAX_FEE,
            "Fee: value exceeded limit"
        );
        _treasuryFee = treasury;
    }

    function _setTreasury(address pool) private {
        require(pool != address(0), "Zero address not allowed");
        _treasury = pool;
    }

    function _calcAmountAndUnstake(
        uint256 baseAmount,
        uint256 _amountLeft,
        address _receiver
    ) private {
        feeUnstakeEnabled
            ? _splitAndSendUnstake(baseAmount, _amountLeft, _receiver)
            : linearAcceptedToken.safeTransfer(_receiver, _amountLeft);
    }

    function _calcAmountAndDeposit(uint256 baseAmount)
        private
        returns (uint256, uint256)
    {
        uint256 treasuryAmount = (baseAmount * _treasuryFee) / PERCENTAGE_CONST;

        uint256 beforeAmount = linearAcceptedToken.balanceOf(address(this));

        feeDepositEnabled
            ? _splitAndSendDeposit(baseAmount)
            : linearAcceptedToken.safeTransferFrom(
                msg.sender,
                address(this),
                baseAmount
            );

        uint256 afterAmount = linearAcceptedToken.balanceOf(address(this));
        return (
            feeDepositEnabled ? baseAmount - treasuryAmount : baseAmount,
            afterAmount - beforeAmount
        );
    }

    function _splitAndSendDeposit(uint256 baseAmount) private {
        uint256 sendingAmount = baseAmount;
        uint256 treasuryAmount = (baseAmount * _treasuryFee) / PERCENTAGE_CONST;
        sendingAmount = sendingAmount - treasuryAmount;
        linearAcceptedToken.safeTransferFrom(
            msg.sender,
            _treasury,
            treasuryAmount
        );
        linearAcceptedToken.safeTransferFrom(
            msg.sender,
            address(this),
            sendingAmount
        );
        emit FeeDeposit(sendingAmount, treasuryAmount);
    }

    function _splitAndSendUnstake(
        uint256 baseAmount,
        uint256 _amountLeft,
        address _receiver
    ) private {
        uint256 treasuryAmount = (baseAmount * _treasuryFee) / PERCENTAGE_CONST;
        uint256 sendingAmount = _amountLeft - treasuryAmount;

        linearAcceptedToken.safeTransfer(_treasury, treasuryAmount);
        linearAcceptedToken.safeTransfer(_receiver, sendingAmount);
        emit FeeWithdraw(sendingAmount, treasuryAmount);
    }

    function unstake(uint256 _poolId, uint256 _amount)
        external
        nonReentrant
        linearValidatePoolById(_poolId)
    {
        (uint256 _amountLeft, uint256 _baseAmount) = _linearWithdraw(
            _poolId,
            _amount
        );

        _calcAmountAndUnstake(_baseAmount, _amountLeft, msg.sender);
    }

    function deposit(uint256 _poolId, uint256 _amount)
        external
        nonReentrant
        linearValidatePoolById(_poolId)
    {
        LinearPoolInfo storage pool = linearPoolInfo[_poolId];

        LinearStakingData storage stakingData = linearStakingData[_poolId][
            msg.sender
        ];

        (uint256 _amountLeft, uint256 _amountDeposit) = _calcAmountAndDeposit(
            _amount
        );

        if (stakingData.balance == 0) {
            require(
                stakingData.balance + _amountLeft >= pool.minInvestment,
                "LinearStakingPool: User must stake equal or higher than Minimum Stake SBX !"
            );
        }

        require(
            _amountLeft >= stakingData.userMinInvestment,
            "LinearStakingPool: User must stake equal or higher than Minimum Stake SBX !"
        );

        _linearDeposit(_poolId, _amountDeposit);
    }
}