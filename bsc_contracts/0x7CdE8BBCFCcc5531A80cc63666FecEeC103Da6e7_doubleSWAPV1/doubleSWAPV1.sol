/**
 *Submitted for verification at BscScan.com on 2023-02-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC20 {
  function decimals() external pure returns (uint8);
  function approve(address spender, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IDEXRouter {
    function WETH() external pure returns (address);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender());
        _;
    }

    function transferOwnership(address account) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, account);
        _owner = account;
    }

}

contract doubleSWAPV1 is Context, Ownable {

  IDEXRouter public router;
  address pcv2 = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
  address busd = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

  IERC20 tokenA;
  IERC20 tokenB;

  mapping(address => bool) public permission;

  modifier onlyPermission() {
    require(permission[msg.sender], "!PERMISSION");
    _;
  }

  constructor() {
    router = IDEXRouter(pcv2);
    permission[msg.sender] = true;
  }

  function flagePermission(address _account,bool _flag) public onlyOwner returns (bool) {
    permission[_account] = _flag;
    return true;
  }

  function processApprove(address token,uint256 amount) public onlyPermission returns (bool) {
    _approval(token,amount);
    return true;
  }

  function DoubleSwap(address[] memory pathBuy,address[] memory pathSell,uint256 amount) public onlyPermission returns (bool) {
    uint256 nextAmount;
    tokenA = IERC20(pathBuy[0]);
    tokenB = IERC20(pathSell[0]);
    tokenA.transferFrom(msg.sender,address(this),amount);
    _swap(amount,pathBuy,address(this));
    nextAmount = tokenB.balanceOf(address(this));
    _swap(nextAmount,pathSell,msg.sender);
    return true;
  }



  function _randomInt(uint256 _mod,address addrs1,address addrs2) internal view returns (uint256) {
    uint256 randomNum = uint256(
      keccak256(abi.encodePacked(block.timestamp,addrs1,addrs2))
    );
    return randomNum % _mod;
  }

  function _approval(address token,uint256 amount) internal {
    IERC20(token).approve(pcv2,amount);
  }

  function _swap(uint256 amountIn,address[] memory path,address to) internal {
    router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
    amountIn,
    0,
    path,
    to,
    block.timestamp
    );
  }

  function rescue(address adr) external onlyOwner {
    IERC20 a = IERC20(adr);
    a.transfer(msg.sender,a.balanceOf(address(this)));
  }

  function purge() external onlyOwner {
    (bool success,) = msg.sender.call{ value: address(this).balance }("");
    require(success, "Failed to send ETH");
  }
  
  receive() external payable { }
}