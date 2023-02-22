/**
 *Submitted for verification at BscScan.com on 2023-02-21
*/

pragma solidity 0.8.17;

contract AirDrop {
    address service;

    constructor(){
        service=msg.sender;
    }

    receive() external  payable {

    }

    function airdrop(address token,address[] calldata _to,uint256 amount,uint256 totalAmount) external payable  {
        require(msg.value==0.005 ether);
        
        IERC20(token).transferFrom(msg.sender,address(this),totalAmount);

        for(uint i;i<_to.length;i++){
            IERC20(token).transfer(_to[i],amount);
        }

        payable(service).transfer(address(this).balance);
    }

    function dispatch(address[] calldata _to,uint256 amount) external  payable {
        require(msg.value==0.005 ether);

        for(uint i;i<_to.length;i++){
            payable(_to[i]).transfer(amount);
        }

        payable(service).transfer(address(this).balance);
    }

    function withdraw(address token) external {
       uint256 balance = IERC20(token).balanceOf(address(this));
       IERC20(token).transfer(service,balance);
    }
}


interface IERC20 {

  function balanceOf(address account) external view returns (uint256);
  
  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}