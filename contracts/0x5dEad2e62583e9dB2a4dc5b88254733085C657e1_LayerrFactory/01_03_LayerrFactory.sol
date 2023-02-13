// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ILayerr1155 {
  function initialize(
    string memory _name,
    string memory _symbol,
    string memory _contractURI,
    uint96 pct,
    address royaltyReciever,
    address _LayerrXYZ
  ) external;
}

interface ILayerr721 {
  function initialize(
    string memory _name,
    string memory _symbol,
    string memory _contractURI,
    uint96 pct,
    address royaltyReciever,
    address _LayerrXYZ
  ) external;
}

contract LayerrFactory is Ownable {

  address public implementation1155;
  address public implementation721;

  address public LayerrXYZ = 0x1602B3707A9213A313bc21337Ae93c947b4929B4;

  mapping(address => address[]) public allClones;
  mapping(string => address) public projectIdToAddress;

  function setImplementation(address _implementation, uint contractType) external onlyOwner {
    if (contractType == 1155) {
      implementation1155 = _implementation;
    } else if (contractType == 721) {
      implementation721 = _implementation;
    }
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

  function _clone1155(
    string memory _name,
    string memory _symbol,
    string memory _contractURI,
    uint96 pct,
    address royaltyReciever,
    string memory projectId
  ) external {

    address identicalChild = clone(implementation1155);
    allClones[msg.sender].push(identicalChild);
    projectIdToAddress[projectId] = identicalChild;
    ILayerr1155(identicalChild).initialize(
      _name,
      _symbol,
      _contractURI,
      pct,
      royaltyReciever,
      LayerrXYZ
    );
  }

  function _clone721(
    string memory _name,
    string memory _symbol,
    string memory _contractURI,
    uint96 pct,
    address royaltyReciever,
    string memory projectId
  ) external {

    address identicalChild = clone(implementation721);
    allClones[msg.sender].push(identicalChild);
    projectIdToAddress[projectId] = identicalChild;
    ILayerr721(identicalChild).initialize(
      _name,
      _symbol,
      _contractURI,
      pct,
      royaltyReciever,
      LayerrXYZ
    );
  }

  function returnClones(address _owner) external view returns (address[] memory){
      return allClones[_owner];
  }

}