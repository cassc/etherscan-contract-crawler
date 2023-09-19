// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;
/**
 * @title LBR is an ERC20-compliant token.
 * - LBR can only be exchanged to esLBR in the lybraFund contract.
 * - Apart from the initial production, LBR can only be produced by destroying esLBR in the fund contract.
 */
import "../interfaces/Iconfigurator.sol";
import "@layerzerolabs/solidity-examples/contracts/token/oft/v2/OFTV2.sol";

contract LBR is OFTV2 {
    Iconfigurator public immutable configurator;
    uint256 constant maxSupply = 100_000_000 * 1e18;

    constructor(address _config, uint8 _sharedDecimals, address _lzEndpoint) OFTV2("Lybra", "LBR", _sharedDecimals, _lzEndpoint) {
        configurator = Iconfigurator(_config);
    }

    function mint(address user, uint256 amount) external returns (bool) {
        require(amount != 0, "ZA");
        require(configurator.tokenMiner(msg.sender), "NA");
        require(totalSupply() + amount <= maxSupply, "exceeding the maximum supply quantity.");
        _mint(user, amount);
        return true;
    }

    function burn(address user, uint256 amount) external returns (bool) {
        require(amount != 0, "ZA");
        require(configurator.tokenMiner(msg.sender), "NA");
        _burn(user, amount);
        return true;
    }
}