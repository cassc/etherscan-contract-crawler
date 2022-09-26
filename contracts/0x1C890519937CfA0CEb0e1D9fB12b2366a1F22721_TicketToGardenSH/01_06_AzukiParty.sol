// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "erc721a/contracts/ERC721A.sol";

contract TicketToGardenSH is Ownable, ERC721A, Pausable {

    string private _internalBaseURI;


    constructor(string memory baseuri) ERC721A("Ticket to Garden SH", "TicketToGardenSH") {
        _internalBaseURI = baseuri;
        _pause();
    }

    function Airdrop(address[] calldata accounts, uint256[] calldata nums) external onlyOwner {
        require(accounts.length == nums.length);
        for (uint i = 0; i < accounts.length; i++) {
            super._safeMint(accounts[i], nums[i]);
        }
    }

    function setBaseURI(string memory internalBaseURI_) external onlyOwner {
        _internalBaseURI = internalBaseURI_;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _internalBaseURI;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override virtual {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        require(!paused() || msg.sender == owner());
    }

    function setApprovalForAll(address operator, bool _approved)
        public
        virtual
        override(ERC721A) {
        super.setApprovalForAll(operator, _approved);
        require(!paused());
    }

    function approve(address to, uint256 tokenId)
        public
        virtual
        override(ERC721A) {
        super.approve(to, tokenId);
        require(!paused());
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        require(!paused());
        return super.isApprovedForAll(owner, operator);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(!paused());
        return super.getApproved(tokenId);
    }
}