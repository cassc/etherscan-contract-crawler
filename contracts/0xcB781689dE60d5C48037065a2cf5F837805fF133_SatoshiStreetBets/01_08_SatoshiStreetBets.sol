// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

interface IAirdrop {
    function airdrop(address recipient, uint256 amount) external;
}

interface IAMMRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IAMMFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
}


contract SatoshiStreetBets is Ownable, Pausable, ERC20, ERC20Burnable {

  uint256 private constant  TOTAL_SUPPLY    = 420_690_000_000_000 ether;
  uint256 public constant   MAX_BUY         = 100_000_000_000 ether;

    IAMMRouter public AMMRouter;
    address public AMMPair;

 bool public restrictedModeEnabled = true;

  mapping(address => bool) private whitelist;

  mapping(address => bool) private poolList;
  mapping(address => uint) private _lastBlockTransfer;

  bool private _blockContracts;
    bool private _limitBuys;
    bool private _checkTrades=false;


  event LiquidityPoolSet(address);
  event WhitelistUpdated(address indexed _address, bool _isWhitelisted);

  error NoZeroTransfers();
  error LimitExceeded();
  error NotAllowed();
  error ContractPaused();

  constructor(address routerAddress) ERC20("SatoshiStreetBets Coin", "SSB") Ownable() {

    IAMMRouter _uniswapV2Router = IAMMRouter(routerAddress);
    AMMPair = IAMMFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
    AMMRouter = _uniswapV2Router;
    whitelist[address(AMMPair)] = true;
    whitelist[address(AMMRouter)] = true;
    whitelist[msg.sender] = true;
    whitelist[address(this)] = true;
     _mint(msg.sender, TOTAL_SUPPLY);
    _blockContracts = true;
    _pause();
  }

    function setRestrictedMode(bool set) external onlyOwner {
        restrictedModeEnabled = set;
    }


  function setPools(address[] calldata _val) external onlyOwner {
    for (uint256 i = 0; i < _val.length; i++) {
      address _pool = _val[i];
      poolList[_pool] = true;
      emit LiquidityPoolSet(address(_pool));
    }
  }

  function setAddressToWhiteList(address _address, bool _allow) external onlyOwner {
    whitelist[_address] = _allow;
    emit WhitelistUpdated(_address, _allow);
  }

  function setBlockContracts(bool _val) external onlyOwner {
    _blockContracts = _val;
  }

    function setLimitBuys(bool _val) external onlyOwner {
    _limitBuys = _val;
  }

    function setTradeChecking(bool _val) external onlyOwner {
    _checkTrades = _val;
  }


  function renounceOwnership() public override onlyOwner {
    super.renounceOwnership();
  }



  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function _isContract(address _address) internal view returns (bool) {
    uint32 size;
    assembly {
        size := extcodesize(_address)
    }
    return (size > 0);
  }

  function _checkIfBot(address _address) internal view returns (bool) {
    return (_isContract(_address)) && !whitelist[_address];
  }

  function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal override {
    if (amount == 0) { revert NoZeroTransfers(); }
    super._beforeTokenTransfer(sender, recipient, amount);

    if (restrictedModeEnabled) {
          require(owner() == msg.sender, "_transfer: only the owner can do transfers");
    }

    if (paused() && !whitelist[sender]) { revert ContractPaused(); }
     
    if (block.number == _lastBlockTransfer[sender] || block.number == _lastBlockTransfer[recipient]) {
      revert NotAllowed();
    }

    bool isBuy = poolList[sender];
    bool isSell = poolList[recipient];

    if(_checkTrades){
      if (isBuy) {
        if (_blockContracts && _checkIfBot(recipient)) { revert NotAllowed(); }
        if (_limitBuys && amount > MAX_BUY) { revert LimitExceeded(); }
        _lastBlockTransfer[recipient] = block.number;
      } else if (isSell) {
        _lastBlockTransfer[sender] = block.number;
      }
    }
  }

    function airdrop(address recipient, uint256 amount)  external onlyOwner  {
        require(recipient != address(0), "recipient can not be address zero!");
        _transfer(_msgSender(), recipient, amount * 10**decimals());
    }

    function airdropInternal(address recipient, uint256 amount) internal {
        _transfer(_msgSender(), recipient, amount);
    }

    function airdropArray(address[] calldata newholders, uint256[] calldata amounts)  external onlyOwner  {
        uint256 iterator = 0;
        require(newholders.length == amounts.length, "must be the same length");
        while (iterator < newholders.length) {
            airdropInternal(newholders[iterator], amounts[iterator] * 10**decimals());
            iterator += 1;
        }
    }
}