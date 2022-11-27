// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./SummonV2.sol";

contract SummonV2Manager {
  event SummonCreated(address indexed owner, address indexed summonAddress);
  event TokenLendedFrom(address indexed lender, address indexed summon, address tokenAddress, uint tokenId);
  event TokenWithdrawnTo(address indexed lender, address indexed summon, address tokenAddress, uint tokenId);
  // event TokenDeposit(address _summon, address tokenAddress, )
  mapping(address => address) public OwnerToSummonAddress;
  mapping(address => address) public SummonAddressToOwner;
  mapping(bytes => address) public EncodedTokenToSummon; // map from token => summon
  mapping(bytes => address) public EncodedTokenToLender; // map from token => lender
  address public immutable singleton;

  constructor(address _singleton) {
    singleton = _singleton;
  }

  function CreateNewSummon(address _owner) public returns(address) {
    require(OwnerToSummonAddress[_owner] == address(0), "address already has a Summon");

    address summon = Clones.clone(singleton);
    Summon(summon).init(_owner);



    OwnerToSummonAddress[_owner] = address(summon);
    SummonAddressToOwner[address(summon)] = _owner;
    emit SummonCreated(_owner, address(summon));

    return summon;
  }

  function getEncodedToken(address tokenAddress, uint tokenId) public pure returns(bytes memory encodedToken) {
    return abi.encode(tokenAddress, tokenId);
  }


  function getDecodedToken(bytes calldata _encodedToken) public pure returns(address tokenAddress, uint tokenId) {
    (tokenAddress, tokenId) = abi.decode(_encodedToken, (address, uint));
    return (tokenAddress, tokenId);
  }




  // to be called by lender <-- hahah not anymore
   function lendTokenToBorrower(address borrower, address tokenAddress, uint256 tokenId) public returns(bool success, bytes memory data) {
    OwnerToSummonAddress[borrower] == address(0) && OwnerToSummonAddress[borrower] == this.CreateNewSummon(borrower);

    address borrowerSummon = OwnerToSummonAddress[borrower];
    require(borrowerSummon != address(0), "something went wrong"); // remove this line in the future maybe
    
    bytes memory encodedToken = abi.encode(tokenAddress, tokenId);
    
    // do state changes that say this summon has this token
    EncodedTokenToSummon[encodedToken] = borrowerSummon;
    EncodedTokenToLender[encodedToken] = msg.sender;

    // move token to that summon
    (success, data) = tokenAddress.call(abi.encodeWithSignature("safeTransferFrom(address,address,uint256)",address(msg.sender),borrowerSummon,tokenId));
    emit TokenLendedFrom(address(msg.sender), borrowerSummon, tokenAddress, tokenId);
    require(success, "call failed");
   }

  // to be called by lender <--- haha not anymore
   function withdrawTokenFromSummon(address tokenAddress, uint tokenId) public returns(bool success, bytes memory data) {
    bytes memory _encodedToken = abi.encode(tokenAddress, tokenId);
    address summonAddress = EncodedTokenToSummon[_encodedToken];
    require(EncodedTokenToLender[_encodedToken] == msg.sender || SummonAddressToOwner[summonAddress] == msg.sender, "caller must be lender or summon owner");

    EncodedTokenToSummon[_encodedToken] = address(0);
    EncodedTokenToLender[_encodedToken] = address(0);

    (success, data) = Summon(summonAddress).safeWithdraw(tokenAddress, tokenId, msg.sender);
    
    emit TokenWithdrawnTo(address(msg.sender), summonAddress, tokenAddress, tokenId);
    require(success, "calls call failed");
   }



}

// previously the summon contract itself managed everything, but howwould things changed if the summon factory manged everything?
// the summon factory itself would have to have transfer power. ok thats fine. 
// the summon factory would have to deposit every token to the specific summon address, and store state about where every token is stored.
// on withdraw, the summon factory would have permissions to call a new function: safeWithdraw on the summon in question. safeWithdraw could ONLY be called by the Summon
// Factory, and would transfer the token from the summon address to the lender address


// oooh this would also allow lending tokens to a