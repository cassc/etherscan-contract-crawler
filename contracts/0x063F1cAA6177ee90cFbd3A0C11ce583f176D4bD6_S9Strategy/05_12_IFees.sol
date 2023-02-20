pragma solidity >=0.8.17;

// SPDX-License-Identifier: MIT

interface IFees {
    struct FeeTokenData {
        uint256 minBalance;
        uint256 fee;
    }

    //read functions

    function defaultFee() external view returns (uint256);

    function feeCollector(uint256 strategyId) external view returns (address);

    function feeTokenMap(uint256 strategyId, address feeToken)
        external
        view
        returns (FeeTokenData memory);    

    function depositStatus(uint256 strategyId) external view returns (bool);

    function whitelistedDepositCurrencies(uint256, address)
        external
        view
        returns (bool);

    function calcFee(
        uint256 strategyId,
        address user,
        address feeToken
    ) external view returns (uint256);

    //write functions    

    function setTokenFee(
        uint256 strategyId,
        address feeToken,
        uint256 minBalance,
        uint256 fee
    ) external;

    function setTokenMulti(
        uint256 strategyId,
        address[] calldata feeTokens,
        uint256[] calldata minBalance,
        uint256[] calldata fee) external;

    function setDepositStatus(uint256 strategyId, bool status) external;

    function setFeeCollector(address newFeeCollector) external;

    function setDefaultFee(uint newDefaultFee) external;

    function toggleWhitelistTokens(
        uint256 strategyId,
        address[] calldata tokens,
        bool state
    ) external;
}