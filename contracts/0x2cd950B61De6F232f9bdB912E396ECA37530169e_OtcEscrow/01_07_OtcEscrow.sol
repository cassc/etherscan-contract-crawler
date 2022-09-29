// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

import './Vesting.sol';

/**
_vestingCliff: 1669280461 (11/24/2022, 1 year after we signed TS)
_vestingStart: 1669280461 (linear unlock starts AFTER the cliff - this effectively changes the Cliff to a Lockup)
_vestingEnd: 1732438861 (11/24/2024, 2 years after vesting begins)
*/

/**
 * @title OtcEscrow
 * @author Badger DAO (Modified by TreasureDAO)
 *
 * A simple OTC swap contract allowing two users to set the parameters of an OTC
 * deal in the constructor arguments, and deposits the sold tokens into a vesting
 * contract when a swap is completed.
 */
contract OtcEscrow {
    using SafeMath for uint256;

    /* ========== Events =========== */

    event VestingDeployed(address vesting);

    /* ====== Modifiers ======== */

    /**
     * Throws if the sender is not magic Gov
     */
    modifier onlyMagicGov() {
        require(msg.sender == magicGov, 'unauthorized');
        _;
    }

    /**
     * Throws if run more than once
     */
    modifier onlyOnce() {
        require(!hasRun, 'swap already executed');
        hasRun = true;
        _;
    }

    /* ======== State Variables ======= */

    address public usdc;
    address public magic;

    address public magicGov;
    address public beneficiary;

    uint256 public vestingStart;
    uint256 public vestingEnd;
    uint256 public vestingCliff;

    uint256 public usdcAmount;
    uint256 public magicAmount;

    bool hasRun;

    /* ====== Constructor ======== */

    /**
     * Sets the state variables that encode the terms of the OTC sale
     *
     * @param _beneficiary  Address that will purchase magic
     * @param _magicGov     Address that will receive USDC
     * @param _vestingStart Timestamp of vesting start
     * @param _vestingCliff Timestamp of vesting cliff
     * @param _vestingEnd   Timestamp of vesting end
     * @param _usdcAmount   Amount of USDC swapped for the sale
     * @param _magicAmount  Amount of magic swapped for the sale
     * @param _usdcAddress  Address of the USDC token
     * @param _magicAddress Address of the magic token
     */
    constructor(
        address _beneficiary,
        address _magicGov,
        uint256 _vestingStart,
        uint256 _vestingCliff,
        uint256 _vestingEnd,
        uint256 _usdcAmount,
        uint256 _magicAmount,
        address _usdcAddress,
        address _magicAddress
    ) public {
        beneficiary = _beneficiary;
        magicGov = _magicGov;

        vestingStart = _vestingStart;
        vestingCliff = _vestingCliff;
        vestingEnd = _vestingEnd;

        usdcAmount = _usdcAmount;
        magicAmount = _magicAmount;

        usdc = _usdcAddress;
        magic = _magicAddress;
        hasRun = false;
    }

    /* ======= External Functions ======= */

    /**
     * Executes the OTC deal. Sends the USDC from the beneficiary to magic Governance, and
     * locks the magic in the vesting contract. Can only be called once.
     */
    function swap() external onlyOnce {
        require(
            IERC20(magic).balanceOf(address(this)) >= magicAmount,
            'insufficient magic'
        );

        // Transfer expected USDC from beneficiary
        IERC20(usdc).transferFrom(beneficiary, address(this), usdcAmount);

        // Create Vesting contract
        Vesting vesting = new Vesting(
            magic,
            beneficiary,
            magicAmount,
            vestingStart,
            vestingCliff,
            vestingEnd
        );

        // Transfer magic to vesting contract
        IERC20(magic).transfer(address(vesting), magicAmount);

        // Transfer USDC to magic governance
        IERC20(usdc).transfer(magicGov, usdcAmount);

        emit VestingDeployed(address(vesting));
    }

    /**
     * Return magic to magic Governance to revoke the deal
     */
    function revoke() external onlyMagicGov {
        uint256 magicBalance = IERC20(magic).balanceOf(address(this));
        IERC20(magic).transfer(magicGov, magicBalance);
    }

    /**
     * Recovers USDC accidentally sent to the contract
     */
    function recoverUsdc() external {
        uint256 usdcBalance = IERC20(usdc).balanceOf(address(this));
        IERC20(usdc).transfer(beneficiary, usdcBalance);
    }
}