// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IBTSOwnerManager.sol";

import "./libraries/String.sol";

contract BTSOwnerManager is Initializable, IBTSOwnerManager {
    using SafeMathUpgradeable for uint256;
    event SetOwnership(address indexed promoter, address indexed newOwner);
    event RemoveOwnership(address indexed remover, address indexed formerOwner);

    address[] private listOfOwners;
    mapping(address => bool) internal owners;

    modifier onlyOwner() {
        require(owners[msg.sender] == true, "Unauthorized");
        _;
    }


    function initialize() public initializer {
        owners[msg.sender] = true;
        listOfOwners.push(msg.sender);
        emit SetOwnership(address(0), msg.sender);
    }

    /**
       @notice Adding another Onwer.
       @dev Caller must be an Onwer of BTP network
       @param _owner    Address of a new Onwer.
   */
    function addOwner(address _owner) external override onlyOwner {
        require(owners[_owner] == false, "ExistedOwner");
        owners[_owner] = true;
        listOfOwners.push(_owner);
        emit SetOwnership(msg.sender, _owner);
    }

    /**
       @notice Removing an existing Owner.
       @dev Caller must be an Owner of BTP network
       @dev If only one Owner left, unable to remove the last Owner
       @param _owner    Address of an Owner to be removed.
   */
    function removeOwner(address _owner) external override onlyOwner {
        require(listOfOwners.length > 1, "CannotRemoveMinOwner");
        require(owners[_owner] == true, "NotanOwner");
        delete owners[_owner];
        _remove(_owner);
        emit RemoveOwnership(msg.sender, _owner);
    }

    function _remove(address _addr) internal {
        for (uint256 i = 0; i < listOfOwners.length; i++)
            if (listOfOwners[i] == _addr) {
                listOfOwners[i] = listOfOwners[listOfOwners.length - 1];
                listOfOwners.pop();
                break;
            }
    }

    /**
       @notice Checking whether one specific address has Owner role.
       @dev Caller can be ANY
       @param _owner    Address needs to verify.
    */
    function isOwner(address _owner) external view override returns (bool) {
        return owners[_owner];
    }

    /**
       @notice Get a list of current Owners
       @dev Caller can be ANY
       @return      An array of addresses of current Owners
    */
    function getOwners() external view override returns (address[] memory) {
        return listOfOwners;
    }
}