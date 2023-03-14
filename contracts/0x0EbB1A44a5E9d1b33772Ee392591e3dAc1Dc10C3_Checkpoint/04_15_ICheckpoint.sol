// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

enum Stage {
    COLLECTING,
    BURNING,
    CLAIMING
}

/// @dev Interface for Checkpoint protoform contract
interface ICheckpoint {
    error InvalidStage(Stage _required, Stage _current);
    error NotOwner();
    error TooManyPoints();

    event Deposit(
        address indexed _owner,
        uint256 indexed _tokenId,
        uint256 indexed _checkValue,
        uint88 _totalPoints
    );
    event Withdraw(
        address indexed _owner,
        uint256 indexed _tokenId,
        uint256 indexed _checkValue,
        uint88 _totalPoints
    );
    event CompositeMany(uint256[] indexed _tokenIds, uint256[] indexed _burnIds);
    event Infinity(uint256[] indexed _tokenIds, uint256 indexed _lowestId);
    event Claim(address indexed _owner, uint256 indexed _points);

    function MAX_SUPPLY() external view returns (uint256);

    function checks() external view returns (address);

    function claim(address _owner) external;

    function compositeMany(uint256[] calldata _tokenIds, uint256[] calldata _burnIds) external;

    function currentStage() external view returns (Stage);

    function deposit(uint256[] calldata _tokenIds) external;

    function getTotalValue(uint256[] calldata _tokenIds) external view returns (uint256);

    function getCheckValue(uint256 _tokenId) external view returns (uint256);

    function infinity(uint256[] calldata _tokenIds) external;

    function ownerToPoints(address) external view returns (uint256);

    function registry() external view returns (address);

    function tokenIdToOwner(uint256) external view returns (address);

    function totalPoints() external view returns (uint88);

    function vault() external view returns (address);

    function withdraw(uint256[] calldata _tokenIds) external;
}