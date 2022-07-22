pragma solidity >=0.4.21 <0.6.0;
contract KeyVerifierInterface{
  function verify_pkey(bytes memory _pkey, bytes memory _pkey_sig) public view returns(bool);
}