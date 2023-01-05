// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface INFTSalesSplitter{
    function split() external ;
}

contract NFTSplitAutomation  is OwnableUpgradeable {

    uint256 public lastSplit;
    uint256 constant public WEEK = 86400 * 7;

    address public caller;
    address public target;

    modifier onlyChainlink {
        require(msg.sender == caller || msg.sender == owner());
        _;
    }

    constructor() {}

    function initialize(address _target, address _caller) initializer  public {
        __Ownable_init();
        target = _target;
        caller = _caller == address(0) ? msg.sender : _caller;
        
        lastSplit = (block.timestamp / WEEK * WEEK) + WEEK; //next thursday
 
    }

    function check() public view returns (bool upkeepNeeded) {
        // if 1 week then check == true
       return block.timestamp >= (lastSplit + WEEK);        
    }

    function nextSplit() public view returns(uint){
        return lastSplit + WEEK;
    }

    function performUpkeep() external onlyChainlink {
        require(msg.sender == caller || msg.sender == owner(), 'cannot execute');
        require(check() == true);

        INFTSalesSplitter(target).split();
        lastSplit = block.timestamp / WEEK * WEEK;      
    }

    function setCaller(address _caller) external onlyOwner {
        require(_caller != address(0));
        caller = _caller;
    }

    function setTarget(address _target) external onlyOwner {
        require(_target != address(0));
        target = _target;
    }

}