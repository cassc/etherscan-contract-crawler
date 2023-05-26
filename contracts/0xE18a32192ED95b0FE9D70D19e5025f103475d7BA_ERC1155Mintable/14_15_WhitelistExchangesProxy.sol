pragma solidity ^0.7.0;

import "./mixin/MixinOwnable.sol";

contract WhitelistExchangesProxy is Ownable {
    mapping(address => bool) internal proxies;

    bool public paused = true;
    
    function setPaused(bool newPaused) external onlyOwner() {
        paused = newPaused;
    }

    function updateProxyAddress(address proxy, bool status) external onlyOwner() {
        proxies[proxy] = status;
    }

    function isAddressWhitelisted(address proxy) external view returns (bool) {
        if (paused) {
            return false;
        } else {
            return proxies[proxy];
        }
    }
}