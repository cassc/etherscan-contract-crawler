//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";

interface ISupplySaverClonable {
  function initialize(address _wgmis, address _destinationAddress) external;
}

contract SupplySaverCloneFactory {

  event NewSupplySaver(address indexed supplySaverAddress);

  address public wgmis;
  address public referenceSupplySaver;
  address public wgmisDeployer;

  constructor(
    address _referenceSupplySaver,
    address _wgmisDeployer,
    address _wgmis
  ) {
    referenceSupplySaver = _referenceSupplySaver;
    wgmisDeployer = _wgmisDeployer;
    wgmis = _wgmis;
  }

  function newSupplySaver(address _destinationAddress) external {
    require(msg.sender == wgmisDeployer);
    address newSupplySaverClone = Clones.clone(referenceSupplySaver);
    ISupplySaverClonable supplySaverClone = ISupplySaverClonable(newSupplySaverClone);
    supplySaverClone.initialize(wgmis, _destinationAddress);
    emit NewSupplySaver(newSupplySaverClone);
  }

  function setReferenceSupplySaver(address _referenceSupplySaver) external {
    require(msg.sender == wgmisDeployer);
    referenceSupplySaver = _referenceSupplySaver;
  }

  function setWgmisDeployer(address _wgmisDeployer) external {
    require(msg.sender == wgmisDeployer);
    wgmisDeployer = _wgmisDeployer;
  }

}