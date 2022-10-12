// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.2.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PreSale is Ownable {
  event SwapEvent(address addr, uint256 amount);

  address public DSTAddress; // DST ERC20 token address
  address public foundationWallet; // Foundation wallet address

  uint256 public preSale1Height; // First presale block number
  uint256 public preSale2Height; // Second presale block number
  uint256 public publicSaleHeight; // Public sale block number
  uint256 public price; // Sale price

  // Presale Account
  struct PreSaleAccount {
    uint256 totalClaimBalance; // Total able claim balance
    uint256 claimedBalance; // Claimed balance
    bool isExist;
  }

  mapping(address => PreSaleAccount) public preSaleAccounts;

  // [Owner] Enter presale information
  function setPreSaleInfo(uint256 _price, uint256 _preSale1Height, uint256 _preSale2Height, uint256 _publicSaleHeight) public onlyOwner {
    require(_price > 0, "price must be greater than zero");
    require(_preSale2Height > _preSale1Height, "Presale 2 cannot be faster than Presale 1");
    require(_publicSaleHeight > _preSale2Height, "Public sale cannot be faster than Presale 1");

    price = _price;
    preSale1Height = _preSale1Height;
    preSale2Height = _preSale2Height;
    publicSaleHeight = _publicSaleHeight;
  }

  // [Owner] Enter foundation wallet address
  function setFoundationWalletAddress(address _addr) public onlyOwner {
    foundationWallet = _addr;
  }

  // [Owner] Enter DST(ERC-20) contract address
  function setDSTAddress(address _addr) public onlyOwner {
    IERC20(_addr).balanceOf(_addr);
    DSTAddress = _addr;
  }

  // [Owner] Add presale accounts
  // Params: addressList:["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4"], balanceList:[123]
  function addPreSaleAccounts(address[] memory _addressList, uint256[] memory _balanceList) public onlyOwner {
    require(_addressList.length == _balanceList.length, "need same length");
    for (uint i = 0; i < _addressList.length; i++) {
      if(!preSaleAccounts[_addressList[i]].isExist) {
        preSaleAccounts[_addressList[i]] = PreSaleAccount({
          totalClaimBalance: _balanceList[i],
          claimedBalance : 0,
          isExist: true
        });
      }
    }
  }

  // [Owner] Set presale account
  function setPreSaleAccount(address _address, uint256 _balance, bool _isExist) public onlyOwner {
    PreSaleAccount storage account = preSaleAccounts[_address];
    require(account.isExist, "not registered");
    account.totalClaimBalance = _balance;
    account.isExist = _isExist;
  }

  // [Onwer] Check the ETH balance
  function getEthBalance() public view returns(uint256){
    return address(this).balance;
  }

  // [Owner] Check the DST balance
  function getDSTBalance() public view returns(uint256){
    return IERC20(DSTAddress).balanceOf(address(this));
  }

  // [Owner] Withdraw ETH
  function withdrawETH() public onlyOwner {
    require(foundationWallet != address(0), "no foundation address");
    payable(foundationWallet).transfer(address(this).balance);
  }

  // [Owner] Withdraw DST
  function withdrawDST() public onlyOwner {
    require(foundationWallet != address(0), "no foundation address");
    IERC20(DSTAddress).transfer(foundationWallet, IERC20(DSTAddress).balanceOf(address(this)));
  }

  // [User] Swap ETH to DST
  function swap() public payable {
    require(price > 0, "price must be greater than zero");
    require(msg.value > 0, "value must be greater than zero");
    require(msg.value % price == 0, "price error");

    uint blockNumber = block.number;
    uint256 amount = msg.value / price;
    require(IERC20(DSTAddress).balanceOf(address(this)) >= amount, "Insufficient quantity");
    uint256 transferAmount = amount * 10 ** 18;

    if(blockNumber >= preSale1Height && blockNumber < preSale2Height) { // Presale 1
      PreSaleAccount storage account = preSaleAccounts[msg.sender];
      require(account.isExist, "Not whitelisted");
      require(account.totalClaimBalance - account.claimedBalance >= amount, "Over claimabled");

      account.claimedBalance += amount;
      IERC20(DSTAddress).transfer(msg.sender, transferAmount);
      emit SwapEvent(msg.sender, amount);
    } else if(blockNumber >= preSale2Height && blockNumber < publicSaleHeight) { // Presale 2
      PreSaleAccount storage account = preSaleAccounts[msg.sender];
      require(account.isExist, "Not whitelisted");

      account.claimedBalance += amount;
      IERC20(DSTAddress).transfer(msg.sender, transferAmount);
      emit SwapEvent(msg.sender, amount);
    } else if(blockNumber >= publicSaleHeight) { // Public Sale
      IERC20(DSTAddress).transfer(msg.sender, transferAmount);
      emit SwapEvent(msg.sender, amount);
    } else {
      revert("can't swap");
    }
  }

  receive() external payable {}
}