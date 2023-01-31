//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract DeedHashedClonable is OwnableUpgradeable {

    // contains title document hash
    bytes32 public hash;
    // Contains hash of the deed parameters which are not included in the document.
    // Those parameters should be arranged in JSON with an appropriate JSON-schema.
    // Version of a schema contained in "getType" function
    bytes32 public metahash;

    function initialize(
      address _admin
    ) public {
      _transferOwnership(_admin);
    }

    function update(bytes32 _hash, bytes32 _metahash) public onlyOwner {
        hash = _hash;
        metahash = _metahash;
    }

    function getType() external pure returns(bytes32) {
        // hd - hashed deed. Number after the dot is a version of Metadata document schema
        return keccak256("hd.0");
    }
}