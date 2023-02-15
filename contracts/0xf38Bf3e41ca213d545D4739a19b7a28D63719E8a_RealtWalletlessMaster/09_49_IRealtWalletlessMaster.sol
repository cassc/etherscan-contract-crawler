// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@gnosis.pm/safe-contracts/contracts/GnosisSafeL2.sol";

import "./IBridgeToken.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

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

    event TokenBought(
        GnosisSafeL2 indexed clientWallet,
        bytes indexed _paymentReference
    );

   event SatoshiCheck(
        GnosisSafeL2 indexed clientWallet,
        uint256 amount
    );

   event FiatWithdraw(
        GnosisSafeL2 indexed clientWallet,
        address token,
        address mtpWallet,
        uint256 amount
    );

    event FundsCustodyExit(
        GnosisSafeL2 indexed clientWallet,
        address indexed destination,
        address[] tokens,
        uint256[] amounts
    );

    event OwnershipCustodyExit(
        GnosisSafeL2 indexed clientWallet,
        address indexed newOwner
    );

    function createSafe() external returns (address, uint256);

    function createSafeWithSalt(uint256 salt)
        external
        returns (address, uint256);

    function buyTokens(
        GnosisSafeL2 clientWallet,
        address feeProxy_,
        address to,
        uint256 amount,
        address[] calldata _path,
        bytes calldata paymentReference,
        uint256 feeAmount,
        address feeAddress,
        uint256 maxToSpend,
        uint256 maxRateTimespan
    ) external returns (bool);

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

    function fiatWithdraw(
        GnosisSafeL2 clientWallet,
        address token,
        address mtpWallet,
        uint256 amount
    ) external returns (bool);

    function satoshiCheck(GnosisSafeL2 clientWallet) external payable returns (bool);
}