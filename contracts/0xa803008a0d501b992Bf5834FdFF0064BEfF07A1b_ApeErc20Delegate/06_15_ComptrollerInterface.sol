pragma solidity ^0.5.16;

import "./ApeToken.sol";
import "./ComptrollerStorage.sol";

contract ComptrollerInterface {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata apeTokens) external;

    function exitMarket(address apeToken) external;

    /*** Policy Hooks ***/

    function mintAllowed(
        address payer,
        address apeToken,
        address minter,
        uint256 mintAmount
    ) external returns (uint256);

    function mintVerify(
        address apeToken,
        address payer,
        address minter,
        uint256 mintAmount,
        uint256 mintTokens
    ) external;

    function redeemAllowed(
        address apeToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    function redeemVerify(
        address apeToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external;

    function borrowAllowed(
        address apeToken,
        address borrower,
        uint256 borrowAmount
    ) external returns (uint256);

    function borrowVerify(
        address apeToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function repayBorrowAllowed(
        address apeToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function repayBorrowVerify(
        address apeToken,
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 borrowerIndex
    ) external;

    function liquidateBorrowAllowed(
        address apeTokenBorrowed,
        address apeTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function liquidateBorrowVerify(
        address apeTokenBorrowed,
        address apeTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount,
        uint256 seizeTokens
    ) external;

    function seizeAllowed(
        address apeTokenCollateral,
        address apeTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function seizeVerify(
        address apeTokenCollateral,
        address apeTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address apeTokenBorrowed,
        address apeTokenCollateral,
        uint256 repayAmount
    ) external view returns (uint256, uint256);
}

interface ComptrollerInterfaceExtension {
    function checkMembership(address account, ApeToken apeToken) external view returns (bool);

    function flashloanAllowed(
        address apeToken,
        address receiver,
        uint256 amount,
        bytes calldata params
    ) external view returns (bool);

    function getAccountLiquidity(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function supplyCaps(address market) external view returns (uint256);

    function isCreditAccount(address account, address apeToken) external view returns (bool);
}