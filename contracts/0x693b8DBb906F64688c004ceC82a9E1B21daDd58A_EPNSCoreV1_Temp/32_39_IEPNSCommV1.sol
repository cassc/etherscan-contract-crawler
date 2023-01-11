pragma solidity >=0.6.0 <0.7.0;

interface IEPNSCommV1 {
 	function subscribeViaCore(address _channel, address _user) external returns(bool);
  function unSubscribeViaCore(address _channel, address _user) external returns (bool);
}