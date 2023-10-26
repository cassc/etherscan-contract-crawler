pragma solidity ^0.8.19;

import "./IFreeBase.sol";

interface IFree7 {
  function claim(uint256 free0TokenId, uint256 supportingFree0TokenId) external;
}

contract Free7Helper {
  IFreeBase public immutable freeBase;
  address public first;

  constructor(address freeBaseAddr) {
    freeBase = IFreeBase(freeBaseAddr);
    first = 0xbc3Ced9089e13C29eD15e47FFE3e0cAA477cb069;
  }

  function claimFree7(uint256 free0TokenId, uint256 supportingTokenId) public {
    address free0Owner = freeBase.ownerOf(free0TokenId);
    address supportingOwner = freeBase.ownerOf(supportingTokenId);
    uint256 nextFreeTokenId = freeBase.totalSupply();
    require(first == address(0) || free0Owner == first);

    freeBase.transferFrom(free0Owner, address(this), free0TokenId);
    freeBase.transferFrom(supportingOwner, address(this), supportingTokenId);

    IFree7(freeBase.collectionIdToMinter(7)).claim(free0TokenId, supportingTokenId);

    freeBase.transferFrom(address(this), free0Owner, nextFreeTokenId);
    freeBase.transferFrom(address(this), free0Owner, free0TokenId);
    freeBase.transferFrom(address(this), supportingOwner, supportingTokenId);
    first = address(0);
  }
}
