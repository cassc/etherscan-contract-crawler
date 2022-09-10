pragma solidity >=0.8.0 <0.9.0;

interface Comptroller {
    function markets(address) external view returns (bool, uint256);

    function enterMarkets(address[] calldata)
        external
        returns (uint256[] memory);
    function exitMarket(address cTokenAddress) external returns (uint256);

    function getAccountLiquidity(address)
        external
        view
        returns (uint256, uint256, uint256);

    function redeemAllowed(
        address cToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    function getHypotheticalAccountLiquidity(
        address account,
        address cTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
        
    function oracle() external view returns(address);
    function _setPriceOracle(address _newPriceOracle) external;
}