// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
                        MM                                                                
                         MMMM                                                             
                          MMMMM                                                           
                           MMMMMM              MM                                         
                             MMM                MMM                                       
                                                 MMMMM                                    
          M                     MMMMMMMMMM       MMMMMM                                   
          MMMM                 MMMMMMMMMMMMM      MMMM                                    
           MMMMMM              MMMMMMMMMMMMMM            MM                               
           MMMMMM              MMMMMMMMMMMMMMM       MMMMMMMMMM                           
            MMMM                MMMMMMMMMMMMMMM     MMMMMMMMMMMM                          
                    MMMM         MMMMMMMMMMMMMMM    MMMMMMMMMMMMM                         
                 MMMMMMMMMMM      MMMMMMMMMMMMMM    MMMMMMMMMMMMMM                        
                 MMMMMMMMMMMMMM     MMMMMMMMMMMM   MMMMMMMMMMMMMMM                        
                  MMMMMMMMMMMMMMM    MMMMMMMMMM     MMMMMMMMMMMMMM                        
                  MMMMMMMMMMMMMMMM    MMMMMMMMM     MMMMMMMMMMMMMM                        
                   MMMMMMMMMMMMMMMM    MMM  MMM     MMMMMMMMMMMMMM                        
                    MMMMMMMMMMMMMMMM                MMMM  MMMMMMM                         
            MM       MMMMMMMMMMMMMMMM                                                     
             MMMM    MMMMMMMMMMMMMMMM     MMMMMMMMMMMMMMMMMMMMMMMMMMM                     
             MMMMM    MMM MMMMMMMMMMM    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                  
               MMM                 MM   MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                
                                       MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM               
                    MMMMMMMMMMM       MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM               
                   MMMMMMMMMMMMMM     MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                
                  MMMMMMMMMMMMMMM     MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                
                   MMMMMMMMMMMMMM     MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   MMMM          
                    MMMMMMMMMMMMM    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   MMMM          
                     MMMMMMMMMMM     MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    MMMM          
                     MMMMMMMMMM     MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   MMM            
                      M    MMM     MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                   
                            MM    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                   
                      M     MM    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                     
                                  MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                        
                                  MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                         
                                  MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                          
                                                MMMMMMMMMMMMMMM                           
                                                 MMMMMMMM   MMM                           
                                                  MMMMMM     M                            
                                                  MMMMMM                                  
                                                   MMMMM                                  
                                                   MMMMM                                  
                                                   MMMMM                                  
                                                   MMMM                                   
                                                    MM                                     
*/

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MutantShibaClub is ERC721A, Ownable {
    using Strings for uint256;

    // ======== SUPPLY ========
    uint256 public constant MAX_SUPPLY = 10000; 

    // ======== MAX MINTS ========
    uint256 public maxCommunityMint = 1;
    uint256 public maxPublicSaleMint = 1;

    // ======== PRICE ========
    uint256 public publicSalePrice; 
    uint256 public communitySalePrice; 
    uint256 public preSalePrice = 0.16 ether;
    uint256 public teamMintPrice = 0.1 ether;

    // ======== SALE STATUS ========
    bool public isPreSaleActive;
    bool public isCommunitySaleActive;
    bool public isPublicSaleActive;

    // ======== METADATA ========
    bool public isRevealed;
    string private _baseTokenURI;

    // ======== MERKLE ROOT ========
    bytes32 public preSaleMerkleRoot;
    bytes32 public communitySaleMerkleRoot;

    // ======== MINTED ========
    mapping(address => uint256) public preSaleMinted;
    mapping(address => bool) public communitySaleMinted;
    mapping(address => uint256) public publicSaleMinted;

    // ======== GNOSIS ========
    address public constant GNOSIS_SAFE = 0xe16B650921475afA532f7C08A8eA1C2fCDa8ab93;

    // ======== FOUNDERS & TEAM ========    
    address public constant TEAM = 0xcdBB9a281f1086aEcB6c4d5ac290130c1A8778De;
    address public constant FOUNDER_BERRY = 0x28C1dEd0D767fDC39530f676362175afe35E96B4; 
    address public constant FOUNDER_GABA = 0xbe14e8d7a3417046627f305C918eC435C3c23fbC; 
    address public constant FOUNDER_LORDSLABS = 0xbb59f8ce665d238A9e8D942172D283ba87061F6F; 
    address public constant FOUNDER_CRAZYJUMP = 0xE386aE197A42e49C727BF15070FE71C68F18ad45; 


    // ======== CONSTRUCTOR ========      
    constructor() ERC721A("Mutant Shiba Club", "MSC") {}

    /**
     * @notice must be an EOA
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // ======== MINTING ========
    /**
     * @notice presale mint
     */
    function preSaleMint(uint256 _quantity, uint256 _maxAmount,  bytes32[] calldata _proof) external payable callerIsUser {
        require(isPreSaleActive, "PRESALE NOT ACTIVE");
        require(msg.value == preSalePrice * _quantity, "NEED TO SEND CORRECT ETH AMOUNT");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "MAX SUPPLY REACHED" );
        require(preSaleMinted[msg.sender] + _quantity <= _maxAmount, "EXCEEDS MAX CLAIM"); 
        bytes32 sender = keccak256(abi.encodePacked(msg.sender, _maxAmount));
        bool isValidProof = MerkleProof.verify(_proof, preSaleMerkleRoot, sender);
        require(isValidProof, "INVALID PROOF");

        preSaleMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    /**
     * @notice community sale mint
     */
    function communitySaleMint(bytes32[] calldata _proof) external payable callerIsUser {
        require(isCommunitySaleActive, "COMMUNITY SALE NOT ACTIVE");
        require(msg.value == communitySalePrice, "NEED TO SEND CORRECT ETH AMOUNT");
        require(totalSupply() + maxCommunityMint <= MAX_SUPPLY, "MAX SUPPLY REACHED" );
        require(!communitySaleMinted[msg.sender], "EXCEEDS MAX CLAIM"); 
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        bool isValidProof = MerkleProof.verify(_proof, communitySaleMerkleRoot, sender);
        require(isValidProof, "INVALID PROOF");

        communitySaleMinted[msg.sender] = true;
        _safeMint(msg.sender, maxCommunityMint);
    }

    /**
     * @notice public sale mint
     */
    function publicSaleMint(uint256 _quantity) external payable callerIsUser {
        require(isPublicSaleActive, "PUBLIC SALE IS NOT ACTIVE");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "MAX SUPPLY REACHED" );
        require(publicSaleMinted[msg.sender] + _quantity <= maxPublicSaleMint, "EXCEEDS MAX MINTS PER ADDRESS"); 
        require(msg.value == publicSalePrice * _quantity, "NEED TO SEND CORRECT ETH AMOUNT");

        publicSaleMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function teamMint(uint256 _quantity, bool _founders) external payable onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "MAX SUPPLY REACHED" );
        require(msg.value == teamMintPrice, "NEED TO SEND CORRECT ETH AMOUNT");
        if (_founders) {
            // ======== FOUNDER MINT ========      
            _safeMint(FOUNDER_BERRY, 15);
            _safeMint(FOUNDER_GABA, 15);
            _safeMint(FOUNDER_LORDSLABS, 15);
            _safeMint(FOUNDER_CRAZYJUMP, 15);

            // ======== TEAM MINT ========      
            _safeMint(TEAM, 40);
            _safeMint(TEAM, 43);
            _safeMint(TEAM, 57);
        } else {
            // ======== TEAM MINT ========      
            _safeMint(TEAM, _quantity);
        }
    }

    // ======== SALE STATUS SETTERS ========
    /**
     * @notice activating or deactivating presale status
     */
    function setPreSaleStatus(bool _status) external onlyOwner {
        isPreSaleActive = _status;
    }

    /**
     * @notice activating or deactivating community sale status
     */
    function setCommunitySaleStatus(bool _status) external onlyOwner {
        isCommunitySaleActive = _status;
    }

    /**
     * @notice activating or deactivating public sale
     */
    function setPublicSaleStatus(bool _status) external onlyOwner {
        isPublicSaleActive = _status;
    }

    // ======== PRICE SETTERS ========
    /**
     * @notice set presale price
     */
    function setPreSalePrice(uint256 _price) external onlyOwner {
        preSalePrice = _price;
    }

    /**
     * @notice set whitelist price
     */
    function setCommunitySalePrice(uint256 _price) external onlyOwner {
        communitySalePrice = _price;
    }

    /**
     * @notice set public sale price
     */
    function setPublicSalePrice(uint256 _price) external onlyOwner {
        publicSalePrice = _price;
    }

    // ======== MERKLE ROOT SETTERS ========
    /**
     * @notice set presale merkleroot
     */
    function setPresaleMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        preSaleMerkleRoot = _merkleRoot;
    }

    /**
     * @notice set community sale merkleroot
     */
    function setCommunitySaleMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        communitySaleMerkleRoot = _merkleRoot;
    }

    // ======== METADATA URI ========
    /**
     * @notice tokenURI
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for non-existent token");
        if (!isRevealed) {
            return _baseTokenURI;
        } else{
            return string(abi.encodePacked(_baseTokenURI, _tokenId.toString()));
        }
    }

    /**
     * @notice set base URI
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }   

    /**
     * @notice set IsRevealed to true or false
     */
    function setIsRevealed(bool _reveal) external onlyOwner {
        isRevealed = _reveal;
    }   

    /** 
    *   @notice set startTokenId to 1
    */
    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }

    // ======== WITHDRAW GNOSIS ========

    /**
     * @notice withdraw funds to gnosis safe
     */
    function withdraw() external onlyOwner {
        (bool success, ) = GNOSIS_SAFE.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}