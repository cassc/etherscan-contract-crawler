// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IWhitelist.sol";
import "./ILisaSettings.sol";

enum CrowdsaleStatus {
    NOT_PLANNED,
    NOT_STARTED,
    IN_PROGRESS,
    SUCCESSFUL,
    UNSUCCESSFUL
}

struct CrowdsaleSimpleInitParams {
    uint256 rate;
    address sellerAddress;
    IERC20Upgradeable at;
    IERC20 bt;
    uint256 startDate;
    uint256 endDate;
    uint256 crowdsaleAmount;
    uint256 sellerRetainedAmount;
    uint256 protocolFeeAmount;
    uint256 minParticipationBT;
    uint256 maxParticipationBT;
    ILisaSettings lisaSettings;
}

struct CrowdsaleProportionalInitParams {
    uint256 rate;
    address sellerAddress;
    IERC20Upgradeable at;
    IERC20 bt;
    uint256 presaleStartDate;
    uint256 startDate;
    uint256 endDate;
    uint256 crowdsaleAmount;
    uint256 sellerRetainedAmount;
    uint256 protocolFeeAmount;
    uint256 minParticipationBT;
    uint256 maxParticipationBT;
    ILisaSettings lisaSettings;
}

interface ICrowdsale is IWhitelist {
    function name() external pure returns (string memory);

    function amountLeftAT() external view returns (uint256);

    function targetSaleProceedsBT() external view returns (uint256);

    function collectedBT() external view returns (uint256);

    function rate() external view returns (uint256);

    function seller() external view returns (address);

    function startTimestamp() external view returns (uint256);

    function endTimestamp() external view returns (uint256);

    function minPurchaseBT() external view returns (uint256);

    function maxPurchaseBT() external view returns (uint256);

    function token() external view returns (address);

    function totalForSaleAT() external view returns (uint256);

    function getAllocationFor(address participant) external view returns (uint256);

    function buyTokens(uint256 amountBT) external;

    function claimSaleProceeds() external returns (uint256);

    function claimProtocolFee() external;

    function claimTokens() external returns (uint256);

    function costBT(uint256 amountAT) external view returns (uint256);

    function status() external view returns (CrowdsaleStatus);

    function refund() external returns (uint256);

    function remainingToBuyAT(address buyer) external view returns (uint256);

    function totalPriceBT() external view returns (uint256);

    function tokenBT() external view returns (IERC20);

    function getTokenAmount(
        uint256 amountBT
    ) external view returns (uint256);

    // --------------------------  EVENTS  --------------------------

    /**
     * @notice Emitted when a buyer reserves tokens
     * @param buyer who reserved the tokens
     * @param tokensAT amount of AT tokens reserved
     */
    event TokensReserved(
        address indexed buyer,
        uint256 tokensAT
    );

    /**
     * @notice Emitted when a buyer claims tokens after a successful crowdsale
     * @param buyer who claimed the tokens
     * @param tokensAT amount of AT tokens claimed
     */
    event TokensClaimed(
        address indexed buyer,
        uint256 tokensAT
    );

    /**
     * @notice Emitted when a buyer receives a refund after an unsuccessful crowdsale or in case of oversubscription
     * @param buyer who received the refund
     * @param tokensBT amount of BT tokens refunded
     */
    event TokensRefunded(address indexed buyer, uint256 tokensBT);
}