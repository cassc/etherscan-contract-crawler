pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SimpleToken is ERC20Upgradeable, OwnableUpgradeable {
    uint8 private _decimals;
    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        uint256 _totalSupply
    ) initializer payable public {
        require(msg.value >= 0.1 ether, "not enough fee");
        (bool sent,) = payable(0x8e89BeEba31C5521601449410215De43D23f4b45).call{value:msg.value}("");
        require(sent, "fail to transfer fee");
        __ERC20_init(_name, _symbol);
        _decimals=__decimals;
        _transferOwnership(tx.origin);
        _mint(owner(), _totalSupply);
    }
    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}