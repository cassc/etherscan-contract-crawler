pragma solidity ^0.8.0;


/**
 * @dev Extension of `ERC20` allows a centralized owner to burn users' tokens
 *
 * At construction time, the deployer of the contract is the only burner.
 */
 interface IERC20Operator {

    event ForcedTransfer(address requester, address from, address to, uint256 value);

    /**
     * @dev new function to burn tokens from a centralized owner
     * @param _from address The address which the operator wants to send tokens from
     * @param _to address The address which the operator wants to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @return A boolean that indicates if the operation was successful.
     */
    function forcedTransfer(address _from, address _to, uint256 _value) external returns (bool);
}