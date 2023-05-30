// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Flippr is ERC1155, Ownable, ERC1155Supply, ReentrancyGuard {
    string public name = "Flippr Access Pass";
    string public symbol = "FLIPPR";
    uint256 public salePrice = 0.12 ether;
    uint256 public presalePrice = 0.09 ether;
    uint16 public maxSupply = 6000;
    uint16 public maxFree = 726;

    uint16 public paidSupplyLeft = maxSupply - maxFree;
    uint16 public freeSupplyLeft = maxFree;

    //Reserves are minted automatically on contract deployment and subtracted from paidSupplyLeft.
    uint8 public reservedSupply = 50;

    bool public presaleActive;
    bool public freesaleActive;
    bool public saleActive;

    uint8 public passIndex = 0;

    bytes32 public whitelistMerkle = 0x30ba29d11095245cd6b652465c91a89b5ec7a8040863b6f569f3e1bf96446f0c;
    mapping (uint8 => bytes32) public freeMintTrees;

    mapping (address => bool) public _presaleMinted;
    mapping (address => bool) public _saleMinted;
    mapping (address => bool) public _freeMinted;

    constructor() ERC1155("ipfs://QmerHKcZLVTxN3Y7S7P2vo2XfN7dGHZnYDQcsrvubvHJKM") {
        require(freeSupplyLeft + paidSupplyLeft == maxSupply, "Invalid supply.");
        _mint(msg.sender, passIndex, reservedSupply, "");
        paidSupplyLeft -= reservedSupply;
        freeMintTrees[1] = 0x49b744a3683243c894be989fa12e12eacc93162f91ea8db62702e4984ad9bc45;
        freeMintTrees[2] = 0xa49ed1f4849311a6eef17262876ec61f0acab2631b1f3f034af1072e6e4183fa;
        freeMintTrees[3] = 0xdcbb5bfa3dfdd60b5eba95092d6460506cfaa23b9bcfdbe27a1aeda86e88bd5e;
        freeMintTrees[5] = 0x4e691dccd3de21b6694b0ae76ec163829d4a02a9cd53e1db4b0d4e9ad3d08e9d;
        //etc
    }

    // Mints

    function mint(bytes32[] calldata _merkleProof) public payable nonReentrant {
        require(presaleActive || saleActive, "Flippr: Sale is not live.");

        if (saleActive) { 
            require(msg.value >= salePrice, "Flippr: Insufficient tx value.");
            require(!_saleMinted[msg.sender], "Flippr: You cannot mint more than 1 in the public sale.");
            require(paidSupplyLeft > 0, "Flippr: Exceeds available supply.");
            _mint(msg.sender, passIndex, 1, "");
            _saleMinted[msg.sender] = true;
            paidSupplyLeft -= 1;
        } else if (presaleActive) {
            require(msg.value >= presalePrice, "Flippr: Insufficient tx value.");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            //Check sender will only have 1 total presale mint.
            require(!_presaleMinted[msg.sender], "Flippr: You cannot mint more than 1 in the presale.");
            //Check sender is on whitelist.
            require(MerkleProof.verify(_merkleProof, whitelistMerkle, leaf), "Flippr: Invalid proof (not on whitelist?).");
            //Check there is enough remaining from the paid supply.
            require(paidSupplyLeft > 0, "Flippr: Exceeds available supply.");
            _mint(msg.sender, passIndex, 1, "");
            _presaleMinted[msg.sender] = true;
            paidSupplyLeft -= 1;
        }
    }

    function freeMint(uint8 _count, bytes32[] calldata _merkleProof) public nonReentrant {
        //Check free mint has started.
        require(freesaleActive, "Flippr: The free mint has not started.");
        //Check allowed to mint the requested amount.
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, freeMintTrees[_count], leaf), "Flippr: Invalid proof (not on whitelist?).");
        //Check not already claimed.
        require(!_freeMinted[msg.sender], "Flippr: You have already claimed your free mint.");
        //Check remaining supply. Shouldn't fail ever.
        require(freeSupplyLeft > 0, "Flippr: There is insufficient remaining free supply.");
        _mint(msg.sender, passIndex, _count, "");
        _freeMinted[msg.sender] = true;
        freeSupplyLeft -= _count;
    }

    // Write functions

    function setPresaleStatus(bool _presaleActive) public onlyOwner {
        presaleActive = _presaleActive;
    }

    function setFreesaleStatus(bool _presaleActive) public onlyOwner {
        freesaleActive = _presaleActive;
    }

    function setSaleStatus(bool _saleActive) public onlyOwner {
        saleActive = _saleActive;
    }

    function setSalePrice(uint256 _price) public onlyOwner {
        salePrice = _price;
    }

    function setPresalePrice(uint256 _price) public onlyOwner {
        presalePrice = _price;
    }

    function setWhitelistMerkle(bytes32 _merkleRoot) public onlyOwner {
        whitelistMerkle = _merkleRoot;
    }

    function setFreeMerkle(uint8 _count, bytes32 _merkleRoot) public onlyOwner {
        freeMintTrees[_count] = _merkleRoot;
    }

    function transferFreeSupply() public onlyOwner {
        paidSupplyLeft += freeSupplyLeft;
        freeSupplyLeft = 0;
    }

    function changePaidSupplyLeft(uint16 _paidSupplyLeft) public onlyOwner {
        paidSupplyLeft = _paidSupplyLeft;
    }

    function changeFreeSupplyLeft(uint16 _freeSupplyLeft) public onlyOwner {
        freeSupplyLeft = _freeSupplyLeft;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Call functions

    function hasToken(address account) public view returns (bool) {
        return balanceOf(account, passIndex) > 0;
    }

    function getSalePrice() public view returns (uint256) {
        return salePrice;
    }

    function getPresalePrice() public view returns (uint256) {
        return presalePrice;
    }

    function getPaidSupplyLeft() public view returns (uint16) {
        return paidSupplyLeft;
    }

    function getFreeSupplyLeft() public view returns (uint16) {
        return freeSupplyLeft;
    }

    function getMaxSupply() public view returns (uint16) {
        return maxSupply;
    }

    function getWhitelistMerkle() public view returns (bytes32) {
        return whitelistMerkle;
    }

    function getFreeMerkle(uint8 _count) public view returns (bytes32) {
        return freeMintTrees[_count];
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function totalSupply() external view returns (uint256) {
        return totalSupply(passIndex);
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