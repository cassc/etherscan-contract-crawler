// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC20Base.sol";

/**
 * @dev allow the owner to block an address
 */
abstract contract AccountValidator is Ownable, ERC20Base {
    mapping(address => bool) private _denied;

    event AddressDenied(address indexed account, bool denied);

    modifier notDenied(address account) {
        require(!_denied[account], "Address denied");
        _;
    }

    function _setIsDenied(address account, bool denied) internal {
        _denied[account] = denied;
        emit AddressDenied(account, denied);
    }

    function isAccountDenied(address account) public view returns (bool) {
        return _denied[account];
    }

    function setIsAccountDenied(address account, bool denied) external onlyOwner {
        require(_denied[account] != denied, "Already set");
        _setIsDenied(account, denied);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override notDenied(from) notDenied(to) {
        super._beforeTokenTransfer(from, to, amount);
    }
}