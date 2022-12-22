// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IBabyBaseRouter.sol";
import "../libraries/SafeMath.sol";

contract BabyBaseRouter is IBabyBaseRouter, Ownable {
    using SafeMath for uint;

    address public immutable override factory;
    address public immutable override WETH;
    address public override swapMining;
    address public override routerFeeReceiver;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'BabyRouter: EXPIRED');
        _;
    }

    function setSwapMining(address _swapMininng) public onlyOwner {
        swapMining = _swapMininng;
    }
    
    function setRouterFeeReceiver(address _receiver) public onlyOwner {
        routerFeeReceiver = _receiver;
    }

    constructor(address _factory, address _WETH, address _swapMining, address _routerFeeReceiver) {
        factory = _factory;
        WETH = _WETH;
        swapMining = _swapMining;
        routerFeeReceiver = _routerFeeReceiver;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }
}