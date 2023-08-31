// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

import "./../interface/celerbridge/IBridge.sol";
import "./../interface/celerbridge/IWithdrawInbox.sol";
import "./../interface/IFeeTierStrate.sol";

contract CbridgeEthPool is ERC20, Ownable {
  mapping (address => bool) public managers;

  address public bridge = 0x5427FEFA711Eff984124bFBB1AB6fbf5E3DA1820;
  address public withdrawInbox = 0xD20fc42E293734f58316E2106933B8D9FB14F5b2;
  address public feeStrate = 0x4d4442Bd5b7a7721794cc98F753BFCB66De590AE;

  uint256 public ratioDec = 100000000;

  struct inboxReq {
    address account;
    uint256 amount;
    uint256 ratio;
  }
  mapping (uint256 => inboxReq) public inboxRequest;
  uint256 public requestIndex = 0;

  event InbxoReq(uint256 index, address account, uint256 amount, uint256 ratio);

  constructor()
    ERC20("CBridgeEthPool_v1", "CBEPv1")
  {
    managers[msg.sender] = true;
  }

  modifier onlyManager() {
    require(managers[msg.sender], "CbridgeEthPool: !manager");
    _;
  }

  receive() external payable {
  }

  function stake() public payable {
    uint256 amount = msg.value;
    (uint256 depositFee, uint256 baseFee) = IFeeTierStrate(feeStrate).getDepositFee();
    uint256 depositFeeAmount = amount * depositFee / baseFee;
    if (depositFeeAmount > 0) {
      amount -= depositFeeAmount;
      _chargeFees(depositFeeAmount);
    }

    IBridge(bridge).addNativeLiquidity{value: amount}(amount);

    _mint(msg.sender, amount);
  }

  function requestInbox(
    uint64 _wdSeq,
    uint64 _toChain,
    uint64[] calldata _fromChains,
    address[] calldata _tokens,
    uint32[] calldata _ratios,
    uint32[] calldata _slippages
  ) public {
    IWithdrawInbox(withdrawInbox).withdraw(_wdSeq, address(this), _toChain, _fromChains, _tokens, _ratios, _slippages);
    uint256 lpAmount = balanceOf(msg.sender);
    lpAmount = lpAmount * _ratios[0] / ratioDec;

    require(lpAmount > 0, "CbridgeEthPool: Too Small");

    inboxRequest[requestIndex] = inboxReq(msg.sender, lpAmount, _ratios[0]);
    emit InbxoReq(requestIndex, msg.sender, lpAmount, _ratios[0]);
    requestIndex ++;
  }

  function unstake(
    uint256 _reqId,
    bytes calldata _wdmsg,
    bytes[] calldata _sigs,
    address[] calldata _signers,
    uint256[] calldata _powers
  ) public {
    IBridge(bridge).withdraw(_wdmsg, _sigs, _signers, _powers);

    uint256 nativeBal = address(this).balance;
    uint256 lpUsed = inboxRequest[_reqId].amount;
    uint256 reward = nativeBal > lpUsed ? 0 : nativeBal - lpUsed;
    if (reward > 0) {
      (uint256 totalFee, uint256 baseFee) = IFeeTierStrate(feeStrate).getTotalFee();
      uint256 feeAmount = reward * totalFee / baseFee;
      if (feeAmount > 0) {
        _chargeFees(feeAmount);
      }
    }

    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "CbridgeEthPool: withdraw");

    _burn(msg.sender, lpUsed);
  }

  function _chargeFees(uint256 _feeAmount) internal {
    uint256[] memory feeIndexs = IFeeTierStrate(feeStrate).getAllTier();
    uint256 len = feeIndexs.length;
    uint256 maxFee = IFeeTierStrate(feeStrate).getMaxFee();
    for (uint256 i=0; i<len; i++) {
      (address feeAccount, ,uint256 fee) = IFeeTierStrate(feeStrate).getTier(feeIndexs[i]);
      uint256 feeAmount = _feeAmount * fee / maxFee;
      if (feeAmount > 0) {
        (bool success, ) = feeAccount.call{value: feeAmount}("");
        require(success, "CbridgeEthPool: send fee");
      }
    }
  }

  function setBridge(address _bridge) public onlyManager {
    bridge = _bridge;
  }

  function setWithdrawInbox(address _withdrawInbox) public onlyManager {
    withdrawInbox = _withdrawInbox;
  }

  function setFeeStrate(address _feeStrate) public onlyManager {
    feeStrate = _feeStrate;
  }
  
  function setManager(address _account, bool _access) public onlyOwner {
    managers[_account] = _access;
  }

  function withdraw() public onlyManager {
    (bool success1, ) = msg.sender.call{value: address(this).balance}("");
    require(success1, "CbridgeEthPool: Failed revoke");
  }

  function withdrawToken(address token) public onlyManager {
    uint256 amount = IERC20(token).balanceOf(address(this));
    IERC20(token).transfer(msg.sender, amount);
  }
}