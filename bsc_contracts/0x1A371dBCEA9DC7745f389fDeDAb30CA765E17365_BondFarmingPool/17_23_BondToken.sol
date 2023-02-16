// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BondToken is ERC20, Ownable {
    address public minter;
    uint256 public constant MINIMUM_SUPPLY = 10**3;

    modifier onlyMinter() {
        require(minter == msg.sender, "Minter only");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address minter_
    ) ERC20(name_, symbol_) Ownable() {
        minter = minter_;
    }

    function setMinter(address minter_) public onlyOwner {
        require(minter_ != address(0), "Cant set minter to zero address");
        minter = minter_;
    }

    function mint(address to_, uint256 amount_) external onlyMinter {
        require(amount_ > 0, "Nothing to mint");
        if (totalSupply() == 0) {
            // permanently lock the first MINIMUM_SUPPLY tokens
            _mint(minter, MINIMUM_SUPPLY);
        }
        _mint(to_, amount_);
    }

    function burnFrom(address account_, uint256 amount_) external onlyMinter {
        require(amount_ > 0, "Nothing to burn");
        _burn(account_, amount_);
    }
}