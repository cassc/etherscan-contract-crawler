// SPDX-License-Identifier: MIT
// Creator: XCart Dev Team

pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract XCartPiecesMint is Ownable, ERC1155Holder {
  using SafeERC20 for IERC20;

  uint256 public constant ID_P1 = 0;
  uint256 public constant ID_P2 = 1;
  uint256 public constant ID_P3 = 2;
  uint256 public constant ID_P4 = 3;
  uint256 public constant ID_P5 = 4;

  uint256[] public IDS = [ID_P1, ID_P2, ID_P3, ID_P4, ID_P5];

  IERC1155 public XCart;
  uint256 public PIECE_PRICE = 0.0188 ether;
  uint256 public MAX_NUMBER = 30;

  address[] private THIS;

  event MultiPiecesMinted(address indexed minter, uint256 amount, address inviter);

  constructor(address _XCart) {
    XCart = IERC1155(_XCart);
    for (uint256 i = 0; i < 5; i++) {
      THIS.push(address(this));
    }
  }

  function setPrice(uint256 price_) external onlyOwner {
    PIECE_PRICE = price_;
  }

  function setMaxNumber(uint256 maxNumber_) external onlyOwner {
    MAX_NUMBER = maxNumber_;
  }

  function mintPiece(uint256 num, address inviter_) public payable {
    num = _mintPiece();
    emit MultiPiecesMinted(msg.sender, num, inviter_);
  }

  function _mintPiece() private returns (uint256 num) {
    num = msg.value / PIECE_PRICE;
    require(tx.origin == msg.sender, 'Contract calls are not allowed');
    require(num > 0, 'Not enough ETH sent: check price.');
    require(num <= MAX_NUMBER, 'Exceeds the maximum number of pieces');
    // check balance
    uint256[] memory balances = XCart.balanceOfBatch(THIS, IDS);
    uint256 total = 0;
    for (uint256 i = 0; i < 5; i++) {
      total += balances[i];
    }
    require(total >= num, 'Pieces not enough to mint');

    uint256 remained = num;
    uint256 random = uint256(keccak256(abi.encode(block.coinbase, block.timestamp, msg.sender, remained, total)));
    uint256 randomStart = random % 5;

    // first random, 0
    total -= balances[randomStart];
    uint256 amount = (random % ((remained * 20) / 5 + 10)) / 10;
    // check if remained balance is enough (min)
    if (total + amount < remained) {
      amount = remained - total;
    }
    if (amount > balances[randomStart]) {
      amount = balances[randomStart];
    }
    if (amount > 0) {
      remained -= amount;
      XCart.safeTransferFrom(address(this), msg.sender, randomStart, amount, '');
    }

    // 1,2,3
    uint256 _i;
    for (_i = 1; _i < 4; _i++) {
      uint256 i = (_i + randomStart) % 5;
      total -= balances[i];
      amount =
        (uint256(
          keccak256(
            abi.encode(
              block.coinbase,
              block.timestamp,
              // block.difficulty,
              msg.sender,
              remained,
              _i
            )
          )
        ) % ((remained * 20) / (5 - _i) + 10)) /
        10;
      // check if remained balance is enough (min)
      if (total + amount < remained) {
        amount = remained - total;
      }
      if (amount > balances[i]) {
        amount = balances[i];
      }
      if (amount > 0) {
        remained -= amount;
        // amounts[i] = amount;
        XCart.safeTransferFrom(address(this), msg.sender, i, amount, '');
        if (remained == 0) {
          break;
        }
      }
    }

    // last one, 4
    if (remained > 0) {
      XCart.safeTransferFrom(address(this), msg.sender, (4 + randomStart) % 5, remained, '');
    }

    _refundIfOver(PIECE_PRICE * num);
  }

  function _refundIfOver(uint256 price_) private {
    if (msg.value > price_) {
      payable(msg.sender).transfer(msg.value - price_);
    }
  }

  function withdrawETH(address payable recipient_) external onlyOwner {
    uint256 balance = address(this).balance;
    (bool success, ) = recipient_.call{ value: balance }('');
    require(success, 'Withdraw successfully');
  }

  function withdrawSafeERC20Token(
    address tokenContract_,
    address payable recipient_,
    uint256 amount_
  ) external onlyOwner {
    IERC20 tokenContract = IERC20(tokenContract_);
    tokenContract.safeTransfer(recipient_, amount_);
  }

  function withdrawXCart(
    uint256[] calldata ids,
    uint256[] calldata amounts,
    address recipient_
  ) external onlyOwner {
    XCart.safeBatchTransferFrom(address(this), recipient_, ids, amounts, '');
  }

  function piecesBalance() external view returns (uint256) {
    uint256[] memory balances = XCart.balanceOfBatch(THIS, IDS);
    uint256 total = 0;
    for (uint256 i = 0; i < 5; i++) {
      total += balances[i];
    }
    return total;
  }

  fallback() external payable {
    address inviter = address(bytes20(msg.data));
    uint256 num = _mintPiece();
    emit MultiPiecesMinted(msg.sender, num, inviter);
  }

  receive() external payable {
    uint256 num = _mintPiece();
    emit MultiPiecesMinted(msg.sender, num, address(0));
  }
}