// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./libraries/logic/ReserveLogic.sol";
import "./libraries/logic/ReserveConfiguration.sol";
import "./libraries/utils/DataTypes.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IKyokoPoolAddressesProvider.sol";

contract KyokoPoolStorage {
    using ReserveLogic for DataTypes.ReserveData;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    IKyokoPoolAddressesProvider internal _addressesProvider;

    mapping(uint256 => DataTypes.ReserveData) internal _reserves;

    // the list of the available nft for each reserves, structured as a mapping for gas savings reasons
    mapping(uint256 => EnumerableSetUpgradeable.AddressSet) internal _reservesNFTList;

    mapping(address => EnumerableSetUpgradeable.UintSet) internal _nftToReserves;

    mapping(uint256 => DataTypes.Rate) internal _ratesList;
    // active NFT on the KyokoPool
    EnumerableSetUpgradeable.AddressSet internal _nfts;

    CountersUpgradeable.Counter internal _borrowId;

    /**
     * @dev borrow and auction info
     */
    mapping(address => EnumerableSetUpgradeable.UintSet) internal userBorrowIdMap;
    // borrowId => BorrowInfo
    mapping(uint256 => DataTypes.BorrowInfo) public borrowMap;
    mapping(uint256 => DataTypes.Auction) public auctionMap;

    uint256 internal _reservesCount;

    bool internal _paused;

    uint256 internal _maxNumberOfReserves;

    address internal _punkGateway;

    IWETH internal WETH;

    uint40 internal MIN_BORROW_TIME;

    EnumerableSetUpgradeable.UintSet internal auctions;
}