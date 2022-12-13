pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface ICampaign {
    enum UnsoldTokensAction { burn, reserve }
    enum Dex { pancake, sushi, uni }
    struct Config {
        IERC20 token;
        uint32 start;
        uint32 end;
        uint256 presaleTokens;
        uint256 liquidityTokens;
        uint256 minPurchaseBnb;
        uint256 maxPurchaseBnb;
        uint256 softCap;
        uint256 tokensPerBnb;
        Dex dex;
        UnsoldTokensAction action;
        uint16 liquidityPercent;
        uint32 liquidityLockupPeriod;
    }

    function raised() external view returns (uint256);
    function initialize(address _owner, uint16 _fee, address _router, Config calldata _config) external;
}