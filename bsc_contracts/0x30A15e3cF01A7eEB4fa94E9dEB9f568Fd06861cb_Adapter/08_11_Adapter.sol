// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "contracts/interfaces/IUpSwapRouter02.sol";
import "contracts/interfaces/IUpSwapPair.sol";

contract Adapter is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // UpSwap router address
    IUpSwapRouter02 public router;

    constructor(address _router) {
        require(_router != address(0), "Zero address");
        router = IUpSwapRouter02(_router);
    }

    /// @dev zap single token to lp token
    function zapIn(address _from, uint256 _amount, address _to) external returns (uint256) {
        IERC20(_from).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 sellAmt = _amount.div(2);
        IERC20(_from).safeApprove(address(router), sellAmt);
        uint256 toAmt = _pairSwap(_from, sellAmt, _to, address(this));

        IERC20(_from).safeApprove(address(router), _amount.sub(sellAmt));
        IERC20(_to).safeApprove(address(router), toAmt);

        (,,uint256 liquidityAmt) = router.addLiquidity(_from, _to, _amount.sub(sellAmt), toAmt, 0, 0, msg.sender, block.timestamp);
        return liquidityAmt;
    }

    /// @dev unzap lp token to single token
    function zapOut(address _lp, uint256 _amount, address _from) external returns (uint256) {
        IUpSwapPair(_lp).transferFrom(msg.sender, address(this), _amount);

        address _to = _from == IUpSwapPair(_lp).token0() ? IUpSwapPair(_lp).token1() : IUpSwapPair(_lp).token0();

        IUpSwapPair(_lp).approve(address(router), _amount);
        (uint256 amtA, uint256 amtB) = router.removeLiquidity(_from, _to, _amount, 0, 0, address(this), block.timestamp);

        IERC20(_to).safeApprove(address(router), amtB);
        uint256 fromAmt = _pairSwap(_to, amtB, _from, address(this));

        uint256 totalAmt = amtA.add(fromAmt);
        IERC20(_from).safeTransfer(msg.sender, totalAmt);
        return totalAmt;
    }

    /* ========== Internal Functions ========== */

    function _pairSwap(address _from, uint256 _amount, address _to, address _receiver) internal returns (uint256) {
        address[] memory path = new address[](2);

        path[0] = _from;
        path[1] = _to;

        uint256[] memory amounts = router.swapExactTokensForTokens(_amount, 0, path, _receiver, block.timestamp);
        return amounts[amounts.length - 1];
    }

    /* ========== Restricted Functions ========== */

    function updateRouter(address _newRouterAddr) external onlyOwner {
        require(_newRouterAddr != address(0), "Zero address");
        router = IUpSwapRouter02(_newRouterAddr);
    }

    function withdraw(address token) external onlyOwner {
        if (token == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
            return;
        }

        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
}