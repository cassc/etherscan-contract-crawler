// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@prb/math/contracts/PRBMathUD60x18.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTRoyaltySplitter is ReentrancyGuard, Ownable {
  using PRBMathUD60x18 for uint256;

  event PaymentReleased(address to, uint256 amount);
  event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
  event PaymentReceived(address from, uint256 amount);

  uint256 private _totalEthClaimed;
  uint256 public MAX_SUPPLY;

  IERC721 public nft;

  mapping(uint256 => uint256) private _rewardDebt;
  mapping(address => mapping(uint256 => uint256)) private _erc20RewardDebt;
  mapping(address => uint256) private _erc20TotalClaimed;

  constructor(uint256 maxSupply, IERC721 contractAddr) {
    nft = contractAddr;
    MAX_SUPPLY = maxSupply;
  }

  /**
   * @dev Public function that can be used to calculate the pending ETH payment for a given NFT ID
   */
  function calculatePendingPayment(uint256 nftId)
    public
    view
    returns (uint256)
  {
    return
      (address(this).balance + _totalEthClaimed - _rewardDebt[nftId]).div(
        MAX_SUPPLY * 10**18
      );
  }

  /**
   * @dev Public function that can be used to calculate the pending ERC20 payment for a given NFT ID
   */
  function calculatePendingPayment(IERC20 erc20, uint256 nftId)
    public
    nonReentrant
    returns (uint256)
  {
    return
      (erc20.balanceOf(address(this)) +
        _erc20TotalClaimed[address(erc20)] -
        _erc20RewardDebt[address(erc20)][nftId]).div(MAX_SUPPLY * 10**18);
  }

  /**
   * @dev Internal function to claim ETH for a given NFT ID
   */
  function _claim(uint256 nftId) private {
    uint256 payment = calculatePendingPayment(nftId);
    require(payment > 0, "Nothing to claim");
    uint256 preBalance = address(this).balance;
    _rewardDebt[nftId] += preBalance;
    _totalEthClaimed += payment;
    address ownerAddr = nft.ownerOf(nftId);
    Address.sendValue(payable(ownerAddr), payment);
    emit PaymentReleased(ownerAddr, payment);
  }

  /**
   * @dev Public function to claim ETH for a given NFT ID.
   */
  function claim(uint256 nftId) public nonReentrant {
    _claim(nftId);
  }

  /**
   * @dev Internal function to claim ERC20 token for a given NFT ID
   */
  function _claim(IERC20 erc20, uint256 nftId) private {
    uint256 payment = calculatePendingPayment(erc20, nftId);
    require(payment > 0, "Nothing to claim");
    uint256 preBalance = erc20.balanceOf(address(this));
    _erc20RewardDebt[address(erc20)][nftId] += preBalance;
    _erc20TotalClaimed[address(erc20)] += payment;
    address ownerAddr = nft.ownerOf(nftId);
    erc20.transfer(ownerAddr, payment);
    emit ERC20PaymentReleased(erc20, ownerAddr, payment);
  }

  /**
   * @dev Public function to claim ERC20 token for a given NFT ID
   */
  function claim(IERC20 erc20, uint256 nftId) public nonReentrant {
    _claim(erc20, nftId);
  }

  /**
   * @dev Public function to claim ETH for a list of NFT IDs
   */
  function claimMany(uint256[] memory nftIds) public nonReentrant {
    for (uint256 i = 0; i < nftIds.length; i++) {
      _claim(nftIds[i]);
    }
  }

  /**
   * @dev Public function to claim ERC20 tokens for a list of NFT IDs
   */
  function claimMany(IERC20 erc20, uint256[] memory nftIds) public {
    for (uint256 i = 0; i < nftIds.length; i++) {
      _claim(erc20, nftIds[i]);
    }
  }

  /**
   * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
   * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
   * reliability of the events, and not the actual splitting of Ether.
   *
   * To learn more about this see the Solidity documentation for
   * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
   * functions].
   */
  receive() external payable virtual {
    emit PaymentReceived(_msgSender(), msg.value);
  }

  /**
   * @dev Function to send arbitrary data
   */
  function message(bytes calldata data) public onlyOwner {}
}