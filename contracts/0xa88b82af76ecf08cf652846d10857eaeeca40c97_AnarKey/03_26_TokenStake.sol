// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./../erc721x/contracts/ERC721X.sol";

abstract contract TokenStake is Ownable, ERC721X {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _tokenStakers;
    mapping(uint256 => address) private _stakedTokens;

    event TokenStaked(address indexed tokenStaker, uint256 tokenId);
    event TokenUnstaked(address indexed tokenStaker, uint256 tokenId);
    event TokenRecoverUnstaked(uint256 tokenId);
    event BatchUpdateTokenStaked(address indexed newTokenStaker, uint256[] tokenIds);

    event TokenStakerAdded(address indexed tokenStaker);
    event TokenStakerRemoved(address indexed tokenStaker);

    modifier tokenStakersOnly() {
        require(_tokenStakers.contains(_msgSender()), "TokenStake: Not staker");
        _;
    }

    modifier whenTokenNotStaked(uint256 tokenId) {
        require(_stakedTokens[tokenId] == address(0), "TokenStake: Token is staked");
        _;
    }

    modifier whenTokenStaked(uint256 tokenId) {
        require(_stakedTokens[tokenId] != address(0), "TokenStake: Token is not staked");
        _;
    }

    /**
     * @notice Returns `true` if token is staked and can't be transfered
     */
    function isTokenStaked(uint256 tokenId) public view returns (bool) {
        return _stakedTokens[tokenId] != address(0);
    }

    /**
     * @notice Returns the address of the staker for a specific `tokenId``
     * Returns 0x0 if token is not staked
     */
    function stakerForToken(uint256 tokenId) public view returns (address) {
        return _stakedTokens[tokenId];
    }

    /**
     * @notice Lock a token for staking
     * only callable by members of the `tokenStakers` list
     * The owner of the token must approve the staking contract prior to call this method
     */
    function stakeToken(uint256 tokenId) external tokenStakersOnly whenTokenNotStaked(tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "TokenStake: Staker not approved");
        _stakedTokens[tokenId] = _msgSender();
        emit TokenStaked(_msgSender(), tokenId);
    }

    /**
     * @notice Lock a token for staking
     * only callable by the staker
     */
    function unstakeToken(uint256 tokenId) external whenTokenStaked(tokenId) {
        require(_msgSender() == _stakedTokens[tokenId], "TokenStake: Token not stake by account");
        require(_msgSender() != address(0), "TokenStake: can't unstake from zero address");
        _stakedTokens[tokenId] = address(0);
        emit TokenUnstaked(_msgSender(), tokenId);
    }

    /**
     * @notice Recover a staked token
     * only callable by the owner
     */
    function recoverStakeToken(uint256 tokenId) external onlyOwner whenTokenStaked(tokenId) {
        _stakedTokens[tokenId] = address(0);
        emit TokenRecoverUnstaked(tokenId);
    }

    /**
     * @dev Change the token staker for a list of tokenIds
     * only callable by the owner
     * this is usefull if the staker contract must be updated
     * if `newStaker` is set to 0x0, tokens will be unstaked
     */
    function batchUpdateTokenStake(address newStaker, uint256[] calldata tokenIds) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_stakedTokens[tokenIds[i]] != address(0), "TokenStake: not restakeable");
            if (newStaker != address(0)) {
                require(_isApprovedOrOwner(newStaker, tokenIds[i]), "TokenStake: Staker not approved");
            }
            _stakedTokens[tokenIds[i]] = newStaker;
        }
        emit BatchUpdateTokenStaked(newStaker, tokenIds);
    }

    /**
     * @dev returns true if `account` is a member of the staker group
     */
    function isTokenStaker(address account) public view returns (bool) {
        return _tokenStakers.contains(account);
    }

    /**
     * @dev Add `tokenStaker` to the list of allowed stakers
     * only callable by the owner
     */
    function addTokenStaker(address tokenStaker) external onlyOwner {
        require(!_tokenStakers.contains(tokenStaker), "TokenStake: Already TokenStaker");
        _tokenStakers.add(tokenStaker);
        emit TokenStakerAdded(tokenStaker);
    }

    /**
     * @dev Remove `tokenStaker` from the list of allowed stakers
     * only callable by the owner
     */
    function removeTokenStaker(address tokenStaker) external onlyOwner {
        require(_tokenStakers.contains(tokenStaker), "TokenStake: Not TokenStaker");
        _tokenStakers.remove(tokenStaker);
        emit TokenStakerRemoved(tokenStaker);
    }
}