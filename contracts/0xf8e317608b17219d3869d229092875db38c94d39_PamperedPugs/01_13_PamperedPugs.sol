// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import '../ERC721AW.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract PamperedPugs is Ownable, ERC721AW, ReentrancyGuard {
    uint256 public constant mintLimit = 1;
    uint256 public constant teamAmt = 15;
    uint256 public constant auctionAmt = 5;
    uint256 public constant collectionSize = 345;

    struct SaleConfig {
        uint32 presaleStartTime;
        uint32 publicStartTime;
        uint64 presalePrice;
        uint64 publicPrice;
        bytes32 merkleRoot;
    }

    SaleConfig public saleConfig;

    constructor() ERC721AW('PugsNFT', 'PamperedPugs') {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, 'The caller is another contract');
        _;
    }

    function presaleMint(uint256 quantity, bytes32[] calldata proof) external payable callerIsUser {
        SaleConfig memory config = saleConfig;
        uint256 _presaleStartTime = uint256(config.presaleStartTime);
        uint256 _publicStartTime = uint256(config.publicStartTime);
        uint256 totalCost = uint256(config.presalePrice) * quantity;

        bool isPublicActive = _publicStartTime != 0 && block.timestamp >= _publicStartTime;

        require(_presaleStartTime != 0 && !isPublicActive && block.timestamp >= _presaleStartTime, 'presale has not started yet');
        require(_totalMinted() + quantity <= collectionSize - auctionAmt, 'reached max supply');
        require(MerkleProof.verify(proof, config.merkleRoot, keccak256(abi.encodePacked(msg.sender))), 'invalid merkle proof supplied');
        require(_numberPresaleMinted(msg.sender) + quantity <= mintLimit, 'exceeded mint limit for presale');

        _safeMint(msg.sender, quantity, false);
        refundIfOver(totalCost);
    }

    function publicMint(uint256 quantity) external payable callerIsUser {
        uint256 totalCost = uint256(saleConfig.publicPrice) * quantity;
        uint256 _publicStartTime = uint256(saleConfig.publicStartTime);

        require(_publicStartTime != 0 && block.timestamp >= _publicStartTime, 'public sale has not started yet');
        require(_totalMinted() + quantity <= collectionSize - auctionAmt, 'reached max supply');
        require(_numberPublicMinted(msg.sender) + quantity <= mintLimit, 'exceeded mint limit for public sale');

        _safeMint(msg.sender, quantity, true);
        refundIfOver(totalCost);
    }

    // For team, auctions, etc.
    function devMint(uint256 quantity) external onlyOwner {
        require(_totalMinted() + quantity <= teamAmt, 'too many already minted before dev mint');
        _safeMint(msg.sender, quantity, true);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, 'Need to send more ETH.');
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function setSaleConfig(
        uint32 _presaleStartTime,
        uint32 _publicStartTime,
        uint64 _presalePrice,
        uint64 _publicPrice,
        bytes32 _merkleRoot
    ) external onlyOwner {
        saleConfig = SaleConfig(
            _presaleStartTime, 
            _publicStartTime, 
            _presalePrice, 
            _publicPrice, 
            _merkleRoot
        );
    }

    function setStartTimes(uint32 _presaleStartTime, uint32 _publicStartTime) external onlyOwner {
        saleConfig.presaleStartTime = _presaleStartTime;
        saleConfig.publicStartTime = _publicStartTime;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        saleConfig.merkleRoot = _merkleRoot;
    }

    // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}('');
        require(success, 'Transfer failed.');
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }
}