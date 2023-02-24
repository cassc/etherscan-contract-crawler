pragma solidity =0.8.8;

import "./interfaces/IUniswapV2Factory.sol";
import "./UniswapV2Pair.sol";
import "../common/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract UniswapV2Factory is
    IUniswapV2Factory,
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    address public feeTo;
    address public feeToSetter;
    address public router;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    function initialize(address _feeToSetter) public initializer {
        OwnableUpgradeable.initialize();
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair)
    {
        require(tokenA != tokenB, "UniswapV2: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2: ZERO_ADDRESS");
        require(
            getPair[token0][token1] == address(0),
            "UniswapV2: PAIR_EXISTS"
        ); // single check is sufficient
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        UniswapV2Pair(pair).initialize(token0, token1);
        UniswapV2Pair(pair).verify(router, true);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, "UniswapV2: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, "UniswapV2: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }

    function verify(
        address _tokenA,
        address _tokenB,
        address _address,
        bool _isVerified
    ) external onlyOwner {
        require(_address != address(0), "UniswapV2: ZERO_ADDRESS");
        address pair = getPair[_tokenA][_tokenB];
        require(pair != address(0), "UniswapV2: ZERO_ADDRESS");
        UniswapV2Pair(pair).verify(_address, _isVerified);
    }

    function setRouter(address _router) external onlyOwner {
        require(_router != address(0), "UniswapV2: ZERO_ADDRESS");
        router = _router;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}