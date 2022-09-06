// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IPolicyQuote {
    /// @notice Let user to calculate policy cost in stable coin, access: ANY
    /// @param _durationSeconds is number of seconds to cover
    /// @param _tokens is a number of tokens to cover
    /// @param _totalCoverTokens is a number of covered tokens
    /// @param _totalLiquidity is a liquidity amount
    /// @param _totalLeveragedLiquidity is a totale deployed leverage to the pool
    /// @param _safePricingModel the pricing model configured for this bool safe or risk
    /// @return amount of stable coin policy costs
    function getQuotePredefined(
        uint256 _durationSeconds,
        uint256 _tokens,
        uint256 _totalCoverTokens,
        uint256 _totalLiquidity,
        uint256 _totalLeveragedLiquidity,
        bool _safePricingModel
    ) external view returns (uint256, uint256);

    /// @notice Let user to calculate policy cost in stable coin, access: ANY
    /// @param _durationSeconds is number of seconds to cover
    /// @param _tokens is number of tokens to cover
    /// @param _policyBookAddr is address of policy book
    /// @return amount of stable coin policy costs
    function getQuote(
        uint256 _durationSeconds,
        uint256 _tokens,
        address _policyBookAddr
    ) external view returns (uint256);

    /// @notice setup all pricing model varlues
    ///@param _highRiskRiskyAssetThresholdPercentage URRp Utilization ration for pricing model when the assets is considered risky, %
    ///@param _lowRiskRiskyAssetThresholdPercentage URRp Utilization ration for pricing model when the assets is not considered risky, %
    ///@param _highRiskMinimumCostPercentage MC minimum cost of cover (Premium) when the assets is considered risky, %;
    ///@param _lowRiskMinimumCostPercentage MC minimum cost of cover (Premium), when the assets is not considered risky, %
    ///@param _minimumInsuranceCost minimum cost of insurance (Premium) , (10**18)
    ///@param _lowRiskMaxPercentPremiumCost TMCI target maximum cost of cover when the asset is not considered risky (Premium)
    ///@param _lowRiskMaxPercentPremiumCost100Utilization MCI not risky
    ///@param _highRiskMaxPercentPremiumCost TMCI target maximum cost of cover when the asset is considered risky (Premium)
    ///@param _highRiskMaxPercentPremiumCost100Utilization MCI risky
    function setupPricingModel(
        uint256 _highRiskRiskyAssetThresholdPercentage,
        uint256 _lowRiskRiskyAssetThresholdPercentage,
        uint256 _highRiskMinimumCostPercentage,
        uint256 _lowRiskMinimumCostPercentage,
        uint256 _minimumInsuranceCost,
        uint256 _lowRiskMaxPercentPremiumCost,
        uint256 _lowRiskMaxPercentPremiumCost100Utilization,
        uint256 _highRiskMaxPercentPremiumCost,
        uint256 _highRiskMaxPercentPremiumCost100Utilization
    ) external;

    ///@notice return min ur under the current pricing model
    ///@param _safePricingModel pricing model of the pool wethere it is safe or risky model
    function getMINUR(bool _safePricingModel) external view returns (uint256 _minUR);
}