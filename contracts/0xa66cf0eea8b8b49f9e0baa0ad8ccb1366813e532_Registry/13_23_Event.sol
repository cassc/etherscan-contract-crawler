// SPDX-License-Identifier: MIT
// Creator: Nullion Labs

pragma solidity 0.8.11;

import './interfaces/IEvent.sol';
import './extensions/ERC721A.sol';
import './extensions/ERC721APausable.sol';
import './extensions/ERC721ABurnable.sol';

contract Event is ERC721A, ERC721ABurnable, ERC721APausable, IEvent {
    string private _baseTokenURI;

    constructor(
        string memory name,
        string memory symbol,
        uint256[] memory ticketTypes,
        string memory baseTokenURI,
        address registry
    ) ERC721A(name, symbol, ticketTypes) {
        _baseTokenURI = baseTokenURI;
        transferOwnership(registry);
    }

    receive() external payable {
        revert();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function pause() public virtual onlyOwner {
        _pause();
    }

    function unpause() public virtual onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721A, ERC721APausable) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        require(!paused(), 'ERC721Pausable: token transfer while paused');
    }

    function mint(address to, uint256[] memory ticketTypes) external onlyOwner returns (uint256 startId) {
        require(to != address(0), 'ERC721: mint to the zero address');
        startId = _nextTokenId();
        _mint(to, ticketTypes);
    }
}