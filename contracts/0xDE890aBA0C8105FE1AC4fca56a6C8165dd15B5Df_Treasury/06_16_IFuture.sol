// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFuture {
    
    function expired() external returns (bool);

    function expiry() external returns (uint256);

    function protocol() external returns (bytes32);

    function underlying() external returns (address);

    function getYT() external view returns (address);

    function totalSupplyYT() external view returns (uint256);

    function claimYT(address _receiver, uint256 _amount) external;

    function burnYT(address) external returns (uint256);

    function getOT() external view returns (address);

    function totalSupplyOT() external view returns (uint256);

    function claimOT(address _receiver, uint256 _amount) external;

    function burnOT(address _sender) external returns (uint256);

    function totalBalanceUnderlying() external view returns (uint256);

    function initialCapitalInUnderlying() external view returns (uint256);

    function start(
        string memory _protocol,
        uint256 _durationSeconds,
        uint256 _amountInUnderlying,
        uint256 _futureIndex
    ) external;

    function depositInUnderlying(uint256 _amount) external;

    function getInterestBearingToken() external view returns (address);

    function expire() external returns (uint256);

    function owner() external view returns (address);

    function yield() external view returns (uint256);

    function mintYT(address _destination, uint256 _amountToMint) external;

    function mintOT(address _destination, uint256 _amountToMint) external;
}