// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;
/**
 * @title LBR is an ERC20-compliant token.
 * - LBR can only be exchanged to esLBR in the lybraFund contract.
 * - Apart from the initial production, LBR can only be produced by destroying esLBR in the fund contract.
 */
import "./ERC20.sol";

contract LBR is ERC20 {
    address public immutable lybraFund;
    uint256 maxSupply = 100_000_000 * 1e18;

    constructor(
        address _fund
    ) ERC20("LBR", "LBR") {
        lybraFund = _fund;
        _mint(msg.sender, 39_500_000 * 1e18);
    }

    function mint(address user, uint256 amount) external returns(bool) {
        require(msg.sender == lybraFund, "not authorized");
        require(totalSupply() + amount <= maxSupply, "exceeding the maximum supply quantity.");
        _mint(user, amount);
        return true;
    }

    function burn(address user, uint256 amount) external returns(bool) {
        require(msg.sender == lybraFund, "not authorized");
        _burn(user, amount);
        return true;
    }
}
