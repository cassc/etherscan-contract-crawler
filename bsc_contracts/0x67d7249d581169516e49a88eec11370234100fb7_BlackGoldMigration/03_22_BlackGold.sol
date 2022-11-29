// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./BEP20/BEP20Feeable.sol";

contract BlackGold is BEP20Feeable, ERC20Burnable {
    string private _name = "BlackGold";
    string private _symbol = "BGLD";
    uint8 private _decimals = 8;
    address public liquidity;

    constructor(address liquidity_) BEP20Feeable(_name, _symbol) {
        liquidity = liquidity_;
        _isExcludedFromOutgoingFee[liquidity] = true;
        _isExcludedFromIncomingFee[liquidity] = true;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(_msgSender(), amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);

        if (_shouldTakeFee(from, to)) {
            uint256 onePercent = amount / 100;
            uint256 burnFee = onePercent * 2;
            uint256 miningFee = onePercent * 4;
            uint256 liquidityFee = onePercent * 4;
            uint256 totalFee = burnFee + miningFee + liquidityFee;
            require(
                balanceOf(from) > amount + totalFee,
                "BGLD: transfer amount with fees exceeds balance"
            );
            // mining fees
            _transfer(from, owner(), miningFee);
            // liquidity fees
            _transfer(from, liquidity, liquidityFee);
            // burn
            _burn(from, burnFee);
            emit Fee(from, totalFee);
        }
    }

    /**
     * @dev Sets the liquidity address and excludes it from fees
     */
    function setLiquidity(address newLiquidity) external onlyOwner {
        require(
            liquidity != newLiquidity,
            "BGLD: liquidity address cannot be the same"
        );
        _isExcludedFromOutgoingFee[liquidity] = false;
        _isExcludedFromIncomingFee[liquidity] = false;
        _isExcludedFromOutgoingFee[newLiquidity] = true;
        _isExcludedFromIncomingFee[newLiquidity] = true;
        liquidity = newLiquidity;
    }
}