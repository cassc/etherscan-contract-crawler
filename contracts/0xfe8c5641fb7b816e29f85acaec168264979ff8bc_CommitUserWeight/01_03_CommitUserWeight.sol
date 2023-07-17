// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./interfaces/IZkEvmBridge.sol";
import "./interfaces/IvlCVX.sol";

contract CommitUserWeight {

    bytes4 private constant updateSelector = bytes4(keccak256("updateWeight(address,address,uint256,uint256,uint256)"));
    address public constant vlcvx = address(0x72a19342e8F1838460eBFCCEf09F6585e32db86E);
    address public constant bridge = address(0x2a3DD3EB832aF982ec71669E178424b10Dca2EDe);
    uint256 public constant epochDuration = 86400 * 7;

    function currentEpoch() public view returns (uint256) {
        return block.timestamp/epochDuration*epochDuration;
    }

    function commit(
        address _votingAddress,
        address _userAddress,
        uint256 _proposalId,
        address _contractAddr
    ) external  {
        //make sure vlcvx is checkpointed
        IvlCVX(vlcvx).checkpointEpoch();

        //get vlcvx balance
        uint256 balance = IvlCVX(vlcvx).balanceOf(_userAddress);

        //build data
        bytes memory data = abi.encodeWithSelector(updateSelector, _votingAddress, _userAddress, currentEpoch(), _proposalId, balance);

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