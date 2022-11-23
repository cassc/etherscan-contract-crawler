// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../Ownable.sol";
import "../../../interfaces/IInterestReceiver.sol";
import "../../../interfaces/IInterestImplementation.sol";
import "../native/MediatorBalanceStorage.sol";

/**
 * @title InterestConnector
 * @dev This contract gives an abstract way of receiving interest on locked tokens.
 */
contract InterestConnector is Ownable, MediatorBalanceStorage {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev Tells address of the interest earning implementation for the specific token contract.
     * If interest earning is disabled, will return 0x00..00.
     * Can be an address of the deployed CompoundInterestERC20 contract.
     * @param _token address of the locked token contract.
     * @return address of the implementation contract.
     */
    function interestImplementation(address _token) public view returns (IInterestImplementation) {
        return IInterestImplementation(addressStorage[keccak256(abi.encodePacked("interestImpl", _token))]);
    }

    /**
     * @dev Initializes interest receiving functionality for the particular locked token.
     * Only owner can call this method.
     * @param _token address of the token for interest earning.
     * @param _impl address of the interest earning implementation contract.
     * @param _minCashThreshold minimum amount of underlying tokens that are not invested.
     */
    function initializeInterest(
        address _token,
        address _impl,
        uint256 _minCashThreshold
    ) external onlyOwner {
        require(address(interestImplementation(_token)) == address(0));
        _setInterestImplementation(_token, _impl);
        _setMinCashThreshold(_token, _minCashThreshold);
    }

    /**
     * @dev Sets minimum amount of tokens that cannot be invested.
     * Only owner can call this method.
     * @param _token address of the token contract.
     * @param _minCashThreshold minimum amount of underlying tokens that are not invested.
     */
    function setMinCashThreshold(address _token, uint256 _minCashThreshold) external onlyOwner {
        _setMinCashThreshold(_token, _minCashThreshold);
    }

    /**
     * @dev Tells minimum amount of tokens that are not being invested.
     * @param _token address of the invested token contract.
     * @return amount of tokens.
     */
    function minCashThreshold(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("minCashThreshold", _token))];
    }

    /**
     * @dev Disables interest for locked funds.
     * Only owner can call this method.
     * Prior to calling this function, consider to call payInterest and claimCompAndPay.
     * @param _token of token to disable interest for.
     */
    function disableInterest(address _token) external onlyOwner {
        interestImplementation(_token).withdraw(_token, uint256(-1));
        _setInterestImplementation(_token, address(0));
    }

    /**
     * @dev Invests all excess tokens. Leaves only minCashThreshold in underlying tokens.
     * Requires interest for the given token to be enabled first.
     * @param _token address of the token contract considered.
     */
    function invest(address _token) external {
        IInterestImplementation impl = interestImplementation(_token);
        // less than _token.balanceOf(this), since it does not take into account mistakenly locked tokens that should be processed via fixMediatorBalance.
        uint256 balance = mediatorBalance(_token).sub(impl.investedAmount(_token));
        uint256 minCash = minCashThreshold(_token);

        require(balance > minCash);
        uint256 amount = balance - minCash;

        IERC20(_token).safeTransfer(address(impl), amount);
        impl.invest(_token, amount);
    }

    /**
     * @dev Internal function for setting interest earning implementation contract for some token.
     * Also acts as an interest enabled flag.
     * @param _token address of the token contract.
     * @param _impl address of the implementation contract.
     */
    function _setInterestImplementation(address _token, address _impl) internal {
        require(_impl == address(0) || IInterestImplementation(_impl).isInterestSupported(_token));
        addressStorage[keccak256(abi.encodePacked("interestImpl", _token))] = _impl;
    }

    /**
     * @dev Internal function for setting minimum amount of tokens that cannot be invested.
     * @param _token address of the token contract.
     * @param _minCashThreshold minimum amount of underlying tokens that are not invested.
     */
    function _setMinCashThreshold(address _token, uint256 _minCashThreshold) internal {
        uintStorage[keccak256(abi.encodePacked("minCashThreshold", _token))] = _minCashThreshold;
    }
}