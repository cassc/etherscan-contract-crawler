// SPDX-License-Identifier: gpl-3.0

pragma solidity 0.7.5;

import './IERC677.sol';
import './IERC677Receiver.sol';

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/Initializable.sol';

contract ERC677Upgradeable is Initializable, IERC677, ERC20Upgradeable {
    /**
     * @dev Sets the values for {_name} and {_symbol}, initializes {_decimals} with
     * a default value of 18. And mints {_initialBalance} to address {_initialAccount}
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC677_init(
        address _initialAccount,
        uint256 _initialBalance,
        string memory _name,
        string memory _symbol
    ) internal initializer {
        __ERC20_init(_name, _symbol);
        if (_initialBalance != 0) {
          _mint(_initialAccount, _initialBalance);
        }
    }

    /**
     * @dev check if an address is a contract.
     * @param _addr The address to check.
     */
    function isContract(address _addr) private view returns (bool hasCode) {
        uint256 length;
        assembly {
            length := extcodesize(_addr)
        }
        return length > 0;
    }

    /**
     * @dev transfer token to a contract address with additional data if the recipient is a contact.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     * @param _data The extra data to be passed to the receiving contract.
     */
    function transferAndCall(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public virtual override returns (bool success) {
        require(super.transfer(_to, _value), 'ERC677Upgradeable: transfer failed');
        if (isContract(_to)) {
            IERC677Receiver(_to).onTokenTransfer(msg.sender, _value, _data);
        }
        return true;
    }
}