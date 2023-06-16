// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/**
 * Copyright (C) 2023 Flare Finance B.V. - All Rights Reserved.
 *
 * This source code and any functionality deriving from it are owned by Flare
 * Finance BV and the use of it is only permitted within the official platforms
 * and/or original products of Flare Finance B.V. and its licensed parties. Any
 * further enquiries regarding this copyright and possible licenses can be directed
 * to partners[at]flr.finance.
 *
 * The source code and any functionality deriving from it are provided "as is",
 * without warranty of any kind, express or implied, including but not limited to
 * the warranties of merchantability, fitness for a particular purpose and
 * noninfringement. In no event shall the authors or copyright holder be liable
 * for any claim, damages or other liability, whether in an action of contract,
 * tort or otherwise, arising in any way out of the use or other dealings or in
 * connection with the source code and any functionality deriving from it.
 */

import { IWrap } from "./IWrap.sol";

/// @title Interface for the side of Wraps where tokens are deposited and
/// redeemed.
interface IWrapDepositRedeem is IWrap {
    /// @dev Allowlist a new token.
    /// @param token Address of the token that will be allowlisted.
    /// @param mirrorToken Address of the token that will be minted
    /// on the other side.
    /// @param tokenInfo Information associated with the token.
    /// @notice Set maxAmount to zero to disable the token.
    /// @notice Can only be called by the weak-admin.
    function addToken(
        address token,
        address mirrorToken,
        TokenInfo calldata tokenInfo
    ) external;
}