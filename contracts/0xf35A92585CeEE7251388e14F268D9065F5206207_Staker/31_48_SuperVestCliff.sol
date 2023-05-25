// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// TRUFFLE
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract SuperVestCliff {
    using SafeMath for uint256;
    using Address for address;

    address public tokenAddress;

    event Claimed(
        address owner,
        address beneficiary,
        uint256 amount,
        uint256 index
    );
    event ClaimCreated(address owner, address beneficiary, uint256 index);

    struct Claim {
        address owner;
        address beneficiary;
        uint256[] timePeriods;
        uint256[] tokenAmounts;
        uint256 totalAmount;
        uint256 amountClaimed;
        uint256 periodsClaimed;
    }
    Claim[] private claims;

    mapping(address => uint256[]) private _ownerClaims;
    mapping(address => uint256[]) private _beneficiaryClaims;

    constructor(address _tokenAddress) public {
        tokenAddress = _tokenAddress;
    }

    /**
     * Get Owner Claims
     *
     * @param owner - Claim Owner Address
     */
    function ownerClaims(address owner)
        external
        view
        returns (uint256[] memory)
    {
        require(owner != address(0), "Owner address cannot be 0");
        return _ownerClaims[owner];
    }

    /**
     * Get Beneficiary Claims
     *
     * @param beneficiary - Claim Owner Address
     */
    function beneficiaryClaims(address beneficiary)
        external
        view
        returns (uint256[] memory)
    {
        require(beneficiary != address(0), "Beneficiary address cannot be 0");
        return _beneficiaryClaims[beneficiary];
    }

    /**
     * Get Amount Claimed
     *
     * @param index - Claim Index
     */
    function claimed(uint256 index) external view returns (uint256) {
        return claims[index].amountClaimed;
    }

    /**
     * Get Total Claim Amount
     *
     * @param index - Claim Index
     */
    function totalAmount(uint256 index) external view returns (uint256) {
        return claims[index].totalAmount;
    }

    /**
     * Get Time Periods of Claim
     *
     * @param index - Claim Index
     */
    function timePeriods(uint256 index)
        external
        view
        returns (uint256[] memory)
    {
        return claims[index].timePeriods;
    }

    /**
     * Get Token Amounts of Claim
     *
     * @param index - Claim Index
     */
    function tokenAmounts(uint256 index)
        external
        view
        returns (uint256[] memory)
    {
        return claims[index].tokenAmounts;
    }

    /**
     * Create a Claim - To Vest Tokens to Beneficiary
     *
     * @param _beneficiary - Tokens will be claimed by _beneficiary
     * @param _timePeriods - uint256 Array of Epochs
     * @param _tokenAmounts - uin256 Array of Amounts to transfer at each time period
     */
    function createClaim(
        address _beneficiary,
        uint256[] memory _timePeriods,
        uint256[] memory _tokenAmounts
    ) public returns (bool) {
        require(
            _timePeriods.length == _tokenAmounts.length,
            "_timePeriods & _tokenAmounts length mismatch"
        );
        require(tokenAddress.isContract(), "Invalid tokenAddress");
        require(_beneficiary != address(0), "Cannot Vest to address 0");
        // Calculate total amount
        uint256 _totalAmount = 0;
        for (uint256 i = 0; i < _tokenAmounts.length; i++) {
            _totalAmount = _totalAmount.add(_tokenAmounts[i]);
        }
        require(_totalAmount > 0, "Provide Token Amounts to Vest");
        require(
            ERC20(tokenAddress).allowance(msg.sender, address(this)) >=
                _totalAmount,
            "Provide token allowance to SuperVestCliff contract"
        );
        // Transfer Tokens to SuperStreamClaim
        ERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _totalAmount
        );
        // Create Claim
        Claim memory claim =
            Claim({
                owner: msg.sender,
                beneficiary: _beneficiary,
                timePeriods: _timePeriods,
                tokenAmounts: _tokenAmounts,
                totalAmount: _totalAmount,
                amountClaimed: 0,
                periodsClaimed: 0
            });
        claims.push(claim);
        uint256 index = claims.length - 1;
        // Map Claim Index to Owner & Beneficiary
        _ownerClaims[msg.sender].push(index);
        _beneficiaryClaims[_beneficiary].push(index);
        emit ClaimCreated(msg.sender, _beneficiary, index);
        return true;
    }

    /**
     * Claim Tokens
     *
     * @param index - Index of the Claim
     */
    function claim(uint256 index) external {
        Claim storage claim = claims[index];
        // Check if msg.sender is the beneficiary
        require(
            claim.beneficiary == msg.sender,
            "Only beneficiary can claim tokens"
        );
        // Check if anything is left to release
        require(
            claim.periodsClaimed < claim.timePeriods.length,
            "Nothing to release"
        );
        // Calculate releasable amount
        uint256 amount = 0;
        for (
            uint256 i = claim.periodsClaimed;
            i < claim.timePeriods.length;
            i++
        ) {
            if (claim.timePeriods[i] <= block.timestamp) {
                amount = amount.add(claim.tokenAmounts[i]);
                claim.periodsClaimed = claim.periodsClaimed.add(1);
            } else {
                break;
            }
        }
        // If there is any amount to release
        require(amount > 0, "Nothing to release");
        // Transfer Tokens from Owner to Beneficiary
        ERC20(tokenAddress).transfer(claim.beneficiary, amount);
        claim.amountClaimed = claim.amountClaimed.add(amount);
        emit Claimed(claim.owner, claim.beneficiary, amount, index);
    }

    /**
     * Get Amount of tokens that can be claimed
     *
     * @param index - Index of the Claim
     */
    function claimableAmount(uint256 index) public view returns (uint256) {
        Claim storage claim = claims[index];
        // Calculate Claimable Amount
        uint256 amount = 0;
        for (
            uint256 i = claim.periodsClaimed;
            i < claim.timePeriods.length;
            i++
        ) {
            if (claim.timePeriods[i] <= block.timestamp) {
                amount = amount.add(claim.tokenAmounts[i]);
            } else {
                break;
            }
        }
        return amount;
    }
}