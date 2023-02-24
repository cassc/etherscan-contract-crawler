// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

interface BRICKS {
    function claim(address wallet, uint256 amount) external;
    function getMaxSupply() external view returns (uint256);
    function totalSupply(uint256 id) external view returns (uint256);
}

contract BricksBurnCounter is Ownable {
    BRICKS private bricks;
    address logicContract;

    uint256 _totalClaimed;
    
    constructor(uint256 _claimTotal, address _logicContract, address _bricksAddress) {
        _totalClaimed = _claimTotal;
        setLogicContract(_logicContract);
        bricks = BRICKS(_bricksAddress);
    }

    function setLogicContract(address addr) public onlyOwner {
        logicContract = addr;
    }

    function setClaimedTotal(uint256 newClaimedTotal) external onlyOwner {
        _totalClaimed = newClaimedTotal;
    }

    function setBricksContract(address newAddress) external onlyOwner {
        bricks = BRICKS(newAddress);
    }

    function _getMaxClaimable(uint256 _amountRequested) internal view returns(uint) {
        if (_totalClaimed + _amountRequested < getMaxSupply()) {
            return _amountRequested;
        }
        
        return getMaxSupply() - _totalClaimed;
    }

    function claim(address _wallet, uint256 _amount) public {
        uint256 maxClaimableAmount = _getMaxClaimable(_amount);
        require(_totalClaimed + maxClaimableAmount <= getMaxSupply(), "No bricks left to claim.");
        require(msg.sender == logicContract, "Must be the correct contract.");
        if(_totalClaimed + maxClaimableAmount <= getMaxSupply()){
            _totalClaimed += maxClaimableAmount;
            bricks.claim(_wallet, maxClaimableAmount);
        }
    }

    function claimsRemaining() public view returns(uint256) {
        return getMaxSupply() - _totalClaimed;
    }
    function getMaxSupply() public view returns (uint256) {
        return bricks.getMaxSupply();
    }
    
    function totalSupply(uint256 id) public view returns (uint256) {
        return bricks.totalSupply(id);
    }
}