pragma solidity <0.6 >=0.4.24;

contract IVerifier {
  function verifyProof(bytes memory _proof, uint256[6] memory _input) public returns(bool);
}