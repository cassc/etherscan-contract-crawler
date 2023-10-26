// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./libraries/BoundedHistory.sol";
import "./external/council/libraries/Storage.sol";

import "./libraries/NFTBoostVaultStorage.sol";
import "./interfaces/INFTBoostVault.sol";
import "./BaseVotingVault.sol";

import {
    NBV_HasRegistration,
    NBV_AlreadyDelegated,
    NBV_InsufficientBalance,
    NBV_InsufficientWithdrawableBalance,
    NBV_MultiplierLimit,
    NBV_NoMultiplierSet,
    NBV_InvalidNft,
    NBV_ZeroAmount,
    NBV_ZeroAddress,
    NBV_ArrayTooManyElements,
    NBV_Locked,
    NBV_AlreadyUnlocked,
    NBV_NotAirdrop,
    NBV_NoRegistration,
    NBV_WrongDelegatee,
    NBV_InvalidExpiration,
    NBV_MultiplierSet
} from "./errors/Governance.sol";

/**
 * @title NFTBoostVault
 * @author Non-Fungible Technologies, Inc.
 *
 * The voting power for participants in this vault holding reputation ERC1155 nfts
 * is enhanced by a multiplier. This contract enables holders of specific ERC1155 nfts
 * to gain an advantage wrt voting power for participation in governance. Participants
 * send their ERC20 tokens to the contract and provide their ERC1155 nfts as calldata.
 * Once the contract confirms their ownership of the ERC1155 token id, and matches the
 * ERC1155 address and tokenId to a multiplier, they are able to delegate their voting
 * power for participation in governance.
 *
 * @dev There is no emergency withdrawal in this contract, any funds not sent via
 *      addNftAndDelegate() are unrecoverable by this version of the NFTBoostVault.
 */
contract NFTBoostVault is INFTBoostVault, BaseVotingVault {
    using SafeERC20 for IERC20;
    // ======================================== STATE ==================================================

    // Bring History library into scope
    using BoundedHistory for BoundedHistory.HistoricalBalances;

    // ======================================== STATE ==================================================

    /// @dev Determines the maximum multiplier for any given NFT.
    /* solhint-disable var-name-mixedcase */
    uint128 public constant MAX_MULTIPLIER = 1.5e3;

    /// @dev Precision of the multiplier.
    uint128 public constant MULTIPLIER_DENOMINATOR = 1e3;

    // ========================================== CONSTRUCTOR ===========================================

    /**
     * @notice Deploys a voting vault, setting immutable values for the token
     *         and staleBlockLag.
     *
     * @param token                     The external erc20 token contract.
     * @param staleBlockLag             The number of blocks before which the delegation history is forgotten.
     * @param timelock                  The address of the timelock who can update the manager address.
     * @param manager                   The address of the manager who can update the multiplier values.
     */
    constructor(
        IERC20 token,
        uint256 staleBlockLag,
        address timelock,
        address manager
    ) BaseVotingVault(token, staleBlockLag) {
        if (timelock == address(0)) revert NBV_ZeroAddress("timelock");
        if (manager == address(0)) revert NBV_ZeroAddress("manager");

        Storage.set(Storage.uint256Ptr("initialized"), 1);
        Storage.set(Storage.addressPtr("timelock"), timelock);
        Storage.set(Storage.addressPtr("manager"), manager);
        Storage.set(Storage.uint256Ptr("entered"), 1);
        Storage.set(Storage.uint256Ptr("locked"), 1);
    }

    // ===================================== USER FUNCTIONALITY =========================================

    /**
     * @notice Performs token and optional ERC1155 registration for the caller. The caller cannot have
     *         an existing registration.
     *
     * @dev User has to own ERC1155 nft for receiving the benefits of a multiplier.
     *
     * @param amount                    Amount of tokens sent to this contract by the user for locking
     *                                  in governance.
     * @param tokenId                   The id of the ERC1155 NFT.
     * @param tokenAddress              The address of the ERC1155 token the user is registering for multiplier
     *                                  access.
     * @param delegatee                 Optional param. The address to delegate the voting power associated
     *                                  with this registration.
     */
    function addNftAndDelegate(
        uint128 amount,
        uint128 tokenId,
        address tokenAddress,
        address delegatee
    ) external override nonReentrant {
        if (amount == 0) revert NBV_ZeroAmount();

        _registerAndDelegate(msg.sender, amount, tokenId, tokenAddress, delegatee);

        // transfer user ERC20 amount and ERC1155 nft into this contract
        _lockTokens(msg.sender, uint256(amount), tokenAddress, tokenId);
    }

    /**
     * @notice Function for an airdrop contract to call to register a user or update
     *         their registration with more tokens.
     *
     * @dev This function is only callable by the airdrop contract.
     * @dev If a user already has a registration, they cannot change their delegatee.
     *
     * @param user                      The address of the user to register.
     * @param amount                    Amount of token to transfer to this contract.
     * @param delegatee                 The address to delegate the voting power to.
     */
    function airdropReceive(
        address user,
        uint128 amount,
        address delegatee
    ) external override onlyAirdrop nonReentrant {
        if (amount == 0) revert NBV_ZeroAmount();
        if (user == address(0)) revert NBV_ZeroAddress("user");

        // load the registration
        NFTBoostVaultStorage.Registration storage registration = _getRegistrations()[user];

        // if user is not already registered, register them
        // else just update their registration
        if (registration.delegatee == address(0)) {
            _registerAndDelegate(user, amount, 0, address(0), delegatee);
        } else {
            // if user supplies new delegatee address revert
            if (delegatee != registration.delegatee) revert NBV_WrongDelegatee(delegatee, registration.delegatee);

            // get this contract's balance
            Storage.Uint256 storage balance = _balance();
            // update contract balance
            balance.data += amount;

            // update registration amount
            registration.amount += amount;

            // sync current delegatee's voting power
            _syncVotingPower(user, registration);
        }

        // transfer user ERC20 amount only into this contract
        _lockTokens(msg.sender, uint256(amount), address(0), 0);
    }

    /**
     * @notice Changes the caller's token voting power delegation.
     *
     * @dev The total voting power is not guaranteed to go up because the token
     *      multiplier can be updated at any time.
     *
     * @param to                        The address to delegate to.
     */
    function delegate(address to) external override {
        if (to == address(0)) revert NBV_ZeroAddress("to");

        NFTBoostVaultStorage.Registration storage registration = _getRegistrations()[msg.sender];

        // user must have an existing registration
        if (registration.delegatee == address(0)) revert NBV_NoRegistration();

        // If to address is already the delegate, don't send the tx
        if (to == registration.delegatee) revert NBV_AlreadyDelegated();

        BoundedHistory.HistoricalBalances memory votingPower = _votingPower();
        uint256 oldDelegateeVotes = votingPower.loadTop(registration.delegatee);

        // Remove voting power from old delegatee and emit event
        votingPower.push(
            registration.delegatee,
            oldDelegateeVotes - registration.latestVotingPower,
            MAX_HISTORY_LENGTH
        );
        emit VoteChange(msg.sender, registration.delegatee, -1 * int256(uint256(registration.latestVotingPower)));

        // Note - It is important that this is loaded here and not before the previous state change because if
        // to == registration.delegatee and re-delegation was allowed we could be working with out of date state
        uint256 newDelegateeVotes = votingPower.loadTop(to);
        // return the current voting power of the Registration. Varies based on the multiplier associated with the
        // user's ERC1155 token at the time of txn
        uint256 addedVotingPower = _currentVotingPower(registration);

        // add voting power to the target delegatee and emit event
        votingPower.push(to, newDelegateeVotes + addedVotingPower, MAX_HISTORY_LENGTH);

        // update registration properties
        registration.latestVotingPower = uint128(addedVotingPower);
        registration.delegatee = to;

        emit VoteChange(msg.sender, to, int256(addedVotingPower));
    }

    /**
     * @notice Removes a user's locked ERC20 tokens from this contract and if no tokens are remaining, the
     *         user's locked ERC1155 (if utilized) is also transferred back to them. Consequently, the user's
     *         delegatee loses the voting power associated with the aforementioned tokens.
     *
     * @dev Withdraw is unlocked when the locked state variable is set to 2.
     *
     * @param amount                      The amount of token to withdraw.
     */
    function withdraw(uint128 amount) external override nonReentrant {
        if (getIsLocked() == 1) revert NBV_Locked();
        if (amount == 0) revert NBV_ZeroAmount();

        // load the registration
        NFTBoostVaultStorage.Registration storage registration = _getRegistrations()[msg.sender];

        // get this contract's balance
        Storage.Uint256 storage balance = _balance();
        if (balance.data < amount) revert NBV_InsufficientBalance();

        // get the withdrawable amount
        uint256 withdrawable = _getWithdrawableAmount(registration);
        if (withdrawable < amount) revert NBV_InsufficientWithdrawableBalance(withdrawable);

        // update contract balance
        balance.data -= amount;
        // update withdrawn amount
        registration.withdrawn += amount;
        // update the delegatee's voting power. Varies based on the multiplier associated with the
        // user's ERC1155 token at the time of the call
        _syncVotingPower(msg.sender, registration);

        if (registration.withdrawn == registration.amount) {
            if (registration.tokenAddress != address(0) && registration.tokenId != 0) {
                _withdrawNft();
            }
            // delete registration. tokenId and token address already set to 0 in _withdrawNft()
            registration.amount = 0;
            registration.latestVotingPower = 0;
            registration.withdrawn = 0;
            registration.delegatee = address(0);
        }

        // transfer the token amount to the user
        token.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Adds tokens to a user's registration. The user must have an existing registration.
     *
     * @param amount                      The amount of tokens to add.
     */
    function addTokens(uint128 amount) external override nonReentrant {
        if (amount == 0) revert NBV_ZeroAmount();
        // load the registration
        NFTBoostVaultStorage.Registration storage registration = _getRegistrations()[msg.sender];

        // If the registration does not have a delegatee, revert because the Registration
        // is not initialized
        if (registration.delegatee == address(0)) revert NBV_NoRegistration();

        // get this contract's balance
        Storage.Uint256 storage balance = _balance();
        // update contract balance
        balance.data += amount;

        // update registration amount
        registration.amount += amount;
        // update the delegatee's voting power
        _syncVotingPower(msg.sender, registration);

        // transfer ERC20 amount into this contract
        _lockTokens(msg.sender, amount, address(0), 0);
    }

    /**
     * @notice Nonreentrant function that calls a helper when users want to withdraw
     *         the ERC1155 NFT they are using in their registration.
     */
    function withdrawNft() external override nonReentrant {
        _withdrawNft();
    }

    /**
     * @notice A function that allows a user's to change the ERC1155 nft they are using for
     *         accessing a voting power multiplier. Or if the users does not have a NFT
     *         registered, they can register one and their voting power will be updated.
     *         The provided ERC1155 token must have an associated multiplier to register it.
     *
     * @param newTokenAddress            Address of the new ERC1155 token the user wants to use.
     * @param newTokenId                 Id of the new ERC1155 token the user wants to use.
     */
    function updateNft(uint128 newTokenId, address newTokenAddress) external override nonReentrant {
        if (newTokenAddress == address(0) || newTokenId == 0) revert NBV_InvalidNft(newTokenAddress, newTokenId);

        // check there is a multiplier associated with the new NFT
        if (getMultiplier(newTokenAddress, newTokenId) == 0) revert NBV_NoMultiplierSet();

        NFTBoostVaultStorage.Registration storage registration = _getRegistrations()[msg.sender];

        // If the registration does not have a delegatee, revert because the Registration
        // is not initialized
        if (registration.delegatee == address(0)) revert NBV_NoRegistration();

        // if the user already has an ERC1155 registered, withdraw it
        if (registration.tokenAddress != address(0)) {
            // withdraw the current ERC1155 from the registration
            _withdrawNft();
        }

        // set the new ERC1155 values in the registration and lock the new ERC1155
        registration.tokenAddress = newTokenAddress;
        registration.tokenId = newTokenId;

        _lockNft(msg.sender, newTokenAddress, newTokenId);

        // update the delegatee's voting power based on new ERC1155 nft's multiplier
        _syncVotingPower(msg.sender, registration);
    }

    /**
     * @notice Update users' registration voting power.
     *
     * @dev Voting power is only updated for this block onward. See Council contract History.sol
     *      for more on how voting power is tracked and queried.
     *      Anybody can update up to 50 users' registration voting power.
     *
     * @param userAddresses             Array of addresses whose registration voting power this
     *                                  function updates.
     */
    function updateVotingPower(address[] calldata userAddresses) public override {
        if (userAddresses.length > 50) revert NBV_ArrayTooManyElements();

        for (uint256 i = 0; i < userAddresses.length; ++i) {
            NFTBoostVaultStorage.Registration storage registration = _getRegistrations()[userAddresses[i]];
            _syncVotingPower(userAddresses[i], registration);
        }
    }

    // ===================================== ADMIN FUNCTIONALITY ========================================

    /**
     * @notice An onlyManager function for setting the multiplier value associated with an ERC1155
     *         contract address. The provided multiplier value must be less than or equal to 1.5x
     *         and greater than or equal to 1x. Every multiplier value has an associated expiration
     *         timestamp. Once a multiplier expires, the multiplier for the ERC1155 returns 1x.
     *         Once a multiplier is set, it cannot be modified.
     *
     * @param tokenAddress              ERC1155 token address to set the multiplier for.
     * @param tokenId                   The token ID of the ERC1155 for which the multiplier is being set.
     * @param multiplierValue           The multiplier value corresponding to the token address and ID.
     * @param expiration                The timestamp at which the multiplier expires.
     */
    function setMultiplier(
        address tokenAddress,
        uint128 tokenId,
        uint128 multiplierValue,
        uint128 expiration
    ) public override onlyManager {
        if (multiplierValue > MAX_MULTIPLIER) revert NBV_MultiplierLimit("high");
        if (multiplierValue < 1e3) revert NBV_MultiplierLimit("low");
        if (expiration <= block.timestamp) revert NBV_InvalidExpiration();

        if (tokenAddress == address(0) || tokenId == 0) revert NBV_InvalidNft(tokenAddress, tokenId);

        NFTBoostVaultStorage.MultiplierData storage multiplierData = _getMultipliers()[tokenAddress][tokenId];

        // cannot modify multiplier data if it is already set
        if (multiplierData.multiplier != 0) {
            revert NBV_MultiplierSet(multiplierData.multiplier, multiplierData.expiration);
        }

        // set multiplier data
        multiplierData.multiplier = multiplierValue;
        multiplierData.expiration = expiration;

        emit MultiplierSet(tokenAddress, tokenId, multiplierValue, expiration);
    }

    /**
     * @notice An Timelock only function for ERC20 allowing withdrawals.
     *
     * @dev Allows the timelock to unlock withdrawals. Cannot be reversed.
     */
    function unlock() external override onlyTimelock {
        if (getIsLocked() != 1) revert NBV_AlreadyUnlocked();
        Storage.set(Storage.uint256Ptr("locked"), 2);

        emit WithdrawalsUnlocked();
    }

    /**
     * @notice Manager-only airdrop contract address update function.
     *
     * @dev Allows the manager to update the airdrop contract address.
     *
     * @param newAirdropContract        The address of the new airdrop contract.
     */
    function setAirdropContract(address newAirdropContract) external override onlyManager {
        Storage.set(Storage.addressPtr("airdrop"), newAirdropContract);

        emit AirdropContractUpdated(newAirdropContract);
    }

    // ======================================= VIEW FUNCTIONS ===========================================

    /**
     * @notice Returns whether tokens can be withdrawn from the vault.
     *
     * @return locked                           Whether withdrawals are locked.
     */
    function getIsLocked() public view override returns (uint256) {
        return Storage.uint256Ptr("locked").data;
    }

    /**
     * @notice A function to access a NFT's voting power multiplier. If the user does not provide
     *         a token address and ID, the function returns the default 1x multiplier. This implies
     *         that a registration without a token address and ID have a default 1x multiplier.
     *
     * @param tokenAddress              ERC1155 token address to lookup.
     * @param tokenId                   The token ID of the ERC1155 to lookup.
     *
     * @return                          The token multiplier.
     */
    function getMultiplier(address tokenAddress, uint128 tokenId) public view override returns (uint128) {
        // if NFT is not registered, return 1x multiplier
        if (tokenAddress == address(0) && tokenId == 0) return 1e3;

        NFTBoostVaultStorage.MultiplierData storage multiplierData = _getMultipliers()[tokenAddress][tokenId];

        // if multiplier is not set, return 0
        if (multiplierData.expiration == 0) return 0;

        // if multiplier has expired, return 1x multiplier
        if (multiplierData.expiration <= block.timestamp) return 1e3;

        return multiplierData.multiplier;
    }

    /**
     * @notice A function to access the storage of the nft's multiplier expiration.
     *
     * @param tokenAddress              The address of the token.
     * @param tokenId                   The token ID.
     *
     * @return                          The multiplier's expiration.
     */
    function getMultiplierExpiration(address tokenAddress, uint128 tokenId) external view override returns (uint128) {
        NFTBoostVaultStorage.MultiplierData storage multiplierData = _getMultipliers()[tokenAddress][tokenId];

        return multiplierData.expiration;
    }

    /**
     * @notice Getter for the registrations mapping.
     *
     * @param who                               The owner of the registration to query.
     *
     * @return registration                     Registration of the provided address.
     */
    function getRegistration(address who) external view override returns (NFTBoostVaultStorage.Registration memory) {
        return _getRegistrations()[who];
    }

    /**
     * @notice A function to access the stored airdrop contract address.
     *
     * @return address                  The address of the airdrop contract.
     */
    function getAirdropContract() external view override returns (address) {
        return Storage.addressPtr("airdrop").data;
    }

    // =========================================== HELPERS ==============================================

    /**
     * @notice A helper function to register a user and delegate their voting power. This function is called
     *         when a user does not have a Registration created yet.
     *
     * @param user                          The address of the user to register.
     * @param _amount                       Amount of tokens to be locked.
     * @param _tokenId                      The id of the ERC1155 NFT.
     * @param _tokenAddress                 The address of the ERC1155 token.
     * @param _delegatee                    The address to delegate the voting power associated
     *                                      with this registration.
     */
    function _registerAndDelegate(
        address user,
        uint128 _amount,
        uint128 _tokenId,
        address _tokenAddress,
        address _delegatee
    ) internal {
        // check there is a multiplier associated with the ERC1155
        uint128 multiplier = getMultiplier(_tokenAddress, _tokenId);
        if (multiplier == 0) revert NBV_NoMultiplierSet();

        // load this contract's balance storage
        Storage.Uint256 storage balance = _balance();

        // load the registration
        NFTBoostVaultStorage.Registration storage registration = _getRegistrations()[user];

        // If the delegate address is not address zero, revert because the Registration
        // is already initialized. Only one Registration per user
        if (registration.delegatee != address(0)) revert NBV_HasRegistration();

        // load the delegate. Defaults to the registration owner
        _delegatee = _delegatee == address(0) ? user : _delegatee;

        // calculate the voting power provided by this registration
        uint128 newVotingPower = (_amount * multiplier) / MULTIPLIER_DENOMINATOR;

        // set the new registration
        registration.amount = _amount;
        registration.latestVotingPower = newVotingPower;
        registration.withdrawn = 0;
        registration.tokenId = _tokenId;
        registration.tokenAddress = _tokenAddress;
        registration.delegatee = _delegatee;

        // update this contract's balance
        balance.data += _amount;

        _grantVotingPower(_delegatee, newVotingPower);

        emit VoteChange(user, _delegatee, int256(uint256(newVotingPower)));
    }

    /**
     * @dev Grants the chosen delegate address voting power when a new user registers.
     *
     * @param delegatee                         The address to delegate the voting power associated
     *                                          with the Registration to.
     * @param newVotingPower                    Amount of votingPower associated with this Registration to
     *                                          be added to delegates existing votingPower.
     *
     */
    function _grantVotingPower(address delegatee, uint128 newVotingPower) internal {
        // update the delegatee's voting power
        BoundedHistory.HistoricalBalances memory votingPower = _votingPower();

        // loads the most recent timestamp of voting power for this delegate
        uint256 delegateeVotes = votingPower.loadTop(delegatee);

        // add block stamp indexed delegation power for this delegate to historical data array
        votingPower.push(delegatee, delegateeVotes + newVotingPower, MAX_HISTORY_LENGTH);
    }

    /**
     * @dev A single function endpoint for loading Registration storage
     *
     * @dev Only one Registration is allowed per user.
     *
     * @return registrations                 A storage mapping to look up registrations data
     */
    function _getRegistrations() internal pure returns (mapping(address => NFTBoostVaultStorage.Registration) storage) {
        // This call returns a storage mapping with a unique non overwrite-able storage location.
        return NFTBoostVaultStorage.mappingAddressToRegistrationPtr("registrations");
    }

    /**
     * @notice Helper function called when a user wants to withdraw the ERC1155 NFT
     *         they have registered for accessing a voting power multiplier.
     */
    function _withdrawNft() internal {
        // load the registration
        NFTBoostVaultStorage.Registration storage registration = _getRegistrations()[msg.sender];

        if (registration.tokenAddress == address(0)) {
            revert NBV_InvalidNft(registration.tokenAddress, registration.tokenId);
        }

        // transfer ERC1155 back to the user
        IERC1155(registration.tokenAddress).safeTransferFrom(
            address(this),
            msg.sender,
            registration.tokenId,
            1,
            bytes("")
        );

        // remove ERC1155 values from registration struct
        registration.tokenAddress = address(0);
        registration.tokenId = 0;

        // update the delegatee's voting power based on multiplier removal
        _syncVotingPower(msg.sender, registration);
    }

    /**
     * @dev Helper to update a delegatee's voting power.
     *
     * @param who                        The address who's voting power we need to sync.
     *
     * @param registration               The storage pointer to the registration of that user.
     */
    function _syncVotingPower(address who, NFTBoostVaultStorage.Registration storage registration) internal {
        BoundedHistory.HistoricalBalances memory votingPower = _votingPower();
        uint256 delegateeVotes = votingPower.loadTop(registration.delegatee);

        uint256 newVotingPower = _currentVotingPower(registration);
        // get the change in voting power. Negative if the voting power is reduced
        int256 change = int256(newVotingPower) - int256(uint256(registration.latestVotingPower));

        // do nothing if there is no change
        if (change == 0) return;
        if (change > 0) {
            votingPower.push(registration.delegatee, delegateeVotes + uint256(change), MAX_HISTORY_LENGTH);
        } else if (delegateeVotes > uint256(change * -1)) {
            // if the change is negative, we multiply by -1 to avoid underflow when casting
            votingPower.push(registration.delegatee, delegateeVotes - uint256(change * -1), MAX_HISTORY_LENGTH);
        } else {
            votingPower.push(registration.delegatee, 0, MAX_HISTORY_LENGTH);
        }

        registration.latestVotingPower = uint128(newVotingPower);

        emit VoteChange(who, registration.delegatee, change);
    }

    /**
     * @dev Calculates how much a user can withdraw.
     *
     * @param registration                The the memory location of the loaded registration.
     *
     * @return withdrawable               Amount which can be withdrawn.
     */
    function _getWithdrawableAmount(
        NFTBoostVaultStorage.Registration memory registration
    ) internal pure returns (uint256) {
        if (registration.withdrawn == registration.amount) {
            return 0;
        }

        return registration.amount - registration.withdrawn;
    }

    /**
     * @dev Helper that returns the current voting power of a registration.
     *
     * @dev This is not always the recorded voting power since it uses the latest multiplier.
     *
     * @param registration               The registration to check for voting power.
     *
     * @return                           The current voting power of the registration.
     */
    function _currentVotingPower(
        NFTBoostVaultStorage.Registration memory registration
    ) internal view virtual returns (uint256) {
        uint128 locked = registration.amount - registration.withdrawn;

        if (registration.tokenAddress != address(0) && registration.tokenId != 0) {
            return (locked * getMultiplier(registration.tokenAddress, registration.tokenId)) / MULTIPLIER_DENOMINATOR;
        }

        return locked;
    }

    /**
     * @notice An internal function for locking a user's ERC20 tokens in this contract
     *         for participation in governance. Calls _lockNft function if an ERC1155
     *         token address and ID are specified.
     *
     * @param from                      Address tokens are transferred from.
     * @param amount                    Amount of ERC20 tokens being transferred.
     * @param tokenAddress              Address of the ERC1155 token being transferred.
     * @param tokenId                   ID of the ERC1155 token being transferred.
     */
    function _lockTokens(address from, uint256 amount, address tokenAddress, uint128 tokenId) internal {
        token.transferFrom(from, address(this), amount);

        if (tokenAddress != address(0) && tokenId != 0) {
            _lockNft(from, tokenAddress, tokenId);
        }
    }

    /**
     * @dev A internal function for locking a user's ERC1155 token in this contract
     *         for participation in governance.
     *
     * @param from                      Address of owner token is transferred from.
     * @param tokenAddress              Address of the token being transferred.
     * @param tokenId                   Id of the token being transferred.
     */
    function _lockNft(address from, address tokenAddress, uint128 tokenId) internal {
        IERC1155(tokenAddress).safeTransferFrom(from, address(this), tokenId, 1, bytes(""));
    }

    /** @dev A single function endpoint for loading storage for multipliers.
     *
     * @return                          A storage mapping which can be used to lookup a
     *                                  token's multiplier data and token id data.
     */
    function _getMultipliers()
        internal
        pure
        returns (mapping(address => mapping(uint128 => NFTBoostVaultStorage.MultiplierData)) storage)
    {
        // This call returns a storage mapping with a unique non overwrite-able storage layout.
        return NFTBoostVaultStorage.mappingAddressToMultiplierData("multipliers");
    }

    /** @dev A function to handles the receipt of a single ERC1155 token. This function is called
     *       at the end of a safeTransferFrom after the balance has been updated. To accept the transfer,
     *       this must return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
     *
     * @return                          0xf23a6e61
     */
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    modifier onlyAirdrop() {
        if (msg.sender != Storage.addressPtr("airdrop").data) revert NBV_NotAirdrop();

        _;
    }
}