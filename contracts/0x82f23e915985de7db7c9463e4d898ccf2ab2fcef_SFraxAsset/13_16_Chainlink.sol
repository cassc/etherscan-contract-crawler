// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IPriceFeed {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

library ChainlinkLibrary {
    uint8 constant USD_DECIMALS = 6;

    function getDecimals(IPriceFeed oracle) internal view returns (uint8) {
        return oracle.decimals();
    }

    function getPrice(IPriceFeed oracle) internal view returns (uint256) {
        (
            uint80 roundID,
            int256 price,
            ,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = oracle.latestRoundData();
        require(answeredInRound >= roundID, "Old data");
        require(timeStamp > 0, "Round not complete");

        return uint256(price);
    }

    function getPrice(
        IPriceFeed oracle,
        IPriceFeed sequencerOracle,
        uint256 frequency
    ) internal view returns (uint256) {
        if (address(sequencerOracle) != address(0))
            checkUptime(sequencerOracle);

        (uint256 roundId, int256 price, , uint256 updatedAt, ) = oracle
            .latestRoundData();
        require(price > 0 && roundId != 0 && updatedAt != 0, "Invalid Price");
        if (frequency > 0)
            require(block.timestamp - updatedAt <= frequency, "Stale Price");

        return uint256(price);
    }

    function checkUptime(IPriceFeed sequencerOracle) internal view {
        (, int256 answer, uint256 startedAt, , ) = sequencerOracle
            .latestRoundData();
        require(answer <= 0, "Sequencer Down"); // 0: Sequencer is up, 1: Sequencer is down
        require(block.timestamp - startedAt > 1 hours, "Grace Period Not Over");
    }

    function convertTokenToToken(
        uint256 amount0,
        uint8 token0Decimals,
        uint8 token1Decimals,
        IPriceFeed oracle0,
        IPriceFeed oracle1
    ) internal view returns (uint256 amount1) {
        uint256 price0 = getPrice(oracle0);
        uint256 price1 = getPrice(oracle1);
        amount1 =
            (amount0 * price0 * (10 ** token1Decimals)) /
            (price1 * (10 ** token0Decimals));
    }

    function convertTokenToUsd(
        uint256 amount,
        uint8 tokenDecimals,
        IPriceFeed oracle
    ) internal view returns (uint256 amountUsd) {
        uint8 decimals = getDecimals(oracle);
        uint256 price = getPrice(oracle);

        amountUsd =
            (amount * price * (10 ** USD_DECIMALS)) /
            10 ** (decimals + tokenDecimals);
    }

    function convertUsdToToken(
        uint256 amountUsd,
        uint256 tokenDecimals,
        IPriceFeed oracle
    ) internal view returns (uint256 amount) {
        uint8 decimals = getDecimals(oracle);
        uint256 price = getPrice(oracle);

        amount =
            (amountUsd * 10 ** (decimals + tokenDecimals)) /
            (price * (10 ** USD_DECIMALS));
    }
}