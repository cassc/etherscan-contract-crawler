// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.5;

interface IOxODexTokenPool {
    function initialize(address _token, address _factory) external;
    function withdraw(
        address payable recipient, uint256 amountToken, uint256 ringIndex,
        uint256 c0, uint256[2] memory keyImage, uint256[] memory s
    ) external;
    function deposit(uint _amount, uint256[4] memory publicKey) external;
    function getBalance() external view returns (uint256);
    function getCurrentRingIndex(uint256 amountToken) external view
        returns (uint256);
    function getRingMaxParticipants() external pure
        returns (uint256);
    function getParticipant(uint packedData) external view returns (uint256);
    function getWParticipant(uint packedData) external view returns (uint256);
    function getRingPackedData(uint packedData) external view returns (uint256, uint256, uint256);
    function getPublicKeys(uint256 amountToken, uint256 index) external view
        returns (bytes32[2][5] memory);
    function getPoolBalance() external view returns (uint256);
    function swapTokenForToken(
        address tokenOut, 
        address router,
        bytes memory params, 
        uint256[4] memory publicKey, 
        uint256 amountToken, 
        uint256 ringIndex,
        uint256 c0, 
        uint256[2] memory keyImage, 
        uint256[] memory s
    ) external;
    function getFeeForAmount(uint256 amount) external view returns(uint256);
    function getRelayerFeeForAmount(uint256 amount) external view returns(uint256);
}