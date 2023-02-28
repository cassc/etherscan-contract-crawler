pragma solidity ^0.8.0;

interface IInsuranceExchange {

    struct InputMint {
        uint256 amount;
    }

    struct InputRedeem {
        uint256 amount;
    }

    function mint(InputMint calldata input) external;

    function redeem(InputRedeem calldata input) external;

    function payout() external;

    function premium(uint256 amount) external;

    function compensate(uint256 assetAmount, address to) external;

    function requestWithdraw() external;

    function checkWithdraw() external;


}