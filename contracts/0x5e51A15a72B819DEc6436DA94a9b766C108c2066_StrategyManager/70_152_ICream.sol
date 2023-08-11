// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.9.0;
pragma experimental ABIEncoderV2;

interface ICream {
    struct CompBalanceMetadata {
        uint256 balance;
        uint256 votes;
        address delegate;
    }

    struct CompBalanceMetadataExt {
        uint256 balance;
        uint256 votes;
        address delegate;
        uint256 allocated;
    }

    function getCompBalanceMetadataExt(
        address comp,
        address comptroller,
        address account
    ) external returns (CompBalanceMetadataExt memory);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function claimComp(address holder) external;

    function getCompBalanceMetadata(address comp, address account) external view returns (CompBalanceMetadata memory);

    function exchangeRateStored() external view returns (uint256);

    function underlying() external view returns (address);

    function compAccrued(address holder) external view returns (uint256);

    function getCash() external view returns (uint256);

    function comptroller() external view returns (address);

    function getCompAddress() external view returns (address);
}