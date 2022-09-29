//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../CopycatDepositer.sol";
import "../CopycatLeader.sol";
import "../lib/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IAxelarExecutable} from "@axelar-network/axelar-cgp-solidity/src/interfaces/IAxelarExecutable.sol";
import {IAxelarGasReceiver} from "@axelar-network/axelar-cgp-solidity/src/interfaces/IAxelarGasReceiver.sol";

interface IRangoMessageReceiver {
  enum ProcessStatus { SUCCESS, REFUND_IN_SOURCE, REFUND_IN_DESTINATION }

  function handleRangoMessage(
    IERC20 _token,
    uint _amount,
    ProcessStatus _status,
    bytes memory _message
  ) external;
}

contract CopycatRangoCrossDeposit is IRangoMessageReceiver, Ownable {
  using SafeERC20 for IERC20;

  address payable public rangoContract;
  CopycatDepositer public copycatDepositer;
  IWETH public weth;

  constructor(address payable _rangoContract, CopycatDepositer _copycatDepositer, IWETH _weth) {
    rangoContract = _rangoContract;
    copycatDepositer = _copycatDepositer;
    weth = _weth;
  }

  // Rango don't need sibling as it is handled in their backend

  receive() external payable { }

  mapping(address => bool) public whitelistedRelayer;

  event WhitelistedRelayer(address indexed relayer, bool whitelisted);
  function whitelistRelayer(address relayer, bool whitelisted) public onlyOwner {
    whitelistedRelayer[relayer] = whitelisted;
    emit WhitelistedRelayer(relayer, whitelisted);
  }

  function bridgeWithToken(uint256 chainId, bytes calldata rangoData, IERC20 token, uint256 amount) internal {
    // Approve rango
    token.safeTransferFrom(msg.sender, address(this), amount);
    token.safeApprove(rangoContract, 0);
    token.safeApprove(rangoContract, amount);

    // Send the money via Rango
    (bool success, bytes memory retData) = rangoContract.call{value: msg.value}(rangoData);
    if (!success) revert(_getRevertMsg(retData));
  }

  function handleRangoMessage(
    IERC20 token,
    uint amount,
    ProcessStatus status,
    bytes memory payload
  ) external {
    require(whitelistedRelayer[msg.sender], "Not Whitelisted");

    (address buyer, address payable leader, uint256 percentage, uint256 finalPercentage, uint256 minShare) = abi.decode(payload, (address, address, uint256, uint256, uint256));

    if (status == ProcessStatus.REFUND_IN_SOURCE || status == ProcessStatus.REFUND_IN_DESTINATION) {
      refundTo(buyer, token, amount);
    } else {
      if (address(token) == address(0)) {
        copycatDepositer.buy{value: amount}(buyer, CopycatLeader(leader), percentage, finalPercentage, minShare);
      } else {
        token.safeApprove(address(copycatDepositer), 0);
        token.safeApprove(address(copycatDepositer), amount);
        copycatDepositer.buyOtherToken(buyer, CopycatLeader(leader), token, amount, percentage, finalPercentage, minShare);
      }
    }
  }

  // Refund mechanism
  function refundTo(address _to, IERC20 _token, uint256 _amount) internal {
    if (address(_token) == address(0)) {
      refundNativeTo(payable(_to), _amount);
    } else {
      IERC20(_token).safeTransfer(_to, _amount);
    }
  }

  function refundNativeTo(address payable _to, uint256 _amount) internal {
    bool success;

    assembly {
      // Transfer the ETH and store if it succeeded or not.
      success := call(gas(), _to, _amount, 0, 0, 0, 0)
    }

    require(success, "ETH_TRANSFER_FAILED");
  }

  function recoverETH() external onlyOwner {
    uint256 amount = address(this).balance;
    bool success;

    assembly {
      // Transfer the ETH and store if it succeeded or not.
      success := call(gas(), caller(), amount, 0, 0, 0, 0)
    }

    require(success, "ETH_TRANSFER_FAILED");
  }

  function recoverERC20(IERC20 token) external onlyOwner {
    token.safeTransfer(msg.sender, token.balanceOf(address(this)));
  }

  function recoverERC721(IERC721 token, uint256 tokenId, bytes calldata data) external onlyOwner {
    token.safeTransferFrom(address(this), msg.sender, tokenId, data);
  }

  function recoverERC1155(IERC1155 token, uint256 tokenId, uint256 amount, bytes calldata data) external onlyOwner {
    token.safeTransferFrom(address(this), msg.sender, tokenId, amount, data);
  }

  function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
    // If the _res length is less than 68, then the transaction failed silently (without a revert message)
    if (_returnData.length < 68) return "Transaction reverted silently";

    assembly {
      // Slice the sighash.
      _returnData := add(_returnData, 0x04)
    }
    return abi.decode(_returnData, (string)); // All that remains is the revert string
  }
}