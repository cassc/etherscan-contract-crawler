// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";


interface IPancakePair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint amount0In,
    uint amount1In,
    uint amount0Out,
    uint amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;

  function initialize(address, address) external;
}

interface IPancakeRouter01 {
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

contract APCStake is Initializable,OwnableUpgradeable,ReentrancyGuardUpgradeable{
  using SafeMathUpgradeable for uint;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /* ========== STATE VARIABLES ========== */


  IERC20Upgradeable MUSD;
  IERC20Upgradeable USDT;
  IERC20Upgradeable APC;

  address _pairAddress;


  function initialize(address musdAddress_,address pairAddress_,address usdtAddress_,address apcAddress_) initializer public {
    __ReentrancyGuard_init();
    __Ownable_init();

    MUSD = IERC20Upgradeable(musdAddress_);
    _pairAddress = pairAddress_;
    USDT = IERC20Upgradeable(usdtAddress_);
    APC = IERC20Upgradeable(apcAddress_);
  }

  struct Deposit{
      address addr;
      uint amount;
      uint amountAPC;
      uint amountUSDT;
      uint withdrawn;
      uint timePoint;
      uint creatTime;
  }

  mapping (address => Deposit[]) userDeposits;
  address [] users;

  function getAPCPrice() public view returns (uint){
    (uint112 reserve0, uint112 reserve1,) = IPancakePair(_pairAddress).getReserves();
    return IPancakeRouter01(0x10ED43C718714eb63d5aA57B78B54704E256024E).getAmountOut(1e18,reserve0,reserve1);
  }

  function getLpToTokenOut(uint lpAmount) public view returns(uint amountAPC,uint amountUSDT ){
   uint pairTotalSupply = IPancakePair(_pairAddress).totalSupply();

    uint APC_PAIR_balance = APC.balanceOf(_pairAddress);
    uint USDT_PAIR_balance = USDT.balanceOf(_pairAddress);

    amountAPC = lpAmount.mul(APC_PAIR_balance) / pairTotalSupply;
    amountUSDT = lpAmount.mul(USDT_PAIR_balance) / pairTotalSupply;
  }



  function stake(uint lpAmount) public {
    IERC20Upgradeable(_pairAddress).safeTransferFrom(msg.sender,address(this),lpAmount);
    (uint amountAPC,uint amountUSDT ) = getLpToTokenOut(lpAmount);
    userDeposits[msg.sender].push(Deposit(msg.sender,lpAmount,amountAPC,amountUSDT,0,block.timestamp,block.timestamp));
    users.push(msg.sender);
  }



  function fecthRewards() public view returns (uint musdAmount){

    for(uint i=0;i<userDeposits[msg.sender].length;i++){
      uint tmpAmountUSDT= userDeposits[msg.sender][i].amountUSDT * 2;
      if(tmpAmountUSDT==0){
        continue;
      }
      uint duration = (block.timestamp - userDeposits[msg.sender][i].creatTime).div(24*60*60);

      uint totalReward = tmpAmountUSDT.mul(3).mul(duration).div(1000);
      uint depositWithdrawAmount = totalReward.sub(userDeposits[msg.sender][i].withdrawn);
      musdAmount += depositWithdrawAmount;
    }


  }

  function withdraw() public{
    uint toWithdraw;
    for(uint i=0;i<userDeposits[msg.sender].length;i++){
        uint tmpAmountUSDT= userDeposits[msg.sender][i].amountUSDT * 2;
        if(tmpAmountUSDT==0){
          continue;
        }
        uint duration = (block.timestamp - userDeposits[msg.sender][i].creatTime).div(24*60*60);

        uint totalReward = tmpAmountUSDT.mul(3).mul(duration).div(1000);
        uint depositWithdrawAmount = totalReward.sub(userDeposits[msg.sender][i].withdrawn);

        userDeposits[msg.sender][i].withdrawn += depositWithdrawAmount;

        toWithdraw += depositWithdrawAmount;
    }

    if(toWithdraw > 0){
      MUSD.safeTransfer(msg.sender,toWithdraw);
    }
    emit Withdraw(msg.sender,toWithdraw);
  }

  event Withdraw(address user,uint amount);


  function exit() public {
    for(uint i=0;i < userDeposits[msg.sender].length;i++){
      if(userDeposits[msg.sender][i].amount == 0){
        continue;
      }
      IERC20Upgradeable(_pairAddress).transfer(msg.sender,userDeposits[msg.sender][i].amount);
      userDeposits[msg.sender][i].amount = 0;
    }
    withdraw();
  }


  function claimT(address tokenAddress,address receiveAddr,uint amount) external onlyOwner{
    IERC20Upgradeable(tokenAddress).transfer(receiveAddr,amount);
  }




}