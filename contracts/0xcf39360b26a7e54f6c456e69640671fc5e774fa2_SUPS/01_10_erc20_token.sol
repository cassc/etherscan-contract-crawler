// SPDX-License-Identifier: AGPL-1.0-only
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./crypto_verifysignatures.sol";

/// @custom:security-contact [email protected]
contract SUPS is ERC20, Ownable {
    using SafeERC20 for IERC20;
    bool public transferrable;

    constructor() ERC20("Supremacy", "SUPS") {
        _mint(msg.sender, 300_000_000 ether);
    }

    // flushSUPS returns the SUPS to the owner in case a user has erroneously sent SUPS over
    function flushSUPS() public onlyOwner {
        uint256 amt = balanceOf(address(this));
        transfer(msg.sender, amt);
    }

    // rescueERC20 withdraws the ERC20 in case a user has erroneously sent ERC20 tokens over
    function flushERC20(address tokenAddr) public onlyOwner {
        IERC20 tokenContract = IERC20(tokenAddr);
        uint256 amt = tokenContract.balanceOf(address(this));
        tokenContract.safeTransfer(msg.sender, amt);
    }

    // setTransferable when platform is ready to allow users to transfer
    function setTransferable(bool _transferrable) public onlyOwner {
        transferrable = _transferrable;
        emit SetTransferrable(_transferrable);
    }

    // _beforeTokenTransfer allows owner to transfer if the flag isn't set yet
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        if (msg.sender != owner()) {
            require(transferrable, "transfers are locked");
        }
    }

    event SetTransferrable(bool _transferrable);
}