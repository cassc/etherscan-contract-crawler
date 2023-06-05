// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EutToken is ERC20, Ownable {
    mapping(address => bool) public minter;
    uint256 public immutable cap;
    constructor(string memory name_, string memory symbol_, uint256  initialSupply_, address[] memory accounts_, uint256[] memory amounts_) ERC20(name_, symbol_) {
        require(accounts_.length == amounts_.length);
        uint256 totalAmount = 0;
        for (uint i = 0; i < amounts_.length; i++) {
            totalAmount += amounts_[i];
        }
        require(initialSupply_ >= totalAmount);
        cap = initialSupply_;
        for (uint i = 0; i < accounts_.length; i++) {
            _mint(accounts_[i], amounts_[i]);
        }
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function mint(address account, uint256 amount) external {
        require(minter[msg.sender]);
        require(amount + totalSupply() <= cap);
        _mint(account, amount);
    }

    function setMinter(address account, bool isMinter) external onlyOwner {
        minter[account] = isMinter;
    }
}