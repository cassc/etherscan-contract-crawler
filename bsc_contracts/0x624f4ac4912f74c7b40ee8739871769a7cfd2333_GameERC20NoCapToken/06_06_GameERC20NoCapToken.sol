//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract GameERC20NoCapToken is ERC20Upgradeable {
    address public owner;

    mapping(address => bool) public blackList;

    constructor() {}

    function initialize(
        string memory name_,
        string memory symbol_,
        address owner_
    ) external initializer {
        // initialize inherited contracts
        __ERC20_init(name_, symbol_);
        owner = owner_;
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function lockAddress(address haker) public onlyOwner {
        blackList[haker] = true;
    }

    function unLockAddress(address haker) public onlyOwner {
        blackList[haker] = false;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal view override {
        require(!blackList[from], "black list error");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }
}