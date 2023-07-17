// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./interfaces/IZkEvmBridge.sol";
import "./interfaces/IvlCVX.sol";

contract CommitUserSurrogate {

    bytes4 private constant updateSelector = bytes4(keccak256("updateUserSurrogate(address,address,uint256)"));
    address public constant bridge = address(0x2a3DD3EB832aF982ec71669E178424b10Dca2EDe);

    function commit(
        address _surrogate,
        address _contractAddr
    ) external  {

        //build data
        bytes memory data = abi.encodeWithSelector(updateSelector, msg.sender, _surrogate, block.timestamp);

        //submit to L2
        uint32 destinationNetwork = 1;
        bool forceUpdateGlobalExitRoot = true;
        IZkEvmBridge(bridge).bridgeMessage{value:0}(
            destinationNetwork,
            _contractAddr,
            forceUpdateGlobalExitRoot,
            data
        );
    }
}