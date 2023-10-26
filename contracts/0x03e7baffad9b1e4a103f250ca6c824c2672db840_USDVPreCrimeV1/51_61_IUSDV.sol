// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity ^0.8.0;

import "@layerzerolabs/lz-evm-oapp-v2/contracts/standards/oft/interfaces/IOFT.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

struct Delta {
    uint32 color;
    int64 amount;
}

struct State {
    uint32 color;
    uint64 balance;
    // config
    bool blacklisted;
    uint32 defaultColor;
}

enum Role {
    OWNER,
    OPERATOR,
    VAULT,
    MESSAGING,
    FOUNDATION
}

interface IUSDV is IOFT, IERC20Upgradeable {
    error Unauthorized();
    error InvalidUser();
    error InvalidArgument();
    error NotImplemented();
    error InsufficientBalance();
    error Paused();
    error Blacklisted();
    error FeeTooHigh();

    // role assigment
    event SetRole(Role role, address addr);
    event SetColorer(address indexed caller, address indexed user, address colorer);
    event SetDefaultColor(address indexed caller, address indexed user, uint32 defaultColor);
    // governance state
    event SetBlacklist(address indexed user, bool isBlacklisted);
    event SetPause(bool paused);
    // cross-chain events
    event Synced(bytes32 guid, Delta[] deltas);

    function mint(address _receiver, uint64 _amount, uint32 _color) external;

    function burn(address _from, uint64 _amount, uint32[] calldata _delta) external returns (Delta[] memory deltas);

    /// -------- coloring interfaces --------
    function setColorer(address _user, address _colorer) external;

    function setDefaultColor(address _user, uint32 _defaultColor) external;

    /// -------- governance interfaces --------
    function setPause(bool _pause) external;

    function setRole(Role _role, address _addr) external;

    /// -------- cross-chain interfaces (non-OFT) --------
    function sendAck(bytes32 _guid, address _receiver, uint32 _color, uint64 _amount, uint64 _theta) external;

    function syncDelta(
        uint32 _dstEid,
        uint64 _theta,
        uint32[] calldata _deficits,
        uint64 _feeCap,
        bytes calldata _extraOptions,
        MessagingFee calldata _msgFee,
        address payable _refundAddress
    ) external payable returns (MessagingReceipt memory msgReceipt);

    function syncDeltaAck(Delta[] calldata _deltas) external;

    function quoteSyncDeltaFee(
        uint32 _dstEid,
        uint32 _numDeficits,
        bytes calldata _extraOptions,
        bool _useLzToken
    ) external view returns (uint nativeFee, uint lzTokenFee);

    function userStates(
        address _user
    ) external view returns (uint32 color, uint64 balance, bool blacklisted, uint32 defaultColor);
}