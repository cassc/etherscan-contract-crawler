// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.17;

import "./interfaces/INorthTreasury.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/token/ERC20/IERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/[email protected]/token/ERC721/IERC721.sol";
import "@openzeppelin/[email protected]/utils/math/Math.sol";

contract NorthCoin is Ownable, ERC20Burnable {
  using SafeERC20 for IERC20;

  uint256 private constant MAX_SUPPLY = 1e9; // 1B
  uint256 private constant FEE_DENOMINATOR = 10000;
  uint256 private constant TIMELOCK = 2 days;

  address private immutable _treasury;
  address private immutable _nft;
  address private immutable _router;
  address private immutable _weth;
  address private immutable _pair;

  mapping (address => bool) private _holding;
  uint256 private _reflections;
  uint256 private _totalStakeShare;
  mapping (address => uint256) private _stakeShares;
  uint256 private _lpUnlockTimestamp;

  uint256 public holders;
  uint256 public variableSellFee;
  uint256 public staked;
  mapping (address => uint256) public stakeUnlockTimestamp;

  event UpdateVariableSellFee(uint256 oldVariableSellFee, uint256 newVariableSellFee);
  event Stake(address account, uint256 stakeUnlockTimestamp);
  event Unstake(address account);
  event UnlockLP(uint256 lpUnlockTimestamp);

  constructor(address treasury, address nft) ERC20("North Coin", "NORTH") {
    _treasury = treasury;
    _nft = nft;
    _router = INorthTreasury(treasury).router();
    IUniswapV2Router02 router = IUniswapV2Router02(_router);
    _weth = router.WETH();
    _pair = IUniswapV2Factory(router.factory()).createPair(address(this), _weth);
    _mint(treasury, 10 ** decimals() * MAX_SUPPLY);
    _updateHolders(treasury);
  }

  function _updateHolders(address account) private {
    if (_holding[account]) {
      if (balanceOf(account) == 0) {
        _holding[account] = false;
        holders--;
      }
    } else if (balanceOf(account) != 0) {
      _holding[account] = true;
      holders++;
    }
  }

  function _transferAndUpdate(address sender, address recipient, uint256 amount) private {
    super._transfer(sender, recipient, amount);
    _updateHolders(sender);
    _updateHolders(recipient);
  }

  function _isStaking(address account) private view returns (bool) {
    return stakeUnlockTimestamp[account] != 0;
  }

  function _stake(address account) private {
    uint256 balance = super.balanceOf(account);
    uint256 stakeShare = _totalStakeShare == 0 ? balance : balance * _totalStakeShare / staked;
    staked += balance;
    _totalStakeShare += stakeShare;
    _stakeShares[account] = stakeShare;
  }

  function _unstake(address account) private {
    uint256 reflection = balanceOf(account) - super.balanceOf(account);

    if (reflection != 0) {
      _reflections -= reflection;
      _transferAndUpdate(address(this), account, reflection);
    }

    staked -= super.balanceOf(account);
    _totalStakeShare -= _stakeShares[account];
    _stakeShares[account] = 0;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal override {
    if (_isStaking(recipient)) {
      _unstake(recipient);
    }

    if (sender != address(this) && sender != _treasury) {
      require(!_isStaking(sender), "NorthCoin::_beforeTokenTransfer: sender is staking");
      uint256 liquidity = super.balanceOf(_pair);
      bool buying;
      uint256 fee;

      if (sender == _pair) { // buying
        if (recipient != address(this)) {
          uint256 newVariableSellFee = variableSellFee - Math.min(FEE_DENOMINATOR * amount / liquidity, variableSellFee); // decrease variable sell fee based on amount vs liquidity

          if (newVariableSellFee != variableSellFee) {
            emit UpdateVariableSellFee(variableSellFee, newVariableSellFee);
            variableSellFee = newVariableSellFee;
          }

          buying = true;
          uint256 balance = IERC721(_nft).balanceOf(recipient);

          if (balance == 0) {
            fee = amount / 20; // 5%
          } else if (balance == 1) {
            fee = amount / 25; // 4%
          } else if (balance == 2) {
            fee = amount * 3 / 100; // 3%
          } else if (balance == 3) {
            fee = amount / 50; // 2%
          } else if (balance == 4) {
            fee = amount / 100; // 1%
          }
        }
      } else if (recipient == _pair) { // selling
        uint256 newVariableSellFee = Math.min(variableSellFee + FEE_DENOMINATOR * amount / liquidity, FEE_DENOMINATOR / 5); // increase variable sell fee based on amount vs liquidity to max. 20%

        if (newVariableSellFee != variableSellFee) {
          emit UpdateVariableSellFee(variableSellFee, newVariableSellFee);
          variableSellFee = newVariableSellFee;
        }

        fee = amount * variableSellFee / FEE_DENOMINATOR;
      }

      if (fee != 0) { // charge fee to keep more Ether in pair (Auto LP)
        amount -= fee;

        if (buying) {
          if (_totalStakeShare != 0) {
            uint256 stakerShare = fee * 3 / 4;

            if (stakerShare != 0) {
              fee -= stakerShare;
              _transferAndUpdate(sender, address(this), stakerShare); // collect 75%
              _reflections += stakerShare; // distribute to stakers (Auto Reflection)
              staked += stakerShare;
            }
          }
        } else {
          uint256 treasuryShare = fee * 3 / 4;

          if (treasuryShare != 0) {
            fee -= treasuryShare;
            _transferAndUpdate(sender, address(this), treasuryShare); // collect 75%
            IUniswapV2Pair pair = IUniswapV2Pair(_pair);
            uint256 requiredLP = pair.totalSupply() * treasuryShare / liquidity;

            // swap to Ether and send to treasury
            if (pair.balanceOf(address(this)) >= requiredLP) {
              pair.transfer(_pair, requiredLP);
              uint256 balance = super.balanceOf(address(this));
              pair.burn(address(this));
              _transferAndUpdate(address(this), _pair, super.balanceOf(address(this)) - balance + treasuryShare);
              pair.sync();
              IERC20 weth = IERC20(_weth);
              weth.safeTransfer(_treasury, weth.balanceOf(address(this)));
            } else { // fallback in case there is not enough LP which, however, should never happen
              _approve(address(this), _router, treasuryShare);
              address[] memory path = new address[](2);
              path[0] = address(this);
              path[1] = _weth;
              IUniswapV2Router02(_router).swapExactTokensForTokens(treasuryShare, 0, path, _treasury, block.timestamp); // tx.origin already takes care of slippage, also does the variable sell fee make frontrunning attacks unprofitable
            }
          }
        }

        _burn(sender, fee); // burn remaining fee (deflationary)
      }
    }

    _transferAndUpdate(sender, recipient, amount);

    if (_isStaking(recipient)) {
      _stake(recipient);
    }
  }

  function balanceOf(address account) public view override returns (uint256) {
    if (account == address(this)) {
      return super.balanceOf(account) - _reflections;
    }

    uint256 stakeShare = _stakeShares[account];
    return stakeShare == 0 ? super.balanceOf(account) : Math.max(staked * stakeShare / _totalStakeShare, super.balanceOf(account));
  }

  function stake() external {
    address sender = _msgSender();
    uint256 unlockTimestamp = stakeUnlockTimestamp[sender];
    require(unlockTimestamp == 0, "NorthCoin::stake: already staking");
    unlockTimestamp = block.timestamp + TIMELOCK;
    stakeUnlockTimestamp[sender] = unlockTimestamp;
    _stake(sender);
    emit Stake(sender, unlockTimestamp);
  }

  function unstake() external {
    address sender = _msgSender();
    uint256 unlockTimestamp = stakeUnlockTimestamp[sender];
    require(unlockTimestamp != 0, "NorthCoin::unstake: not staking");
    require(block.timestamp >= unlockTimestamp, "NorthCoin::unstake: unlock timestamp not reached");
    stakeUnlockTimestamp[sender] = 0;
    _unstake(sender);
    emit Unstake(sender);
  }

  function unlockLP() external onlyOwner {
    _lpUnlockTimestamp = block.timestamp + TIMELOCK;
    emit UnlockLP(_lpUnlockTimestamp);
  }

  function withdrawLP() external onlyOwner {
    require(_lpUnlockTimestamp != 0 && block.timestamp >= _lpUnlockTimestamp, "NorthCoin::withdrawLP: LP is locked");
    IUniswapV2Pair pair = IUniswapV2Pair(_pair);
    uint256 lp = pair.balanceOf(address(this));

    if (lp != 0) {
      pair.transfer(_pair, lp);
      pair.burn(address(this));
    }

    IERC20 weth = IERC20(_weth);
    weth.safeTransfer(_treasury, weth.balanceOf(address(this)));
  }
}