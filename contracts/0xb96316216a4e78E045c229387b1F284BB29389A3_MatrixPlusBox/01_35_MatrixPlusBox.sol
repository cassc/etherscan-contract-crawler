// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@divergencetech/ethier/contracts/erc721/BaseTokenURI.sol";
import "@divergencetech/ethier/contracts/utils/OwnerPausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "../EIP5058/extensions/ERC5058Bound.sol";
import "../utils/ERC721Attachable.sol";
import "../utils/TokenWithdraw.sol";

//       _____            _____
//      |  __ \     /\   / ____|   /\
//      | |__) |   /  \ | |       /  \
//      |  _  /   / /\ \| |      / /\ \
//      | | \ \  / ____ \ |____ / ____ \
//      |_|  \_\/_/    \_\_____/_/    \_\

contract MatrixPlusBox is
    Context,
    OwnerPausable,
    BaseTokenURI,
    ERC721Enumerable,
    ERC721Pausable,
    ERC5058Bound,
    ERC721Attachable,
    ERC721Royalty,
    AccessControlEnumerable,
    TokenWithdraw
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant UNBIND_ROLE = keccak256("UNBIND_ROLE");

    constructor() ERC721("Matrix Plus Box", "MPB") BaseTokenURI("https://api.bakeryswap.org/nft/matrix-plus-box/") {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(BURNER_ROLE, _msgSender());
        _grantRole(UNBIND_ROLE, _msgSender());
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) external onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId, data);
    }

    function lockMint(
        address to,
        uint256 tokenId,
        uint256 expired,
        bytes memory data
    ) external onlyRole(MINTER_ROLE) {
        _safeLockMint(to, tokenId, expired, data);
    }

    function mint(address to, uint256 tokenId) external onlyRole(MINTER_ROLE) {
        _mint(to, tokenId);
    }

    function mintBatch(address to, uint256[] calldata tokenIds) external onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mint(to, tokenIds[i]);
        }
    }

    function mintRange(
        address to,
        uint256 fromId,
        uint256 toId
    ) external onlyRole(MINTER_ROLE) {
        for (; fromId <= toId; fromId++) {
            _mint(to, fromId);
        }
    }

    function burn(uint256 tokenId) external {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId) ||
                hasRole(BURNER_ROLE, _msgSender()) ||
                masterOf(tokenId) == _msgSender(),
            "ERC721: caller is not owner nor approved"
        );

        _burn(tokenId);
    }

    function slaveMint(
        address to,
        uint256 tokenId,
        address collection,
        uint256 hostTokenId
    ) external onlyRole(MINTER_ROLE) {
        _slaveMint(to, tokenId, collection, hostTokenId);
    }

    function removeSlave(uint256 tokenId) external {
        require(hasRole(UNBIND_ROLE, _msgSender()) || masterOf(tokenId) == _msgSender(), "ERC721: not unbind role");

        _removeSlave(tokenId);
    }

    function removeMaster(uint256 tokenId) external onlyRole(UNBIND_ROLE) {
        _removeMaster(tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, ERC721Attachable) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override(ERC721, ERC721Attachable) {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function setRoleAdmin(bytes32 roleId, bytes32 adminRoleId) external onlyOwner {
        _setRoleAdmin(roleId, adminRoleId);
    }

    function setFactory(address factory) external onlyOwner {
        _setFactory(factory);
    }

    function setDefaultRoyaltyInfo(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address recipient,
        uint96 fraction
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, recipient, fraction);
    }

    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    function _baseURI() internal view override(BaseTokenURI, ERC721) returns (string memory) {
        return BaseTokenURI._baseURI();
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721Royalty, ERC5058, ERC721Attachable) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable, ERC5058) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, ERC5058, ERC721Royalty, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}