//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IDodoRouter.sol";
import "../interfaces/IDODOApproveProxy.sol";

contract DodoAdapter is Ownable {
    using SafeERC20 for IERC20;

    IDodoRouter public immutable router;
    address public immutable dodoApprove;

    event HermesSwap(
        address indexed router,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    constructor(address routerAddr) {
        router = IDodoRouter(routerAddr);
        address approveProxy = router._DODO_APPROVE_PROXY_();
        dodoApprove = IDODOApproveProxy(approveProxy)._DODO_APPROVE_();
    }

    function mixSwap(
        address[] calldata path,
        address[] memory mixAdapters,
        address[] memory mixPairs,
        address[] memory assetTo,
        uint256 directions,
        bytes[] memory moreInfos
    ) external virtual returns (uint256[] memory amounts) {
        require(path.length == 2, "DodoAdapter: INVALID_PATH");
        IERC20 token = IERC20(path[0]);
        uint256 amount = token.balanceOf(address(this));
        token.approve(dodoApprove, amount);
        amounts = new uint256[](2);
        amounts[0] = amount;
        amounts[1] = router.mixSwap(
            path[0],
            path[1],
            amount,
            1,
            mixAdapters,
            mixPairs,
            assetTo,
            directions,
            moreInfos,
            block.timestamp
        );
        emit HermesSwap(address(router), path[0], path[path.length - 1], amounts[0], amounts[amounts.length - 1]);
        return amounts;
    }

    function inCaseTokensGetStuck(
        address token,
        address to,
        uint256 amount
    ) public onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }
}