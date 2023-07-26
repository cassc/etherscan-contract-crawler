// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./TokenAdmin.sol";

/**
 * @title dForce's lending Token ERC20 Contract
 * @author dForce
 */
abstract contract TokenERC20 is TokenAdmin {
    /**
     * @dev Transfers `_amount` tokens from `_sender` to `_recipient`.
     * @param _sender The address of the source account.
     * @param _recipient The address of the destination account.
     * @param _amount The number of tokens to transfer.
     */
    function _transferTokens(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal returns (bool) {
        require(
            _sender != _recipient,
            "_transferTokens: Do not self-transfer!"
        );

        controller.beforeTransfer(address(this), _sender, _recipient, _amount);

        _transfer(_sender, _recipient, _amount);

        controller.afterTransfer(address(this), _sender, _recipient, _amount);

        return true;
    }

    //----------------------------------
    //********* ERC20 Actions **********
    //----------------------------------

    /**
     * @notice Cause iToken is an ERC20 token, so users can `transfer` them,
     *         but this action is only allowed when after transferring tokens, the caller
     *         does not have a shortfall.
     * @dev Moves `_amount` tokens from caller to `_recipient`.
     * @param _recipient The address of the destination account.
     * @param _amount The number of tokens to transfer.
     */
    function transfer(address _recipient, uint256 _amount)
        public
        virtual
        override
        nonReentrant
        returns (bool)
    {
        return _transferTokens(msg.sender, _recipient, _amount);
    }

    /**
     * @notice Cause iToken is an ERC20 token, so users can `transferFrom` them,
     *         but this action is only allowed when after transferring tokens, the `_sender`
     *         does not have a shortfall.
     * @dev Moves `_amount` tokens from `_sender` to `_recipient`.
     * @param _sender The address of the source account.
     * @param _recipient The address of the destination account.
     * @param _amount The number of tokens to transfer.
     */
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public virtual override nonReentrant returns (bool) {
        _approve(
            _sender,
            msg.sender, // spender
            allowance[_sender][msg.sender].sub(_amount)
        );
        return _transferTokens(_sender, _recipient, _amount);
    }
}