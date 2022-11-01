//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;

import "../lib/ConsiderationStructs.sol";

/**
 * @title NFT Derivative token
 * @author ysqi
 * @notice NFT Derivative token protocol.
 */
interface IDerivativeToken {
    function initialize(
        address creator,
        address originToken,
        string memory name,
        string memory symbol
    ) external;

    /**
     * @notice return the Derivative[] metas data.
     *
     * Requirements:
     *
     * - `id` must be exist.
     * @param id is the token id.
     * @return DerivativeMeta
     */
    function meta(uint256 id) external view returns (DerivativeMeta calldata);

    /**
     * @notice return the license[] metas data.
     *
     * Requirements:
     *
     * - `id` must be exist.
     * @param ids is the token ids.
     * @return DerivativeMetas:
     *
     */
    function metas(uint256[] memory ids) external view returns (DerivativeMeta[] calldata);
}