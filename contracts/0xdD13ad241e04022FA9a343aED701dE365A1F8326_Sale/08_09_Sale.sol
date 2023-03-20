// SPDX-License-Identifier: NONE 

pragma solidity >= 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IWoofPack.sol";
import "hardhat/console.sol";

contract Sale is Ownable {
    using ECDSA for bytes32;

    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public MINT_PRICE = 0.05 ether;
    uint256 public constant RARITY_PRICE = 5555 ether; // BOOM

    // address where payments will be withdrawn to
    address public K9DAO;
    // signer of messages for claims
    address public signer;
    // list of claims that have been made
    mapping(address => uint256) public claims;
    // whether or not claims are enabled
    bool public claimsEnabled = false;
    // list of whitelist mints that have been made
    mapping(address => uint256) public whitelistMints;
    // whether or not whitelists are enabled
    bool public whitelistsEnabled = false;
    // reference to WoofPack NFT
    IWoofPack public woofPack;
    // reference to BOOM token
    IERC20 public boom;

    uint256 public totalMints;
    // number of general mints so far
    uint256 public unreservedMints;
    // number of general mints allowed (MAX_SUPPLY - number of mints that are free - number of whitelists)
    uint256 public unreservedMintLimit;
    // whether or not general mints are enabled
    bool public generalEnabled = false;

    event Mint(
        address recipient,
        uint256 id,
        bool rare
    );

    /****
    @param _signer the address of the signing wallet
    @param _unreservedMintLimit the number of mints available for general minting (non-free, non-whitelist)
    @param _woofPack the address of the NFT contract
    @param _boom the address of BOOM token
    ****/
    constructor(address _signer, uint256 _unreservedMintLimit, address _woofPack, address _boom) {
        signer = _signer;
        K9DAO = msg.sender;
        unreservedMintLimit = _unreservedMintLimit;
        woofPack = IWoofPack(_woofPack);
        boom = IERC20(_boom);
    }

    //a function that allows the owner to mint NFTs for giveaways
    //this was added in by matt and is not part of the original contract provided
    /***
    @param recipient the address to mint the NFTs to
    @param quantity the number of NFTs to mint
    @param rare whether or not the NFTs should be rare
    ****/
    function ownerMint(address recipient, uint256 quantity, bool rare) external onlyOwner {
        // makes sure that there are general mints available
        require(unreservedMints + quantity <= unreservedMintLimit, "General mint sold out");
        // update the number of general mints that have been done
        unreservedMints += quantity;
        // mint the NFTs
        _mint(recipient, quantity, rare);
    }

    /****
    allows addresses to claim their free NFT(s)
    @param quantity the number of NFTs to claim for free
    @param rare whether or not the address wants to spend BOOM for additional rarity
    @param signature the signature from the project allowing the claims
    @param maxAllowed the maximum number a user is allowed to claim for straightforward leaf generation
    ****/
    function claimMint(uint256 quantity, bool rare, bytes memory signature, uint256 maxAllowed) external {
        // makes sure that claims are currently enabled
        require(claimsEnabled, "Claims are currently paused");
        // make sure the address hasn't reached the max claim amount
        require(claims[msg.sender] + quantity <= maxAllowed, "Address cannot mint this many");
        // encode the passed in data
        bytes memory message = abi.encode(msg.sender, maxAllowed, "claim");
        bytes32 messageHash = keccak256(message);
        // ensure that the signature is valid
        require(messageHash.toEthSignedMessageHash().recover(signature) == signer, "Invalid signature");        
        // record that the address has made their claim(s)
        claims[msg.sender] += quantity;
        // mint the claimed NFTs
        _mint(msg.sender, quantity, rare);
    }

    /****
    allows addresses a guaranteed mint if they're on the whitelist
    @param quantity the number of NFTs to mint
    @param rare whether or not the address wants to spend BOOM for additional rarity
    @param signature the signature from the project allowing the whitelists
    @param maxAllowed the maximum number a user is whitelisted to mint for straightforward leaf generation
    ****/
    function whitelistMint(uint256 quantity, bool rare, bytes memory signature, uint256 maxAllowed) payable external {
        // makes sure that whitelist minting is currently enabled
        require(whitelistsEnabled, "Whitelists are currently paused");
        // guarantee the payment amount is correct
        require(msg.value == quantity * MINT_PRICE, "Invalid payment amount");
        // make sure the address hasn't reached the max whitelist amount
        require(whitelistMints[msg.sender] + quantity <= maxAllowed, "Address cannot mint this many");
        // encode the passed in data
        bytes memory message = abi.encode(msg.sender, maxAllowed, "whitelist");
        bytes32 messageHash = keccak256(message);
        // ensure that the signature is valid
        require(messageHash.toEthSignedMessageHash().recover(signature) == signer, "Invalid signature");   
        // record that the address has made their mint(s)
        whitelistMints[msg.sender] += quantity;
        // mint the whitelist enabled NFTs
        _mint(msg.sender, quantity, rare);
    }

    /****
    function for direct mints without whitelist
    @param quantity the number of NFTs to mint
    @param rare whether or not the address wants to spend BOOM for additional rarity
    ****/
    function generalMint(uint256 quantity, bool rare) payable external {
        // makes sure that general minting is currently enabled
        require(generalEnabled, "General mints are currently paused");
        // makes sure that there are general mints available
        require(unreservedMints + quantity <= unreservedMintLimit, "General mint sold out");
        // guarantee the payment amount is correct
        require(msg.value == quantity * MINT_PRICE, "Invalid payment amount");
        // update the number of general mints that have been done
        unreservedMints += quantity;
        // mint the NFTs
        _mint(msg.sender, quantity, rare);
    }

    /****
    general internal function for minting multiple NFTs
    @param recipient the address to send the NFTs to
    @param quantity the number of NFTs to mint
    @param rare whether or not the NFTs are guaranteed rare
    ****/
    function _mint(address recipient, uint256 quantity, bool rare) internal {
        // charge the requisite BOOM, will fail if they don't have enough
        if (rare) _chargeBoom(quantity);
        for (uint256 i = 0; i < quantity; i++) {
            woofPack.mint(recipient, ++totalMints, rare);
            emit Mint(recipient, totalMints, rare);
        }
    }

    /****
    burns BOOM to the DEAD address
    @param quantity the number of tokens having BOOM applied to rarity
    ****/
    function _chargeBoom(uint256 quantity) internal {
        boom.transferFrom(msg.sender, address(0xdead), RARITY_PRICE * quantity);
    }

    /****
    allows owner to update the signer of claims and whitelists
    @param _signer the new signer of valid signatures
    ****/
    function setSigner(address _signer) external onlyOwner{
        signer = _signer;
    }
    
    /****
    allows owner to update the unreserved limit after whitelist owners have time to mint
    @param _unreservedMintLimit the new limit, likely MAX_SUPPLY - minted
    ****/
    function setUnreservedMintLimit(uint256 _unreservedMintLimit) external onlyOwner {
        unreservedMintLimit = _unreservedMintLimit;
    }

    /****
    allows owner to withdraw ETH to the DAO
    ****/
    function withdraw() external onlyOwner {
        payable(K9DAO).transfer(address(this).balance);
    }

    /****
    allows owner to update destination of withdrawals
    @param _K9DAO the new address
    ****/
    function setK9DAO(address _K9DAO) external onlyOwner {
        K9DAO = _K9DAO;
    }

    /****
    allows owner to enable/disable claims
    @param _enabled whether or not it's enabled
    ****/
    function setClaimsEnabled(bool _enabled) external onlyOwner {
        claimsEnabled = _enabled;
    }

    /****
    allows owner to enable/disable whitelist mints
    @param _enabled whether or not it's enabled
    ****/
    function setWhitelistEnabled(bool _enabled) external onlyOwner {
        whitelistsEnabled = _enabled;
    }

    /****
    allows owner to enable/disable general mints
    @param _enabled whether or not it's enabled
    ****/
    function setGeneralEnabled(bool _enabled) external onlyOwner {
        generalEnabled = _enabled;
    }

    /****
    allows owner to change price of WL and general mints
    @param _price new price IN WEI (not ETH) of mint
    ****/
    function setMintPrice(uint256 _price) external onlyOwner {
        MINT_PRICE = _price;
    }
}