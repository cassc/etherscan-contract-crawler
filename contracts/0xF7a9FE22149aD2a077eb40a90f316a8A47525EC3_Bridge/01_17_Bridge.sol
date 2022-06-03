// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./Utils.sol";
import "../access/Ownable.sol";
import "./interfaces/IBridge.sol";
import "./interfaces/ICallProxy.sol";
import "../assets/interfaces/IPToken.sol";
import "./interfaces/IEthCrossChainManager.sol";
import "./interfaces/IEthCrossChainManagerProxy.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Bridge is Ownable, IBridge, Pausable, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    struct TxArgs {
        bytes toAssetHash;
        bytes toAddress;
        uint256 amount;
        bytes callData;
    }

    bool isInitialized = true;
    uint256 private constant FEE_DENOMINATOR = 10**10;

    uint256 public bridgeFeeRate;
    address public bridgeFeeCollector;
    address public callProxy;
    address public managerProxyContract;

    mapping(uint64 => bytes) public bridgeHashMap;
    mapping(address => mapping(uint64 => bytes)) public assetHashMap;

    event setBridgeFeeEvent(uint256 rate, address feeCollector);
    event SetCallProxyEvent(address callProxy);
    event SetManagerProxyEvent(address manager);
    event BindBridgeEvent(uint64 toChainId, bytes targetBridge);
    event BindAssetEvent(address fromAssetHash, uint64 toChainId, bytes toAssetHash);
    event UnlockEvent(address toAssetHash, address toAddress, uint256 amount);
    event LockEvent(address fromAssetHash, address fromAddress, uint64 toChainId, bytes toAssetHash, bytes toAddress, uint256 amount);

    modifier onlyManagerContract() {
        IEthCrossChainManagerProxy ieccmp = IEthCrossChainManagerProxy(managerProxyContract);
        require(_msgSender() == ieccmp.getEthCrossChainManager(), "msgSender is not EthCrossChainManagerContract");
        _;
    }

    modifier initialization() {
        require(!isInitialized, "Already initialized");
        _;
        isInitialized = true;
    }

    function initialize(address initOwner) public initialization {
        _transferOwnership(initOwner);
    }

    function setBridgeFee(uint256 _rate, address _feeCollector) public onlyOwner {
        bridgeFeeRate = _rate;
        bridgeFeeCollector = _feeCollector;
        emit setBridgeFeeEvent(_rate, _feeCollector);
    }

    function setCallProxy(address _callProxy) onlyOwner public {
        callProxy = _callProxy;
        emit SetCallProxyEvent(_callProxy);
    }

    function setManagerProxy(address ethCCMProxyAddr) onlyOwner public {
        managerProxyContract = ethCCMProxyAddr;
        emit SetManagerProxyEvent(managerProxyContract);
    }

    function bindBridge(uint64 toChainId, bytes memory targetBridge) onlyOwner public returns (bool) {
        bridgeHashMap[toChainId] = targetBridge;
        emit BindBridgeEvent(toChainId, targetBridge);
        return true;
    }

    function bindAssetHash(address fromAssetHash, uint64 toChainId, bytes memory toAssetHash) onlyOwner public returns (bool) {
        assetHashMap[fromAssetHash][toChainId] = toAssetHash;
        emit BindAssetEvent(fromAssetHash, toChainId, toAssetHash);
        return true;
    }

    function bindBridgeBatch(uint64[] memory toChainIds, bytes[] memory targetBridgeHashes) onlyOwner public returns(bool) {
        require(toChainIds.length == targetBridgeHashes.length, "Inconsistent parameter lengths");
        for (uint i=0; i<toChainIds.length; i++) {
            bridgeHashMap[toChainIds[i]] = targetBridgeHashes[i];
            emit BindBridgeEvent(toChainIds[i], targetBridgeHashes[i]);
        }
        return true;
    }

    function bindAssetHashBatch(address[] memory fromAssetHashs, uint64[] memory toChainIds, bytes[] memory toAssetHashes) onlyOwner public returns(bool) {
        require(toChainIds.length == fromAssetHashs.length, "Inconsistent parameter lengths");
        require(toChainIds.length == toAssetHashes.length, "Inconsistent parameter lengths");
        for (uint i=0; i<toChainIds.length; i++) {
            assetHashMap[fromAssetHashs[i]][toChainIds[i]] = toAssetHashes[i];
            emit BindAssetEvent(fromAssetHashs[i], toChainIds[i], toAssetHashes[i]);
        }
        return true;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function depositAndBridgeOut(
        address originalTokenAddress,
        address pTokenAddress,
        uint64 toChainId,
        bytes memory toAddress,
        uint256 amount,
        bytes memory callData
    ) public override nonReentrant whenNotPaused returns(bool) {
        require(amount != 0, "amount cannot be zero!");

        // no bridge fee for deposit

        // transfer_to_this + deposit + burn = transfer_to_ptoken
        require(IPToken(pTokenAddress).tokenUnderlying() == originalTokenAddress, "invalid originalToken / pToken");
        require(IPToken(pTokenAddress).checkIfDepositWithdrawEnabled(), "ptoken deposit/withdraw not enabled");
        IERC20(originalTokenAddress).safeTransferFrom(_msgSender(), pTokenAddress, amount);

        // precision conversion
        uint8 ptokenDecimals = ERC20(pTokenAddress).decimals();
        uint8 underlyingTokenDecimals = ERC20(originalTokenAddress).decimals();
        amount = amount.mul(10**ptokenDecimals).div(10**underlyingTokenDecimals);
        require(amount != 0, "bridge amount cannot be zero!");

        return _bridgeOut(pTokenAddress, toChainId, toAddress, amount, callData);
    }

    function bridgeOutAndWithdraw(
        address fromAssetHash,
        uint64 toChainId,
        bytes memory toAddress,
        uint256 amount
    ) public override nonReentrant whenNotPaused returns(bool) {
        require(amount != 0, "amount cannot be zero!");

        // no bridge fee for withdraw

        // encode call data for withdraw
        bytes memory toAssetHash = assetHashMap[fromAssetHash][toChainId];
        require(toAssetHash.length != 0, "empty illegal toAssetHash");
        bytes memory callData = ICallProxy(callProxy).encodeArgsForWithdraw(toAssetHash, toAddress, amount);

        require(_burnFrom(fromAssetHash, _msgSender(), amount), "transfer and burn asset from fromAddress to bridge contract failed!");

        return _bridgeOut(fromAssetHash, toChainId, toAddress, amount, callData);
    }

    function bridgeOut(
        address fromAssetHash,
        uint64 toChainId,
        bytes memory toAddress,
        uint256 amount,
        bytes memory callData
    ) public override nonReentrant whenNotPaused returns(bool) {
        require(amount != 0, "amount cannot be zero!");

        // check if bridge fee is required
        uint256 bridgeFee = 0;
        if (bridgeFeeRate == 0 || bridgeFeeCollector == address(0)) {
            // no bridge fee
        } else {
            bridgeFee = amount.mul(bridgeFeeRate).div(FEE_DENOMINATOR);
            amount = amount.sub(bridgeFee);
            require(_chargeFee(fromAssetHash, _msgSender(), bridgeFeeCollector, bridgeFee), "charge fee failed!");
        }

        require(_burnFrom(fromAssetHash, _msgSender(), amount), "transfer and burn asset from fromAddress to bridge contract failed!");

        return _bridgeOut(fromAssetHash, toChainId, toAddress, amount, callData);
    }

    function _bridgeOut(
        address fromAssetHash,
        uint64 toChainId,
        bytes memory toAddress,
        uint256 amount,
        bytes memory callData
    ) internal returns(bool) {
        bytes memory toAssetHash = assetHashMap[fromAssetHash][toChainId];
        require(toAssetHash.length != 0, "empty illegal toAssetHash");

        {
            TxArgs memory txArgs = TxArgs({
                toAssetHash: toAssetHash,
                toAddress: toAddress,
                amount: amount,
                callData: callData
            });
            bytes memory txData = _serializeTxArgs(txArgs);

            IEthCrossChainManager eccm = IEthCrossChainManager(getCrossChainManagerAddress());

            bytes memory targetBridge = bridgeHashMap[toChainId];
            require(targetBridge.length != 0, "empty illegal targetBridge");
            require(eccm.crossChain(toChainId, targetBridge, "bridgeIn", txData), "EthCrossChainManager crossChain executed error!");
        }

        emit LockEvent(fromAssetHash, _msgSender(), toChainId, toAssetHash, toAddress, amount);

        return true;
    }

    function bridgeIn(
        bytes memory argsBs,
        bytes memory fromContractAddr,
        uint64 fromChainId
    ) onlyManagerContract public nonReentrant whenNotPaused returns (bool) {
        TxArgs memory args = _deserializeTxArgs(argsBs);

        require(fromContractAddr.length != 0, "from proxy contract address cannot be empty");
        require(Utils.equalStorage(bridgeHashMap[fromChainId], fromContractAddr), "From Proxy contract address error!");

        require(args.toAssetHash.length != 0, "toAssetHash cannot be empty");
        address toAssetHash = Utils.bytesToAddress(args.toAssetHash);

        require(args.toAddress.length != 0, "toAddress cannot be empty");
        address toAddress = Utils.bytesToAddress(args.toAddress);

        if (args.callData.length == 0 || callProxy == address(0)) {
            require(_mintTo(toAssetHash, toAddress, args.amount), "mint ptoken to user failed");
        } else {
            require(_mintTo(toAssetHash, callProxy, args.amount), "mint ptoken to callProxy failed");
            require(ICallProxy(callProxy).proxyCall(toAssetHash, toAddress, args.amount, args.callData), "execute callData via callProxy failed");
        }

        emit UnlockEvent(toAssetHash, toAddress, args.amount);

        return true;
    }

    function _chargeFee(address assetHash, address fromAddress, address toAddress, uint256 amount) internal returns (bool) {
        IERC20(assetHash).safeTransferFrom(fromAddress, toAddress, amount);
        return true;
    }

    function _burnFrom(address fromAssetHash, address fromAddress , uint256 amount) internal returns (bool) {
        IERC20(fromAssetHash).safeTransferFrom(fromAddress, address(this), amount);
        IPToken(fromAssetHash).burn(amount);
        return true;
    }

    function _mintTo(address toAssetHash, address toAddress, uint256 amount) internal returns (bool) {
        IPToken(toAssetHash).mint(toAddress, amount);
        return true;
    }

    function getCrossChainManagerAddress() public view returns(address) {
        IEthCrossChainManagerProxy eccmp = IEthCrossChainManagerProxy(managerProxyContract);
        return eccmp.getEthCrossChainManager();
    }

    function _serializeTxArgs(TxArgs memory args) internal pure returns (bytes memory) {
        bytes memory buff;
        buff = abi.encodePacked(
            Utils.WriteVarBytes(args.toAssetHash),
            Utils.WriteVarBytes(args.toAddress),
            Utils.WriteUint255(args.amount),
            Utils.WriteVarBytes(args.callData)
            );
        return buff;
    }

    function _deserializeTxArgs(bytes memory valueBs) internal pure returns (TxArgs memory) {
        TxArgs memory args;
        uint256 off = 0;
        (args.toAssetHash, off) = Utils.NextVarBytes(valueBs, off);
        (args.toAddress, off) = Utils.NextVarBytes(valueBs, off);
        (args.amount, off) = Utils.NextUint255(valueBs, off);
        (args.callData, off) = Utils.NextVarBytes(valueBs, off);
        return args;
    }
}