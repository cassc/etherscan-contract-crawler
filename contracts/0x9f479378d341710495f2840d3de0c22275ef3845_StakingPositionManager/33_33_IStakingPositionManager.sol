// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IStakingPositionManager {

    event Mint(
        uint256 indexed tokenId,
        bytes32 indexed stakeId,
        uint256 amount,
        address container,
        address indexed owner,
        address sender
    );

    event Burn(
        uint256 indexed tokenId,
        bytes32 indexed stakeId,
        uint256 amount,
        address indexed sender
    );

    struct TokenDetails {
        bytes32 stakeId;
        address container;
    }

    function STAKING_TOKEN() external view returns (address);
    function STAKING() external view returns (address);

    function stakeId(uint256 tokenId) external view returns (bytes32);
    function stakeBalanceOf(uint256 tokenId) external view returns (bytes32 _stakeId, uint256 _stakeBalance);

    function setDelegate(uint256 tokenId, address target) external;

    function mint(
        bytes32 stakeId,
        uint256 amount,
        address owner,
        bytes memory data
    ) external returns (uint256 tokenId);

    function burn(
        uint256 tokenId,
        address recipient,
        bytes memory data
    ) external returns (bytes32 stakeId, uint256 tokensReleased);

}