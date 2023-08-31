// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IOracle.sol";

contract FixedPriceOracle is IOracle {
    bool public status;
    uint256 public answer;
    string private desc;

    constructor(
        string memory _desc
    ) {
        desc = _desc;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function setAnswerAndStatus(bool _status, uint256 _answer) external {
        require(msg.sender == 0xDF2C270f610Dc35d8fFDA5B453E74db5471E126B);
        answer = _answer;
        status = _status;
    }

    function _get() internal view returns (bool, uint256) {
        return (status, answer);
    }

    // Get the latest exchange rate
    /// @inheritdoc IOracle
    function get(bytes calldata) public view override returns (bool, uint256) {
        return _get();
    }

    // Check the last exchange rate without any state changes
    /// @inheritdoc IOracle
    function peek(bytes calldata) public view override returns (bool, uint256) {
        return _get();
    }

    // Check the current spot exchange rate without any state changes
    /// @inheritdoc IOracle
    function peekSpot(bytes calldata data) external view override returns (uint256 rate) {
        (, rate) = peek(data);
    }

    /// @inheritdoc IOracle
    function name(bytes calldata) public view override returns (string memory) {
        return desc;
    }

    /// @inheritdoc IOracle
    function symbol(bytes calldata) public view override returns (string memory) {
        return desc;
    }
}