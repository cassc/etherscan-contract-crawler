// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

import "./abstracts/OwnableFactoryHandler.sol";

/// @title Tracks data for underlying assets of NestedNFTs
contract NestedRecords is OwnableFactoryHandler {
    /* ------------------------------ EVENTS ------------------------------ */

    /// @dev Emitted when maxHoldingsCount is updated
    /// @param maxHoldingsCount The new value
    event MaxHoldingsChanges(uint256 maxHoldingsCount);

    /// @dev Emitted when the lock timestamp of an NFT is increased
    /// @param nftId The NFT ID
    /// @param timestamp The new lock timestamp of the portfolio
    event LockTimestampIncreased(uint256 nftId, uint256 timestamp);

    /// @dev Emitted when the reserve is updated for a specific portfolio
    /// @param nftId The NFT ID
    /// @param newReserve The new reserve address
    event ReserveUpdated(uint256 nftId, address newReserve);

    /* ------------------------------ STRUCTS ------------------------------ */

    /// @dev Store user asset informations
    struct NftRecord {
        mapping(address => uint256) holdings;
        address[] tokens;
        address reserve;
        uint256 lockTimestamp;
    }

    /* ----------------------------- VARIABLES ----------------------------- */

    /// @dev stores for each NFT ID an asset record
    mapping(uint256 => NftRecord) public records;

    /// @dev The maximum number of holdings for an NFT record
    uint256 public maxHoldingsCount;

    /* ---------------------------- CONSTRUCTOR ---------------------------- */

    constructor(uint256 _maxHoldingsCount) {
        maxHoldingsCount = _maxHoldingsCount;
    }

    /* -------------------------- OWNER FUNCTIONS -------------------------- */

    /// @notice Sets the maximum number of holdings for an NFT record
    /// @param _maxHoldingsCount The new maximum number of holdings
    function setMaxHoldingsCount(uint256 _maxHoldingsCount) external onlyOwner {
        require(_maxHoldingsCount != 0, "NRC: INVALID_MAX_HOLDINGS");
        maxHoldingsCount = _maxHoldingsCount;
        emit MaxHoldingsChanges(maxHoldingsCount);
    }

    /* ------------------------- FACTORY FUNCTIONS ------------------------- */

    /// @notice Update the amount for a specific holding and delete
    /// the holding if the amount is zero.
    /// @param _nftId The id of the NFT
    /// @param _token The token/holding address
    /// @param _amount Updated amount for this asset
    function updateHoldingAmount(
        uint256 _nftId,
        address _token,
        uint256 _amount
    ) public onlyFactory {
        if (_amount == 0) {
            uint256 tokenIndex = 0;
            address[] memory tokens = getAssetTokens(_nftId);
            while (tokenIndex < tokens.length) {
                if (tokens[tokenIndex] == _token) {
                    deleteAsset(_nftId, tokenIndex);
                    break;
                }
                tokenIndex++;
            }
        } else {
            records[_nftId].holdings[_token] = _amount;
        }
    }

    /// @notice Fully delete a holding record for an NFT
    /// @param _nftId The id of the NFT
    /// @param _tokenIndex The token index in holdings array
    function deleteAsset(uint256 _nftId, uint256 _tokenIndex) public onlyFactory {
        address[] storage tokens = records[_nftId].tokens;
        address token = tokens[_tokenIndex];

        require(records[_nftId].holdings[token] != 0, "NRC: HOLDING_INACTIVE");

        delete records[_nftId].holdings[token];
        tokens[_tokenIndex] = tokens[tokens.length - 1];
        tokens.pop();
    }

    /// @notice Delete a holding item in holding mapping. Does not remove token in NftRecord.tokens array
    /// @param _nftId NFT's identifier
    /// @param _token Token address for holding to remove
    function freeHolding(uint256 _nftId, address _token) public onlyFactory {
        delete records[_nftId].holdings[_token];
    }

    /// @notice Helper function that creates a record or add the holding if record already exists
    /// @param _nftId The NFT's identifier
    /// @param _token The token/holding address
    /// @param _amount Amount to add for this asset
    /// @param _reserve Reserve address
    function store(
        uint256 _nftId,
        address _token,
        uint256 _amount,
        address _reserve
    ) external onlyFactory {
        NftRecord storage _nftRecord = records[_nftId];

        uint256 amount = records[_nftId].holdings[_token];
        require(_amount != 0, "NRC: INVALID_AMOUNT");
        if (amount != 0) {
            require(_nftRecord.reserve == _reserve, "NRC: RESERVE_MISMATCH");
            updateHoldingAmount(_nftId, _token, amount + _amount);
            return;
        }
        require(_nftRecord.tokens.length < maxHoldingsCount, "NRC: TOO_MANY_TOKENS");
        require(
            _reserve != address(0) && (_reserve == _nftRecord.reserve || _nftRecord.reserve == address(0)),
            "NRC: INVALID_RESERVE"
        );

        _nftRecord.holdings[_token] = _amount;
        _nftRecord.tokens.push(_token);
        _nftRecord.reserve = _reserve;
    }

    /// @notice The factory can update the lock timestamp of a NFT record
    /// The new timestamp must be greater than the records lockTimestamp
    //  if block.timestamp > actual lock timestamp
    /// @param _nftId The NFT id to get the record
    /// @param _timestamp The new timestamp
    function updateLockTimestamp(uint256 _nftId, uint256 _timestamp) external onlyFactory {
        require(_timestamp > records[_nftId].lockTimestamp, "NRC: LOCK_PERIOD_CANT_DECREASE");
        records[_nftId].lockTimestamp = _timestamp;
        emit LockTimestampIncreased(_nftId, _timestamp);
    }

    /// @notice Delete from mapping assetTokens
    /// @param _nftId The id of the NFT
    function removeNFT(uint256 _nftId) external onlyFactory {
        delete records[_nftId];
    }

    /// @notice Set the reserve where assets are stored
    /// @param _nftId The NFT ID to update
    /// @param _nextReserve Address for the new reserve
    function setReserve(uint256 _nftId, address _nextReserve) external onlyFactory {
        records[_nftId].reserve = _nextReserve;
        emit ReserveUpdated(_nftId, _nextReserve);
    }

    /* ------------------------------- VIEWS ------------------------------- */

    /// @notice Get content of assetTokens mapping
    /// @param _nftId The id of the NFT
    /// @return Array of token addresses
    function getAssetTokens(uint256 _nftId) public view returns (address[] memory) {
        return records[_nftId].tokens;
    }

    /// @notice Get reserve the assets are stored in
    /// @param _nftId The NFT ID
    /// @return The reserve address these assets are stored in
    function getAssetReserve(uint256 _nftId) external view returns (address) {
        return records[_nftId].reserve;
    }

    /// @notice Get how many tokens are in a portfolio/NFT
    /// @param _nftId NFT ID to examine
    /// @return The array length
    function getAssetTokensLength(uint256 _nftId) external view returns (uint256) {
        return records[_nftId].tokens.length;
    }

    /// @notice Get holding amount for a given nft id
    /// @param _nftId The id of the NFT
    /// @param _token The address of the token
    /// @return The holding amount
    function getAssetHolding(uint256 _nftId, address _token) public view returns (uint256) {
        return records[_nftId].holdings[_token];
    }

    /// @notice Returns the holdings associated to a NestedAsset
    /// @param _nftId the id of the NestedAsset
    /// @return Two arrays with the same length :
    ///         - The token addresses in the portfolio
    ///         - The respective amounts
    function tokenHoldings(uint256 _nftId) external view returns (address[] memory, uint256[] memory) {
        address[] memory tokens = getAssetTokens(_nftId);
        uint256 tokensCount = tokens.length;
        uint256[] memory amounts = new uint256[](tokensCount);

        for (uint256 i = 0; i < tokensCount; i++) {
            amounts[i] = getAssetHolding(_nftId, tokens[i]);
        }
        return (tokens, amounts);
    }

    /// @notice Get the lock timestamp of a portfolio/NFT
    /// @param _nftId The NFT ID
    /// @return The lock timestamp from the NftRecord
    function getLockTimestamp(uint256 _nftId) external view returns (uint256) {
        return records[_nftId].lockTimestamp;
    }
}