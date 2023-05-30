// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";

contract Auth is Context {
    error NotAuthorized(uint16 req, address sender);

    mapping(address => uint16) _roles;

    modifier requireRole(uint16 req) {
        if (!_hasRole(_msgSender(), req)) {
            revert NotAuthorized(req, _msgSender());
        }
        _;
    }

    function _setRole(address operator, uint16 mask) internal virtual {
        _roles[operator] = mask;
    }

    function _hasRole(
        address operator,
        uint16 role
    ) internal view virtual returns (bool) {
        return _roles[operator] & role == role;
    }
}