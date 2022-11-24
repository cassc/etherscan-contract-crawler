// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./BEP20/BEP20Feeable.sol";

contract Bet is BEP20Feeable {
    string private _name = "Bet";
    string private _symbol = "BET";
    uint8 private _decimals = 8;
    address public council;

    constructor(address council_, uint256 totalSupply_)
        BEP20Feeable(_name, _symbol)
    {
        council = council_;
        _isExcludedFromOutgoingFee[council] = true;
        _isExcludedFromIncomingFee[council] = true;

        _mint(_msgSender(), totalSupply_);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);

        if (_shouldTakeFee(from, to)) {
            uint256 onePercent = amount / 100;
            uint256 councilFee = onePercent * 10;
            uint256 totalFee = councilFee;
            require(
                balanceOf(from) > amount + totalFee,
                "BET: transfer amount with fees exceeds balance"
            );
            // council fees
            _transfer(from, council, councilFee);
            emit Fee(from, totalFee);
        }
    }

    /**
     * @dev Sets the council address and excludes it from fees
     */
    function setCouncil(address newCouncil) external onlyOwner {
        require(
            council != newCouncil,
            "BET: council address cannot be the same"
        );
        _isExcludedFromOutgoingFee[council] = false;
        _isExcludedFromIncomingFee[council] = false;
        _isExcludedFromOutgoingFee[newCouncil] = true;
        _isExcludedFromIncomingFee[newCouncil] = true;
        council = newCouncil;
    }
}