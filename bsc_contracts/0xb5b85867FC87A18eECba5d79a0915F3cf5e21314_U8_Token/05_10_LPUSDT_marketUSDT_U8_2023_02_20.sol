// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.17;

import "./auth/Owned.sol";
import "./interfaces/IERC20.sol";
import "./utils/ExcludedFromFeeList.sol";
import "./tokens/ERC20.sol";
import "./Uniswap/IUniswapV2Factory.sol";
import "./Uniswap/IUniswapV2Router.sol";
import "./Uniswap/DexBaseUSDT.sol";
import "./library/FixUSDTLpFeeWithMarket1.sol";

contract U8_Token is ExcludedFromFeeList, FixUSDTLpFeeWithMarket1 {
    uint256 private constant _totalSupply = 39_0000 * 1e18;
    uint256 public launchedAt;
    uint256 public launchedAtTimestamp;

    constructor()
        Owned(msg.sender)
        ERC20("U8", "U8", 18)
        FixUSDTLpFeeWithMarket1(
            1 ether,
            _totalSupply / 10_0000,
            0x90Dd4D268d6107f74066599fbf6018EACdd50413,
            15,
            14
        )
    {
        _mint(msg.sender, _totalSupply);
        excludeFromFee(msg.sender);
        excludeFromFee(0x9AD7db7ACA475D901249cfA26AdF982A5fD552a2);
        excludeFromFee(address(this));
        allowance[msg.sender][address(uniswapV2Router)] = type(uint256).max;
    }

    function takeFee(address sender, uint256 amount)
        internal
        returns (uint256)
    {
        if (launchedAt + 20 >= block.number) {
            unchecked {
                uint256 some = (amount * 7) / 10;
                uint256 antAmount = amount - some;
                super._transfer(sender, address(this), antAmount);
                return some;
            }
        }

        uint256 lpAmount = _takelpFee(sender, amount);
        return amount - lpAmount;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        require(launchedAt == 0, "Already launched boi");
        launchedAt = block.number;
        launchedAtTimestamp = block.timestamp;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (inSwapAndLiquify) {
            super._transfer(sender, recipient, amount);
            return;
        }

        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            super._transfer(sender, recipient, amount);

            if (!launched() && recipient == uniswapV2Pair) {
                require(balanceOf[sender] > 0);
                launch();
            }

            //dividend token
            dividendToUsers(sender, recipient);
            return;
        }

        if (recipient == uniswapV2Pair) {
            require(launched(), "launched");
            // sell
            if (shouldSwapAndLiquify(sender)) {
                swapAndLiquify();
            }
            uint256 transferAmount = takeFee(sender, amount);
            super._transfer(sender, recipient, transferAmount);
        } else if (sender == uniswapV2Pair) {
            // buy
            uint256 transferAmount = takeFee(sender, amount);
            super._transfer(sender, recipient, transferAmount);
        } else {
            // transfer
            super._transfer(sender, recipient, amount);
        }
        //dividend token
        dividendToUsers(sender, recipient);
    }
}