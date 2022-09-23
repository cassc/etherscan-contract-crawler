/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract heiguogao {

    address public owner;
    address  public  hei =0x51d9E4137b08A0c740E3c5F1ef87dfE0FDe546ba;
    address  public  guo =0xcDeA0a2df3D709313E7DE20AF21842B99884Ab92;
    address  public  gao =0x627A331Dad24fE90dd335CDA24E191ff1720c9Da;
    constructor(){
        owner =msg.sender;
    }
    function deposit() payable public{
  
    }
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    function send_eth() external payable{

        uint per_num =address(this).balance/3;
        payable(hei).transfer(per_num);
        payable(guo).transfer(per_num);
        payable(gao).transfer(per_num);
    }
    function claim() external payable{
        require(msg.sender==owner,'this address no claim');
        payable(owner).transfer(address(this).balance);
    }
    function change_hei(address _hei) external{
        require(msg.sender==owner,'this address NO');
        hei=_hei;
    }
    function change_guo(address _guo) external{
        require(msg.sender==owner,'this address NO');
        guo=_guo;
    }
    function change_gao(address _gao) external{
        require(msg.sender==owner,'this address NO');
        gao=_gao;
    }
}