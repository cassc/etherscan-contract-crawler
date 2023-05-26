// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;   

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract WabiSabi is Ownable, ERC721A, ReentrancyGuard {

    string public baseURI;
    uint256 public teamWS = 70; // launch
    uint256 public constant price = 0.075 ether;
    uint8 public maxWLMint = 1;
    uint8 public maxMintPerAccount = 2;
    uint256 public maxPresaleSupply = 4200; // launch
    uint256 public maxWSsupply = 5678; // launch
    bool public isPublicActive = false;
    bool public isPresaleBActive = false;
    bool public isPresaleAActive = false;
    uint256 public mintedPresale = 0;
    uint256 public maxMintsPerTx = 5;

    // WS mint
    mapping (address => uint256) public mintedWSforPresaleA;

    // S mint
    mapping (address => uint256) public mintedWSforPresaleB;

    mapping(address => uint256) addressBlockBought;

    bytes32 private presaleAMerkleRoot;
    bytes32 private presaleBMerkleRoot;


    constructor(
        bytes32 presaleARoot,
        bytes32 presaleBRoot
        ) 
        ERC721A("Wabi Sabi Collective", "WabiSabi", 50, 5678)  {
        presaleAMerkleRoot = presaleARoot;
        presaleBMerkleRoot = presaleBRoot;
    } // launch

    modifier isSecured(uint8 mintType) {
        require(addressBlockBought[msg.sender] < block.timestamp, "CANNOT_MINT_ON_THE_SAME_BLOCK");
        require(tx.origin == msg.sender,"CONTRACTS_NOT_ALLOWED_TO_MINT");

        if(mintType == 1) {
            require(isPresaleAActive, "PRESALEA_MINT_IS_NOT_YET_ACTIVE");
        } 

        if(mintType == 2) {
            require(isPresaleBActive, "PRESALEB_MINT_IS_NOT_YET_ACTIVE");
        }

        if(mintType == 3) {
            require(isPublicActive, "PUBLIC_MINT_IS_NOT_YET_ACTIVE");
        }
        _;
    }

    /**
     * Presale mint function
     */

    function ogListMint(bytes32[] calldata proof, uint256 numberOfTokens) external payable isSecured(1) {
        require(msg.value == price * numberOfTokens, "INSUFFICIENT_PAYMENT");
        require(msg.value > 0, "Mint must be greater than 0."); // test check
        
        require(mintedWSforPresaleA[msg.sender] + numberOfTokens <= maxMintPerAccount, "NOT_ALLOWED_TO_MINT_MORE_THAN_2" );
        require(mintedPresale + numberOfTokens <= maxPresaleSupply, "EXCEEDS_MAX_PRESALE_SUPPLY" );
        require(totalSupply() + numberOfTokens <= maxWSsupply, "EXCEEDS_MAX_SUPPLY" );
        require(MerkleProof.verify(proof, presaleAMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "INVALID_WHITELIST_PROOF");

        addressBlockBought[msg.sender] = block.timestamp;
        mintedWSforPresaleA[msg.sender] += numberOfTokens;
        mintedPresale += numberOfTokens;
        _safeMint( msg.sender, numberOfTokens);
    }

    function whitelistMint(bytes32[] calldata proof, uint256 numberOfTokens) external payable isSecured(2) {
        require(msg.value == price * numberOfTokens, "INSUFFICIENT_PAYMENT");
        require(msg.value > 0, "Mint must be greater than 0."); // test check

        require(mintedWSforPresaleB[msg.sender] + numberOfTokens <= maxWLMint, "EXCEEDS_MAX_PRESALEB_MINT" );
        require(mintedPresale + numberOfTokens <= maxPresaleSupply, "EXCEEDS_MAX_PRESALE_SUPPLY" );
        require(totalSupply() + numberOfTokens <= maxWSsupply, "EXCEEDS_MAX_SUPPLY" );
        require(MerkleProof.verify(proof, presaleBMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "INVALID_WHITELIST_PROOF");

        addressBlockBought[msg.sender] = block.timestamp;
        mintedWSforPresaleB[msg.sender] += numberOfTokens;
        mintedPresale += numberOfTokens;
        _safeMint( msg.sender, numberOfTokens);
    }
    
    function mintTeamWS(uint256 numberOfTokens) external onlyOwner {
        require(teamWS > 0, "NFTS_FOR_THE_TEAM_HAS_BEEN_MINTED");
        require(numberOfTokens <= teamWS, "EXCEEDS_MAX_MINT_FOR_TEAM");

        teamWS -= numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    // Public Mint Functions
    function mintPublic(uint256 numberOfTokens) external payable isSecured(3) {
        require(msg.value == price * numberOfTokens, "INSUFFICIENT_PAYMENT");
        require(msg.value > 0, "Mint must be greater than 0."); // test check
        require(maxMintsPerTx >= numberOfTokens, "Over maxmimum mints per Tx!");
        
        require(totalSupply() + numberOfTokens <= maxWSsupply, "EXCEEDS_MAX_SUPPLY" );
        
        addressBlockBought[msg.sender] = block.timestamp;
        
        _safeMint( msg.sender, numberOfTokens);

        

    }
    
    function tokenIdOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // SETTER FUNCTIONS

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setMerkleOGRoot(bytes32 presaleRoot) external onlyOwner {
        presaleAMerkleRoot = presaleRoot;
    }
    function setMerkleRoot(bytes32 presaleRoot) external onlyOwner {
        presaleBMerkleRoot = presaleRoot;
    }

    // TOGGLES

    function togglePublicMintActive() external onlyOwner {
        isPublicActive = !isPublicActive;
    }

    function togglePresaleAActive() external onlyOwner {
        isPresaleAActive = !isPresaleAActive;
        isPresaleBActive = !isPresaleBActive;

    }

    // function togglePresaleBActive() external onlyOwner {
    //     isPresaleBActive = !isPresaleBActive;
    // }

    /**
     * Withdraw Ether
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Failed to withdraw payment");
    }
}