/**
 *Submitted for verification at BscScan.com on 2023-02-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IMP {
    function executeToken(address tokenaddress,address receiver,uint256 amount) external returns (bool);
}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) { owner = _owner; }
    modifier onlyOwner() { require(isOwner(msg.sender), "!OWNER"); _; }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

contract valueProveRouterV1 is Ownable {

  address public implement;
  address public rewardToken;
  mapping (address=>bool) public isAdmin;

  mapping (address=>uint256) public _claimed;
  mapping (address=>uint256) public _count;

  event Withdraw(address indexed admin, address indexed recaiver, uint256 amount, uint256 nounce);

  constructor(address _implement,address _rewardToken) Ownable(msg.sender) {
    implement = _implement;
    rewardToken = _rewardToken;
  }

  function Authorize(address account,bool flag) public onlyOwner {
    isAdmin[account] = flag;
  }

  function updateImplement(address _implement,address _rewardToken) public onlyOwner {
    implement = _implement;
    rewardToken = _rewardToken;
  }

  function getMessageHash(address _to,uint _amount,uint _nonce) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_to, _amount, _nonce));
  }

  function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
  }

  function verify(address _signer,address _to,uint _amount,uint _nonce,bytes memory signature) public view returns (bool) {
    bytes32 messageHash = getMessageHash(_to, _amount, _nonce);
    bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);     
    require(isAdmin[_signer] == true,"_signer != admin");
    return recoverSigner(ethSignedMessageHash, signature) == _signer;
  }

  function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
    return ecrecover(_ethSignedMessageHash, v, r, s);
  }

  function splitSignature(bytes memory sig) public pure returns (bytes32 r,bytes32 s,uint8 v) {
    require(sig.length == 65, "invalid signature length");
    assembly { 
        r := mload(add(sig, 32))
        s := mload(add(sig, 64))
        v := byte(0, mload(add(sig, 96))) }
  }

  function ClaimReward(address _admin,uint256 _amount,bytes memory _sig) external returns(bool) {
    bool success = verify(_admin,msg.sender,_amount,_count[msg.sender],_sig);
    require(success,"Revert By Vault : Claim Fail");
    require(_amount>_claimed[msg.sender]);
    uint256 claimamount = _amount - _claimed[msg.sender];
    _claimed[msg.sender] += claimamount;
    _count[msg.sender] += 1;
    IMP(implement).executeToken(rewardToken,msg.sender,claimamount);
    return true;
  }

}