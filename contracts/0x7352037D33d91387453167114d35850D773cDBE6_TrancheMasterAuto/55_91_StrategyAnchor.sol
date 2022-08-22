//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../refs/CoreRef.sol";

interface IAnchorBridge {
    function depositStable(address token, uint256 amount) external;
    function redeemStable(address token, uint256 amount) external;
}

contract StrategyAnchor is ReentrancyGuard, CoreRef {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public constant xAnchorBridge = 0x95aE712C309D33de0250Edd0C2d7Cb1ceAFD4550;

    address public constant wantAddress = 0xb599c3590F42f8F995ECfa0f85D2980B76862fc1;
    address public constant aUSTAddress = 0xaB9A04808167C170A9EC4f8a87a0cD781ebcd55e;

    constructor(
        address _core
    ) public CoreRef(_core) {
        IERC20(wantAddress).safeApprove(xAnchorBridge, uint256(-1));
        IERC20(aUSTAddress).safeApprove(xAnchorBridge, uint256(-1));
    }

    function deposit(uint256 _wantAmt) external nonReentrant whenNotPaused {
        IERC20(wantAddress).safeTransferFrom(address(msg.sender), address(this), _wantAmt);
        _deposit(wantLockedInHere());
    }

    function _deposit(uint256 _wantAmt) internal {
        IAnchorBridge(xAnchorBridge).depositStable(wantAddress, _wantAmt);
    }

    function earn() external {}

    function withdraw() public onlyMultistrategy nonReentrant {
        IAnchorBridge(xAnchorBridge).redeemStable(aUSTAddress, IERC20(aUSTAddress).balanceOf(address(this)));
    }

    function _pause() internal override {
        super._pause();
        IERC20(wantAddress).safeApprove(xAnchorBridge, 0);
        IERC20(aUSTAddress).safeApprove(xAnchorBridge, 0);
    }

    function _unpause() internal override {
        super._unpause();
        IERC20(wantAddress).safeApprove(xAnchorBridge, uint256(-1));
        IERC20(aUSTAddress).safeApprove(xAnchorBridge, uint256(-1));
    }

    function wantLockedInHere() public view returns (uint256) {
        return IERC20(wantAddress).balanceOf(address(this));
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyTimelock {
        require(_token != wantAddress, "!safe");
        require(_token != aUSTAddress, "!safe");
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function updateStrategy() external {}
}