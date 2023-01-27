/**
                                                         __
     _____      __      ___    ___     ___     __       /\_\    ___
    /\ '__`\  /'__`\   /'___\ / __`\  /'___\ /'__`\     \/\ \  / __`\
    \ \ \_\ \/\ \_\.\_/\ \__//\ \_\ \/\ \__//\ \_\.\_  __\ \ \/\ \_\ \
     \ \ ,__/\ \__/.\_\ \____\ \____/\ \____\ \__/.\_\/\_\\ \_\ \____/
      \ \ \/  \/__/\/_/\/____/\/___/  \/____/\/__/\/_/\/_/ \/_/\/___/
       \ \_\
        \/_/

    The sweetest DeFi portfolio manager.

**/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import "../interfaces/IZapStructs.sol";

interface IPeanutZap is IZapStructs {
    function initialize(
        address _treasury,
        address _owner,
        address _wNative
    ) external;

    function zapToken(
        ZapInfo calldata _zapInfo,
        address _inputToken,
        uint _inputTokenAmount
    ) external;

    function zapNative(
        ZapInfo calldata _zapInfo
    ) external payable;

    function unZapToken(
        UnZapInfo calldata _unZapInfo,
        address _outputToken
    ) external;

    function unZapTokenWithPermit(
        UnZapInfo calldata _unZapInfo,
        address _outputToken,
        bytes calldata _signatureData
    ) external;

    function unZapNative(
        UnZapInfo calldata _unZapInfo
    ) external;

    function unZapNativeWithPermit(
        UnZapInfo calldata _unZapInfo,
        bytes calldata _signatureData
    ) external;

    function zapPair(
        ZapPairInfo calldata _zapPairInfo
    ) external;

    function collectDust(
        address _token
    ) external;

    function collectDustMultiple(
        address[] calldata _tokens
    ) external;

    function setTreasury(
        address _treasury
    ) external;

    receive() external payable;
}