// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @author lwx12525
 * @dev For cqone.art   
 */
interface IERC721Releasable is IERC721Enumerable {
    /**
     * @dev 设置总份数
     */
    function setTotalShares(uint256 newValue) external;

    /**
     * @dev 合约接收ETH
     */
    receive() external payable;

    /**
     * @dev 总金额
     */
    function totalReceived() external view returns (uint256);

    /**
     * @dev 总提取
     */
    function totalReleased() external view returns (uint256);

    /**
     * @dev 总份数
     */
    function totalShares() external view returns (uint256);

    /**
     * @dev 账户总提取
     */
    function released(address account) external view returns (uint256);

    /**
     * @dev 账户总提取的份数
     */
    function releasedShares(address account) external view returns (uint256);

    /**
     * @dev Token领取记录
     */
    function releasedRecord(uint256 tokenId) external view returns (address);

    /**
     * @dev 账户可提取
     */
    function releasable(address account) external view returns (uint256);

    /**
     * @dev 账户可提取的份数
     */
    function releasableShares(address account) external view returns (uint256);

    /**
     * @dev 当前账户提取
     */
    function release() external;
}