// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../base/BaseClaimNFT.sol";
import "./IPublicClaimNFT.sol";
import "./PublicClaimNFTStorage.sol";

error PublicClaimingNotAllowed();

// solhint-disable func-name-mixedcase
// solhint-disable ordering
contract PublicClaimNFT is IPublicClaimNFT, BaseClaimNFT, PublicClaimNFTStorage {
    event PublicClaimChanged(bool publicClaim);

    function __PublicClaimNFTContract_init(
        address aclContract,
        string memory name,
        string memory symbol,
        string memory baseUri,
        string memory collectionUri,
        uint256 maxEditionTokens,
        uint256 claimValue
    ) internal onlyInitializing {
        __BaseNFTContract_init(aclContract, name, symbol, baseUri, collectionUri);
        __MintNFTContract_init_unchained();
        __BaseClaimNFTContract_init_unchained(maxEditionTokens, claimValue);
        __PublicClaimNFTContract_init_unchained();
    }

    function __PublicClaimNFTContract_init_unchained() internal onlyInitializing {
        _publicClaimAllowed = false;
    }

    function togglePublicClaim() external onlyOperator {
        _publicClaimAllowed = !_publicClaimAllowed;
        emit PublicClaimChanged(_publicClaimAllowed);
    }

    function publicClaim(Edition edition, Size size) external payable returns (uint256 tokenId) {
        if (!_publicClaimAllowed) revert PublicClaimingNotAllowed();
        if (msg.value < _claimValue) revert InvalidClaimValue(msg.value);
        tokenId = _checkedClaim(edition, size);
    }

    function freeClaim(Edition edition, Size size) external onlyFreeClaimer returns (uint256 tokenId) {
        tokenId = _claim(edition, size);
    }

    function isPublicClaimAllowed() external view returns (bool) {
        return _publicClaimAllowed;
    }
}