// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../ERC4626Strategy.sol";

contract InstadappLiteETHV2Strategy is ERC4626Strategy {
    address internal constant ETHV2Vault = 0xA0D3707c569ff8C87FA923d3823eC5D81c98Be78;
    address internal constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    // @notice these 3 vars are not used anymore, 
    // kept for storage compatibility
    uint256 internal lastPriceTimestamp;
    uint256 internal lastPrice;
    uint256 internal lastApr;

    function initialize(address _owner) public {
        _initialize(ETHV2Vault, STETH, _owner);
    }

    // @notice apr is calculated in the client directly for this strategy
    // so we return 0 here
    function getApr() external pure override returns (uint256) {}
}