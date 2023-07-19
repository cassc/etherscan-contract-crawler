// SPDX-License-Identifier: UNLICENSED
/*
Copyright (C) 2023 MC² Finance

All rights reserved. This program and the accompanying materials
are made available for use and disclosure in accordance with the terms of this copyright notice.
This notice does not constitute a license agreement. No part of this program may be used, reproduced, 
or transmitted in any form or by any means, electronic, mechanical, photocopying, recording, or otherwise, 
without the prior written permission of MC² Finance.
*/

pragma solidity ^0.8.0;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the MC²Fi Escrow contract
 */
interface IEscrow {
    event AcceptDeposit(
        address indexed proprietor,
        IERC20 indexed asset,
        uint256 indexed amount
    );

    event RejectDeposit(
        address indexed proprietor,
        IERC20 indexed asset,
        uint256 indexed depositAmount,
        address feeRecipient,
        uint256 feeAmount
    );

    event Withdraw(
        address indexed proprietor,
        IERC20 indexed asset,
        uint256 indexed amount
    );

    event TransferAssetFrom(
        address indexed proprietor,
        IERC20 indexed asset,
        uint256 indexed amount,
        address recipient
    );

    event RefundAsset(
        address indexed proprietor,
        IERC20 indexed asset,
        uint256 indexed amount
    );

    event RescueAssets(
        address indexed recipient,
        IERC20[] assets,
        uint256[] amounts
    );

    event AddBlacklistedAccount(address indexed account);

    event RemoveBlacklistedAccount(address indexed account);

    /**
     * @dev Returns currently held assets of proprietor.
     *
     * - MUST NOT revert.
     */
    function assets(
        address proprietor
    ) external view returns (IERC20[] memory assets);

    /**
     * @dev Returns the amount of one currently held asset of proprietor.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST return 0 if the asset is not owned by the Pool.
     * - MUST NOT revert.
     */
    function assetBalance(
        address proprietor,
        IERC20 asset
    ) external view returns (uint256 balance);

    /**
     * @dev Returns the addresses and amounts of all currently held assets of proprietor.
     *
     * - MUST NOT revert.
     */
    function assetsAndBalances(
        address proprietor
    ) external view returns (IERC20[] memory assets, uint256[] memory balances);

    /**
     * @dev Register transfer of asset and amount made to this contract by proprietor.
     *
     * - MUST emit the AcceptDeposit event.
     * - MUST revert if amount is 0.
     */
    function acceptDeposit(
        address proprietor,
        IERC20 asset,
        uint256 amount
    ) external;

    /**
     * @dev Transfer unregistered deposit amount of asset to proprietor, and fee amount to fee recipient.
     *
     * - MUST emit the RejectDeposit event.
     * - MUST revert if deposit amount + fee amount is 0.
     * - MUST revert if the asset cannot be transferred,
     *	 i.e. the contract not having enough assets before the call.
     */
    function rejectDeposit(
        address proprietor,
        IERC20 asset,
        uint256 depositAmount,
        address feeRecipient,
        uint256 feeAmount
    ) external;

    /**
     * @dev Withdraw of previously accepted asset deposit by the caller.
     *
     * - MUST emit the Withdraw event.
     * - MUST revert if amount is 0.
     * - MUST revert if the asset cannot be withdrawn,
     *	 i.e. the contract not having enough assets registered to the caller before the call.
     */
    function withdraw(IERC20 asset, uint256 amount) external;

    /**
     * @dev Transfer of asset deposited by proprietor to another address.
     *
     * - MUST emit the TransferAssetFrom event.
     * - MUST revert if amount is 0.
     * - MUST revert if asset is not owned by proprietor.
     * - MUST revert if amount is greater than the proprietor's asset balance.
     */
    function transferAssetFrom(
        address proprietor,
        IERC20 asset,
        uint256 amount,
        address recipient
    ) external;

    /**
     * @dev Partial or total refund of previously accepted deposit to proprietor.
     *
     * - MUST emit the RefundAsset event.
     * - MUST revert if amount is 0.
     * - MUST revert if asset is not owned by proprietor.
     * - MUST revert if amount is greater than the proprietor's asset balance.
     */
    function refundAsset(
        address proprietor,
        IERC20 asset,
        uint256 amount
    ) external;

    /**
     * @dev Rescue of any unregistered assets owned by this contract.
     *
     * - MUST emit the RescueAssets event.
     * - MUST revert if arrays are of different lengths.
     * - MUST revert if any amount is 0.
     * - MUST revert if the asset cannot be transferred,
     *	 i.e. the contract not having enough assets before the call.
     */
    function rescueAssets(
        address recipient,
        IERC20[] memory assets,
        uint256[] memory amounts
    ) external;

    /**
     * @dev Adds address to blacklisted addresses.
     *
     * - MUST emit the AddBlacklistedAccount event.
     * - MUST revert if address is 0.
     */
    function addBlacklistedAccount(address blacklisted) external;

    /**
     * @dev Removes address from blacklisted addresses.
     *
     * - MUST emit the RemoveBlacklistedAccount event.
     * - MUST revert if address is 0.
     */
    function removeBlacklistedAccount(address blacklisted) external;

    /**
     * @dev Returns a bool indicating if the address is currently blacklisted.
     */
    function accountIsBlacklisted(
        address _blacklisted
    ) external view returns (bool isBlacklisted);

    /**
     * @dev Returns the list of currently blacklisted addresses.
     */
    function blacklistedAccounts()
        external
        view
        returns (address[] memory blacklistedAccounts);
}