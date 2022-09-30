// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./external/polygon/IRootChainManager.sol";
import "./external/optimism/IL1StandardBridge.sol";

import "./external/openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "./external/IWETH.sol";

contract BridgeTester2 {

    IWETH constant public weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    function bridgeToPolygon(address token, uint amount, bytes calldata bridgeData) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        address bridge = abi.decode(bridgeData, (address));
        _bridgeToPolygon(bridge, msg.sender, token, amount);
    }

    function bridgeToOptimism(address token, uint amount, bytes calldata bridgeData) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        (address bridge, address tokenL2) = abi.decode(bridgeData, (address, address));
        _bridgeToOptimism(bridge, msg.sender, token, tokenL2, amount);
    }

    function _bridgeToPolygon(address bridge, address to, address tokenL1, uint amount) internal {
        if (bridge != address(0)) {
            IRootChainManager manager = IRootChainManager(bridge);
            bytes32 t = manager.tokenToType(tokenL1);
            address predicate = manager.typeToPredicate(t);
            
            if (predicate != address(0)) {
                IERC20(tokenL1).approve(predicate, amount);
                IRootChainManager(bridge).depositFor(to, tokenL1, abi.encode(amount));
            } else {
                revert("missing bridge token");
            }
        } else {
            revert("missing bridge data");
        }
    }

    function _bridgeToOptimism(address bridge, address to, address tokenL1, address tokenL2, uint amount) internal {
        if (bridge != address(0)) {
            if (tokenL1 == address(weth)) {
                weth.withdraw(amount);
                IL1StandardBridge(bridge).depositETHTo{value: amount}(to, 200_000, "");
            } else {
                if (tokenL2 != address(0)) {
                    IERC20(tokenL1).approve(bridge, amount);
                    IL1StandardBridge(bridge).depositERC20To(address(tokenL1), tokenL2, to, amount, 200_000, "");
                } else {
                    revert("missing bridge token");
                }
            }
        } else {
            revert("missing bridge data");
        }
    }

    // for WETH unwrapping
    receive() external payable {}
}