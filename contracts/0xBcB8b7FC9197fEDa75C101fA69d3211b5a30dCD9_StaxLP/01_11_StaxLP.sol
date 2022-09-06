pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract StaxLP is Ownable, ERC20, AccessControl {
    bytes32 public constant CAN_MINT = keccak256("CAN_MINT");

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, owner());
    }

    function mint(address _to, uint256 _amount) external {
      require(hasRole(CAN_MINT, msg.sender), "Caller cannot mint");
      _mint(_to, _amount);
    }

    function burn(address _account, uint256 _amount) external {
        require(hasRole(CAN_MINT, msg.sender), "Caller cannot burn");
        _burn(_account, _amount);
    }

    function addMinter(address _account) external onlyOwner {
        grantRole(CAN_MINT, _account);
    }

    function removeMinter(address _account) external onlyOwner {
        revokeRole(CAN_MINT, _account);
    }
}