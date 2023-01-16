// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IBPContract {
    function protect(
        address sender,
        address receiver,
        uint256 amount
    ) external;
}

/// @custom:security-contact [email protected]
contract Koakuma is ERC20, ERC20Burnable, Pausable, Ownable {
    IBPContract public bpContract;

    bool public bpEnabled;
    bool public bpDisabledForever;

    constructor() ERC20("Koakuma", "KKMA") {
        _mint(msg.sender, 1000000000 * 10**decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setBPContract(address addr) public onlyOwner {
        require(addr != address(0), "BP address cannot be 0x0");

        bpContract = IBPContract(addr);
    }

    function setBPEnabled(bool enabled) public onlyOwner {
        bpEnabled = enabled;
    }

    function setBPDisableForever() public onlyOwner {
        require(!bpDisabledForever, "Bot protection disabled");

        bpDisabledForever = true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        if (bpEnabled && !bpDisabledForever) {
            bpContract.protect(from, to, amount);
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}