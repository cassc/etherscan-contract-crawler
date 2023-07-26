// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

contract Th3D1g1talG3n3rat1on is Ownable, ERC721A, ReentrancyGuard {
    string private _baseTokenURI;
    uint256 public maxWalletQty = 3;
    bool public paused = true;
    bool public allowListActive = true;
    uint256 public immutable maxMintQty;
    uint256 public immutable amountForTeam;

    mapping(address => bool) public isAllowlistAddress;

    constructor(
        uint256 maxBatchSize_, //3
        uint256 collectionSize_, //333
        uint256 amountForTeam_ //27
    ) ERC721A("Th3 D1g1tal G3n3rat1on", "TDG", maxBatchSize_, collectionSize_) {
        maxMintQty = maxBatchSize_;
        amountForTeam = amountForTeam_;
    }

    function freeMint(uint256 amount) external nonReentrant {
        require(paused == false, "Minting is paused");
        require(amount <= maxMintQty, "Mint quantity is too high");
        require(balanceOf(msg.sender) + amount <= maxWalletQty, "You have hit the max tokens per wallet");
        require(totalSupply() + amount <= collectionSize, "All Minted");
        require(tx.origin == msg.sender, "The caller is another contract");

        if(allowListActive == true) {
            require(isAllowlistAddress[msg.sender], "Address is not in the Allow List");
        }

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

    function allowlistAddresses(address[] calldata wAddresses) public onlyOwner {
        for (uint i = 0; i < wAddresses.length; i++) {
            isAllowlistAddress[wAddresses[i]] = true;
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

    function toggleAllowListActive() public onlyOwner {
        allowListActive = !allowListActive;
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