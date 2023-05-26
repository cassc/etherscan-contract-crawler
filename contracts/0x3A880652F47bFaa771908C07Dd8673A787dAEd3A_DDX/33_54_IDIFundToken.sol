// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @title IDIFundToken
 * @author DerivaDEX (Borrowed/inspired from Compound)
 * @notice This is the native token contract for DerivaDEX. It
 *         implements the ERC-20 standard, with additional
 *         functionality to efficiently handle the governance aspect of
 *         the DerivaDEX ecosystem.
 * @dev The contract makes use of some nonstandard types not seen in
 *      the ERC-20 standard. The DDX token makes frequent use of the
 *      uint96 data type, as opposed to the more standard uint256 type.
 *      Given the maintenance of arrays of balances, allowances, and
 *      voting checkpoints, this allows us to more efficiently pack
 *      data together, thereby resulting in cheaper transactions.
 */
interface IDIFundToken {
    function transfer(address _recipient, uint256 _amount) external returns (bool);

    function mint(address _recipient, uint256 _amount) external;

    function burnFrom(address _account, uint256 _amount) external;

    function delegate(address _delegatee) external;

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external returns (bool);

    function approve(address _spender, uint256 _amount) external returns (bool);

    function getPriorValues(address account, uint256 blockNumber) external view returns (uint96);

    function getTotalPriorValues(uint256 blockNumber) external view returns (uint96);

    function balanceOf(address _account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}