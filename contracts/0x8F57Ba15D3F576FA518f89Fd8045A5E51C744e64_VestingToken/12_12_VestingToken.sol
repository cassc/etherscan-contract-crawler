// SPDX-License-Identifier: None
// Unvest Contracts (last updated v2.0.0) (VestingToken.sol)
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IFeeManager.sol";
import "./interfaces/IVestingToken.sol";

error AddressIsNotAContract();
error MaxAllowedMilestonesHit();
error ClaimableAmountOfImportIsGreaterThanExpected();
error EqualPercentagesOnlyAllowedBeforeLinear();
error InputArraysMustHaveSameLength();
error LastPercentageMustBe100();
error MilestonePercentagesNotSorted();
error MilestoneTimestampsNotSorted();
error MoreThanTwoEqualPercentages();
error OnlyLastPercentageCanBe100();
error UnlockedIsGreaterThanExpected();
error UnsuccessfulFetchOfTokenBalance();

/**
 * @title VestingToken
 * @notice VestingToken locks ERC20 and contains the logic for tokens to be partially unlocked based on
 * milestones.
 */
contract VestingToken is ERC20Upgradeable, ReentrancyGuardUpgradeable, IVestingToken {
    using SafeERC20Upgradeable for ERC20Upgradeable;
    using AddressUpgradeable for address;

    /**
     * @dev `claimedAmountAfterTransfer` is used to calculate the `_claimableAmount` of an account. It's value is
     * updated on every `transfer`, `transferFrom`, and `claim` calls.
     * @dev While `claimedAmountAfterTransfer` contains a fraction of the `claimedAmountAfterTransfer`s of every token
     * transfer the owner of account receives, `claimedBalance` works as a counter for tokens claimed by this account.
     */
    struct Metadata {
        uint256 claimedAmountAfterTransfer;
        uint256 claimedBalance;
    }

    /**
     * @param claimer Address that will receive the `amount` of `underlyingToken`.
     * @param amount  Amount of tokens that will be sent to the `claimer`.
     */
    event Claim(address indexed claimer, uint256 amount);

    /**
     * @param milestoneIndex Index of the Milestone reached.
     * @param percentage     Claimable percentage of tokens.
     */
    event MilestoneReached(uint256 indexed milestoneIndex, uint64 percentage);

    /**
     * @dev Percentages and fees are calculated using 18 decimals where 1 ether is 100%.
     */
    uint256 internal constant ONE = 1 ether;

    /**
     * @notice The ERC20 token that this contract will be vesting.
     */
    ERC20Upgradeable public underlyingToken;

    /**
     * @notice The manager that deployed this contract which controls the values for `fee` and `feeCollector`.
     */
    IFeeManager public manager;

    /**
     * @dev The `decimals` value that is fetched from `underlyingToken`.
     */
    uint8 internal _decimals;

    /**
     * @dev The initial supply used for calculating the `claimableSupply`, `claimedSupply`, and `lockedSupply`.
     */
    uint256 internal _startingSupply;

    /**
     * @dev The imported claimed supply is necessary for an accurate `claimableSupply` but leads to an improper
     * offset in `claimedSupply`, so we keep track of this to account for it.
     */
    uint256 internal _importedClaimedSupply;

    /**
     * @notice An array of Milestones describing the times and behaviour of the rules to release the vested tokens.
     */
    Milestone[] internal _milestones;

    /**
     * @notice Keep track of the last reached Milestone to minimize the iterations over the milestones and save gas.
     */
    uint256 internal _lastReachedMilestone;

    /**
     * @dev Maps a an address to the metadata needed to calculate `claimableBalance` and `lockedBalanceOf`.
     */
    mapping(address => Metadata) internal _metadata;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract by setting up the ERC20 variables, the `underlyingToken`, and the
     * `milestonesArray` information.
     *
     * @dev The Ramp of the first Milestone in the `milestonesArray` will always act as a Cliff since it doesn't have
     * a previous milestone.
     *
     * Requirements:
     *
     * - `underlyingTokenAddress` cannot be the zero address.
     * - `timestamps` must be given in ascending order.
     * - `percentages` must be given in ascending order and the last one must always be 1 eth, where 1 eth equals to
     * 100%.
     * - 2 `percentages` may have the same value as long as they are followed by a `Ramp.Linear` Milestone.
     *
     * @param name                   This ERC20 token name.
     * @param symbol                 This ERC20 token symbol.
     * @param underlyingTokenAddress The ERC20 token that will be held by this contract.
     * @param milestonesArray        Array of all `Milestone`s for this contract's lifetime.
     */
    function initialize(
        string memory name,
        string memory symbol,
        address underlyingTokenAddress,
        Milestone[] calldata milestonesArray
    ) external override initializer {
        __ERC20_init(name, symbol);
        __ReentrancyGuard_init();

        manager = IFeeManager(_msgSender());

        if (!underlyingTokenAddress.isContract()) revert AddressIsNotAContract();
        if (milestonesArray.length > 826) revert MaxAllowedMilestonesHit();

        Milestone calldata current = milestonesArray[0];
        bool twoInARow;

        for (uint256 i = 0; i < milestonesArray.length; i++) {
            if (i > 0) {
                Milestone calldata previous = current;
                current = milestonesArray[i];

                _sortRule(current, previous);
                _twoInARowRule(current, previous, twoInARow);

                twoInARow = previous.percentage == current.percentage;
            }

            _hundredPercentRule(current, i == milestonesArray.length - 1);
            _milestones.push(current);
        }

        underlyingToken = ERC20Upgradeable(underlyingTokenAddress);
        _decimals = _tryFetchDecimals();
    }

    /**
     * @dev Returns the number of decimals used to get its user representation. For example, if `decimals` equals `2`,
     * a balance of `505` tokens should be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between Ether and Wei. Since we can't predict
     * the decimals the `underlyingToken` will have, we need to provide our own implementation which is setup at
     * initialization.
     *
     * NOTE: This information is only used for _display_ purposes: it in no way affects any of the arithmetic of the
     * contract.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @notice Vests an `amount` of `underlyingToken` and mints LVTs for a `recipient`.
     *
     * Requirements:
     *
     * - `msg.sender` must have approved this contract an amount of `underlyingToken` greater or equal than `amount`.
     *
     * @param recipient The address that will receive the newly minted LVT.
     * @param amount    The amount of `underlyingToken` to be vested.
     */
    function addRecipient(address recipient, uint256 amount) external nonReentrant {
        uint256 currentBalance = _getBalanceOfThis();

        underlyingToken.safeTransferFrom(_msgSender(), address(this), amount);
        uint256 transferredAmount = _getBalanceOfThis() - currentBalance;

        _startingSupply += transferredAmount;
        _mint(recipient, transferredAmount);
    }

    /**
     * @notice Vests multiple `amounts` of `underlyingToken` and mints LVTs for multiple `recipients`.
     *
     * Requirements:
     *
     * - `recipients` and `amounts` must have the same length.
     * - `msg.sender` must have approved this contract an amount of `underlyingToken` greater or equal than the sum of
     * all of the `amounts`.
     *
     * @param recipients Array of addresses that will receive the newly minted LVTs.
     * @param amounts    Array of amounts of `underlyingToken` to be vested.
     */
    function addRecipients(address[] calldata recipients, uint256[] calldata amounts) external nonReentrant {
        if (recipients.length != amounts.length) revert InputArraysMustHaveSameLength();
        uint256 currentBalance = _getBalanceOfThis();

        uint256 totalAmount;
        for (uint256 i = 0; i < recipients.length; i++) {
            totalAmount += amounts[i];
        }
        underlyingToken.safeTransferFrom(_msgSender(), address(this), totalAmount);
        uint256 transferredAmount = _getBalanceOfThis() - currentBalance;

        _startingSupply += transferredAmount;
        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = transferredAmount == totalAmount
                ? amounts[i]
                : (amounts[i] * transferredAmount) / totalAmount;
            _mint(recipient, amount);
        }
    }

    /**
     * @notice Behaves as `addRecipient` but provides the ability to set the initial state of the recipient's metadata.
     * @notice This functionality is included in order to allow users to restart an allocation on a different chain and
     * keeping the inner state as close as possible to the original.
     *
     * @dev The `Metadata.claimedAmountAfterTransfer` for the recipient is inferred from the parameters.
     * @dev The `Metadata.claimedBalance` is lost in the transfer, the closest value will be
     * `claimedAmountAfterTransfer`.
     * @dev In the rare case where the contract and it's users are migrated after the last milestone has been reached,
     * the `claimedAmountAfterTransfer` can't be inferred and the `claimedSupply` value for the whole contract is lost
     * in the transfer.
     * @dev The decision to do this is to minimize the altering of metadata to the amount that is being transferred and
     * protect an attack that would render the contract unusable.
     *
     * Requirements:
     *
     * - `unlocked` must be less than or equal to this contracts `unlockedPercentage`.
     * - `claimableAmountOfImport` must be less than or equal than the amount that would be claimable given the values
     *  of `amount` and `percentage`.
     * - `msg.sender` must have approved this contract an amount of `underlyingToken` greater or equal than `amount`.
     *
     * @param recipient               The address that will receive the newly minted LVT.
     * @param amount                  The amount of `underlyingToken` to be vested.
     * @param claimableAmountOfImport The amount of `underlyingToken` from this transaction that should be considered
     *                                claimable.
     * @param unlocked                The unlocked percentage value at the time of the export of this transaction.
     */
    function importRecipient(
        address recipient,
        uint256 amount,
        uint256 claimableAmountOfImport,
        uint256 unlocked
    ) external nonReentrant {
        if (unlocked > unlockedPercentage()) revert UnlockedIsGreaterThanExpected();
        uint256 currentBalance = _getBalanceOfThis();

        underlyingToken.safeTransferFrom(_msgSender(), address(this), amount);
        uint256 transferredAmount = _getBalanceOfThis() - currentBalance;

        uint256 claimedAmount = _claimedAmount(transferredAmount, claimableAmountOfImport, unlocked);

        _metadata[recipient].claimedAmountAfterTransfer += claimedAmount;

        _importedClaimedSupply += claimedAmount;
        _startingSupply += transferredAmount + claimedAmount;
        _mint(recipient, transferredAmount);
    }

    /**
     * @notice Behaves as `addRecipients` but provides the ability to set the initial state of the recipient's
     * metadata.
     * @notice This functionality is included in order to allow users to restart an allocation on a different chain and
     * keeping the inner state as close as possible to the original.
     *
     * @dev The `Metadata.claimedAmountAfterTransfer` for each recipient is inferred from the parameters.
     * @dev The `Metadata.claimedBalance` is lost in the transfer, the closest value will be
     * `claimedAmountAfterTransfer`.
     * @dev In the rare case where the contract and it's users are migrated after the last milestone has been reached,
     * the `claimedAmountAfterTransfer` can't be inferred and the `claimedSupply` value for the whole contract is lost
     * in the transfer.
     * @dev The decision to do this to minimize the altering of metadata to the amount that is being transferred and
     * protect an attack that would render the contract unusable.
     *
     * @dev The Metadata for the recipient is inferred from the parameters. The decision to do this to minimize the
     * altering of metadata to the amount that is being transferred.
     *
     * Requirements:
     *
     * - `recipients`, `amounts`, and `claimableAmountsOfImport` must have the same length.
     * - `unlocked` must be less than or equal to this contracts `unlockedPercentage`.
     * - each value in `claimableAmountsOfImport` must be less than or equal than the amount that would be claimable
     *   given the values in `amounts` and `percentages`.
     * - `msg.sender` must have approved this contract an amount of `underlyingToken` greater or equal than the sum of
     *   all of the `amounts`.
     *
     * @param recipients               Array of addresses that will receive the newly minted LVTs.
     * @param amounts                  Array of amounts of `underlyingToken` to be vested.
     * @param claimableAmountsOfImport Array of amounts of `underlyingToken` from this transaction that should be
     *                                 considered claimable.
     * @param unlocked                 The unlocked percentage value at the time of the export of this transaction.
     */
    function importRecipients(
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256[] calldata claimableAmountsOfImport,
        uint256 unlocked
    ) external nonReentrant {
        if (unlocked > unlockedPercentage()) revert UnlockedIsGreaterThanExpected();
        if (recipients.length != amounts.length || claimableAmountsOfImport.length != amounts.length)
            revert InputArraysMustHaveSameLength();
        uint256 currentBalance = _getBalanceOfThis();
        uint256 totalAmount;
        for (uint256 i = 0; i < recipients.length; i++) {
            totalAmount += amounts[i];
        }

        underlyingToken.safeTransferFrom(_msgSender(), address(this), totalAmount);
        uint256 transferredAmount = _getBalanceOfThis() - currentBalance;

        uint256 totalClaimed;

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = transferredAmount == totalAmount
                ? amounts[i]
                : (amounts[i] * transferredAmount) / totalAmount;

            uint256 claimableAmountOfImport = claimableAmountsOfImport[i];

            uint256 claimedAmount = _claimedAmount(amount, claimableAmountOfImport, unlocked);
            _mint(recipient, amount);

            _metadata[recipient].claimedAmountAfterTransfer += claimedAmount;

            totalClaimed += claimedAmount;
        }

        _importedClaimedSupply += totalClaimed;
        _startingSupply += transferredAmount + totalClaimed;
    }

    /**
     * @param recipient The address that will be exported.
     *
     * @return The arguments to use in a call `importRecipient` on a different contract to migrate the `recipient`'s
     * metadata.
     */
    function exportRecipient(address recipient) external view returns (address, uint256, uint256, uint256) {
        return (recipient, balanceOf(recipient), claimableBalanceOf(recipient), unlockedPercentage());
    }

    /**
     * @param recipients Array of addresses that will be exported.
     *
     * @return The arguments to use in a call `importRecipients` on a different contract to migrate the `recipients`'
     * metadata.
     */
    function exportRecipients(
        address[] calldata recipients
    ) external view returns (address[] calldata, uint256[] memory, uint256[] memory, uint256) {
        uint256[] memory balances = new uint256[](recipients.length);
        uint256[] memory claimableBalances = new uint256[](recipients.length);

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            balances[i] = balanceOf(recipient);
            claimableBalances[i] = claimableBalanceOf(recipient);
        }

        return (recipients, balances, claimableBalances, unlockedPercentage());
    }

    /**
     * @notice This function will check and update the `_lastReachedMilestone` so the gas usage will be minimal in
     * calls to `unlockedPercentage`.
     *
     * @dev This function is called by claim with a value of `startIndex` equal to the previous value of
     * `_lastReachedMilestone`, but can be called externally with a more accurate value in case multiple Milestones
     * have been reached without anyone claiming.
     *
     * @param startIndex Index of the Milestone we want the loop to start checking.
     */
    function updateLastReachedMilestone(uint256 startIndex) public {
        Milestone storage previous = _milestones[startIndex];
        if (previous.timestamp > block.timestamp) return;

        for (uint256 i = startIndex; i < _milestones.length; i++) {
            Milestone storage current = _milestones[i];
            if (current.timestamp <= block.timestamp) {
                previous = current;
                continue;
            }

            if (i > _lastReachedMilestone + 1) {
                _lastReachedMilestone = i - 1;
                emit MilestoneReached(_lastReachedMilestone, previous.percentage);
            }
            return;
        }

        if (_lastReachedMilestone < _milestones.length - 1) {
            _lastReachedMilestone = _milestones.length - 1;
            emit MilestoneReached(_lastReachedMilestone, uint64(ONE));
        }
    }

    /**
     * @return The percentage of `underlyingToken` that users could claim.
     */
    function unlockedPercentage() public view returns (uint256) {
        Milestone storage previous = _milestones[_lastReachedMilestone];
        // If the first Milestone is still pending, the contract hasn't started unlocking tokens
        if (previous.timestamp > block.timestamp) return 0;

        uint256 percentage = previous.percentage;

        for (uint256 i = _lastReachedMilestone + 1; i < _milestones.length; i++) {
            Milestone storage current = _milestones[i];
            // If `current` Milestone has expired, `percentage` is at least `current` Milestone's percentage
            if (current.timestamp <= block.timestamp) {
                percentage = current.percentage;
                previous = current;
                continue;
            }
            // If `current` Milestone has a `Linear` ramp, `percentage` is between `previous` and `current`
            // Milestone's percentage
            if (current.ramp == Ramp.Linear) {
                percentage +=
                    ((block.timestamp - previous.timestamp) * (current.percentage - previous.percentage)) /
                    (current.timestamp - previous.timestamp);
            }
            // `percentage` won't change after this
            break;
        }
        return percentage;
    }

    /**
     * @return The amount of `underlyingToken` that were held in this contract and have been claimed.
     */
    function claimedSupply() public view returns (uint256) {
        return _startingSupply - totalSupply() - _importedClaimedSupply;
    }

    /**
     * @return The amount of `underlyingToken` being held in this contract and that can be claimed.
     */
    function claimableSupply() public view returns (uint256) {
        return _claimableAmount(_startingSupply, _startingSupply - totalSupply());
    }

    /**
     * @return The amount of `underlyingToken` being held in this contract that can't be claimed yet.
     */
    function lockedSupply() public view returns (uint256) {
        return totalSupply() - claimableSupply();
    }

    /**
     * @param account The address whose tokens are being queried.
     *
     * @return The amount of `underlyingToken` that were held in this contract and this `account` already claimed.
     */
    function claimedBalanceOf(address account) public view returns (uint256) {
        return _metadata[account].claimedBalance;
    }

    /**
     * @param account The address whose tokens are being queried.
     *
     * @return The amount of `underlyingToken` that this `account` owns and can claim.
     */

    function claimableBalanceOf(address account) public view returns (uint256) {
        uint256 claimedAmountAfterTransfer = _metadata[account].claimedAmountAfterTransfer;
        return _claimableAmount(claimedAmountAfterTransfer + balanceOf(account), claimedAmountAfterTransfer);
    }

    /**
     * @param account The address whose tokens are being queried.
     *
     * @return The amount of `underlyingToken` that this `account` owns but can't claim yet.
     */
    function lockedBalanceOf(address account) public view returns (uint256) {
        return balanceOf(account) - claimableBalanceOf(account);
    }

    /**
     * @notice This function transfers the claimable amount of `underlyingToken` and transfers it to `msg.sender`.
     *
     * @custom:emits `Claim(account, claimableAmount)`
     */
    function claim() public {
        address account = _msgSender();
        Metadata storage accountMetadata = _metadata[account];

        updateLastReachedMilestone(_lastReachedMilestone);

        uint256 claimableAmount = _claimableAmount(
            accountMetadata.claimedAmountAfterTransfer + balanceOf(account),
            accountMetadata.claimedAmountAfterTransfer
        );

        if (claimableAmount > 0) {
            _burn(account, claimableAmount);

            accountMetadata.claimedAmountAfterTransfer += claimableAmount;
            accountMetadata.claimedBalance += claimableAmount;

            emit Claim(account, claimableAmount);
            underlyingToken.safeTransfer(account, claimableAmount);
        }
    }

    /**
     * @notice Calculates and transfers the fee before executing a normal ERC20 transfer.
     *
     * @dev This method also updates the metadata in `msg.sender`, `to`, and `feeCollector`.
     *
     * @param to     Address of recipient.
     * @param amount Amount of tokens.
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        _updateMetadataAndTransfer(_msgSender(), to, amount, true);
        return true;
    }

    /**
     * @notice Calculates and transfers the fee before executing a normal ERC20 transferFrom.
     *
     * @dev This method also updates the metadata in `from`, `to`, and `feeCollector`.
     *
     * @param from   Address of sender.
     * @param to     Address of recipient.
     * @param amount Amount of tokens.
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        _updateMetadataAndTransfer(from, to, amount, false);
        return true;
    }

    /**
     * @notice Exposes the whole array of `_milestones`.
     */
    function milestones() external view returns (Milestone[] memory) {
        return _milestones;
    }

    /**
     * @dev This function updates the metadata on the `sender`, the `receiver`, and the `feeCollector` if there's any
     * fee involved. The changes on the metadata are on the value `claimedAmountAfterTransfer` which is used to
     * calculate `_claimableAmount`.
     *
     * @dev The math behind these changes can be explained by the following logic:
     *
     *     1) claimableAmount = (unlockedPercentage * startingAmount) / ONE - claimedAmount
     *
     * When there's a transfer of an amount, we transfer both locked and unlocked tokens so the
     * `claimableAmountAfterTransfer` will look like:
     *
     *     2) claimableAmountAfterTransfer = claimableAmount ± claimableAmountOfTransfer
     *
     * Notice the ± symbol is because the `sender`'s `claimableAmount` is reduced while the `receiver`'s
     * `claimableAmount` is increased.
     *
     *     3) claimableAmountOfTransfer = claimableAmountOfSender * amountOfTransfer / balanceOfSender
     *
     * We can expand 3) into:
     *
     *     4) claimableAmountOfTransfer =
     *            (unlockedPercentage * ((startingAmountOfSender * amountOfTransfer) / balanceOfSender)) / ONE) -
     *            ((claimedAmountOfSender * amountOfTransfer) / balanceOfSender)
     *
     * Notice how the structure of the equation is the same as 1) and 2 new variables can be created to calculate
     * `claimableAmountOfTransfer`
     *
     *     a) startingAmountOfTransfer = (startingAmountOfSender * amountOfTransfer) / balanceOfSender
     *     b) claimedAmountOfTransfer = (claimedAmountOfSender * amountOfTransfer) / balanceOfSender
     *
     * Replacing `claimableAmountOfTransfer` in equation 2) and expanding it, we get:
     *
     *     5) claimableAmountAfterTransfer =
     *            ((unlockedPercentage * startingAmount) / ONE - claimedAmount) ±
     *            ((unlockedPercentage * startingAmountOfTransfer) / ONE - claimedAmountOfTransfer)
     *
     * We can group similar variables like this:
     *
     *     6) claimableAmountAfterTransfer =
     *            (unlockedPercentage * (startingAmount - startingAmountOfTransfer)) / ONE -
     *            (claimedAmount - claimedAmountOfTransfer)
     *
     * This shows that the new values to calculate `claimableAmountAfterTransfer` if we want to continue using the
     * equation 1) are:
     *
     *     c) startingAmountAfterTransfer =
     *            startingAmount ±
     *            (startingAmountOfSender * amountOfTransfer) / balanceOfSender
     *     d) claimedAmountAfterTransfer =
     *            claimedAmount ±
     *            (claimedAmountOfSender * amountOfTransfer) / balanceOfSender
     *
     * Since these values depend linearly on the value of `amountOfTransfer`, and the fee is a fraction of the amount,
     * we can just factor in the `feePercentage` to get the values for the transfer to the `feeCollector`.
     *
     *     e) startingAmountOfFee = (startingAmountOfTransfer * feePercentage) / ONE;
     *     f) claimedAmountOfFee = (claimedAmountOfTransfer * feePercentage) / ONE;
     *
     * If we look at equation 1) and set `unlockedPercentage` to ONE, then `claimableAmount` must equal to the
     * `balance`. Therefore the relation between `startingAmount`, `claimedAmount`, and `balance` should be:
     *
     *     g) startingAmount = claimedAmount + balance
     *
     * Since we want to minimize independent rounding in all of the `startingAmount`s, and `claimedAmount`s we will
     * calculate the `claimedAmount` using multiplication and division as shown in b) and f), and the `startingAmount`
     * can be derived using a simple subtraction.
     * With this we ensure that if there's a rounding down in the divisions, we won't be leaving any token locked.
     *
     * @param from       Address of sender.
     * @param to         Address of recipient.
     * @param amount     Amount of tokens.
     * @param isTransfer If a fee is charged, this will let the function know whether to use `transfer` or
     *                   `transferFrom` to collect the fee.
     */
    function _updateMetadataAndTransfer(address from, address to, uint256 amount, bool isTransfer) internal {
        Metadata storage accountMetadata = _metadata[from];

        // Calculate `claimedAmountOfTransfer` as described on equation b)
        // uint256 can handle 78 digits well. Normally token transactions have 18 decimals that gives us 43 digits of
        // wiggle room in the multiplication `(accountMetadata.claimedAmountAfterTransfer * amount)` without
        // overflowing.
        uint256 claimedAmountOfTransfer = (accountMetadata.claimedAmountAfterTransfer * amount) / balanceOf(from);

        // Modify `claimedAmountAfterTransfer` of the sender following equation d)
        // Notice in this case we are reducing the value
        accountMetadata.claimedAmountAfterTransfer -= claimedAmountOfTransfer;

        if (to != from) {
            IFeeManager.FeeData memory feeData = manager.feeData();
            uint256 feePercentage = feeData.feePercentage;

            if (feePercentage != 0) {
                address feeCollector = feeData.feeCollector;

                // The values of `fee` and `claimedAmountOfFee` are calculated using the `feePercentage` shown in
                // equation f)
                uint256 fee = (amount * feePercentage) / ONE;
                uint256 claimedAmountOfFee = (claimedAmountOfTransfer * feePercentage) / ONE;

                // The values for the receiver need to be updated accordingly
                amount -= fee;
                claimedAmountOfTransfer -= claimedAmountOfFee;

                // Modify `claimedAmountAfterTransfer` of the feeCollector following equation d)
                // Notice in this case we are increasing the value
                _metadata[feeCollector].claimedAmountAfterTransfer += claimedAmountOfFee;

                if (isTransfer) {
                    super.transfer(feeCollector, fee);
                } else {
                    super.transferFrom(from, feeCollector, fee);
                }
            }
        }

        // Modify `claimedAmountAfterTransfer` of the receiver following equation d)
        // Notice in this case we are increasing the value
        // The next line triggers the linter because it's not aware that super.transfer does not call an external
        // contract, nor does trigger a fallback function.
        // solhint-disable-next-line reentrancy
        _metadata[to].claimedAmountAfterTransfer += claimedAmountOfTransfer;

        if (isTransfer) {
            super.transfer(to, amount);
        } else {
            super.transferFrom(from, to, amount);
        }
    }

    /**
     * @dev Checks that 2 Milestones have percentages and timestamps sorted in ascending order.
     * @dev Percentages may be repeated and that scenario will be checked in the `_twoInARowRule`.
     *
     * @param current  Milestone with index `i` in the for loop.
     * @param previous Milestone with index `i - 1` in the for loop.
     */
    function _sortRule(Milestone calldata current, Milestone calldata previous) internal pure {
        if (previous.timestamp >= current.timestamp) revert MilestoneTimestampsNotSorted();
        if (previous.percentage > current.percentage) revert MilestonePercentagesNotSorted();
    }

    /**
     * @dev No more than 2 consecutive Milestones can have the same percentage.
     * @dev 2 Milestones may have the same percentage as long as they are followed by a Milestone with a `Ramp.Linear`.
     *
     * @param current   Milestone with index `i` in the for loop.
     * @param previous  Milestone with index `i - 1` in the for loop.
     * @param twoInARow Boolean declaring if the Milestones with index `i - 2` and `i - 1` already had the same
     *                  percentage.
     */
    function _twoInARowRule(Milestone calldata current, Milestone calldata previous, bool twoInARow) internal pure {
        if (twoInARow) {
            if (previous.percentage == current.percentage) revert MoreThanTwoEqualPercentages();
            if (current.ramp != Ramp.Linear) revert EqualPercentagesOnlyAllowedBeforeLinear();
        }
    }

    /**
     * @dev The last Milestone must have 100%.
     * @dev Only the last Milestone can have 100%.
     *
     * @param current         Milestone with index `i` in the for loop.
     * @param isLastMilestone Boolean declaring if the Milestone is the last in the for loop.
     */
    function _hundredPercentRule(Milestone calldata current, bool isLastMilestone) internal pure {
        if (isLastMilestone) {
            if (current.percentage != ONE) revert LastPercentageMustBe100();
        } else {
            if (current.percentage == ONE) revert OnlyLastPercentageCanBe100();
        }
    }

    /**
     * @dev Perform a staticcall to attempt to fetch `underlyingToken`'s decimals. In case of an error, we default to
     * 18.
     */
    function _tryFetchDecimals() internal view returns (uint8) {
        (bool success, bytes memory encodedDecimals) = address(underlyingToken).staticcall(
            abi.encodeWithSelector(ERC20Upgradeable.decimals.selector)
        );

        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return uint8(returnedDecimals);
            }
        }
        return 18;
    }

    /**
     * @dev Perform a staticcall to attempt to fetch `underlyingToken`'s balance of this contract.
     * In case of an error, reverts with custom `UnsuccessfulFetchOfTokenBalance` error.
     */
    function _getBalanceOfThis() internal view returns (uint256) {
        (bool success, bytes memory encodedBalance) = address(underlyingToken).staticcall(
            abi.encodeWithSelector(ERC20Upgradeable.balanceOf.selector, address(this))
        );

        if (success && encodedBalance.length >= 32) {
            return abi.decode(encodedBalance, (uint256));
        }
        revert UnsuccessfulFetchOfTokenBalance();
    }

    /**
     * @notice This method is used to infer the value of claimed amounts.
     *
     * @dev If the unlocked percentage has already reached 100%, there's no way to infer the claimed amount.
     *
     * @param amount                  Amount of `underlyingToken` in the transaction.
     * @param claimableAmountOfImport Amount of `underlyingToken` from this transaction that should be considered
     *                                claimable.
     * @param unlocked                The unlocked percentage value at the time of the export of this transaction.
     *
     * @return Amount of `underlyingToken` that has been claimed based on the arguments given.
     */
    function _claimedAmount(
        uint256 amount,
        uint256 claimableAmountOfImport,
        uint256 unlocked
    ) internal pure returns (uint256) {
        if (unlocked == ONE) return 0;

        uint256 a = unlocked * amount;
        uint256 b = ONE * claimableAmountOfImport;
        // If `a - b` underflows, we display a better error message.
        if (b > a) revert ClaimableAmountOfImportIsGreaterThanExpected();
        return (a - b) / (ONE - unlocked);
    }

    /**
     * @param startingAmount Amount of `underlyingToken` originally held.
     * @param claimedAmount  Amount of `underlyingToken` already claimed.
     *
     * @return Amount of `underlyingToken` that can be claimed based on the milestones reached and initial amounts
     * given.
     */
    function _claimableAmount(uint256 startingAmount, uint256 claimedAmount) internal view returns (uint256) {
        return (unlockedPercentage() * startingAmount) / ONE - claimedAmount;
    }
}