// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IReference {
  function addReference(address _user, address _referrer) external;
  function addRefIncome(address _user, uint256 _amount) external;
}

contract BuyFarmTycoon is Ownable, Pausable {
    using SafeERC20 for IERC20;

    IERC20 token;
    IReference refcontract;
    uint256 public price;

    mapping(address => uint256) public sended;
    mapping(address => uint256) public withdrawed;
    
    fallback() external payable {
        deposit(address(0x0));
    }

    receive() external payable {
        deposit(address(0x0));
    }

    function Setup(address token_addr, address reference_addr) external onlyOwner {
        token = IERC20(token_addr);
        refcontract = IReference(reference_addr);
    }

    function deposit(address _referred) public payable whenNotPaused {
        require(msg.value > 0, "must be greater than zero");
        refcontract.addReference(msg.sender, _referred);
        sended[msg.sender] += msg.value;
    }

    function withdraw() external{
      require(price > 0, "must be greater than zero");
      require(sended[msg.sender] >= price, "minimum 1 FTY");
      
      uint256 _sold = getAwailable(msg.sender);
      
      require(token.balanceOf(address(this)) >= _sold,"INSUFFICIENT CONTRACT BALANCE");
      require(token.transfer(msg.sender, _sold), "TRANSFER FAILED");
      
      refcontract.addRefIncome(msg.sender, _sold);

      withdrawed[msg.sender] += _sold;
      sended[msg.sender] = 0;
    }

    function getAwailable(address _user) public view returns(uint256){
        if(sended[_user] > 0 && price > 0){
            return ((sended[_user] * 10 ** token.decimals()) / price);
        }else{
            return 0;
        }
    }

    // Only Owner

    function setPrice(uint256 _price) external onlyOwner{
      price = _price;
    }

    function withdrawToken(uint256 _amount) external onlyOwner{
        require(token.transfer(owner(), _amount), "TRANSFER FAILED");
    }

    function withdrawBnb() external onlyOwner {
        if (address(this).balance >= 0) {
            payable(owner()).transfer(address(this).balance);
        }
    }
}