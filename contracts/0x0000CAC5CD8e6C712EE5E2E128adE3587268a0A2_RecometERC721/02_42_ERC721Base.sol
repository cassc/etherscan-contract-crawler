// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./libraries/PartLib.sol";
import "./libraries/MintERC721Lib.sol";
import "../../../utils/AdminControllerUpgradeable.sol";
import "./extensions/Root.sol";
import "./extensions/Provenance.sol";
import "./extensions/ERC721TxValidatable.sol";
import "./extensions/ERC2771ContextUpgradeable.sol";
import "./extensions/ERC721BurnableUpgradeable.sol";
import "./extensions/ERC721Creator.sol";
import "./extensions/ERC721DefaultApproval.sol";
import "./extensions/ERC721LazyMint.sol";
import "./extensions/ERC721Royalty.sol";
import "./extensions/ERC721TokenURI.sol";

/**
 * @title ERC721Base
 * ERC721Base - The ERC721 central contract.
 */
abstract contract ERC721Base is
    Initializable,
    ContextUpgradeable,
    EIP712Upgradeable,
    ERC721Upgradeable,
    ERC2771ContextUpgradeable,
    AdminControllerUpgradeable,
    Root,
    Provenance,
    ERC721BurnableUpgradeable,
    ERC721Creator,
    ERC721DefaultApproval,
    ERC721LazyMint,
    ERC721Royalty,
    ERC721TokenURI,
    ERC721TxValidatable
{
    function __ERC721Base_init_unchained(
        string memory name,
        string memory version,
        string memory tokenName,
        string memory tokenSymbol,
        address trustedForwarder,
        address[] memory defaultApprovals
    ) internal {
        __Ownable_init_unchained();
        __ERC165_init_unchained();
        __EIP712_init_unchained(name, version);
        __ERC721_init_unchained(tokenName, tokenSymbol);
        __ERC721Burnable_init_unchained();
        __ERC2771Context_init_unchained(trustedForwarder);
        __AdminController_init_unchained(_msgSender());
        for (uint256 i = 0; i < defaultApprovals.length; i++) {
            _setDefaultApproval(defaultApprovals[i], true);
        }
    }

    function setDefaultApproval(address operator, bool status)
        external
        onlyAdminOrOwner
    {
        _setDefaultApproval(operator, status);
    }

    function freezeProvenance() external onlyAdminOrOwner {
        _freezeProvenance();
    }

    function setProvenance(string memory _provenance, bool freezing)
        external
        onlyAdminOrOwner
    {
        _setProvenance(_provenance, freezing);
    }

    function freezeRoot() external onlyAdminOrOwner {
        _freezeRoot();
    }

    function setRoot(bytes32 _root, bool freezing) external onlyAdminOrOwner {
        _setRoot(_root, freezing);
    }

    function freezeTokenStaticURI(uint256 tokenId)
        external
        onlyTokenCreators(tokenId)
    {
        _freezeTokenStaticURI(tokenId);
    }

    function freezeTokenURIBase() external onlyAdminOrOwner {
        _freezeTokenURIBase();
    }

    function setTokenStaticURI(
        uint256 tokenId,
        string memory tokenStaticURI,
        bool freezing
    ) external onlyTokenCreators(tokenId) {
        _setTokenStaticURI(tokenId, tokenStaticURI, freezing);
    }

    function setTokenURIBase(string memory tokenURIBase, bool freezing)
        external
        onlyAdminOrOwner
    {
        _setTokenURIBase(tokenURIBase, freezing);
    }

    function freezeDefaultCreators() external onlyAdminOrOwner {
        _freezeDefaultCreators();
    }

    function freezeTokenCreators(uint256 tokenId)
        external
        onlyTokenCreators(tokenId)
    {
        _freezeTokenCreators(tokenId);
    }

    function setTokenCreators(
        uint256 tokenId,
        PartLib.PartData[] memory creators,
        bool freezing
    ) external onlyTokenCreators(tokenId) {
        _setTokenCreators(tokenId, creators, freezing);
    }

    function setDefaultCreators(
        PartLib.PartData[] memory creators,
        bool freezing
    ) external onlyAdminOrOwner {
        _setDefaultCreators(creators, freezing);
    }

    function freezeDefaultRoyalties() external onlyAdminOrOwner {
        _freezeDefaultRoyalties();
    }

    function freezeTokenRoyalties(uint256 tokenId)
        external
        onlyTokenCreators(tokenId)
    {
        _freezeTokenRoyalties(tokenId);
    }

    function setTokenRoyalties(
        uint256 tokenId,
        PartLib.PartData[] memory royalties,
        bool freezing
    ) external onlyTokenCreators(tokenId) {
        _setTokenRoyalties(tokenId, royalties, freezing);
    }

    function setDefaultRoyalties(
        PartLib.PartData[] memory royalties,
        bool freezing
    ) external onlyAdminOrOwner {
        _setDefaultRoyalties(royalties, freezing);
    }

    function lazyMint(
        MintERC721Lib.MintERC721Data memory mintERC721Data,
        SignatureLib.SignatureData memory signatureData
    ) external override {
        bytes32 mintERC721Hash = MintERC721Lib.hash(mintERC721Data);
        (
            bool isSignatureValid,
            string memory signatureErrorMessage
        ) = _validateTx(mintERC721Data.minter, mintERC721Hash, signatureData);
        require(isSignatureValid, signatureErrorMessage);
        _revokeHash(mintERC721Hash);
        _lazyMint(mintERC721Data);
        if (mintERC721Data.data.length > 0) {
            (
                string memory tokenStaticURI,
                bool tokenStaticURIFreezing,
                PartLib.PartData[] memory tokenCreators,
                bool tokenCreatorsFreezing,
                PartLib.PartData[] memory tokenRoyalties,
                bool tokenRoyaltyFreezing
            ) = abi.decode(
                    mintERC721Data.data,
                    (
                        string,
                        bool,
                        PartLib.PartData[],
                        bool,
                        PartLib.PartData[],
                        bool
                    )
                );
            if (bytes(tokenStaticURI).length > 0) {
                _setTokenStaticURI(
                    mintERC721Data.tokenId,
                    tokenStaticURI,
                    tokenStaticURIFreezing
                );
            }
            if (tokenCreators.length > 0) {
                _setTokenCreators(
                    mintERC721Data.tokenId,
                    tokenCreators,
                    tokenCreatorsFreezing
                );
            }
            if (tokenRoyalties.length > 0) {
                _setTokenRoyalties(
                    mintERC721Data.tokenId,
                    tokenRoyalties,
                    tokenRoyaltyFreezing
                );
            }
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721LazyMint, ERC721Royalty, ERC721Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override(ERC721DefaultApproval, IERC721Upgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return super.isApprovedForAll(owner, operator);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721TokenURI, ERC721Upgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _mint(address to, uint256 tokenId)
        internal
        virtual
        override(ERC721LazyMint, ERC721Upgradeable)
    {
        super._mint(to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(
            ERC721Creator,
            ERC721Royalty,
            ERC721TokenURI,
            ERC721Upgradeable
        )
    {
        super._burn(tokenId);
    }

    function _msgSender()
        internal
        view
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address)
    {
        return super._msgSender();
    }

    function _msgData()
        internal
        view
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes memory)
    {
        return super._msgData();
    }

    function _baseURI()
        internal
        view
        virtual
        override(ERC721TokenURI, ERC721Upgradeable)
        returns (string memory)
    {
        return super._baseURI();
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        override(ERC721DefaultApproval, ERC721Upgradeable)
        returns (bool)
    {
        return super._isApprovedOrOwner(spender, tokenId);
    }

    uint256[50] private __gap;
}