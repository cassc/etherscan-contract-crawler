// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC1155Invoke.sol";
import "./TokenIdCutoff.sol";

/// @title ERC1155Invoke contract
/// @notice ERC1155 contract that supports the echelon protocol
contract ERC1155InvokeCutoff is ERC1155Invoke, TokenIdCutoff {
    /// @param _allowMultiMint Indicator to allow minting same token id more than once.
    /// @param _uri Metadata url.
    /// @param _name Name of collection.
    /// @param _symbol Symbol for collection.
    constructor(
        bool _allowMultiMint,
        string memory _uri,
        string memory _name,
        string memory _symbol
    ) ERC1155Invoke(_allowMultiMint, _uri, _name, _symbol) {}

    /**
     * @notice Setter for token id cutoff
     * @dev Only callable by owner
     * @param _tokenIdCuttoff New token id cutoff
     */
    function setCutoffTokenId(uint256 _tokenIdCuttoff) external onlyMinter {
        _setCutoffTokenId(_tokenIdCuttoff);
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        string memory _tokenUri,
        bytes memory _data
    ) external virtual override onlyMinter {
        require(_id > cutoffTokenId(), "ERC1155InvokeCutoff: id at cutoff");
        require(
            bytes(_tokenUri).length != 0,
            "ERC1155InvokeCutoff: token uri cannot be empty"
        );

        if (allowMultiMint) {
            require(
                keccak256(bytes(tokenSuffix[_id])) ==
                    keccak256(bytes(_tokenUri)) ||
                    bytes(tokenSuffix[_id]).length == 0,
                "ERC1155InvokeCutoff: token minted with different uri"
            );
        } else {
            require(
                bytes(tokenSuffix[_id]).length == 0,
                "ERC1155InvokeCutoff: token already minted"
            );
        }

        tokenSuffix[_id] = _tokenUri;

        _mint(_to, _id, _amount, _data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        string[] memory _tokenUris,
        bytes memory _data
    ) external virtual override onlyMinter {
        for (uint256 i = 0; i < _ids.length; i++) {
            require(
                _ids[i] > cutoffTokenId(),
                "ERC1155InvokeCutoff: id at cutoff"
            );

            require(
                bytes(_tokenUris[i]).length != 0,
                "ERC1155InvokeCutoff: token uri cannot be empty"
            );

            if (allowMultiMint) {
                require(
                    keccak256(bytes(tokenSuffix[_ids[i]])) ==
                        keccak256(bytes(_tokenUris[i])) ||
                        bytes(tokenSuffix[_ids[i]]).length == 0,
                    "ERC1155InvokeCutoff: token minted with different uri"
                );
            } else {
                require(
                    bytes(tokenSuffix[_ids[i]]).length == 0,
                    "ERC1155InvokeCutoff: token already minted"
                );
            }

            tokenSuffix[_ids[i]] = _tokenUris[i];
        }

        _mintBatch(_to, _ids, _amounts, _data);
    }
}