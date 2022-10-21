pragma solidity ^0.8.0;

import "IERC20.sol";
import "Math.sol";
import "SafeERC20.sol";



interface IStrategy {
    function vault() external returns (address);
}

contract Donator {
    using SafeERC20 for IERC20;

    event Donated(address strategy, uint256 amount, uint256 period);

    uint internal constant WEEK = 60 * 60 * 24 * 7;
    address internal constant YCRV = 0xFCc5c47bE19d06BF83eB04298b026F81069ff65b;
    address public governance;
    address public management;
    address public strategy;
    address public pendingGovernance;
    uint256 public donateAmount;
    uint256 public lastDonatePeriod;
    bool public donationsPaused;

    constructor() {
        governance = 0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52;
        management = 0x16388463d60FFE0661Cf7F1f31a7D658aC790ff7;
        strategy = 0xE7863292dd8eE5d215eC6D75ac00911D06E59B2d;
        donateAmount = 50_000e18;
    }
    
    /// @notice check if enough time has elapsed since our last donation
    function canDonate() public view returns (bool) {
        return (
            !donationsPaused &&
            block.timestamp / WEEK * WEEK > lastDonatePeriod
        );
    }
    
    function donate() external {
        require(canDonate(), "cannotDonate");
        uint256 balance = IERC20(YCRV).balanceOf(address(this));
        require(balance > 0, "nothingToDonate");
        uint amountDonated = Math.min(balance, donateAmount);
        address _strategy = strategy;
        IERC20(YCRV).transfer(_strategy, amountDonated);
        uint currentPeriod = block.timestamp / WEEK * WEEK;
        lastDonatePeriod = currentPeriod;
        emit Donated(_strategy, amountDonated, currentPeriod);
    }
    
    function setDonateAmount(uint256 _donateAmount) public {
        require(msg.sender == governance, "!authorized");
        donateAmount = _donateAmount;
    }

    function setPaused(bool _paused) public {
        require(msg.sender == governance || msg.sender == management, "!authorized");
        donationsPaused = _paused;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!authorized");
        pendingGovernance = _governance;
    }

    function setManagement(address _management) external {
        require(msg.sender == governance, "!authorized");
        management = _management;
    }

    function setStrategy(address _strategy) external {
        require(msg.sender == governance, "!authorized");
        require(IStrategy(_strategy).vault() != address(0), "invalidStrategy");
        strategy = _strategy;
    }

    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "!authorized");
        governance = pendingGovernance;
    }
    
    /// @notice sweep function in case anyone sends random tokens here or we need to rescue yvBOOST
    function sweep(address _token) external {
        require(msg.sender == governance, "!authorized");
        uint bal = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(address(governance), bal);
    }
}