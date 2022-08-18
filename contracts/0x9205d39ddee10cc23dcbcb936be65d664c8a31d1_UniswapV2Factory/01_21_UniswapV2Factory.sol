// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

import './interfaces/IUniswapV2Factory.sol';
import '../starkex/interfaces/MFreezable.sol';
import '../interfaces/IPairWithOverlay.sol';
import './OperatorAccessControl.sol';
import './PairProxy.sol';

contract UniswapV2Factory is OperatorAccessControl, IUniswapV2Factory {
    uint internal constant starkExContractSwitchDelay = 8 days;
    uint private constant MAX_PAIRS = 2**16;
    uint private constant MAX_GAP = 2**32;

    address public override feeTo;
    address public override feeToSetter;
    address public override migrator;
    address public override starkExContract;
    address public override wethAddress;
    address public pairHolder;
    address public nextStarkExContract;
    uint public nextStarkExContractSwitchDeadline;

    mapping(address => mapping(address => address)) public override getPair;
    uint private currentPairCount;
    address[MAX_PAIRS] public override allPairs;

    // https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[MAX_GAP] private __gap;

    modifier _isFeeToSetter() {
        require(msg.sender == feeToSetter, 'DVF_AMM: FORBIDDEN');
        _;
    }

    function isOperator() public override view returns (bool) {
      return hasRole(OPERATOR_ROLE, tx.origin);
    }

    function beacon() external view returns (address) {
      return pairHolder;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer { }

    function initialize(address _feeToSetter, address _starkExContract, address _wethAddress, address _pairHolder)
     initializer external virtual {
        __OperatorAccessControl_init();
        feeToSetter = _feeToSetter;
        starkExContract = _starkExContract;
        wethAddress = _wethAddress;
        pairHolder = _pairHolder;
        _setupRole(DEFAULT_ADMIN_ROLE, _feeToSetter);
        grantRole(OPERATOR_ROLE, _feeToSetter);
        currentPairCount = 0;
    }

    function allPairsLength() external override view returns (uint) {
        return currentPairCount;
    }

    function pairCodeHash() public override pure returns (bytes32) {
        return keccak256(type(PairProxy).creationCode);
    }

    function pairByteCode() private pure returns (bytes memory) {
        return type(PairProxy).creationCode;
    }

    function pairFor(address tokenA, address tokenB) external override view returns (address pair) {
      pair = getPair[tokenA][tokenB];

      if (pair == address(0)) {
        pair = calculatePairAddress(tokenA, tokenB);
      }
    }

    function calculatePairAddress(address tokenA, address tokenB) internal view returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                address(this),
                keccak256(abi.encodePacked(token0, token1)),
                pairCodeHash()
            )))));
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(isOperator(), 'DVF: FORBIDDEN');
        require(tokenA != tokenB, 'DVF_AMM: IDENTICAL_ADDRESSES');
        require(currentPairCount < MAX_PAIRS, 'DVF: PAIRS_LIMIT');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        // token1 check not required due to the sorting above
        require(token0 != address(0), 'DVF_AMM: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'DVF_AMM: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = pairByteCode();
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        address payable payablePair;

        assembly {
            payablePair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        pair = address(payablePair);
        IPairWithOverlay(payablePair).initialize(token0, token1, wethAddress);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs[currentPairCount++] = pair;
        emit PairCreated(token0, token1, pair, currentPairCount);
    }

    function setFeeTo(address _feeTo) external override _isFeeToSetter {
        feeTo = _feeTo;
    }

    function setMigrator(address _migrator) external override _isFeeToSetter {
        migrator = _migrator;
    }

    function setFeeToSetter(address _feeToSetter) external override _isFeeToSetter {
        grantRole(DEFAULT_ADMIN_ROLE, _feeToSetter);
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        feeToSetter = _feeToSetter;
    }

    function isStarkExContractFrozen() external override view returns (bool) {
        return MFreezable(starkExContract).isFrozen();
    }

    function initiateStarkExContractChange(address _starkExContract) external _isFeeToSetter {
        require(nextStarkExContract == address(0), 'DVF_AMM: STARKEX_CONTRACT_CHANGE_ALREADY_IN_PROGRESS');
        require(_starkExContract != starkExContract, 'DVF_AMM: INPUT_STARKEX_CONTRACT_SAME_AS_CURRENT');
        require(_starkExContract != address(0) , 'DVF_AMM: INPUT_STARKEX_CONTRACT_UNDEFINED');
        nextStarkExContract = _starkExContract;
        nextStarkExContractSwitchDeadline = block.timestamp + starkExContractSwitchDelay;
    }

    function finalizeStarkExContractChange() external {
        require(nextStarkExContract != address(0), 'DVF_AMM: NEXT_STARKEX_CONTRACT_UNDEFINED');
        require(block.timestamp >= nextStarkExContractSwitchDeadline, 'DVF_AMM: DELAY_NO_REACHED_FOR_STARKEX_CONTRACT_CHANGE');
        require(!this.isStarkExContractFrozen(), 'DVF_AMM: CURRENT_STARKEX_CONTRACT_FROZEN');
        starkExContract = nextStarkExContract;
        nextStarkExContract = address(0);
        nextStarkExContractSwitchDeadline = 0;
    }

    // Emit events on behalf of pair contracts

    modifier fromPair(address token0, address token1) {
      require(getPair[token0][token1] == msg.sender, 'ONLY_ALLOWED_FROM_PAIR');
      _;
    }

  event WithdrawalRequested(address indexed pair, address user, uint amount, uint withdrawalId);
  event WithdrawalCompleted(address indexed pair, address user, uint amount, uint token0Amount, uint token1Amount);
  event WithdrawalForced(address indexed pair, address user);

  function withdrawalRequested(address token0, address token1, address user, uint amount, uint withdrawalId) 
    external 
    override
    fromPair(token0, token1)
  {
    emit WithdrawalRequested(msg.sender, user, amount, withdrawalId);
  }

  function withdrawalCompleted(address token0, address token1, address user, uint amount, uint token0Amount, uint token1Amount) 
    external 
    override
    fromPair(token0, token1)
  {
    emit WithdrawalCompleted(msg.sender, user, amount, token0Amount, token1Amount);
  }

  function withdrawalForced(address token0, address token1, address user) 
    external 
    override
    fromPair(token0, token1)
  {
    emit WithdrawalForced(msg.sender, user);
  }
}