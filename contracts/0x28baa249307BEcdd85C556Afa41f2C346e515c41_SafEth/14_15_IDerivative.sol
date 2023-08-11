// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IDerivative {
    error ChainlinkFailed(string derivativeName);

    // Represents a Chainlink oracle response.
    // only applicable to some derivatives
    struct ChainlinkResponse {
        uint80 roundId;
        int256 answer;
        uint256 updatedAt;
        bool success;
    }

    /// Returns human readable identifier string
    function name() external pure returns (string memory);

    /// buys the underlying derivative for this contract
    function deposit() external payable returns (uint256);

    /// sells the underlying derivative for this contract & sends user eth
    function withdraw(uint256 amount) external;

    /// Estimated price per derivative when depositing amount
    function ethPerDerivative(bool _validate) external view returns (uint256);

    /// underlying derivative balance held by this contract
    function balance() external view returns (uint256);

    /// Maximum acceptable slippage when buying/selling underlying derivative
    function setMaxSlippage(uint256 slippage) external;
}