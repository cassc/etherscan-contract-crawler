// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./NFTingErrors.sol";

contract NFTingBase is Context, IERC721Receiver, IERC1155Receiver {
    bytes4 internal constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 internal constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    modifier isValidAddress(address _addr) {
        if (
            !_supportsInterface(_addr, INTERFACE_ID_ERC1155) &&
            !_supportsInterface(_addr, INTERFACE_ID_ERC721)
        ) {
            revert InvalidAddressProvided(_addr);
        }

        _;
    }

    modifier isTokenOwnerOrApproved(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amount,
        address _addr
    ) {
        if (_supportsInterface(_nftAddress, INTERFACE_ID_ERC1155)) {
            if (
                IERC1155(_nftAddress).balanceOf(_addr, _tokenId) < _amount &&
                !IERC1155(_nftAddress).isApprovedForAll(_addr, _msgSender())
            ) {
                revert NotTokenOwnerOrInsufficientAmount();
            }
            _;
        } else if (_supportsInterface(_nftAddress, INTERFACE_ID_ERC721)) {
            if (
                IERC721(_nftAddress).ownerOf(_tokenId) != _addr &&
                IERC721(_nftAddress).getApproved(_tokenId) != _addr
            ) {
                revert NotTokenOwnerOrInsufficientAmount();
            }
            _;
        } else {
            revert InvalidAddressProvided(_nftAddress);
        }
    }

    modifier isApprovedMarketplace(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) {
        if (_supportsInterface(_nftAddress, INTERFACE_ID_ERC1155)) {
            if (
                !IERC1155(_nftAddress).isApprovedForAll(_owner, address(this))
            ) {
                revert NotApprovedMarketplace();
            }
            _;
        } else if (_supportsInterface(_nftAddress, INTERFACE_ID_ERC721)) {
            if (
                !IERC721(_nftAddress).isApprovedForAll(_owner, address(this)) &&
                IERC721(_nftAddress).getApproved(_tokenId) != address(this)
            ) {
                revert NotApprovedMarketplace();
            }
            _;
        } else {
            revert InvalidAddressProvided(_nftAddress);
        }
    }

    function _transfer721And1155(
        address _from,
        address _to,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amount
    ) internal virtual {
        if (_amount == 0) {
            revert ZeroAmountTransfer();
        }

        if (_supportsInterface(_nftAddress, INTERFACE_ID_ERC1155)) {
            IERC1155(_nftAddress).safeTransferFrom(
                _from,
                _to,
                _tokenId,
                _amount,
                ""
            );
        } else if (_supportsInterface(_nftAddress, INTERFACE_ID_ERC721)) {
            IERC721(_nftAddress).safeTransferFrom(_from, _to, _tokenId);
        } else {
            revert InvalidAddressProvided(_nftAddress);
        }
    }

    function _supportsInterface(address _addr, bytes4 _interface)
        internal
        view
        returns (bool)
    {
        return IERC165(_addr).supportsInterface(_interface);
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external virtual override returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external virtual override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external virtual override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            type(IERC1155Receiver).interfaceId == _interfaceId ||
            type(IERC721Receiver).interfaceId == _interfaceId;
    }
}