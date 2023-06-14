pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import './IToken.sol';

contract BridgeBase is Ownable {

  using SafeMath for uint256;

  IToken public token;
  mapping(address => mapping(uint => bool)) public processedNonces;
  mapping(address => uint256) public balances;

  mapping (address => uint256) public lastProcessedNonce;

  address public admin;

  uint256 private frozenTokens;

  enum Step { Freeze, UnFreeze }
  event Transfer(
    address from,
    address indexed to,
    uint amount,
    uint date,
    uint nonce,
    Step indexed step
  );

  constructor(address _token){
    token = IToken(_token);
  }

  function unlockNonce(address to, uint256 nonce) external onlyOwner {
    processedNonces[to][nonce] = false;
  }

  function changeAdmin(address newAdmin) external onlyOwner {
    admin = newAdmin;
  }

  function addLiquidity(uint256 amount) onlyOwner external  {
    token.transferFrom(msg.sender, address(this), amount);
    balances[msg.sender].add(amount);
  }

  function removeLiquidity(uint256 amount) onlyOwner external  {
    balances[msg.sender].sub(amount);
    token.transfer(msg.sender, amount);
  }

  function freeze(address to, uint amount, uint nonce) external {
    require(processedNonces[msg.sender][nonce] == false, 'transfer already processed');
    processedNonces[msg.sender][nonce] = true;
    token.transferFrom(to, address(this), amount);
    lastProcessedNonce[to] = nonce;
    emit Transfer(
      msg.sender,
      to,
      amount,
      block.timestamp,
      nonce,
      Step.Freeze
    );
  }

    function unFreeze(
    address from, 
    address to, 
    uint amount, 
    uint nonce,
    bytes calldata signature
  ) external {
    bytes32 message = prefixed(keccak256(abi.encodePacked(
      from, 
      to, 
      amount,
      nonce
    )));
    require(recoverSigner(message, signature) == admin , 'wrong signature');
    require(processedNonces[from][nonce] == false, 'transfer already processed');
    processedNonces[from][nonce] = true;
    token.transfer(to, amount);
    lastProcessedNonce[to] = nonce;
    emit Transfer(
      from,
      to,
      amount,
      block.timestamp,
      nonce,
      Step.UnFreeze
    );
  }

  function prefixed(bytes32 hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(
      '\x19Ethereum Signed Message:\n32', 
      hash
    ));
  }

  function recoverSigner(bytes32 message, bytes memory sig)
    internal
    pure
    returns (address)
  {
    uint8 v;
    bytes32 r;
    bytes32 s;
  
    (v, r, s) = splitSignature(sig);
  
    return ecrecover(message, v, r, s);
  }

  function splitSignature(bytes memory sig)
    internal
    pure
    returns (uint8, bytes32, bytes32)
  {
    require(sig.length == 65);
  
    bytes32 r;
    bytes32 s;
    uint8 v;
  
    assembly {
        // first 32 bytes, after the length prefix
        r := mload(add(sig, 32))
        // second 32 bytes
        s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes)
        v := byte(0, mload(add(sig, 96)))
    }
  
    return (v, r, s);
  }
}