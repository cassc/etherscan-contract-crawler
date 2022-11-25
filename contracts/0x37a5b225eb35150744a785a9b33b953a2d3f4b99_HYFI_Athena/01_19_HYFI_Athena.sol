// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../interfaces/IHYFI_Athena.sol";
import "../interfaces/IHYFI_RewardsManager.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// solhint-disable-next-line contract-name-camelcase
contract HYFI_Athena is
    Initializable,
    IHYFI_Athena,
    IHYFI_RewardsManager,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ERC721BurnableUpgradeable
{
    /**
     * @dev information about Athena type
     * @param name - Athena type name
     * @param rangeMin - Athena type min id (comparison >=)
     * @param rangeMax - Athena type max id (comparison <)
     * @param distributedRewardAmount is amount of tokens already distributed within this type
     */
    struct RewardTypesInfo {
        string name;
        uint256 rangeMin;
        uint256 rangeMax;
        uint256 distributedRewardAmount;
    }

    /// @dev PAUSER_ROLE role identifier
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @dev MINTER_ROLE role identifier
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @dev BURNER_ROLE role identifier
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /**
     * @dev array of Athena types
     *  uses struct RewardTypesInfo
     *
     *      name - Athena type name
     *      rangeMin - Athena type min id (comparison >=)
     *      rangeMax - Athena type max id (comparison <)
     *      distributedRewardAmount is amount of tokens already distributed within this type
     */
    RewardTypesInfo[] public rewardTypes;

    /// @dev limit of Athena tokens supply
    uint256 private _supplyLimit;

    /// @dev base token URI
    string private _baseTokenURI;

    /**
     * @dev event on successfull base URI change
     * @param _baseURI the new base URI
     */
    event BaseURIChanged(string _baseURI);

    /**
     * @dev event on successfull Athena tokens mint
     * @param user owner of Athena tokens
     * @param tokenIds newly minted ids
     */
    event AthenaMinted(address user, uint256[] tokenIds);

    /**
     * @dev check if token amount is less than supply limit
     * @param tokenAmount amount of tokens is going to mint
     */
    modifier underSupplyLimit(uint256 tokenAmount) {
        require(
            tokenAmount + totalSupply() <= _supplyLimit,
            "Tokens surpass supply limit."
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev initializer
     * @param tokenName Athena token name
     * @param tokenSymbol Athena token symbol
     * @param supplyLimit total supply limit for Athena tokens
     */
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 supplyLimit
    ) external virtual initializer {
        __ERC721_init(tokenName, tokenSymbol);
        __ERC721Enumerable_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC721Burnable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        _supplyLimit = supplyLimit;
    }

    /**
     * @dev pause Athena token, tokens transfers are not available when paused
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev unpause Athena token, tokens transfers are available
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev add new Athena Type
     * @param setName Athena type name
     * @param rangeMin min Athena type ID
     * @param rangeMax max Athena type ID
     */
    function addRewardsType(
        string memory setName,
        uint256 rangeMin,
        uint256 rangeMax
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        RewardTypesInfo memory rewardType;
        rewardType.name = setName;
        rewardType.rangeMax = rangeMax;
        rewardType.rangeMin = rangeMin;
        rewardType.distributedRewardAmount = 0;
        rewardTypes.push(rewardType);
    }

    /**
     * @dev update Athena Type
     * @param rewardsTypeId Athena type ID is going to be updated
     * @param setName new Athena type name
     * @param rangeMin min Athena type ID
     * @param rangeMax max Athena type ID
     */
    function updateRewardsType(
        uint256 rewardsTypeId,
        string memory setName,
        uint256 rangeMin,
        uint256 rangeMax
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        RewardTypesInfo storage rewardType = rewardTypes[rewardsTypeId];
        rewardType.name = setName;
        rewardType.rangeMax = rangeMax;
        rewardType.rangeMin = rangeMin;
    }

    /**
     * @dev delete last Athena Type
     */
    function deleteRewardsTypeTop() external onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardTypes.pop();
    }

    /**
     * @dev generate/reveal rewards for user
     * @param user the user, rewards are revealed for
     * @param amount the amount of rewards need to be revealed
     * @param rewardId the reward ID from lottery SC
     */
    function revealRewards(
        address user,
        uint256 amount,
        uint256 rewardId
    ) external underSupplyLimit(amount) onlyRole(MINTER_ROLE) {
        uint256 typeId;
        uint256 lastRangeUsedId;
        uint256[] memory tokenIds = new uint256[](amount);
        for (uint256 i = 0; i < amount; i++) {
            typeId = getWinningRewardsType(i);
            lastRangeUsedId =
                rewardTypes[typeId].distributedRewardAmount +
                rewardTypes[typeId].rangeMin;
            rewardTypes[typeId].distributedRewardAmount += 1;
            _safeMint(user, lastRangeUsedId);
            tokenIds[i] = lastRangeUsedId;
        }
        emit AthenaMinted(user, tokenIds);

        emit RewardsRevealed(user, rewardId, amount);
    }

    /**
     * @dev set max supply limit for Athena tokens
     * @param supplyLimit new supply limit
     */
    function setMaximumSupplyLimit(
        uint256 supplyLimit
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _supplyLimit = supplyLimit;
    }

    /**
     * @dev set new base URI
     * @param baseTokenURI new base uri
     */
    function setBaseURI(
        string memory baseTokenURI
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = baseTokenURI;
        emit BaseURIChanged(_baseTokenURI);
    }

    /**
     * @dev burn specific token
     * @param tokenId token id need to be burned
     */
    function burn(
        uint256 tokenId
    ) public override(ERC721BurnableUpgradeable) onlyRole(BURNER_ROLE) {
        _burn(tokenId);
    }

    /**
     * @dev generate random value
     * @param salt additional parameter for random generation
     * @return return random value
     */
    function getRandomValue(uint256 salt) public view returns (uint256) {
        /* solhint-disable not-rely-on-time */
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender,
                        salt
                    )
                )
            );
        /* solhint-enable not-rely-on-time */
    }

    /**
     * @dev get Athena type which is winning for specific order number
     * @param salt additional parameter for random generation, order number of reward
     * @return return Athena type ID
     */
    function getWinningRewardsType(uint256 salt) public view returns (uint256) {
        uint256 index;
        uint256 randomID = getRandomValue(salt) % _supplyLimit;
        for (uint256 i = 0; i < rewardTypes.length; i++) {
            if (
                randomID >= rewardTypes[i].rangeMin &&
                randomID < rewardTypes[i].rangeMax
            ) {
                for (uint256 j = 0; j < rewardTypes.length; j++) {
                    index = (i + j) % rewardTypes.length;
                    if (
                        (rewardTypes[index].distributedRewardAmount +
                            rewardTypes[index].rangeMin) <
                        rewardTypes[index].rangeMax
                    ) {
                        return index;
                    }
                }
            }
        }
        revert("No available reward");
    }

    /**
     * @dev get supply limit value
     * @return return value of supply limit
     */
    function getSupplyLimit() public view returns (uint256) {
        return _supplyLimit;
    }

    /**
     * @dev get token ids owned by user
     * @param user user address
     * @return return token ids array
     */
    function getUserTokenIds(
        address user
    ) public view returns (uint256[] memory) {
        uint256 tokensAmount = balanceOf(user);
        uint256[] memory tokenIds = new uint256[](tokensAmount);
        for (uint256 i = 0; i < tokensAmount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(user, i);
        }
        return tokenIds;
    }

    /**
     * @dev get token ids owned by user for specific type
     * @param user user address
     * @param rewardTypeId Athena type id
     * @return return token ids array
     */
    function getUserTokenIdsByType(
        address user,
        uint256 rewardTypeId
    ) public view returns (uint256[] memory) {
        (
            uint256[] memory tokenIdsAll,
            uint256 size
        ) = _getUserTokenIdsByTypeAll(user, rewardTypeId);
        uint256[] memory tokenIds = new uint256[](size);
        for (uint256 i = 0; i < size; i++) {
            tokenIds[i] = tokenIdsAll[i];
        }
        return tokenIds;
    }

    /**
     * @dev get token URI by id
     * @param tokenId token id
     * @return return token URI string
     */
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721Upgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev check if SC supports interface
     * @param interfaceId interface id
     * @return return true if supported
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev burn token internal
     * @param tokenId token id
     */
    function _burn(uint256 tokenId) internal override(ERC721Upgradeable) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev get base URI internal
     */
    function _baseURI()
        internal
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        return _baseTokenURI;
    }

    /**
     * @dev get user token ids for specific type, but with trailing zeros ex: [1,5,0,8,0,0]
     * @param user user address
     * @param rewardTypeId Athena type id
     * @return return token ids array with trailing zeros
     * @return return size
     */
    function _getUserTokenIdsByTypeAll(
        address user,
        uint256 rewardTypeId
    ) internal view returns (uint256[] memory, uint256) {
        uint256 tokensAmount = balanceOf(user);
        uint256[] memory tokenIds = new uint256[](tokensAmount);
        uint256 tokenId;
        uint256 size;
        for (uint256 i = 0; i < tokensAmount; i++) {
            tokenId = tokenOfOwnerByIndex(user, i);
            if (
                tokenId < rewardTypes[rewardTypeId].rangeMax &&
                tokenId >= rewardTypes[rewardTypeId].rangeMin
            ) {
                tokenIds[size] = tokenId;
                size++;
            }
        }
        return (tokenIds, size);
    }
}