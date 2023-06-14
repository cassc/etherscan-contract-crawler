pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: GPL-3.0-only



import "../utils/Common.sol";
import "../utils/Governed.sol";

import "../interface/IERC165.sol";
import "../interface/IERC1155.sol";

/**
 * @notice Base class for ERC1155 contracts. Implements balanceOf and operator methods.
 */
abstract contract ERC1155Base is Governed, IERC1155, IERC165 {
    // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 internal constant ERC1155_ACCEPTED = 0xf23a6e61;
    // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    bytes4 internal constant ERC1155_BATCH_ACCEPTED = 0xbc197c81;
    bytes4 internal constant ERC1155_INTERFACE = 0xd9b67a26;

    mapping(address => mapping(address => bool)) public operators;

    /**
     * @notice ERC165 compatibility for ERC1155
     * @dev skip
     * @param interfaceId the hash signature of the interface id
     */
    function supportsInterface(bytes4 interfaceId) external override view returns (bool) {
        if (interfaceId == ERC1155_INTERFACE) return true;
    }

    /**
     * @notice Get the balance of an account's tokens. For a more complete picture of an account's
     * portfolio, see the method `Portfolios.getAssets()`
     * @param account The address of the token holder
     * @param id ID of the token
     * @return The account's balance of the token type requested
     */
    function balanceOf(address account, uint256 id) external override view returns (uint256) {
        bytes1 assetType = Common.getAssetType(id);

        (uint8 cashGroupId, uint16 instrumentId, uint32 maturity) = Common.decodeAssetId(id);
        (Common.Asset memory asset, ) = Portfolios().searchAccountAsset(
            account,
            assetType,
            cashGroupId,
            instrumentId,
            maturity
        );

        return uint256(asset.notional);
    }

    /**
     * @notice Get the balance of multiple account/token pairs. For a more complete picture of an account's
     * portfolio, see the method `Portfolios.getAssets()`
     * @param accounts The addresses of the token holders
     * @param ids ID of the tokens
     * @return The account's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        override
        view
        returns (uint256[] memory)
    {
        uint256[] memory results = new uint256[](accounts.length);

        for (uint256 i; i < accounts.length; i++) {
            results[i] = this.balanceOf(accounts[i], ids[i]);
        }

        return results;
    }

    /**
     * @notice Encodes a asset object into a uint256 id for ERC1155 compatibility
     * @param asset the asset object to encode
     * @return a uint256 id that is representative of a matching fungible token
     */
    function encodeAssetId(Common.Asset calldata asset) external pure returns (uint256) {
        return Common.encodeAssetId(asset);
    }

    /**
     * @notice Encodes a asset object into a uint256 id for ERC1155 compatibility
     * @param cashGroupId cash group id
     * @param instrumentId instrument id
     * @param maturity maturity of the asset
     * @param assetType asset type identifier
     * @return a uint256 id that is representative of a matching fungible token
     */
    function encodeAssetId(
        uint8 cashGroupId,
        uint16 instrumentId,
        uint32 maturity,
        bytes1 assetType
    ) external pure returns (uint256) {
        Common.Asset memory asset = Common.Asset(cashGroupId, instrumentId, maturity, assetType, 0, 0);

        return Common.encodeAssetId(asset);
    }

    /**
     * @notice Decodes an ERC1155 id into its attributes
     * @param id the asset id to decode
     * @return (cashGroupId, instrumentId, maturity, assetType)
     */
    function decodeAssetId(uint256 id)
        external
        pure
        returns (
            uint8,
            uint16,
            uint32,
            bytes1
        )
    {
        bytes1 assetType = Common.getAssetType(id);
        (uint8 cashGroupId, uint16 instrumentId, uint32 maturity) = Common.decodeAssetId(id);

        return (cashGroupId, instrumentId, maturity, assetType);
    }

    /**
     * @notice Sets approval for an operator to transfer tokens on the sender's behalf
     * @param operator address of the operator
     * @param approved true for complete appoval, false otherwise
     */
    function setApprovalForAll(address operator, bool approved) external override {
        operators[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @notice Determines if the operator is approved for the owner's account
     * @param owner address of the token holder
     * @param operator address of the operator
     * @return true for complete appoval, false otherwise
     */
    function isApprovedForAll(address owner, address operator) public override view returns (bool) {
        return operators[owner][operator];
    }
}