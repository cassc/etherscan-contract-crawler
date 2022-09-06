pragma solidity 0.8.9;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// Contract for conditionally performing actions depending on if it's on POS or POW fork
/// in order to safely split account's holding (e.g. move POW funds to different wallet
/// without replay risk on POS chain).
///
/// Using the block.difficulty check from https://eips.ethereum.org/EIPS/eip-4399
///
/// Supports sending ETH, ERC20, ERC721 (or any contract with transferFrom)
///
/// Assumptions:
///     - The contract is deployed before the fork to ensure that it exists on both forks.
///     - Caller knows that the fork already occurred.
///     - block.difficulty reports difficulty on POW chain correctly (and wasn't updated in client to be over 2^64)
contract PoSPoWSplitter {
    using SafeERC20 for IERC20;

    /******* Event ********/
    event PoSForkRecorded();

    /******* Modifiers ********/
    modifier onlyOnPOS() {
        require(_onPOSCHain(), "only on POS fork");
        _;
    }

    modifier notOnPOS() {
        require(!_onPOSCHain(), "only not on POS fork");
        _;
    }

    /******* Constants & Storage ********/

    /// flag for resolved POS state
    bool public thresholdPassedRecorded;

    uint immutable public difficultyThresholdPOS;

    constructor(uint _threshold) {
        // threshold is settable to facilitate testing
        difficultyThresholdPOS = _threshold;
    }

    /******* External views ********/

    // convenience view
    function difficulty() external view returns (uint) {
        return block.difficulty;
    }

    function onPOSCHain() external view returns (bool) {
        return _onPOSCHain();
    }

    /******* Internal views ********/

    function _onPOSCHain() internal view returns (bool) {
        // Rither the difficulty is above threshold or it was previously recorded to be above threshold.
        // This is needed because there's a very small chance that RANDAO can return a value under the threshold
        // an any specific time (although highly unlikely)
        return block.difficulty > difficultyThresholdPOS || thresholdPassedRecorded;
    }

    /******* Mutative ********/

    /// can run set isPOSFork once after difficulty > TTD
    /// before that will revert, and after that will revert as well
    function recordThresholdPassed() external onlyOnPOS {
        require(!thresholdPassedRecorded, "already recorded");
        thresholdPassedRecorded = true;
        emit PoSForkRecorded();
    }

    /******* Sending ETH ********/

    function sendETHPOW(address to) external payable notOnPOS {
        _sendETH(to);
    }

    function sendETHPOS(address to) external payable onlyOnPOS {
        _sendETH(to);
    }

    /******* ERC20 & ERC721 ********/

    /// ERC721 has same signature for "transferFrom" but different meaning to the last "uint256" (tokenId vs. amount)

    /// assumes approval was granted
    function safeTransferTokenPOW(address token, address to, uint amountOrId) external notOnPOS {
        _safeTokenTransfer(token, to, amountOrId);
    }

    /// assumes approval was granted
    function safeTransferTokenPOS(address token, address to, uint amountOrId) external onlyOnPOS {
        _safeTokenTransfer(token, to, amountOrId);
    }

    /******* Internal mutative ********/

    function _sendETH(address to) internal {
        (bool success, ) = address(to).call{value : msg.value}("");
        require(success, "sending ETH unsuccessful");
    }

    function _safeTokenTransfer(address token, address to, uint amountOrId) internal {
        IERC20(token).safeTransferFrom(msg.sender, to, amountOrId);
    }
}