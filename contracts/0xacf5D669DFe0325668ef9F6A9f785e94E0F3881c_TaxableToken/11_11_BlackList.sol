// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BlackList is Ownable {
    mapping (address => bool) private _isBlackListed;

    /**
     * @dev Emitted when the `_account` blocked.
     */
    event BlockedAccount(address indexed _account);

    /**
     * @dev Emitted when the `_account` unblocked.
     */
    event UnblockedAccount(address indexed _account);

    function isAccountBlocked(address _account) public view returns (bool) {
        return _isBlackListed[_account];
    }

    function blockAccount (address _account) public onlyOwner {
        require(!_isBlackListed[_account], "Account is already blocked");
        _isBlackListed[_account] = true;
        emit BlockedAccount(_account);
    }

    function unblockAccount (address _account) public onlyOwner {
        require(_isBlackListed[_account], "Account is already unblocked");
        _isBlackListed[_account] = false;
        emit UnblockedAccount(_account);
    }
}