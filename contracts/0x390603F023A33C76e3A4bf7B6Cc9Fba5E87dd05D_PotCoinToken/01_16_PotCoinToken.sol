// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./lib/token/ERC20/ERC20Snapshot.sol";
import "./lib/access/Ownable.sol";
import "./ERC677/IERC677.sol";
import "./ERC677/IERC677Receiver.sol";
import "./ContextMixin.sol";
import "./NativeMetaTransaction.sol";

/*
** Standard ERC20 capabilities 
** Implements ERC677 transferAndCall, EIP712, Snaphot, and meta transactions
*/
contract PotCoinToken is ERC20Snapshot, Ownable, ContextMixin, NativeMetaTransaction {
    constructor(uint256 initialSupply) ERC20("PotCoin.com POT", "POT") {
        _initializeEIP712("PotCoin.com POT");//domain

        _mint(_msgSender(), initialSupply);
    }

    /* /////////////////////////////
    ** ERC677 Transfer and call
    ** /////////////////////////////
    */
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);

    /**
     * Mints new POT to address (owner only)
     * @param to The address to transfer to.
     * @param amount The amount to be transferred.
     */
    function mint(address to, uint256 amount)
        external
        onlyOwner
    {
        _mint(to, amount);
    }

    /**
    * @dev transfer token to a contract address with additional data if the recipient is a contact.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @param _data The extra data to be passed to the receiving contract.
    */
    function transferAndCall(address _to, uint _value, bytes memory _data)
        public
        returns (bool success)
    {
        super.transfer(_to, _value);
        emit Transfer(_msgSender(), _to, _value, _data);
        if (isContract(_to)) {
            IERC677Receiver receiver = IERC677Receiver(_to);
            receiver.onTokenTransfer(_msgSender(), _value, _data);
        }
        return true;
    }

    function isContract(address _addr)
        private
        view
        returns (bool hasCode)
    {
        uint length;
        assembly { length := extcodesize(_addr) }
        return length > 0;
    }

    /**
     * This is used instead of msg.sender as transactions won't always be sent by the original token owner
     * This overrides ./lib/utils/Context.sol
     */
    function _msgSender()
        internal
        override
        view
        returns (address payable sender)
    {
        return ContextMixin.msgSender();
    }
}