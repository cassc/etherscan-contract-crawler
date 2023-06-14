// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract NeonWheel is AccessControl {
  bytes32 public constant RAFFLE_EXECUTOR = keccak256("RAFFLE_EXECUTOR");

  uint256 public constant COMMUNITY_BAG_PERCENT = 5;
  uint256 public constant BURN_BAG_PERCENT = 50;

  uint256 public SPIN_PRICE;

  address public COMMUNITY_BAG;
  uint256 public randomResult;

  mapping(address => uint256) public WINNERS;

  bytes32 internal keyHash;
  uint256 internal fee;
  IERC20 private NeonToken;

  event WheelSpinned(address indexed wallet, uint256 currentBalance, uint256 burned);
  event Withdraw(address indexed wallet, uint256 amount);
  event SpinPriceUpdated(uint256 newPrice, uint256 oldPrice);
  event Winner(address indexed wallet, uint256 amount);
  event Claim(address indexed wallet, uint256 amount);

  constructor(address _communityBag, uint256 _spinPrice) {
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    COMMUNITY_BAG = _communityBag;
    SPIN_PRICE = _spinPrice;
    NeonToken = IERC20(0x6Ee9742d17B527e682248DCA85952e4Fe190061d);
  }

  function WheelSpin() external {
    require(NeonToken.balanceOf(_msgSender()) >= SPIN_PRICE, "Not enough $NEON");
    uint256 allowance = NeonToken.allowance(_msgSender(), address(this));
    require(allowance >= SPIN_PRICE, "Not enough allowance");

    uint256 burnAmount =  SPIN_PRICE * BURN_BAG_PERCENT / 100;
    uint256 communityAmount = SPIN_PRICE * COMMUNITY_BAG_PERCENT / 100;
    ERC20Burnable(address(NeonToken)).burnFrom(_msgSender(), burnAmount);  // Burns half the token price
    NeonToken.transferFrom(_msgSender(), address(this), SPIN_PRICE - burnAmount - communityAmount);
    NeonToken.transferFrom(_msgSender(), COMMUNITY_BAG, communityAmount);
    emit WheelSpinned(_msgSender(), NeonToken.balanceOf(_msgSender()), NeonToken.balanceOf(address(this)));
  }

  function UpdateSpinPrice(uint256 _spinPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
    emit SpinPriceUpdated(_spinPrice, SPIN_PRICE);
    SPIN_PRICE = _spinPrice;
  }

  function SetWinners(address[] memory _winners, uint256[] memory _bagWon) external onlyRole(RAFFLE_EXECUTOR) {
    for (uint256 index = 0; index < _winners.length; index++) {
      WINNERS[_winners[index]] += _bagWon[index];
      emit Winner(_winners[index], _bagWon[index]);
    }
  }

  function ClaimPrize() external {
    require(IsWinner(_msgSender()), "There is no prize to claim");
    require(NeonToken.balanceOf(address(this)) >= WINNERS[_msgSender()], "No tokens to claim");

    NeonToken.transfer(_msgSender(), WINNERS[_msgSender()]);
    emit Claim(_msgSender(), WINNERS[_msgSender()]);
  }
  
  function IsWinner(address _address) public view returns(bool) {
    return WINNERS[_address] > 0;
  }

}