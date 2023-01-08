// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

import "ERC20ElasticSupply.sol";


/**
* @title JPYG
* @author Geminon Protocol
* @notice Japanese Yen Stablecoin
*/
contract JPYG is ERC20ElasticSupply {

    address public priceFeed;
    uint8 public priceFeedDecimals;
    bool public isInitialized;

    
    constructor(address priceFeed_) ERC20ElasticSupply("Geminon Japanese Yen", "JPYG", 50, 1e24) {
        priceFeed = priceFeed_;
        priceFeedDecimals = AggregatorV3Interface(priceFeed).decimals();
        isInitialized = false;
        require(priceFeedDecimals <= 18); // dev: Too many decimals
    }


    /// @dev Initializes the CNHG token adding the address of the stablecoin 
    /// minter contract. This function can only be called once
    /// after deployment. Owner can't be a minter.
    /// @param scMinter Stablecoin minter address. 
    function initialize(address scMinter) external onlyOwner {
        require(!isInitialized); // dev: Initialized
        require(scMinter != address(0)); // dev: Address 0
        require(scMinter != owner()); // dev: Minter is owner

        minters[scMinter] = true;
        isInitialized = true;
    }

    
    /// @dev Updates the address of the Chainlink oracle that provides the peg values. 7 days timelock.
    function updatePriceFeed(address priceFeed_) external onlyOwner {
        require(changeRequests[priceFeed].changeRequested); // dev: Not requested
        require(block.timestamp - changeRequests[priceFeed].timestampRequest > 7 days); // dev: Time elapsed
        require(changeRequests[priceFeed].newAddressRequested == priceFeed_); // dev: Different address requested

        changeRequests[priceFeed].changeRequested = false;
        priceFeed = priceFeed_;
        priceFeedDecimals = AggregatorV3Interface(priceFeed).decimals();
        
        require(priceFeedDecimals <= 18, 'Oracle has too many decimals');
    }

    
    /// @dev Compatibility with ERC20Indexed tokens
    function getOrUpdatePegValue() public view returns(uint256) {
        return getPegValue();
    }

    /// @dev Get the current value of the peg in USD with 18 decimals
    function getPegValue() public view returns(uint256) {
        (, int256 answer, , , ) = AggregatorV3Interface(priceFeed).latestRoundData();
        return uint256(answer) * 10**(18-priceFeedDecimals);
    }

    /// @notice Calculates the max amount of the token that can be minted
    function maxAmountMintable() public view override returns(uint256) {
        int256 maxDailyMintable = _toInt256(_maxMintRatio()*totalSupply()) / 1e3;
        maxDailyMintable = (maxDailyMintable*_toInt256(getPegValue())) / 1e18;
        (int256 w, int256 w2) = _weightsMean();
        int256 maxAmount = (1e6*maxDailyMintable - w2*_meanMintRatio)/w;
        return maxAmount > 0 ? uint256(maxAmount) : 0;
    }

    /// @dev Checks that the amount minted is not higher than the max allowed.
    /// Begins working when the threshold of initial supply has been reached.
    function _requireMaxMint(uint256 amount) internal override {
        if (totalSupply() > thresholdLimitMint) {
            uint256 maxDailyMintable = (_maxMintRatio()*totalSupply()) / 1e3;
            maxDailyMintable = (maxDailyMintable*getPegValue()) / 1e18;
            require(_meanDailyAmount(_toInt256(amount)) <= maxDailyMintable, 'Max mint rate');
        }
    }
}