// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ProxyRegistry} from "./ProxyRegistry.sol";
import {IAllowsProxy} from "./IAllowsProxy.sol";

///@notice Checks approval against a single proxy address configured at deploy for gas-free trading on a marketplace
contract AllowsImmutableProxy is IAllowsProxy, Ownable {
    address internal immutable proxyAddress_;
    bool internal isProxyActive_;

    constructor(address _proxyAddress, bool _isProxyActive) {
        proxyAddress_ = _proxyAddress;
        isProxyActive_ = _isProxyActive;
    }

    ///@notice toggles proxy check in isApprovedForProxy. Proxy can be disabled in emergency circumstances. OnlyOwner
    function setIsProxyActive(bool _isProxyActive) external onlyOwner {
        isProxyActive_ = _isProxyActive;
    }

    function proxyAddress() public view returns (address) {
        return proxyAddress_;
    }

    function isProxyActive() public view returns (bool) {
        return isProxyActive_;
    }

    ///@dev to be used in conjunction with isApprovedForAll in token contracts
    ///@param _owner address of token owner
    ///@param _operator address of operator
    ///@return bool true if operator is approved
    function isApprovedForProxy(address _owner, address _operator)
        public
        view
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyAddress_);
        if (
            isProxyActive_ &&
            address(proxyRegistry.proxies(_owner)) == _operator
        ) {
            return true;
        }
        return false;
    }
}