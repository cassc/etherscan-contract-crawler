// SPDX-License-Identifier: BUSL-1.1
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.20;

interface IERC20Base {
    event Received(address indexed sender, uint256 value);

    /**
     * @dev function owner()
     * @dev returns the owner of the contract
     * @dev the owner is always granted all roles
     */
    function owner() external view returns (address);

    /**
     * @dev function hasAttribute(account. _attribute)
     * @dev returns true if account has the defined _attribute
     */
    function hasAttribute(
        address account,
        uint256 _attribute
    ) external view returns (bool);

    /**
     * @dev function setAttributes(_wallet, _attributes)
     * @dev adds attributes to _wallet
     */
    function setAttributes(address _wallet, uint256 _attributes) external;

    /**
     * @dev function delAttributes(_wallet, _attributes)
     * @dev removes _attributes from _wallet
     */
    function delAttributes(address _wallet, uint256 _attributes) external;

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool);

    function decreaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool);

    function xtransfer(address token, address creditor, uint256 value) external;

    function xapprove(address token, address spender, uint256 value) external;

    function withdrawEth() external returns (bool);

    function mint(address account, uint256 amount) external;

    receive() external payable;
}