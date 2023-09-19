// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.21;

interface IERC20 {

    function totalSupply()
        external
        view
        returns (uint256);

    function balanceOf(
        address _account
    )
        external
        view
        returns (uint256);

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool);

    function transfer(
        address _recipient,
        uint256 _amount
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
        address _spender,
        uint256 _amount
    )
        external
        returns (bool);

    function decimals()
        external
        view
        returns (uint8);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event  Deposit(
        address indexed dst,
        uint wad
    );

    event  Withdrawal(
        address indexed src,
        uint wad
    );
}