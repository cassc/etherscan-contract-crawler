//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol';

contract MTRL is ERC20, ERC20Permit {
    /// @dev admin that can manage minters and transfer
    address public admin;

    /// @dev initial supply to be minted
    uint256 public constant INITIAL_SUPPLY = 100_000_000e18;

    /// @dev enable/disable token transfer
    bool public transfersAllowed = true;

    /// @dev Emitted when transfer toggle is switched
    event TransfersAllowed(bool transfersAllowed);

    constructor(address _admin) ERC20('Material', 'MTRL') ERC20Permit('Material') {
        require(_admin != address(0), 'constructor: invalid admin');
        admin = _admin;
        _mint(_admin, INITIAL_SUPPLY);
    }

    modifier onlyAdmin() {
        require(admin == msg.sender, 'onlyAdmin: caller is not the owner');
        _;
    }

    /// @dev Toggles transfer allowed flag.
    function setTransfersAllowed(bool _transfersAllowed) external onlyAdmin {
        transfersAllowed = _transfersAllowed;
        emit TransfersAllowed(transfersAllowed);
    }

    /// @dev transfer ownership
    function transferOwnership(address _newAdmin) external onlyAdmin {
        require(admin != _newAdmin && _newAdmin != address(0), 'transferOwnership: invalid admin');
        admin = _newAdmin;
    }

    /// @dev disable/enable transfer with transfersAllowed
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(transfersAllowed, '_beforeTokenTransfer: transfer is disabled');
    }
}