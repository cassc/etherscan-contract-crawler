// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma abicoder v2;

import "@layerzero/contracts/lzApp/NonblockingLzApp.sol";
import "./interfaces/IDemoToken.sol";

/// @title A LayerZero example sending a cross chain message from a source chain to a destination chain to increment a counter
contract Portal is NonblockingLzApp {

    uint256 gas = 350000;
    IDemoToken iDemoToken = IDemoToken(0x87e143018574F86612352C73ADBfc781eC3f2303);

    constructor(address _lzEndpoint) NonblockingLzApp(_lzEndpoint) {}

    function _nonblockingLzReceive(uint16, bytes memory, uint64, bytes memory _payload) internal override {
        (address toAddress, uint256 amount) = abi.decode(
            _payload,
            (address, uint256)
        );

        iDemoToken.mint(toAddress, amount);
    }

    function bridgeToken(uint16 _dstChainId, uint _amount) public payable {
       iDemoToken.burn(msg.sender, _amount);
       bytes memory payload = abi.encode(msg.sender, _amount);

       uint16 version = 1;
       bytes memory adapterParams = abi.encodePacked(version, gas);
    
       (uint256 messageFee, ) = lzEndpoint.estimateFees(
            _dstChainId,
            address(this),
            payload,
            false,
            adapterParams
        );

        require(
            msg.value >= messageFee,
            "Must send enough value to cover messageFee"
        );

        _lzSend(_dstChainId, payload, payable(msg.sender), address(0x0), adapterParams);
    }

}