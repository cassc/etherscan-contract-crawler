//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

import {Ownable} from "../TokenContracts/Ownable.sol";

/**
* @notice Contract that lets owner set a controller admin that can add or remove
* controllers. Only the contract owner can modify the admin.
 */

contract ControllerAdmin is Ownable {
    address internal _controllerAdmin;
    uint256 internal _maxNumOfMinters;

    event controllerAdminChanged(address indexed admin);

    modifier onlyControllerAdmin() {
        require(msg.sender != address(0), "No zero addr");
        require(msg.sender == _controllerAdmin, "caller not controller admin");
        _;
    }

    function getControllerAdmin() external view returns (address) {
        return _controllerAdmin;
    }

    function setControllerAdmin(address _newAdmin) external onlyOwner {
        require(_newAdmin != address(0), "No zero addr");
        _controllerAdmin = _newAdmin;
        emit controllerAdminChanged(_controllerAdmin);
    }

    function setMaxNumberOfMinters(uint256 _newMax) external onlyControllerAdmin {
        _setMaxNumberOfMinters(_newMax);
    }

    function _setMaxNumberOfMinters(uint256 _newMax) internal  {
        require(_newMax != 0, "No zero addr");
        _maxNumOfMinters = _newMax;
    }


    function getMaxMinters() external view returns (uint256) {
        return _maxNumOfMinters;
    }

}