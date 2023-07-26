// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "IERC721Receiver.sol";
import "IERC721.sol";
import "Ownable.sol";
import "HONOR.sol";

contract War is Ownable, IERC721Receiver {
    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    event TokenStaked(address owner, uint256 tokenId, uint256 value);
    event HONORClaimed(uint256 tokenId, uint256 earned, bool unstaked);

    // reference to the SamuraiDoge NFT contract
    IERC721 samuraidoge;
    // reference to the $HONOR contract for minting $HONOR earnings
    HONOR honor;

    // maps tokenId to stake
    mapping(uint256 => Stake) public war;

    // maps address to number of tokens staked
    mapping(address => uint256) public numTokensStaked;

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // samuraidoge earn 10 $HONOR per day
    uint256 public constant DAILY_HONOR_RATE = 10 ether;

    // number of SamuraiDoge staked in the War
    uint256 public totalSamuraiDogeStaked;

    // the last time $HONOR can be claimed
    uint256 public lastClaimTimestamp;

    // whether staking is active
    bool public stakeIsActive = true;

    // Bonus $HONOR for elligible tokens
    uint256 public tokensElligibleForBonus;
    uint256 public bonusAmount;
    mapping(uint256 => bool) public bonusClaimed;

    /**
     * @param _samuraidoge reference to the SamuraiDoge NFT contract
     * @param _honor reference to the $HONOR token
     * @param _claimPeriod Period (in seconds) from contract creation when staked SamuraiDoges can earn $HON
     * @param _tokensElligibleForBonus Number of tokens elligible for bonus $HON (ordered by tokenId)
     * @param _bonusAmount Amount of $HON (in Wei) to be given out as bonus
     */
    constructor(
        address _samuraidoge,
        address _honor,
        uint256 _claimPeriod,
        uint256 _tokensElligibleForBonus,
        uint256 _bonusAmount
    ) {
        samuraidoge = IERC721(_samuraidoge);
        honor = HONOR(_honor);
        lastClaimTimestamp = block.timestamp + _claimPeriod;
        tokensElligibleForBonus = _tokensElligibleForBonus;
        bonusAmount = _bonusAmount;
    }

    /** STAKING */

    /**
     * adds SamuraiDoges to the War
     * @param tokenIds the IDs of the SamuraiDoge to stake
     */
    function addManyToWar(uint16[] calldata tokenIds) external {
        require(stakeIsActive, "Staking is paused");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                samuraidoge.ownerOf(tokenIds[i]) == msg.sender,
                "Not your token"
            );
            samuraidoge.transferFrom(msg.sender, address(this), tokenIds[i]);
            _addSamuraiDogeToWar(msg.sender, tokenIds[i]);
        }
    }

    /**
     * adds a single SamuraiDoge to the War
     * @param owner the address of the staker
     * @param tokenId the ID of the SamuraiDoge to add to the War
     */
    function _addSamuraiDogeToWar(address owner, uint256 tokenId) internal {
        war[tokenId] = Stake({
            owner: owner,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp)
        });
        _addTokenToOwnerEnumeration(owner, tokenId);
        totalSamuraiDogeStaked += 1;
        numTokensStaked[owner] += 1;
        emit TokenStaked(owner, tokenId, block.timestamp);
    }

    /** CLAIMING / UNSTAKING */

    /**
     * realize $HONOR earnings and optionally unstake tokens from the War
     * @param tokenIds the IDs of the tokens to claim earnings from
     * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
     */
    function claimManyFromWar(uint16[] calldata tokenIds, bool unstake)
        external
    {
        uint256 owed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            owed += _claimHonorFromWar(tokenIds[i], unstake);
        }
        if (owed == 0) return;
        honor.stakingMint(msg.sender, owed);
    }

    /**
     * realize $HONOR earnings for a single SamuraiDoge and optionally unstake it
     * @param tokenId the ID of the SamuraiDoge to claim earnings from
     * @param unstake whether or not to unstake the SamuraiDoge
     * @return owed - the amount of $HONOR earned
     */
    function _claimHonorFromWar(uint256 tokenId, bool unstake)
        internal
        returns (uint256)
    {
        Stake memory stake = war[tokenId];
        if (stake.owner == address(0)) {
            // Unstaked SD tokens
            require(
                samuraidoge.ownerOf(tokenId) == msg.sender,
                "Not your token"
            );
            uint256 owed = _getClaimableHonor(tokenId);
            bonusClaimed[tokenId] = true;
            emit HONORClaimed(tokenId, owed, unstake);
            return owed;
        } else {
            // Staked SD tokens
            require(stake.owner == msg.sender, "Not your token");
            uint256 owed = _getClaimableHonor(tokenId);
            if (_elligibleForBonus(tokenId)) {
                bonusClaimed[tokenId] = true;
            }
            if (unstake) {
                // Send back SamuraiDoge to owner
                samuraidoge.safeTransferFrom(
                    address(this),
                    msg.sender,
                    tokenId,
                    ""
                );
                _removeTokenFromOwnerEnumeration(stake.owner, stake.tokenId);
                delete war[tokenId];
                totalSamuraiDogeStaked -= 1;
                numTokensStaked[msg.sender] -= 1;
            } else {
                // Reset stake
                war[tokenId] = Stake({
                    owner: msg.sender,
                    tokenId: uint16(tokenId),
                    value: uint80(block.timestamp)
                });
            }
            emit HONORClaimed(tokenId, owed, unstake);
            return owed;
        }
    }

    /** GET CLAIMABLE AMOUNT */

    /**
     * Calculate total claimable $HONOR earnings from staked SamuraiDoges
     * @param tokenIds the IDs of the tokens to claim earnings from
     */
    function getClaimableHonorForMany(uint16[] calldata tokenIds)
        external
        view
        returns (uint256)
    {
        uint256 owed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            owed += _getClaimableHonor(tokenIds[i]);
        }
        return owed;
    }

    /**
     * Check if a SamuraiDoge token is elligible for bonus
     * @param tokenId the ID of the token to check for elligibility
     */
    function _elligibleForBonus(uint256 tokenId) internal view returns (bool) {
        return tokenId < tokensElligibleForBonus && !bonusClaimed[tokenId];
    }

    /**
     * Calculate claimable $HONOR earnings from a single staked SamuraiDoge
     * @param tokenId the ID of the token to claim earnings from
     */
    function _getClaimableHonor(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        uint256 owed = 0;
        if (tokenId < tokensElligibleForBonus && !bonusClaimed[tokenId]) {
            owed += bonusAmount;
        }
        Stake memory stake = war[tokenId];
        if (stake.value == 0) {} else if (
            block.timestamp < lastClaimTimestamp
        ) {
            owed +=
                ((block.timestamp - stake.value) * DAILY_HONOR_RATE) /
                1 days;
        } else if (stake.value > lastClaimTimestamp) {
            // $HONOR production stopped already
        } else {
            owed =
                ((lastClaimTimestamp - stake.value) * DAILY_HONOR_RATE) /
                1 days; // stop earning additional $HONOR after lastClaimTimeStamp
        }
        return owed;
    }

    /** ENUMERABLE */

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {numTokensStaked} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256)
    {
        require(index < numTokensStaked[owner], "Owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param owner address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address owner, uint256 tokenId)
        private
    {
        uint256 length = numTokensStaked[owner];
        _ownedTokens[owner][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures.
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param owner address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address owner, uint256 tokenId)
        private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = numTokensStaked[owner] - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[owner][lastTokenIndex];

            _ownedTokens[owner][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[owner][lastTokenIndex];
    }

    /** UTILS */

    /**
     * @dev Returns the owner address of a staked SamuraiDoge token
     * @param tokenId the ID of the token to check for owner
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        Stake memory stake = war[tokenId];
        return stake.owner;
    }

    /**
     * @dev Returns whether a SamuraiDoge token is staked
     * @param tokenId the ID of the token to check for staking
     */
    function isStaked(uint256 tokenId) public view returns (bool) {
        Stake memory stake = war[tokenId];
        return stake.owner != address(0);
    }

    /** ADMIN */

    /**
     * enables owner to pause / unpause staking
     */
    function setStakingStatus(bool _status) external onlyOwner {
        stakeIsActive = _status;
    }

    /**
     * allows owner to unstake tokens from the War, return the tokens to the tokens' owner, and claim $HON earnings
     * @param tokenIds the IDs of the tokens to claim earnings from
     * @param tokenOwner the address of the SamuraiDoge tokens owner
     */
    function rescueManyFromWar(uint16[] calldata tokenIds, address tokenOwner)
        external
        onlyOwner
    {
        uint256 owed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            owed += _rescueFromWar(tokenIds[i], tokenOwner);
        }
        if (owed == 0) return;
        honor.stakingMint(tokenOwner, owed);
    }

    /**
     * unstake a single SamuraiDoge from War and claim $HON earnings
     * @param tokenId the ID of the SamuraiDoge to rescue
     * @param tokenOwner the address of the SamuraiDoge token owner
     * @return owed - the amount of $HONOR earned
     */
    function _rescueFromWar(uint256 tokenId, address tokenOwner)
        internal
        returns (uint256)
    {
        Stake memory stake = war[tokenId];
        require(stake.owner == tokenOwner, "Not your token");
        uint256 owed = _getClaimableHonor(tokenId);
        if (_elligibleForBonus(tokenId)) {
            bonusClaimed[tokenId] = true;
        }
        // Send back SamuraiDoge to owner
        samuraidoge.safeTransferFrom(address(this), tokenOwner, tokenId, "");
        _removeTokenFromOwnerEnumeration(stake.owner, stake.tokenId);
        delete war[tokenId];
        totalSamuraiDogeStaked -= 1;
        numTokensStaked[tokenOwner] -= 1;
        emit HONORClaimed(tokenId, owed, true);
        return owed;
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send tokens to War directly");
        return IERC721Receiver.onERC721Received.selector;
    }
}