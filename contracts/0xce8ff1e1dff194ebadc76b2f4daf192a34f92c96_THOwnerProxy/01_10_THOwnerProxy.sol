// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IOwnerProxy.sol";

contract THOwnerProxy is Initializable, IOwnerProxy, AccessControlUpgradeable{
    mapping (bytes32 => address) public ownerMap;
    bytes32 public constant INITIALIZER_ROLE= keccak256("INITIALIZER_ROLE");
    address placeholder; //for future use

    function initialize() public initializer{
      __AccessControl_init();
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function ownerOf(bytes32 hash) public view returns (address){
      require(ownerMap[hash]!=address(0),"HTOwnerProxy: This hash doesn't exist");
      return ownerMap[hash];
    }

    event InitOwnerOf(bytes32 hash, address owner);
    function initOwnerOf(bytes32 hash, address owner) external onlyRole(INITIALIZER_ROLE) returns(bool){
      require(ownerMap[hash] == address(0x0), "HTOwnerProxy: Already initialized");
      ownerMap[hash]=owner;
      emit InitOwnerOf(hash, owner);
      return true;
    }

    event TransferOwnership(bytes32 hash, address newOwner);
    function transferOwnership (bytes32 hash, address newOwner) external{
      require(ownerMap[hash]!=address(0),"HTOwnerProxy: This hash doesn't exist");
      require(ownerMap[hash]==msg.sender,"HTOwnerProxy: The caller is not the owner");
      ownerMap[hash]=newOwner;
      emit TransferOwnership(hash, newOwner);
    }

    event TransferAdminstrator(address new_admin);
    function transferAdministrator(address addr) public onlyRole(DEFAULT_ADMIN_ROLE){
      _grantRole(DEFAULT_ADMIN_ROLE, addr);
      _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}