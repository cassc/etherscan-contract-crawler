// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

import "./AccessControlPermissible.sol";
import "./interfaces/IWhitelist.sol";

contract Whitelist is AccessControlPermissible, IWhitelist {
    mapping(address => bool) private _members;

    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);

    function isWhitelisted(address _account)
        public
        view
        override
        returns (bool result)
    {
        result = _members[_account];
    }

    //	function findWhitelisted(address[] calldata _accounts) external view returns (address[] memory results) {
    //		//
    //	}

    function add(address _account) external onlyRole(WL_OPERATOR_ROLE) {
        require(!_members[_account], "Whitelist: Address is member already");

        _members[_account] = true;
        emit MemberAdded(_account);
    }

    function addBatch(address[] calldata _accounts)
        external
        onlyRole(WL_OPERATOR_ROLE)
    {
        for (uint256 i; i < _accounts.length; i++) {
            require(
                !_members[_accounts[i]],
                "Whitelist: Address is member already"
            );

            _members[_accounts[i]] = true;
            emit MemberAdded(_accounts[i]);
        }
    }

    function remove(address _account) external onlyRole(WL_OPERATOR_ROLE) {
        require(_members[_account], "Whitelist: Not member of whitelist");

        delete _members[_account];
        emit MemberRemoved(_account);
    }

    function removeBatch(address[] calldata _accounts)
        external
        onlyRole(WL_OPERATOR_ROLE)
    {
        for (uint256 i; i < _accounts.length; i++) {
            require(_members[_accounts[i]], "Whitelist: Address is no member");

            delete _members[_accounts[i]];
            emit MemberRemoved(_accounts[i]);
        }
    }
}