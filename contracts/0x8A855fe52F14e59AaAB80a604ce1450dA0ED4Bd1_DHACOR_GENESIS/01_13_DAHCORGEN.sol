// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./utils/Ownable.sol";
import "./utils/strings.sol";

contract DHACOR_GENESIS is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public constant maxMintSupply = 300;
    uint256 public constant mintPrice = 0.15 ether;
    uint256 public constant refundPeriod = 3 days;

    // Sale Status
    bool public publicSaleActive;
    bool public presaleActive;
    uint256 public refundEndTime;
    string public uriSuffix = ".json";

    address public refundAddress;
    uint256 public constant maxUserMintAmount = 10;
    bytes32 public merkleRoot;

    mapping(uint256 => bool) public hasRefunded; // users can search if the NFT has been refunded
    mapping(uint256 => bool) public isOwnerMint; // if the NFT was freely minted by owner

    string private baseURI;

    constructor() ERC721A("DAHCOR GENESIS", "DAHCORGEN") {
        refundAddress = msg.sender;
        toggleRefundCountdown();
    }

    function preSaleMint(uint256 quantity, bytes32[] calldata proof) external payable {
        require(presaleActive, "Presale is not active");
        require(msg.value == quantity * mintPrice, "Value");
        require(_isAllowlisted(msg.sender, proof, merkleRoot), "Not on allow list");
        require(_numberMinted(msg.sender) + quantity <= maxUserMintAmount, "Max amount");
        require(totalSupply() + quantity <= maxMintSupply, "Max mint supply");

        _safeMint(msg.sender, quantity);
    }

    function publicSaleMint(uint256 quantity) external payable {
        require(publicSaleActive, "Public sale is not active");
        require(msg.value >= quantity * mintPrice, "Not enough eth sent");
        require(_numberMinted(msg.sender) + quantity <= maxUserMintAmount, "Over mint limit");
        require(totalSupply() + quantity <= maxMintSupply, "Max mint supply reached");

        _safeMint(msg.sender, quantity);
    }

    function ownerMint(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= maxMintSupply, "Max mint supply reached");
        _safeMint(msg.sender, quantity);

        for (uint256 i = currentIndex - quantity; i < currentIndex; i++) {
            isOwnerMint[i] = true;
        }
    }

    function refund(uint256[] calldata tokenIds) external {
        require(isRefundGuaranteeActive(), "Refund expired");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(msg.sender == ownerOf(tokenId), "Not token owner");
            require(!hasRefunded[tokenId], "Already refunded");
            require(!isOwnerMint[tokenId], "Freely minted NFTs cannot be refunded");
            hasRefunded[tokenId] = true;
            transferFrom(msg.sender, refundAddress, tokenId);
        }

        uint256 refundAmount = tokenIds.length * mintPrice;
        Address.sendValue(payable(msg.sender), refundAmount);
    }

    function getRefundGuaranteeEndTime() public view returns (uint256) {
        return refundEndTime;
    }

    function isRefundGuaranteeActive() public view returns (bool) {
        return (block.timestamp <= refundEndTime);
    }

    function withdraw() external onlyOwner {
        require(block.timestamp > refundEndTime, "Refund period not over");
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setRefundAddress(address _refundAddress) external onlyOwner {
        refundAddress = _refundAddress;
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function toggleRefundCountdown() public onlyOwner {
        refundEndTime = block.timestamp + refundPeriod;
    }

    function togglePresaleStatus() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function togglePublicSaleStatus() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function _leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
                : "";
    }

    function _isAllowlisted(address _account, bytes32[] calldata _proof, bytes32 _root) internal pure returns (bool) {
        return MerkleProof.verify(_proof, _root, _leaf(_account));
    }
}