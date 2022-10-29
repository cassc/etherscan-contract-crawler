// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./MerkleProof.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract DistortionGames is Ownable, ERC721A, ReentrancyGuard {
    
    uint256 private _publicPrice = 0.025 ether;
    uint256 private _presalePrice = 0.02 ether;
    uint256 private _maxPurchaseDuringWhitelist = 2;
    uint256 private _maxPurchaseDuringPublic = 5;
    uint256 private _maxPerTransaction = 10;
    uint256 private _maxMint = 3500;
    address private _team = 0xfA0a865E07385C55516C7a6f069Ba82AACB109fa;
    bytes32 public merkleRoot = 0xb219a2592b5ab2fa34ba206de030ead9f78457f8574694b7e7f38c862317e532;
    mapping(address => uint256) public presaleAddressMintCount;
    bool public isPaused = false;
    bool public isPublicMint = false;
    bool public isWhitelistMint = false;

    string private _tokenURI = "https://distortiongames.xyz/api/metadata/";

    constructor() ERC721A("Distortion Games", "DISTORT", _maxPerTransaction, _maxMint) {}

    function checkIsPublicMint () external view returns (bool) {
        return isPublicMint;
    }

    function setMax (uint256 wl, uint256 transac) external onlyOwner {
        _maxPurchaseDuringWhitelist = wl;
        _maxPurchaseDuringPublic = transac;
    }

    function setPaused(bool value) external onlyOwner {
        isPaused = value;
    }

    function getPublicPrice() external view returns (uint256) {
        return _publicPrice;
    }

    function setPublicMint (bool value) external onlyOwner {
        isPublicMint = value;
    }

    function setWhitelistMint (bool value) external onlyOwner {
        isWhitelistMint = value;
    }

    function setPresalePrice (uint256 price) external onlyOwner {
        _presalePrice = price;
    }

    function setPublicPrice (uint256 price) external onlyOwner {
        _publicPrice = price;
    }

    modifier mintGuard(uint256 tokenCount) {
        require(!isPaused, "Paused!");
        require(tokenCount > 0 && tokenCount <= _maxPerTransaction, "Max per transaction reached");
        require(msg.sender == tx.origin, "Sender not origin");
        // Price check
        if (isPublicMint) {
            require(_publicPrice * tokenCount <= msg.value, "Insufficient funds");
        } else {
            require(_presalePrice * tokenCount <= msg.value, "Insufficient funds");
        }
        require(totalSupply() + tokenCount <= _maxMint+1, "Sold out!");
        _;
    }

    function mint(uint256 amount) external payable mintGuard(amount) {
        require(isPublicMint, "Sale has not started!");
        _safeMint(msg.sender, amount);
    }

    function allowlistMint(bytes32[] calldata proof, uint256 amount) external payable mintGuard(amount) {
        require(isWhitelistMint, "Allowlist mint has not started!");
        require(presaleAddressMintCount[msg.sender] + amount <= _maxPurchaseDuringWhitelist, "Maximum allowlist quantity reached!");
        presaleAddressMintCount[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function cashout() external onlyOwner {
        payable(_team).transfer(address(this).balance);
    }

    function setCashout(address addr) external onlyOwner returns(address) {
        _team = addr;
        return addr;
    }

    function devMint(uint32 qty) external onlyOwner {
        _safeMint(msg.sender, qty);
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function setMaxMint(uint256 maxMint) external onlyOwner {
        _maxMint = maxMint;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _tokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenURI;
    }
}