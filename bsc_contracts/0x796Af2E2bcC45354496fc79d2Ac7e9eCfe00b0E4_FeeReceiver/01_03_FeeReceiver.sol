//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IERC20.sol";
import "./IUniswapV2Router02.sol";

interface IInfinity {
    function getOwner() external view returns (address);
    function sell(uint256 amount) external returns (bool);
}

interface IYieldFarm {
    function depositRewards(uint256 amount) external;
}

contract FeeReceiver {

    // Infinity token
    address public immutable token;

    // Recipients Of Fees
    address public immutable trustFund;

    /**
        Minimum Amount Of Infinity In Contract To Trigger `trigger` Unless `approved`
            If Set To A Very High Number, Only Approved May Call Trigger Function
            If Set To A Very Low Number, Anybody May Call At Their Leasure
     */
    uint256 public minimumTokensRequiredToTrigger;

    // router
    IUniswapV2Router02 public constant router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    // Address => Can Call Trigger
    mapping ( address => bool ) public approved;

    // Swap Path
    address[] path;

    // Phoenix+
    address public constant phoenix = 0xfc62b18CAC1343bd839CcbEDB9FC3382a84219B9;

    // Events
    event Approved(address caller, bool isApproved);

    modifier onlyOwner(){
        require(
            msg.sender == IInfinity(token).getOwner(),
            'Only Infinity Owner'
        );
        _;
    }

    constructor(address _token, address _fund) {
        
        // save constructor args
        token = _token;
        trustFund = _fund;

        // set initial approved
        approved[msg.sender] = true;

        // only approved can trigger at the start
        minimumTokensRequiredToTrigger = 10**30;

        // swap path
        path = new address[](2);
        path[0] = _token;
        path[1] = phoenix;
    }

    function trigger() external {

        // Infinity Balance In Contract
        uint balance = IERC20(token).balanceOf(address(this));
        if (balance < minimumTokensRequiredToTrigger && !approved[msg.sender]) {
            return;
        }

        // sell Infinity in contract for BNB
        IInfinity(token).sell(balance);

        // Send BNB To Trust Fund
        if (address(this).balance > 0) {
            (bool s,) = payable(trustFund).call{value: address(this).balance}("");
            require(s, 'Trust Fund');
        }
    }
   
    function setApproved(address caller, bool isApproved) external onlyOwner {
        approved[caller] = isApproved;
        emit Approved(caller, isApproved);
    }
    
    function setMinTriggerAmount(uint256 minTriggerAmount) external onlyOwner {
        minimumTokensRequiredToTrigger = minTriggerAmount;
    }
    
    function withdraw() external onlyOwner {
        (bool s,) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }
    
    function withdraw(address _token) external onlyOwner {
        IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }
    
    receive() external payable {}
}