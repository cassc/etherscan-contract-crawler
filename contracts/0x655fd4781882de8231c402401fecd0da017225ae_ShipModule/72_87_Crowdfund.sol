// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import {ERC20SnapshotUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import {ICrowdfundEvents} from "szns/interfaces/ICrowdfundEvents.sol";

/**
 * @title Crowdfund
 * @dev Crowdfund contract that allows external contributions to raise funds.
 *  It mints tokens in return for ether contributions.
 */
contract Crowdfund is ERC20SnapshotUpgradeable, ICrowdfundEvents {
    /**
     * Error raised when the raise has closed and contributions are no longer accepted.
     */
    error RaiseClosed();

    /**
     * Timestamp when the fund raising period ends and contributions are no longer accepted.
     */
    uint256 public endDuration;
    /**
     * Number of tokens minted per ether contributed
     */
    uint256 public tokensPerEth;
    /**
     * Minimum amount of ether that must be raised
     */
    uint256 public minRaise;
    /**
     * Total amount of ether raised
     */
    uint256 public totalContributions;

    /**
     * @dev Constructor that initializes the crowdfund
     * @param _endDuration Timestamp when the fund raising period ends
     * @param _tokensPerEth Number of tokens minted per ether contributed
     * @param _minRaise Minimum amount of ether that must be raised
     */
    constructor(
        uint256 _endDuration,
        uint256 _tokensPerEth,
        uint256 _minRaise
    ) {
        endDuration = _endDuration;
        tokensPerEth = _tokensPerEth;
        minRaise = _minRaise;
        totalContributions = 0;
    }

    function __Crowdfund_init(
        uint256 _endDuration,
        uint256 _tokensPerEth,
        uint256 _minRaise
    ) internal onlyInitializing {
        __Crowdfund_init_unchained(_endDuration, _tokensPerEth, _minRaise);
    }

    /**
     * @dev Initializes the Crowdfund contract with the provided parameters.
     * This function should only be called during contract creation.
     * @param _endDuration The timestamp when the Crowdfund will end and contributions will no longer be accepted.
     * @param _tokensPerEth The number of tokens that will be minted for each Ether contributed.
     * @param _minRaise The minimum amount of Ether that must be raised for the Crowdfund to be considered successful.
     */
    function __Crowdfund_init_unchained(
        uint256 _endDuration,
        uint256 _tokensPerEth,
        uint256 _minRaise
    ) internal onlyInitializing {
        _setDuration(_endDuration);
        _setTokensPerEth(_tokensPerEth);
        _setMinRaise(_minRaise);
    }

    /**
     * @dev Set the end time for the crowdfunding campaign
     * @param _endDuration The timestamp at which the crowdfunding campaign will end
     */
    function _setDuration(uint256 _endDuration) internal onlyInitializing {
        endDuration = _endDuration;
    }

    /**
     * @dev Sets the tokens per eth for the crowdfunding campaign.
     * @param _tokensPerEth The number of tokens to mint for each ether contributed.
     */
    function _setTokensPerEth(uint256 _tokensPerEth) internal onlyInitializing {
        tokensPerEth = _tokensPerEth;
    }

    /**
     * @dev Initialize minRaise variable
     * @param _minRaise The minimum raise in ETH to be met
     */
    function _setMinRaise(uint256 _minRaise) internal onlyInitializing {
        minRaise = _minRaise;
    }

    /**
     * @dev Check if sail raise duration is over
     * @return true if sail raise still open for contributions
     */
    function _isRaiseOpen() internal view returns (bool) {
        return block.timestamp < endDuration;
    }

    /**
     * @dev Check if endRaise() was called
     * @return true if endRaise() was called
     */
    function _hasRaiseClosed() internal view returns (bool) {
        return endDuration == 0;
    }

    /**
     * @dev Contributes to the crowdfund, mints new tokens, and emits an event
     * @return minted The amount of tokens minted
     */
    function _contribute() internal returns (uint256 minted) {
        if (!_isRaiseOpen()) {
            revert RaiseClosed();
        }

        minted = tokensPerEth * msg.value;
        _mint(msg.sender, minted);
        emit Contributed(msg.sender, msg.value);

        totalContributions += msg.value;

        if (_hasRaiseMet()) {
            emit RaiseMet();
        }
    }

    /**
     * @dev Force end the sail raise and make the contract no longer accept contributions.
     * Only the captain can call this function.
     */
    function _endRaise() internal {
        endDuration = 0;
        emit ForceEndRaise();
    }

    /**
     * @dev This function checks if the total contributions have met the minimum raise goal.
     * @return true if the goal has been met, false otherwise.
     */
    function _hasRaiseMet() internal view returns (bool) {
        return totalContributions >= minRaise;
    }
}