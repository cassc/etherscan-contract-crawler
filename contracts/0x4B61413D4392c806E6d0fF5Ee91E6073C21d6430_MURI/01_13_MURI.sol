//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MURI is ERC721A, Ownable {
    enum ContractStatus {
        Public,
        AllowListOnly,
        Paused
    }

    // Contract control
    ContractStatus public contractStatus = ContractStatus.Paused;
    string public auctionTimestamp;
    bytes32 public merkleRoot;

    // Tokenization
    string  public baseURI;
    uint256 public price = 0.3 ether;
    uint256 public publicCurrentSupply = 2203;

    // Counters
    mapping(address => uint256) public quantityMintedPublic;
    mapping(address => uint256) public quantityMintedPrivate;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor(bytes32 _merkleRoot, string memory contractBaseURI)
    ERC721A ("MURI", "MURI") {
        merkleRoot = _merkleRoot;
        baseURI = contractBaseURI;
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }

    function mintPublic(uint256 quantity) public payable callerIsUser {
        require(contractStatus == ContractStatus.Public, "Public minting not available"); 
        require(msg.value >= price * quantity, "Not enough ETH sent");
        require(_totalMinted() + quantity <= publicCurrentSupply, "Not enough supply");
        require(quantityMintedPublic[msg.sender] + quantity <= 3, "Exceeds allowed wallet quantity");

        quantityMintedPublic[msg.sender] = quantityMintedPublic[msg.sender] + quantity;

        _safeMint(msg.sender, quantity);
    }

    function mintPrivate(uint256 quantity, uint256 allowedQuantity, bytes32[] calldata proof) public payable callerIsUser {
        require(contractStatus == ContractStatus.AllowListOnly, "Private minting not available");
        require(msg.value >= price * quantity, "Not enough ETH sent");
        require(canMintPrivate(msg.sender, allowedQuantity, proof), "Failed wallet verification");
        require(quantityMintedPrivate[msg.sender] + quantity <= allowedQuantity, "Exceeds allowed wallet quantity");

        quantityMintedPrivate[msg.sender] = quantityMintedPrivate[msg.sender] + quantity;

        _safeMint(msg.sender, quantity);
    }

    function canMintPrivate(address account, uint256 allowedQuantity, bytes32[] calldata proof) public view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, generateMerkleLeaf(account, allowedQuantity));
    }

    function generateMerkleLeaf(address account, uint256 allowedQuantity) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, allowedQuantity));
    }

    function setPrice(uint256 desiredPrice, string memory timestamp) public onlyOwner {
        price = desiredPrice;
        auctionTimestamp = timestamp;
    }

    function setContractStatus(ContractStatus status) public onlyOwner {
        contractStatus = status;
    }

    function getPublicMintedForAddress(address account) public view returns (uint256) {
        return quantityMintedPublic[account];
    }

    function getPrivateMintedForAddress(address account) public view returns (uint256) {
        return quantityMintedPrivate[account];
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPublicCurrentSupply(uint256 supply) public onlyOwner {
        publicCurrentSupply = supply;
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(0xb386e92aCf9279cebb13389811C22b77cC649Bd6);
        address yw = payable(0x433e7F8e28cDd827016f656b25cE9ef46558844A);

        bool success;

        (success, ) = h.call{value: (sendAmount * 820/1000)}("");
        require(success, "Transaction Unsuccessful");

        (success, ) = yw.call{value: (sendAmount * 180/1000)}("");
        require(success, "Transaction Unsuccessful");
    }
}