// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract CTAC is ERC721A, Ownable {

    string  public baseTokenURI;
    string  public defaultTokenURI;
    uint256 public maxSupply;
    uint256 public publicSalePrice = 0.004 ether;
    uint256 public allowlistSalePrice = 0.006 ether;
    address payable public payMent;
    bytes32 private _merkleRoot;

    constructor(
        string memory _baseTokenURI,
        uint256 _maxSupply
    ) ERC721A ("Crazy Thursday Ape Club", "CTAC") {
        payMent = payable(msg.sender);
        baseTokenURI = _baseTokenURI;
        maxSupply = _maxSupply;
        _safeMint(_msgSender(), 1);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Must from real wallet address");
        _;
    }

    function mint(uint256 _quantity) external   payable {
        require(publicMintStatus == EPublicMintStatus.PUBLIC_MINT, "Public sale closed");
        require(_quantity <= 5, "Invalid quantity");
        require(totalSupply() + _quantity <= maxSupply, "Exceed supply");
        require(msg.value >= _quantity*publicSalePrice, "Ether is not enough");
        if (msg.value > 0) {
            (bool success,) = payMent.call{value : msg.value}("");
            require(success, "Transfer failed.");
        }

        _safeMint(msg.sender, _quantity);
    }


    function allowListMint(bytes32[] calldata merkleProof, uint256 _quantity) external  payable {
        require(publicMintStatus == EPublicMintStatus.ALLOWLIST_MINT || publicMintStatus == EPublicMintStatus.PUBLIC_MINT, "Allowlist sale closed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, _merkleRoot, leaf), "Invalid merkle proof");
        require(_quantity <= 5, "Invalid quantity");

        require(msg.value >= _quantity*allowlistSalePrice, "Ether is not enough");
        if (msg.value > 0) {
            (bool success,) = payMent.call{value : msg.value}("");
            require(success, "Transfer failed.");
        }

        _safeMint(msg.sender, _quantity);
    }


    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : defaultTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setDefaultURI(string calldata _defaultURI) external onlyOwner {
        defaultTokenURI = _defaultURI;
    }

    function setPublicPrice(uint256 mintprice) external onlyOwner {
        publicSalePrice = mintprice;
    }

    function setPublicMintStatus(uint256 status) external onlyOwner {
        publicMintStatus = EPublicMintStatus(status);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function devMint(address[] memory marketmintaddress, uint256[] memory mintquantity) public payable callerIsUser onlyOwner {
        for (uint256 i = 0; i < marketmintaddress.length; i++) {
            require(totalSupply() + mintquantity[i] <= maxSupply, "Exceed supply");
            _safeMint(marketmintaddress[i], mintquantity[i]);
        }
    }

    function withdrawMoney() external onlyOwner {
        (bool success,) = payMent.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }

    enum EPublicMintStatus {
        NOTACTIVE,
        ALLOWLIST_MINT,
        PUBLIC_MINT,
        CLOSED
    }

    EPublicMintStatus public publicMintStatus;
}