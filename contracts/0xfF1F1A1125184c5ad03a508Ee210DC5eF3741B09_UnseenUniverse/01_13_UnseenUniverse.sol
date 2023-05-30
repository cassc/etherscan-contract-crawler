//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*************************************
*                                    *
*     developed by filet.digital      *
*        https://filet.digital        *
*                                    *
**************************************/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract UnseenUniverse is ERC721A, Ownable {
    enum ContractStatus {
        Public,
        MintList,
        Paused
    }

    // Contract control
    ContractStatus public contractStatus = ContractStatus.Paused;
    string public auctionTimestamp;
    bytes32 public merkleRoot;

    // Tokenization
    string  public baseURI;
    uint256 public price = 0.05 ether;
    uint256 public maxSupply = 7000;
    uint256 public publicSupply = 0;

    // Counters
    mapping(address => uint256) public quantityMintedPublic;
    mapping(address => uint256) public quantityMintedMintList;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor(bytes32 _merkleRoot, string memory contractBaseURI)
    ERC721A ("UNSEEN UNIVERSE", "UNSEEN UNIVERSE") {
        merkleRoot = _merkleRoot;
        baseURI = contractBaseURI;
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }

    function mint(uint256 quantity) external payable callerIsUser {
        require(contractStatus == ContractStatus.Public, "Public minting not available");
        require(msg.value >= price * quantity, "Not enough ETH sent");
        require(_totalMinted() + quantity <= publicSupply, "Not enough supply");
        require(quantityMintedPublic[msg.sender] + quantity <= 3, "Exceeds allowed wallet quantity");

        quantityMintedPublic[msg.sender] = quantityMintedPublic[msg.sender] + quantity;

        _safeMint(msg.sender, quantity);
    }

    function mintFromMintList(uint256 quantity, uint256 allowedQuantity, bytes32[] calldata proof) external payable callerIsUser {
        require(contractStatus == ContractStatus.MintList, "MintList sale not available");
        require(msg.value >= price * quantity, "Not enough ETH sent");
        require(_totalMinted() + quantity <= maxSupply, "Not enough supply");
        require(isWalletOnMintList(msg.sender, allowedQuantity, proof), "Wallet verification failed");
        require(quantityMintedMintList[msg.sender] + quantity <= allowedQuantity, "Exceeds allowed wallet quantity");

        quantityMintedMintList[msg.sender] = quantityMintedMintList[msg.sender] + quantity;

        _safeMint(msg.sender, quantity);
    }

    function isWalletOnMintList(address account, uint256 allowedQuantity, bytes32[] calldata proof) public view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, generateMerkleLeaf(account, allowedQuantity));
    }

    function generateMerkleLeaf(address account, uint256 allowedQuantity) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, allowedQuantity));
    }

    function setPrice(uint256 desiredPrice, string memory timestamp) external onlyOwner {
        price = desiredPrice;
        auctionTimestamp = timestamp;
    }

    function setContractStatus(ContractStatus status) external onlyOwner {
        contractStatus = status;
    }

    function getPublicMintedForAddress(address account) external view returns (uint256) {
        return quantityMintedPublic[account];
    }

    function getMintListMintedForAddress(address account) external view returns (uint256) {
        return quantityMintedMintList[account];
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPublicCurrentSupply(uint256 supply) external onlyOwner {
        publicSupply = supply;
    }

    function setMaxSupply(uint256 supply) external onlyOwner {
        maxSupply = supply;
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;

        address uno = payable(0xB528f5141d828b3e5c05040543E44389936ac523);

        bool success;

        (success,) = uno.call{value : (amount)}("");
        require(success, "Transaction Unsuccessful");
    }
}