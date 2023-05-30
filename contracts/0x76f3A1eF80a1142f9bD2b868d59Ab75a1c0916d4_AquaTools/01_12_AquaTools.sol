// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract AquaTools is ERC1155, Ownable, ERC1155Supply {
    uint256 public price = 0.1 ether;
    uint16 public maxSupply = 3000;
    uint16 public supplyLeft = maxSupply;
    uint8 public reservedSupply = 200;
    bool public presaleActive;
    bool public saleActive;
    uint8 public presaleMaxMintsPerTrans = 1;
    uint8 public publicMaxMintsPerTrans = 3;
    uint8 public passIndex = 0;
    bytes32 public merkleRoot =
        0x9492a15aa69d55a18e1181ac3b84b971ef9799e23b284f144961474af08621d9;

    mapping(address => bool) public whitelistClaimed;

    constructor()
        ERC1155("ipfs://QmTF8cSSv5Ewexo4TMU8Wg1MqEwXHfLVxYkuhy7GzwSU6U")
    {
        _mint(msg.sender, passIndex, reservedSupply, "");

        supplyLeft -= reservedSupply;
    }

    // Write functions

    function setPresaleStatus(bool _presaleActive) public onlyOwner {
        presaleActive = _presaleActive;
    }

    function setSaleStatus(bool _saleActive) public onlyOwner {
        saleActive = _saleActive;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Read functions

    function hasToken(address account) public view returns (bool) {
        return balanceOf(account, passIndex) > 0;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function getSupplyLeft() public view returns (uint16) {
        return supplyLeft;
    }

    function getMaxSupply() public view returns (uint16) {
        return maxSupply;
    }

    function getMerkleRoot() public view returns (bytes32) {
        return merkleRoot;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Mint

    function mintPresale(
        address account,
        uint8 amount,
        bytes32[] calldata _merkleProof
    ) public payable {
        require(msg.value >= amount * price, "Wrong amount sent");
        require(presaleActive, "Sale is not active");
        require(amount > 0, "Amount must be positive integer");
        require(
            totalSupply(passIndex) + amount <= maxSupply,
            "Purchase would exceed max supply"
        );
        require(!whitelistClaimed[msg.sender], "Address has already claimed");
        require(amount <= presaleMaxMintsPerTrans, "Only 1 mint allowed");

        bytes32 leaf = keccak256(abi.encodePacked(account));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof"
        );

        _mint(account, passIndex, amount, "");
        whitelistClaimed[msg.sender] = true;

        supplyLeft -= amount;
    }

    function mint(address account, uint8 amount) public payable {
        require(msg.value >= amount * price, "Wrong amount sent");
        require(saleActive, "Sale is not active");
        require(amount > 0, "Amount must be positive integer");
        require(
            totalSupply(passIndex) + amount <= maxSupply,
            "Purchase would exceed max supply"
        );
        require(amount <= publicMaxMintsPerTrans, "Only 3 mints allowed");

        _mint(account, passIndex, amount, "");

        supplyLeft -= amount;
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

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}