pragma solidity =0.5.16;

import "./interfaces/IProDexV2Factory.sol";
import "./ProDexV2Pair.sol";

contract ProDexV2Factory is IProDexV2Factory {
    address public feeTo;
    address public feeToSetter;
    address public operator;

    mapping(address => mapping(address => address)) public getPair;
    mapping(address => bool) public whitelisted;
    address[] public allPairs;

    modifier onlyOperator() {
        require(
            tx.origin == operator || msg.sender == operator,
            "Only 8Bit Operators!"
        );
        _;
    }

    modifier onlyWhitelisted() {
        require(
            whitelisted[msg.sender] == true || whitelisted[tx.origin] == true,
            "Only Whitelisted addresses are able to create pair"
        );
        _;
    }

    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint poolsLength
    );

    constructor(address _feeToSetter, address _Operator) public {
        feeToSetter = _feeToSetter;
        operator = _Operator;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(
        address tokenA,
        address tokenB
    ) external onlyWhitelisted returns (address pair) {
        require(tokenA != tokenB, "ProDex: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "ProDex: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "ProDex: PAIR_EXISTS"); // single check is sufficient
        bytes memory bytecode = type(ProDexV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IProDexV2Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, "ProDex: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, "ProDex: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }

    function setOperator(
        address newOperator,
        string calldata confirmation
    ) external onlyOperator {
        require(
            newOperator != address(0),
            "cant set new operator to address zero!"
        );
        require(
            keccak256(bytes(confirmation)) ==
                keccak256(bytes("CONFIRM_TRANSFERRING_OPERATOR")),
            "please confirm transferring oeprator"
        );
        operator = newOperator;
    }

    function addWhitelistedWallet(address newWallet) external onlyOperator {
        whitelisted[newWallet] = true;
    }

    function removeWhitelistedWallet(address newWallet) external onlyOperator {
        whitelisted[newWallet] = false;
    }
}