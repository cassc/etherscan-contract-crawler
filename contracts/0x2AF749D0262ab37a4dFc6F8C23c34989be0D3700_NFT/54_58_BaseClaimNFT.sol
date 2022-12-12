// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "../../state/StateNFTStorage.sol";
import "../../mint/MintNFT.sol";
import "./IBaseClaimNFT.sol";
import "./BaseClaimNFTStorage.sol";

error InvalidClaimValue(uint256 value);
error MaxEditionSupplyReached(StateNFTStorage.Edition edition, uint256 supply);
error ClaimingNotAllowed();

// solhint-disable func-name-mixedcase
// solhint-disable ordering
contract BaseClaimNFT is IBaseClaimNFT, MintNFT, BaseClaimNFTStorage {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    event ClaimValueChanged(uint256 claimValue);
    event ClaimChanged(bool claimAllowed);

    function __BaseClaimNFTContract_init(
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
    }

    function __BaseClaimNFTContract_init_unchained(uint256 maxEditionTokens, uint256 claimValue)
        internal
        onlyInitializing
    {
        _claimAllowed = false;
        _claimValue = claimValue;
        _maxEditionTokens = maxEditionTokens;
    }

    function setClaimValue(uint256 claimValue) external onlyOperator {
        _claimValue = claimValue;
        emit ClaimValueChanged(claimValue);
    }

    function toggleClaim() external onlyOperator {
        _claimAllowed = !_claimAllowed;
        emit ClaimChanged(_claimAllowed);
    }

    function getClaimValue() external view returns (uint256) {
        return _claimValue;
    }

    function isClaimAllowed() external view returns (bool) {
        return _claimAllowed;
    }

    function getEditionTokenCounter(Edition edition) external view returns (uint256) {
        return _editionTokenCounters[edition].current();
    }

    function _checkedClaim(Edition edition, Size size) internal returns (uint256 tokenId) {
        if (!_claimAllowed) revert ClaimingNotAllowed();
        tokenId = _claim(edition, size);
    }

    function _claim(Edition edition, Size size) internal returns (uint256 tokenId) {
        if (_editionTokenCounters[edition].current() == _maxEditionTokens)
            revert MaxEditionSupplyReached(edition, _maxEditionTokens);

        _editionTokenCounters[edition].increment();

        tokenId = this.mint(msg.sender);

        _tokenNumbers[tokenId] = _editionTokenCounters[edition].current();
        _tokenEditions[tokenId] = edition;
        _tokenSizes[tokenId] = size;
        _tokenRedeems[tokenId] = false;
    }
}