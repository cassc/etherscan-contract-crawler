//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

interface IClonableDeedHashed {
  function initialize(address _admin) external;
  function update(bytes32 _hash, bytes32 _metahash) external;
  function transferOwnership(address newOwner) external;
  function getType() external pure returns(bytes32);
}

contract DeedHashedCloneFactory is Ownable {

    event NewDeedHashedClone(
      address indexed referenceContract,
      address indexed cloneContract,
      address indexed admin
    );

    event UpdatedDeedHashedClone(
      address indexed cloneContract,
      bytes32 indexed _hash,
      bytes32 indexed _metahash
    );

    event TransferOwnershipDeedHashedClone(
      address indexed cloneContract,
      address _newOwner
    );

    event SetClonableDeedHashedReferenceContractValidity(
      address indexed referenceContract,
      bool validity
    );

    mapping(address => bool) public validClonableDeedHashed;
    mapping(address => bool) public isClone;

    constructor(
      address _clonableDeedHashedReference
    ) {
      validClonableDeedHashed[_clonableDeedHashedReference] = true;
      emit SetClonableDeedHashedReferenceContractValidity(_clonableDeedHashedReference, true);
    }

    function setClonableDeedHashedReferenceValidity(
      address _clonableDeedHashedReference,
      bool _validity
    ) external onlyOwner {
      validClonableDeedHashed[_clonableDeedHashedReference] = _validity;
      emit SetClonableDeedHashedReferenceContractValidity(_clonableDeedHashedReference, _validity);
    }

    function newDeedHashedClone(
      address _clonableDeedHashedReference
    ) external onlyOwner {
      require(validClonableDeedHashed[_clonableDeedHashedReference], "INVALID_WHITELIST_REFERENCE_CONTRACT");
      // Deploy new DeedHashed contract
      address newDeedHashedCloneAddress = Clones.clone(_clonableDeedHashedReference);
      isClone[newDeedHashedCloneAddress] = true;
      IClonableDeedHashed deedHashedClone = IClonableDeedHashed(newDeedHashedCloneAddress);
      deedHashedClone.initialize(address(this));
      emit NewDeedHashedClone(_clonableDeedHashedReference, newDeedHashedCloneAddress, address(this));
    }

    function updateDeedHashedClone(
      address _deedHashedClone,
      bytes32 _hash,
      bytes32 _metahash
    ) external onlyOwner {
      require(isClone[_deedHashedClone] == true, "INVALID_CLONE_ADDRESS");
      IClonableDeedHashed deedHashedClone = IClonableDeedHashed(_deedHashedClone);
      deedHashedClone.update(_hash, _metahash);
      emit UpdatedDeedHashedClone(_deedHashedClone, _hash, _metahash);
    }

    function transferDeedHashedCloneOwnership(
      address _deedHashedClone,
      address _newOwner
    ) external onlyOwner {
      require(isClone[_deedHashedClone] == true, "INVALID_CLONE_ADDRESS");
      IClonableDeedHashed deedHashedClone = IClonableDeedHashed(_deedHashedClone);
      deedHashedClone.transferOwnership(_newOwner);
      emit TransferOwnershipDeedHashedClone(_deedHashedClone, _newOwner);
    }

    function getTypeDeedHashedClone(
      address _deedHashedClone
    ) external view returns (bytes32) {
      require(isClone[_deedHashedClone] == true, "INVALID_CLONE_ADDRESS");
      IClonableDeedHashed deedHashedClone = IClonableDeedHashed(_deedHashedClone);
      return deedHashedClone.getType();
    }

}