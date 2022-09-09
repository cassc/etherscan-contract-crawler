// SPDX-License-Identifier: MIT

/*********************************************************
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░  .░░░░░░░░░░░░░░░░░░░░░░░░.  ҹ░░░░░░░░░░░░*
*░░░░░░░░░░░░░  ∴░░░░░░░░░░░░░░░░░░`   ░░․  ░░∴   (░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º   ҹ  ░   (░░░░░░░░*
*░░░░░⁕  .░░░░░░░░░░░░░░░░░░░░░░░     ⁕..    .∴,    ⁕░░░░*
*░░░░░░  ∴░░░░░░░░░░░░░░░░░░░░░░░ҹ ,(º⁕ҹ     ․∴ҹ⁕(. ⁕░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º`  ․░  ⁕,   ░░░░░░░░*
*░░░░░,  .░░░░░░░░░░░░░░░░░░░░░░░░░`  ,░░⁕  ∴░░   `░░░░░░*
*░░░░░░⁕º░░░░░░░░░░░░░░⁕   ҹ░░░░░░░░░░░░░,  %░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░ҹ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░ҹ   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░º(░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*********************************************************/

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC20X/ERC20X.sol";

/// ERC-20 that can be held by a token
contract SpellsCoin is ERC20X, Ownable {
    address minter;
    uint256 private claimable;

    constructor(address _minter, uint256 _claimable) ERC20X("Spells Magic", "CAST") {
        minter = _minter;
        claimable = _claimable;
    }
    
    function claim() external onlyOwner nonReentrant {
        require(claimable > 0, "SpellsCoin: no claimabled remaining");
        _mint(owner(), claimable);
        claimable = 0;
    }
    
    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }
    
    function setName(string memory name_, string memory symbol_) external onlyOwner {
        _name = name_;
        symbol_ = symbol_;
    }

    function decimals() public pure override(ERC20) returns (uint8) {
        return 18;
    }

    /// @dev Spells contract can mint spellsCoin to given `tokenId`.
    function mint(
        address _contract,
        uint256 tokenId,
        uint256 amount
    ) external {
        require(msg.sender == minter, "SpellsCoin: sender not minter");
        _mint(_contract, tokenId, amount);
    }
    
    /// @dev Spells contract can mint spellsCoin to given address.
    function mint(address account, uint256 amount) external {
        require(msg.sender == minter, "SpellsCoin: sender not minter");
        _mint(account, amount);
    }
}