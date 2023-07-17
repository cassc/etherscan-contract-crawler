/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 *
 */
abstract contract ERC1155Supply is ERC1155 {
    /**
     * @dev keeps track of per-token id's total supply, as well as overall supply.
     *      also used as a counter when minting, by reading the .length property of the array.
     * @dev toalSupply MUST be incremented by the implementing contract, as `_beforeTokenTransfer` function
     *      has been removed in order to make normal (non-mint) transfers cheaper.
     */
    uint256[] internal _totalSupply;

    /**
     * @dev Total amount of tokens in with a given _id.
     * @dev > The total value transferred from address 0x0 minus the total value transferred to 0x0 observed via the TransferSingle and TransferBatch events MAY be used by clients and exchanges to determine the “circulating supply” for a given token ID.
     */
    function totalSupply(uint256 _id) public view returns (uint256) {
        return _totalSupply[_id];
    }

    /**
     * @dev Amount of unique token ids in this collection, required in order to
     *      enumerate `_totalSupply` (or `_tokenURIs`, see {ERC1155URIStorage-uri}) from a client
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply.length;
    }

    /**
     * @dev Indicates whether any token exist with a given _id, or not.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function exists(uint256 _id) public view returns (bool) {
        return _totalSupply.length > _id;
    }
}