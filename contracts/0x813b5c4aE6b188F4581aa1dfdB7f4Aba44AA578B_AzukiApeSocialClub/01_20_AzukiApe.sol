//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./lib/ERC721A.sol";
import "./lib/Allowlist.sol";

contract AzukiApeSocialClub is ERC721A, Allowlist, PaymentSplitter, Ownable, Pausable, ReentrancyGuard {
    uint private constant MAX_SUPPLY = 3333;
    uint private constant MAX_PER_TX = 5;

    uint public price;
    uint public wlPrice;

    // Metadata
    string internal _tokenURI;

    mapping(address => uint) private claimed;

    constructor (
        string memory __tokenURI,
        uint _price,
        uint _wlPrice,
        address[] memory payees,
        uint256[] memory shares
    ) ERC721A("AzukiApeSocialClub", "AASC", MAX_PER_TX) 
    PaymentSplitter(payees, shares) {
        price = _price;
        wlPrice = _wlPrice;
        _tokenURI = __tokenURI;
    }

    function mint(uint amount, bytes32[] calldata proof) external payable whenNotPaused nonReentrant {
        require(amount > 0, "amount too little");
        require(totalSupply() + amount < MAX_SUPPLY + 2, "exceed max supply");

        if(requireAllowlist) {
            _whitelistMint(amount, proof);
        } else {
            _mint(amount);
        }
    }

    function _whitelistMint(uint amount, bytes32[] calldata proof) internal onlyAllowed(proof) {
        require(amount < 3, "amount can't exceed 2");
        require(claimed[msg.sender] < 2, "exceeded whitelist mint quota");
        require(msg.value == wlPrice * amount, "insufficient fund");
        claimed[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

    function _mint(uint amount) internal {
        require(amount < MAX_PER_TX + 1, "amount can't exceed 5");
        require(msg.value == price * amount, "insufficient fund");

        _safeMint(msg.sender, amount);
    }

    function airdrop(address wallet, uint256 amount) external onlyOwner {
        require(totalSupply() + amount < MAX_SUPPLY + 1, "exceed max supply");
        
        _safeMint(wallet, amount);
    }

    function owned(address owner) external view returns (uint256[] memory) {
        uint balance = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](balance);
        for(uint i = 0; i < balance; i++){
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    // Pausable
    function setPause(bool pause) external onlyOwner {
        if(pause) {
            _pause();
        } else {
            _unpause();
        }
    }

    // Allowlist
    function setRequireAllowlist(bool value) external onlyOwner {
        _setRequireAllowlist(value);
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        _setMerkleRoot(root);
    }

    // Minting fee
    function setPrice(uint amount) external onlyOwner {
        price = amount;
    }
    function setWLPrice(uint amount) external onlyOwner {
        wlPrice = amount;
    }
    function claim() external {
        release(payable(msg.sender));
    }

    // Metadata
    function setTokenURI(string calldata uri) external onlyOwner {
        _tokenURI = uri;
    }
    function baseTokenURI() external view returns (string memory) {
        return _tokenURI;
    }
    
    function tokenURI(uint256 _tokenId) external view override returns (string memory) {
        return string(abi.encodePacked(
            _tokenURI,
            "/",
            Strings.toString(_tokenId),
            ".json"
        ));
    }
}