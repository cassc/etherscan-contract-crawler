// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISupernova {

    function Received(bytes32 _hsh,bool  _is)  external ;
    function _WithdrawToken(uint _amount,address _recipient,bytes32  appSecret) external payable returns(bool);
    function WithdrawEth(uint _amount,address _recipient,bytes32  appSecret) external payable returns(bool);
    function PutInReward_1(bytes32 _hsh,address _ask,uint _amount) external;
   function PutInReward_2(bytes32 _hsh,address _ask,uint _amount) external;
   function PutInTreasuryETH(bytes32 _hsh,uint _amount) external;
   function PutAndDropReward_1(bytes32 _hsh,address _ask,address _new,uint _amount,uint _userIndex)  external;
   function PutAndDropReward_2(bytes32 _hsh,address _ask,address _new,uint _amount,uint _userIndex)  external;

}