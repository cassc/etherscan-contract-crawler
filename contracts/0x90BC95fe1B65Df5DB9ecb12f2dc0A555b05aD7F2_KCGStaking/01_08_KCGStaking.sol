// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KCGStaking is Ownable, ReentrancyGuard {
    uint256 public constant DAY = 24 * 60 * 60;
    uint256 public constant FOURTY_FIVE_DAYS = 45 * DAY;
    uint256 public constant NINETY_DAYS = 90 * DAY;
    uint256 public constant ONE_HUNDREDS_EIGHTY_DAYS = 180 * DAY;

    address public KCGAddress = 0xA302F0d51A365B18e86c291056dC265a73F19419;
    bool public emergencyUnstakePaused = true;

    struct stakeRecord {
        address tokenOwner;
        uint256 tokenId;
        uint256 endingTimestamp;
    }

    mapping(uint256 => stakeRecord) public stakingRecords;

    mapping(address => uint256) public numOfTokenStaked;

    event Staked(address owner, uint256 amount, uint256 timeframe);

    event Unstaked(address owner, uint256 amount);

    event EmergencyUnstake(address indexed user, uint256 tokenId);

    constructor() {}

    // MODIFIER
    modifier checkArgsLength(
        uint256[] calldata tokenIds,
        uint256[] calldata timeframe
    ) {
        require(
            tokenIds.length == timeframe.length,
            "Token IDs and timeframes must have the same length."
        );
        _;
    }

    modifier checkStakingTimeframe(uint256[] calldata timeframe) {
        for (uint256 i = 0; i < timeframe.length; i++) {
            uint256 period = timeframe[i];
            require(
                period == FOURTY_FIVE_DAYS ||
                    period == NINETY_DAYS ||
                    period == ONE_HUNDREDS_EIGHTY_DAYS,
                "Invalid staking timeframes."
            );
        }
        _;
    }

    // STAKING
    function batchStake(
        uint256[] calldata tokenIds,
        uint256[] calldata timeframe
    )
        external
        checkStakingTimeframe(timeframe)
        checkArgsLength(tokenIds, timeframe)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stake(msg.sender, tokenIds[i], timeframe[i]);
        }
    }

    function _stake(
        address _user,
        uint256 _tokenId,
        uint256 _timeframe
    ) internal {
        require(
            IERC721Enumerable(KCGAddress).ownerOf(_tokenId) == msg.sender,
            "You must own the NFT."
        );
        uint256 endingTimestamp = block.timestamp + _timeframe;

        stakingRecords[_tokenId] = stakeRecord(
            _user,
            _tokenId,
            endingTimestamp
        );
        numOfTokenStaked[_user] = numOfTokenStaked[_user] + 1;
        IERC721Enumerable(KCGAddress).safeTransferFrom(
            _user,
            address(this),
            _tokenId
        );

        emit Staked(_user, _tokenId, _timeframe);
    }

    // RESTAKE
    function batchRestake(
        uint256[] calldata tokenIds,
        uint256[] calldata timeframe
    )
        external
        checkStakingTimeframe(timeframe)
        checkArgsLength(tokenIds, timeframe)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _restake(msg.sender, tokenIds[i], timeframe[i]);
        }
    }

    function _restake(
        address _user,
        uint256 _tokenId,
        uint256 _timeframe
    ) internal {
        require(
            block.timestamp >= stakingRecords[_tokenId].endingTimestamp,
            "NFT is locked."
        );
        require(
            stakingRecords[_tokenId].tokenOwner == msg.sender,
            "Token does not belong to you."
        );

        uint256 endingTimestamp = block.timestamp + _timeframe;
        stakingRecords[_tokenId].endingTimestamp = endingTimestamp;

        emit Staked(_user, _tokenId, _timeframe);
    }

    // UNSTAKE
    function batchUnstake(uint256[] calldata tokenIds) external nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _unstake(msg.sender, tokenIds[i]);
        }
    }

    function _unstake(address _user, uint256 _tokenId) internal {
        require(
            block.timestamp >= stakingRecords[_tokenId].endingTimestamp,
            "NFT is locked."
        );
        require(
            stakingRecords[_tokenId].tokenOwner == msg.sender,
            "Token does not belong to you."
        );

        delete stakingRecords[_tokenId];
        numOfTokenStaked[_user]--;
        IERC721Enumerable(KCGAddress).safeTransferFrom(
            address(this),
            _user,
            _tokenId
        );

        emit Unstaked(_user, _tokenId);
    }

    function getStakingRecords(address user)
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256[] memory tokenIds = new uint256[](numOfTokenStaked[user]);
        uint256[] memory expiries = new uint256[](numOfTokenStaked[user]);
        uint256 counter = 0;
        for (
            uint256 i = 0;
            i < IERC721Enumerable(KCGAddress).totalSupply();
            i++
        ) {
            if (stakingRecords[i].tokenOwner == user) {
                tokenIds[counter] = stakingRecords[i].tokenId;
                expiries[counter] = stakingRecords[i].endingTimestamp;
                counter++;
            }
        }
        return (tokenIds, expiries);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // MIGRATION ONLY.
    function setKCGNFTContract(address operator) public onlyOwner {
        KCGAddress = operator;
    }

    // EMERGENCY ONLY.
    function setEmergencyUnstakePaused(bool paused) public onlyOwner {
        emergencyUnstakePaused = paused;
    }

    function emergencyUnstake(uint256 tokenId) external nonReentrant {
        require(!emergencyUnstakePaused, "No emergency unstake.");
        require(
            stakingRecords[tokenId].tokenOwner == msg.sender,
            "Token does not belong to you."
        );
        delete stakingRecords[tokenId];
        numOfTokenStaked[msg.sender]--;
        IERC721Enumerable(KCGAddress).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );
        emit EmergencyUnstake(msg.sender, tokenId);
    }

    function emergencyUnstakeByOwner(uint256[] calldata tokenIds)
        external
        onlyOwner
        nonReentrant
    {
        require(!emergencyUnstakePaused, "No emergency unstake.");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            address user = stakingRecords[tokenId].tokenOwner;
            require(user != address(0x0), "Need owner exists.");
            delete stakingRecords[tokenId];
            numOfTokenStaked[user]--;
            IERC721Enumerable(KCGAddress).safeTransferFrom(
                address(this),
                user,
                tokenId
            );
            emit EmergencyUnstake(user, tokenId);
        }
    }
}