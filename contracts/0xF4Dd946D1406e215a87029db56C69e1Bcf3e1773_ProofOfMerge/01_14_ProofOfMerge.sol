// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title: Proof of Merge
/// @author: x0r (Michael Blau) and Mason Hall

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {LicenseVersion, CantBeEvil} from "@a16z/contracts/licenses/CantBeEvil.sol";
import {IASCIIGenerator} from "./IASCIIGenerator.sol";

contract ProofOfMerge is ERC1155, Ownable, CantBeEvil(LicenseVersion.CBE_CC0) {

    // =================== CUSTOM ERRORS =================== //

    error NonTransferableToken();
    error CantMintPostMerge();
    error NonexistentToken();
    error AlreadyMinted();


    address public asciiGenerator;
    mapping(address => bool) public hasMinted;

    constructor(address _asciiGenerator) ERC1155("") {
        asciiGenerator = _asciiGenerator;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, CantBeEvil)
        returns (bool)
    {
        return
            ERC1155.supportsInterface(interfaceId) ||
            CantBeEvil.supportsInterface(interfaceId);
    }

    /**
     * @notice Mint a single Proof of Merge NFT. You can't mint after the merge. One NFT per address.
     */
    function mint() external {
        if (hasMinted[msg.sender]) revert AlreadyMinted();
        if (mergeHasOccured()) revert CantMintPostMerge();
        hasMinted[msg.sender] = true;
        _mint(msg.sender, 1, 1, "");
    }

    /**
     * @notice You can burn the NFT.
     */
    function burn() external {
        _burn(msg.sender, 1, 1);
    }

    /**
     * @notice The Proof of Merge NFT is non-transferable.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        if (from != address(0) && to != address(0)) {
            revert NonTransferableToken();
        }
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     */
    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (_tokenId != 1) revert NonexistentToken();
        return IASCIIGenerator(asciiGenerator).generateMetadata();
    }

    /**
     * @notice Determine whether we're running in Proof of Work or Proof of Stake
     * @dev Post-merge, the DIFFICULTY opcode gets renamed to PREVRANDAO,
     * and stores the prevRandao field from the beacon chain state if EIP-4399 is finalized.
     * If not, the difficulty number must be 0 according to EIP-3675, so both possibilities are
     * checked here.
     */
    function mergeHasOccured() public view returns (bool) {
        return block.difficulty > 2**64 || block.difficulty == 0;
    }

    // =================== ADMIN FUNCTIONS =================== //

    function setASCIIGenerator(address _asciiGenerator) external onlyOwner {
        asciiGenerator = _asciiGenerator;
    }
}