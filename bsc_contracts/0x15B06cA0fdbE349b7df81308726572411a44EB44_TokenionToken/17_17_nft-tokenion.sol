// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./depo-tokenion.sol";

contract TokenionToken is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {

    string private _name;
    string private _symbol;

    address[] public _depositContract;
    mapping(address => bool) public allowedAddresses;
    bool _blockedTransfer;

    constructor(string memory name_, string memory symbol_) ERC1155("https://dars.one/{id}.jpg") {
        _blockedTransfer = true;
        allowedAddresses[owner()] = true;
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setAllowedAddresses(address a) public onlyOwner {
        allowedAddresses[a] = true;
    }

    function setDepositContract(address depositContract) public onlyOwner {
        _depositContract.push(depositContract);
        allowedAddresses[depositContract] = true;
    }

    function blockedTransfer() public onlyOwner {
        _blockedTransfer = !_blockedTransfer;
    }

    function getBlockedTransfer() public view returns(bool) {
        return _blockedTransfer;
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        TokenionDeposit(_depositContract[id]).setTotalSupply(amount);
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        if(!allowedAddresses[from] && !allowedAddresses[to]){
            require(!_blockedTransfer, "Transfers are not possible at the moment!");
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}