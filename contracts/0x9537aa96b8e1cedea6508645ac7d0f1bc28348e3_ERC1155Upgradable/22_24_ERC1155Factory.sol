// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "./ERC1155Upgradable.sol";
import "./ClonableFactory.sol";

interface IHasRegistration {
  function isRegistered(address _contract, uint256 _type) external returns (bool);
  function registerContract(address _contract, uint _type) external;
}

contract ERC1155Factory is ClonableFactory {

  address public handlerAddress;

  function initialize() virtual override public initializer {
    __Ownable_init();
    factoryType = "ERC1155";
  }

  function initializeStage2(address _handlerAddress) public onlyOwner {
    handlerAddress = _handlerAddress;
    ClonableFactory.initialize();
  }

  function implement() virtual override internal returns(address) {
    return address(new ERC1155Upgradable());
  }

  function updateHandler(address _handlerAddress) public onlyOwner {
    handlerAddress = _handlerAddress;
  }

  function afterClone(address newOwner, address clone) internal override onlyOwner {
    if (IHasRegistration(handlerAddress).isRegistered(address(this), 8)) { // if factory registered with handler
      IHasRegistration(handlerAddress).registerContract(clone, 1);
    }
    IHasRegistration(clone).registerContract(handlerAddress, 3); // register handler on erc1155
    // Stream(ERC1155Upgradable(clone).streamAddress()).addMember(Stream.Member(newOwner, 1, 1)); // add owner as stream recipient
    // IERC2981Royalties(clone).setTokenRoyalty(0, ERC1155Upgradable(clone).streamAddress(), 10000); // set contract wide royalties to stream
    // OwnableUpgradeable(ERC1155Upgradable(clone).streamAddress()).transferOwnership(newOwner); // transfer stream, to new owner
    OwnableUpgradeable(clone).transferOwnership(newOwner); // transfer clone to newOwner
  }

  function version() virtual override public view returns (uint256 _version) {
    return 1;
  }
}