// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

contract PixelatedStakingV2 is
    Initializable,
    OwnableUpgradeable,
    IERC721ReceiverUpgradeable,
    UUPSUpgradeable
{
    uint256 public stakedTotal;
    uint256 public stakingStartTime;
    IERC721Upgradeable public nft;
    address[] public claimerAdresses;

    struct Staker {
        uint256[] tokenIds;
        mapping(uint256 => uint256) tokenStakingTime;
        uint256 balance;
        uint256 rewardsReleased;
    }
    /// @notice mapping of a staker to its wallet

    mapping(address => Staker) public stakers;

    /// @notice Mapping from token ID to owner address
    mapping(uint256 => address) public tokenOwner;

    function initialize(address _nft) external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        nft = IERC721Upgradeable(_nft);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    // add claimer address
    function addClaimer(address _claimer) public onlyOwner {
        claimerAdresses.push(_claimer);
    }

    bool public tokensClaimable;
    bool public initialized;

    /// @notice event emitted when a user has staked a nft

    event Staked(address owner, uint256 amount);

    /// @notice event emitted when a user has unstaked a nft
    event Unstaked(address owner, uint256 amount);

    function initStaking() public onlyOwner {
        //needs access control
        require(!initialized, "Already initialised");
        stakingStartTime = block.timestamp;
        initialized = true;
    }

    function getStakedTokens(address _user)
        public
        view
        returns (uint256[] memory _tokenIds)
    {
        return stakers[_user].tokenIds;
    }

    function _stake(address _user, uint256 _tokenId) internal {
        require(initialized, "Staking System: the staking has not started");
        require(
            nft.ownerOf(_tokenId) == _user,
            "user must be the owner of the token"
        );
        Staker storage staker = stakers[_user];

        staker.tokenIds.push(_tokenId);
        staker.tokenStakingTime[_tokenId] = block.timestamp;
        tokenOwner[_tokenId] = _user;
        nft.safeTransferFrom(_user, address(this), _tokenId);

        emit Staked(_user, _tokenId);
        stakedTotal++;
    }

    function stake(uint256 tokenId) public {
        _stake(msg.sender, tokenId);
    }

    function stakeBatch(uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _stake(msg.sender, _tokenIds[i]);
        }
    }

    function unstake(uint256 _tokenId) public {
        _unstake(msg.sender, _tokenId);
    }

    function unstakeBatch(uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenOwner[tokenIds[i]] == msg.sender) {
                _unstake(msg.sender, tokenIds[i]);
            }
        }
    }

    function _unstake(address _user, uint256 _tokenId) internal {
        require(
            tokenOwner[_tokenId] == _user,
            "user must be the owner of the staked nft"
        );
        Staker storage staker = stakers[_user];

        staker.tokenStakingTime[_tokenId] = 0;

        // remove token from staker tokenIds array
        for (uint256 i = 0; i < staker.tokenIds.length; i++) {
            if (staker.tokenIds[i] == _tokenId) {
                staker.tokenIds[i] = staker.tokenIds[
                    staker.tokenIds.length - 1
                ];
                if (staker.tokenIds.length > 0) {
                    staker.tokenIds.pop();
                }
                break;
            }
        }

        // remove token from tokenOwner mapping
        tokenOwner[_tokenId] = address(0);

        nft.safeTransferFrom(address(this), _user, _tokenId);

        emit Unstaked(_user, _tokenId);
        stakedTotal--;
    }

    // change owner of nft
    function changeOwner(uint256 _tokenId, address _newOwner) public {
        require(
            tokenOwner[_tokenId] == msg.sender,
            "user must be the owner of the staked nft"
        );
        // remove from staker
        Staker storage staker = stakers[msg.sender];
        uint256 stakedTime = staker.tokenStakingTime[_tokenId];
        staker.tokenStakingTime[_tokenId] = 0;

        staker.tokenStakingTime[_tokenId] = 0;

        // remove token from staker tokenIds array
        for (uint256 i = 0; i < staker.tokenIds.length; i++) {
            if (staker.tokenIds[i] == _tokenId) {
                staker.tokenIds[i] = staker.tokenIds[
                    staker.tokenIds.length - 1
                ];

                if (staker.tokenIds.length > 0) {
                    staker.tokenIds.pop();
                }
                break;
            }
        }

        // add to new owner and set stake period to that of current time
        Staker storage newOwner = stakers[_newOwner];
        newOwner.tokenIds.push(_tokenId);
        newOwner.tokenStakingTime[_tokenId] = stakedTime;
        tokenOwner[_tokenId] = _newOwner;
    }

    function checkTokenStakedPeriod(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return stakers[tokenOwner[_tokenId]].tokenStakingTime[_tokenId];
    }

    function checkTokenStakedPeriodForUser(uint256 _tokenId, address user_)
        public
        view
        returns (uint256)
    {
        require(
            tokenOwner[_tokenId] == user_,
            "user must be the owner of the staked nft"
        );
        return stakers[tokenOwner[_tokenId]].tokenStakingTime[_tokenId];
    }

    // balace of user
    function balanceOf(address _user) public view returns (uint256) {
        return stakers[_user].tokenIds.length;
    }

    function getTokensStakedForMoreThanAWeek(address user_)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokenIds = stakers[user_].tokenIds;
        uint256[] memory tokenIdsStakedForMoreThanAWeek = new uint256[](
            tokenIds.length
        );
        uint256 count = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (
                stakers[user_].tokenStakingTime[tokenIds[i]] + 7 days <
                block.timestamp
            ) {
                tokenIdsStakedForMoreThanAWeek[count] = tokenIds[i];
                count++;
            }
        }
        // remove empty elements from array
        uint256[] memory tokenIdsStakedForMoreThanAWeek_ = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            tokenIdsStakedForMoreThanAWeek_[i] = tokenIdsStakedForMoreThanAWeek[
                i
            ];
        }
        return tokenIdsStakedForMoreThanAWeek_;
    }
}