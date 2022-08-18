// SPDX-License-Identifier: MIT
// Creator: twitter.com/0xNox_ETH

//               .;::::::::::::::::::::::::::::::;.
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;
//               ;KNNNWMMWMMMMMMWWNNNNNNNNNWMMMMMN:
//                .',oXMMMMMMMNk:''''''''';OMMMMMN:
//                 ,xNMMMMMMNk;            l00000k,
//               .lNMMMMMMNk;               .....  
//                'dXMMWNO;                ....... 
//                  'd0k;.                .dXXXXX0;
//               .,;;:lc;;;;;;;;;;;;;;;;;;c0MMMMMN:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWX:
//               .,;,;;;;;;;;;;;;;;;;;;;;;;;,;;,;,.
//               'dkxkkxxkkkkkkkkkkkkkkkkkkxxxkxkd'
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               'xkkkOOkkkkkkkkkkkkkkkkkkkkkkkkkx'
//                          .,,,,,,,,,,,,,,,,,,,,,.
//                        .lKNWWWWWWWWWWWWWWWWWWWX;
//                      .lKWMMMMMMMMMMMMMMMMMMMMMX;
//                    .lKWMMMMMMMMMMMMMMMMMMMMMMMN:
//                  .lKWMMMMMWKo:::::::::::::::::;.
//                .lKWMMMMMWKl.
//               .lNMMMMMWKl.
//                 ;kNMWKl.
//                   ;dl.
//
//               We vow to Protect
//               Against the powers of Darkness
//               To rain down Justice
//               Against all who seek to cause Harm
//               To heed the call of those in Need
//               To offer up our Arms
//               In body and name we give our Code
//               
//               FOR THE BLOCKCHAIN ⚔️

pragma solidity ^0.8.4;

import "./extensions/IERC721ABurnable.sol";
import "./extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MintStone is ERC721AQueryable, IERC721ABurnable, Ownable, Pausable, ReentrancyGuard {
    using MerkleProof for bytes32[];

    event PermanentURI(string _value, uint256 indexed _id);

    string private _baseTokenURI;
    bool public _baseURILocked;

    address private _authorizedContract;
    address private _admin;

	bytes32 public _allowlistMerkleRoot;
    uint256 public _maxMintPerWallet = 1;
    uint256 public _maxSupply = 7000;
    bool private _maxSupplyLocked;

    constructor(
        string memory baseTokenURI,
        address admin,
        bytes32 allowlistMerkleRoot)
    ERC721A("CF Mintstone", "MINTSTONE") {
        _admin = admin;
        _baseTokenURI = baseTokenURI;
        _allowlistMerkleRoot = allowlistMerkleRoot;
        _safeMint(msg.sender, 1);
        _pause();
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller is another contract");
        _;
    }

    modifier verify(
        address account,
        bytes32[] calldata merkleProof,
        bytes32 merkleRoot
    ) {
        require(
            merkleProof.verify(merkleRoot, keccak256(abi.encodePacked(account))),
            "Address not allowed"
            );
        _;
    }
    
    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || msg.sender == _admin, "Not owner or admin");
        _;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwnerOrAdmin {
        require(!_baseURILocked, "Base URI is locked");
        _baseTokenURI = newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function setAllowlistMerkleRoot(bytes32 root) external onlyOwnerOrAdmin {
        _allowlistMerkleRoot = root;
    }

    function isAllowlisted(address account, bytes32[] calldata merkleProof) external view returns(bool) {
        return merkleProof.verify(_allowlistMerkleRoot, keccak256(abi.encodePacked(account)));
    }

    function mint(bytes32[] calldata merkleProof, uint256 quantity)
        external
        nonReentrant
        callerIsUser
        verify(msg.sender, merkleProof, _allowlistMerkleRoot)
        whenNotPaused
    {
        require(_numberMinted(msg.sender) + quantity <= _maxMintPerWallet, "Quantity exceeds wallet limit");
        require(totalSupply() + quantity <= _maxSupply, "Quantity exceeds supply");

        _safeMint(msg.sender, quantity);
    }

    function ownerMint(address to, uint256 quantity) external onlyOwnerOrAdmin {
        require(totalSupply() + quantity <= _maxSupply, "Quantity exceeds supply");
        _safeMint(to, quantity);
    }

    // Pauses the mint process
    function pause() external onlyOwnerOrAdmin {
        _pause();
    }

    // Unpauses the mint process
    function unpause() external onlyOwnerOrAdmin {
        _unpause();
    }

    function setMaxMintPerWallet(uint256 quantity) external onlyOwnerOrAdmin {
        _maxMintPerWallet = quantity;
    }

    function setMaxSupply(uint256 supply) external onlyOwnerOrAdmin {
        require(!_maxSupplyLocked, "Max supply is locked");
        _maxSupply = supply;
    }

    // Locks maximum supply forever
    function lockMaxSupply() external onlyOwnerOrAdmin {
        _maxSupplyLocked = true;
    }

    // Locks base token URI forever and emits PermanentURI for marketplaces (e.g. OpenSea)
    function lockBaseURI() external onlyOwnerOrAdmin {
        _baseURILocked = true;
        for (uint256 i = 0; i < totalSupply(); i++) {
            emit PermanentURI(tokenURI(i), i);
        }
    }

    // Only the owner of the token and its approved operators, and the authorized contract
    // can call this function.
    function burn(uint256 tokenId) public virtual override {
        // Avoid unnecessary approvals for the authorized contract
        bool approvalCheck = msg.sender != _authorizedContract;
        _burn(tokenId, approvalCheck);
    }

    function setAdmin(address admin) external onlyOwner {
        _admin = admin;
    }
    
    function setAuthorizedContract(address authorizedContract) external onlyOwnerOrAdmin {
        _authorizedContract = authorizedContract;
    }

    // OpenSea metadata initialization
    function contractURI() public pure returns (string memory) {
        return "https://cloneforce.xyz/api/mintstone/marketplace-metadata";
    }
}