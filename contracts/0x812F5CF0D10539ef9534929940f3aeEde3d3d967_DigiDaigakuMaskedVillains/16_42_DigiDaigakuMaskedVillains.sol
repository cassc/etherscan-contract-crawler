// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "limit-break-contracts/contracts/presets/BlacklistedTransferAdventureNFT.sol";
import "limit-break-contracts/contracts/utils/tokens/ClaimableHolderMint.sol";
import "limit-break-contracts/contracts/utils/tokens/MerkleWhitelistMint.sol";
import "limit-break-contracts/contracts/utils/tokens/SignedApprovalMint.sol";

contract DigiDaigakuMaskedVillains is BlacklistedTransferAdventureNFT, ClaimableHolderMint, MerkleWhitelistMint, SignedApprovalMint {

    constructor(address royaltyReceiver_, uint96 royaltyFeeNumerator_) ERC721("", "") EIP712("DigiDaigakuMaskedVillains", "1")  {
        initializeERC721("DigiDaigakuMaskedVillains", "DIDMV");
        initializeURI("https://digidaigaku.com/masked-villains/metadata/", ".json");
        initializeAdventureERC721(100);
        initializeRoyalties(royaltyReceiver_, royaltyFeeNumerator_);
        initializeOperatorFilterer(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), true);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdventureNFT, IERC165) returns (bool) {
        return
        interfaceId == type(ISignedApprovalInitializer).interfaceId ||
        interfaceId == type(IRootCollectionInitializer).interfaceId ||
        interfaceId == type(IMerkleRootInitializer).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function _safeMintToken(address to, uint256 tokenId) internal virtual override(ClaimableHolderMint, MerkleWhitelistMint, SignedApprovalMint) {
        _safeMint(to, tokenId);
    }
}