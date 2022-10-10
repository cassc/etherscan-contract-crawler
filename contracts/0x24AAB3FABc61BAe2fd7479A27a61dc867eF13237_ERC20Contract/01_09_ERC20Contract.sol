// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract ERC20Contract is ERC20, Ownable, PaymentSplitter {

    bool public supplyLock;
    uint256 public maxSupply;
    mapping(address => bool) public allowlist;

    constructor(
        string memory _name,
        string memory _symbol,
        address[] memory _payees,
        uint256[] memory _shares,
        address _owner
    ) ERC20(_name, _symbol) PaymentSplitter(_payees, _shares) {
        transferOwnership(_owner);
    }

    modifier onlyAllowlist() {
        require(allowlist[msg.sender], "Not authorized");
        _;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(!supplyLock, "Supply is locked");
        maxSupply = _maxSupply;
    }

    function addToAllowlist(address _address) public onlyOwner {
        allowlist[_address] = true;
    }

    function removeFromAllowlist(address _address) public onlyOwner {
        delete allowlist[_address];
    }

    function burn(address _from, uint256 _amount) public onlyAllowlist {
        _burn(_from, _amount * (10**18));
    }

    function mint(address _to, uint256 _amount) public onlyAllowlist {
        require(totalSupply() + _amount * (10**18) <= maxSupply * (10**18), "Insufficient supply");
        _mint(_to, _amount * (10**18));
    }

    function lockSupply() public onlyOwner {
        supplyLock = true;
    }
}