pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./helpers/TransferHelper.sol";

contract Airdrop is Ownable {
  using Address for address;
  using SafeMath for uint256;

  struct AirdropItem {
    address to;
    uint256 amount;
  }

  uint256 public fee;

  constructor(uint256 _fee) {
    fee = _fee;
  }

  function setFee(uint256 _fee) external onlyOwner {
    fee = _fee;
  }

  function drop(address token, AirdropItem[] memory airdropItems) external payable {
    require(token.isContract(), "must_be_contract_address");
    require(msg.value >= fee, "fee");

    uint256 totalSent;

    for (uint256 i = 0; i < airdropItems.length; i++) totalSent = totalSent.add(airdropItems[i].amount);

    require(IERC20(token).allowance(_msgSender(), address(this)) >= totalSent, "not_enough_allowance");

    for (uint256 i = 0; i < airdropItems.length; i++) {
      TransferHelpers._safeTransferFromERC20(token, _msgSender(), airdropItems[i].to, airdropItems[i].amount);
    }
  }

  function retrieveEther(address to) external onlyOwner {
    TransferHelpers._safeTransferEther(to, address(this).balance);
  }

  function retrieveERC20(
    address token,
    address to,
    uint256 amount
  ) external onlyOwner {
    TransferHelpers._safeTransferERC20(token, to, amount);
  }

  receive() external payable {}
}