// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract ReinvestmentProxy is Proxy, Initializable, Ownable {

    uint256 public constant VERSION = 1;

    // @dev Supported Interface this proxy allows
    bytes4 public immutable supportedInterfaceId;

    /// @dev The registered logic address
    address public logic;

    error IncompatibleLogicInterface(address newLogic, bytes4 expectedInterface);

    event SetLogic(address oldAddress, address newAddress);

    constructor(
        address logic_,
        bytes4 supportedInterfaceId_
    ) Ownable() {
        logic = logic_;
        supportedInterfaceId = supportedInterfaceId_;
    }

    /**
     * @dev newLogic The new reinvestment logic address
     * @notice setLogic
     * @param newLogic newLogic
     **/
    function setLogic(address newLogic) external onlyOwner {

        if(!IERC165(newLogic).supportsInterface(supportedInterfaceId)) revert IncompatibleLogicInterface(newLogic, supportedInterfaceId);

        emit SetLogic(logic, newLogic);

        logic = newLogic;

    }


    function _implementation() internal view override returns (address){
        return logic;
    }

}