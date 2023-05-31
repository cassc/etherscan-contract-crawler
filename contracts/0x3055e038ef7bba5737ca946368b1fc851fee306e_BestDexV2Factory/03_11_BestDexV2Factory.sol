// SPDX-License-Identifier: Unlicensed
pragma solidity =0.6.0;

import './interfaces/IBestDexV2Factory.sol';
import './BestDexV2Pair.sol';
import './interfaces/IBestDexV2Pair.sol';
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

contract BestDexV2Factory is IBestDexV2Factory, Initializable {
    address public override feeTo;
    address public override feeToSetter;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;
    
    // bytes32 public constant INIT_CODE_HASH = keccak256(abi.encodePacked(type(BestDexV2Pair).creationCode));
    bytes32 public INIT_CODE_HASH;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    // constructor(address _feeToSetter) public {
    //     feeToSetter = _feeToSetter;
    // }

    function __BestDexV2Factory_init(address _feeToSetter) public initializer {
        feeToSetter = _feeToSetter;
        INIT_CODE_HASH = keccak256(abi.encodePacked(type(BestDexV2Pair).creationCode));
    }

    function allPairsLength() external view override returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'BestDexV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'BestDexV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'BestDexV2: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(BestDexV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IBestDexV2Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, 'BestDexV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, 'BestDexV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}