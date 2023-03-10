// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@limit-break/presets/BlacklistedTransferAdventureNFT.sol";
import "@limit-break/utils/tokens/ClaimableHolderMint.sol";
import "@limit-break/utils/tokens/SignedApprovalMint.sol";

/**
 * @title DigiDaigakuDragonEssence
 * @author Limit Break, Inc.
 * @notice Dragon Essences designed to enhance your baby dragon.
 */
contract DigiDaigakuDragonEssence is BlacklistedTransferAdventureNFT, ClaimableHolderMint, SignedApprovalMint {
    constructor(address royaltyReceiver_, uint96 royaltyFeeNumerator_)
        ERC721("", "")
        EIP712("DigiDaigakuDragonEssence", "1")
    {
        initializeERC721("DigiDaigakuDragonEssence", "DIDE");
        initializeURI("https://digidaigaku.com/dragon-essences/metadata/", ".json");
        initializeAdventureERC721(100);
        initializeRoyalties(royaltyReceiver_, royaltyFeeNumerator_);
        initializeOperatorFilterer(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), true);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdventureNFT, IERC165) returns (bool) {
        return interfaceId == type(ISignedApprovalInitializer).interfaceId
            || interfaceId == type(IRootCollectionInitializer).interfaceId || super.supportsInterface(interfaceId);
    }

    function _safeMintToken(address to, uint256 tokenId) internal virtual override {
        _safeMint(to, tokenId);
    }

    function _mintToken(address to, uint256 tokenId) internal virtual override {
        _mint(to, tokenId);
    }
}