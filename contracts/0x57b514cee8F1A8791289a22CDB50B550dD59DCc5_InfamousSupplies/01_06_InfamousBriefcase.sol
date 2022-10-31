// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * Infamous Briefcases
 * Guard them with your life
 * These supplies are essential to survival
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

contract InfamousSupplies is ERC721A, Ownable {

    using Strings for uint256;

//  ==========================================
//  ============= THE S.T.A.T.E ==============
//  ==========================================

    uint256 public constant MAX_SUPPLY = 5555;

    string public baseURI;

    bool public paused;

    mapping(uint256 => uint256) public tierById;


//  ==========================================
//  ==== SECURITY CLEARANCE VERIFICATION  ====
//  ==========================================
    
    modifier unpaused() {
        require(!paused, "Paused");
        _;
    }

    constructor() ERC721A("InfamousSupplies", "INSUP") {}

//  ==========================================
//  =========== SUPPLY DISTRIBUTION ==========
//  ==========================================

    function distributeSupplies(address[] calldata addresses, uint256[] calldata quantities, uint256[] calldata tiers) external onlyOwner unpaused {
        for (uint256 i; i < addresses.length; i++) {
            tierById[_nextTokenId()] = tiers[i];
            _mint(addresses[i], quantities[i]);
        }
    }

//  ==========================================
//  ====== TOP SECURITY CLEARANCE ONLY =======
//  ==========================================

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function adjustTier(uint256 tokenId, uint256 tier) external onlyOwner {
        tierById[tokenId] = tier;
    }

//  ==========================================
//  ======== S.T.A.T.E BUSINESS ONLY =========
//  ==========================================


    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        if (tierById[_tokenId] != 0) {
            return string(abi.encodePacked(baseURI, Strings.toString(tierById[_tokenId])));
        }
        else {
            uint256 tier;
            while (tier == 0) 
            {
                _tokenId--;
                tier = tierById[_tokenId];
            }
            return string(abi.encodePacked(baseURI, Strings.toString(tierById[_tokenId])));
        }
    }

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }
}