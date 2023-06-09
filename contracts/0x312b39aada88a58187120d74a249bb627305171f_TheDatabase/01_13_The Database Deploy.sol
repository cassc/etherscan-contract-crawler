// SPDX-License-Identifier: MIT

// ██████╗░██╗░░░██╗███╗░░██╗██╗░░██╗░██████╗
// ██╔══██╗██║░░░██║████╗░██║██║░██╔╝██╔════╝
// ██████╔╝╚██╗░██╔╝██╔██╗██║█████═╝░╚█████╗░
// ██╔═══╝░░╚████╔╝░██║╚████║██╔═██╗░░╚═══██╗
// ██║░░░░░░░╚██╔╝░░██║░╚███║██║░╚██╗██████╔╝
// ╚═╝░░░░░░░░╚═╝░░░╚═╝░░╚══╝╚═╝░░╚═╝╚═════╝░

// The United Government recently got their hands on information leaked from Kaleidoscope.
// It appears as if all Repeat Offenders have been identified, and their info is live on "The Database".
// Do what you must to stay safe and avoid capture at all costs.

// https://pvnks.com/

pragma solidity 0.8.9;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

abstract contract RO {
  function ownerOf(uint256 tokenId) public virtual view returns (address);
}

contract TheDatabase is ERC721, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    RO private ro = RO(0xD0F325e434d5d8143087Ccd16a7c92af223480f7); // RO Mainnet

    bool public claimIsActive = false;

    string private _baseTokenURI;

    constructor() ERC721("The Database", "Entries") { }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        revert("These tokens cannot be transferred");
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        revert("These tokens cannot be transferred");
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        revert("These tokens cannot be transferred");
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return false;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        revert("These tokens cannot be transferred");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        revert("These tokens cannot be transferred");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        revert("These tokens cannot be manually transferred");
    }

     function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function flipClaimState() public onlyOwner {
        claimIsActive = !claimIsActive;
    }

    function claimPortraits(uint256[] memory portraitsToClaim) public {
        require(claimIsActive, "Claim is not active");

        for (uint256 i = 0; i < portraitsToClaim.length; i++) {
        require(ro.ownerOf(portraitsToClaim[i]) == msg.sender, "You do not own this token");
            
            if (_exists(portraitsToClaim[i])){_burn(portraitsToClaim[i]);}
            _safeMint(msg.sender, portraitsToClaim[i]);
        }
    }

    function sendPortraits(uint256[] memory portraitsToSend) public {
        require(claimIsActive, "Claim is not active");

        for (uint256 i = 0; i < portraitsToSend.length; i++) {
            
            if (_exists(portraitsToSend[i])){_burn(portraitsToSend[i]);}
            _safeMint(ro.ownerOf(portraitsToSend[i]), portraitsToSend[i]);
        }
    }

    function portraitClaimed(uint256 _tokenId) external view returns (bool) {
        require(_tokenId < 6666, "Token ID outside collection bounds!");
        return _exists(_tokenId);
    }
}