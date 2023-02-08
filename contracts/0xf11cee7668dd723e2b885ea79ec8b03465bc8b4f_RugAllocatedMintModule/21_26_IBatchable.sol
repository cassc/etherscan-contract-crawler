// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {IAdministrable} from "src/contracts/utils/Administrable/IAdministrable.sol";

/**
 * @title IBatchable (unchained)
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Interface for `Batchable`, the abstract utility that should be inherited by
 * any contracts with functions that should be restricted to admins and the
 * batcher (`Batcher`) being operated by an admin.
 *
 * This "unchained" interface excludes inherited and overriden functions.
 */
interface IBatchableUnchained {
    event BatcherUpdated(address batcher);

    /**
     * @return The address of the transaction Batcher.
     */
    function batcher() external view returns (address);

    /**
     * Update the address of the Batcher.
     *
     * Emits a `BatcherUpdated` event.
     *
     * Requirements:
     * - The caller must be an admin or the batcher operated by an admin.
     * @param batcher_ Address of new batcher
     */
    function updateBatcher(address batcher_) external;
}

/**
 * @title IBatchable
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Interface for `Batchable`, the abstract utility that should be inherited by
 * any contracts with functions that should be restricted to admins and the
 * batcher (`Batcher`) being operated by an admin.
 *
 * This interface includes inherited and overridden functions.
 */
interface IBatchable is IBatchableUnchained, IAdministrable {

}