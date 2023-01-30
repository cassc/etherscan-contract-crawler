// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OFTCoreV2.sol";
import "./IOFTV2.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract BaseOFTV2 is OFTCoreV2, ERC165, IOFTV2 {

    address public treasure;
    uint public fee;

    constructor(uint8 _sharedDecimals, address _lzEndpoint) OFTCoreV2(_sharedDecimals, _lzEndpoint) {
    }

    modifier checkFee(){
        require( msg.value >= fee, "F");
        if( msg.value > 0 && fee > 0 ){
            (bool status,) = payable(treasure).call{value: fee}("");
            require(status);
        }
        _;
    }

    function setTreasure(address _treasure) external onlyOwner {
        require(_treasure != address(0));
        treasure = _treasure;
    }

    /************************************************************************
    * public functions
    ************************************************************************/
    function sendFrom(address _from, uint16 _dstChainId, bytes32 _toAddress, uint _amount, LzCallParams calldata _callParams) public payable checkFee virtual override {
        uint _nativeFee = msg.value - fee;
        _send(_from, _dstChainId, _toAddress, _amount, _callParams.refundAddress, _callParams.zroPaymentAddress, _callParams.adapterParams, _nativeFee);
    }

    function sendAndCall(address _from, uint16 _dstChainId, bytes32 _toAddress, uint _amount, bytes calldata _payload, uint64 _dstGasForCall, LzCallParams calldata _callParams) public payable checkFee virtual override {
        uint _nativeFee = msg.value - fee;
        _sendAndCall(_from, _dstChainId, _toAddress, _amount, _payload, _dstGasForCall, _callParams.refundAddress, _callParams.zroPaymentAddress, _callParams.adapterParams, _nativeFee);
    }

    /************************************************************************
    * public view functions
    ************************************************************************/
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IOFTV2).interfaceId || super.supportsInterface(interfaceId);
    }

    function estimateSendFee(uint16 _dstChainId, bytes32 _toAddress, uint _amount, bool _useZro, bytes calldata _adapterParams) public view virtual override returns (uint nativeFee, uint zroFee) {
        (uint nativeFee, uint zroFee) = _estimateSendFee(_dstChainId, _toAddress, _amount, _useZro, _adapterParams);
        return (nativeFee + fee, zroFee);
    }

    function estimateSendAndCallFee(uint16 _dstChainId, bytes32 _toAddress, uint _amount, bytes calldata _payload, uint64 _dstGasForCall, bool _useZro, bytes calldata _adapterParams) public view virtual override returns (uint nativeFee, uint zroFee) {
        (uint nativeFee, uint zroFee) = _estimateSendAndCallFee(_dstChainId, _toAddress, _amount, _payload, _dstGasForCall, _useZro, _adapterParams);
        return (nativeFee + fee, zroFee);
    }

    function circulatingSupply() public view virtual override returns (uint);

    function token() public view virtual override returns (address);
}