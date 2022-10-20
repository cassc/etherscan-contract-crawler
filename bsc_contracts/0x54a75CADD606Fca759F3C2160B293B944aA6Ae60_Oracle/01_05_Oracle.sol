// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract Oracle{
  address owner;
  uint256 price = 16000000000000000;
  uint256 busdPrice;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require( owner == msg.sender,  'No sufficient right');
      _;
  }

  function setOwner(address _owner) onlyOwner external {
     owner = _owner;
  }

   function setPrice(uint256 price_, uint256 bprice) onlyOwner external {
     price = price_;
     busdPrice = bprice;
  }

  function getPrice() external view returns (uint256) {
    return price;
  }
  
  function getBusdPrice() external view returns (uint256) {
    return busdPrice;
  }

  
  function withdrawToken(address token) public onlyOwner{
   ERC20 token_contract = ERC20(token);
   token_contract.transferFrom(address(this),msg.sender, token_contract.balanceOf(address(this)));
  }

  function withdrawETH() public onlyOwner{
  address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
  }
}