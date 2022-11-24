pragma solidity ^0.8.0;

interface ISHORTFACTORY {

    function createShort(uint256 _startTime,
        address _traderContractAddress,
        address _traderAddress,
        address _participationTokenAddress
    ) external returns (address);

    function allowedLendTokens(address) external view returns (bool);

    function allowedBorrowTokens(address) external view returns (bool);
}