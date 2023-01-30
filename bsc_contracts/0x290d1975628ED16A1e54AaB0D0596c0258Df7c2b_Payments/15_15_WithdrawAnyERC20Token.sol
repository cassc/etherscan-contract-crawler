pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// interface IWithdrawAnyERC20Token {
    
//     function withdrawAnyERC20Token(address _token, address _target, uint _amount) external;

// }

contract WithdrawAnyERC20Token is AccessControlEnumerable {
    bytes32 public constant WITHDRAWANY_ROLE = keccak256("WITHDRAWANY_ROLE");

    constructor (address _admin, bool _isDefaultAdminRole) {
        if (_isDefaultAdminRole) {
            _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        }
        _setupRole(WITHDRAWANY_ROLE, _admin);
    }

    function withdrawAnyERC20Token(address _token, address _target, uint _amount) public onlyRole(WITHDRAWANY_ROLE) {
        IERC20(_token).transfer(_target, _amount);
    }

}