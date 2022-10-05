// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./SSTORE2Map.sol";
import "./potted_types.sol";

contract PPData is Ownable {
  PottedTypes.Potted[] private potteds;
  PottedTypes.Branch[] private branches;
  PottedTypes.Blossom[] private blossoms;
  PottedTypes.Bg[] private bgs;

  string constant bg = "bg";
  string constant pottedA = "PottedA";
  string constant pottedB = "PottedB";
  string constant pottedC = "PottedC";
  string constant branchA = "branchA";
  string constant branchB = "branchB";
  string constant branchC = "branchC";
  string constant blossomA = "blossomA";
  string constant blossomB = "blossomB";
  string constant blossomC = "blossomC";
  string constant unreveal = "unreveal";

  function getAllPotted() external view returns (PottedTypes.Potted[] memory) {
    return potteds;
  }

  function getAllBranch() external view returns (PottedTypes.Branch[] memory) {
    return branches;
  }

  function getAllBlossom() external view returns (PottedTypes.Blossom[] memory) {
    return blossoms;
  }

  function getAllBg() external view returns (PottedTypes.Bg[] memory) {
    return bgs;
  }

  function updatePotted(uint index, PottedTypes.Potted memory newData) external onlyOwner {
    potteds[index] = newData;
  }

  function updateBranch(uint index, PottedTypes.Branch memory newData) external onlyOwner {
    branches[index] = newData;
  }

  function updateBlossom(uint index, PottedTypes.Blossom memory newData) external onlyOwner {
    blossoms[index] = newData;
  }

  function setPotteds(PottedTypes.Potted[] calldata _potted) external onlyOwner {
    for (uint i; i < _potted.length; i++) {
      potteds.push(_potted[i]);
    } 
  }

  function setBranches(PottedTypes.Branch[] calldata _branch) external onlyOwner {
    for (uint i; i < _branch.length; i++) {
      branches.push(_branch[i]);
    } 
  }

  function setBlossoms(PottedTypes.Blossom[] calldata _blossom) external onlyOwner {
    for (uint i; i < _blossom.length; i++) {
      blossoms.push(_blossom[i]);
    } 
  }

  function setBgs(PottedTypes.Bg[] calldata _bg) external onlyOwner {
    for (uint i; i < _bg.length; i++) {
      bgs.push(_bg[i]);
    } 
  }

  ///IMAGES
  //Potted
  function setPottedAImages(bytes[] calldata _hashes) external onlyOwner {
    SSTORE2Map.write(pottedA, abi.encode(_hashes));
  }
  function setPottedBImages(bytes[] calldata _hashes) external onlyOwner {
    SSTORE2Map.write(pottedB, abi.encode(_hashes));
  }
  function setPottedCImages(bytes[] calldata _hashes) external onlyOwner {
    SSTORE2Map.write(pottedC, abi.encode(_hashes));
  }
  function getPottedImages() external view returns (bytes[] memory) {
    bytes[] memory dataA = abi.decode(SSTORE2Map.read(pottedA), (bytes[]));
    bytes[] memory dataB = abi.decode(SSTORE2Map.read(pottedB), (bytes[]));
    bytes[] memory dataC = abi.decode(SSTORE2Map.read(pottedC), (bytes[]));

    bytes[] memory hashes = new bytes[](dataA.length + dataB.length + dataC.length);

    for (uint i = 0; i < dataA.length; i++) {
      hashes[i] = dataA[i];
    }
    
    for (uint i = 0; i < dataB.length; i++) {
      hashes[i + dataA.length] = dataB[i];
    }
    
    for (uint i = 0; i < dataC.length; i++) {
      hashes[i + dataA.length + dataB.length] = dataC[i];
    }

    return hashes;
  }

  //Branch
  function setBranchAImages(bytes[] calldata _hashes) external onlyOwner {
    SSTORE2Map.write(branchA, abi.encode(_hashes));
  }
  function setBranchBImages(bytes[] calldata _hashes) external onlyOwner {
    SSTORE2Map.write(branchB, abi.encode(_hashes));
  }
  function setBranchCImages(bytes[] calldata _hashes) external onlyOwner {
    SSTORE2Map.write(branchC, abi.encode(_hashes));
  }
  function getBranchImages() external view returns (bytes[] memory) {
    bytes[] memory dataA = abi.decode(SSTORE2Map.read(branchA), (bytes[]));
    bytes[] memory dataB = abi.decode(SSTORE2Map.read(branchB), (bytes[]));
    bytes[] memory dataC = abi.decode(SSTORE2Map.read(branchC), (bytes[]));

    bytes[] memory hashes = new bytes[](dataA.length + dataB.length + dataC.length);

    for (uint i = 0; i < dataA.length; i++) {
      hashes[i] = dataA[i];
    }
    
    for (uint i = 0; i < dataB.length; i++) {
      hashes[i + dataA.length] = dataB[i];
    }
    
    for (uint i = 0; i < dataC.length; i++) {
      hashes[i + dataA.length + dataB.length] = dataC[i];
    }

    return hashes;
  }

  //Blossom
  function setBlossomAImages(bytes[] calldata _hashes) external onlyOwner {
    SSTORE2Map.write(blossomA, abi.encode(_hashes));
  }
  function setBlossomBImages(bytes[] calldata _hashes) external onlyOwner {
    SSTORE2Map.write(blossomB, abi.encode(_hashes));
  }
  function setBlossomCImages(bytes[] calldata _hashes) external onlyOwner {
    SSTORE2Map.write(blossomC, abi.encode(_hashes));
  }
  function getBlossomImages() external view returns (bytes[] memory) {
    bytes[] memory dataA = abi.decode(SSTORE2Map.read(blossomA), (bytes[]));
    bytes[] memory dataB = abi.decode(SSTORE2Map.read(blossomB), (bytes[]));
    bytes[] memory dataC = abi.decode(SSTORE2Map.read(blossomC), (bytes[]));

    bytes[] memory hashes = new bytes[](dataA.length + dataB.length + dataC.length);

    for (uint i = 0; i < dataA.length; i++) {
      hashes[i] = dataA[i];
    }
    
    for (uint i = 0; i < dataB.length; i++) {
      hashes[i + dataA.length] = dataB[i];
    }
    for (uint i = 0; i < dataC.length; i++) {
      hashes[i + dataA.length + dataB.length] = dataC[i];
    }

    return hashes;
  }

  //Background
  function setBgImages(bytes[] calldata _hashes) external onlyOwner {
    SSTORE2Map.write(bg, abi.encode(_hashes));
  }
  function getBgImages() external view returns (bytes[] memory) {
    return abi.decode(SSTORE2Map.read(bg), (bytes[]));
  }

  //Unreveal
  function setUnreveal(bytes[] calldata _hashes) external onlyOwner {
    SSTORE2Map.write(unreveal, abi.encode(_hashes));
  }
  function getUnreveal() external view returns (bytes[] memory) {
    return abi.decode(SSTORE2Map.read(unreveal), (bytes[]));
  }

}