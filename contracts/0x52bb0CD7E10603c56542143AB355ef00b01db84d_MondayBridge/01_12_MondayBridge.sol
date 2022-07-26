// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/ILayerZeroReceiver.sol";
import "./interfaces/ILayerZeroEndpoint.sol";
import "./MondayClubToken.sol";
import "./lzApp/NonblockingLzApp.sol";

contract MondayBridge is NonblockingLzApp {

    MondayClubToken public mondayToken;
    event SendToChain(address indexed _sender, uint16 indexed _dstChainId, address indexed _toAddress, uint _amount, uint64 _nonce);

    event ReceiveFromChain(uint16 indexed _srcChainId, bytes indexed _srcAddress, address indexed _toAddress, uint _amount, uint64 _nonce);

    constructor(address _lzEndpoint) NonblockingLzApp(_lzEndpoint) {}

    function setToken(address _mondayToken) onlyOwner external {
        mondayToken = MondayClubToken(_mondayToken);
    }

    function sendCrossChain(uint16 _dstChainId, uint _amount) public payable {
        require(mondayToken.balanceOf(msg.sender) >= _amount,"not enuf balance");
        (uint256 messageFee, ) = estimateSendFee(_dstChainId, _amount);

        require( msg.value >= messageFee,"not enough messageFee");

        mondayToken.bridgeBurn(msg.sender, _amount);

        bytes memory payload = abi.encode(msg.sender, _amount);
        _lzSend(_dstChainId, payload, payable(msg.sender), address(0x0), bytes(""));

        uint64 nonce = lzEndpoint.getOutboundNonce(_dstChainId, address(this));
        
        emit SendToChain(msg.sender, _dstChainId, msg.sender, _amount, nonce);
    }

    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override {
     
        (address toAddress, uint256 amount) = abi.decode(_payload,(address, uint256));

        mondayToken.bridgeMint(toAddress, amount);

        emit ReceiveFromChain(_srcChainId, _srcAddress, toAddress, amount, _nonce);
    }

    function estimateSendFee(uint16 _dstChainId, uint _amount) public view virtual returns (uint nativeFee, uint zroFee) {
        bytes memory payload = abi.encode(msg.sender, _amount);
        return lzEndpoint.estimateFees(_dstChainId, address(this), payload, false, bytes(""));
    }

}