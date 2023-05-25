// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

//     ______  ______  ______  ______  _____       ______  ______ ______    
//    /\  == \/\  __ \/\  == \/\  ___\/\  __-.    /\  __ \/\  == /\  ___\   
//    \ \  __<\ \ \/\ \ \  __<\ \  __\\ \ \/\ \   \ \  __ \ \  _-\ \  __\   
//     \ \_____\ \_____\ \_\ \_\ \_____\ \____-    \ \_\ \_\ \_\  \ \_____\ 
//      \/_____/\/_____/\/_/ /_/\/_____/\/____/     \/_/\/_/\/_/   \/_____/ 
//     ______  ______  ______  ______  __  __       __  __  __  __  ______  
//    /\  == \/\  ___\/\  __ \/\  ___\/\ \_\ \     /\ \_\ \/\ \/\ \/\__  _\ 
//    \ \  __<\ \  __\\ \  __ \ \ \___\ \  __ \    \ \  __ \ \ \_\ \/_/\ \/ 
//     \ \_____\ \_____\ \_\ \_\ \_____\ \_\ \_\    \ \_\ \_\ \_____\ \ \_\ 
//      \/_____/\/_____/\/_/\/_/\/_____/\/_/\/_/     \/_/\/_/\/_____/  \/_/ 

contract BoredApeBeachHut is Ownable, ERC721A, ReentrancyGuard {
    string private _baseTokenURI;
    uint256 public maxWalletQty = 10;
    bool public paused = true;
    uint256 public immutable maxMintQty;
    uint256 public immutable amountForTeam;

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_,
        uint256 amountForTeam_
    ) ERC721A("Bored Ape Beach Hut", "BABH", maxBatchSize_, collectionSize_) {
        maxMintQty = maxBatchSize_;
        amountForTeam = amountForTeam_;
    }

    function freeMint(uint256 amount) external nonReentrant {
        require(paused == false, "Minting is paused");
        require(amount <= maxMintQty, "Mint quantity is too high");
        require(balanceOf(msg.sender) + amount <= maxWalletQty, "You have hit the max tokens per wallet");
        require(totalSupply() + amount <= collectionSize, "All Minted");
        require(tx.origin == msg.sender, "The caller is another contract");

        _safeMint(msg.sender, amount);
    }

    //=============================================================================
    // Admin Functions
    //=============================================================================

    function teamMint() external onlyOwner {
        require(paused == true, "Public minting must be paused");
        require(totalSupply() < collectionSize, "All Minted, cannot team mint");
        require(amountForTeam % maxBatchSize == 0, "You can only mint a multiple of the maxBatchSize");
        uint256 numChunks = amountForTeam / maxBatchSize;

        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    function setMaxWalletQty(uint256 qty) public onlyOwner {
        maxWalletQty = qty;
    }

    function togglePaused() public onlyOwner {
        paused = !paused;
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }
    
    //=============================================================================
    // Override Functions
    //=============================================================================

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
       return string(abi.encodePacked(super.tokenURI(tokenId),".json"));
    }
}