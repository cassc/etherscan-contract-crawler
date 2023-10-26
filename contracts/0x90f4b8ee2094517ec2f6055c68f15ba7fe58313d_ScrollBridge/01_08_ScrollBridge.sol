pragma solidity ^0.8.9;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IScrollGateway.sol";
import "./interfaces/IL2GasOracle.sol";

// https://onthis.xyz
/*
 .d88b.  d8b   db d888888b db   db d888888b .d8888. 
.8P  Y8. 888o  88    88    88   88    88    88   YP 
88    88 88V8o 88    88    88ooo88    88     8bo.   
88    88 88 V8o88    88    88   88    88       Y8b. 
`8b  d8' 88  V888    88    88   88    88    db   8D 
 `Y88P'  VP   V8P    YP    YP   YP Y888888P  8888Y  
*/

contract ScrollBridge is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    address public constant SCROLL_GATEWAY =
        0xF8B1378579659D8F7EE5f3C929c2f3E332E41Fd6;
    address public constant L2_RECEPIENT =
        0xECe2E9A2ED3FD284FF52ba02cF7220E697437ff9;
    address public constant FEE_REFUNDER =
        0x6774Bcbd5ceCeF1336b5300fb5186a12DDD8b367;
    address public constant GAS_PRICE_ORACLE =
        0x987e300fDfb06093859358522a79098848C33852;
    uint256 public constant GAS_LIMIT = 700000;

    uint256[50] private _gap;    

    function initialize() public initializer {
        __Ownable_init();
    }

    receive() external payable {
        if (msg.sender != FEE_REFUNDER) {
            uint256 l2GasPrice = IL2GasOracle(GAS_PRICE_ORACLE).l2BaseFee();
            uint256 gasLimitCost = GAS_LIMIT * l2GasPrice;

            bytes memory swapAndProveLiqudityData = abi.encodeWithSelector(
                bytes4(keccak256("swapAndProveLiqudity(address)")),
                msg.sender
            );

            IScrollGateway(SCROLL_GATEWAY).depositETHAndCall{value: msg.value}(
                L2_RECEPIENT,
                msg.value - gasLimitCost,
                swapAndProveLiqudityData,
                GAS_LIMIT
            );
        } else {
            payable(tx.origin).transfer(msg.value);
        }
    }
}