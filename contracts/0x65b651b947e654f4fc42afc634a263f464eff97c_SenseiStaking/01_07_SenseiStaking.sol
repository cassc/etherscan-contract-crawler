// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//Openzepellin imports
import "openzeppelin/contracts/token/ERC721/IERC721.sol";
import "openzeppelin/contracts/access/Ownable.sol";
import "openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract SenseiStaking is Ownable, ERC721Holder {
    IERC721 public senseiNFT;

    uint256 public stakedTotal;

    struct StakedToken {
        address owner;
        uint256 lockDownExpiration;
    }

    constructor(IERC721 _senseiNFT) {
        senseiNFT = _senseiNFT;
    }

    /// @notice mapping of a stakedToken struct to tokenId
    mapping(uint256 => StakedToken) internal stakedToken;

    /// @notice mapping of address to tokens staked
    mapping(address => uint256[]) public staker;

    /// @notice boolean to activate staking
    bool enabled;

    /// @notice event emitted when a user has staked a Sensei Pass

    event BatchStaked(address owner, uint256[] tokenIds);

    /// @notice event emitted when a user has unstaked Sensei Pass
    event BatchUnstaked(address owner, uint256[] tokenIds);

    /// @notice event emitted when admin changes lockdown Expiration for community
    event LockDownExpirationChanged(
        address user,
        uint256 tokenId,
        uint256 lockdownExpiration
    );

    // Modify name of init staking to Activate Staking
    function enableStaking() public onlyOwner {
        //needs access control
        require(!enabled, "Already initialised");
        enabled = true;
    }

    function stopStaking() public onlyOwner {
        require(enabled, "Already stopped");
        enabled = false;
    }

    function stakedTokens(address _user)
        public
        view
        returns (uint256[] memory tokenIds)
    {
        return staker[_user];
    }

    function tokenInfo(uint256 _tokenId)
        public
        view
        returns (StakedToken memory info)
    {
        return stakedToken[_tokenId];
    }

    function stakingEnabled() public view returns (bool) {
        return enabled;
    }

    function stakeBatch(uint256[] memory tokenIds, uint256 _lockdownExpiration)
        public
    {
        require(tokenIds.length > 0, "You are trying to stake 0 tokens");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stake(msg.sender, tokenIds[i], _lockdownExpiration);
        }
        emit BatchStaked(msg.sender, tokenIds);
    }

    function _stake(
        address _user,
        uint256 _tokenId,
        uint256 _lockdownExpiration
    ) internal {
        require(enabled, "Staking System: the staking has not started");
        require(
            _lockdownExpiration > block.timestamp,
            "Expiration time is in the past must be in the future"
        );
        require(
            senseiNFT.ownerOf(_tokenId) == _user,
            "user must be the owner of the token"
        );
        require(
            senseiNFT.isApprovedForAll(_user, address(this)),
            "user needs to set approval first"
        );

        stakedToken[_tokenId].owner = _user;
        stakedToken[_tokenId].lockDownExpiration = _lockdownExpiration;
        staker[_user].push(_tokenId);

        senseiNFT.safeTransferFrom(_user, address(this), _tokenId);

        stakedTotal++;
    }

    function unstakeBatch(uint256[] memory tokenIds) public {
        require(tokenIds.length > 0, "You are trying to unstake 0 tokens");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _unstake(msg.sender, tokenIds[i]);
        }
        emit BatchUnstaked(msg.sender, tokenIds);
    }

    function _unstake(address _user, uint256 _tokenId) internal {
        require(
            enabled,
            "Staking System: the staking system is not enabled, cannot unstake tokens."
        );
        require(
            block.timestamp >= stakedToken[_tokenId].lockDownExpiration,
            "Your token is currently locked down"
        );
        require(
            stakedToken[_tokenId].owner == _user,
            "You are not the owner if this token or token is not staked"
        );

        delete stakedToken[_tokenId].owner;
        delete stakedToken[_tokenId].lockDownExpiration;

        senseiNFT.safeTransferFrom(address(this), _user, _tokenId);

        for (uint256 i = 0; i < staker[_user].length; i++) {
            if (staker[_user][i] == _tokenId) {
                staker[_user][i] = staker[_user][staker[_user].length - 1];
                staker[_user].pop();
            }
        }
        stakedTotal--;
    }

    function updateLockDown(
        uint256 lockdownExpiration,
        uint256[] memory tokenIds
    ) public onlyOwner {
        require(tokenIds.length > 0, "You are trying to modify 0 tokens");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _updateLockDown(lockdownExpiration, tokenIds[i]);
        }
    }

    function _updateLockDown(uint256 _lockdownExpiration, uint256 _tokenId)
        internal
    {
        require(
            _lockdownExpiration > block.timestamp,
            "You are trying to update in the past"
        );
        require(enabled, "Staking System: the staking has not started");

        stakedToken[_tokenId].lockDownExpiration = _lockdownExpiration;
        emit LockDownExpirationChanged(
            stakedToken[_tokenId].owner,
            _tokenId,
            _lockdownExpiration
        );
    }
}