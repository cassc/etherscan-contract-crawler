// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../mint/MintNFT.sol";
import "../state/StateNFT.sol";
import "./RedeemNFTStorage.sol";
import "./IRedeemNFT.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

error NotApprovedOrOwner(address owner);

// solhint-disable func-name-mixedcase
// solhint-disable ordering
contract RedeemNFT is IRedeemNFT, MintNFT, StateNFT, RedeemNFTStorage {
    event PermanentURI(string _value, uint256 indexed _id);

    function __RedeemNFTContract_init(
        address aclContract,
        string memory name,
        string memory symbol,
        string memory baseUri,
        string memory collectionUri
    ) internal onlyInitializing {
        __BaseNFTContract_init(aclContract, name, symbol, baseUri, collectionUri);
        __MintNFTContract_init_unchained();
        __RedeemNFTContract_init_unchained();
    }

    function __RedeemNFTContract_init_unchained() internal onlyInitializing {}

    function redeem(uint256 tokenId, address owner) external onlyOperator returns (uint256 newTokenId) {
        _requireMinted(tokenId);
        if (!_isApprovedOrOwner(owner, tokenId)) revert NotApprovedOrOwner(owner);
        _burn(tokenId);

        newTokenId = this.mint(owner);
        _tokenNumbers[newTokenId] = _tokenNumbers[tokenId];
        _tokenSizes[newTokenId] = _tokenSizes[tokenId];
        _tokenEditions[newTokenId] = _tokenEditions[tokenId];
        _tokenRedeems[newTokenId] = true;

        emit PermanentURI(tokenURI(tokenId), tokenId);
        emit PermanentURI(tokenURI(newTokenId), newTokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(StateNFT, ERC721Upgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}