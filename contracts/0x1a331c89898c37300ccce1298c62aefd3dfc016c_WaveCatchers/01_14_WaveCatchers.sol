// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// ._.  __      __                                          
// | | /  \    /  \_____ ___  __ ____                       
// | | \   \/\/   /\__  \\  \/ // __ \                      
//  \|  \        /  / __ \\   /\  ___/                      
//  __   \__/\  /  (____  /\_/  \___  >                     
//  \/        \/        \/          \/                      
// _________         __         .__                         
// \_   ___ \_____ _/  |_  ____ |  |__   ___________  ______
// /    \  \/\__  \\   __\/ ___\|  |  \_/ __ \_  __ \/  ___/
// \     \____/ __ \|  | \  \___|   Y  \  ___/|  | \/\___ \ 
//  \______  (____  /__|  \___  >___|  /\___  >__|  /____  >
//         \/     \/          \/     \/     \/           \/
// @author 0xBori <https://twitter.com/0xBori>
contract WaveCatchers is Ownable, ERC721A, ReentrancyGuard {

    using Strings for uint256;

    // Variables
    uint256 public collectionSize = 3334; 
    uint256 public wlSupplyLeft = 334;
    uint256 public price = 0.025 ether;
    bytes32 public merkleRoot;
    string private baseTokenURI;
    string private defaultURI;
    bool public isRevealed;
    bool public saleIsActive;
    

    // Mappings
    mapping(address => bool) internal hasClaimed;

    constructor() ERC721A("WaveCatchers", "WC", 10) {}

    // Mint Magic
    function mint(uint256 _amount) external payable {
        require(
            saleIsActive,
            "Sale is not active"
        );
        require(
            totalSupply() + _amount <= collectionSize - wlSupplyLeft,
            "Exceeds max supply"
        );
        require(
            msg.value == price * _amount,
            "Incorrect ETH value sent"
        );
        require(
            tx.origin == msg.sender,
            "Not allowing contracts"
        );

        _safeMint(msg.sender, _amount);
    }

    function OGMint(bytes32[] calldata merkleProof) external {
        require(
            saleIsActive,
            "Sale is not active"
        );
        require(
            wlSupplyLeft != 0,
            "No supply left for OG"
        );
        require(
            !hasClaimed[msg.sender],
            "Already claimed"
        );                                                                                                                            
        require(
            tx.origin == msg.sender,
            "Not allowing contracts"
        );
    
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
                "Invalid merkle proof");

        hasClaimed[msg.sender] = true;
        unchecked {
            wlSupplyLeft--;
        }
        _safeMint(msg.sender, 1);
    }

    function reserve(uint256 _amount) external onlyOwner {
        require(
            totalSupply() == 0,
            "Owner has already minted"
        );
        _safeMint(msg.sender, _amount);
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    // Merkle Magic
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner { 
        merkleRoot = _merkleRoot;
    }

    function canClaimOG(address _address, bytes32[] calldata _merkleProof) public view returns (bool){
        return !hasClaimed[_address] &&
            MerkleProof.verify(
                _merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(_address))
            );
    }

    // Metadata Magic
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function reveal(string calldata baseURI) external onlyOwner {
        isRevealed = true;
        baseTokenURI = baseURI;
    }

    function setDefaultURI(string calldata _defaultURI ) external onlyOwner {
        defaultURI = _defaultURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return isRevealed ? string(abi.encodePacked(
            baseTokenURI,
            _tokenId.toString()
        )) : defaultURI;
    }

    // Withdraw Magic
      function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        (bool s1, ) = address(0x67eF43A7b0FDC38DB0990413a86f7B0dc0220f7F).call{value: balance / 100 * 4}("");
        (bool s2, ) = address(0x70E93674A2f0eE65a5f16baDa5B13952C6671188).call{value: balance / 100 * 5}("");
        (bool s3, ) = address(0x6E6ee51549aF3a11488b3D52D91B5e0697170d59).call{value: balance / 100 * 20}("");
        (bool s4, ) = address(0xA57a867160240d95Dc317177F700b42bec36515b).call{value: balance / 100 * 71}("");
        require(s1 && s2 && s3 && s4, "Transfer failed.");
    }
}