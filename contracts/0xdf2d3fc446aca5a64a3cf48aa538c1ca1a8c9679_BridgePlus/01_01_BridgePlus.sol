// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);
}

interface IWETH is IERC20 {
  function deposit() external payable;
  function withdraw(uint amount) external;
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }
  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    _transferOwnership(_msgSender());
  }

  modifier onlyOwner() {
    _checkOwner();
    _;
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  function _checkOwner() internal view virtual {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
  }

  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

library Address {
  function isContract(address account) internal view returns (bool) {
    return account.code.length > 0;
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    (bool success, ) = recipient.call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCallWithValue(target, data, 0, "Address: low-level call failed");
  }

  function functionCall(
      address target,
      bytes memory data,
      string memory errorMessage
  ) internal returns (bytes memory) {
      return functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(
      address target,
      bytes memory data,
      uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, "Address: low-level static call failed");
  }

  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, "Address: low-level delegate call failed");
  }

  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  function verifyCallResultFromTarget(
    address target,
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    if (success) {
      if (returndata.length == 0) {
        require(isContract(target), "Address: call to non-contract");
      }
      return returndata;
    } else {
      _revert(returndata, errorMessage);
    }
  }

  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      _revert(returndata, errorMessage);
    }
  }

  function _revert(bytes memory returndata, string memory errorMessage) private pure {
    if (returndata.length > 0) {
      assembly {
        let returndata_size := mload(returndata)
        revert(add(32, returndata), returndata_size)
      }
    } else {
      revert(errorMessage);
    }
  }
}

interface IERC20Permit {
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
  function nonces(address owner) external view returns (uint256);
  function DOMAIN_SEPARATOR() external view returns (bytes32);
}

library SafeERC20 {
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    unchecked {
      uint256 oldAllowance = token.allowance(address(this), spender);
      require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
      uint256 newAllowance = oldAllowance - value;
      _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
  }

  function safePermit(
    IERC20Permit token,
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal {
    uint256 nonceBefore = token.nonces(owner);
    token.permit(owner, spender, value, deadline, v, r, s);
    uint256 nonceAfter = token.nonces(owner);
    require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}

interface ISwapPlusv1 {
  struct swapRouter {
    string platform;
    address tokenIn;
    address tokenOut;
    uint256 amountOutMin;
    uint256 meta; // fee, flag(stable), 0=v2
    uint256 percent;
  }
  struct swapLine {
    swapRouter[] swaps;
  }
  struct swapBlock {
    swapLine[] lines;
  }

  function swap(address tokenIn, uint256 amount, address tokenOut, address recipient, swapBlock[] calldata swBlocks) external payable returns(uint256, uint256);
}

interface ILCBridgev2 {
  function swap(address _to, address _refund, uint256 _outChainID) external payable returns(uint256);
  function redeem(address account, uint256 amount, uint256 srcChainId, uint256 _swapIndex, uint256 operatorFee) external returns(uint256);
  function refund(uint256 _index, uint256 _fee) external returns(uint256);
}

interface IBridge {
  function addNativeLiquidity(uint256 _amount)
    external payable;
  
  function send(
    address _receiver,
    address _token,
    uint256 _amount,
    uint64 _dstChainId,
    uint64 _nonce,
    uint32 _maxSlippage // slippage * 1M, eg. 0.5% -> 5000
  ) external;

  function sendNative(
    address _receiver,
    uint256 _amount,
    uint64 _dstChainId,
    uint64 _nonce,
    uint32 _maxSlippage
  ) external payable;

  function withdraw(
    bytes calldata _wdmsg,
    bytes[] calldata _sigs,
    address[] calldata _signers,
    uint256[] calldata _powers
  ) external;
}

interface IStargateRouter {
  struct lzTxObj {
    uint256 dstGasForCall;
    uint256 dstNativeAmount;
    bytes dstNativeAddr;
  }

  function addLiquidity(uint256 _poolId, uint256 _amountLD, address to) external payable;
  function instantRedeemLocal(uint16 _srcPoolId, uint256 _amountLD, address to) external payable;

  function swap(
    uint16 _dstChainId,
    uint256 _srcPoolId,
    uint256 _dstPoolId,
    address payable _refundAddress,
    uint256 _amountLD,
    uint256 _minAmountLD,
    lzTxObj memory _lzTxParams,
    bytes calldata _to,
    bytes calldata _payload
  ) external payable;

  function quoteLayerZeroFee(
    uint16 _dstChainId,
    uint8 _functionType,
    bytes calldata _toAddress,
    bytes calldata _transferAndCallPayload,
    lzTxObj memory _lzTxParams
  ) external view returns (uint256, uint256);
}

contract BridgePlus is Ownable {
  using SafeERC20 for IERC20;

  uint256 public chainId;
  address public WETH;
  address public treasury;
  address public swapRouter;
  uint256 public swapFee = 3000;
  uint256 public coreDecimal = 1000000;
  uint256 public stargateSwapFeeMultipler = 1400000;
  uint256 public stargateSwapFeeDivider = 1000000;

  mapping (address => bool) public noFeeWallets;
  mapping (address => bool) public managers;

  struct Operator {
    address bridge;
    address inToken;
    address token;
    uint256 amount;
    address dstAddress;
    address receiver;
    address refund;
    uint256 desChainId;
    address dstToken;
    address receiveToken;
    uint256 bridgeType;
    uint256 basketId;
  }

  struct swapPath {
    ISwapPlusv1.swapBlock[] path;
  }

  event BridgePlusFee(address token, uint256 fee, address treasury);
  event BridgePlusSwap(address dstAddress, address receiver, uint256 srcChainId, address srcToken, uint256 amount, uint256 dstChainId, address dstToken, address receiveToken, uint256 bridgeType, uint256 basketId);

  constructor(
    uint256 _chainId,
    address _swapRouter,
    address _WETH,
    address _treasury
  ) {
    require(_swapRouter != address(0), "BridgePlus: swap router");
    require(_WETH != address(0), "BridgePlus: WETH");
    require(_treasury != address(0), "BridgePlus: Treasury");

    chainId = _chainId;
    swapRouter = _swapRouter;
    WETH = _WETH;
    treasury = _treasury;
    managers[msg.sender] = true;
  }

  modifier onlyManager() {
    require(managers[msg.sender], "BridgePlus: !manager");
    _;
  }

  receive() external payable {
  }

  function swap(Operator calldata info, swapPath calldata paths, uint256[] calldata metadata) public payable {
    uint256 amount = info.amount;
    if (info.inToken != address(0)) {
      IERC20(info.inToken).safeTransferFrom(msg.sender, address(this), info.amount);
    }
    else if (info.bridgeType == 2) {
      uint256 fee = getStgSwapFee(info.bridge, uint16(info.desChainId));
      amount -= fee;
    }
    if (noFeeWallets[msg.sender] == false && info.bridgeType != 0) {
      amount = _cutFee(info.inToken, amount);
    }
    
    if (paths.path.length > 0) {
      address tokenI = info.inToken;
      address tokenO = info.token == address(0) ? WETH : info.token;
      if (tokenI == address(0)) {
        tokenI = WETH;
        IWETH(WETH).deposit{value: amount}();
      }
      _approveTokenIfNeeded(tokenI, swapRouter, amount);
      (, amount) = ISwapPlusv1(swapRouter).swap(tokenI, amount, tokenO, address(this), paths.path);

      if (info.token == address(0)) {
        IWETH(WETH).withdraw(amount);
      }
    }

    if (info.bridgeType == 0) { // LC bridge
      if (info.token != address(0)) {
        IWETH(WETH).withdraw(amount);
      }
      ILCBridgev2(info.bridge).swap{value: amount}(info.dstAddress, info.refund, info.desChainId);
    }
    else {
      _approveTokenIfNeeded(info.token, info.bridge, amount);
      if (info.bridgeType == 1) { // CBridge
        uint64 nonce = uint64(block.timestamp);
        IBridge(info.bridge).send(info.dstAddress, info.token, amount, uint64(info.desChainId), nonce, 1000000);
      }
      else if (info.bridgeType == 2) { // Stargate
        uint256 fee = getStgSwapFee(info.bridge, uint16(info.desChainId));
        IStargateRouter(info.bridge).swap{value: fee}(
          uint16(info.desChainId),
          metadata[0],
          metadata[1],
          payable(msg.sender),
          amount,
          0,
          IStargateRouter.lzTxObj(0, 0, "0x"),
          abi.encodePacked(info.dstAddress),
          bytes("")
        );
      }
    }

    emit BridgePlusSwap(info.dstAddress, info.receiver, chainId, info.token, amount, info.desChainId, info.dstToken, info.receiveToken, info.bridgeType, info.basketId);
  }

  function redeem(address bridge, address receiver, address tokenO, address tokenR, uint256 amount, uint256 bridgeType, swapPath[2] calldata paths, uint256[] memory metadata) public payable onlyManager returns(uint256) {
    if (bridgeType == 0) { // LC bridge
      amount = ILCBridgev2(bridge).redeem(address(this), amount, metadata[0], metadata[1], metadata[2]);
      if (metadata[2] > 0) {
        (bool success, ) = payable(msg.sender).call{value: metadata[2]}("");
        require(success, "BridgePlus: Failed refund oeprator fee");
      }
    }

    if (metadata[3] > 0) { // operator fee
      amount -= metadata[3];
      if (paths[1].path.length > 0) {
        _approveTokenIfNeeded(tokenO, swapRouter, metadata[3]);
        (, metadata[3]) = ISwapPlusv1(swapRouter).swap(tokenO, metadata[3], WETH, address(this), paths[1].path);
      }
      if (tokenO != address(0)) {
        IWETH(WETH).withdraw(metadata[3]);
      }
      (bool success, ) = payable(msg.sender).call{value: metadata[3]}("");
      require(success, "BridgePlus: Failed operator fee");
    }

    if (paths[0].path.length > 0) {
      address tokenI = tokenO;
      address tokenSO = tokenR == address(0) ? WETH : tokenR;
      if (tokenI == address(0)) {
        tokenI = WETH;
        IWETH(WETH).deposit{value: amount}();
      }
      _approveTokenIfNeeded(tokenI, swapRouter, amount);
      (, amount) = ISwapPlusv1(swapRouter).swap(tokenI, amount, tokenSO, address(this), paths[0].path);
    }

    if (tokenR == address(0)) {
      if (tokenO != address(0)) {
        IWETH(WETH).withdraw(amount);
      }
      (bool success, ) = payable(receiver).call{value: amount}("");
      require(success, "BridgePlus: Failed redeem");
    }
    else {
      IERC20(tokenR).safeTransfer(receiver, amount);
    }
    return amount;
  }

  function refundCbridge(
    address cbridge,
    bytes calldata _wdmsg,
    bytes[] calldata _sigs,
    address[] calldata _signers,
    uint256[] calldata _powers,
    address account,
    address _token
  ) public {
    IBridge(cbridge).withdraw(_wdmsg, _sigs, _signers, _powers);

    if (_token == address(0)) {
      (bool success, ) = payable(account).call{value: address(this).balance}("");
      require(success, "BridgePlus: refund cbrdige");
    }
    else {
      IERC20(_token).safeTransfer(account, IERC20(_token).balanceOf(address(this)));
    }
  }

  function getStgSwapFee(address bridge, uint16 _desChain) public view returns(uint256) {
    (uint256 swFee, ) = IStargateRouter(bridge).quoteLayerZeroFee(
      _desChain,
      1,
      bytes("0x"),
      bytes("0x"),
      IStargateRouter.lzTxObj(0, 0, "0x")
    );
    return swFee * stargateSwapFeeMultipler / stargateSwapFeeDivider;
  }

  function setManager(address account, bool access) public onlyOwner {
    managers[account] = access;
  }

  function setNoFeeWallets(address account, bool access) public onlyManager {
    noFeeWallets[account] = access;
  }

  function setSwapFee(uint256 _swapFee) public onlyManager {
    swapFee = _swapFee;
  }

  function setTreasury(address _treasury) public onlyManager {
    treasury = _treasury;
  }

  function _approveTokenIfNeeded(address token, address spender, uint256 amount) private {
    if (IERC20(token).allowance(address(this), spender) < amount) {
      IERC20(token).safeApprove(spender, 0);
      IERC20(token).safeApprove(spender, type(uint256).max);
    }
  }

  function _cutFee(address _token, uint256 _amount) internal returns(uint256) {
    if (_amount > 0) {
      uint256 fee = _amount * swapFee / coreDecimal;
      if (fee > 0) {
        if (_token == address(0)) {
          (bool success, ) = payable(treasury).call{value: fee}("");
          require(success, "BridgePlus: Failed cut fee");
        }
        else {
          IERC20(_token).safeTransfer(treasury, fee);
        }
        emit BridgePlusFee(_token, fee, treasury);
      }
      return _amount - fee;
    }
    return 0;
  }
}