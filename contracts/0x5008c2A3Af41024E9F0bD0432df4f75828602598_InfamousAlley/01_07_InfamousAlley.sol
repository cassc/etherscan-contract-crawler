// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * Infamous Alley
 * Dare to Rise Above
 * Be Infamous
 */

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

contract InfamousAlley is ERC721A, Ownable {

    using Strings for uint256;

//  ==========================================
//  ============= THE S.T.A.T.E ==============
//  ==========================================

    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public constant BOOST_PRICE = 0.025 ether;

    uint256 public price = 0.035 ether;
    uint256 public presalePrice = 0.025 ether;
    
    uint256 public maxPerTxn = 2;
    uint256 public recruitAllowance = 2;
    uint256 public mintPhase;

    string public baseURI;

    bytes32 public allowlistRoot;

    bool public paused;
    bool public revealed;

    mapping(uint256 => uint256) public tokenBoosts;


//  ==========================================
//  ==== SECURITY CLEARANCE VERIFICATION  ====
//  ==========================================

    modifier verifySTATE(uint256 _amount) {
        require(_totalMinted() + _amount <= MAX_SUPPLY, "Exceeds MAX_SUPPLY");
        _;
    }
    
    modifier unpaused() {
        require(!paused, "Paused");
        _;
    }


    constructor() ERC721A("Infamous", "INFM") {}

//  ==========================================
//  ======== RECRUITMENT APPLICATIONS ========
//  ==========================================

    function recruitMint(uint64 quantity, bytes32[] calldata proof, uint256 boosts) external payable verifySTATE(quantity) unpaused {
        require(mintPhase == 1, "Recruitment not active");
        require(quantity + _numberMinted(msg.sender) <= recruitAllowance, "Allowance exceeded.");
        require(boosts < 4, "The STATE does not tolerate those who do not follow the rules.");
        require((quantity * (presalePrice * (boosts + 1))) == msg.value, "Insufficient Dues - Incorrect ETH amount");
        require(_verifyRecruitStatus(proof), "Recruitment Status Unclear - Proof Invalid");
        if (boosts != 0) {
            for (uint256 i; i < quantity; i++) {
                uint256 next = _currentIndex + i;
                tokenBoosts[next] = boosts;
                }
        }
        _mint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity, uint256 boosts) external payable verifySTATE(quantity) unpaused {
        require(mintPhase == 2, "Public sale not active");
        require(quantity <= maxPerTxn, "Quantity too high.");
        require(boosts < 4, "The STATE does not tolerate those who do not follow the rules.");
        require(((quantity * price) + (BOOST_PRICE * boosts)) == msg.value, "Insufficient Dues - Incorrect ETH amount");
        _mint(msg.sender, quantity);
    }


//  ==========================================
//  ====== TOP SECURITY CLEARANCE ONLY =======
//  ==========================================

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setRevealed(bool status) external onlyOwner {
        revealed = status;
    }

    function adminMint(address[] calldata to, uint256[] calldata quantity) external onlyOwner {
        require(to.length == quantity.length, "Array length mismatch");
        for (uint256 i = 0; i < to.length; i++) {
            require(totalSupply() + quantity[i] <= MAX_SUPPLY);
            _mint(to[i], quantity[i]);
        }
    }

    function changePhase(uint256 _phase) external onlyOwner {
        mintPhase = _phase;
    }

    function promoteRecruit(uint256 tokenId, uint256 boost) external onlyOwner {
        tokenBoosts[tokenId] = boost;
    }

    function stopRecruitment(bool _status) external onlyOwner {
        paused = _status;
    }

    function setAllowlistRoot(bytes32 root) external onlyOwner {
        allowlistRoot = root;
    }

    function adjustRecruitAllowance(uint256 _allowance) external onlyOwner {
        recruitAllowance = _allowance;
    }

    function updatePrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

//  ==========================================
//  ======== S.T.A.T.E BUSINESS ONLY =========
//  ==========================================

    function _verifyRecruitStatus(bytes32[] calldata proof) internal view returns (bool) {
        return MerkleProof.verify(proof, allowlistRoot, keccak256(abi.encodePacked(msg.sender)));
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        if (revealed) return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
        else {
            uint256 tier = tokenBoosts[_tokenId] + 1;
            return string(abi.encodePacked(baseURI, Strings.toString(tier)));
        }
    }

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }
}