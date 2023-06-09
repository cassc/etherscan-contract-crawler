import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC20.sol";

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

contract Fees is Ownable {
    uint256 public defaultFee;

    constructor(uint256 defaultFee_) {
        defaultFee = defaultFee_;
    }

    struct FeeTokenData {
        uint256 minBalance;
        uint256 fee;
    }

    //mappings
    //strategyId => feeCollector
    mapping(uint256 => address) public feeCollector;

    //strategyId => feeToken => FeeTokenData
    mapping(uint256 => mapping(address => FeeTokenData)) public feeTokenMap;

    //strategyId => depositStatus
    mapping(uint256 => bool) public depositStatus;

    //strategyId => tokenAddress => status
    mapping(uint256 => mapping(address => bool))
        public whitelistedDepositCurrencies;

    //read functions

    //calculates expected fee for specified parameters
    function calcFee(
        uint256 strategyId,
        address user,
        address feeToken
    ) public view returns (uint256) {
        FeeTokenData memory feeData = feeTokenMap[strategyId][feeToken];
        if (
            feeData.minBalance > 0 &&
            IERC20(feeToken).balanceOf(user) >= feeData.minBalance
        ) {
            return feeData.fee;
        }
        return defaultFee;
    }

    //write functions

    //sets fee benefits if user holds token
    function setTokenFee(
        uint256 strategyId,
        address feeToken,
        uint256 minBalance,
        uint256 fee
    ) external onlyOwner {
        _setTokenFee(strategyId, feeToken, minBalance, fee);
    }

    //convenience method to set fees for multiple tokens
    function setTokenMulti(
        uint256 strategyId,
        address[] calldata feeTokens,
        uint256[] calldata minBalance,
        uint256[] calldata fee
    ) external onlyOwner {
        require(
            feeTokens.length == minBalance.length &&
                minBalance.length == fee.length,
            "setMulti: length mismatch"
        );
        for (uint256 i = 0; i < feeTokens.length; i++) {
            _setTokenFee(strategyId, feeTokens[i], minBalance[i], fee[i]);
        }
    }

    function setDepositStatus(uint256 strategyId, bool status)
        external
        onlyOwner
    {
        depositStatus[strategyId] = status;
    }

    function setFeeCollector(uint256 strategyId, address newFeeCollector)
        external
        onlyOwner
    {
        feeCollector[strategyId] = newFeeCollector;
    }

    function setDefaultFee(uint256 newDefaultFee) external onlyOwner {
        require(newDefaultFee<1000, "setDefaultFee: exceed 1%");
        defaultFee = newDefaultFee;
    }

    function toggleWhitelistTokens(
        uint256 strategyId,
        address[] calldata tokens,
        bool state
    ) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            whitelistedDepositCurrencies[strategyId][tokens[i]] = state;
        }
    }

    //internal functions

    function _setTokenFee(
        uint256 strategyId,
        address feeToken,
        uint256 minBalance,
        uint256 fee
    ) internal {
        feeTokenMap[strategyId][feeToken] = FeeTokenData({
            minBalance: minBalance,
            fee: fee
        });
    }
}