// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@gnosis.pm/safe-contracts/contracts/GnosisSafeL2.sol";
import "./IBridgeToken.sol";

interface IRealtWalletlessMaster {
    event BuyBack(
        GnosisSafeL2 indexed clientWallet,
        IBridgeToken indexed token,
        uint256 indexed amount
    );

    event BatchBuyBack(
        GnosisSafeL2 indexed clientWallet,
        IBridgeToken[] indexed tokens,
        uint256[] indexed amounts
    );

    event AddSafeOwner(
        GnosisSafeL2 indexed clientWallet,
        address indexed newOwner
    );

    event RemoveSafeOwner(
        GnosisSafeL2 indexed clientWallet,
        address indexed prevOwner,
        address indexed owner
    );

    function createSafe() external returns (address, uint256);

    function createSafeWithSalt(uint256 salt)
        external
        returns (address, uint256);

    function buyBack(
        GnosisSafeL2 clientWallet,
        IBridgeToken token,
        uint256 amount
    ) external returns (bool);

    function batchBuyBack(
        GnosisSafeL2 clientWallet,
        IBridgeToken[] calldata tokens,
        uint256[] calldata amounts
    ) external returns (bool);

    function addSafeOwner(GnosisSafeL2 clientWallet, address newOwner)
        external
        returns (bool);

    function removeSafeOwner(
        GnosisSafeL2 clientWallet,
        address prevOwner,
        address owner
    ) external returns (bool);
}