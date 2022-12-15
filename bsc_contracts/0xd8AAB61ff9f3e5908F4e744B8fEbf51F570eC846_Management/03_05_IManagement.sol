// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IManagement {
    function admin() external returns (address);

    function treasury() external returns (address);

    function verifier() external returns (address);

    function minter() external returns (address);

    function microphoneNFT() external returns (address);

    function lootBox() external returns (address);

    function breeding() external returns (address);

    function ruby() external returns (address);

    function busd() external returns (address);

    function prevSigns(bytes32) external returns (bool);

    function updateTreasury(address _newTreasury) external;

    function updateVerifier(address _newVerifier) external;

    function updateMinter(address _newMinter) external;

    function updateRandomService(address _newService) external;

    function updateMicroNFT(address _microNFT) external;

    function updateLootBox(address _lootBox) external;

    function updateBreeding(address _breeding) external;

    function updateRuby(address _ruby) external;

    function updateBUSD(address _busd) external;

    function getRandom() external returns (uint256);
}