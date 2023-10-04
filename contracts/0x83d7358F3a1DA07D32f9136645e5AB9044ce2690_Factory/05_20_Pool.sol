// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPool} from "./interfaces/IPool.sol";

contract Pool is Initializable, ReentrancyGuardUpgradeable, IPool {
    using SafeERC20 for IERC20;

    uint256 public poolId;

    address public router; // the token for the pool

    address private _token;

    uint8 public sharedDecimals;

    uint8 public localDecimals;

    uint256 private _convertRate;

    event AddLiquidity(address indexed user, uint256 amount);
    event RemoveLiquidity(address indexed user, uint256 amount);
    event RemoveLiquidityTo(address indexed user, uint256 amount, address to);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    //---------------------------------MODIFIERS------------------------------------------
    modifier onlyRouter() {
        require(msg.sender == router, "Pool: only the router can call this method");
        _;
    }

    /**
     * @dev Initialize pool contract function.
     */
    function initialize(uint256 poolId_, address router_, address token_, uint8 sharedDecimals_, uint8 localDecimals_)
        public
        initializer
    {
        __ReentrancyGuard_init();

        poolId = poolId_;
        router = router_;
        _token = token_;
        sharedDecimals = sharedDecimals_;
        localDecimals = localDecimals_;
        _convertRate = 10 ** (localDecimals_ - sharedDecimals_);
    }

    function addLiquidity(address user_, uint256 amountLD_) external nonReentrant onlyRouter {
        require(amountLD_ > 0, "Pool: Amount too small");

        emit AddLiquidity(user_, amountLD_);
    }

    function removeLiquidity(address user_, uint256 amountLD_) external nonReentrant onlyRouter {
        require(balance() >= amountLD_, "Pool: Insufficient Liquidity");

        IERC20(_token).safeTransfer(user_, amountLD_);
        emit RemoveLiquidity(user_, amountLD_);
    }

    function removeLiquidityTo(address user_, uint256 amountLD_, address to_) external nonReentrant onlyRouter {
        require(balance() >= amountLD_, "Pool: Insufficient Liquidity");

        IERC20(_token).safeTransfer(to_, amountLD_);
        emit RemoveLiquidityTo(user_, amountLD_, to_);
    }

    function deposit(address user_, uint256 amountLD_) external nonReentrant onlyRouter returns (uint256 amountSD) {
        amountSD = amountLDtoSD(amountLD_);
        emit Deposit(user_, amountLD_);
    }

    function withdraw(address user_, uint256 amountSD_) external nonReentrant onlyRouter returns (uint256 amountLD) {
        amountLD = amountSDtoLD(amountSD_);

        require(balance() >= amountLD, "Pool: Liquidity shortage");
        IERC20(_token).safeTransfer(user_, amountLD);
        emit Withdraw(user_, amountLD);
    }

    function token() external view returns (address) {
        return _token;
    }

    function convertRate() external view returns (uint256) {
        return _convertRate;
    }

    function balance() public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function amountSDtoLD(uint256 amount_) internal view returns (uint256) {
        return amount_ * _convertRate;
    }

    function amountLDtoSD(uint256 amount_) internal view returns (uint256) {
        return amount_ / _convertRate;
    }
}