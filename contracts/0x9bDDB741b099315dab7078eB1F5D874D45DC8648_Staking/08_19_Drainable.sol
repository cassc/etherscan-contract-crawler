// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Drainable is AccessControl {
	bytes32 public constant DRAINER_ADMIN = keccak256("DRAINER_ADMIN");
	bytes32 public constant DRAINER = keccak256("DRAINER");

    constructor() {
        _grantRole(DRAINER_ADMIN, msg.sender);
        _setRoleAdmin(DRAINER, DRAINER_ADMIN);
        grantRole(DRAINER, msg.sender);
    }

    modifier onlyAdmin {
        require(hasRole(DRAINER, msg.sender), "err-invalid-drainer");
        _;
    }

    function drain(address _token, address _receiver, uint256 _amount) external onlyAdmin {
        IERC20(_token).transfer(_receiver, _amount);
    }

    function drainETH(address payable _receiver, uint256 _amount) external onlyAdmin {
        (bool success) = _receiver.send(_amount);
        require(success);
    }
}