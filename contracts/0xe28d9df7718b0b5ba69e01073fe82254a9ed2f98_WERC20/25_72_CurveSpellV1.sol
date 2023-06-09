pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';

import './BasicSpell.sol';
import '../utils/HomoraMath.sol';
import '../../interfaces/ICurvePool.sol';
import '../../interfaces/ICurveRegistry.sol';
import '../../interfaces/IWLiquidityGauge.sol';
import '../../interfaces/IWERC20.sol';

contract CurveSpellV1 is BasicSpell {
  using SafeMath for uint;
  using HomoraMath for uint;

  ICurveRegistry public immutable registry;
  IWLiquidityGauge public immutable wgauge;
  address public immutable crv;
  mapping(address => address[]) public ulTokens; // lpToken -> underlying token array
  mapping(address => address) public poolOf; // lpToken -> pool

  constructor(
    IBank _bank,
    address _werc20,
    address _weth,
    address _wgauge
  ) public BasicSpell(_bank, _werc20, _weth) {
    wgauge = IWLiquidityGauge(_wgauge);
    IWLiquidityGauge(_wgauge).setApprovalForAll(address(_bank), true);
    registry = IWLiquidityGauge(_wgauge).registry();
    crv = address(IWLiquidityGauge(_wgauge).crv());
  }

  /// @dev Return pool address given LP token and update pool info if not exist.
  /// @param lp LP token to find the corresponding pool.
  function getPool(address lp) public returns (address) {
    address pool = poolOf[lp];
    if (pool == address(0)) {
      require(lp != address(0), 'no lp token');
      pool = registry.get_pool_from_lp_token(lp);
      require(pool != address(0), 'no corresponding pool for lp token');
      poolOf[lp] = pool;
      uint n = registry.get_n_coins(pool);
      address[8] memory tokens = registry.get_coins(pool);
      ulTokens[lp] = new address[](n);
      for (uint i = 0; i < n; i++) {
        ulTokens[lp][i] = tokens[i];
      }
    }
    return pool;
  }

  function ensureApproveN(address lp, uint n) public {
    require(ulTokens[lp].length == n, 'incorrect pool length');
    address pool = poolOf[lp];
    address[] memory tokens = ulTokens[lp];
    for (uint idx = 0; idx < n; idx++) {
      ensureApprove(tokens[idx], pool);
    }
  }

  /// @dev add liquidity for pools with 2 underlying tokens
  function addLiquidity2(
    address lp,
    uint[2] calldata amtsUser,
    uint amtLPUser,
    uint[2] calldata amtsBorrow,
    uint amtLPBorrow,
    uint minLPMint,
    uint pid,
    uint gid
  ) external payable {
    address pool = getPool(lp);
    require(ulTokens[lp].length == 2, 'incorrect pool length');
    require(wgauge.getUnderlyingToken(wgauge.encodeId(pid, gid, 0)) == lp, 'incorrect underlying');
    address[] memory tokens = ulTokens[lp];

    // 0. Take out collateral
    uint positionId = bank.POSITION_ID();
    (, , uint collId, uint collSize) = bank.getPositionInfo(positionId);
    if (collSize > 0) {
      (uint decodedPid, uint decodedGid, ) = wgauge.decodeId(collId);
      require(decodedPid == pid && decodedGid == gid, 'incorrect coll id');
      bank.takeCollateral(address(wgauge), collId, collSize);
      wgauge.burn(collId, collSize);
    }

    // 1. Ensure approve 2 underlying tokens
    ensureApproveN(lp, 2);

    // 2. Get user input amounts
    for (uint i = 0; i < 2; i++) doTransmit(tokens[i], amtsUser[i]);
    doTransmit(lp, amtLPUser);

    // 3. Borrow specified amounts
    for (uint i = 0; i < 2; i++) doBorrow(tokens[i], amtsBorrow[i]);
    doBorrow(lp, amtLPBorrow);

    // 4. add liquidity
    uint[2] memory suppliedAmts;
    for (uint i = 0; i < 2; i++) {
      suppliedAmts[i] = IERC20(tokens[i]).balanceOf(address(this));
    }
    ICurvePool(pool).add_liquidity(suppliedAmts, minLPMint);

    // 5. Put collateral
    uint amount = IERC20(lp).balanceOf(address(this));
    ensureApprove(lp, address(wgauge));
    uint id = wgauge.mint(pid, gid, amount);
    bank.putCollateral(address(wgauge), id, amount);

    // 6. Refund
    for (uint i = 0; i < 2; i++) doRefund(tokens[i]);

    // 7. Refund crv
    doRefund(crv);
  }

  /// @dev add liquidity for pools with 3 underlying tokens
  function addLiquidity3(
    address lp,
    uint[3] calldata amtsUser,
    uint amtLPUser,
    uint[3] calldata amtsBorrow,
    uint amtLPBorrow,
    uint minLPMint,
    uint pid,
    uint gid
  ) external payable {
    address pool = getPool(lp);
    require(ulTokens[lp].length == 3, 'incorrect pool length');
    require(wgauge.getUnderlyingToken(wgauge.encodeId(pid, gid, 0)) == lp, 'incorrect underlying');
    address[] memory tokens = ulTokens[lp];

    // 0. take out collateral
    uint positionId = bank.POSITION_ID();
    (, , uint collId, uint collSize) = bank.getPositionInfo(positionId);
    if (collSize > 0) {
      (uint decodedPid, uint decodedGid, ) = wgauge.decodeId(collId);
      require(decodedPid == pid && decodedGid == gid, 'incorrect coll id');
      bank.takeCollateral(address(wgauge), collId, collSize);
      wgauge.burn(collId, collSize);
    }

    // 1. Ensure approve 3 underlying tokens
    ensureApproveN(lp, 3);

    // 2. Get user input amounts
    for (uint i = 0; i < 3; i++) doTransmit(tokens[i], amtsUser[i]);
    doTransmit(lp, amtLPUser);

    // 3. Borrow specified amounts
    for (uint i = 0; i < 3; i++) doBorrow(tokens[i], amtsBorrow[i]);
    doBorrow(lp, amtLPBorrow);

    // 4. add liquidity
    uint[3] memory suppliedAmts;
    for (uint i = 0; i < 3; i++) {
      suppliedAmts[i] = IERC20(tokens[i]).balanceOf(address(this));
    }
    ICurvePool(pool).add_liquidity(suppliedAmts, minLPMint);

    // 5. put collateral
    uint amount = IERC20(lp).balanceOf(address(this));
    ensureApprove(lp, address(wgauge));
    uint id = wgauge.mint(pid, gid, amount);
    bank.putCollateral(address(wgauge), id, amount);

    // 6. Refund
    for (uint i = 0; i < 3; i++) doRefund(tokens[i]);

    // 7. Refund crv
    doRefund(crv);
  }

  /// @dev add liquidity for pools with 4 underlying tokens
  function addLiquidity4(
    address lp,
    uint[4] calldata amtsUser,
    uint amtLPUser,
    uint[4] calldata amtsBorrow,
    uint amtLPBorrow,
    uint minLPMint,
    uint pid,
    uint gid
  ) external payable {
    address pool = getPool(lp);
    require(ulTokens[lp].length == 4, 'incorrect pool length');
    require(wgauge.getUnderlyingToken(wgauge.encodeId(pid, gid, 0)) == lp, 'incorrect underlying');
    address[] memory tokens = ulTokens[lp];

    // 0. Take out collateral
    uint positionId = bank.POSITION_ID();
    (, , uint collId, uint collSize) = bank.getPositionInfo(positionId);
    if (collSize > 0) {
      (uint decodedPid, uint decodedGid, ) = wgauge.decodeId(collId);
      require(decodedPid == pid && decodedGid == gid, 'incorrect coll id');
      bank.takeCollateral(address(wgauge), collId, collSize);
      wgauge.burn(collId, collSize);
    }

    // 1. Ensure approve 4 underlying tokens
    ensureApproveN(lp, 4);

    // 2. Get user input amounts
    for (uint i = 0; i < 4; i++) doTransmit(tokens[i], amtsUser[i]);
    doTransmit(lp, amtLPUser);

    // 3. Borrow specified amounts
    for (uint i = 0; i < 4; i++) doBorrow(tokens[i], amtsBorrow[i]);
    doBorrow(lp, amtLPBorrow);

    // 4. add liquidity
    uint[4] memory suppliedAmts;
    for (uint i = 0; i < 4; i++) {
      suppliedAmts[i] = IERC20(tokens[i]).balanceOf(address(this));
    }
    ICurvePool(pool).add_liquidity(suppliedAmts, minLPMint);

    // 5. Put collateral
    uint amount = IERC20(lp).balanceOf(address(this));
    ensureApprove(lp, address(wgauge));
    uint id = wgauge.mint(pid, gid, amount);
    bank.putCollateral(address(wgauge), id, amount);

    // 6. Refund
    for (uint i = 0; i < 4; i++) doRefund(tokens[i]);

    // 7. Refund crv
    doRefund(crv);
  }

  function removeLiquidity2(
    address lp,
    uint amtLPTake,
    uint amtLPWithdraw,
    uint[2] calldata amtsRepay,
    uint amtLPRepay,
    uint[2] calldata amtsMin
  ) external payable {
    address pool = getPool(lp);
    uint positionId = bank.POSITION_ID();
    (, address collToken, uint collId, ) = bank.getPositionInfo(positionId);
    require(IWLiquidityGauge(collToken).getUnderlyingToken(collId) == lp, 'incorrect underlying');
    address[] memory tokens = ulTokens[lp];

    // 0. Ensure approve
    ensureApproveN(lp, 2);

    // 1. Compute repay amount if MAX_INT is supplied (max debt)
    uint[2] memory actualAmtsRepay;
    for (uint i = 0; i < 2; i++) {
      actualAmtsRepay[i] = amtsRepay[i] == uint(-1)
        ? bank.borrowBalanceCurrent(positionId, tokens[i])
        : amtsRepay[i];
    }
    uint[2] memory amtsDesired;
    for (uint i = 0; i < 2; i++) {
      amtsDesired[i] = actualAmtsRepay[i].add(amtsMin[i]); // repay amt + slippage control
    }

    // 2. Take out collateral
    bank.takeCollateral(address(wgauge), collId, amtLPTake);
    wgauge.burn(collId, amtLPTake);

    // 3. Compute amount to actually remove. Remove to repay just enough
    uint amtLPToRemove;
    if (amtsDesired[0] > 0 || amtsDesired[1] > 0) {
      amtLPToRemove = IERC20(lp).balanceOf(address(this)).sub(amtLPWithdraw);
      ICurvePool(pool).remove_liquidity_imbalance(amtsDesired, amtLPToRemove);
    }

    // 4. Compute leftover amount to remove. Remove balancedly.
    amtLPToRemove = IERC20(lp).balanceOf(address(this)).sub(amtLPWithdraw);
    uint[2] memory mins;
    ICurvePool(pool).remove_liquidity(amtLPToRemove, mins);

    // 5. Repay
    for (uint i = 0; i < 2; i++) {
      doRepay(tokens[i], actualAmtsRepay[i]);
    }
    doRepay(lp, amtLPRepay);

    // 6. Refund
    for (uint i = 0; i < 2; i++) {
      doRefund(tokens[i]);
    }
    doRefund(lp);

    // 7. Refund crv
    doRefund(crv);
  }

  function removeLiquidity3(
    address lp,
    uint amtLPTake,
    uint amtLPWithdraw,
    uint[3] calldata amtsRepay,
    uint amtLPRepay,
    uint[3] calldata amtsMin
  ) external payable {
    address pool = getPool(lp);
    uint positionId = bank.POSITION_ID();
    (, address collToken, uint collId, ) = bank.getPositionInfo(positionId);
    require(IWLiquidityGauge(collToken).getUnderlyingToken(collId) == lp, 'incorrect underlying');
    address[] memory tokens = ulTokens[lp];

    // 0. Ensure approve
    ensureApproveN(lp, 3);

    // 1. Compute repay amount if MAX_INT is supplied (max debt)
    uint[3] memory actualAmtsRepay;
    for (uint i = 0; i < 3; i++) {
      actualAmtsRepay[i] = amtsRepay[i] == uint(-1)
        ? bank.borrowBalanceCurrent(positionId, tokens[i])
        : amtsRepay[i];
    }
    uint[3] memory amtsDesired;
    for (uint i = 0; i < 3; i++) {
      amtsDesired[i] = actualAmtsRepay[i].add(amtsMin[i]); // repay amt + slippage control
    }

    // 2. Take out collateral
    bank.takeCollateral(address(wgauge), collId, amtLPTake);
    wgauge.burn(collId, amtLPTake);

    // 3. Compute amount to actually remove. Remove to repay just enough
    uint amtLPToRemove;
    if (amtsDesired[0] > 0 || amtsDesired[1] > 0 || amtsDesired[2] > 0) {
      amtLPToRemove = IERC20(lp).balanceOf(address(this)).sub(amtLPWithdraw);
      ICurvePool(pool).remove_liquidity_imbalance(amtsDesired, amtLPToRemove);
    }

    // 4. Compute leftover amount to remove. Remove balancedly.
    amtLPToRemove = IERC20(lp).balanceOf(address(this)).sub(amtLPWithdraw);
    uint[3] memory mins;
    ICurvePool(pool).remove_liquidity(amtLPToRemove, mins);

    // 5. Repay
    for (uint i = 0; i < 3; i++) {
      doRepay(tokens[i], actualAmtsRepay[i]);
    }
    doRepay(lp, amtLPRepay);

    // 6. Refund
    for (uint i = 0; i < 3; i++) {
      doRefund(tokens[i]);
    }
    doRefund(lp);

    // 7. Refund crv
    doRefund(crv);
  }

  function removeLiquidity4(
    address lp,
    uint amtLPTake,
    uint amtLPWithdraw,
    uint[4] calldata amtsRepay,
    uint amtLPRepay,
    uint[4] calldata amtsMin
  ) external payable {
    address pool = getPool(lp);
    uint positionId = bank.POSITION_ID();
    (, address collToken, uint collId, ) = bank.getPositionInfo(positionId);
    require(IWLiquidityGauge(collToken).getUnderlyingToken(collId) == lp, 'incorrect underlying');
    address[] memory tokens = ulTokens[lp];

    // 0. Ensure approve
    ensureApproveN(lp, 4);

    // 1. Compute repay amount if MAX_INT is supplied (max debt)
    uint[4] memory actualAmtsRepay;
    for (uint i = 0; i < 4; i++) {
      actualAmtsRepay[i] = amtsRepay[i] == uint(-1)
        ? bank.borrowBalanceCurrent(positionId, tokens[i])
        : amtsRepay[i];
    }
    uint[4] memory amtsDesired;
    for (uint i = 0; i < 4; i++) {
      amtsDesired[i] = actualAmtsRepay[i].add(amtsMin[i]); // repay amt + slippage control
    }

    // 2. Take out collateral
    bank.takeCollateral(address(wgauge), collId, amtLPTake);
    wgauge.burn(collId, amtLPTake);

    // 3. Compute amount to actually remove. Remove to repay just enough
    uint amtLPToRemove;
    if (amtsDesired[0] > 0 || amtsDesired[1] > 0 || amtsDesired[2] > 0 || amtsDesired[3] > 0) {
      amtLPToRemove = IERC20(lp).balanceOf(address(this)).sub(amtLPWithdraw);
      ICurvePool(pool).remove_liquidity_imbalance(amtsDesired, amtLPToRemove);
    }

    // 4. Compute leftover amount to remove. Remove balancedly.
    amtLPToRemove = IERC20(lp).balanceOf(address(this)).sub(amtLPWithdraw);
    uint[4] memory mins;
    ICurvePool(pool).remove_liquidity(amtLPToRemove, mins);

    // 5. Repay
    for (uint i = 0; i < 4; i++) {
      doRepay(tokens[i], actualAmtsRepay[i]);
    }
    doRepay(lp, amtLPRepay);

    // 6. Refund
    for (uint i = 0; i < 4; i++) {
      doRefund(tokens[i]);
    }
    doRefund(lp);

    // 7. Refund crv
    doRefund(crv);
  }

  function harvest() external {
    uint positionId = bank.POSITION_ID();
    (, , uint collId, uint collSize) = bank.getPositionInfo(positionId);
    (uint pid, uint gid, ) = wgauge.decodeId(collId);
    address lp = wgauge.getUnderlyingToken(collId);

    // 1. Take out collateral
    bank.takeCollateral(address(wgauge), collId, collSize);
    wgauge.burn(collId, collSize);

    // 2. Put collateral
    uint amount = IERC20(lp).balanceOf(address(this));
    ensureApprove(lp, address(wgauge));
    uint id = wgauge.mint(pid, gid, amount);
    bank.putCollateral(address(wgauge), id, amount);

    // 3. Refund crv
    doRefund(crv);
  }
}