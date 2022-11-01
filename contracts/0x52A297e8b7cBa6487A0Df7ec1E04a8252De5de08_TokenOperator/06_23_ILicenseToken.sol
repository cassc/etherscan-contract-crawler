//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;
import "./IApproveAuthorization.sol";
import "./ITokenActionable.sol";

/**
 * @title NFT License token
 * @author ysqi
 * @notice NFT License token protocol.
 */
interface ILicenseToken is IApproveAuthorization, ITokenActionable {
    function initialize(address creator, address origin) external;

    /**
     * @notice return the license meta data.
     *
     * Requirements:
     *
     * - `id` must be exist.
     * @param id is the token id.
     * @return LicenseMeta:
     *
     *    uint256 originTokenId;
     *    uint16 earnPoint;
     *    uint64 expiredAt;
     */
    function meta(uint256 id) external view returns (LicenseMeta calldata);

    /**
     * @notice return the license[] metas data.
     *
     * Requirements:
     *
     * - `id` must be exist.
     * @param ids is the token ids.
     * @return LicenseMetas:
     *
     *    uint256 originTokenId;
     *    uint16 earnPoint;
     *    uint64 expiredAt;
     */
    function metas(uint256[] memory ids) external view returns (LicenseMeta[] calldata);

    /*
     * @notice return whether NFT has expired.
     *
     * Requirements:
     *
     * - `id` must be exist.
     *
     * @param id is the token id.
     * @return bool returns whether NFT has expired.
     */
    function expired(uint256 id) external view returns (bool);
}