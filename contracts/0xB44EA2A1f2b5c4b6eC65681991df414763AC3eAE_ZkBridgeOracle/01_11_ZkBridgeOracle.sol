// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import "../interface/ILayerZeroOracleV2.sol";
import "../interface/IBlockUpdater.sol";
import "../interface/ILayerZeroEndpoint.sol";
import "../interface/ILayerZeroUltraLightNodeV2.sol";
import "../interface/IZKMptValidator.sol";


contract ZkBridgeOracle is ILayerZeroOracleV2, Initializable, OwnableUpgradeable {
    event OracleNotified(uint16 dstChainId, uint16 proofType, uint blockConfirmations, address uln, uint fee);
    event WithdrawFee(address receiver, uint256 amount);
    event SetFee(uint16 dstChainId, uint16 proofType, uint256 fee);
    event RemoveFee(uint16 dstChainId, uint16 proofType);
    event ModBlockUpdater(uint16 sourceChainId, address oldBlockUpdater, address newBlockUpdater);
    event ModZKMptValidator(address oldZKMptValidator, address newZKMptValidator);
    event ModLayerZeroEndpoint(address oldLayerZeroEndpoint, address newLayerZeroEndpoint);
    event EnableSupportedDstChain(uint16 _proofType, uint16 dstChainId);
    event DisableSupportedDstChain(uint16 _proofType, uint16 dstChainId);

    ILayerZeroEndpoint public layerZeroEndpoint;

    // proofType=>chainId=>price
    mapping(uint16 => mapping(uint16 => uint)) public chainPriceLookup;

    // proofType=>chainId=>bool
    mapping(uint16 => mapping(uint16 => bool)) public supportedDstChain;

    // chainId=>blockUpdater
    mapping(uint16 => IBlockUpdater) public blockUpdaters;

    IZKMptValidator public zkMptValidator;

    EnumerableSet.AddressSet private lzUln;

    function initialize(address _layerZeroEndpoint) public initializer {
        require(_layerZeroEndpoint != address(0), "ZkBridgeOracle:Zero address");
        layerZeroEndpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
        __Ownable_init();
    }

    function updateMptHash(uint16 _sourceChainId, bytes32 _blockHash, bytes32 _receiptHash, address _userApplication) external {
        _updateHash(_sourceChainId, _blockHash, _receiptHash, _blockHash, _receiptHash, _userApplication);
    }

    function batchUpdateMptHash(uint16[] calldata _sourceChainIds, bytes32[] calldata _blockHashes, bytes32[] calldata _receiptHashes, address[] calldata _userApplications) external {
        require(_sourceChainIds.length == _blockHashes.length, "ZkBridgeOracle:Parameter lengths must be the same");
        require(_sourceChainIds.length == _receiptHashes.length, "ZkBridgeOracle:Parameter lengths must be the same");
        require(_sourceChainIds.length == _userApplications.length, "ZkBridgeOracle:Parameter lengths must be the same");
        for (uint256 i = 0; i < _sourceChainIds.length; i++) {
            _updateHash(_sourceChainIds[i], _blockHashes[i], _receiptHashes[i], _blockHashes[i], _receiptHashes[i], _userApplications[i]);
        }
    }

    function updateFpHash(uint16 _sourceChainId, bytes32 _blockHash, bytes calldata zkMptProof, address _userApplication) external {
        require(address(zkMptValidator)!=address(0),"ZkBridgeOracle:Not set zkMptValidator");
        IZKMptValidator.Receipt memory receipt = zkMptValidator.validateMPT(zkMptProof);
        _updateHash(_sourceChainId, _blockHash, receipt.receiptHash, receipt.logsHash, receipt.logsHash, _userApplication);
    }

    function batchUpdateFpHash(uint16[] calldata _sourceChainIds, bytes32[] calldata _blockHashes, bytes[] calldata zkMptProofs, address[] calldata _userApplications) external {
        require(address(zkMptValidator)!=address(0),"ZkBridgeOracle:Not set zkMptValidator");
        require(_sourceChainIds.length == _blockHashes.length, "ZkBridgeOracle:Parameter lengths must be the same");
        require(_sourceChainIds.length == zkMptProofs.length, "ZkBridgeOracle:Parameter lengths must be the same");
        require(_sourceChainIds.length == _userApplications.length, "ZkBridgeOracle:Parameter lengths must be the same");
        IZKMptValidator.Receipt memory receipt;
        for (uint256 i = 0; i < _sourceChainIds.length; i++) {
            receipt = zkMptValidator.validateMPT(zkMptProofs[i]);
            _updateHash(_sourceChainIds[i], _blockHashes[i], receipt.receiptHash, receipt.logsHash, receipt.logsHash, _userApplications[i]);
        }
    }

    function assignJob(uint16 _dstChainId, uint16 _proofType, uint64 _outboundBlockConfirmation, address _userApplication) external override returns (uint price){
        require(supportedDstChain[_proofType][_dstChainId], "ZkBridgeOracle:Unsupported dest chain");
        require(isSupportedUln(msg.sender), "ZkBridgeOracle:Unsupported user application uln");
        price = chainPriceLookup[_proofType][_dstChainId];
        emit OracleNotified(_dstChainId, _proofType, _outboundBlockConfirmation, msg.sender, price);
    }

    function getFee(uint16 _dstChainId, uint16 _proofType, uint64 _outboundBlockConfirmation, address _userApplication) external override view returns (uint price){
        price = chainPriceLookup[_proofType][_dstChainId];
    }

    function hashLookup(uint16 _srcChainId, bytes32 _blockHash, bytes32 _blockData, address _userApplication) external view returns (uint256 confirmation){
        address uln = layerZeroEndpoint.getReceiveLibraryAddress(_userApplication);
        confirmation = ILayerZeroUltraLightNodeV2(uln).hashLookup(address(this), _srcChainId, _blockHash, _blockData);
    }

    function feeBalance() public view returns (uint256 balance){
        for (uint256 i = 0; i < getLzUlnLength(); i++) {
            uint256 ulnBalance = ILayerZeroUltraLightNodeV2(getLzUln(i)).accruedNativeFee(address(this));
            balance += ulnBalance;
        }
    }

    function isSupportedUln(address _uln) public view returns (bool) {
        return EnumerableSet.contains(lzUln, _uln);
    }

    function getLzUlnLength() public view returns (uint256) {
        return EnumerableSet.length(lzUln);
    }

    function getLzUln(uint256 _index) public view returns (address){
        require(_index <= getLzUlnLength() - 1, "ZkBridgeOracle:index out of bounds");
        return EnumerableSet.at(lzUln, _index);
    }


    function _updateHash(uint16 _sourceChainId, bytes32 _blockHash, bytes32 _receiptHash, bytes32 _lookupHash, bytes32 _blockData, address _userApplication) internal {
        IBlockUpdater blockUpdater = blockUpdaters[_sourceChainId];
        require(address(blockUpdater) != address(0), "ZkBridgeOracle:Unsupported source chain");
        (bool exist,uint256 blockConfirmation) = blockUpdater.checkBlockConfirmation(_blockHash, _receiptHash);
        require(exist, "ZkBridgeOracle:Block Data is not set");
        address uln = layerZeroEndpoint.getReceiveLibraryAddress(_userApplication);
        require(isSupportedUln(uln), "ZkBridgeOracle:Unsupported user application uln");
        ILayerZeroUltraLightNodeV2(uln).updateHash(_sourceChainId, _lookupHash, blockConfirmation, _blockData);
    }

    //----------------------------------------------------------------------------------
    // onlyOwner
    function enableSupportedDstChain(uint16 _proofType, uint16 _dstChainId) external onlyOwner {
        supportedDstChain[_proofType][_dstChainId] = true;
        emit EnableSupportedDstChain(_proofType, _dstChainId);
    }

    function disableSupportedDstChain(uint16 _proofType, uint16 _dstChainId) external onlyOwner {
        supportedDstChain[_proofType][_dstChainId] = false;
        emit DisableSupportedDstChain(_proofType, _dstChainId);
    }

    function addLzUln(address _lzUln) external onlyOwner {
        require(_lzUln != address(0), "ZkBridgeOracle:Zero address");
        require(!isSupportedUln(_lzUln), "ZkBridgeOracle:The uln is already exist");
        EnumerableSet.add(lzUln, _lzUln);
    }

    function removeLzUln(address _lzUln) external onlyOwner {
        require(_lzUln != address(0), "ZkBridgeOracle:Zero address");
        require(isSupportedUln(_lzUln), "ZkBridgeOracle:The uln is already remove");
        EnumerableSet.remove(lzUln, _lzUln);
    }

    function setFee(uint16 _dstChainId, uint16 _proofType, uint _price) external onlyOwner {
        require(_price > 0, "ZkBridgeOracle:Price must be greater than zero.");
        chainPriceLookup[_proofType][_dstChainId] = _price;
        emit SetFee(_proofType, _dstChainId, _price);
    }

    function removeFee(uint16 _dstChainId, uint16 _proofType) external onlyOwner {
        require(chainPriceLookup[_proofType][_dstChainId] > 0, "ZkBridgeOracle:The price is already 0.");
        chainPriceLookup[_proofType][_dstChainId] = 0;
        emit RemoveFee(_dstChainId, _proofType);
    }

    function withdrawFee(address payable _to, uint _amount) external override onlyOwner {
        require(feeBalance() >= _amount, "ZkBridgeOracle:Insufficient Balance");
        uint256 surplusAmount = _amount;
        for (uint256 i = 0; i < getLzUlnLength(); i++) {
            uint256 ulnBalance = ILayerZeroUltraLightNodeV2(getLzUln(i)).accruedNativeFee(address(this));
            if (ulnBalance > 0) {
                if (ulnBalance >= surplusAmount) {
                    ILayerZeroUltraLightNodeV2(getLzUln(i)).withdrawNative(_to, surplusAmount);
                    break;
                } else {
                    ILayerZeroUltraLightNodeV2(getLzUln(i)).withdrawNative(_to, ulnBalance);
                }
            }
            surplusAmount = surplusAmount - ulnBalance;
        }
        emit WithdrawFee(_to, _amount);
    }

    function setBlockUpdater(uint16 _sourceChainId, address _blockUpdater) external onlyOwner {
        require(_blockUpdater != address(0), "ZkBridgeOracle:Zero address");
        emit ModBlockUpdater(_sourceChainId, address(blockUpdaters[_sourceChainId]), _blockUpdater);
        blockUpdaters[_sourceChainId] = IBlockUpdater(_blockUpdater);
    }

    function setZKMptValidator(address _zkMptValidator) external onlyOwner {
        require(_zkMptValidator != address(0), "ZkBridgeOracle:Zero address");
        emit ModZKMptValidator(address(zkMptValidator), _zkMptValidator);
        zkMptValidator = IZKMptValidator(_zkMptValidator);
    }

    function setLayerZeroEndpoint(address _layerZeroEndpoint) external onlyOwner {
        require(_layerZeroEndpoint != address(0), "ZkBridgeOracle:Zero address");
        emit ModLayerZeroEndpoint(address(_layerZeroEndpoint), _layerZeroEndpoint);
        layerZeroEndpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
    }

}