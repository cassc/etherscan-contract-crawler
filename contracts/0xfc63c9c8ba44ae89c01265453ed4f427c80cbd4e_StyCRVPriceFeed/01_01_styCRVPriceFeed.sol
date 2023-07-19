pragma solidity ^0.8.13;

interface IChainlinkFeed {
    function decimals() external view returns (uint8 decimals);
    function latestRoundData() external view returns (uint80 roundId, int256 crvUsdPrice, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

interface ICurvePool {
    function price_oracle() external view returns (uint256);
    function last_price() external view returns (uint256);
}

interface I4626 {
    function pricePerShare() external view returns (uint256);
    function decimals() external view returns (uint256);
}

contract StyCRVPriceFeed is IChainlinkFeed {
    
    IChainlinkFeed public constant crvToUsd = IChainlinkFeed(0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f);
    ICurvePool public constant yCrvCrvPool = ICurvePool(0x99f5aCc8EC2Da2BC0771c32814EFF52b712de1E5);
    I4626 public constant styCRV = I4626(0x27B5739e22ad9033bcBf192059122d163b60349D);
    address public gov = 0x926dF14a23BE491164dCF93f4c468A50ef659D5B;
    address public guardian = 0xE3eD95e130ad9E15643f5A5f232a3daE980784cd;
    uint public minCrvPeryCrv = 10**18 / 2;
    uint8 public constant decimals = 18;

    event NewMinCrvPeryCrvRatio(uint newMinRatio);

    /**
     * @notice Retrieves the latest round data for the styCrv token price feed
     * @dev This function calculates the styCrv price in USD by combining the CRV to USD price from a Chainlink oracle and the yCrv to CRV ratio from a Curve pool,
     before multiplying by the price per share from the styCrv vault.
     WARNING: DO NOT USE THIS FEED FOR LENDING PROTOCOLS WHERE THE st-yCRV IS BORROWABLE
     * @return roundId The round ID of the Chainlink price feed for CRV to USD
     * @return answer The latest styCrv price in USD
     * @return startedAt The timestamp when the latest round of Chainlink price feed started
     * @return updatedAt The timestamp when the latest round of Chainlink price feed was updated
     * @return answeredInRound The round ID in which the answer was computed
     */
    function latestRoundData() external view returns
    (uint80 roundId,
     int256 answer,
     uint256 startedAt,
     uint256 updatedAt,
     uint80 answeredInRound
    ){
        int crvUsdPrice;
        (roundId, crvUsdPrice, startedAt, updatedAt, answeredInRound) = crvToUsd.latestRoundData();
        uint crvPeryCrv = yCrvCrvPool.price_oracle();
        if(crvPeryCrv > 10 ** 18){
            //1 CRV can always be traded for 1 yCrv, so price for yCrv should never be higher than the price of CRV
            crvPeryCrv = 10**18;
        } else if (minCrvPeryCrv > crvPeryCrv) {
            //If price of yCrv falls below a certain ratio, we assume something might have gone wrong with the EMA oracle
            //NOTE: This ratio floor is only meant as an intermediate protection, and should be removed as the EMA oracle gains lindy
            crvPeryCrv = minCrvPeryCrv;
        }
        //Account for accumulating yCrv in styCrv
        uint crvPerstyCrv = crvPeryCrv * styCRV.pricePerShare() / 10**18;
        //Divide by 10**8 as crvUsdPrice is 8 decimals
        int256 styCrvUsdPrice = crvUsdPrice * int256(crvPerstyCrv) / 10**8;
        return (roundId, styCrvUsdPrice, startedAt, updatedAt, answeredInRound);
    }

    /**
     * @notice Sets a new minimum CRV per yCrv ratio
     * @dev Can only be called by the gov or guardian addresses
     * @param newMinRatio The new minimum CRV per yCrv ratio
     */
    function setMinCrvPeryCrv(uint newMinRatio) external {
        require(msg.sender == gov || msg.sender == guardian, "ONLY GOV OR GUARDIAN");
        require(newMinRatio <= 10**18, "RATIO CAN'T EXCEED 1");
        minCrvPeryCrv = newMinRatio;
        emit NewMinCrvPeryCrvRatio(newMinRatio);
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