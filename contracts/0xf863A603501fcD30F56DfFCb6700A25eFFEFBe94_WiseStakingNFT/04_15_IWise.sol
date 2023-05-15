// SPDX-License-Identifier: WISE

pragma solidity =0.8.19;

interface IWise {

    function createStake(
        uint256 _stakedAmount,
        uint64 _lockDays,
        address _referrer
    )
        external
        returns (
            bytes16,
            uint256,
            bytes16
        );

    function endStake(
        bytes16 _stakeID
    )
        external
        returns (uint256);

    function createStakeWithETH(
        uint64 _lockDays,
        address _referrer
    )
        external
        payable
        returns (
            bytes16,
            uint256,
            bytes16
        );

    function createStakeWithToken(
        address _tokenAddress,
        uint256 _tokenAmount,
        uint64 _lockDays,
        address _referrer
    )
        external
        returns (
            bytes16,
            uint256,
            bytes16
        );

    function transfer(
        address _to,
        uint256 _amount
    )
        external
        returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    )
        external
        returns (bool);

    function approve(
        address _spender,
        uint256 _amount
    )
        external
        returns (bool);

    function balanceOf(
        address _owner
    )
        external
        returns (uint256);
}