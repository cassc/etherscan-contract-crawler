// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Metablizzard is ERC721Enumerable, ERC721Burnable, Ownable, ReentrancyGuard {

    uint256 public constant AIRDROPPED_UNLOCK_TIME = 1664971200;
    bytes32 public immutable WHITELIST_MERKLE_ROOT;
    bytes32 public immutable AIRDROP_MERKLE_ROOT;

    uint256 public totalIDs;

    uint16[2] public TOTAL_AMOUNTS = [772, 5];
    uint16[2] public sold;

    uint256[2] public price = [80000000000000000, 3000000000000000000];

    bool public publicSaleStarted;
    bool public baseURILocked;

    mapping(address => bool) public receivedAirdrop;
    mapping(uint256 => bool) public wasReceivedInAirdrop;

    string private __baseURI;

    event Buy(address user, uint16 amount, uint256 totalIDs);
    event BuyDeck(address user, uint256 totalIDs);
    event Airdrop(address user, uint16 amount, uint256 totalIDs);

    constructor(string memory baseURI_, bytes32 _whitelistMerkleRoot, bytes32 _airdropMerkleRoot) ERC721("ColdPlaying card","CPC") {
        __baseURI = baseURI_;
        WHITELIST_MERKLE_ROOT = _whitelistMerkleRoot;
        AIRDROP_MERKLE_ROOT = _airdropMerkleRoot;
    }

    function getAirdrop(uint16 amount, bytes32[] calldata proof) external nonReentrant {
        require(publicSaleStarted, "Public sale not started yet");
        require(!receivedAirdrop[_msgSender()], "Already received airdrop");
        receivedAirdrop[_msgSender()] = true;
        require(MerkleProof.verify(proof, AIRDROP_MERKLE_ROOT, keccak256(abi.encodePacked(_msgSender(), amount))), "Not allegible for airdrop");
        for (uint16 i; i < amount; i++) {
            _safeMint(_msgSender(), totalIDs);
            wasReceivedInAirdrop[totalIDs] = true;
            totalIDs++;
        }
        emit Airdrop(_msgSender(), amount, totalIDs);
    }

    function buy(uint16 amount, bytes32[] calldata proof) external payable nonReentrant {
        require(publicSaleStarted || MerkleProof.verify(proof, WHITELIST_MERKLE_ROOT, keccak256(abi.encodePacked(_msgSender()))), "Public sale not started yet");
        sold[0] += amount;
        require(sold[0] <= TOTAL_AMOUNTS[0], "Collection exhausted");
        require(msg.value == price[0] * amount, "Wrong payment amount");
        for (uint16 i; i < amount; i++) {
            _safeMint(_msgSender(), totalIDs);
            totalIDs++;
        }
        emit Buy(_msgSender(), amount, totalIDs);
    }

    function buyDeck(bytes32[] calldata proof) external payable nonReentrant {
        require(publicSaleStarted || MerkleProof.verify(proof, WHITELIST_MERKLE_ROOT, keccak256(abi.encodePacked(_msgSender()))), "Public sale not started yet");
        sold[1]++;
        require(sold[1] <= TOTAL_AMOUNTS[1], "Collection exhausted");
        require(msg.value == price[1], "Wrong payment amount");
        for (uint16 i; i < 36; i++) {
            _safeMint(_msgSender(), totalIDs);
            totalIDs++;
        }
        emit BuyDeck(_msgSender(), totalIDs);
    }

    function startPublicSale() external onlyOwner {
        publicSaleStarted = true;
    }

    function setPrice(uint256[2] calldata _price) external onlyOwner {
        price = _price;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        require(!baseURILocked, "URI already locked");
        __baseURI = baseURI_;
    }

    function lockBaseURI() external onlyOwner {
        baseURILocked = true;
    }

    function getETH() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return ERC721Enumerable.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        require(block.timestamp >= AIRDROPPED_UNLOCK_TIME || !wasReceivedInAirdrop[tokenId], "Airdropped token unlock time not passed yet");
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }
}