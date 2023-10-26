// Allocation (ALLO) Vester
//
// https://alloeth.com
// https://t.me/allocationofficial
//
// This contract allows anyone to lock tokens that will linearly vest over
// a specified time frame for a wallet owned by an ENS name. The goal is to
// make token allocations more transparent for projects who give or OTC tokens
// out to KOLs, advisors, influencers, etc.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import './interfaces/ENS.sol';
import './interfaces/ENSResolver.sol';

contract AlloVester is Context, Ownable {
  using SafeERC20 for IERC20Metadata;

  address public immutable ALLO;
  ENS public immutable ETH_NAME_SERVICE;

  uint256 public createCostALLO = 20_000 * 10 ** 18;
  uint256 public createCostNative = 3 ether / 100; // 0.03 ETH
  address public feeReceiver;

  struct VestedAllocation {
    uint256 total;
    uint256 start;
    uint256 end;
    uint256 debt;
  }

  // token => ENS namehash => allocation info
  mapping(address => mapping(bytes32 => VestedAllocation)) public allocations;

  event AlloCreate(
    address indexed creator,
    address indexed token,
    bytes32 indexed node,
    string ensName,
    uint256 amount
  );
  event AlloClaim(
    address indexed token,
    bytes32 indexed node,
    string ensName,
    address wallet,
    uint256 amountClaimed
  );

  constructor(address _nameService) {
    ALLO = _msgSender();
    ETH_NAME_SERVICE = ENS(_nameService);
  }

  function ensNodeToWallet(bytes32 _node) public view returns (address) {
    ENSResolver resolver = ETH_NAME_SERVICE.resolver(_node);
    return resolver.addr(_node);
  }

  /// @notice exclude `.eth` in ENS name
  /// @notice i.e. to resolve `vitalik.eth`, only pass `vitalik` to _ensName
  function ensNameToNode(string memory _ensName) public pure returns (bytes32) {
    bytes32 _namehash = keccak256(
      abi.encodePacked(bytes32(0), keccak256(abi.encodePacked('eth')))
    );
    return
      keccak256(
        abi.encodePacked(_namehash, keccak256(abi.encodePacked(_ensName)))
      );
  }

  function ensNameToWallet(
    string memory _ensName // name without `.eth` suffix (for vitalik.eth, just pass vitalik)
  ) external view returns (address) {
    bytes32 _node = ensNameToNode(_ensName);
    return ensNodeToWallet(_node);
  }

  function vestedAlloClaim(
    address _token,
    string memory _ensName // name without `.eth` suffix (for vitalik.eth, just pass vitalik)
  ) external virtual {
    bytes32 _node = ensNameToNode(_ensName);
    address _wallet = ensNodeToWallet(_node);

    VestedAllocation storage _allo = allocations[_token][_node];
    require(_allo.end > 0, 'EXIST');
    require(_allo.start < block.timestamp, 'START');

    uint256 _nowEnd = block.timestamp > _allo.end ? _allo.end : block.timestamp;
    uint256 _withTotal = (_allo.total * (_nowEnd - _allo.start)) /
      (_allo.end - _allo.start);
    uint256 _withdrawAmount = _withTotal - _allo.debt;
    require(_withdrawAmount > 0, 'NOTHING');

    if (_nowEnd == _allo.end) {
      delete allocations[_token][_node];
    } else {
      _allo.debt += _withdrawAmount;
    }
    IERC20Metadata(_token).safeTransfer(_wallet, _withdrawAmount);
    emit AlloClaim(_token, _node, _ensName, _wallet, _withdrawAmount);
  }

  function vestedAlloCreate(
    address _token,
    string memory _ensName, // name without `.eth` suffix (for vitalik.eth, just pass vitalik)
    uint256 _amount,
    uint256 _start,
    uint256 _end,
    bool _feesInNative
  ) external payable virtual {
    _processFees(_feesInNative);
    bytes32 _node = ensNameToNode(_ensName);
    require(allocations[_token][_node].end == 0, 'DUPLICATE');
    require(_end > 0 && _end > _start && _amount > 0, 'VAL');

    // reverts if the namehash does not resolve to a wallet
    ensNodeToWallet(_node);

    uint256 _balBefore = IERC20Metadata(_token).balanceOf(address(this));
    IERC20Metadata(_token).safeTransferFrom(
      _msgSender(),
      address(this),
      _amount
    );
    _amount = IERC20Metadata(_token).balanceOf(address(this)) - _balBefore;
    allocations[_token][_node] = VestedAllocation({
      total: _amount,
      start: _start,
      end: _end,
      debt: 0
    });
    emit AlloCreate(_msgSender(), _token, _node, _ensName, _amount);
  }

  function _processFees(bool _feesInNative) internal {
    address _feeRec = _getFeeReceiver();
    if (_feesInNative && createCostNative > 0) {
      require(msg.value >= createCostNative, 'FEE');
      (bool _fee, ) = payable(_feeRec).call{ value: createCostNative }('');
      require(_fee, 'FEESENT');
      uint256 _refund = msg.value - createCostNative;
      if (_refund > 0) {
        (bool _refunded, ) = payable(_msgSender()).call{ value: _refund }('');
        require(_refunded, 'REFUND');
      }
    } else if (createCostALLO > 0) {
      IERC20Metadata(ALLO).safeTransferFrom(
        _msgSender(),
        _feeRec,
        createCostALLO
      );
    }
  }

  function _getFeeReceiver() internal view returns (address) {
    return feeReceiver == address(0) ? owner() : feeReceiver;
  }

  function setCreateCosts(
    uint256 _costALLO,
    uint256 _costNative
  ) external onlyOwner {
    createCostALLO = _costALLO;
    createCostNative = _costNative;
  }

  function setFeeReceiver(address _receiver) external onlyOwner {
    feeReceiver = _receiver;
  }
}