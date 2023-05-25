// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title ReviverArt abstract contract
 * @dev This contract defines the required methods for interacting with the ReviverArt token contract.
 */
abstract contract ReviverArt {
    function mintBaseExisting(
        address[] calldata to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) public virtual;

    function burn(
        address account,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) public virtual;

    function balanceOf(
        address account,
        uint256 id
    ) external view virtual returns (uint256);
}

/**
 * @title RTokenExchange contract
 * @dev This contract allows users to exchange YIN and YANG Magatama tokens for YIN and YANG Edition tokens.
 */
contract RTokenExchange {
    // Reference to the ReviverArt token contract
    ReviverArt public reviverArt;

    // The start time of the exchange window (Unix timestamp)
    uint256 private constant startTime = 1684166400; // 2023-05-16 00:00:00 GMT+8

    // The duration of the exchange window (5 days)
    uint256 private constant duration = 5 days;

    // Token IDs for YIN Magatama, YANG Magatama, YIN Edition, and YANG Edition tokens
    uint256 private constant yinMagatamaId = 3;
    uint256 private constant yangMagatamaId = 4;
    uint256 private constant yinEditionId = 25;
    uint256 private constant yangEditionId = 26;

    /**
     * @dev RTokenExchange constructor
     * Initializes the reference to the ReviverArt token contract.
     */
    constructor() {
        reviverArt = ReviverArt(0x890dc5Dd5fc40c056c8D4152eDB146a1c76d1C29);
    }

    /**
     * @dev Modifier to check if the current time is within the exchange window.
     */
    modifier withinTimeWindow() {
        require(block.timestamp >= startTime, "Exchange not started yet");
        require(
            block.timestamp <= startTime + duration,
            "Exchange period has ended"
        );
        _;
    }

    /**
     * @dev Allows users to exchange YIN Magatama tokens for YIN Edition tokens.
     * Users need to burn 4 YIN Magatama tokens for each YIN Edition token they want to mint.
     * @param amount The number of YIN Edition tokens the user wants to mint.
     */
    function mintYinEdition(uint256 amount) external withinTimeWindow {
        uint256 yinMagatamaBalance = reviverArt.balanceOf(
            msg.sender,
            yinMagatamaId
        );
        uint256 requiredYinMagatama = 4 * amount;
        require(
            yinMagatamaBalance >= requiredYinMagatama,
            "Insufficient YIN Magatama balance"
        );

        address[] memory recipients = new address[](1);
        recipients[0] = msg.sender;

        uint256[] memory tokenIdsToBurn = new uint256[](1);
        tokenIdsToBurn[0] = yinMagatamaId;

        uint256[] memory amountsToBurn = new uint256[](1);
        amountsToBurn[0] = requiredYinMagatama;

        uint256[] memory tokenIdsToMint = new uint256[](1);
        tokenIdsToMint[0] = yinEditionId;
        uint256[] memory amountsToMint = new uint256[](1);
        amountsToMint[0] = amount;

        reviverArt.burn(msg.sender, tokenIdsToBurn, amountsToBurn);
        reviverArt.mintBaseExisting(recipients, tokenIdsToMint, amountsToMint);
    }

    /**
     * @dev Allows users to exchange YANG Magatama tokens for YANG Edition tokens.
     * Users need to burn 4 YANG Magatama tokens for each YANG Edition token they want to mint.
     * @param amount The number of YANG Edition tokens the user wants to mint.
     */
    function mintYangEdition(uint256 amount) external withinTimeWindow {
        uint256 yangMagatamaBalance = reviverArt.balanceOf(
            msg.sender,
            yangMagatamaId
        );
        uint256 requiredYangMagatama = 4 * amount;
        require(
            yangMagatamaBalance >= requiredYangMagatama,
            "Insufficient YANG Magatama balance"
        );

        address[] memory recipients = new address[](1);
        recipients[0] = msg.sender;

        uint256[] memory tokenIdsToBurn = new uint256[](1);
        tokenIdsToBurn[0] = yangMagatamaId;

        uint256[] memory amountsToBurn = new uint256[](1);
        amountsToBurn[0] = requiredYangMagatama;

        uint256[] memory tokenIdsToMint = new uint256[](1);
        tokenIdsToMint[0] = yangEditionId;

        uint256[] memory amountsToMint = new uint256[](1);
        amountsToMint[0] = amount;

        reviverArt.burn(msg.sender, tokenIdsToBurn, amountsToBurn);
        reviverArt.mintBaseExisting(recipients, tokenIdsToMint, amountsToMint);
    }
}