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

contract DumpsterDorks is ERC721A, Ownable{
    ///variables
    //Sale Info
    uint256 public currentPrice = 40000000000000000;
    //team will mint the final 75 for giveaways after sale is completed
    uint256 public totalTokens = 4925;
    uint256 public limitPerWallet = 4;
    //sale status
    bool public openToWhitelistSale;
    bool public openToPublic;
    bool public mintedGiveaways;

//proxy addresses
//rinkeby 0xf57b2c51ded3a29e6891aba85459d600256cf317
//mainnet 0xa5409ec958c83c3f309868babaca7c86dcb077c1

    address proxyRegistryAddress;

    string public _contractURI = "https://DumpsterDorks.com/token-metadata";
    string private baseURI_ = "https://www.DumpsterDorks.com/Dorks/";
    string public provenance;
    bytes32 public root;

    constructor(address _proxyRegistryAddress) ERC721A("DumpsterDorks", "Dork") {
        proxyRegistryAddress = _proxyRegistryAddress;
        //Reserve 0 thru 19 (Complete matched sets, first 20 in collection) for giveaways
        _safeMint(msg.sender, 20);
    }
    
    //Owner Only functions
    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        provenance = provenanceHash;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);                
    }
    
    ///Secret Dork giveaway random mints - 75!
    function adminMint() external onlyOwner {
        require(!mintedGiveaways, "You minted giveaways!");
        _safeMint(msg.sender, 75);
        mintedGiveaways = true;
    }

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    //Upload MerkleTreeRoot for whitelist
    function setWhitelist(bytes32 theRoot) external onlyOwner {
        root = theRoot;
    }

    //sale control
    function beginSale() external onlyOwner {
        openToWhitelistSale = true;
        openToPublic = false;
    }
    
    function enablePublicSale() external onlyOwner {
        openToPublic = true;
    }

    function closeSales() external onlyOwner {
        openToPublic = false;
        openToWhitelistSale = false;
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
        require(msg.value == qty * currentPrice, "Ether value sent isn't correct");
        require((totalSupply() + qty) < totalTokens + 1, "Purchase exceeds max supply");
        // prevent smart contracts from minting 
        require(msg.sender == tx.origin, "Only EOA can mint"); 
        _safeMint(msg.sender, qty);
    }

    //
    function WhitelistPurchase(uint qty, bytes32[] calldata proof) external payable {
        require(openToWhitelistSale, "The Presale has not started yet!");
        require(_verify(_leaf(msg.sender), proof), "Invalid merkle proof");
        require(_numberMinted(msg.sender) + qty < limitPerWallet + 1, "Purchase exceeds wallet limit");
        require(msg.value == qty * currentPrice, "Ether value sent isn't correct");
        require((totalSupply() + qty) < totalTokens + 1, "Purchase exceeds max supply");

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
    function _leaf(address account) internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }

    function checkIfOnWhitelist(bytes32[] calldata proof) public view returns(bool){
        return _verify(_leaf(msg.sender), proof);
    }
}