// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./access/HasERC677TokenParent.sol";

/**
 * @title Crunch Multi Vesting V2
 * @author Enzo CACERES <[email protected]>
 * @notice Allow the vesting of multiple users using only one contract.
 */
contract CrunchMultiVestingV2 is HasERC677TokenParent {
    /// see IERC20.Transfer
    event Transfer(address indexed from, address indexed to, uint256 value);

    // prettier-ignore
    event VestingBegin(
        uint256 startDate
    );

    // prettier-ignore
    event TokensReleased(
        uint256 indexed vestingId,
        address indexed beneficiary,
        uint256 amount
    );

    // prettier-ignore
    event VestingCreated(
        uint256 indexed vestingId,
        address indexed beneficiary,
        uint256 amount,
        uint256 cliffDuration,
        uint256 duration,
        bool revocable
    );

    // prettier-ignore
    event VestingRevoked(
        uint256 indexed vestingId,
        address indexed beneficiary,
        uint256 refund
    );

    // prettier-ignore
    event VestingTransfered(
        uint256 indexed vestingId,
        address indexed from,
        address indexed to
    );

    struct Vesting {
        /** vesting id. */
        uint256 id;
        /** address that will receive the token. */
        address beneficiary;
        /** the amount of token to vest. */
        uint256 amount;
        /** the cliff time of the token vesting. */
        uint256 cliffDuration;
        /** the duration of the token vesting. */
        uint256 duration;
        /** whether the vesting can be revoked. */
        bool revocable;
        /** whether the vesting is revoked. */
        bool revoked;
        /** the amount of the token released. */
        uint256 released;
    }

    /** currently locked tokens that are being used by all of the vestings */
    uint256 public totalSupply;

    uint256 public startDate;

    /** mapping to vesting list */
    mapping(uint256 => Vesting) public vestings;

    /** mapping to list of address's owning vesting id */
    mapping(address => uint256[]) public owned;

    /** always incrementing value to generate the next vesting id */
    uint256 _idCounter;

    /**
     * @notice Instanciate a new contract.
     * @param crunch CRUNCH token address.
     */
    constructor(address crunch) HasERC677TokenParent(crunch) {}

    /**
     * @notice Fake an ERC20-like contract allowing it to be displayed from wallets.
     * @return the contract 'fake' token name.
     */
    function name() external pure returns (string memory) {
        return "Vested CRUNCH Token v2 (multi)";
    }

    /**
     * @notice Fake an ERC20-like contract allowing it to be displayed from wallets.
     * @return the contract 'fake' token symbol.
     */
    function symbol() external pure returns (string memory) {
        return "mvCRUNCH";
    }

    /**
     * @notice Fake an ERC20-like contract allowing it to be displayed from wallets.
     * @return the crunch's decimals value.
     */
    function decimals() external view returns (uint8) {
        return parentToken.decimals();
    }

    /**
     * @notice Get the current reserve (or balance) of the contract in CRUNCH.
     * @return The balance of CRUNCH this contract has.
     */
    function reserve() public view returns (uint256) {
        return parentToken.balanceOf(address(this));
    }

    /**
     * @notice Get the available reserve.
     * @return The number of CRUNCH that can be used to create another vesting.
     */
    function availableReserve() public view returns (uint256) {
        return reserve() - totalSupply;
    }

    /**
     * @notice Begin the vesting of everyone at the current block timestamp.
     */
    function beginNow() external onlyOwner {
        _begin(block.timestamp);
    }

    /**
     * @notice Begin the vesting of everyone at a specified timestamp.
     * @param timestamp Timestamp to use as a begin date.
     */
    function beginAt(uint256 timestamp) external onlyOwner {
        require(timestamp != 0, "MultiVesting: timestamp cannot be zero");

        _begin(timestamp);
    }

    /**
     * @notice Create a new vesting.
     *
     * Requirements:
     * - caller must be the owner
     * - `amount` must not be zero
     * - `beneficiary` must not be the null address
     * - `cliffDuration` must be less than the duration
     * - `duration` must not be zero
     * - there must be enough available reserve to accept the amount
     *
     * @dev A `VestingCreated` event will be emitted.
     * @param beneficiary Address that will receive CRUNCH tokens.
     * @param amount Amount of CRUNCH to vest.
     * @param cliffDuration Cliff duration in seconds.
     * @param duration Vesting duration in seconds.
     */
    function vest(
        address beneficiary,
        uint256 amount,
        uint256 cliffDuration,
        uint256 duration,
        bool revocable
    ) external onlyOwner onlyWhenNotStarted {
        _requireVestInputs(duration);
        _vest(beneficiary, amount, cliffDuration, duration, revocable);
    }

    /**
     * @notice Create multiple vesting at once.
     *
     * Requirements:
     * - caller must be the owner
     * - `amounts` must not countains a zero values
     * - `beneficiaries` must not contains null addresses
     * - `cliffDuration` must be less than the duration
     * - `duration` must not be zero
     * - there must be enough available reserve to accept the amount
     *
     * @dev A `VestingCreated` event will be emitted.
     * @param beneficiaries Addresses that will receive CRUNCH tokens.
     * @param amounts Amounts of CRUNCH to vest.
     * @param cliffDuration Cliff duration in seconds.
     * @param duration Vesting duration in seconds.
     */
    function vestMultiple(
        address[] calldata beneficiaries,
        uint256[] calldata amounts,
        uint256 cliffDuration,
        uint256 duration,
        bool revocable
    ) external onlyOwner onlyWhenNotStarted {
        require(beneficiaries.length == amounts.length, "MultiVesting: arrays are not the same length");
        require(beneficiaries.length != 0, "MultiVesting: must vest at least one person");
        _requireVestInputs(duration);

        for (uint256 index = 0; index < beneficiaries.length; ++index) {
            _vest(beneficiaries[index], amounts[index], cliffDuration, duration, revocable);
        }
    }

    /**
     * @notice Transfer a vesting to another person.
     * @dev A `VestingTransfered` event will be emitted.
     * @param to Receiving address.
     * @param vestingId Vesting ID to transfer.
     */
    function transfer(address to, uint256 vestingId) external {
        _transfer(_getVesting(vestingId, _msgSender()), to);
    }

    /**
     * @notice Release the tokens of a specified vesting.
     *
     * Requirements:
     * - the vesting must exists
     * - the caller must be the vesting's beneficiary
     * - at least one token must be released
     *
     * @dev A `TokensReleased` event will be emitted.
     * @param vestingId Vesting ID to release.
     */
    function release(uint256 vestingId) external returns (uint256) {
        return _release(_getVesting(vestingId, _msgSender()));
    }

    /**
     * @notice Release the tokens of a all of sender's vesting.
     *
     * Requirements:
     * - at least one token must be released
     *
     * @dev `TokensReleased` events will be emitted.
     */
    function releaseAll() external returns (uint256) {
        return _releaseAll(_msgSender());
    }

    /**
     * @notice Release the tokens of a specified vesting.
     *
     * Requirements:
     * - caller must be the owner
     * - the vesting must exists
     * - at least one token must be released
     *
     * @dev A `TokensReleased` event will be emitted.
     * @param vestingId Vesting ID to release.
     */
    function releaseFor(uint256 vestingId) external onlyOwner returns (uint256) {
        return _release(_getVesting(vestingId));
    }

    /**
     * @notice Release the tokens of a all of beneficiary's vesting.
     *
     * Requirements:
     * - caller must be the owner
     * - at least one token must be released
     *
     * @dev `TokensReleased` events will be emitted.
     */
    function releaseAllFor(address beneficiary) external onlyOwner returns (uint256) {
        return _releaseAll(beneficiary);
    }

    /**
     * @notice Revoke a vesting.
     *
     * Requirements:
     * - caller must be the owner
     * - the vesting must be revocable
     * - the vesting must be not be already revoked
     *
     * @dev `VestingRevoked` events will be emitted.
     * @param vestingId Vesting ID to revoke.
     * @param sendBack Should the revoked tokens stay in the contract or be sent back to the owner?
     */
    function revoke(uint256 vestingId, bool sendBack) public onlyOwner returns (uint256) {
        return _revoke(_getVesting(vestingId), sendBack);
    }

    /**
     * @notice Test if an address is the beneficiary of a vesting.
     * @return `true` if the address is the beneficiary of the vesting, `false` otherwise.
     */
    function isBeneficiary(uint256 vestingId, address account) public view returns (bool) {
        return _isBeneficiary(_getVesting(vestingId), account);
    }

    /**
     * @notice Test if an address has at least one vesting.
     * @return `true` if the address has one or more vesting.
     */
    function isVested(address beneficiary) public view returns (bool) {
        return ownedCount(beneficiary) != 0;
    }

    /**
     * @notice Get the releasable amount of tokens.
     * @param vestingId Vesting ID to check.
     * @return The releasable amounts.
     */
    function releasableAmount(uint256 vestingId) public view returns (uint256) {
        return _releasableAmount(_getVesting(vestingId));
    }

    /**
     * @notice Get the vested amount of tokens.
     * @param vestingId Vesting ID to check.
     * @return The vested amount of the vestings.
     */
    function vestedAmount(uint256 vestingId) public view returns (uint256) {
        return _vestedAmount(_getVesting(vestingId));
    }

    /**
     * @notice Get the number of vesting for an address.
     * @param beneficiary Address to check.
     * @return The amount of vesting for the address.
     */
    function ownedCount(address beneficiary) public view returns (uint256) {
        return owned[beneficiary].length;
    }

    /**
     * @notice Get the remaining amount of token of a beneficiary.
     * @dev This function is to make wallets able to display the amount in their UI.
     * @param beneficiary Address to check.
     * @return balance The remaining amount of tokens.
     */
    function balanceOf(address beneficiary) external view returns (uint256 balance) {
        uint256[] storage indexes = owned[beneficiary];

        for (uint256 index = 0; index < indexes.length; ++index) {
            uint256 vestingId = indexes[index];

            balance += balanceOfVesting(vestingId);
        }
    }

    /**
     * @notice Get the remaining amount of token of a specified vesting.
     * @param vestingId Vesting ID to check.
     * @return The remaining amount of tokens.
     */
    function balanceOfVesting(uint256 vestingId) public view returns (uint256) {
        return _balanceOfVesting(_getVesting(vestingId));
    }

    /**
     * @notice Send the available token back to the owner.
     */
    function emptyAvailableReserve() external onlyOwner {
        uint256 available = availableReserve();
        require(available > 0, "MultiVesting: no token available");

        parentToken.transfer(owner(), available);
    }

    /**
     * @notice Get the remaining amount of token of a specified vesting.
     * @param vesting Vesting to check.
     * @return The remaining amount of tokens.
     */
    function _balanceOfVesting(Vesting storage vesting) internal view returns (uint256) {
        return vesting.amount - vesting.released;
    }

    /**
     * @notice Begin the vesting for everyone.
     * @param timestamp Timestamp to use for the start date.
     * @dev A `VestingBegin` event will be emitted.
     */
    function _begin(uint256 timestamp) internal onlyWhenNotStarted {
        startDate = timestamp;

        emit VestingBegin(startDate);
    }

    /**
     * @notice Check the shared inputs of a vest method.
     */
    function _requireVestInputs(uint256 duration) internal pure {
        require(duration > 0, "MultiVesting: duration is 0");
    }

    /**
     * @notice Create a vesting.
     */
    function _vest(
        address beneficiary,
        uint256 amount,
        uint256 cliffDuration,
        uint256 duration,
        bool revocable
    ) internal {
        require(beneficiary != address(0), "MultiVesting: beneficiary is the zero address");
        require(amount > 0, "MultiVesting: amount is 0");
        require(availableReserve() >= amount, "MultiVesting: available reserve is not enough");

        uint256 vestingId = _idCounter++; /* post-increment */

        // prettier-ignore
        vestings[vestingId] = Vesting({
            id: vestingId,
            beneficiary: beneficiary,
            amount: amount,
            cliffDuration: cliffDuration,
            duration: duration,
            revocable: revocable,
            revoked: false,
            released: 0
        });

        _addOwnership(beneficiary, vestingId);

        totalSupply += amount;

        emit VestingCreated(vestingId, beneficiary, amount, cliffDuration, duration, revocable);
        emit Transfer(address(0), beneficiary, amount);
    }

    /**
     * @notice Transfer a vesting to another address.
     */
    function _transfer(Vesting storage vesting, address to) internal {
        address from = vesting.beneficiary;

        require(from != to, "MultiVesting: cannot transfer to itself");
        require(to != address(0), "MultiVesting: target is the zero address");

        _removeOwnership(from, vesting.id);
        _addOwnership(to, vesting.id);

        vesting.beneficiary = to;

        emit VestingTransfered(vesting.id, from, to);
        emit Transfer(from, to, _balanceOfVesting(vesting));
    }

    /**
     * @dev Internal implementation of the release() method.
     * @dev The methods will fail if there is no tokens due.
     * @dev A `TokensReleased` event will be emitted.
     * @param vesting Vesting to release.
     */
    function _release(Vesting storage vesting) internal returns (uint256 unreleased) {
        unreleased = _doRelease(vesting);
        _checkAmount(unreleased);
    }

    /**
     * @dev Internal implementation of the releaseAll() method.
     * @dev The methods will fail if there is no tokens due.
     * @dev `TokensReleased` events will be emitted.
     * @param beneficiary Address to release all vesting from.
     */
    function _releaseAll(address beneficiary) internal returns (uint256 unreleased) {
        uint256[] storage indexes = owned[beneficiary];

        for (uint256 index = 0; index < indexes.length; ++index) {
            uint256 vestingId = indexes[index];
            Vesting storage vesting = vestings[vestingId];

            unreleased += _doRelease(vesting);
        }

        _checkAmount(unreleased);
    }

    /**
     * @dev Actually releasing the vestiong.
     * @dev This method will not fail. (aside from a lack of reserve, which should never happen!)
     */
    function _doRelease(Vesting storage vesting) internal returns (uint256 unreleased) {
        unreleased = _releasableAmount(vesting);

        if (unreleased != 0) {
            parentToken.transfer(vesting.beneficiary, unreleased);

            vesting.released += unreleased;
            totalSupply -= unreleased;

            emit TokensReleased(vesting.id, vesting.beneficiary, unreleased);
            emit Transfer(vesting.beneficiary, address(0), unreleased);
        }
    }

    /**
     * @dev Revert the transaction if the value is zero.
     */
    function _checkAmount(uint256 unreleased) internal pure {
        require(unreleased > 0, "MultiVesting: no tokens are due");
    }

    /**
     * @dev Revoke a vesting and send the extra CRUNCH back to the owner.
     */
    function _revoke(Vesting storage vesting, bool sendBack) internal returns (uint256 refund) {
        require(vesting.revocable, "MultiVesting: token not revocable");
        require(!vesting.revoked, "MultiVesting: token already revoked");

        uint256 unreleased = _releasableAmount(vesting);
        refund = vesting.amount - vesting.released - unreleased;

        vesting.revoked = true;
        vesting.amount -= refund;
        totalSupply -= refund;

        if (sendBack) {
            parentToken.transfer(owner(), refund);
        }

        emit VestingRevoked(vesting.id, vesting.beneficiary, refund);
        emit Transfer(vesting.beneficiary, address(0), refund);
    }

    /**
     * @dev Test if the vesting's beneficiary is the same as the specified address.
     */
    function _isBeneficiary(Vesting storage vesting, address account) internal view returns (bool) {
        return vesting.beneficiary == account;
    }

    /**
     * @dev Compute the releasable amount.
     * @param vesting Vesting instance.
     */
    function _releasableAmount(Vesting memory vesting) internal view returns (uint256) {
        return _vestedAmount(vesting) - vesting.released;
    }

    /**
     * @dev Compute the vested amount.
     * @param vesting Vesting instance.
     */
    function _vestedAmount(Vesting memory vesting) internal view returns (uint256) {
        if (startDate == 0) {
            return 0;
        }

        uint256 cliffEnd = startDate + vesting.cliffDuration;

        if (block.timestamp < cliffEnd) {
            return 0;
        }

        if ((block.timestamp >= cliffEnd + vesting.duration) || vesting.revoked) {
            return vesting.amount;
        }

        return (vesting.amount * (block.timestamp - cliffEnd)) / vesting.duration;
    }

    /**
     * @dev Get a vesting.
     * @return vesting struct stored in the storage.
     */
    function _getVesting(uint256 vestingId) internal view returns (Vesting storage vesting) {
        vesting = vestings[vestingId];
        require(vesting.beneficiary != address(0), "MultiVesting: vesting does not exists");
    }

    /**
     * @dev Get a vesting and make sure it is from the right beneficiary.
     * @param beneficiary Address to get it from.
     * @return vesting struct stored in the storage.
     */
    function _getVesting(uint256 vestingId, address beneficiary) internal view returns (Vesting storage vesting) {
        vesting = _getVesting(vestingId);
        require(vesting.beneficiary == beneficiary, "MultiVesting: not the beneficiary");
    }

    /**
     * @dev Remove the vesting from the ownership mapping.
     */
    function _removeOwnership(address account, uint256 vestingId) internal returns (bool) {
        uint256[] storage indexes = owned[account];

        (bool found, uint256 index) = _indexOf(indexes, vestingId);
        if (!found) {
            return false;
        }

        if (indexes.length <= 1) {
            delete owned[account];
        } else {
            indexes[index] = indexes[indexes.length - 1];
            indexes.pop();
        }

        return true;
    }

    /**
     * @dev Add the vesting ID to the ownership mapping.
     */
    function _addOwnership(address account, uint256 vestingId) internal {
        owned[account].push(vestingId);
    }

    /**
     * @dev Find the index of a value in an array.
     * @param array Haystack.
     * @param value Needle.
     * @return If the first value is `true`, that mean that the needle has been found and the index is stored in the second value. Else if `false`, the value isn't in the array and the second value should be discarded.
     */
    function _indexOf(uint256[] storage array, uint256 value) internal view returns (bool, uint256) {
        for (uint256 index = 0; index < array.length; ++index) {
            if (array[index] == value) {
                return (true, index);
            }
        }

        return (false, 0);
    }

    /**
     * @dev Revert if the start date is not zero.
     */
    modifier onlyWhenNotStarted() {
        require(startDate == 0, "MultiVesting: already started");
        _;
    }
}