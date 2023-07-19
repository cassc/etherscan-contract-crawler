pragma solidity ^0.8.13;

interface IChainlinkFeed {
    function decimals() external view returns (uint8 decimals);
    function latestRoundData() external view returns (uint80 roundId, int256 fxsUsdPrice, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

interface ICurvePool {
    function price_oracle() external view returns (uint256);
    function last_price() external view returns (uint256);
}

contract ConvexFraxSharePriceFeed is IChainlinkFeed {
    
    IChainlinkFeed public constant fxsToUsd = IChainlinkFeed(0x6Ebc52C8C1089be9eB3945C4350B68B8E4C2233f);
    ICurvePool public constant cvxFxsCrvPool = ICurvePool(0x6a9014FB802dCC5efE3b97Fd40aAa632585636D0);
    address public gov = 0x926dF14a23BE491164dCF93f4c468A50ef659D5B;
    address public guardian = 0xE3eD95e130ad9E15643f5A5f232a3daE980784cd;
    uint public minFxsPerCvxFxsRatio = 10**18 / 2;
    uint8 public constant decimals = 18;

    event NewMinFxsPerCvxFxsRatio(uint newMinRatio);
    
    /**
     * @notice Retrieves the latest round data for the CvxFxs token price feed
     * @dev This function calculates the CvxFxs price in USD by combining the FXS to USD price from a Chainlink oracle and the CvxFxs to FXS ratio from a Curve pool
     * @return roundId The round ID of the Chainlink price feed for FXS to USD
     * @return cvxFxsUsdPrice The latest CvxFxs price in USD
     * @return startedAt The timestamp when the latest round of Chainlink price feed started
     * @return updatedAt The timestamp when the latest round of Chainlink price feed was updated
     * @return answeredInRound The round ID in which the answer was computed
     */
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80){
        (uint80 roundId,int256 fxsUsdPrice,uint startedAt,uint updatedAt,uint80 answeredInRound) = fxsToUsd.latestRoundData();
        uint fxsPerCvxFxs = cvxFxsCrvPool.price_oracle();
        if(fxsPerCvxFxs > 10 ** 18){
            //1 FXS can always be traded for 1 CvxFxs, so price for CvxFxs should never be higher than the price of FXS
            fxsPerCvxFxs = 10**18;
        } else if (minFxsPerCvxFxsRatio > fxsPerCvxFxs) {
            //If price of cvxFxs falls below a certain ratio, we assume something might have gone wrong with the EMA oracle
            //NOTE: This ratio floor is only meant as an intermediate protection, and should be removed as the EMA oracle gains lindy
            fxsPerCvxFxs = minFxsPerCvxFxsRatio;
        }
        
        //Divide by 10**8 as fxsUsdPrice is 8 decimals
        int256 cvxFxsUsdPrice = fxsUsdPrice * int256(fxsPerCvxFxs) / 10**8;
        return (roundId, cvxFxsUsdPrice, startedAt, updatedAt, answeredInRound);
    }

    /**
     * @notice Sets a new minimum FXS per CvxFxs ratio
     * @dev Can only be called by the gov or guardian addresses
     * @param newMinRatio The new minimum FXS per CvxFxs ratio
     */
    function setMinFxsPerCvxFxsRatio(uint newMinRatio) external {
        require(msg.sender == gov || msg.sender == guardian, "ONLY GOV OR GUARDIAN");
        require(newMinRatio <= 10**18, "RATIO CAN'T EXCEED 1");
        minFxsPerCvxFxsRatio = newMinRatio;
        emit NewMinFxsPerCvxFxsRatio(newMinRatio);
    }

    /**
     * @notice Sets a new guardian address
     * @dev Can only be called by the gov address
     * @param newGuardian The new guardian address
     */
    function setGuardian(address newGuardian) external {
        require(msg.sender == gov, "ONLY GOV");
        guardian = newGuardian;
    }

    /**
     * @notice Sets a new gov address
     * @dev Can only be called by the current gov address
     * @param newGov The new gov address
     */
    function setGov(address newGov) external {
        require(msg.sender == gov, "ONLY GOV");
        gov = newGov;
    }
}