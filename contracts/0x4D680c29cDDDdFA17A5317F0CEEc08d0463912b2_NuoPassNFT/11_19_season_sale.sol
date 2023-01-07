// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

abstract contract SeasonSale is Ownable {
    enum SaleStatus {
        NotStart,
        Paused,
        Saling,
        Finished
    }

    struct SeasonData {
        // store merkleTree id
        uint256 treeId;
        // store round minted count
        uint256 minted;
        // store round maxSupply
        uint256 maxSupply;
        // store round userMaxMint
        uint256 userMaxMint;
        // store price
        uint256 price;
        // store status
        SaleStatus status;
    }

    constructor() Ownable() {}

    // mapping of season and round user minted data, using for limit
    mapping(uint32 => mapping(uint32 => mapping(address => uint256))) internal mintedMap;

    // mapping of season and round data of the proofed charged data, using for limit
    mapping(uint32 => mapping(uint32 => mapping(address => uint256))) internal chargedMap;

    // mapping of season and round config
    mapping(uint32 => mapping(uint32 => SeasonData)) internal _seasonDataMap;

    /**
     * @notice  get user minted count of season and round
     * @dev     .
     * @param   _season  .
     * @param   _round  .
     * @param   user  .
     * @return  uint256  the minted count of user
     */
    function getUserMintedCount(
        uint32 _season,
        uint32 _round,
        address user
    ) public view returns (uint256) {
        return mintedMap[_season][_round][user];
    }

    /**
     * @notice  update the amount of user minted
     * @dev     .
     * @param   _season  .
     * @param   _round  .
     * @param   user  .
     * @param   amount  new amount
     */
    function updateUserMinted(
        uint32 _season,
        uint32 _round,
        address user,
        uint256 amount
    ) internal {
        mintedMap[_season][_round][user] = amount;
    }

    /**
     * @notice  update the amount of user minted
     * @dev     .
     * @param   _season  .
     * @param   _round  .
     * @param   user  .
     * @param   newAmount  new amount
     */
    function addUserMinted(
        uint32 _season,
        uint32 _round,
        address user,
        uint256 newAmount
    ) internal {
        mintedMap[_season][_round][user] = getUserMintedCount(_season, _round, user) + newAmount;
    }

    /**
     * @notice  get round config saved
     * @dev     .
     * @param   _season  .
     * @param   _round  .
     * @return  SeasonConfig  .
     */
    function getRoundData(uint32 _season, uint32 _round) public view returns (SeasonData memory) {
        return _seasonDataMap[_season][_round];
    }

    event LogSeasonConfigUpdate(
        uint32 indexed _season,
        uint32 indexed _round,
        uint treeId,
        uint maxSupply,
        uint256 price,
        uint32 status
    );

    /**
     * @notice  update or create SeasonData
     * @dev     .
     * @param   _season  index: season
     * @param   _round  index: round
     * @param   treeId  param treeId, 0 -> do not update
     * @param   maxSupply  param maxSupply, 0 -> do not update
     * @param   userMaxMint  param userMaxMint, 0 -> do not update
     * @param   price  .param price, can be 0 (free mint)
     * @param   priceUpdate  .flag to control if price shall be updated
     */
    function updateSeasonConfig(
        uint32 _season,
        uint32 _round,
        uint256 treeId,
        uint256 maxSupply,
        uint256 userMaxMint,
        uint256 price,
        uint32 priceUpdate, // 1 = update, 0 = not update
        uint32 status //  [0,5] -> status, 65535 -> not change
    ) public onlyOwner {
        SeasonData storage temp = _seasonDataMap[_season][_round];
        if (treeId > 0) {
            temp.treeId = treeId;
        }
        if (maxSupply > 0) {
            temp.maxSupply = maxSupply;
        }
        if (userMaxMint > 0) {
            temp.userMaxMint = userMaxMint;
        }
        if (priceUpdate == 1) {
            temp.price = price;
        }
        if (status != 65535) {
            temp.status = SaleStatus(status);
        }
        emit LogSeasonConfigUpdate(_season, _round, temp.treeId, temp.maxSupply, temp.price, uint32(temp.status));
    }

    /// pass args to update or init multiple season and rounds
    function bulkUpdateSeasonConfig(uint256[] calldata args) public onlyOwner {
        require(args.length % 8 == 0, "args not valid");
        for (uint256 i = 0; i < args.length; i += 8) {
            updateSeasonConfig(
                uint32(args[i]),
                uint32(args[i + 1]),
                uint256(args[i + 2]),
                uint256(args[i + 3]),
                uint256(args[i + 4]),
                uint256(args[i + 5]),
                uint32(args[i + 6]),
                uint32(args[i + 7])
            );
        }
    }

    function setRoundStatus(
        uint32 _season,
        uint32 _round,
        uint32 _status
    ) public onlyOwner {
        SeasonData storage temp = _seasonDataMap[_season][_round];
        temp.status = SaleStatus(_status);
    }

    function getCharged(
        uint32 _season,
        uint32 _round,
        address _user
    ) public view returns (uint256) {
        return chargedMap[_season][_round][_user];
    }

    function addCharge(
        uint32 _season,
        uint32 _round,
        address _user,
        uint256 amount
    ) internal {
        chargedMap[_season][_round][_user] += amount;
    }

    function cosumeCharge(
        uint32 _season,
        uint32 _round,
        address _user,
        uint256 amount
    ) internal {
        chargedMap[_season][_round][_user] -= amount;
    }
}