// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract DumpsterDorksSeries2 is ERC721A, Ownable{
    ///variables
    //Sale Info
    uint256 public presalePrice = 50000000000000000;
    uint256 public publicPrice = 60000000000000000;

    //team will mint the final 500 for giveaways after sale is completed
    uint256 public totalTokens = 7000;
    //sale status
    bool public openToAllowlistSale;
    bool public openToPublic;
    bool public mintedGiveaways;

    mapping(address => bool) public claimed;
    mapping(address => bool) public presaleSpotUsed;

//proxy addresses
//rinkeby 0xf57b2c51ded3a29e6891aba85459d600256cf317
//mainnet 0xa5409ec958c83c3f309868babaca7c86dcb077c1

    address proxyRegistryAddress;
    string public _contractURI = "https://DumpsterDorks.com/token-metadata-2";
    string private baseURI_ = "https://www.DumpsterDorks.com/S2_Dorks/";
    string public provenance;
    bytes32 public allowlistRoot;
    bytes32 public claimlistRoot;

    constructor(address _proxyRegistryAddress) ERC721A("DumpsterDorks_S2", "Dork_S2") {
        proxyRegistryAddress = _proxyRegistryAddress;
    }
    
    //Owner Only functions
    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        provenance = provenanceHash;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);                
    }
    
    ///Secret Dork giveaway random mints - 500!
    function adminMint() external onlyOwner {
        require(!mintedGiveaways, "You minted giveaways!");
        _safeMint(msg.sender, 500);
        mintedGiveaways = true;
    }

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    //Upload MerkleTreeRoot for whitelist
    function setAllowlist(bytes32 theRoot) external onlyOwner {
        allowlistRoot = theRoot;
    }
    //Upload MerkleTreeRoot for whitelist
    function setClaimlistRoot(bytes32 theRoot) external onlyOwner {
        claimlistRoot = theRoot;
    }
    
    //sale control
    function beginSale() external onlyOwner {
        openToAllowlistSale = true;
        openToPublic = false;
    }
    
    function enablePublicSale() external onlyOwner {
        openToPublic = true;
    }

    function closeSales() external onlyOwner {
        openToPublic = false;
        openToAllowlistSale = false;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        baseURI_ = baseURI;
    }

    /**
    * Mint Secret Dork
    */
    function PublicPurchase(uint qty) external payable {
        require(openToPublic, "The sale is not open to the public!");
        require(qty < 11, "Purchase exceeds per transaction limit");
        require(msg.value == qty * publicPrice, "Ether value sent isn't correct");
        require((totalSupply() + qty) < totalTokens + 1, "Purchase exceeds max supply");
        // prevent smart contracts from minting 
        require(msg.sender == tx.origin, "Only EOA can mint"); 
        _safeMint(msg.sender, qty);
    }

    //
    function AllowlistPurchase(uint qty, bytes32[] calldata proof, uint purchaseQuantity) external payable {
        require(openToAllowlistSale, "The Presale has not started yet!");
        require(_verifyAllowlist(_leaf(msg.sender, qty), proof), "Invalid merkle proof");
        require(presaleSpotUsed[msg.sender] == false, "Your presale spot has been used");
        require(msg.value == purchaseQuantity * presalePrice, "Ether value sent isn't correct");
        require((totalSupply() + purchaseQuantity) < totalTokens + 1, "Purchase exceeds max supply");
        require(purchaseQuantity <= qty, "What are you tryin' ta pull maaaan?!?");
        presaleSpotUsed[msg.sender] = true;
        _safeMint(msg.sender, purchaseQuantity);
    }

    function ClaimFreeDorks(uint qty, bytes32[] calldata proof) public {
        require(openToAllowlistSale, "Claim window is not open");
        require(claimed[msg.sender] == false, "Your address has already used its claim.");
        require(_verifyClaimlist(_leaf(msg.sender, qty), proof), "Invalid merkle proof");
        claimed[msg.sender] = true;
        _safeMint(msg.sender, qty);
    }
    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }
    
    function _baseURI() override internal view returns (string memory) {
        return baseURI_;
    }

    ///Merkelproof functions
    function _leaf(address account, uint256 qty) internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, qty));
    }

    function _verifyAllowlist(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, allowlistRoot, leaf);
    }

    function _verifyClaimlist(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, claimlistRoot, leaf);
    }

    function checkIfOnAllowlist(bytes32[] calldata proof, uint256 qty) public view returns(bool){
        return _verifyAllowlist(_leaf(msg.sender, qty), proof);
    }

    function checkIfOnClaimlist(bytes32[] calldata proof, uint256 qty) public view returns(bool){
        return _verifyClaimlist(_leaf(msg.sender, qty), proof);
    }
}