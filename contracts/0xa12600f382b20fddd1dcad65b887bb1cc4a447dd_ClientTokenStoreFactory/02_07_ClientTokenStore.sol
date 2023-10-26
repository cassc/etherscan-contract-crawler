// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import {IClientTokenStore} from './interfaces/IClientTokenStore.sol';
import {Ownable} from 'oz/access/Ownable.sol';
import {IERC20} from 'oz/token/ERC20/IERC20.sol';

contract ClientTokenStore is Ownable, IClientTokenStore {
  address public claimContract;

  constructor(address _claimContract) {
    claimContract = _claimContract;
  }

  function setClaimContract(address _claimContract) onlyOwner public {
    claimContract = _claimContract;
    //make event
  }

  function withdraw(address _token, uint _amount) external onlyOwner {
    IERC20 token = IERC20(_token);
    require(token.balanceOf(address(this)) >= _amount);
    token.transfer(owner(), _amount);

    emit Withdraw(owner(), _token, _amount);
  }

  function withdrawToReceiver(address _receiver, address _token, uint _amount) external onlyClaimer {
    IERC20 token = IERC20(_token);
    require(_receiver != address(0), "Receiver address invalid");
    require(_token != address(0), "Token address invalid");
    require(_amount > 0, "Amount must be greater than 0");
    require(token.balanceOf(address(this)) >= _amount, "Insufficient Tokens");
    token.transfer(_receiver, _amount);

    emit WithdrawToReceiver(_receiver, _token, _amount);
  }

  // requires allowance
  function deposit(address _token, uint _amount) external {
    require(_token != address(0), "Token address invalid");
    IERC20 token = IERC20(_token);
    require(
      token.allowance(msg.sender, address(this)) >= _amount,
      "Error: Insufficient Allowance"
    );
    token.transferFrom(msg.sender, address(this), _amount);
  }

  modifier onlyClaimer() {
    require(msg.sender == claimContract);
    _;
  }
}