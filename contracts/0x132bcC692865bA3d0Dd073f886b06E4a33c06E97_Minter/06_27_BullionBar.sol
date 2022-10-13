// contracts/BullionBar.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BullionBar is ERC721PresetMinterPauserAutoId, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter public tokenIdTracker;

    address public minterAddress;
    
    mapping (uint256 => string) public barCommodity;
    mapping (uint256 => string) public barRefiner;
    mapping (uint256 => string) public barMinter;
    mapping (uint256 => string) public barVault;
    mapping (uint256 => string) public barIdentifier;
    mapping (uint256 => uint256) public barWeight;

    modifier onlyMinter() {
        require(
            minterAddress == msg.sender,
            "Only the minter contract can call this function"
        );
        _;
    }

    event MinterAddressChanged(address indexed minterAddress);
    event BarMinted(uint256 tokenId, address beneficiary, string barComodity, string barRefiner, string barMinter, string barVault, string barIdentifier, uint256 barWeight);
    event ForceTransfer(address indexed to, uint256 tokenId, bytes32 details);

    constructor(string memory name_, string memory symbol_, string memory baseTokenURI_)
        ERC721PresetMinterPauserAutoId(name_, symbol_, baseTokenURI_) {
    }

    /*
     * Set the minter (contract) address
     */
    function setMinterAddress(address minterAddress_) external onlyOwner {
        minterAddress = minterAddress_;
        emit MinterAddressChanged(minterAddress_);
    }        

    /*
     * The minter (contract) can mint bars.
     */
    function mintBar(address beneficiary_, 
    string memory barCommodity_, 
    string memory barRefiner_, 
    string memory barMinter_, 
    string memory barVault_, 
    string memory barIdentifier_, 
    uint256 barWeight_) external onlyMinter {
        require(beneficiary_ != address(0), "Cannot mint to null address");
        uint256 tokenId = tokenIdTracker.current();        
        _mint(beneficiary_, tokenId);        
        
        barCommodity[tokenId] = barCommodity_;
        barRefiner[tokenId] = barRefiner_;
        barMinter[tokenId] = barMinter_;
        barVault[tokenId] = barVault_;
        barIdentifier[tokenId] = barIdentifier_;
        barWeight[tokenId] = barWeight_;
        emit BarMinted(tokenId, beneficiary_, barCommodity_, barRefiner_, barMinter_, barVault_, barIdentifier_, barWeight_);
        tokenIdTracker.increment();
    }

    /*
     * Force transfer callable by owner (governance).
     */ 
    function forceTransfer(address recipient_, uint256 tokenId_, bytes32 details_) external onlyOwner {
        _burn(tokenId_);
        _mint(recipient_,tokenId_);
        emit ForceTransfer(recipient_, tokenId_, details_);
    }    
    
    function getLastTokenId() external view returns (uint256 lastTokenId_) {
        return tokenIdTracker.current();
    }
}