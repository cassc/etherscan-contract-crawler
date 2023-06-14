// SPDX-License-Identifier: --DAO--

/**
 * @author René Hochmuth
 * @author Vitally Marinchenko
 */

pragma solidity =0.8.19;

interface IERC20 {

    function transfer(
        address _to,
        uint256 _amount
    )
        external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    )
        external;

    function balanceOf(
        address _account
    )
        external
        view
        returns (uint256);

    function approve(
        address _spender,
        uint256 _amount
    )
        external;

    function allowance(
        address _user,
        address _spender
    )
        external
        view
        returns (uint256);

    function decimals()
        external
        view
        returns (uint8);

    function symbol()
        external
        view
        returns (string memory);
}