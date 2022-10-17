// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * Kaijira
 * ERC721A Mint
 * Merkle Tree Allowlist
 */

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

contract Kaijra is ERC721A, Ownable {
    using Strings for uint256;

    struct teamInfo {
        uint128 teamStatus;
        uint128 teamMint;
    }

    string public baseURI;

    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public price = 0.01 ether;
    uint256 public presalePrice = 0.01 ether;
    uint256 public maxTxn = 5;
    uint256 public presaleAllowance = 2;
    uint256 public phase;

    bytes32 public merkleRoot;

    bool public paused;

    mapping(address => teamInfo) public team;

    modifier controlMint(uint256 _amount) {
        require(_totalMinted() + _amount <= MAX_SUPPLY, "Kaijira: Exceeds MAX_SUPPLY");
        require(_amount <= maxTxn, "Kaijira: Exceeds maxTxn");
        _;
    }
    
    modifier notPaused() {
        require(!paused, "Kaijira: Paused");
        _;
    }

    /*
    ================================================
                    CONSTRUCTION        
    ================================================
*/

    constructor() ERC721A("Kaijira", "KJRA") {}

    /*
    ================================================
            Public/External Write Functions         
    ================================================
*/

    function teamMint(uint128 quantity) external payable controlMint(quantity) notPaused {
        require(quantity * presalePrice == msg.value, "Kaijira: Incorrect ETH amount");
        require(team[msg.sender].teamStatus != 0, "Kaijira: Not a team wallet");
        require(team[msg.sender].teamMint + quantity <= 3, "Kaijira: Exceed Allowance");
        team[msg.sender].teamMint = quantity + team[msg.sender].teamMint;
        _mint(msg.sender, quantity);
    }

    function allowlistMint(uint64 quantity, bytes32[] calldata proof) external payable controlMint(quantity) notPaused {
        require(quantity + _getAux(msg.sender) <= presaleAllowance, "Kaijira: Allowance exceeded.");
        require(phase == 1, "Kaijira: Presale not active");
        require(quantity * presalePrice == msg.value, "Kaijira: Incorrect ETH amount");
        require(_verifyProof(proof), "Kaijira: Invalid proof");
        _setAux(msg.sender, quantity + _getAux(msg.sender));
        _mint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable controlMint(quantity) notPaused {
        require(phase == 2, "Kaijira: Public sale not active");
        require(quantity * price == msg.value, "Kaijira: Incorrect ETH amount");
        _mint(msg.sender, quantity);
    }

    /*
    ================================================
               ACCESS RESTRICTED FUNCTIONS        
    ================================================
*/

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function adminMint(address[] calldata to, uint256[] calldata quantity) external onlyOwner {
        require(to.length == quantity.length, "Kaijira: Array length mismatch");
        for (uint256 i = 0; i < to.length; i++) {
            require(totalSupply() + quantity[i] <= MAX_SUPPLY);
            _mint(to[i], quantity[i]);
        }
    }

    function cyclePhases(uint256 _phase) external onlyOwner {
        phase = _phase;
    }

    function pause(bool _status) external onlyOwner {
        paused = _status;
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function setTeam(address[] memory _addresses) external onlyOwner {
        for (uint256 i; i < _addresses.length; i++) {
            team[_addresses[i]].teamStatus = 1;
        }
    }

    function adjustPresaleAllowance(uint256 _allowance) external onlyOwner {
        presaleAllowance = _allowance;
    }

    function adjustPrice(uint256 _type, uint256 _price) external onlyOwner {
        if (_type == 0) price = _price;
        if (_type == 1) presalePrice = _price;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    /*
    ================================================
                Internal Write Functions         
    ================================================
*/

    function _verifyProof(bytes32[] calldata proof) internal view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)));
    }

    /*
    ================================================
                    VIEW FUNCTIONS        
    ================================================
*/

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }
}