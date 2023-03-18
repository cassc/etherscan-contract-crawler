// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface IERC20Token {
    function eRC20TokenStorage() external view returns (address _eRC20TokenStorage);

    function name() external view returns (string memory _name);

    function symbol() external view returns (string memory _symbol);

    function decimals() external view returns (uint8 _decimals);

    function getAirdropService() external view returns (address _airdropService);

    function getAirdropLastClaimNonce(bytes4 airdropId, address _user)
        external
        view
        returns (uint256 _lastClaimNonce);

    // Setter functions
    //
    function setName(string calldata _name) external;

    function setSymbol(string calldata _symbol) external;

    function setDecimals(uint8 _decimals) external;

    function setAirdropService(address _airdropService) external;

    function setERC721ManagerProxy(address _eRC721ManagerProxy) external;

    // Mint/burn functions
    //
    function mint(address recipient, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    // ERC20 airdrop and airdrop referral rewards claim function
    function claimAirdrop(
        uint256 claimAmountAirdrop,
        uint256 claimAmountReferral1,
        uint256 claimAmountReferral2,
        uint256 claimAmountReferral3,
        bytes4 airdropId,
        uint256 lastClaimNonce,
        uint256 claimNonce,
        bytes calldata airdropServiceSignature
    ) external;
}