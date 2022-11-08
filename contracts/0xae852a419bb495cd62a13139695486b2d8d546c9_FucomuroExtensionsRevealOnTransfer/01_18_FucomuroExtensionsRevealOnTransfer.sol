// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 ________ 
|\  _____\
\ \  \__/ 
 \ \   __\
  \ \  \_|
   \ \__\ 
    \|__|  fucomuro.eth
          
 */

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ERC1155/IERC1155CreatorExtensionBurnable.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ERC1155/IERC1155CreatorExtensionApproveTransfer.sol";

contract FucomuroExtensionsRevealOnTransfer is
    AdminControl,
    ICreatorExtensionTokenURI,
    IERC1155CreatorExtensionBurnable,
    IERC1155CreatorExtensionApproveTransfer
{
    struct TokenUriStruct {
        string revealed;
        string scrubbed;
        bool isHidden;
    }
    using Strings for uint256;

    address private _creator;
    bool private _allowBurn;
    mapping(uint256 => TokenUriStruct) _tokenURIs;
    mapping(uint256 => bool) _deletedTokenURIs;

    constructor(address creator) {
        _creator = creator;
        _allowBurn = false;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AdminControl, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            interfaceId == type(IERC1155CreatorExtensionBurnable).interfaceId ||
            interfaceId ==
            type(IERC1155CreatorExtensionApproveTransfer).interfaceId ||
            AdminControl.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function mintNew(
        address[] calldata to,
        uint256[] calldata amounts,
        string[] calldata tokenUris,
        string[] calldata scrubbedTokenUris
    ) external adminRequired {
        string[] memory emptyUris;
        uint256[] memory tokenIds = IERC1155CreatorCore(_creator)
            .mintExtensionNew(to, amounts, emptyUris);
        for (uint i = 0; i < tokenIds.length; i++) {
            require(
                abi.encodePacked(tokenUris[i]).length > 0,
                "token uri cannot be empty"
            );
            _tokenURIs[tokenIds[i]] = TokenUriStruct({
                revealed: tokenUris[i],
                scrubbed: scrubbedTokenUris[i],
                isHidden: abi.encodePacked(scrubbedTokenUris[i]).length > 0
            });
            _deletedTokenURIs[tokenIds[i]] = false;
        }
    }

    /**
     * @dev See {IERC1155CreatorExtensionApproveTransfer-setApproveTransfer}
     */
    function setApproveTransfer(address creator, bool enabled)
        external
        override
        adminRequired
    {
        require(
            ERC165Checker.supportsInterface(
                creator,
                type(IERC1155CreatorCore).interfaceId
            ),
            "creator must implement IERC1155CreatorCore"
        );
        IERC1155CreatorCore(creator).setApproveTransferExtension(enabled);
    }

    function approveTransfer(
        address,
        address,
        uint256[] calldata tokenIds,
        uint256[] calldata
    ) external virtual override returns (bool) {
        for (uint i = 0; i < tokenIds.length; i++) {
            if (_tokenURIs[tokenIds[i]].isHidden) {
                _tokenURIs[tokenIds[i]].isHidden = false;
            }
        }
        return true;
    }

    function tokenURI(address creator, uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _creator == creator && _deletedTokenURIs[tokenId] == false,
            "Invalid token"
        );
        TokenUriStruct memory metadata = _tokenURIs[tokenId];
        return metadata.isHidden ? metadata.scrubbed : metadata.revealed;
    }

    function enableBurn(bool enabled) public adminRequired {
        _allowBurn = enabled;
    }

    function onBurn(
        address owner,
        uint256[] calldata tokenIds,
        uint256[] calldata
    ) public virtual override {
        require(
            _allowBurn || isAdmin(owner),
            "only creator can burn right now"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            delete _tokenURIs[tokenIds[i]];
            _deletedTokenURIs[tokenIds[i]] = true;
        }
    }
}