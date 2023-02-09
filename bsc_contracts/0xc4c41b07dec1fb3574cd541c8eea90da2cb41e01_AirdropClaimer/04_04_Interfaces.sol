// SPDX-License-Identifier: WISE

pragma solidity ^0.8.17;

interface IAirdropRegister {

    function userShares(
        address _user
    )
        external
        view
        returns (uint256);

    function registerStakeBulk(
        bytes16[] memory _stakeIDs
    )
        external;

    function registerStake(
        bytes16 _stakeID
    )
        external;
}

interface IToken {

    function totalSupply()
        external
        view
        returns (uint256);

    function balanceOf(
        address account
    )
        external
        view
        returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    )
        external
        returns (bool);

    function allowance(
        address owner,
        address spender
    )
        external
        view
        returns (uint256);

    function approve(
        address spender,
        uint256 amount
    )
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

}
