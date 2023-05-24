// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IWETH.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/utils/cryptography/ECDSA.sol";
import "@openzeppelin/[email protected]/utils/math/Math.sol";

contract AirdropPepe is Ownable, ERC20Burnable {
  using ECDSA for bytes32;

  uint256 private constant MAX_SUPPLY = 1e18 * 42069e10; // 420,690,000,000,000
  uint256 private constant HALF_SUPPLY = MAX_SUPPLY / 2; // half for airdrop, other half for liquidity
  address private constant SIGNER = 0xe1cF960437d2fA4f4D857493249de23635a1A51E;
  address private constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

  address private immutable _weth;
  address private immutable _pair;

  mapping (address => bool) private _holding;

  uint256 public holders = 1; // token itself initially holds the max. supply
  mapping (address => bool) public claimedAirdrop;

  constructor() ERC20("Airdrop Pepe", "AIRPEPE") {
    IUniswapV2Router02 router = IUniswapV2Router02(ROUTER);
    address weth = router.WETH();
    _weth = weth;
    address token = address(this);
    address pair = IUniswapV2Factory(router.factory()).createPair(token, weth);
    _pair = pair;
    _mint(token, MAX_SUPPLY);
    _holding[token] = true;
  }

  function _transfer(address from, address to, uint256 amount) internal override {
    require(to == _pair || owner() == address(0), "AirdropPepe::_transfer: not launched");
    super._transfer(from, to, amount);

    if (amount != 0) { // the sender was a holder and the recipient is a potential new holder
      // use these local variables for gas savings
      bool removeHolder;
      bool addHolder;

      if (balanceOf(from) == 0) {
        _holding[from] = false;
        removeHolder = true;
      }

      if (!_holding[to]) {
        _holding[to] = true;
        addHolder = true;
      }

      unchecked {
        if (removeHolder) {
          if (!addHolder) {
            holders--;
          }
        } else if (addHolder) {
          holders++;
        }
      }
    }
  }

  function addLiquidity(bool launch) external payable onlyOwner {
    uint256 liquidity = msg.value;

    if (liquidity != 0) {
      address weth = _weth;
      IWETH wethContract = IWETH(weth);
      wethContract.deposit{ value: msg.value }();
      address pair = _pair;
      wethContract.transfer(pair, msg.value);

      if (balanceOf(pair) == 0) {
        _transfer(address(this), pair, HALF_SUPPLY);
        IUniswapV2Pair(pair).mint(address(0)); // burn LP
      } else {
        (uint256 amount0Out, uint256 amount1Out) = address(this) < weth ? (1, 0) : (0, 1);
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, pair, new bytes(0));
      }
    }

    if (launch) {
      renounceOwnership();
    }
  }

  function claimAirdrop(uint256 points, uint256 totalPoints, bytes memory signature) external {
    address token = address(this);
    address sender = _msgSender();
    require(keccak256(abi.encode(block.chainid, token, sender, points, totalPoints)).toEthSignedMessageHash().recover(signature) == SIGNER, "AirdropPepe::claimAirdrop: invalid signature");
    require(!claimedAirdrop[sender], "AirdropPepe::claimAirdrop: already claimed");
    claimedAirdrop[sender] = true;
    uint256 amount;

    unchecked {
      amount = HALF_SUPPLY * points / totalPoints;
    }

    _transfer(token, sender, Math.min(amount, balanceOf(token)));
  }
}