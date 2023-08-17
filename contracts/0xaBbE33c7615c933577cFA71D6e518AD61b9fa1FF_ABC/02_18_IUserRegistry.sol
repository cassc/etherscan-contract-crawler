// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @dev Interface of the Registry contract.
 */
interface IUserRegistry {
    function canTransfer(address _from, address _to) external view;

    function canTransferFrom(
        address _spender,
        address _from,
        address _to
    ) external view;

    function canMint(address _to) external view;

    function canBurn(address _from, uint256 _amount) external view;

    function canWipe(address _account) external view;

    function isRedeem(address _sender, address _recipient)
        external
        view
        returns (bool);

    function isRedeemFrom(
        address _caller,
        address _sender,
        address _recipient
    ) external view returns (bool);
}