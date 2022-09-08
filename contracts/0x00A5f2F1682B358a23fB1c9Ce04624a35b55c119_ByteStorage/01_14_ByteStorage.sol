// SPDX-License-Identifier: MIT
// Code By: Justin Taylor & Christian Perkins, YaoBin T
// Email: [email protected]
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract ByteStorage is ERC1155, Ownable, ERC1155Supply {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    uint256 public price = 0.15 ether;
    uint256 public maxSupply = 12000;
    uint256 public currentID = 0;
    uint256 public maxPerTx = 1;

    address public dev1;
    address public dev2;
    address public dev3;

    // keeps track of how many were minted per wallet
    mapping(address => uint256) public purchaseTxs;


    EnumerableSet.AddressSet private _addresses;

    constructor(address _dev1, address _dev2, address _dev3)
        ERC1155("ipfs://QmZ967NQWvpST1Ah2Gy8A17GxpMp9zAAWtAyHmUqAhGPfn/") {
            dev1 = _dev1;
            dev2 = _dev2;
            dev3 = _dev3;        
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI: nonexistent token");

        return
            string(
                abi.encodePacked(super.uri(_id), Strings.toString(_id), ".json")
            );
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setCurrentID(uint256 _currentID) external onlyOwner {
        currentID = _currentID;
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function mint() public payable {
        require(msg.value >= price, " The price recived in invaild"); // requires the msg.value to be equal to the price the price is a gloabl Var//
        require(totalSupply(currentID) + 1 <= maxSupply, "Max Supply Reached");
        require(purchaseTxs[msg.sender] + 1 <= maxPerTx, "Wallet Mint Limit");

        uint256 devAmount = msg.value.mul(8).div(30);
        // send coin to dev1
        (bool dev1Result, ) = payable(dev1).call{value: devAmount}("");
        require(dev1Result, "Failed to send fee to dev1");

        // send coin to dev2
        (bool dev2Result, ) = payable(dev2).call{value: devAmount}("");
        require(dev2Result, "Failed to send fee to dev2");

        // send coin to dev3
        (bool dev3Result, ) = payable(dev3).call{value: devAmount}("");
        require(dev3Result, "Failed to send fee to dev3");


        _mint(msg.sender, currentID, 1, "");
        _addresses.add(msg.sender);
        purchaseTxs[msg.sender] += 1;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function isMinted(address account_) public view returns (bool) {
        return _addresses.contains(account_);
    }

    function withdraw(address _addr) external onlyOwner {
        // This function is to pay out the owner of the contract funds from the main contract.
        uint256 balance = address(this).balance;
        payable(_addr).transfer(balance); // ETh address of the contract owner
    }
}