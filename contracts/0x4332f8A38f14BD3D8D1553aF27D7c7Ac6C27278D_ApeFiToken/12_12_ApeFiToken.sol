// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";


contract ApeFiToken is Ownable, ERC20Permit {
    address public minter;

    event NewMinter(address oldMinter, address newMinter);

    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) ERC20Permit(name) {}

    function setMinter(address newMinter) public onlyOwner {
        address oldMinter = minter;
        minter = newMinter;
        emit NewMinter(oldMinter, newMinter);
    }

    /**
     * @notice See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must be `owner`.
     */
    function mint(address to, uint256 amount) public {
        require(_msgSender() == minter, "caller is not the minter");
        _mint(to, amount);
    }

    /**
     * @notice See {ERC20-_burn}.
     *
     * Requirements:
     *
     * - the caller must be `owner`.
     */
    function burn(uint256 amount) public onlyOwner {
        _burn(_msgSender(), amount);
    }
}