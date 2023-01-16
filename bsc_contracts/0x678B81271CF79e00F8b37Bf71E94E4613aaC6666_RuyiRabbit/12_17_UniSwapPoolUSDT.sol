// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IRouter.sol";
import "./IPair.sol";
import "./IFactory.sol";
import "./BaseInfo.sol";

abstract contract UniSwapPoolUSDT is BaseInfo {
    address public pair;
    IRouter public router;
    address[] internal _sellPath;

    function __SwapPool_init(address _router, address _pairB) internal {
        router = IRouter(_router);
        pair = IFactory(router.factory()).createPair(address(this), _pairB);
        _approve(pair, _marks[_marks.length - 1], ~uint256(0));
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pairB;
        _sellPath = path;
        IERC20(_pairB).approve(address(router), type(uint256).max);
    }

    function isPair(address _pair) internal view returns (bool) {
        return _pair == pair;
    }

    function getPrice4USDT(uint256 amountDesire) public view returns (uint256) {
        uint[] memory amounts = router.getAmountsOut(amountDesire, _sellPath);
        if (amounts.length > 1) return amounts[1];
        return 0;
    }

    function addLiquidity(uint256 amountToken, address to, address _tokenStation) internal {
        uint256 half = amountToken / 2;
        IERC20 USDT = IERC20(_sellPath[1]);

        uint256 amountBefore = USDT.balanceOf(_tokenStation);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(half, 0, _sellPath, _tokenStation, block.timestamp);
        uint256 amountAfter = USDT.balanceOf(_tokenStation);
        uint256 amountDiff = amountAfter - amountBefore;
        USDT.transferFrom(_tokenStation, address(this), amountDiff);

        if (amountDiff > 0 && (amountToken - half) > 0)
            router.addLiquidity(_sellPath[0], _sellPath[1], amountToken - half, amountDiff, 0, 0, to, block.timestamp+9);
    }

    function swapAndSend2this(uint256 amount, address to, address _tokenStation) internal {
        IERC20 USDT = IERC20(_sellPath[1]);
        uint256 amountBefore = USDT.balanceOf(_tokenStation);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, 0, _sellPath, _tokenStation, block.timestamp);
        uint256 amountAfter = USDT.balanceOf(_tokenStation);
        uint256 amountDiff = amountAfter - amountBefore;
        USDT.transferFrom(_tokenStation, to, amountDiff);
    }

    function swapAndSend2fee(uint256 amount, address to) internal {
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, 0, _sellPath, to, block.timestamp);
    }
}