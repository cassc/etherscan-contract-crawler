// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/IETHRegistrarController.sol";
import "./interfaces/IChainlinkAggregatorV3.sol";

contract NamehashController {
    address public immutable treasury;
    IETHRegistrarController public immutable ensController;

    constructor(address _treasury, address _ensController) {
        treasury = _treasury;
        ensController = IETHRegistrarController(_ensController);
    }

    receive() external payable {}

    fallback() external payable {}

    function register(
        string memory name,
        address owner,
        uint256 duration,
        bytes32 secret,
        address resolver,
        address addr
    ) public payable {
        // register in ENS
        ensController.registerWithConfig{value: msg.value}(
            name,
            owner,
            duration,
            secret,
            resolver,
            addr
        );
    }

    function withdraw() public {
        // withdraw to treasury
        payable(treasury).transfer(address(this).balance);
    }

    function getPrice(address priceFeed) public view returns (int256) {
        (, int256 price, , , ) = IChainlinkAggregatorV3(priceFeed)
            .latestRoundData();
        return price;
    }
}