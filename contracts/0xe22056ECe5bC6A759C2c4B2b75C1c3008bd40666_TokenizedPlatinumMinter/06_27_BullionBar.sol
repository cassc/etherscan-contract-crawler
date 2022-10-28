// contracts/BullionBar.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BullionBar is ERC721PresetMinterPauserAutoId, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter public tokenIdTracker;

    address[] public minters;    
    mapping (address => bool) public isMinter;
    
    mapping (uint256 => string) public barCommodity;
    mapping (uint256 => string) public barIdentifier;
    mapping (uint256 => string) public barVault;
    mapping (uint256 => string) public barFineness;
    mapping (uint256 => uint256) public barWeight;

    modifier onlyMinter() {
        require(
            isMinter[msg.sender],
            "BullionBar: Only a minter can call this function"
        );
        _;
    }

    event MinterAdded(address indexed minterAddress);
    event MinterRemoved(address indexed minterAddress);
    event BarMinted(uint256 tokenId, address beneficiary, string barCommodity, string barIdentifier, string barFineness, string barVault, uint256 barWeight);
    event BarBurned(uint256 tokenId, string barCommodity, string barIdentifier, string barFineness, string barVault, uint256 barWeight);
    event BarUpdated(uint256 tokenId, string barCommodity, string barIdentifier, string barFineness, string barVault, uint256 barWeight);
    event ForceTransfer(address indexed to, uint256 tokenId, bytes32 details);

    constructor(string memory name_, string memory symbol_, string memory baseTokenURI_)
        ERC721PresetMinterPauserAutoId(name_, symbol_, baseTokenURI_) {
    }

    /*
     * Owner can add a minter
     */
    function addMinter(address minterAddress_) external onlyOwner {
        require(minterAddress_ != address(0), "Minter cannot be null");
        minters.push(minterAddress_);
        isMinter[minterAddress_] = true;
        emit MinterAdded(minterAddress_);
    }

    /*
     * Owner can remove minter
     */
    function removeMinter(address minterAddress_, uint256 index_) external onlyOwner {
        minters.push(minterAddress_);
        require(index_ < minters.length, "Cannot find minter to remove");
        minters[index_] = minters[minters.length-1];
        minters.pop();
        isMinter[minterAddress_] = false;
        emit MinterRemoved(minterAddress_);
    }

    /*
     * A minter can mint bars
     */
    function mintBar(address beneficiary_, 
        string calldata commodity_,   
        string calldata identifier_, 
        string calldata fineness_, 
        string calldata vault_,     
        uint256 weight_) external onlyMinter {
        require(beneficiary_ != address(0), "Cannot mint to null address");
        uint256 tokenId = tokenIdTracker.current();        
        _mint(beneficiary_, tokenId); 
        
        barCommodity[tokenId] = commodity_;
        barIdentifier[tokenId] = identifier_;
        barVault[tokenId] = vault_;
        barFineness[tokenId] = fineness_;        
        barWeight[tokenId] = weight_;

        emit BarMinted(tokenId, beneficiary_, commodity_, identifier_, fineness_, vault_, weight_);
        tokenIdTracker.increment();
    }

    /*
     * A minter can burn a bar
     */
    function burnBar(uint256 tokenId_) external onlyMinter {
        require((ownerOf(tokenId_) == msg.sender),"The minter needs to hold the BullionBar");
        _burn(tokenId_);
        emit BarBurned(tokenId_, barCommodity[tokenId_], barIdentifier[tokenId_], barFineness[tokenId_], barVault[tokenId_], barWeight[tokenId_]);
    }

    /*
     * Force transfer callable by owner (governance). Event emitted
     */ 
    function forceTransfer(address recipient_, uint256 tokenId_, bytes32 details_) external onlyOwner {
        _burn(tokenId_);
        _mint(recipient_,tokenId_);
        emit ForceTransfer(recipient_, tokenId_, details_);
    }    

    /*
     * Owner (governance) can update the bar. Event emitted
     */
    function updateBar(uint256 tokenId_,
        string calldata commodity_,   
        string calldata identifier_, 
        string calldata fineness_, 
        string calldata vault_,
        uint256 weight_) external onlyOwner {
        barCommodity[tokenId_] = commodity_;
        barIdentifier[tokenId_] = identifier_;
        barVault[tokenId_] = vault_;
        barFineness[tokenId_] = fineness_;        
        barWeight[tokenId_] = weight_;
        emit BarUpdated(tokenId_, commodity_, identifier_, fineness_, vault_, weight_);
    }
    
    function getLastTokenId() external view returns (uint256 lastTokenId_) {
        return tokenIdTracker.current();
    }
}