// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./SafePausable.sol";
import "../interfaces/IBatchTransferNFT.sol";

error BatchTransferNFT__UnsupportedContract(address nft);

/**
 * @title BatchTransferNFT
 * @notice Enables to batch transfer multiple NFTs in a single call to this contract
 */
contract BatchTransferNFT is SafePausable, IBatchTransferNFT {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IBatchTransferNFT).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Batch transfer different NFT in a single call
     * @dev The function can get paused
     * @param _transfers The list of transfer.
     * The different nft needs to support either the IERC721 or IERC1155 interface
     */
    function batchTransfer(Transfer[] calldata _transfers)
        external
        override
        whenNotPaused
    {
        uint256 _length = _transfers.length;
        unchecked {
            for (uint256 i; i < _length; ++i) {
                Transfer memory _transfer = _transfers[i];

                if (_isERC721(_transfer.nft)) {
                    IERC721(_transfer.nft).safeTransferFrom(
                        _msgSender(),
                        _transfer.recipient,
                        _transfer.tokenId
                    );
                } else if (_isERC1155(_transfer.nft)) {
                    IERC1155(_transfer.nft).safeTransferFrom(
                        _msgSender(),
                        _transfer.recipient,
                        _transfer.tokenId,
                        _transfer.amount,
                        ""
                    );
                } else {
                    revert BatchTransferNFT__UnsupportedContract(_transfer.nft);
                }
            }
        }
    }

    /**
     * @notice Internal view function to return whether the address supports IERC721
     * @param nft The address of the nft
     * @return Whether the interface is supported or not
     */
    function _isERC721(address nft) internal view returns (bool) {
        return IERC165(nft).supportsInterface(type(IERC721).interfaceId);
    }

    /**
     * @notice Internal view function to return whether the address supports IERC1155
     * @param nft The address of the nft
     * @return Whether the interface is supported or not
     */
    function _isERC1155(address nft) internal view returns (bool) {
        return IERC165(nft).supportsInterface(type(IERC1155).interfaceId);
    }
}