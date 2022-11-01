// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// DYNAMIC DECENTRALIZED SUPPLY CONTROL ALGORITHM
contract DDSCA is Ownable {

    IERC20 public immutable token;

    uint256 public tokenPerBlock;
    uint256 public maxEmissionRate;
    uint256 public emissionStartBlock;
    uint256 public emissionEndBlock = type(uint256).max;
    address public masterchef;

    // Dynamic emissions
    uint256 public topPriceInCents    = 800;  // 8$
    uint256 public bottomPriceInCents = 100;  // 1$

    enum EmissionRate {SLOW, MEDIUM, FAST, FASTEST}
    EmissionRate public ActiveEmissionIndex = EmissionRate.MEDIUM;

    event UpdateDDSCAPriceRange(uint256 topPrice, uint256 bottomPrice);
    event updatedDDSCAMaxEmissionRate(uint256 maxEmissionRate);
    event SetFarmStartBlock(uint256 startBlock);
    event SetFarmEndBlock(uint256 endBlock);

    constructor(IERC20 _tokenAddress, uint256 _tokenPerBlock, uint256 _maxTokenPerBlock, uint256 _startBlock) {
        token = _tokenAddress;
        tokenPerBlock = _tokenPerBlock;
        maxEmissionRate = _maxTokenPerBlock;
        emissionStartBlock = _startBlock;
    }

    // Called externally by bot
    function checkIfUpdateIsNeeded(uint256 priceInCents) public view returns(bool, EmissionRate) {

        EmissionRate _emissionRate;

        bool isOverATH = priceInCents > topPriceInCents;
        // if price is over ATH, set to fastest
        if (isOverATH){
            _emissionRate = EmissionRate.FASTEST;
        } else {
            _emissionRate = getEmissionStage(priceInCents);
        }

        // No changes, no need to update
        if (_emissionRate == ActiveEmissionIndex){
            return(false, _emissionRate);
        }

        // Means its a downward movement, and it changed a stage
        if (_emissionRate < ActiveEmissionIndex){
            return(true, _emissionRate);
        }

        // Check if its a upward movement
        if (_emissionRate > ActiveEmissionIndex){

            uint256 athExtra = 0;
            if (isOverATH){
                athExtra = 1;
            }

            // Check if it moved up by two stages
            if ((uint256(_emissionRate) + athExtra) - uint256(ActiveEmissionIndex) >= 2){
                // price has moved 2 ranges from current, so update
                _emissionRate = EmissionRate(uint256(_emissionRate) + athExtra - 1 );
                return(true, _emissionRate);
            }
        }
        return(false, _emissionRate);

    }

    function updateEmissions(EmissionRate _newEmission) public {
        require(msg.sender ==  masterchef); 
        ActiveEmissionIndex = _newEmission;
        tokenPerBlock = (maxEmissionRate / 4) * (uint256(_newEmission) + 1);
    }

    function getEmissionStage(uint256 currentPriceCents) public view returns (EmissionRate){

        if (currentPriceCents > topPriceInCents){
            return EmissionRate.FASTEST;
        }

        // Prevent function from underflowing when subtracting currentPriceCents - bottomPriceInCents
        if (currentPriceCents < bottomPriceInCents){
            currentPriceCents = bottomPriceInCents;
        }
        uint256 percentageChange = ((currentPriceCents - bottomPriceInCents ) * 1000) / (topPriceInCents - bottomPriceInCents);
        percentageChange = 1000 - percentageChange;

        if (percentageChange <= 250){
            return EmissionRate.FASTEST;
        }
        if (percentageChange <= 500 && percentageChange > 250){
            return EmissionRate.FAST;
        }
        if (percentageChange <= 750 && percentageChange > 500){
            return EmissionRate.MEDIUM;
        }

        return EmissionRate.SLOW;
    }

    function updateDDSCAPriceRange(uint256 _topPrice, uint256 _bottomPrice) external onlyOwner {
        require(_topPrice > _bottomPrice, "top < bottom price");
        topPriceInCents = _topPrice;
        bottomPriceInCents = _bottomPrice;
        emit UpdateDDSCAPriceRange(topPriceInCents, bottomPriceInCents);
    }

    function updateDDSCAMaxEmissionRate(uint256 _maxEmissionRate) external onlyOwner {
        require(_maxEmissionRate > 0, "_maxEmissionRate !> 0");
        require(_maxEmissionRate <= 10 ether, "_maxEmissionRate !");
        maxEmissionRate = _maxEmissionRate;
        emit updatedDDSCAMaxEmissionRate(_maxEmissionRate);
    }

    function _setFarmStartBlock(uint256 _newStartBlock) external {
        require(msg.sender ==  masterchef); 
        require(_newStartBlock > block.number, "must be in the future");
        require(block.number < emissionStartBlock, "farm has already started");
        emissionStartBlock = _newStartBlock;
        emit SetFarmStartBlock(_newStartBlock);
    }

    function setFarmEndBlock(uint256 _newEndBlock) external onlyOwner {
        require(_newEndBlock > block.number, "must be in the future");
        emissionEndBlock = _newEndBlock;
        emit SetFarmEndBlock(_newEndBlock);
    }
    
    function updateMcAddress(address _mcAddress) external onlyOwner {
        masterchef = _mcAddress;
    }
}