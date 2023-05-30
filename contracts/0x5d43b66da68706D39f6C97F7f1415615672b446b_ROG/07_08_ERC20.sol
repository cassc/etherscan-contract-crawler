// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

abstract contract ERC20 {
    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /*
     * Internal Functions for ERC20 standard logics
     */

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool success) {
        _balances[from] = _balances[from] - amount;
        _balances[to] = _balances[to] + amount;
        emit Transfer(from, to, amount);
        success = true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal returns (bool success) {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        success = true;
    }

    function _mint(address recipient, uint256 amount)
        internal
        returns (bool success)
    {
        _totalSupply = _totalSupply + amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(address(0), recipient, amount);
        success = true;
    }

    function _burn(address burned, uint256 amount)
        internal
        returns (bool success)
    {
        _balances[burned] = _balances[burned] - amount;
        _totalSupply = _totalSupply - amount;
        emit Transfer(burned, address(0), amount);
        success = true;
    }

    /*
     * public view functions to view common data
     */

    function totalSupply() external view returns (uint256 total) {
        total = _totalSupply;
    }

    function balanceOf(address owner) external view returns (uint256 balance) {
        balance = _balances[owner];
    }

    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining)
    {
        remaining = _allowances[owner][spender];
    }

    /*
     * External view Function Interface to implement on final contract
     */
    function name() external view virtual returns (string memory tokenName);

    function symbol() external view virtual returns (string memory tokenSymbol);

    function decimals() external view virtual returns (uint8 tokenDecimals);

    /*
     * External Function Interface to implement on final contract
     */
    function transfer(address to, uint256 amount)
        external
        virtual
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external virtual returns (bool success);

    function approve(address spender, uint256 amount)
        external
        virtual
        returns (bool success);
}