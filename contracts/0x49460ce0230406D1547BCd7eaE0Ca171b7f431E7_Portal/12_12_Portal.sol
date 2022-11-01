//SPDX-License-Identifier: MIT
/**
███    ███  █████  ████████ ██████  ██ ██   ██     ██████   █████   ██████  
████  ████ ██   ██    ██    ██   ██ ██  ██ ██      ██   ██ ██   ██ ██    ██ 
██ ████ ██ ███████    ██    ██████  ██   ███       ██   ██ ███████ ██    ██ 
██  ██  ██ ██   ██    ██    ██   ██ ██  ██ ██      ██   ██ ██   ██ ██    ██ 
██      ██ ██   ██    ██    ██   ██ ██ ██   ██     ██████  ██   ██  ██████  

Website: https://matrixdaoresearch.xyz/
Twitter: https://twitter.com/MatrixDAO_
Author: 0xEstarriol

 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

/**
    @dev MatrixDAO Investment Portal

    Flow: invest pool1 => invest pool2 => settle pool2 => refund

    In the pool1, an investor can invest up to an allocated amount.
    All the pool1 investment will be transfered to the treasury and count as investors' shares immediately.

    In the pool2, investors can invest up to the total remaining quota from the pool1.
    The investment will not be transferred to the treasury immediately.
    Instead, the funds will stay in the contract as the commitment.

    After the pool2 ends, the funds up to the total remaining investment quota from the pool1 will be transfered from the contract to the treasury.
    The remaining amount will be refunded and can be claim by the investors after the settlement. 
    The actual investment amount and refundable amount will both be propotional to the amount an investor committed in the pool2. 


    Priviledged Accounts:
    - treasury: MatrixDAO multisig
    - owner: MatrixDAO operational team
    - proxy admin: MatrixDAO multisig
 */

contract Portal is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    address public immutable treasury;
    IERC20 public immutable usdc;
    IERC20 public immutable mtx;

    address public signer;

    struct Investment {
        // The ratio of $MTX usage for the investment opportunity.
        uint256 mtxBurnRate;
        // Amount of USDC that is still available for investment.
        uint256 investAmountRemaining;
        // Timestamp of the start and the end time of the pool1 and pool2.
        uint64 pool1StartTime;
        uint64 pool1EndTime;
        uint64 pool2StartTime;
        uint64 pool2EndTime;
        // The total amount of USDC that investors commited in the pool2
        uint256 pool2TotalCommited;
        // Amount of USDC in the pool2 that has been transfered to the treasury
        uint256 pool2Transfered;
    }

    mapping(uint256 => Investment) public investment;

    mapping(uint256 => mapping(address => uint256)) public poolOneInvested;
    mapping(uint256 => mapping(address => uint256)) public poolTwoInvested;
    mapping(uint256 => mapping(address => bool)) public poolTwoRefunded;

    constructor(
        address treasury_,
        IERC20 usdc_,
        IERC20 mtx_
    ) {
        // configure the immutables
        treasury = treasury_;
        usdc = usdc_;
        mtx = mtx_;

        // disable the initializer to prevent implementation take over.
        _disableInitializers();
    }

    function initialize() external initializer {
        __Ownable_init();
        signer = owner();
    }

    function _transferFund(
        address from,
        address to,
        uint256 amount,
        uint256 mtxBurnRate
    ) internal {
        if (from == address(this)) {
            usdc.safeTransfer(to, amount);
        } else {
            usdc.safeTransferFrom(from, to, amount);
        }

        if (mtxBurnRate > 0) {
            if (from == address(this)) {
                mtx.safeTransfer(to, mtxUsage(amount, mtxBurnRate));
            } else {
                mtx.safeTransferFrom(from, to, mtxUsage(amount, mtxBurnRate));
            }
        }
    }

    function mtxUsage(uint256 usdcAmount, uint256 mtxBurnRate)
        public
        pure
        returns (uint256)
    {
        // The decimal of MTX is much larger than USDC (18 vs 6), so we don't need a denominator here.
        return usdcAmount * mtxBurnRate;
    }

    function _checkTime(uint64 startTime, uint64 endTime) internal view {
        require(
            block.timestamp > startTime,
            "Portal: Investment hasn't started."
        );
        require(block.timestamp < endTime, "Portal: Investment has ended.");
    }

    /// @dev Create investment pools (pool1 and pool2) for an investment opportunity.
    function addInvestment(
        uint256 investmentId,
        uint256 mtxBurnRate,
        uint256 investAmountRemaining,
        uint64 pool1StartTime,
        uint64 pool1EndTime,
        uint64 pool2StartTime,
        uint64 pool2EndTime
    ) external onlyOwner {
        require(pool1StartTime != 0);
        require(pool1EndTime > pool1StartTime);
        require(pool2StartTime >= pool1EndTime);
        require(pool2EndTime > pool2StartTime);
        require(investAmountRemaining > 0);
        Investment storage _investment = investment[investmentId];

        require(
            _investment.pool1StartTime == 0,
            "Portal: Investment has been deployed."
        ); // Cannot overwrite existing investments

        _investment.mtxBurnRate = mtxBurnRate;
        _investment.investAmountRemaining = investAmountRemaining;
        _investment.pool1StartTime = pool1StartTime;
        _investment.pool1EndTime = pool1EndTime;
        _investment.pool2StartTime = pool2StartTime;
        _investment.pool2EndTime = pool2EndTime;
    }

    function investPoolOne(
        uint256 investmentId,
        uint256 amount,
        uint256 minimumAmount,
        uint256 allowedAmount,
        bytes calldata signature,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(amount > 0, "Portal: zero amount");
        Investment storage _investment = investment[investmentId];

        _checkTime(_investment.pool1StartTime, _investment.pool1EndTime);

        bytes32 hash = keccak256(
            abi.encodePacked(
                address(this),
                investmentId,
                msg.sender,
                minimumAmount,
                allowedAmount,
                block.chainid
            )
        );
        hash = ECDSAUpgradeable.toEthSignedMessageHash(hash);

        require(
            ECDSAUpgradeable.recover(hash, signature) == signer,
            "Portal: Invalid Signature"
        );

        require(
            amount + poolOneInvested[investmentId][msg.sender] <= allowedAmount,
            "Portal: Invalid Amount"
        );

        require(
            amount + poolOneInvested[investmentId][msg.sender] >= minimumAmount,
            "Portal: Doesn't meet the minimum amount."
        );

        poolOneInvested[investmentId][msg.sender] += amount;
        _investment.investAmountRemaining -= amount;

        if (v > 0) {
            IERC20Permit(address(usdc)).permit(
                msg.sender,
                address(this),
                amount,
                _investment.pool1EndTime,
                v,
                r,
                s
            );
        }

        _transferFund(msg.sender, treasury, amount, _investment.mtxBurnRate);
    }

    function availableAmountPoolTwo(uint256 investmentId, address user)
        public
        view
        returns (uint256)
    {
        Investment storage _investment = investment[investmentId];
        return
            _investment.investAmountRemaining -
            poolTwoInvested[investmentId][user];
    }

    function investPoolTwo(
        uint256 investmentId,
        uint256 amount,
        bytes calldata signature,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(amount > 0, "Portal: zero amount");
        Investment storage _investment = investment[investmentId];

        _checkTime(_investment.pool2StartTime, _investment.pool2EndTime);

        bytes32 hash = keccak256(
            abi.encodePacked(
                address(this),
                investmentId,
                msg.sender,
                block.chainid
            )
        );
        hash = ECDSAUpgradeable.toEthSignedMessageHash(hash);

        require(
            ECDSAUpgradeable.recover(hash, signature) == signer,
            "Portal: Invalid Signature"
        );

        require(
            availableAmountPoolTwo(investmentId, msg.sender) >= amount,
            "Portal: Cannot invest more than the cap."
        );

        poolTwoInvested[investmentId][msg.sender] += amount;
        _investment.pool2TotalCommited += amount;

        if (v > 0) {
            IERC20Permit(address(usdc)).permit(
                msg.sender,
                address(this),
                amount,
                _investment.pool2EndTime,
                v,
                r,
                s
            );
        }

        _transferFund(
            msg.sender,
            address(this),
            amount,
            _investment.mtxBurnRate
        );
    }

    function poolTwoIsSettled(uint256 investmentId) public view returns (bool) {
        Investment storage _investment = investment[investmentId];
        return _investment.pool2Transfered != 0;
    }

    function settlePoolTwo(uint256 investmentId) external onlyOwner {
        Investment storage _investment = investment[investmentId];

        require(
            block.timestamp > _investment.pool2EndTime,
            "Portal: Investment hasn't ended."
        );
        require(
            !poolTwoIsSettled(investmentId),
            "Portal: Investment has been settled."
        );

        uint256 toTransfer = MathUpgradeable.min(
            _investment.pool2TotalCommited,
            _investment.investAmountRemaining
        );

        _investment.pool2Transfered = toTransfer;
        _investment.investAmountRemaining -= toTransfer;

        _transferFund(
            address(this),
            treasury,
            toTransfer,
            _investment.mtxBurnRate
        );
    }

    /// @dev Amount of USDC refund for a user from a invetment opportunity
    function refundableAmount(address user, uint256 investmentId)
        public
        view
        returns (uint256)
    {
        Investment storage _investment = investment[investmentId];
        if (poolTwoRefunded[investmentId][user]) {
            return 0;
        }

        if (!poolTwoIsSettled(investmentId)) {
            // No refundable amount before settlement.
            return 0;
        }

        uint256 remaining = _investment.pool2TotalCommited -
            _investment.pool2Transfered;
        return
            (poolTwoInvested[investmentId][user] * remaining) /
            _investment.pool2TotalCommited;
    }

    function refundPoolTwo(uint256 investmentId) external {
        Investment storage _investment = investment[investmentId];
        uint256 toRefund = refundableAmount(msg.sender, investmentId);
        require(toRefund > 0, "Portal: Zero refundable amount.");
        poolTwoRefunded[investmentId][msg.sender] = true;

        _transferFund(
            address(this),
            msg.sender,
            toRefund,
            _investment.mtxBurnRate
        );
    }

    /// @dev Amount of USDC an user actually invested. This number excludes the USDC refunded to the user.
    ///      The pool2 protion is zero before the settlement.
    function actualInvested(address user, uint256 investmentId)
        public
        view
        returns (uint256 invested)
    {
        Investment storage _investment = investment[investmentId];

        invested = poolOneInvested[investmentId][user];

        if (_investment.pool2TotalCommited > 0) {
            invested +=
                (poolTwoInvested[investmentId][user] *
                    _investment.pool2Transfered) /
                _investment.pool2TotalCommited;
        }
    }

    function extendPoolOne(uint256 investmentId, uint64 time)
        external
        onlyOwner
    {
        require(time <= 1 weeks); // Prevent accidently extending the investment period too long.
        Investment storage _investment = investment[investmentId];

        _checkTime(_investment.pool1StartTime, _investment.pool1EndTime);

        _investment.pool1EndTime += time;
        _investment.pool2StartTime += time;
        _investment.pool2EndTime += time;
    }

    function extendPoolTwo(uint256 investmentId, uint64 time)
        external
        onlyOwner
    {
        require(time <= 1 weeks); // Prevent accidently extending the investment period too long.
        Investment storage _investment = investment[investmentId];

        _checkTime(_investment.pool2StartTime, _investment.pool2EndTime);

        _investment.pool2EndTime += time;
    }

    function setSigner(address signer_) external onlyOwner {
        signer = signer_;
    }

    function emergencyWitdrawUSDC() external onlyOwner {
        usdc.transfer(treasury, usdc.balanceOf(address(this)));
    }

    function emergencyWitdrawMTX() external onlyOwner {
        mtx.transfer(treasury, mtx.balanceOf(address(this)));
    }
}