// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import '../libraries/BespokeTypes.sol';

interface IOpenSkyBespokeSettings {
    event InitLoanAddress(address operator, address borrowLoanAddress, address lendLoanAddress);
    event InitMarketAddress(address operator, address address_);

    event SetReserveFactor(address operator, uint256 factor);
    event SetOverdueLoanFeeFactor(address operator, uint256 factor);

    event SetMinBorrowDuration(address operator, uint256 factor);
    event SetMaxBorrowDuration(address operator, uint256 factor);
    event SetOverdueDuration(address operator, uint256 factor);

    event OpenWhitelist(address operator);
    event CloseWhitelist(address operator);
    event AddToWhitelist(address operator, address nft);
    event RemoveFromWhitelist(address operator, address nft);

    event AddCurrency(address operator, address currency);
    event RemoveCurrency(address operator, address currency);

    function marketAddress() external view returns (address);

    function borrowLoanAddress() external view returns (address);

    function lendLoanAddress() external view returns (address);


    function minBorrowDuration() external view returns (uint256);

    function maxBorrowDuration() external view returns (uint256);

    function overdueDuration() external view returns (uint256);

    function reserveFactor() external view returns (uint256);

    function MAX_RESERVE_FACTOR() external view returns (uint256);

    function overdueLoanFeeFactor() external view returns (uint256);

    function isWhitelistOn() external view returns (bool);

    function inWhitelist(address nft) external view returns (bool);

    function getWhitelistDetail(address nft) external view returns (BespokeTypes.WhitelistInfo memory);

    function getBorrowDurationConfig(address nftAddress)
        external
        view
        returns (
            uint256 minBorrowDuration,
            uint256 maxBorrowDuration,
            uint256 overdueDuration
        );

    function isCurrencyWhitelisted(address currency) external view returns (bool);
}