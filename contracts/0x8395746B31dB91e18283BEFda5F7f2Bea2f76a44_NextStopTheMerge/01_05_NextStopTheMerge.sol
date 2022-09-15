// SPDX-License-Identifier: MIT

// Contract by @Montana_Wong

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NextStopTheMerge is ERC721A, Ownable {

    string public metadataUri;
    mapping(address => bool) public hasMinted;

    /**
     * @notice Determine whether we're running in Proof of Work or Proof of Stake
     * @dev Post-merge, the DIFFICULTY opcode gets renamed to PREVRANDAO,
     * and stores the prevRandao field from the beacon chain state if EIP-4399 is finalized.
     * If not, the difficulty number must be 0 according to EIP-3675, so both possibilities are
     * checked here.
     */
    modifier preMergeOnly() {
        require(!(block.difficulty > 2**64 || block.difficulty == 0), "callable premerge only");
        _;
    }

    constructor(string memory _metadataUri) ERC721A("Next stop, the Merge", "MERGE") {
        metadataUri = _metadataUri;
	_mint(msg.sender, 1);
    }

    function mint() external preMergeOnly {
        require(!hasMinted[msg.sender], "Address already minted.");
        hasMinted[msg.sender] = true;
        _mint(msg.sender, 1);
    }

    function setMetadataUri(string memory _metadataUri) external onlyOwner {
        metadataUri = _metadataUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return bytes(metadataUri).length != 0 ? metadataUri : '';
    }
}