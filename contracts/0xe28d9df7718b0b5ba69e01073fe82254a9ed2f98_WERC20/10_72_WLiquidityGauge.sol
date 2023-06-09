pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/token/ERC1155/ERC1155.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/SafeERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/utils/ReentrancyGuard.sol';

import '../Governable.sol';
import '../utils/HomoraMath.sol';
import '../../interfaces/IERC20Wrapper.sol';
import '../../interfaces/ICurveRegistry.sol';
import '../../interfaces/ILiquidityGauge.sol';

interface ILiquidityGaugeMinter {
  function mint(address gauge) external;
}

contract WLiquidityGauge is ERC1155('WLiquidityGauge'), ReentrancyGuard, IERC20Wrapper, Governable {
  using SafeMath for uint;
  using HomoraMath for uint;
  using SafeERC20 for IERC20;

  struct GaugeInfo {
    ILiquidityGauge impl;
    uint accCrvPerShare;
  }

  ICurveRegistry public immutable registry;
  IERC20 public immutable crv;
  mapping(uint => mapping(uint => GaugeInfo)) public gauges;

  constructor(ICurveRegistry _registry, IERC20 _crv) public {
    __Governable__init();
    registry = _registry;
    crv = _crv;
  }

  function encodeId(
    uint pid,
    uint gid,
    uint crvPerShare
  ) public pure returns (uint id) {
    require(pid < (1 << 8), 'bad pid');
    require(gid < (1 << 8), 'bad gid');
    require(crvPerShare < (1 << 240), 'bad crv per share');
    return (pid << 248) | (gid << 240) | crvPerShare;
  }

  function decodeId(uint id)
    public
    pure
    returns (
      uint pid,
      uint gid,
      uint crvPerShare
    )
  {
    pid = id >> 248; // First 8 bits
    gid = (id >> 240) & (255); // Next 8 bits
    crvPerShare = id & ((1 << 240) - 1); // Last 240 bits
  }

  function getUnderlyingToken(uint id) external view override returns (address) {
    (uint pid, uint gid, ) = decodeId(id);
    ILiquidityGauge impl = gauges[pid][gid].impl;
    require(address(impl) != address(0), 'no gauge');
    return impl.lp_token();
  }

  /// @dev Return the conversion rate from ERC-1155 to ERC-20, multiplied by 2**112.
  function getUnderlyingRate(uint) external view override returns (uint) {
    return 2**112;
  }

  function registerGauge(uint pid, uint gid) external onlyGov {
    require(address(gauges[pid][gid].impl) == address(0), 'gauge already exists');
    address pool = registry.pool_list(pid);
    require(pool != address(0), 'no pool');
    (address[10] memory _gauges, ) = registry.get_gauges(pool);
    address gauge = _gauges[gid];
    require(gauge != address(0), 'no gauge');
    IERC20 lpToken = IERC20(ILiquidityGauge(gauge).lp_token());
    lpToken.approve(gauge, 0);
    lpToken.approve(gauge, uint(-1));
    gauges[pid][gid] = GaugeInfo({impl: ILiquidityGauge(gauge), accCrvPerShare: 0});
  }

  function mint(
    uint pid,
    uint gid,
    uint amount
  ) external nonReentrant returns (uint) {
    GaugeInfo storage gauge = gauges[pid][gid];
    ILiquidityGauge impl = gauge.impl;
    require(address(impl) != address(0), 'gauge not registered');
    mintCrv(gauge);
    IERC20 lpToken = IERC20(impl.lp_token());
    lpToken.safeTransferFrom(msg.sender, address(this), amount);
    impl.deposit(amount);
    uint id = encodeId(pid, gid, gauge.accCrvPerShare);
    _mint(msg.sender, id, amount, '');
    return id;
  }

  function burn(uint id, uint amount) external nonReentrant returns (uint) {
    if (amount == uint(-1)) {
      amount = balanceOf(msg.sender, id);
    }
    (uint pid, uint gid, uint stCrvPerShare) = decodeId(id);
    _burn(msg.sender, id, amount);
    GaugeInfo storage gauge = gauges[pid][gid];
    ILiquidityGauge impl = gauge.impl;
    require(address(impl) != address(0), 'gauge not registered');
    mintCrv(gauge);
    impl.withdraw(amount);
    IERC20(impl.lp_token()).safeTransfer(msg.sender, amount);
    uint stCrv = stCrvPerShare.mul(amount).divCeil(1e18);
    uint enCrv = gauge.accCrvPerShare.mul(amount).div(1e18);
    if (enCrv > stCrv) {
      crv.safeTransfer(msg.sender, enCrv.sub(stCrv));
    }
    return pid;
  }

  function mintCrv(GaugeInfo storage gauge) internal {
    ILiquidityGauge impl = gauge.impl;
    uint balanceBefore = crv.balanceOf(address(this));
    ILiquidityGaugeMinter(impl.minter()).mint(address(impl));
    uint balanceAfter = crv.balanceOf(address(this));
    uint gain = balanceAfter.sub(balanceBefore);
    uint supply = impl.balanceOf(address(this));
    if (gain > 0 && supply > 0) {
      gauge.accCrvPerShare = gauge.accCrvPerShare.add(gain.mul(1e18).div(supply));
    }
  }
}