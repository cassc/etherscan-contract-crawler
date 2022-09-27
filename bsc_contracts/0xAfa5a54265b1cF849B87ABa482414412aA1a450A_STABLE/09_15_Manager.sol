/**
 * @title Manager
 * @dev Manager contract
 *
 * @author - <USDFI TRUST>
 * for the USDFI Trust
 *
 * SPDX-License-Identifier: GNU GPLv2
 *
 **/

pragma solidity 0.6.12;

import "./MinterRole.sol";
import "./IWhitelist.sol";
import "./IBlacklist.sol";
import "./IZeroFee.sol";
import "./IReferrals.sol";
import "./SafeMath.sol";
import "./Pausable.sol";

contract Manager is Pausable {
    using SafeMath for uint256;

    /**
     * @dev Outputs the external contracts.
     */
    IWhitelist public whitelist;
    IBlacklist public blacklist;
    IZeroFee public zeroFee;

    /**
     * @dev Outputs the fee variables.
     */
    uint256 public fee;
    address public feeReceiver;

    /**
     * @dev Outputs the `freeMintSupply` variable.
     */
    uint256 public freeMintSupply;

    /**
     * @dev Sets the {fee} for transfers.
     *
     * How much fees should be deducted from a transaction.
     *
     * Requirements:
     *
     * - only `owner` can update the `fee`
     * - fee can only be lower than 10%
     *
     */
    function setFee(uint256 _fee) public onlyOwner {
        require(_fee <= 1000, "too high");
        fee = _fee;
    }

    /**
     * @dev Sets the {feeReceiver} for transfers.
     *
     * The `owner` decides which address receives the fee.
     *
     * Requirements:
     *
     * - only `owner` can update the `feeReceiver`
     */
    function setfeeReceiver(address _feeReceiver) public onlyOwner {
        feeReceiver = _feeReceiver;
    }

    /**
     * @dev Sets the {freeMintSupply} so that the minter can create new coins.
     *
     * The owner decides how many new coins may be created by the minter.
     *
     * Requirements:
     *
     * - only `owner` can update the `freeMintSupply`
     */
    function setFreeMintSupply(uint256 _freeMintSupply) public onlyPauser {
        freeMintSupply = _freeMintSupply;
    }

    /**
     * @dev Sets `external smart contracts`.
     *
     * These functions have the purpose to be flexible and to connect further automated systems
     * which will require an update in the longer term.
     *
     * Requirements:
     *
     * - only `owner` can update the external smart contracts
     * - `external smart contracts` must be correct and work
     */
    function updateZeroFeeContract(address _ZeroFeeContract) public onlyOwner {
        zeroFee = IZeroFee(_ZeroFeeContract);
    }

    function updateWhitelistContract(address _whitelistContract)
        public
        onlyOwner
    {
        whitelist = IWhitelist(_whitelistContract);
    }

    function updateBlacklistContract(address _blacklistContract)
        public
        onlyOwner
    {
        blacklist = IBlacklist(_blacklistContract);
    }
}
