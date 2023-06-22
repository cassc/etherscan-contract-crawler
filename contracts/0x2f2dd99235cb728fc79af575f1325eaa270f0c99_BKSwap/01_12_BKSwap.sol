//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./BKCommon.sol";
import "./interfaces/IBKRegistry.sol";

contract BKSwap is BKCommon {
    address public bkRegistry;
    mapping(address => bool) public isCaller;

    event ManagerCaller(address operator, address caller, bool isCaller);
    event SetRegistry(address operator, address bkRegistry);

    constructor(address _bkRegistry, address _owner) {
        bkRegistry = _bkRegistry;
        emit SetRegistry(msg.sender, _bkRegistry);
        _transferOwnership(_owner);
    }
    
    function setRegistry(address _bkRegistry) external whenNotPaused onlyOwner {
        bkRegistry = _bkRegistry;
        emit SetRegistry(msg.sender, _bkRegistry);
    }

    function managerCaller(address _caller, bool _isCaller) external onlyOwner {
        isCaller[_caller] = _isCaller;
        emit ManagerCaller(msg.sender, _caller, _isCaller);
    }

    fallback() external payable whenNotPaused nonReentrant {
        if(!isCaller[msg.sender]) {
            revert InvalidCaller();
        }

        if (msg.sig.length != 4) {
            revert InvalidMsgSig();
        }

        (address proxy, bool isLib) = IBKRegistry(bkRegistry).getFeature(msg.sig);

        (bool success, bytes memory resultData) = isLib
            ? proxy.delegatecall(msg.data)
            : proxy.call{value: msg.value}(msg.data);

        if (!success) {
            _revertWithData(resultData);
        }
    }
}