// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

import "./IMetaHero.sol";
import "./MetaHeroGeneGenerator.sol";

/*
* @title ERC721 token for MetaHero, redeemable through burning MintPass tokens
*
* @author Niftydude
*/
contract MetaHero is IMetaHero, ERC721Enumerable, ERC721Pausable, ERC721Burnable, Ownable {
    using MetaHeroGeneGenerator for MetaHeroGeneGenerator.Gene;
    using Strings for uint256;

    uint256 constant MAX_REDEEM = 40;

    uint256 public windowOpen; 
    
    string private baseTokenURI;
    string private ipfsURI;

    string public arweaveAssets;

    uint256 private ipfsAt;

    MintPassContract public mintPassContract;

    mapping (uint256 => uint256) internal _genes;
    MetaHeroGeneGenerator.Gene internal geneGenerator;

    event Redeemed(address indexed account, uint256 amount);

    /**
    * @notice Constructor to create MetaHero contract
    * 
    * @param _symbol the token symbol
    * @param _windowOpen UNIX timestamp for redeem start
    * @param _baseTokenURI the respective base URI
    * @param _mintPassToken contract address of MintPass token to be burned
    */
    constructor (
        string memory _name, 
        string memory _symbol, 
        uint256 _windowOpen, 
        string memory _baseTokenURI,
        address _mintPassToken,
        string memory _arweaveAssets
    ) ERC721(_name, _symbol) {
        windowOpen  = _windowOpen;
        baseTokenURI = _baseTokenURI;    
        arweaveAssets = _arweaveAssets;
        
        mintPassContract = MintPassContract(_mintPassToken);    
    }

    /**
    * @notice Change the base URI for returning metadata
    * 
    * @param _baseTokenURI the respective base URI
    */
    function setBaseURI(string memory _baseTokenURI) external override onlyOwner {
        baseTokenURI = _baseTokenURI;    
    }    


    /**
    * @notice Change the base URI for returning metadata
    * 
    * @param _ipfsURI the respective ipfs base URI
    */
    function setIpfsURI(string memory _ipfsURI) external override onlyOwner {
        ipfsURI = _ipfsURI;    
    }    

    /**
    * @notice Change last ipfs token index
    * 
    * @param at the token index 
    */
    function endIpfsUriAt(uint256 at) external onlyOwner {
        ipfsAt = at;    
    }    

    /**
    * @notice Pause redeems until unpause is called
    */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
    * @notice Unpause redeems until pause is called
    */
    function unpause() external override onlyOwner {
        _unpause();
    }

    /**
    * @notice Set pointer to arweave assets
    * 
    * @param _arweaveAssets pointer to images on Arweave network
    */
    function setArweaveAssets(string memory _arweaveAssets) external onlyOwner {
        arweaveAssets = _arweaveAssets;
    }            

    /**
    * @notice Configure time to enable redeem functionality
    * 
    * @param _windowOpen UNIX timestamp for redeem start
    */
    function setRedeemStart(uint256 _windowOpen) external override onlyOwner {
        windowOpen = _windowOpen;
    }        

    /**
    * @notice Redeem specified amount of MintPass tokens for MetaHero
    * 
    * @param amount the amount of MintPasses to redeem
    */
    function redeem(uint256 amount) external override {
        require(msg.sender == tx.origin, "Redeem: not allowed from contract");
        require(!paused(), "Redeem: paused");
        require(amount <= MAX_REDEEM, "Redeem: Max amount exceeded");
        require(block.timestamp > windowOpen || msg.sender == owner(), "Redeem: Not started yet");
        require(mintPassContract.balanceOf(msg.sender, 0) >= amount, "Redeem: insufficient amount of MintPasses");

        mintPassContract.burnFromRedeem(msg.sender, 0, amount);

        for(uint256 i = 0; i < amount; i++) {
            uint256 tokenId = totalSupply() + 1;

            _genes[tokenId] = geneGenerator.random();
            _mint(msg.sender, tokenId);
        }

        emit Redeemed(msg.sender, amount);
    }  

    /**
    * @notice returns the gene combination for a given MetaHero
    * 
    * @param tokenId the MetaHero id to return genes for
    */
    function geneOf(uint256 tokenId) public view virtual override returns (uint256 gene) {
        require(_exists(tokenId), "Genes: Query for nonexistent token");
        
        return _genes[tokenId];
    }    

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }     

    function _baseURI(uint256 tokenId) internal view returns (string memory) {
        if(tokenId > ipfsAt) {
            return baseTokenURI;
        } else {
            return ipfsURI;
        }
    }     

        /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI(tokenId);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }   

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }   
}

interface MintPassContract {
    function burnFromRedeem(address account, uint256 id, uint256 amount) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
 }