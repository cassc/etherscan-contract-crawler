// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "TransferHelper.sol";
import "XfaiLibrary.sol";

import "IInfinityNFTPeriphery.sol";
import "IXfaiINFT.sol";
import "IXfaiV0Core.sol";
import "IXfaiFactory.sol";
import "IWETH.sol";

contract InfinityNFTPeriphery is IInfinityNFTPeriphery {
  /**
   * @notice The factory address of xfai
   */
  address private immutable factory;

  /**
   * @notice The old factory address of xfai
   */
  address private immutable optionalOldFactory;

  /**
   * @notice The INFT address of xfai
   */
  address private immutable infinityNFT;

  /**
   * @notice The address of the underlying ERC20 token used for infinity staking / boosting within the INFT contract
   */
  address private immutable xfit;

  /**
   * @notice The address of the xfETH token
   */
  address private immutable xfETH;

  /**
   * @notice The weth address.
   * @dev In the case of a chain ID other than Ethereum, the wrapped ERC20 token address of the chain's native coin
   */
  address private immutable weth;

  /**
   * @notice The XfaiV0Core address of Xfai
   */
  address private immutable core;

  /**
   * @notice The code hash od XfaiPool
   * @dev keccak256(type(XfaiPool).creationCode)
   */
  bytes32 private immutable poolCodeHash;

  modifier ensure(uint deadline) {
    require(deadline >= block.timestamp, 'InfinityNFTPeriphery: EXPIRED');
    _;
  }

  constructor(
    address _factory,
    address _optionalOldFactory,
    address _xfETH,
    address _infinityNFT,
    address _xfit,
    address _weth
  ) {
    factory = _factory;
    optionalOldFactory = _optionalOldFactory;
    core = IXfaiFactory(_factory).getXfaiCore();
    xfETH = _xfETH;
    infinityNFT = _infinityNFT;
    xfit = _xfit;
    weth = _weth;
    poolCodeHash = IXfaiFactory(_factory).poolCodeHash();
  }

  /**
   * @notice Performs one-sided infinity staking and mints in return an INFT. The share of the INFT depends on the amount of underlying tokens staked, and the existing underlying reserve within the INFT contract.
   * @dev This low-level function should be called from a contract which performs important safety checks.
   * This function locks the pool of _token0 and _token1 to prevent reentrancy attacks.
   * This function cannot be called to stake underlying tokens directly. It only accepts ERC20 tokens as _token0 that are hosted on Dexfai and that are not xfit.
   * To stake underlying tokens directly, use the mint function of the INFT contract.
   * @param _token0 An ERC20 token address. Token must have already a pool
   * @param _to The address of the recipient that receives the minted INFT
   * @return share The share value of the minted INFT
   */
  function _infinityStake(address _token0, address _to) private returns (uint share) {
    uint id;
    (, uint amount1Out) = IXfaiV0Core(core).swap(_token0, xfit, optionalOldFactory);
    (id, share) = IXfaiINFT(infinityNFT).mint(_to);
    emit InfinityStake(msg.sender, amount1Out, share, id);
  }

  /**
   * @notice Performs one-sided infinity boosting and increases the share of an already existing INFT. The new share of the INFT depends on the amount of underlying tokens staked, and the existing underlying reserve within the INFT contract.
   * @dev This low-level function should be called from a contract which performs important safety checks.
   * This function locks the pool of _token0 and _token1 to prevent reentrancy attacks.
   * This function cannot be called to boost underlying tokens directly. It only accepts ERC20 tokens as _token0 that are hosted on Dexfai and that are not xfit.
   * To boost an INFt via underlying tokens directly, use the boost function of the INFT contract.
   * @param _id The token ID of the INFT
   * @param _token0 An ERC20 token address. Token must have already a pool
   * @return share The share value added to an INFT
   */
  function _infinityBoost(uint _id, address _token0) private returns (uint share) {
    (, uint amount1Out) = IXfaiV0Core(core).swap(_token0, xfit, optionalOldFactory);
    share = IXfaiINFT(infinityNFT).boost(_id);
    emit InfinityBoost(msg.sender, amount1Out, share, _id);
  }

  // **** Permanent Staking ****
  // requires the initial amount to have already been sent to the first pair

  /**
   * @notice Permanently stake liquidity within Xfai
   * @dev Requires _token0 approval. At the end of the function call, an INFT is minted. The share of witch depends on the exchange value of _amount0In in terms of xfit and the INFT's reserve.
   * @param _to The address of the recipient
   * @param _token0 An ERC20 token address
   * @param _amount0In The amount of _token0 to be permanently staked
   * @param _shareMin The minimal amount of INFT shares that the user will accept for a given _amount0In
   * @param _deadline The UTC timestamp that if reached, causes the transaction to fail automatically
   * @return share The share of the minted INFT
   */
  function permanentStaking(
    address _to,
    address _token0,
    uint _amount0In,
    uint _shareMin,
    uint _deadline
  ) external override ensure(_deadline) returns (uint share) {
    if (_token0 == xfit) {
      TransferHelper.safeTransferFrom(_token0, msg.sender, optionalOldFactory, _amount0In);
      (, share) = IXfaiINFT(infinityNFT).mint(_to);
    } else {
      address pool0 = _token0 == xfETH
        ? XfaiLibrary.poolFor(xfit, factory, poolCodeHash)
        : XfaiLibrary.poolFor(_token0, factory, poolCodeHash);
      TransferHelper.safeTransferFrom(_token0, msg.sender, pool0, _amount0In);
      share = _infinityStake(_token0, _to);
    }
    require(share >= _shareMin, 'InfinityNFTPeriphery: INSUFFICIENT_SHARE');
  }

  /**
   * @notice Permanently stake ether within Xfai
   * @dev At the end of the function call, an INFT is minted. The share of witch depends on the exchange value of _amount0In in terms of xfit and the INFT's reserve.
   * @param _to The address of the recipient
   * @param _shareMin The minimal amount of INFT shares that the user will accept for a given _amount0In
   * @param _deadline The UTC timestamp that if reached, causes the swap transaction to fail automatically
   * @return share The share of the minted INFT
   */
  function permanentStakingEth(
    address _to,
    uint _shareMin,
    uint _deadline
  ) external payable override ensure(_deadline) returns (uint share) {
    address wrappedETH = weth; // gas savings
    uint amount0In = msg.value;
    address pool0 = XfaiLibrary.poolFor(wrappedETH, factory, poolCodeHash);
    IWETH(wrappedETH).deposit{value: amount0In}();
    assert(IWETH(wrappedETH).transfer(pool0, amount0In));
    share = _infinityStake(wrappedETH, _to);
    require(share >= _shareMin, 'InfinityNFTPeriphery: INSUFFICIENT_SHARE');
  }

  // **** Permanent Boosting ****
  // requires the initial amount to have already been sent to the first pair

  /**
   * @notice Permanently stake liquidity within Xfai
   * @dev Requires _token0 approval. At the end of the function call, the share value of an existing INFT is increased. The share of witch depends on the exchange value of _amount0In in terms of xfit and the INFT's reserve.
   * @param _token0 An ERC20 token address
   * @param _amount0In The amount of _token0 to be permanently staked
   * @param _shareMin The minimal amount of INFT shares that the user will accept for a given _amount0In
   * @param _id The token ID of the INFT
   * @param _deadline The UTC timestamp that if reached, causes the swap transaction to fail automatically
   * @return share The new share of the INFT
   */
  function permanentBoosting(
    address _token0,
    uint _amount0In,
    uint _shareMin,
    uint _id,
    uint _deadline
  ) external override ensure(_deadline) returns (uint share) {
    if (_token0 == xfit) {
      TransferHelper.safeTransferFrom(_token0, msg.sender, optionalOldFactory, _amount0In);
      share = IXfaiINFT(infinityNFT).boost(_id);
    } else {
      address pool0 = _token0 == xfETH
        ? XfaiLibrary.poolFor(xfit, factory, poolCodeHash)
        : XfaiLibrary.poolFor(_token0, factory, poolCodeHash);
      TransferHelper.safeTransferFrom(_token0, msg.sender, pool0, _amount0In);
      share = _infinityBoost(_id, _token0);
    }
    require(share >= _shareMin, 'InfinityNFTPeriphery: INSUFFICIENT_SHARE');
  }

  /**
   * @notice Permanently stake liquidity within Xfai
   * @dev Requires _token0 approval. At the end of the function call, the share value of an existing INFT is increased. The share of witch depends on the exchange value of _amount0In in terms of xfit and the INFT's reserve.
   * @param _shareMin The minimal amount of INFT shares that the user will accept for a given amount of ether
   * @param _id The token ID of the INFT
   * @param _deadline The UTC timestamp that if reached, causes the swap transaction to fail automatically
   * @return share The new share of the INFT
   */
  function permanentBoostingEth(
    uint _shareMin,
    uint _id,
    uint _deadline
  ) external payable override ensure(_deadline) returns (uint share) {
    address wrappedETH = weth; // gas savings
    uint amount0In = msg.value;
    address pool0 = XfaiLibrary.poolFor(wrappedETH, factory, poolCodeHash);
    IWETH(wrappedETH).deposit{value: amount0In}();
    assert(IWETH(wrappedETH).transfer(pool0, amount0In));
    share = _infinityBoost(_id, wrappedETH);
    require(share >= _shareMin, 'InfinityNFTPeriphery: INSUFFICIENT_SHARE');
  }
}