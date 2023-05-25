// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../common/Constants.sol";

contract GROToken is Constants, ERC20, Ownable {
    uint256 public immutable INIT_MAX_TOTAL_SUPPLY;
    uint256 public immutable INFLATION_BLOCKED_UNTIL; // Governance cannot vote on through inflation before this timestamp
    // GRO token inflation is defined by inflation rate / one year in seconds, where inflation rate can be
    // between 0 and MAX_INFLATION_RATE (500 BP)
    uint256 public constant MAX_INFLATION_RATE = (500 * DEFAULT_DECIMALS_FACTOR) / PERCENTAGE_DECIMAL_FACTOR; // 500 BP

    address public distributer;
    // inflation variables initated to 0 and cannot be updated until INFLATION_START_TIME
    uint256 public inflationRate;
    uint256 public inflationPerSecond;
    uint256 public lastMaxTotalSupply;
    uint256 public lastMaxTotalSupplyTime;

    event LogInflationRate(
        uint256 newInflationRate,
        uint256 newInflationPerSecond,
        uint256 lastMaxTotalSupply,
        uint256 lastMaxTotalSupplyTime
    );
    event LogDistributer(address newDistributer);

    constructor(
        string memory name,
        string memory symbol,
        uint256 _maxTotalSupply,
        uint256 nonInflationPeriod // The unit is second
    ) ERC20(name, symbol) {
        INIT_MAX_TOTAL_SUPPLY = _maxTotalSupply;
        INFLATION_BLOCKED_UNTIL = block.timestamp + nonInflationPeriod;
        lastMaxTotalSupply = _maxTotalSupply;
        lastMaxTotalSupplyTime = block.timestamp + nonInflationPeriod;
        emit LogInflationRate(0, 0, lastMaxTotalSupply, lastMaxTotalSupplyTime);
    }

    function setDistributer(address _distributer) public onlyOwner {
        distributer = _distributer;
        emit LogDistributer(_distributer);
    }

    /// @notice Set inflation rate, if current inflation rate
    /// @param rate New inflation rate, decimals is 18
    function setInflationRate(uint256 rate) public onlyOwner {
        uint256 currentTime = block.timestamp;
        require(
            currentTime > INFLATION_BLOCKED_UNTIL,
            "setInflationRate: Cannot set inflation rate before inflation start time"
        );
        require(rate <= MAX_INFLATION_RATE, "setInflationRate: !rate");
        require(rate != inflationRate, "setInflationRate: same rate");

        inflationRate = rate;
        lastMaxTotalSupply += (currentTime - lastMaxTotalSupplyTime) * inflationPerSecond;
        lastMaxTotalSupplyTime = currentTime;
        inflationPerSecond = ((lastMaxTotalSupply * rate) / DEFAULT_DECIMALS_FACTOR) / ONE_YEAR_SECONDS;

        emit LogInflationRate(rate, inflationPerSecond, lastMaxTotalSupply, lastMaxTotalSupplyTime);
    }

    function mint(address account, uint256 amount) external {
        require(msg.sender == distributer, "mint: !distributer");
        require(amount + totalSupply() <= maxTotalSupply(), "mint: > cap");
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        require(msg.sender == distributer, "mint: !distributer");
        _burn(account, amount);
    }

    function maxTotalSupply() public view returns (uint256) {
        uint256 currentTime = block.timestamp;
        if (currentTime <= INFLATION_BLOCKED_UNTIL) {
            return INIT_MAX_TOTAL_SUPPLY;
        } else {
            return lastMaxTotalSupply + (currentTime - lastMaxTotalSupplyTime) * inflationPerSecond;
        }
    }
}