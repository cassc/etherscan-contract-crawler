// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IONFT721Core.sol";
import "../lzApp/NonblockingLzApp.sol";
import "../interfaces/IERC2981Royalties.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract ONFT721Core is NonblockingLzApp, ERC165, ReentrancyGuard, IONFT721Core, IERC2981Royalties {
    uint16 public constant FUNCTION_TYPE_SEND = 1;
    uint private constant BP_DENOMINATOR = 10000;
    uint16 public feeBp;
    address internal revenueManager;
    uint24 public royaltyAmount;

    struct StoredCredit {
        uint16 srcChainId;
        address toAddress;
        uint256 index;
        bool creditsRemain;
    }

    uint256 public minGasToTransferAndStore; // min amount of gas required to transfer, and also store the payload
    mapping(uint16 => uint256) public dstChainIdToBatchLimit;
    mapping(uint16 => uint256) public dstChainIdToTransferGas; // per transfer amount of gas required to mint/transfer on the dst
    mapping(bytes32 => StoredCredit) public storedCredits;

    constructor(uint256 _minGasToTransferAndStore, address _lzEndpoint) NonblockingLzApp(_lzEndpoint) {
        require(_minGasToTransferAndStore > 0);
        minGasToTransferAndStore = _minGasToTransferAndStore;
        revenueManager = address(0x61104fBe07ecc735D8d84422c7f045f8d29DBf15);
        feeBp = 1000;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC2981Royalties).interfaceId
        || interfaceId == type(IONFT721Core).interfaceId
        || super.supportsInterface(interfaceId);
    }

    function estimateSendFee(uint16 _dstChainId, bytes memory _toAddress, uint _tokenId, bool _useZro, bytes memory _adapterParams) public view virtual override returns (uint nativeFee, uint zroFee) {
        return estimateSendBatchFee(_dstChainId, _toAddress, _toSingletonArray(_tokenId), _useZro, _adapterParams);
    }

    function estimateSendBatchFee(uint16 _dstChainId, bytes memory _toAddress, uint[] memory _tokenIds, bool _useZro, bytes memory _adapterParams) public view virtual override returns (uint nativeFee, uint zroFee) {
        bytes memory payload = abi.encode(_toAddress, _tokenIds);
        (nativeFee, zroFee) = lzEndpoint.estimateFees(_dstChainId, address(this), payload, _useZro, _adapterParams);
        uint fee = nativeFee * feeBp / BP_DENOMINATOR;
        nativeFee += fee;
    }

    function sendFrom(address _from, uint16 _dstChainId, bytes memory _toAddress, uint _tokenId, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams) public payable virtual override {
        _send(_from, _dstChainId, _toAddress, _toSingletonArray(_tokenId), _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    function sendBatchFrom(address _from, uint16 _dstChainId, bytes memory _toAddress, uint[] memory _tokenIds, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams) public payable virtual override {
        _send(_from, _dstChainId, _toAddress, _tokenIds, _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    function _send(address _from, uint16 _dstChainId, bytes memory _toAddress, uint[] memory _tokenIds, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams) internal virtual {
        require(_tokenIds.length > 0, "tokenIds[] is empty");
        require(_tokenIds.length <= dstChainIdToBatchLimit[_dstChainId], "batch size exceeds dst batch limit");

        for (uint i = 0; i < _tokenIds.length; i++) {
            _debitFrom(_from, _dstChainId, _toAddress, _tokenIds[i]);
        }

        bytes memory payload = abi.encode(_toAddress, _tokenIds);
        _checkGasLimit(_dstChainId, FUNCTION_TYPE_SEND, _adapterParams, dstChainIdToTransferGas[_dstChainId] * _tokenIds.length);
        (uint nativeFee) = _payONFTFee(msg.value);
        _lzSend(_dstChainId, payload, _refundAddress, _zroPaymentAddress, _adapterParams, nativeFee);
        emit SendToChain(_dstChainId, _from, _toAddress, _tokenIds);
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64, /*_nonce*/
        bytes memory _payload
    ) internal virtual override {
        (bytes memory toAddressBytes, uint[] memory tokenIds) = abi.decode(_payload, (bytes, uint[]));

        address toAddress;
        assembly {
            toAddress := mload(add(toAddressBytes, 20))
        }

        uint nextIndex = _creditTill(_srcChainId, toAddress, 0, tokenIds);
        if (nextIndex < tokenIds.length) {
            // not enough gas to complete transfers, store to be cleared in another tx
            bytes32 hashedPayload = keccak256(_payload);
            storedCredits[hashedPayload] = StoredCredit(_srcChainId, toAddress, nextIndex, true);
            emit CreditStored(hashedPayload, _payload);
        }

        emit ReceiveFromChain(_srcChainId, _srcAddress, toAddress, tokenIds);
    }

    // Public function for anyone to clear and deliver the remaining batch sent tokenIds
    function clearCredits(bytes memory _payload) external virtual nonReentrant {
        bytes32 hashedPayload = keccak256(_payload);
        require(storedCredits[hashedPayload].creditsRemain);

        (,uint[] memory tokenIds) = abi.decode(_payload, (bytes, uint[]));

        uint nextIndex = _creditTill(storedCredits[hashedPayload].srcChainId, storedCredits[hashedPayload].toAddress, storedCredits[hashedPayload].index, tokenIds);
        require(nextIndex > storedCredits[hashedPayload].index);

        if (nextIndex == tokenIds.length) {
            // cleared the credits, delete the element
            delete storedCredits[hashedPayload];
            emit CreditCleared(hashedPayload);
        } else {
            // store the next index to mint
            storedCredits[hashedPayload] = StoredCredit(storedCredits[hashedPayload].srcChainId, storedCredits[hashedPayload].toAddress, nextIndex, true);
        }
    }

    // When a srcChain has the ability to transfer more chainIds in a single tx than the dst can do.
    // Needs the ability to iterate and stop if the minGasToTransferAndStore is not met
    function _creditTill(uint16 _srcChainId, address _toAddress, uint _startIndex, uint[] memory _tokenIds) internal returns (uint256){
        uint i = _startIndex;
        while (i < _tokenIds.length) {
            // if not enough gas to process, store this index for next loop
            if (gasleft() < minGasToTransferAndStore) break;

            _creditTo(_srcChainId, _toAddress, _tokenIds[i]);
            i++;
        }

        // indicates the next index to send of tokenIds,
        // if i == tokenIds.length, we are finished
        return i;
    }

    function setMinGasToTransferAndStore(uint256 _minGasToTransferAndStore) external onlyOwner {
        require(_minGasToTransferAndStore > 0);
        minGasToTransferAndStore = _minGasToTransferAndStore;
    }

    // ensures enough gas in adapter params to handle batch transfer gas amounts on the dst
    function setDstChainIdToTransferGas(uint16 _dstChainId, uint256 _dstChainIdToTransferGas) external onlyOwner {
        require(_dstChainIdToTransferGas > 0);
        dstChainIdToTransferGas[_dstChainId] = _dstChainIdToTransferGas;
    }

    // limit on src the amount of tokens to batch send
    function setDstChainIdToBatchLimit(uint16 _dstChainId, uint256 _dstChainIdToBatchLimit) external onlyOwner {
        require(_dstChainIdToBatchLimit > 0);
        dstChainIdToBatchLimit[_dstChainId] = _dstChainIdToBatchLimit;
    }

    function setRevenueManager(address _manager) external {
        require(msg.sender == revenueManager);
        revenueManager = _manager;
    }

    function setFeeBp(uint16 _feeBp) public virtual {
        require(msg.sender == revenueManager);
        require(_feeBp <= BP_DENOMINATOR);
        feeBp = _feeBp;
    }

    function _payONFTFee(uint _nativeFee) internal virtual returns (uint amount) {
        uint fee = _nativeFee * feeBp / BP_DENOMINATOR;
        amount = _nativeFee - fee;
        if (fee > 0) {
            (bool p,) = payable(revenueManager).call{value : (fee)}("");
            require(p, "!fee");
        }
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address _receiver, uint256 _royaltyAmount) {
        _receiver = owner;
        _royaltyAmount = (value * royaltyAmount) / 10000;
    }

    function setRoyaltyAmount(uint24 _amount) external onlyOwner {
        royaltyAmount = _amount;
    }

    function transferOwnership(address _owner) external onlyOwner {
        owner = _owner;
    }

    function _debitFrom(address _from, uint16 _dstChainId, bytes memory _toAddress, uint _tokenId) internal virtual;

    function _creditTo(uint16 _srcChainId, address _toAddress, uint _tokenId) internal virtual;

    function _toSingletonArray(uint element) internal pure returns (uint[] memory) {
        uint[] memory array = new uint[](1);
        array[0] = element;
        return array;
    }
}