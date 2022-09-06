// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PIXELBAES is Ownable, ERC721A, ReentrancyGuard {
    uint256 public maxSupply = 10000;
    bool public paused = true;
    bool public presalePaused = true;
    string public baseURI;

    address private teamWallet = 0xc00fCD5e5c7D931b1d42b84bf9292b2D28B9Aec5;

    // Merkle roots for verifying WL and holder status
    bytes32 public merkleRootHolders = 0x8b11720cf53bd926f30a83ba226dfddedc2c4db60eacef28cbabdc186d422ba5;
    bytes32 public merkleRootWL = 0x5a858e42fc3c8bebb5712d41bf21d93475b3f03d67d21a4694abd33405767e88;

    // For checking minted per wallet
    mapping(address => uint) internal hasMinted;
    mapping(address => uint) internal hasMintedPresale;

    constructor(string memory _uri) ERC721A('PIXELBAES', 'PXBAE') {
        // Mint for the team wallet giveaways
        baseURI = _uri;
        _safeMint(teamWallet, 300);
    }

    /** MINTING FUNCTIONS */

    /**
     * @dev Allows you to mint 1 token in public sale
     */
    function mint() public nonReentrant {
        // Public mint only 1
        uint _mintAmount = 1;
        
        require(tx.origin == _msgSender(), "Only EOA");
        require(!paused, "Public sale is paused");
        require(totalSupply() + _mintAmount <= maxSupply, "No enought mints left.");

        // Adds check per wallet
        require(hasMinted[msg.sender] == 0, "You have already minted!");
        
        hasMinted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    /**
     * @dev Presale mint function
     */
    function mintPresale(bytes32[] calldata _merkleProof) public nonReentrant {
        // Checks if wallet has minted
        require(tx.origin == _msgSender(), "Only EOA");
        require(hasMintedPresale[msg.sender] == 0, "User has already presale minted!");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        uint _mintAmount = 0;

        // Check MerkleProofs to verify if holder at snapshot or WL
        if(MerkleProof.verify(_merkleProof, merkleRootHolders, leaf)) {
            // Set holder mint amount
            _mintAmount = 3;
        } else if (MerkleProof.verify(_merkleProof, merkleRootWL, leaf)) {
            // Set WL mint amount
            _mintAmount = 2;
        } else {
            // Not on either list
            revert();
        }
        
        require(!presalePaused, "Presale is paused");
        require(totalSupply() + _mintAmount <= maxSupply, "No enought mints left.");
        
        hasMintedPresale[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function adminMint(uint _amount, address _to) public onlyOwner {
        require(totalSupply() + _amount <= maxSupply, "No enought mints left.");
        _safeMint(_to, _amount);
    }

    /**
     * Function to set MerkleRoot
     */
    function setMerkleRootHolders(bytes32 merkleRoot_) public onlyOwner {
        merkleRootHolders = merkleRoot_;
    }

    function setMerkleRootWL(bytes32 merkleRoot_) public onlyOwner {
        merkleRootWL = merkleRoot_;
    }

    function setPause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setPresalePause(bool _state) public onlyOwner {
        presalePaused = _state;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}