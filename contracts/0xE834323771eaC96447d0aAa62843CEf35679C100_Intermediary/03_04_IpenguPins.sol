// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IpenguPins {
    function airdropPenguPin(uint256 id, address[] calldata holders) external;

    function claimPenguPinToWallet(
        address receiverWallet,
        uint256 id,
        uint256 nonce,
        bytes memory signature
    ) external;

    function burnTruePengu(uint256 id) external;

    function adminBurnPenguPin(address holder, uint256 id) external;

    function uri(uint256 id) external view returns (string memory);

    function setURI(string calldata _base, string calldata _suffix) external;

    function pause() external;

    function unpause() external;

    function claimPaused() external view;

    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

    function updateSignVersion(string calldata signVersion_) external;

    function updateSignerWallet(address signerWallet_) external;
}