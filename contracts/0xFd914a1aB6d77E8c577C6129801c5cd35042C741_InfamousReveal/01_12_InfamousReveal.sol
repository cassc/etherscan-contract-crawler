// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * Infamous Agents
 * The Identies Have Been Revealed
 * Welcome to The S.T.A.T.E
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC721A.sol";

contract InfamousReveal is ERC721, Ownable {

    using Strings for uint256;

//  ==========================================
//  ============= THE S.T.A.T.E ==============
//  ==========================================
    
    string public baseURI;
    bool public paused;
    IERC721A public InfamousUnrevealed;

//  ==========================================
//  ==== SECURITY CLEARANCE VERIFICATION  ====
//  ==========================================

    modifier unpaused() {
        require(!paused, "Paused");
        _;
    }

    constructor() ERC721("InfamousAgents", "IMAG") {}

//  ==========================================
//  ======== RECRUITMENT APPLICATIONS ========
//  ==========================================

    function revealAgents(uint256[] calldata tokenIds) external unpaused {
        for (uint256 i; i < tokenIds.length; i++) {
            InfamousUnrevealed.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, tokenIds[i]);
            _mint(msg.sender, tokenIds[i]);
        }
    }

//  ==========================================
//  ====== TOP SECURITY CLEARANCE ONLY =======
//  ==========================================

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function stopRecruitment(bool _status) external onlyOwner {
        paused = _status;
    }

    function setInfamousUnrevealed(address _address) external onlyOwner {
        InfamousUnrevealed = IERC721A(_address);
    }

//  ==========================================
//  ======== S.T.A.T.E BUSINESS ONLY =========
//  ==========================================

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }
}