// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./interfaces/ICurveGauge.sol";
import "./interfaces/IGaugeController.sol";
import "./interfaces/IZkEvmBridge.sol";

contract CommitGaugeStatus {

    bytes4 private constant updateSelector = bytes4(keccak256("setGauge(address,bool,uint256)"));
    address public constant gaugeController = address(0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB);
    address public constant bridge = address(0x2a3DD3EB832aF982ec71669E178424b10Dca2EDe);
    uint256 public constant epochDuration = 86400 * 7;
    
    function currentEpoch() public view returns (uint256) {
        return block.timestamp/epochDuration*epochDuration;
    }

    function commit(
        address _gauge,
        address _contractAddr
    ) external  {
        //check killed for status
        bool active = isValidGauge(_gauge);

        //build data
        bytes memory data = abi.encodeWithSelector(updateSelector, _gauge, active, currentEpoch());

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

    function isValidGauge(address _gauge) public view returns(bool){
        return IGaugeController(gaugeController).get_gauge_weight(_gauge) > 0 && !ICurveGauge(_gauge).is_killed();
    }
}