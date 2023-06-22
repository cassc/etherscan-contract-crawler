// SPDX-License-Identifier: MIT
// vmh

pragma solidity ^0.8.0;

interface IXChance {
    function blocksPerGame() external view returns (uint256);

    function getDivisions() external view returns (uint256[] memory);

    function getTokens(
        uint256 _division
    ) external view returns (address[] memory);

    function fund(uint256 _division, uint256 _potID) external payable;

    function fundToken(
        uint256 _division,
        address _token,
        uint256 _potID,
        uint256 _value
    ) external;

    function fundBatch(
        uint256 _division,
        uint256[] memory _pots
    ) external payable;

    function fundBatchToken(
        uint256 _division,
        address _token,
        uint256[] memory _pots
    ) external;

    function getPots(
        uint256 _division,
        address _token,
        uint256 _gameID
    ) external view returns (uint256[] memory);

    function getFunds(
        uint256 _division,
        address _token,
        uint256 _gameID,
        address _address
    ) external view returns (uint256[] memory);

    function claimPrize(uint256 _division, uint256 _gameID) external;

    function claimTokenPrize(
        uint256 _division,
        address _token,
        uint256 _gameID
    ) external;

    function claimPrizeBatch(uint256 _gameID) external;

    function getClaim(
        uint256 _division,
        address _token,
        uint256 _gameID,
        address _address
    ) external view returns (uint256);
}