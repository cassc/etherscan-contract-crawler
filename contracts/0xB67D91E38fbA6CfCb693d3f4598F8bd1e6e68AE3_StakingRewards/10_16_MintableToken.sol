//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/Owned.sol";
import "../interfaces/IBurnableToken.sol";

/// @author  umb.network
abstract contract MintableToken is Owned, ERC20, IBurnableToken {
    uint256 public immutable maxAllowedTotalSupply;
    uint256 public everMinted;

    modifier assertMaxSupply(uint256 _amountToMint) {
        _assertMaxSupply(_amountToMint);
        _;
    }

    // ========== CONSTRUCTOR ========== //

    constructor (uint256 _maxAllowedTotalSupply) {
        require(_maxAllowedTotalSupply != 0, "_maxAllowedTotalSupply is empty");

        maxAllowedTotalSupply = _maxAllowedTotalSupply;
    }

    // ========== MUTATIVE FUNCTIONS ========== //

    function burn(uint256 _amount) override external {
        _burn(msg.sender, _amount);
    }

    // ========== RESTRICTED FUNCTIONS ========== //

    function mint(address _holder, uint256 _amount)
        virtual
        external
        onlyOwner()
        assertMaxSupply(_amount)
    {
        require(_amount != 0, "zero amount");

        _mint(_holder, _amount);
    }

    function _assertMaxSupply(uint256 _amountToMint) internal {
        uint256 everMintedTotal = everMinted + _amountToMint;
        everMinted = everMintedTotal;
        require(everMintedTotal <= maxAllowedTotalSupply, "total supply limit exceeded");
    }
}