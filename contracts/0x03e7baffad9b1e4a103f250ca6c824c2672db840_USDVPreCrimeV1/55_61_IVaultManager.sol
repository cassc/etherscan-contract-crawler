// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity ^0.8.0;

import {Delta} from "../../usdv/interfaces/IUSDV.sol";
import "../libs/Asset.sol";

enum Role {
    OWNER,
    OPERATOR,
    FOUNDATION,
    LIQUIDITY_PROVIDER,
    DONOR
}

interface IVaultManager {
    error InvalidAmount();
    error NotDeltaZero();
    error WrongSign();
    error InvalidArgument();
    error InvalidColor(uint32 color);
    error ColorPaused();
    error Unauthorized();

    event DistributedReward(address[] token, uint[] amounts);
    event Minted(address indexed receiver, uint32 indexed color, uint64 amount, bytes32 memo);
    event Redeemed(address indexed redeemer, uint64 amount);
    event PendingRemint(Delta[] deltas);
    event WithdrewReward(address caller, address receiver, uint32 color, uint64 rewards);
    event WithdrewFees(address caller, address receiver, uint64 fees);
    event RegisteredAsset(address asset);
    event EnabledAsset(bool enabled);
    event SetRole(Role role, address addr);
    event SetFeeBpsCap(Role role, uint16 cap);
    event SetFeeBps(Role role, uint16 bps);
    event SetRateLimiter(address limiter);
    event PausedColor(uint32 color, bool paused);
    event SetMinter(address minter, uint32 color);

    function assetInfoOf(
        address _token
    ) external view returns (bool enabled, uint usdvToTokenRate, uint collateralized);

    function mint(address _token, address _receiver, uint64 _amount, uint32 _color, bytes32 _memo) external;

    function remint(Delta[] calldata _deltas, uint64 _remintFee) external;

    function redeem(
        address _token,
        address _receiver,
        uint64 _amount,
        uint64 _minAmount,
        uint32[] calldata _deficits
    ) external returns (uint amountAfterFee);

    function redeemOut(address _token, uint64 _amount) external view returns (uint);
}