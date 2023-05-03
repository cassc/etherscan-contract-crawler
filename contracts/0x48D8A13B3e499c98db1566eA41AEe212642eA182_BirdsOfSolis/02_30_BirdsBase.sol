// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/token/ERC721/extensions/ERC721Consecutive.sol";
import "@openzeppelin/utils/cryptography/EIP712.sol";
import "@openzeppelin/access/Ownable.sol";
import "./interfaces/IERC4906.sol";
import "@openzeppelin/token/common/ERC2981.sol";
import "@operator-filter-registry/RevokableDefaultOperatorFilterer.sol";
import "@operator-filter-registry/UpdatableOperatorFilterer.sol";

contract BirdsBase is
    ERC721Consecutive,
    EIP712,
    RevokableDefaultOperatorFilterer,
    Ownable,
    IERC4906,
    ERC2981
{
    struct Claim {
        address wallet;
        uint256 tokenId;
    }

    bytes32 private constant MINTKEY_TYPE_HASH =
        keccak256("Claim(address wallet,uint256 tokenId)");

    address private _signer;
    address public vault;

    string private _migratedBaseURI;
    string private _unmigratedBaseURI;

    constructor(
        string memory name_,
        string memory symbol_,
        address signer_,
        address vault_
    ) ERC721(name_, symbol_) EIP712(name_, "1") {
        _signer = signer_;
        vault = vault_;
    }

    function setSigner(address signer) external onlyOwner {
        _signer = signer;
    }

    function verify(
        bytes calldata signature,
        address wallet,
        uint256 tokenId
    ) public view returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(MINTKEY_TYPE_HASH, wallet, tokenId))
        );

        return ECDSA.recover(digest, signature) == _signer;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(IERC165, ERC2981, ERC721) returns (bool) {
        return
            interfaceId == bytes4(0x49064906) || // ERC-4906
            ERC2981.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev Returns the owner of the ERC721 token contract.
     */
    function owner()
        public
        view
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );
        _burn(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = ownerOf(tokenId) == vault
            ? _unmigratedBaseURI
            : _migratedBaseURI;

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    function setMigratedBaseURI(string calldata baseURI_) external onlyOwner {
        _setMigratedBaseURI(baseURI_);
        emit BatchMetadataUpdate(0, 2001);
    }

    function _setMigratedBaseURI(string memory baseURI_) internal {
        _migratedBaseURI = baseURI_;
    }

    function setUnmigratedBaseURI(string calldata baseURI_) external onlyOwner {
        _setUnmigratedBaseURI(baseURI_);
        emit BatchMetadataUpdate(0, 2001);
    }

    function _setUnmigratedBaseURI(string memory baseURI_) internal {
        _unmigratedBaseURI = baseURI_;
    }

    error BadSignature();
}