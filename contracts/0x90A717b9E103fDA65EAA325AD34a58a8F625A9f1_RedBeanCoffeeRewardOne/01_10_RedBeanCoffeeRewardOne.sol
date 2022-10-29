// SPDX-License-Identifier: MIT
// RedBeanCoffeeReward1
pragma solidity 0.8.17;

import "./extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RedBeanCoffeeRewardOne is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 private constant MAX_SUPPLY = 60;
    
    string private baseURI;

    constructor(string memory _initBaseURI) ERC721A("Redbean Coffee Reward 1", "RCR1") {
        require(bytes(_initBaseURI).length > 0, "[Error] Base URI Cannot Be Blank");

        baseURI = _initBaseURI;
    }

    // ===== Check Caller Is User =====
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "[Error] Function cannot be called by a contract");
        _;
    }

    // ===== Dev Mint =====
    function devMint(uint256 quantity) external onlyOwner nonReentrant callerIsUser {
        require(totalSupply() + quantity <= MAX_SUPPLY, "[Error] Max Mint Reached");
        require(quantity > 0, "[Error] Quantity cannot be zero");
        _mint(msg.sender, quantity);
    }

    // ====== override transfer ========
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable virtual override nonReentrant callerIsUser {
        if(to != owner()) {
            require(balanceOf(to) < 1, "This address already has a token");
        }
        safeTransferFrom(from, to, tokenId, '');   
    }

    // ===== Change Base URI =====
    function setBaseURI(string memory newBaseURI) external onlyOwner nonReentrant callerIsUser {
        baseURI = newBaseURI;
    }

    // ===== Set Start Token ID =====
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // ===== Set Base URI =====
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    // ===== Set Token URI =====
    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory) {
		return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    // ===== Add Withdraw Incase Ether Sent =====
    function withdraw() external onlyOwner nonReentrant callerIsUser {
        (bool success,) = payable(owner()).call{value:address(this).balance}("");
        require(success,"Transfer failed!");
    }
}