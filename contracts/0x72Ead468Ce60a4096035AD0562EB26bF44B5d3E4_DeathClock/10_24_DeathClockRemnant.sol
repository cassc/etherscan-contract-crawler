// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "solmate/src/tokens/ERC721.sol";

error NoEscape();
error Unauthorized();
error NotMinted();

contract DeathClockRemnant is ERC721 {

    IERC721Metadata private _deathClock;

    constructor(address deathClock)
        ERC721("Death Clock Remnants", "REMNANT") {
        _deathClock = IERC721Metadata(deathClock);
    }

    function mintRemnant(address to, uint256 tokenId) external {
        if (msg.sender != address(_deathClock)) revert Unauthorized();
        _mint(to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if(_ownerOf[tokenId] == address(0)) revert NotMinted();
        return _deathClock.tokenURI(tokenId);
    }

    /// @notice Approval is the first step to transfer, there is no escape.
    function approve(address, uint256) public pure override {
        revert NoEscape();
    }

    /// @notice Approval is the first step to transfer, there is no escape.
    function setApprovalForAll(address, bool) public pure override {
        revert NoEscape();
    }

    /// @notice There is no escape.
    function transferFrom(address, address, uint256) public virtual override {
        revert NoEscape();
    }

    /// @notice There is no escape.
    function safeTransferFrom(address, address, uint256) public virtual override {
        revert NoEscape();
    }

    /// @notice There is no escape.
    function safeTransferFrom(address, address, uint256, bytes calldata) public virtual override {
        revert NoEscape();
    }
}