//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./matic/BasicMetaTransaction.sol";
import "./openzeppelinModified/ERC20PresetMinterPauser.sol";

contract Stars is BasicMetaTransaction, ERC20PresetMinterPauser {
    using SafeMath for uint256;

    uint256 public nextMintStartTime;
    uint256 public totalSupplyThisYear;
    uint256 public remainingYearlyInflationAmt;
    uint256 public inflationBasisPoint;
    uint256 public mintLockPeriodSecs;

    /**
     * @dev Distributes tokens to inital holders,
     * locks the mint function for a specified time period,
     * sets the total supply at the beggining of the period,
     * sets inflation basis point numerator,
     * sets the mint lock period in secs.
     *
     * Parameters:
     *
     * - _admin: the Stars contract admin.
     * - _initialHolders: the initial holders of the Stars token.
     * - _prmintedAmounts: the token amount mantissas that _initialHolders will receive on deployment.
     * - _inflationBasisPoint: the yearly inflation rate basis point represented as a numerator.
     * - _mintLockPeriodSecs: the amount of seconds to lock minting after each mint.
     *
     * Requirements:
     *
     * - _initialHolders and _initialHolders must be same length.
     */
    constructor(
        address _admin,
        address[] memory _initialHolders,
        uint256[] memory _premintedAmounts,
        uint256 _inflationBasisPoint,
        uint256 _mintLockPeriodSecs
    ) public ERC20PresetMinterPauser("Mogul Stars", "STARS", _admin) {
        require(
            _initialHolders.length == _premintedAmounts.length,
            "StarToken: Wrong lengths of arrays"
        );
        for (uint256 i = 0; i < _initialHolders.length; i++) {
            _mint(_initialHolders[i], _premintedAmounts[i]);
        }

        nextMintStartTime = block.timestamp.add(_mintLockPeriodSecs);
        totalSupplyThisYear = totalSupply();
        remainingYearlyInflationAmt = totalSupplyThisYear
            .mul(_inflationBasisPoint)
            .div(10000);
        inflationBasisPoint = _inflationBasisPoint;
        mintLockPeriodSecs = _mintLockPeriodSecs;
    }

    /**
     * @dev Admin function to mint up to x% of yearly supply at
     * the beggining of the period.
     *
     * Parameters:
     *
     * - recipient: the address of the Stars contract admin.
     * - amount: token amount mantissa to mint.
     *
     * Requirements:
     *
     * - caller must be admin.
     * - amount <= remainingYearlyInflationAmt.
     */
    function mint(address recipient, uint256 amount) public override {
        require(admin == msgSender(), "Caller is not an admin");
        require(
            amount <= remainingYearlyInflationAmt,
            "Minting too many tokens for this year"
        );
        remainingYearlyInflationAmt = remainingYearlyInflationAmt.sub(amount);
        _mint(recipient, amount);
    }

    /**
     * @dev When mint lock period is over, admin will call this function
     * to reset the available minting amount to x% of total supply.
     *
     * Requirements:
     *
     * - caller must be admin.
     * - block.timestamp >= nextMintStartTime.
     */
    function updateYearPeriod() public {
        require(admin == msgSender(), "Caller is not an admin");
        require(
            block.timestamp >= nextMintStartTime,
            "Year period is not over"
        );

        nextMintStartTime = nextMintStartTime.add(mintLockPeriodSecs);
        totalSupplyThisYear = totalSupply();
        remainingYearlyInflationAmt = totalSupplyThisYear
            .mul(inflationBasisPoint)
            .div(10000);
    }

    /**
     * @dev Admin function to add a address to the whitelist.
     * When transfers are paused, whitlisted address will not be affected.
     *
     * Parameters:
     *
     * - whitelistAddress: the address to add to whitelist.
     * - isWhitelisted: whitelist status to change to.
     *
     * Requirements:
     *
     * - caller must be admin.
     */
    function changeWhitelistStatus(address whitelistAddress, bool isWhitelisted)
        public
    {
        require(admin == msgSender(), "Caller is not an admin");
        super._changeWhitelistStatus(whitelistAddress, isWhitelisted);
    }
}