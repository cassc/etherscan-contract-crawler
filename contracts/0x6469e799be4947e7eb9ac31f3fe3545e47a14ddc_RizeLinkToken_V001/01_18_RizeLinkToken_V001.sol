// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @custom:security-contact [email protected]
contract RizeLinkToken_V001 is
    Initializable,
    ERC20Upgradeable,
    ERC20SnapshotUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    /**
     * @notice All stakeholders of RLT
     */
    address[] internal stakeholders;  

    /**
     * @notice The stakes for each stakeholder, segregated by tiers
     */
    mapping(address => uint256[3]) internal stakes;

    /**
     * @notice The thresholds of stakes, segregated by tiers (0 = unlimited)
     */
    mapping(uint8 => uint256) internal stakesLimit;

    /**
     * @notice Total number of tiers
     */
    uint8 internal numTiers;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {

        __ERC20_init("RizeLink Token", "RLT");
        __ERC20Snapshot_init();
        __Ownable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _mint(msg.sender, 13000000 * 10**decimals());

        setInitialStakeLimits();
    }

    function setInitialStakeLimits() internal onlyOwner {

         stakesLimit[0] = 250000 * 10**decimals();
         stakesLimit[1] = 400000 * 10**decimals();
         stakesLimit[2] = 0;    // 0 = No limit
         
         numTiers = 3;          // Totally 3 tiers at the moment
    }

    function setStakeLimit(uint8 _tier, uint256 _newLimit) public onlyOwner {

        stakesLimit[_tier] = _newLimit;
    }

    function stakeLimit(uint8 _tier) public view returns (uint256) {

        return stakesLimit[_tier];
    }

    function stakeLimits() public view returns (uint256[] memory) {

        uint256[] memory result = new uint256[](3);

        for (uint8 i = 0; i < numTiers; i++)
            result[i] = stakesLimit[i];

        return result;
    }

    function decimals() public view virtual override returns (uint8) {

        // 6 decimal places is enough for RLT to simplify things
        return 6; 
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        override(ERC20Upgradeable, ERC20SnapshotUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function versionNumber() public pure returns (uint) {
        return 1118;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? b : a;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /*** Staking Functions ***/

    /**
     * @notice A method to check if an address is a stakeholder.
     * @param _address The address to verify.
     * @return bool, uint256 Whether the address is a stakeholder,
     * and if so its position in the stakeholders array.
     */
    function isStakeholder(address _address)
        public
        view
        returns (bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    /**
     * @notice A method to add a stakeholder.
     * @param _stakeholder The stakeholder to add.
     */
    function addStakeholder(address _stakeholder) internal {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if (!_isStakeholder) stakeholders.push(_stakeholder);
    }

    /**
     * @notice A method to remove a stakeholder.
     * @param _stakeholder The stakeholder to remove.
     */
    function removeStakeholder(address _stakeholder) internal {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if (_isStakeholder) {
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        }
    }

    /**
     * @notice A method to retrieve the stake for a stakeholder for ALL tiers.
     * @param _stakeholder The stakeholder to retrieve the stake for.
     * @return uint256 The amount of RLT staked.
     */
    function stakeOf(address _stakeholder) public view returns (uint256) {
        return stakeOfByTier(_stakeholder, 0) + stakeOfByTier(_stakeholder, 1) + stakeOfByTier(_stakeholder, 2);
    }

        /**
     * @notice A method to retrieve the stake for a stakeholder for ALL tiers.
     * @param _stakeholder The stakeholder to retrieve the stake for.
     * @return uint256 The amount of RLT staked at each tier.
     */
    function stakeOfByTiers(address _stakeholder) public view returns (uint256[] memory) {
        
        uint256[] memory result = new uint256[](3);

        for (uint8 i = 0; i < numTiers; i++)
            result[i] = stakes[_stakeholder][i];

        return result;
    }

    /**
     * @notice A method to retrieve the stake for a stakeholder.
     * @param _stakeholder The stakeholder to retrieve the stake for.
     * @param _tier The tier of stake to check for (tier 0 to tier 2)
     * @return uint256 The amount of RLT staked.
     */
    function stakeOfByTier(address _stakeholder, uint8 _tier) public view returns (uint256) {

        return stakes[_stakeholder][_tier];
    }

    /**
     * @notice A method to the aggregated stakes from all stakeholders.
     * @return uint256 The aggregated stakes from all stakeholders.
     */
    function totalStakes() public view returns (uint256) {
        uint256 _totalStakes = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            for (uint8 t = 0; t < stakes[stakeholders[s]].length; t += 1) {
                _totalStakes = _totalStakes + stakes[stakeholders[s]][t];
            }
        }
        return _totalStakes;
    }

    /**
     * @notice Check whether all upper tier(s) stake are empty (prerequisite for unstaking a particular tier).
     * @param _stakeholderAddress The address of the stakeholder.
     * @param _tier The tier to check (tier 0 to tier 2).
     */
    function isUpperTiersAllEmpty(address _stakeholderAddress, uint _tier) internal view returns (bool) {

        for (uint8 i = numTiers - 1; i > _tier; i -= 1) {

            if (stakes[_stakeholderAddress][i] != 0)
                return false;
        }

        return true;
    }

    /**
     * @notice Check whether all lower tier(s) stake are fully filled (prerequisite for staking a particular tier).
     * @param _stakeholderAddress The address of the stakeholder.
     * @param _tier The tier to check (tier 0 to tier 2).
     */
    function isLowerTiersAllFilled(address _stakeholderAddress, uint _tier) internal view returns (bool) {

        for (uint8 i = 0; i < _tier; i += 1) {

            if (stakes[_stakeholderAddress][i] != stakesLimit[i])
                return false;
        }

        return true;
    }

    /**
     * @notice A method for a stakeholder to create a stake.
     * @param _stake The size of the stake to be created (with all decimals included in the inputted parameter)
    * @param _tier The tier to stake (tier 0 to tier 2).
     */
    function createStake(uint256 _stake, uint8 _tier) public {

        createStakeInternal(msg.sender, _stake, _tier, false);
    }

    /**
     * @notice A method for a administrator to create a stake for a stakeholder.
     * @param _stakeholderAddress The address of the stakeholder to be created.
     * @param _stake The size of the stake to be created (with all decimals included in the inputted parameter)
     * @param _tier The tier to stake (tier 0 to tier 2).
     */
    function createStakeByAdmin(address _stakeholderAddress, uint256 _stake, uint8 _tier) public onlyOwner {

       createStakeInternal(_stakeholderAddress, _stake, _tier, true);
    }

    /**
     * @notice An internal method to create a stake.
     * @param _stakeholderAddress The address of the stakeholder to be created.
     * @param _stake The size of the stake to be created (with all decimals included in the inputted parameter)
     * @param _tier The tier to stake (tier 0 to tier 2).
     * @param _isOverride whether the call is an overriding one for tier threshold and staking rules.
     */
    function createStakeInternal(address _stakeholderAddress, uint256 _stake, uint8 _tier, bool _isOverride) internal {

        // Validation: Sufficient token balance for staking
        require(balanceOf(_stakeholderAddress) >= _stake, "Insufficient token for staking");

        // Validation: all lower staking levels need to be fully filled (if the rule is not to be overridden)
        require(_isOverride || isLowerTiersAllFilled(_stakeholderAddress, _tier), "All lower tiers must be fully staked before staking to this tier");

        // Validation: New staked amount < tier threshold (if threhold is not to be overridden)
        uint256 newStakedAmount = stakes[_stakeholderAddress][_tier] + _stake;
        require(_isOverride || stakesLimit[_tier] == 0 || newStakedAmount <= stakesLimit[_tier], "Total staking amount exceeds threshold of this tier");

        // Add the stakeholder if needed
        addStakeholder(_stakeholderAddress);

        // Stake !
        stakes[_stakeholderAddress][_tier] = newStakedAmount;

        // Finally, burn the stake from the client's wallet
        _burn(_stakeholderAddress, _stake);
    }

    /**
     * @notice A method for a stakeholder to remove a stake.
     * @param _stake The size of the stake to be removed (with all decimals included in the inputted parameter)
     * @param _tier The tier to reomve the stake from (tier 0 to tier 2).
     */
    function removeStake(uint256 _stake, uint8 _tier) public { 

        removeStakeInternal(msg.sender, _stake, _tier, false, false);
    }

    /**
     * @notice A method for administrator to remove a stake from a stakeholder.
     * @param _stakeholderAddress The address of the stakeholder to be removed.
     * @param _stake The size of the stake to be removed  (with all decimals included in the inputted parameter)
     * @param _tier The tier to reomve the stake from (tier 0 to tier 2).
     * @param _isWaivePenalty to denote whether the calculated penalty should be waived.
     */
    function removeStakeByAdmin(address _stakeholderAddress, uint256 _stake, uint8 _tier, bool _isWaivePenalty) public onlyOwner { 

        removeStakeInternal(_stakeholderAddress, _stake, _tier, true, _isWaivePenalty);
    }

    /**
     * @notice An internal method for to remove a stake from a stakeholder.
     * @param _stakeholderAddress The address of the stakeholder to be removed.
     * @param _stake The size of the stake to be removed (with all decimals included in the inputted parameter)
     * @param _tier The tier to reomve the stake from (tier 0 to tier 2).
     * @param _isOverride whether the call is an overriding one for tier threshold and staking rules.
     * @param _isWaivePenalty to denote whether the calculated penalty should be waived.
     */
    function removeStakeInternal(address _stakeholderAddress, uint256 _stake, uint8 _tier, bool _isOverride, bool _isWaivePenalty) internal { 

        // Validation: amount to be removed from stake >= available staked amount
        require(stakes[_stakeholderAddress][_tier] >= _stake, "Insufficient staked amount to be unstaked");

        // Validation: all upper staking levels need to be empty (if the rule is not to be overridden)
        require(_isOverride || isUpperTiersAllEmpty(_stakeholderAddress, _tier), "All upper tiers must be all unstaked / empty before unstaking this tier");

        // Calcuate penalty amount
        // * Take note that penalty amount is ALWAYS deducted from the unstaking amount (rounding down to the nearest 1 RLT with minimum of 1 RLT)
        // * Rebate will be conducted offline manually within 1 business day if the unstaking happens after 90 calendar days of staking for the particular portion of RLT.
        uint256 penaltyAmount = _isWaivePenalty ? 0 : max(_stake * 3 / 100 / (10**decimals()) * (10**decimals()), 10**decimals());

        // Unstake !
        stakes[_stakeholderAddress][_tier] = stakes[msg.sender][_tier] - _stake;

        // Remove the stakeholder if needed
        if (stakeOf(_stakeholderAddress) == 0)
            removeStakeholder(_stakeholderAddress);

        // Finally, mint the stake amount to the client's wallet (omitting the penalty amount)
        _mint(_stakeholderAddress, _stake - penaltyAmount);
    }
}