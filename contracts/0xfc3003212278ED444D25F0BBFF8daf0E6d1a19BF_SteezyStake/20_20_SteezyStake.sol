// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract SteezyStake is Ownable, ReentrancyGuard, Pausable, IERC721Receiver {
    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint24 tokenId;
        uint48 timestamp;
        address owner;
    }
    uint256 public totalStaked;
    uint256 public lockPeriod = 30; // 30 days until claimable
    uint256 private rewardAmount = 7 ether; // 7 tokens per day

    // Steezy NFT Contract address
    ERC721Enumerable nft;
    // Smoke Token address as reward token
    IERC20 token;

    address private sessionWallet;


    // maps' tokenId to stake
    mapping(uint256 => Stake) public vault;

    mapping(address => uint256[]) private userTokensStaked;
    // staked token ids to their userstake indexes
    mapping(uint256 => uint256) private tokenIdToIndex;

    event NFTStaked(address owner, uint256 tokenId, uint256 value);
    event NFTUnstaked(address owner, uint256 tokenId, uint256 value);
    event Claimed(address owner, uint256 amount);

    constructor(address nftAddress, address rewardTokenAddress, address _sessions) {
        nft = ERC721Enumerable(nftAddress);
        token = IERC20(rewardTokenAddress);
        sessionWallet = _sessions;
    }

    receive() external payable {}

    fallback() external payable {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function stake(uint256[] calldata tokenIds) external nonReentrant whenNotPaused returns (bool) {
        uint256 tokenId;
        totalStaked += tokenIds.length;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            require(nft.ownerOf(tokenId) == _msgSender(), "not your token");
            require(vault[tokenId].tokenId == 0, "already staked");

            nft.transferFrom(_msgSender(), address(this), tokenId);
            emit NFTStaked(_msgSender(), tokenId, block.timestamp);

            vault[tokenId] = Stake({
                owner: _msgSender(),
                tokenId: uint24(tokenId),
                timestamp: uint48(block.timestamp)
            });
            userTokensStaked[_msgSender()].push(tokenId);
            tokenIdToIndex[tokenId] = userTokensStaked[_msgSender()].length - 1;
        }

        return true;
    }

    function claim(uint256[] calldata tokenIds) external nonReentrant whenNotPaused returns (bool) {
        return _claim(_msgSender(), tokenIds, false);
    }

    function claimForAddress(address account, uint256[] calldata tokenIds)
        external
        nonReentrant
        whenNotPaused
        returns (bool)
    {
        return _claim(account, tokenIds, false);
    }

    function unstake(uint256[] calldata tokenIds)
        external
        nonReentrant
        whenNotPaused
        returns (bool)
    {
        return _claim(_msgSender(), tokenIds, true);
    }

    // internal
    function _claim(
        address account,
        uint256[] calldata tokenIds,
        bool _unstake
    ) internal returns (bool) {
        uint256 tokenId;
        uint256 lapsedDays;
        uint256 unclaimableReward = 0;
        uint256 claimableReward = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory staked = vault[tokenId];
            require(staked.owner == account, "not an owner");
            lapsedDays = (block.timestamp - staked.timestamp) / 86400; //1 day == 24 hours = 86400 seconds
            // Can't claim until lockPeriod(30) days
            if (lapsedDays > lockPeriod) {
                vault[tokenId] = Stake({
                    owner: account,
                    tokenId: uint24(tokenId),
                    timestamp: uint48(block.timestamp)
                });
                claimableReward += rewardAmount * lapsedDays;
            } else {
                unclaimableReward += rewardAmount * lapsedDays; // 1 ether == 1e18
            }
        }

        if (claimableReward > 0) {
            require(
                token.balanceOf(address(this)) > claimableReward,
                "Insuficient contract tokens for claim"
            );
            bool result = token.transfer(account, claimableReward);
            require(result, "Claim unsuccessful, insufficient amount");
            emit Claimed(account, claimableReward);
        }

        //penalty on early unstake 100% unclaimed rewards
        if (_unstake) {
            //to session 33.4% Of Unclaimed Rewards & keep 66.6% Of Unclaimed Rewards in the pool
            if (unclaimableReward > 0) {
                uint256 toBurnAmount = (unclaimableReward * 334) / (1000); // divide by 1000 to cover .4% as well
                require(
                    token.balanceOf(address(this)) > toBurnAmount,
                    "Insuficient contract tokens for burn"
                );
                token.transfer(sessionWallet, toBurnAmount);
            }

            _unstakeMany(account, tokenIds);
        }
        return true;
    }

    function _unstakeMany(address account, uint256[] memory tokenIds) internal {
        uint256 tokenId;
        totalStaked -= tokenIds.length;
        uint256[] storage tokens = userTokensStaked[account];
        

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory staked = vault[tokenId];
            require(staked.owner == _msgSender(), "not an owner");

            delete vault[tokenId];
            //get tokenId at last ind
            uint256 lastToken = tokens[
                tokens.length - 1
            ];
            // shift last token item to current tokens ind
            tokens[tokenIdToIndex[tokenId]] = lastToken;
            //reset TokenIdToIndex as well for the lastToken: 
            tokenIdToIndex[lastToken] = tokenIdToIndex[tokenId];
            // now just pop the last element (will also reduce length)
            tokens.pop();

            emit NFTUnstaked(account, tokenId, block.timestamp);
            nft.transferFrom(address(this), account, tokenId);
        }
    }


    /**
     * Get total rewards, unclaimable and claimable by the user
     */
    function earningInfo(address account, uint256[] calldata tokenIds)
        external
        view
        returns (uint256, uint256)
    {
        uint256 tokenId;
        uint256 lapsedDays;
        uint256 unclaimableReward = 0;
        uint256 claimableReward = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory staked = vault[tokenId];
            require(staked.owner == account, "not an owner");
            lapsedDays = (block.timestamp - staked.timestamp) / 86400; //1 day == 24 hours = 86400 seconds
            // Can't claim until lockPeriod(30) days
            if (lapsedDays > lockPeriod) {
                claimableReward += rewardAmount * lapsedDays;
            } else {
                unclaimableReward += rewardAmount * lapsedDays; // 1 ether == 1e18
            }
        }

        return (unclaimableReward, claimableReward);
    }

    // users' staked NFT count
    function balanceOf(address account) public view returns (uint256) {
        return userTokensStaked[account].length;
    }

    // should return the tokenIds stored by the user
    function tokensOfOwner(address account) public view returns (uint256[] memory ownerTokens) {
        return userTokensStaked[account];
    }

    /**
     * @param amount should be in like 7 ether/7 * 10**18
     */
    function setRewardAmount(uint256 amount) public onlyOwner {
        rewardAmount = amount * 1 ether;
    }

    function setSessionsWallet(address _newSessions) public onlyOwner {
        sessionWallet = _newSessions;
    }

    /**
     * unstake all account tokens in case of emergency paused
     */
    function emergencyUnstake(address account) public whenPaused {
        _unstakeMany(account, tokensOfOwner(account));
    }

    function withdrawContractRewardTokens() public onlyOwner whenPaused returns (bool) {
        bool success = token.transfer(_msgSender(), token.balanceOf(address(this)));
        require(success, "Token Transfer failed.");
        return true;
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send nfts to Vault directly");
        return IERC721Receiver.onERC721Received.selector;
    }
}