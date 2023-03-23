// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ILayerrToken.sol";

contract LayerrFactory is Ownable {
  struct ContractImplementation {
    address implementationAddress;
    bool active;
  }

  error InactiveImplementation();

  address public LayerrXYZ;

  mapping(address => address[]) public allClones;
  mapping(string => address) public projectIdToAddress;
  mapping(uint256 => ContractImplementation) public contractImplementations;

  /**
    * @dev Sets the `implementation` address for the `implementationId`.
    * @param implementationId The id of the implementation to be set.
    * @param _implementation The address of the implementation.
    * @param active Whether the implementation is active or not.
    */
  function setImplementation(uint256 implementationId, address _implementation, bool active) external onlyOwner {
    ContractImplementation storage contractImplementation = contractImplementations[implementationId];
    contractImplementation.implementationAddress = _implementation;
    contractImplementation.active = active;
  }

  /**
    * @dev Sets the `LayerrVariables` address to be passed to clones to read fees and addresses.
    */
  function setLayerrXYZ(address _LayerrXYZ) external onlyOwner {
    LayerrXYZ = _LayerrXYZ;
  }
  
  /**
    * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
    *
    * This function uses the create opcode, which should never revert.
    */
  function clone(address _implementation) internal returns (address instance) {
    assembly {
      let ptr := mload(0x40)
      mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(ptr, 0x14), shl(0x60, _implementation))
      mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      instance := create(0, ptr, 0x37)
    }
    require(instance != address(0), "ERC1167: create failed");
  }

  /**
    * @dev Deploys a clone of the implementation with the given `implementationId`.
    * @param implementationId The id of the implementation to be deployed.
    * @param data The data to be passed to the clone's `initialize` function.
    * @param projectId The id of the project to be deployed.
    */
  function deployContract(string calldata projectId, uint256 implementationId, bytes calldata data) external {
    ContractImplementation storage contractImplementation = contractImplementations[implementationId];
    if(!contractImplementation.active) { revert InactiveImplementation(); }

    address identicalChild = clone(contractImplementation.implementationAddress);
    allClones[msg.sender].push(identicalChild);
    projectIdToAddress[projectId] = identicalChild;
    ILayerrToken(identicalChild).initialize(data, LayerrXYZ);
  }

  function returnClones(address _owner) external view returns (address[] memory){
      return allClones[_owner];
  }

}