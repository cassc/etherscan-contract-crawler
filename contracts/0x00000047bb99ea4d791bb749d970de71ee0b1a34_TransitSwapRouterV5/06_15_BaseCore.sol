// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libs/Pausable.sol";
import "./libs/ReentrancyGuard.sol";
import "./libs/TransferHelper.sol";
import "./libs/RevertReasonParser.sol";
import "./libs/SafeMath.sol";
import "./libs/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2.sol";
import "./interfaces/IUniswapV3Pool.sol";


contract BaseCore is Ownable, Pausable, ReentrancyGuard {

    using SafeMath for uint256;

    struct ExactInputV2SwapParams {
        address dstReceiver;
        address wrappedToken;
        uint256 router;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 fee;
        address[] path;
        address[] pool;
        bytes signature;
        string channel;
    }

    struct ExactInputV3SwapParams {
        address srcToken;
        address dstToken;
        address dstReceiver;
        address wrappedToken;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 fee;
        uint256 deadline;
        uint256[] pools;
        bytes signature;
        string channel;
    }

    struct TransitSwapDescription {
        address srcToken;
        address dstToken;
        address dstReceiver;
        address wrappedToken;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 fee;
        string channel;
        bytes signature;
    }

    struct CrossDescription {
        address srcToken;
        address dstToken;
        address caller;
        address dstReceiver;
        address wrappedToken;
        uint256 amount;
        uint256 fee;
        uint256 toChain;
        string channel;
        bytes calls;
        bytes signature;
    }

    struct CallbytesDescription {
        address srcToken;
        bytes calldatas;
    }

    struct UniswapV3Pool {
        address factory;
        bytes initCodeHash;
    }

    uint256 internal _aggregate_fee;
    uint256 internal _cross_fee;
    address internal _aggregate_bridge;
    address internal _fee_signer;
    bytes32 public DOMAIN_SEPARATOR;
    //whitelist cross's caller
    mapping(address => bool) internal _cross_caller_allowed;
    //whitelist wrapped
    mapping(address => bool) internal _wrapped_allowed;
    //whitelist uniswap v3 factory
    mapping(uint => UniswapV3Pool) internal _uniswapV3_factory_allowed;
    bytes32 public constant CHECKFEE_TYPEHASH = keccak256("CheckFee(address payer,uint256 amount,uint256 fee)");

    event Receipt(address from, uint256 amount);
    event Withdraw(address indexed token, address indexed executor, address indexed recipient, uint amount);
    event ChangeWrappedAllowed(address[] wrappedTokens, bool[] newAllowed);
    event ChangeV3FactoryAllowed(uint256[] poolIndex, address[] factories, bytes[] initCodeHash);
    event ChangeCrossCallerAllowed(address[] callers);
    event ChangeFeeRate(bool isAggregate, uint256 newRate);
    event ChangeSigner(address preSigner, address newSigner);
    event ChangeAggregateBridge(address newBridge);
    event TransitSwapped(address indexed srcToken, address indexed dstToken, address indexed dstReceiver, uint256 amount, uint256 returnAmount, uint256 toChainID, string channel);
    
    constructor() Ownable(msg.sender) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("TransitSwapV5")),
                keccak256(bytes("5")),
                block.chainid,
                address(this)
            )
        );
    }

    receive() external payable {
        emit Receipt(msg.sender, msg.value);
    }

    function calculateTradeFee(bool isAggregate, uint256 tradeAmount, uint256 fee, bytes calldata signature) internal view returns (uint256) {
        uint256 thisFee;
        if (isAggregate) {
            thisFee = tradeAmount.mul(_aggregate_fee).div(10000);
        } else {
            thisFee = tradeAmount.mul(_cross_fee).div(10000);
        }
        if (fee < thisFee) {
            require(verifySignature(tradeAmount, fee, signature), "Invalid signature fee");
        }
        return tradeAmount.sub(fee);
    }

    function _emitTransit(address srcToken, address dstToken, address dstReceiver, uint256 amount, uint256 returnAmount, uint256 toChainID, string memory channel) internal {
        emit TransitSwapped (
            srcToken, 
            dstToken, 
            dstReceiver,
            amount,
            returnAmount,
            toChainID,
            channel
        );
    }

    function changeFee(bool[] memory isAggregate, uint256[] memory newRate) external onlyExecutor {
        for (uint i; i < isAggregate.length; i++) {
            require(newRate[i] >= 0 && newRate[i] <= 1000, "fee rate is:0-1000");
            if (isAggregate[i]) {
                _aggregate_fee = newRate[i];
            } else {
                _cross_fee = newRate[i];
            }
            emit ChangeFeeRate(isAggregate[i], newRate[i]);
        }
    }

    function changeTransitProxy(address aggregator, address signer) external onlyExecutor {
        if (aggregator != address(0)) {
            _aggregate_bridge = aggregator;
            emit ChangeAggregateBridge(aggregator);
        }
        if (signer != address(0)) {
            address preSigner = _fee_signer;
            _fee_signer = signer;
            emit ChangeSigner(preSigner, signer);
        }
    }

    function changeAllowed(address[] calldata crossCallers, address[] calldata wrappedTokens) public onlyExecutor {
        if(crossCallers.length != 0){
            for (uint i; i < crossCallers.length; i++) {
                _cross_caller_allowed[crossCallers[i]] = !_cross_caller_allowed[crossCallers[i]];
            }
            emit ChangeCrossCallerAllowed(crossCallers);
        }
        if(wrappedTokens.length != 0) {
            bool[] memory newAllowed = new bool[](wrappedTokens.length);
            for (uint index; index < wrappedTokens.length; index++) {
                _wrapped_allowed[wrappedTokens[index]] = !_wrapped_allowed[wrappedTokens[index]];
                newAllowed[index] = _wrapped_allowed[wrappedTokens[index]];
            }
            emit ChangeWrappedAllowed(wrappedTokens, newAllowed);
        }
    }

    function changeUniswapV3FactoryAllowed(uint[] calldata poolIndex, address[] calldata factories, bytes[] calldata initCodeHash) public onlyExecutor {
        require(poolIndex.length == initCodeHash.length, "invalid data");
        require(factories.length == initCodeHash.length, "invalid data");
        uint len = factories.length;
        for (uint i; i < len; i++) {
            _uniswapV3_factory_allowed[poolIndex[i]] = UniswapV3Pool(factories[i],initCodeHash[i]);
        }
        emit ChangeV3FactoryAllowed(poolIndex, factories, initCodeHash);
    }

    function changePause(bool paused) external onlyExecutor {
        if (paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    function transitProxyAddress() external view returns (address bridgeProxy, address feeSigner) {
        bridgeProxy = _aggregate_bridge;
        feeSigner = _fee_signer;
    }

    function transitFee() external view returns (uint256, uint256) {
        return (_aggregate_fee, _cross_fee);
    }

    function transitAllowedQuery(address crossCaller, address wrappedToken, uint256 poolIndex) external view returns (bool isCrossCallerAllowed, bool isWrappedAllowed, UniswapV3Pool memory pool) {
        isCrossCallerAllowed = _cross_caller_allowed[crossCaller];
        isWrappedAllowed = _wrapped_allowed[wrappedToken];
        pool = _uniswapV3_factory_allowed[poolIndex];
    }

    function verifySignature(uint256 amount, uint256 fee, bytes calldata signature) internal view returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(CHECKFEE_TYPEHASH, msg.sender, amount, fee))
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
        address recovered = ecrecover(digest, v, r, s);
        return recovered == _fee_signer;
    }

    function splitSignature(bytes memory _signature) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(bytes(_signature).length == 65, "Invalid signature length");

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        return (v, r, s);
    }

}