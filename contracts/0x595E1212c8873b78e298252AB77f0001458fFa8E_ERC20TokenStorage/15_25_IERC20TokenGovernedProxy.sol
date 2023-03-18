// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface IERC20TokenGovernedProxy {
    event AirdropRewardsClaimed(
        address indexed recipient,
        uint256 claimAmountAirdrop,
        uint256 claimAmountReferral1,
        uint256 claimAmountReferral2,
        uint256 claimAmountReferral3,
        bytes4 airdropId,
        uint256 lastClaimNonce,
        uint256 claimNonce,
        bytes airdropServiceSignature
    );

    // ERC20 events
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function setSporkProxy(address payable _sporkProxy) external;

    function emitAirdropRewardsClaimed(
        address recipient,
        uint256 claimAmountAirdrop,
        uint256 claimAmountReferral1,
        uint256 claimAmountReferral2,
        uint256 claimAmountReferral3,
        bytes4 airdropId,
        uint256 lastClaimNonce,
        uint256 claimNonce,
        bytes calldata airdropServiceSignature
    ) external;

    function emitTransfer(
        address from,
        address to,
        uint256 value
    ) external;

    // ERC20 standard interface
    function name() external view returns (string memory _name);

    function symbol() external view returns (string memory _symbol);

    function decimals() external view returns (uint256 _decimals);

    function balanceOf(address account) external view returns (uint256 _balance);

    function allowance(address owner, address spender) external view returns (uint256 _allowance);

    function totalSupply() external view returns (uint256 _totalSupply);

    function approve(address spender, uint256 value) external returns (bool result);

    function transfer(address to, uint256 value) external returns (bool result);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool result);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool result);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool result);
}