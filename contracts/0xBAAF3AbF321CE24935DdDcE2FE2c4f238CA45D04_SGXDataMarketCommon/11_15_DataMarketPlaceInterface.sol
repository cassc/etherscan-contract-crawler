pragma solidity >=0.4.21 <0.6.0;
import "./ProgramProxyInterface.sol";
import "./OwnerProxyInterface.sol";

contract DataMarketPlaceInterface{
  address public payment_token;

  function program_proxy() public view returns(ProgramProxyInterface);
  function owner_proxy() public view returns(OwnerProxyInterface);

  function delegateCallUseData(address _e, bytes memory data) public returns(bytes memory);
  function getRequestStatus(bytes32 _vhash, bytes32 request_hash) public view returns(int);
  function updateRequestStatus(bytes32 _vhash, bytes32 request_hash, int status) public;

  function getDataInfo(bytes32 _vhash) public view returns(bytes32 data_hash, string memory extra_info, uint256 price, bytes memory pkey, address owner, bool removed, uint256 revoke_timeout_block_num, bool exists);

  function getRequestInfo1(bytes32 _vhash, bytes32 request_hash) public view returns(
          address from, bytes memory pkey4v, bytes memory secret, bytes memory input, bytes memory forward_sig, bytes32 program_hash, bytes32 result_hash);

  function getRequestInfo2(bytes32 _vhash, bytes32 request_hash) public view returns(
          address target_token, uint gas_price, uint block_number, uint256 revoke_block_num, uint256 data_use_price, uint program_use_price, uint status, uint result_type);

}