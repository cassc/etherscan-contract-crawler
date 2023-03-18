// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface IERC20TokenStorage {
    function getName() external view returns (string memory _name);

    function getSymbol() external view returns (string memory _symbol);

    function getDecimals() external view returns (uint8 _decimals);

    function getAirdropService() external view returns (address _airdropService);

    function getAirdropLastClaimNonce(bytes4 airdropId, address _user)
        external
        view
        returns (uint256 _lastClaimNonce);

    function getERC721ManagerProxy() external view returns (address _eRC721ManagerProxy);

    function setName(string calldata _name) external;

    function setSymbol(string calldata _symbol) external;

    function setDecimals(uint8 _decimals) external;

    function setAirdropService(address _airdropService) external;

    function setAirdropLastClaimNonce(
        bytes4 airdropId,
        address _user,
        uint256 _lastClaimNonce
    ) external;

    function setERC721ManagerProxy(address _eRC721ManagerProxy) external;
}