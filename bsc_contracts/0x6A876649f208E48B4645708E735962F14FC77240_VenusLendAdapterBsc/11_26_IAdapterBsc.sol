// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IWrap.sol";
import "../adapters/BaseAdapterBsc.sol";

interface IAdapterBsc {
    function getPaths(address _inToken, address _outToken)
        external
        view
        returns (address[] memory);

    function stakingToken() external view returns (address);

    function strategy() external view returns (address);

    function name() external view returns (string memory);

    function rewardToken() external view returns (address);

    function rewardToken1() external view returns (address);

    function router() external view returns (address);

    function swapRouter() external view returns (address);

    function depth() external view returns (uint256);

    function deposit(
        uint256 _tokenId,
        uint256 _amount,
        address _account
    )
        external
        payable
        returns (
            uint256 amount,
            uint256 invested,
            uint256 userShares,
            uint256 userShares1
        );

    function deposit(
        uint256 _tokenId,
        uint256 _amount,
        address _account,
        uint256 _tradeTokenId
    )
        external
        payable
        returns (
            uint256 amount,
            uint256 invested,
            uint256 userShares,
            uint256 userShares1
        );

    function withdraw(
        uint256 _tokenId,
        address _account,
        BaseAdapterBsc.UserAdapterInfo memory
    ) external payable returns (uint256 amountOut);

    function withdraw(
        uint256 _tokenId,
        address _account,
        BaseAdapterBsc.UserAdapterInfo memory,
        uint256 _tradeTokenId
    ) external payable returns (uint256 amountOut);

    function claim(
        uint256 _tokenId,
        address _account,
        BaseAdapterBsc.UserAdapterInfo memory
    )
        external
        payable
        returns (
            uint256 amountOut,
            uint256 userShares,
            uint256 userShares1
        );

    function pendingReward(
        uint256 _tokenId,
        BaseAdapterBsc.UserAdapterInfo memory
    ) external view returns (uint256 amountOut);

    function adapterInfos(uint256 _tokenId)
        external
        view
        returns (BaseAdapterBsc.AdapterInfo memory);

    function userAdapterInfos(address _account, uint256 _tokenId)
        external
        view
        returns (BaseAdapterBsc.UserAdapterInfo memory);
}