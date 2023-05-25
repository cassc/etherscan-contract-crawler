// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./ABDKMath64x64.sol";
import "./interfaces/IEthLizards.sol";
import "./interfaces/IGenesisEthLizards.sol";
import "./interfaces/IUSDC.sol";

/**
 * @title The staking contract for Ethlizards
 * @author kmao (@kmao37)
 * @notice Lets users stake their Ethlizard NFTs accruing continuous compound interest,
 * and also claim rewards based on their share of the pool(s).
 * See docs at docs.ethlizards.io
 * @dev One Ethlizard is assigned the value of 100 * 1e18 (without any rebases), and we store the overall
 * combined shares of all of the Ethlizards in order to calculate the specific percentage share of an Ethlizards.
 * Rebases refer to the daily interest that is applied to each Ethlizard.
 * Resets refer to when rewards are released into a pool for claim.
 * Technical documentation can be found at docs.ethlizards.io
 */
contract LizardLounge is ERC721, Ownable {
    IEthlizards public immutable Ethlizards;
    IGenesisEthlizards public immutable GenesisLiz;
    IUSDC public immutable USDc;

    // Last ID of the EthlizardsV2 Collection
    uint256 constant MAXETHLIZARDID = 5049;
    // The default assigned share of a staked Ethlizard, which is 100,
    // we multiply by 1e18 for more precise calculation and storage of a user's shares
    uint256 constant DEFAULTLIZARDSHARE = 100 * 1e18;

    // When a LLZ is first initially minted
    event LockedLizardMinted(address mintedAddress, uint256 mintedId);
    // When a LLZ is transferred from this contract, ie, a user stakes their Ethlizards again
    event LockedLizardReMinted(address ownerAddress, uint256 lizardId);
    // When a user claims rewards from their lizard
    event RewardsClaimed(uint256 tokenId, uint256 rewardsClaimed);
    // A deposit is made
    event RewardsDeposited(uint256 depositAmount);
    // AllowedContracts is updated
    event AllowedContractsUpdated(address allowedContract, bool status);
    // Reset Share Value is updated
    event ResetShareValueUpdated(uint256 newResetShareValue);
    // Council address is updated
    event CouncilAddressUpdated(address councilAddress);
    // Updating the min days a user needs to be staked to withdraw their funds
    event MinLockedTimeUpdated(uint256 minLockedTime);
    // Min Reset Value has been updated
    event MinResetValueUpdated(uint256 newMinResetValue);
    // BaseURI has been updated
    event BaseURIUpdated(string newBaseuri);

    // Stores which tokenId was staked by which address
    mapping(uint256 => address) public originalLockedLizardOwners;
    // Stores the timestamp deposited per tokenId
    mapping(uint256 => uint256) public timeLizardLocked;
    // Stores the tokenId, and it's current claim status on each specific pool,
    // when a claim is made, we make it true
    mapping(uint256 => mapping(uint256 => bool)) stakePoolClaims;
    // Stores which contracts Locked Lizards are able to interact and approve to
    mapping(address => bool) public allowedContracts;

    struct Pool {
        // Timestamp of reset/pool creation
        uint256 time;
        // USDC value stored in the pool
        uint256 value;
        // The current overallShare when the pool is created
        uint256 currentGlobalShare;
    }

    // Pool structure
    Pool[] pool;

    // Flipstate for staking deposits
    bool public depositsActive;
    // Address of the EthlizardsDAO
    address public ethlizardsDAO = 0xa5D55281917936818665c6cB87959b6a147D9306;
    // Council address used for depositing rewards
    address public councilAddress;
    // Current count of rewards that are not in a pool, in 1e6 decimals
    uint256 public currentRewards;
    // Total count of the rewards that have been invested
    uint256 public totalRewardsInvested;
    // Current count of Ethlizards staked
    uint256 public currentEthlizardStaked;
    // Current count of Ethlizards staked
    uint256 public currentGenesisEthlizardStaked;
    // The timestamp when deposits are enabled
    uint256 public startTimestamp;
    // Global counter for the combined shares of all Ethlizards
    uint256 public overallShare;
    // The timestamp of the last rebase
    uint256 public lastGlobalUpdate;
    // Counter for resets
    uint256 public resetCounter = 0;
    // Refers to the current percentage of inflation kept per reset
    // EG, 20 = 80% slash in inflation, 20% of inflated shares kept per reset.
    uint256 public resetShareValue = 20;
    // The minimum rewards to be deposited for a reset to occur/a pool to be created.
    // Is in 1e6 format due to USDC's restrictions
    uint256 public minResetValue = 50000 * 1e6;
    // How long a lizard is locked up for
    uint256 public minLockedTime = 90 days;
    // Counter for rebases
    uint256 public rebaseCounter = 0;
    // This is the current approximated rebase value, stored in 64.64 fixed point format.
    // The real rebase value is calculated by nominator/2^64.
    int128 public nominator = 18.5389777940780994 * 1e18;
    // Metadata for LLZs
    string public baseURI = "https://ipfs.io/ipfsx";

    /**
     * @notice Deploys the smart contract and assigns interfaces
     * @param ethLizardsAddress Existing address of EthlizardsV2
     * @param genesisLizaddress Existing address of Genesis Ethlizards
     * @param USDCAddress Existing address of USDC
     */
    constructor(IEthlizards ethLizardsAddress, IGenesisEthlizards genesisLizaddress, IUSDC USDCAddress)
        ERC721("Locked Lizard", "LLZ")
    {
        Ethlizards = ethLizardsAddress;
        GenesisLiz = genesisLizaddress;
        USDc = USDCAddress;
    }

    /// @dev Modifier created to prevent marketplace sales and listings of Locked Lizard NFTs
    modifier onlyApprovedContracts(address operator) {
        if (!allowedContracts[operator]) {
            revert NotWhitelistedContract();
        }
        _;
    }

    /**
     * @notice Allows user to deposit their regular and Genesis Ethlizards for staking
     * @dev Upon initial call, a user will mint a Locked Lizard per Ethlizards (genesis and regular) they stake.
     * with matching tokenIds. Upon withdrawing their stake and staking their Ethlizard again,
     * the LLZ will be stored in the contract and thus when a later deposit is made, it is transferred
     * to the user. Genesis Ids are incremented by 5049 (The last tokenId of a regular Ethlizard).
     * @param _regularTokenIds The array of tokenIds that is deposited by the caller
     * @param _genesisTokenIds The array of Genesis tokenIds that is deposited by the caller
     */
    function depositStake(uint256[] calldata _regularTokenIds, uint256[] calldata _genesisTokenIds) external {
        if (!depositsActive) {
            revert DepositsInactive();
        }

        if (msg.sender != tx.origin) {
            revert CallerNotAnAddress();
        }

        if (_regularTokenIds.length > 0) {
            Ethlizards.batchTransferFrom(msg.sender, address(this), _regularTokenIds);
        }
        if (_genesisTokenIds.length > 0) {
            GenesisLiz.batchTransferFrom(msg.sender, address(this), _genesisTokenIds);
        }

        // Iterate over the regular Ethlizards deposits
        for (uint256 i = 0; i < _regularTokenIds.length; i++) {
            // First time stakers mint their new LLZ
            if (!_exists(_regularTokenIds[i])) {
                mintLLZ(_regularTokenIds[i]);
            } else {
                // Later deposits
                _safeTransfer(address(this), (msg.sender), _regularTokenIds[i], "");
                emit LockedLizardReMinted(msg.sender, _regularTokenIds[i]);
            }

            // add the timestamp the lizard was locked, and map user's address to deposited tokenId
            originalLockedLizardOwners[_regularTokenIds[i]] = msg.sender;
            timeLizardLocked[_regularTokenIds[i]] = block.timestamp;
            currentEthlizardStaked++;
        }

        // Iterate over the genesis Ethlizards deposits
        for (uint256 i = 0; i < _genesisTokenIds.length; i++) {
            // First time stakers mint their new LLZ, exception is here is the genesis ids
            uint256 newGenesisId = _genesisTokenIds[i] + MAXETHLIZARDID;
            if (!_exists(newGenesisId)) {
                mintLLZ(newGenesisId);
                emit LockedLizardMinted(msg.sender, newGenesisId);
            } else {
                // Later deposits
                _safeTransfer(address(this), (msg.sender), newGenesisId, "");
                emit LockedLizardReMinted(msg.sender, newGenesisId);
            }

            // add the timestamp the lizard was locked, and map user's address to deposited newGenesisId
            originalLockedLizardOwners[newGenesisId] = msg.sender;
            timeLizardLocked[newGenesisId] = block.timestamp;
            currentGenesisEthlizardStaked++;
        }

        /// @notice Calls a global update to the overallShare, then add the new shares
        updateGlobalShares();
        uint256 totalDeposit =
            (_regularTokenIds.length * DEFAULTLIZARDSHARE) + (_genesisTokenIds.length * DEFAULTLIZARDSHARE * 2);
        overallShare += totalDeposit;
    }

    /**
     * @notice Allows a user to withdraw their stake
     * @dev Users should only be able to withdraw their stake of both Genesis and regular Ethlizard,
     * and remove their current raw share from the overallShare.
     * @param _regularTokenIds The array of regular Ethlizards tokenIds that is deposited by the caller
     * @param _genesisTokenIds The array of genesis Ethlizards tokenIds that is deposited by the caller
     */
    function withdrawStake(uint256[] calldata _regularTokenIds, uint256[] calldata _genesisTokenIds) external {
        if (msg.sender != tx.origin) {
            revert CallerNotAnAddress();
        }

        /// @dev We need to update the overall share values first to ensure the future rebases are accurate
        updateGlobalShares();
        // Array of Locked Lizard tokenIds we transfer back to the staking contract
        /// @dev Loop for regular Ethlizard tokenIds
        for (uint256 i = 0; i < _regularTokenIds.length; i++) {
            if (originalLockedLizardOwners[_regularTokenIds[i]] != msg.sender) {
                revert CallerNotdepositor({
                    depositor: originalLockedLizardOwners[_regularTokenIds[i]],
                    caller: msg.sender
                });
            }

            if (!isLizardWithdrawable(_regularTokenIds[i])) {
                revert LizardNotWithdrawable();
            }

            // Remove the current raw share from the overall total
            uint256 regularShare = getCurrentShareRaw(_regularTokenIds[i]);
            overallShare = overallShare - regularShare;

            // Reset values
            timeLizardLocked[_regularTokenIds[i]] = 0;
            originalLockedLizardOwners[_regularTokenIds[i]] = address(0);
            currentEthlizardStaked--;

            // Transfer the token
            transferFrom(msg.sender, address(this), _regularTokenIds[i]);
        }

        for (uint256 i = 0; i < _genesisTokenIds.length; i++) {
            if (originalLockedLizardOwners[_genesisTokenIds[i]] != msg.sender) {
                revert CallerNotdepositor({
                    depositor: originalLockedLizardOwners[_genesisTokenIds[i]],
                    caller: msg.sender
                });
            }

            if (!isLizardWithdrawable(_genesisTokenIds[i])) {
                revert LizardNotWithdrawable();
            }

            // Remove the current raw share from the overall total
            uint256 genesisShare = getCurrentShareRaw(_genesisTokenIds[i]) * 2;
            overallShare = overallShare - genesisShare;

            // Reset values
            uint256 genesisId = _genesisTokenIds[i] + MAXETHLIZARDID;
            timeLizardLocked[genesisId] = 0;
            originalLockedLizardOwners[genesisId] = address(0);
            currentGenesisEthlizardStaked--;

            // Transfer the token
            transferFrom(msg.sender, address(this), _genesisTokenIds[i]);
        }

        if (_regularTokenIds.length > 0) {
            Ethlizards.batchTransferFrom(address(this), msg.sender, _regularTokenIds);
        }
        if (_genesisTokenIds.length > 0) {
            GenesisLiz.batchTransferFrom(address(this), msg.sender, _genesisTokenIds);
        }
    }

    /**
     * @notice Allows a user to claim their rewards
     * @dev When users unstake their NFT, they will lose their rewards, and the funds
     * will be locked into the contract.
     * @param _tokenIds Array of Locked Lizard tokenIds
     * @param _poolNumber Number of the pool where the user is trying to claim rewards from
     */
    function claimReward(uint256[] calldata _tokenIds, uint256 _poolNumber) external {
        uint256 claimableRewards;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (originalLockedLizardOwners[_tokenIds[i]] != msg.sender) {
                revert CallerNotdepositor({depositor: originalLockedLizardOwners[_tokenIds[i]], caller: msg.sender});
            }

            if (isRewardsClaimed(_tokenIds[i], _poolNumber)) {
                revert RewardsAlreadyClaimed({tokenId: _tokenIds[i], poolNumber: _poolNumber});
            }

            if (timeLizardLocked[_tokenIds[i]] >= pool[_poolNumber].time) {
                revert TokenStakedAfterPoolCreation({
                    tokenStakedTime: timeLizardLocked[_tokenIds[i]],
                    poolTime: pool[_poolNumber].time
                });
            }

            // Rewards calculation
            if (_tokenIds[i] > MAXETHLIZARDID) {
                // Genesis tokens have 2x more rewards share
                claimableRewards += (claimCalculation(_tokenIds[i], _poolNumber)) * 2;
                stakePoolClaims[_tokenIds[i]][_poolNumber] = true;
                emit RewardsClaimed(_tokenIds[i], (claimCalculation(_tokenIds[i], _poolNumber)) * 2);
            } else {
                claimableRewards += claimCalculation(_tokenIds[i], _poolNumber);
                stakePoolClaims[_tokenIds[i]][_poolNumber] = true;
                emit RewardsClaimed(_tokenIds[i], (claimCalculation(_tokenIds[i], _poolNumber)));
            }
        }

        // Transfer the USDC rewards to the user, this function does not require approvals
        USDc.transfer(msg.sender, claimableRewards);
    }

    /// @dev Required implementation for a smart contract to receive ERC721 token
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @notice Allows a user to send their Locked Lizard NFT back to the original depositor address
     * @dev As the claim function requires the user to hold the LLZ whilst also be the original depositor,
     * this function sends their LLZs back to them.
     * @param _tokenIds Array of Locked Lizard tokenIds
     */
    function retractLockedLizard(uint256[] calldata _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (originalLockedLizardOwners[_tokenIds[i]] != msg.sender) {
                revert CallerNotdepositor({depositor: originalLockedLizardOwners[_tokenIds[i]], caller: msg.sender});
            }

            _safeTransfer(
                ownerOf(_tokenIds[i]),
                (originalLockedLizardOwners[_tokenIds[i]]),
                /// @dev Don't think using msg.sender here is as safe as this
                _tokenIds[i],
                ""
            );
        }
    }

    /**
     * @notice Allows an approved council address to deposit rewards
     * @dev Council members deposit USDC, and once the deposited rewards reach the minResetValue,
     * a new pool is created and the currentRewards counter is reset.
     * @param _depositAmount Amount of USDC to withdrawal, in 6 DP
     */
    function depositRewards(uint256 _depositAmount) external {
        if (msg.sender != councilAddress) {
            revert AddressNotCouncil({council: councilAddress, caller: msg.sender});
        }
        USDc.transferFrom(msg.sender, address(this), _depositAmount);
        currentRewards += _depositAmount;
        totalRewardsInvested += _depositAmount;
        if (currentRewards >= minResetValue) {
            resetCounter++;
            createPool(currentRewards);
        }

        emit RewardsDeposited(_depositAmount);
    }

    /**
     * @notice Checks if a lizard is withdrawable
     * @dev A lizard is withdrawable if it been over minLockedTime since it was deposited
     * @param _tokenId TokenId of the lizard
     */
    function isLizardWithdrawable(uint256 _tokenId) public view returns (bool) {
        if (block.timestamp - timeLizardLocked[_tokenId] >= minLockedTime) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Checks if the rewards of a lizard for a specific pool have been claimed
     * @dev Default mapping is false, when claim is made, mapping is updated to be true
     * @param _tokenId TokenId of the lizard
     * @param _poolNumber The pool number
     */
    function isRewardsClaimed(uint256 _tokenId, uint256 _poolNumber) public view returns (bool) {
        return stakePoolClaims[_tokenId][_poolNumber];
    }

    /**
     * @dev Overriden approval function to limit contract interactions and marketplace listings
     */
    function setApprovalForAll(address operator, bool approved) public override onlyApprovedContracts(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev Overriden approval function to limit contract interactions and marketplace listings
     */
    function approve(address operator, uint256 tokenId) public override onlyApprovedContracts(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev Flips the state of deposits, only called once.
     */
    function setDepositsActive() external onlyOwner {
        if (depositsActive) {
            revert DepositsAlreadyActive();
        }
        depositsActive = true;
        startTimestamp = block.timestamp;
        lastGlobalUpdate = block.timestamp;
    }

    /**
     * @notice This function can only be called by the EthlizardsDAO address
     *  This should only be used in emergency scenarios
     * @param _withdrawalAmount Amount of USDC to withdrawal, in 6 DP
     */
    function withdrawalToDAO(uint256 _withdrawalAmount) external {
        if (msg.sender != ethlizardsDAO) {
            revert AddressNotDAO();
        }
        USDc.transfer(msg.sender, _withdrawalAmount);
    }

    /**
     * @dev Sets contracts users are allowed to approve contract interactions with
     * @param _address Contract address where access is being modified
     * @param access The access of the address (false = users aren't allowed to approve, vice versa)
     */
    function setAllowedContracts(address _address, bool access) external onlyOwner {
        allowedContracts[_address] = access;
        emit AllowedContractsUpdated(_address, access);
    }

    /**
     * @dev Sets the reset value. Values are stored in percentages, 20 = 20% of inflation rewards kept per reset
     * @param _newShareResetValue New reset value
     */
    function setResetShareValue(uint256 _newShareResetValue) external onlyOwner {
        if (_newShareResetValue >= 100) {
            revert ShareResetTooHigh();
        }
        resetShareValue = _newShareResetValue;
        emit ResetShareValueUpdated(_newShareResetValue);
    }

    /**
     * @dev Whitelists a council address to be able to deposit rewards.
     * There can only be one council address at the same time.
     * @param _councilAddress The council's address
     */
    function setCouncilAddress(address _councilAddress) external onlyOwner {
        councilAddress = _councilAddress;
        emit CouncilAddressUpdated(_councilAddress);
    }

    /**
     * @dev Updates how long a user needs to stake before they can withdraw their NFT
     * @param _minLockedTime The amount of seconds a user needs to stake
     */
    function setMinLockedTime(uint256 _minLockedTime) external onlyOwner {
        minLockedTime = _minLockedTime;
        emit MinLockedTimeUpdated(minLockedTime);
    }

    /**
     * @dev Modifies the minimum value for a reset to occur and a new pool to be created
     * @param _newMinResetValue The minimum value for a reset, keep in mind USDC uses 6 decimal points
     * so an input of 100,000,000,000 would be 100,000 USDC
     */
    function setMinResetValue(uint256 _newMinResetValue) external onlyOwner {
        minResetValue = _newMinResetValue;
        emit MinResetValueUpdated(_newMinResetValue);
    }

    /**
     * @notice Updates metadata
     */
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit BaseURIUpdated(_baseURI);
    }

    /**
     * @notice Overriden tokenURI to accept ipfs links
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json")) : "";
    }

    /**
     * @notice Gets the current raw share of an Ethlizard
     * @dev See technical documentation for how user's shares are calculated
     * @param _tokenId TokenId for which share is being calculated
     */
    function getCurrentShareRaw(uint256 _tokenId) public view returns (uint256) {
        // The current raw share which gets iterated over throughout the code
        uint256 currentShareRaw;

        // Counter for the current pool
        uint256 currPool;
        // Counter for the previous pool
        uint256 prevPool;

        // Case A: If there is only 1 pool, we do not need to factor into resets.
        // Case B: If no pools have been created after the user has staked, we do not need to factor in resets.
        if ((pool.length == 0) || (pool[pool.length - 1].time) < timeLizardLocked[_tokenId]) {
            currentShareRaw = calculateShareFromTime(block.timestamp, timeLizardLocked[_tokenId], DEFAULTLIZARDSHARE);
            return currentShareRaw;
        } // Case C: One or more pools created, but the user was staked before the creation of all of them.
        else if (timeLizardLocked[_tokenId] <= pool[0].time) {
            // Will always be the first pool because the the user is staked before creation of any pools
            currentShareRaw = calculateShareFromTime(pool[0].time, timeLizardLocked[_tokenId], DEFAULTLIZARDSHARE);

            currentShareRaw = resetShareRaw(currentShareRaw);
            // Setting the values for the loop
            currPool = 1;
            prevPool = currPool - 1;
        } // Case D: User was staked between 2 pools
        else {
            // Iterate through the pools and set currPool to the next pool created after user is staked.
            currPool = pool.length - 1;
            prevPool = currPool - 1;
            while (timeLizardLocked[_tokenId] < pool[prevPool].time) {
                currPool--;
                prevPool--;
            }
            // Calculate first share which is done by the first pool created after token staked
            currentShareRaw =
                calculateShareFromTime(pool[currPool].time, timeLizardLocked[_tokenId], DEFAULTLIZARDSHARE);
            currentShareRaw = resetShareRaw(currentShareRaw);
            currPool++;
            prevPool++;
        }

        // Counter for the last reset
        uint256 lastReset = pool.length - 1;

        // Looping over the pools
        while (currPool <= lastReset) {
            currentShareRaw = calculateShareFromTime(pool[currPool].time, pool[prevPool].time, currentShareRaw);
            currentShareRaw = resetShareRaw(currentShareRaw);
            currPool++;
            prevPool++;
        }

        // Finding the inflation between the current time and the last pool's reset's time.
        currentShareRaw = calculateShareFromTime(block.timestamp, pool[lastReset].time, currentShareRaw);
        return currentShareRaw;
    }

    /**
     * @notice Creates a new pool for rewards
     * @dev A new pool is created everytime a reset occurs, and they contain a user's rewards.
     * Reset of user's shares and inflation occurs after the values are pushed to the pool.
     */
    function createPool(uint256 _value) internal {
        updateGlobalShares();
        pool.push(Pool(block.timestamp, _value, overallShare));
        currentRewards = 0;
        resetGlobalShares();
    }

    /**
     * @notice Resets the inflation for a user's shares
     * @dev See technical documentation for how shares are calculated
     */
    function resetGlobalShares() internal {
        uint256 nonInflatedOverallShare =
            (currentEthlizardStaked * DEFAULTLIZARDSHARE) + (currentGenesisEthlizardStaked * DEFAULTLIZARDSHARE * 2);

        overallShare = (((overallShare - nonInflatedOverallShare) * resetShareValue) / 100) + (nonInflatedOverallShare);
    }

    /**
     * @notice Updates the global counter shares
     * @dev See technical documentation for how shares are calculated
     */
    function updateGlobalShares() internal {
        uint256 requiredRebases = ((block.timestamp - lastGlobalUpdate) / 1 days);
        if (requiredRebases >= 1) {
            overallShare = ((overallShare * calculateRebasePercentage(requiredRebases)) / 1e18);
            rebaseCounter += requiredRebases;
            lastGlobalUpdate += requiredRebases * 1 days;
        }
    }

    /**
     * @notice Calculates the rewards of a tokenId for the specific pool
     * @param _tokenId The tokenId which rewards are being claimed
     * @param _poolNumber The pool in which rewards are being claimed from
     */

    function claimCalculation(uint256 _tokenId, uint256 _poolNumber) public view returns (uint256 owedAmount) {
        // The current raw share which gets iterated over throughout the code
        uint256 currentShareRaw;
        // Counter for the current pool
        uint256 currPool;
        // Counter for the previous pool
        uint256 prevPool;

        // Case A: If there is only 1 pool, we do not need to factor into any resets
        if (_poolNumber == 0) {
            currentShareRaw =
                calculateShareFromTime(pool[_poolNumber].time, timeLizardLocked[_tokenId], DEFAULTLIZARDSHARE);
            owedAmount = (currentShareRaw * pool[_poolNumber].value) / pool[_poolNumber].currentGlobalShare;
            return owedAmount;
        } // Case B: One or more pools created, but the user was staked before the creation of all of them.
        else if (timeLizardLocked[_tokenId] <= pool[0].time) {
            // Second case runs if there has been at least 1 reset
            // and the user was staked before the first reset
            currentShareRaw = calculateShareFromTime(pool[0].time, timeLizardLocked[_tokenId], DEFAULTLIZARDSHARE);
            currPool = 1;
            prevPool = currPool - 1;
        } // Case C: User was staked between 2 pools
        else {
            // Iterate through the pools and set currPool to the next pool created after the user has staked.
            currPool = pool.length - 1;
            prevPool = currPool - 1;
            while (timeLizardLocked[_tokenId] < pool[prevPool].time) {
                currPool--;
                prevPool--;
            }
            // Calculate first share which is done by the first pool created after token staked
            currentShareRaw =
                calculateShareFromTime(pool[currPool].time, timeLizardLocked[_tokenId], DEFAULTLIZARDSHARE);
            currPool++;
            prevPool++;
        }

        // Loop to apply inflations
        while (currPool <= _poolNumber) {
            currentShareRaw = resetShareRaw(currentShareRaw);
            currentShareRaw = calculateShareFromTime(pool[currPool].time, pool[prevPool].time, currentShareRaw);
            prevPool++;
            currPool++;
        }
        // Calculate the rewards the user can claim
        owedAmount = (currentShareRaw * pool[_poolNumber].value) / pool[_poolNumber].currentGlobalShare;
        return owedAmount;
    }

    /**
     * @notice Takes 2 different unix timestamps and returns the inflation-applied raw share of it.
     * If 0 is called from requiredRebases, the rebase percentage will just be 1.
     */
    function calculateShareFromTime(uint256 _currentTime, uint256 _previousTime, uint256 _rawShare)
        internal
        view
        returns (uint256)
    {
        uint256 requiredRebases = ((_currentTime - startTimestamp) - (_previousTime - startTimestamp)) / 1 days;
        uint256 result = (_rawShare * calculateRebasePercentage(requiredRebases)) / 1e18;
        return result;
    }

    /**
     * @notice We calculate the 1.005^_requiredRebases via this function.
     * @dev See technical documents for how maths is calculated.
     *  We apply log laws to a compound interest formula which allows us to calculate
     *  values in big number form without overflow errors
     */
    function calculateRebasePercentage(uint256 _requiredRebases) internal view returns (uint256) {
        // Conversion of the uint256 rebases to int128 form
        // Divide by 2^64 as the converted result is in 64.64-bit fixed point form
        int128 requiredRebasesConverted = ABDKMath64x64.fromUInt(_requiredRebases) / (2 ** 64);
        // Using compound formula specified in technical documents
        int128 calculation = (ABDKMath64x64.log_2(nominator) * requiredRebasesConverted);
        int128 result = (ABDKMath64x64.exp_2(calculation) * 1e16);
        uint256 uintResult = ABDKMath64x64.toUInt(result) * 1e2;
        return uintResult;
    }

    /**
     * @dev Maths function to apply a reset to a user's shares
     * @param _currentShareRaw The raw share where inflation is being slashed
     */
    function resetShareRaw(uint256 _currentShareRaw) internal view returns (uint256) {
        return (((_currentShareRaw - DEFAULTLIZARDSHARE) * resetShareValue) / 100) + (DEFAULTLIZARDSHARE);
    }

    /**
     * @notice Calls ERC721's mint function
     * @param _tokenId TokenId being minted
     */
    function mintLLZ(uint256 _tokenId) internal {
        _mint(msg.sender, _tokenId);
        emit LockedLizardMinted(msg.sender, _tokenId);
    }

    ////////////
    // Errors //
    ////////////

    // User is trying to approve contract interactions with a contract that hasn't been whitelisted
    error NotWhitelistedContract();
    // Deposits are not enabled yet
    error DepositsInactive();
    // The address isn't the same address as the depositor
    error CallerNotdepositor(address depositor, address caller);
    // The lizard has not passed the minimum lockup term and is not withdrawable
    error LizardNotWithdrawable();
    // Rewards have already been claimed for the lizard
    error RewardsAlreadyClaimed(uint256 tokenId, uint256 poolNumber);
    // Address isn't the council
    error AddressNotCouncil(address council, address caller);
    // Address isn't the Ethlizards DAO address
    error AddressNotDAO();
    // _newShareResetValue value cannot be more than 100%
    error ShareResetTooHigh();
    // Deposits are already active
    error DepositsAlreadyActive();
    // Tokens must have been staked prior to a pools creation
    error TokenStakedAfterPoolCreation(uint256 tokenStakedTime, uint256 poolTime);
    // No contract interactions
    error CallerNotAnAddress();
}