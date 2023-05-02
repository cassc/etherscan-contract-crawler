// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;
/**
 * @title LBR is an ERC20-compliant token.
 * - LBR can only be exchanged to esLBR in the lybraFund contract.
 * - Apart from the initial production, LBR can only be produced by destroying esLBR in the fund contract.
 */
import "./ERC20.sol";

contract LBR is ERC20 {
    address public lybraFund;
    uint256 maxSupply = 100_000_000 * 1e18;
    address public oldLBR = 0xC98835e792553e505AE46e73a6fD27a23985aCcA;
    address public owner;
    uint256 public bonusMigrationPeriod = 1683032400;

    constructor(
        address _fund
    ) ERC20("LBR", "LBR") {
        owner = msg.sender;
        lybraFund = _fund;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    function setBonusMigrationPeriod(uint256 time) external onlyOwner {
        bonusMigrationPeriod = time;
    }

    function setLybraFund(address _fund) external onlyOwner {
        lybraFund = _fund;
    }

    function migrate(uint256 amount) external {
        require(totalSupply() + amount <= maxSupply, "exceeding the maximum supply quantity.");
        ERC20(oldLBR).transferFrom(msg.sender, address(this), amount);
        if(block.timestamp < bonusMigrationPeriod) {
            _mint(msg.sender, amount * 105 / 100);
        } else {
            _mint(msg.sender, amount);
        }
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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;
    }
}