pragma solidity 0.8.16;

import "../Mocks/LiquidLockerMock.sol";

interface IveMAV {
    function stake(uint256 amount, uint256 duration, bool doDelegation) external;
    function extend(uint256 lockupId, uint256 duration, uint256 amount, bool doDelegation) external;

    function unstake(uint256 lockupId) external;

    struct Lockup {
        uint128 amount;
        uint128 end;
        uint256 points;
    }

    function lockups(address, uint256) external view returns(uint128 amount, uint128 end, uint256 points);
    function lockupCount(address staker) external view returns (uint256 count);
    function balanceOf(address) external view returns(uint256);
}

contract LiquidLockerMAV is LiquidLockerMock {
    using SafeERC20 for IERC20;

    address public constant veMAV = 0x4949Ac21d5b2A0cCd303C20425eeb29DCcba66D8;
    uint256 constant MAXTIME = 4 * 365 * 86400; // 4 years
    uint256 constant DEFAULTLOCK = 0;

    function target() external override view returns(address) {
        return veMAV;
    }

    function locked() external override view returns(uint256) {
        return IveMAV(veMAV).balanceOf(msg.sender);
    }

    function initialize(uint256 amount, uint256) external {
        if (IveMAV(veMAV).lockupCount(address(this)) > 0) {
            return;
        }
        IveMAV(veMAV).stake(amount, MAXTIME, true);
    }

    function lock(
        uint256 amount,
        uint256
    ) external override returns(uint256){
        _extend(amount, MAXTIME);
        return amount;
    }

    function _extend(uint256 amount, uint256 unlockTime) internal{
        IveMAV(veMAV).extend(DEFAULTLOCK, unlockTime, amount, false);
    }

    function release(address token, uint256, bytes memory payload) external override {
        uint256 lockId = abi.decode(payload, (uint256));
        _release(lockId);
        IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function _release(uint256 lockId) internal {
        IveMAV(veMAV).unstake(lockId);
    }

    function exec(bytes memory payload) external override {
        revert("not implemented");
    }
}