pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

// Contracts
import "../MarketRegistry.sol";

contract MarketRegistry__Goerli_TellerAS_Fix is MarketRegistry {
    function setTellerAS(address _tellerAS) external {
        require(
            address(tellerAS) == address(0),
            "MarketRegistry: TellerAS already set"
        );
        tellerAS = TellerAS(_tellerAS);
    }
}