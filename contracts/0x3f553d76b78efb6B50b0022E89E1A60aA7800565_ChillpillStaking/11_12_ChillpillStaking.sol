// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.15;

/*
  /$$$$$$ /$$   /$$/$$$$$$/$$      /$$      /$$$$$$$ /$$$$$$/$$      /$$      
 /$$__  $| $$  | $|_  $$_| $$     | $$     | $$__  $|_  $$_| $$     | $$      
| $$  \__| $$  | $$ | $$ | $$     | $$     | $$  \ $$ | $$ | $$     | $$      
| $$     | $$$$$$$$ | $$ | $$     | $$     | $$$$$$$/ | $$ | $$     | $$      
| $$     | $$__  $$ | $$ | $$     | $$     | $$____/  | $$ | $$     | $$      
| $$    $| $$  | $$ | $$ | $$     | $$     | $$       | $$ | $$     | $$      
|  $$$$$$| $$  | $$/$$$$$| $$$$$$$| $$$$$$$| $$      /$$$$$| $$$$$$$| $$$$$$$$
 \______/|__/  |__|______|________|________|__/     |______|________|________/                                                                                                                                                                                                                               
*/

/// ============ Imports ============

import "./ChillToken.sol";
import "./PartyPillStaking.sol";
import "openzeppelin-contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";

contract ChillpillStaking is
    PartyPillStaking,
    ReentrancyGuard,
    IERC721Receiver
{
    /// @notice total count of staked chillpill nfts
    uint256 public totalStaked;
    /// @notice $CHILL Token
    ChillToken public immutable chillToken;
    /// @notice max supply of $CHILL token
    uint256 public immutable maxSupply = 8080000000000000000000000;
    /// @notice returns amount of $CHILL earned by staking 1 pill for 1 day
    uint256 public dailyStakeRate;
    /// @notice number of $CHILL halvenings executed
    uint8 public halveningCount;

    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint24 tokenId;
        uint48 timestamp;
        address owner;
    }

    /// @notice event fired when NFT is staked
    event NFTStaked(address owner, uint256 tokenId, uint256 value);
    /// @notice event fired when NFT is unstaked
    event NFTUnstaked(address owner, uint256 tokenId, uint256 value);
    /// @notice event fired when $CHILL is claimed
    event Claimed(address owner, uint256 amount);

    /// @notice address of ChillRx ERC721 contract
    address public nftAddress;
    /// @notice amount of $CHILL claimed
    uint256 public totalClaimed;
    /// @notice total amount of ChillRx + PartyPills
    uint256 public totalNftSupply;

    // maps tokenId to stake
    mapping(uint256 => Stake) public vault;

    constructor(address _nft, uint256 _totalNftSupply) {
        chillToken = new ChillToken(address(this));
        nftAddress = _nft;
        totalNftSupply = _totalNftSupply;
        dailyStakeRate = 8080000000000000000;
    }

    /// @notice transfer pill to staking contract
    function _stakeTransfer(IERC721 _nft, uint256 _tokenId) private {
        require(_nft.ownerOf(_tokenId) == msg.sender, "not your token");
        require(
            _nft.isApprovedForAll(msg.sender, address(this)) ||
                _nft.getApproved(_tokenId) == address(this),
            "not approved for transfer"
        );
        _nft.safeTransferFrom(msg.sender, address(this), _tokenId);
    }

    /// @notice transfer pill from staking contract to owner
    function _unstakeTransfer(uint256 _tokenId, address _account) private {
        if (_tokenId > partyPillStartIndex) {
            IERC721(partyPillAddress).safeTransferFrom(
                address(this),
                _account,
                _tokenId - partyPillStartIndex
            );
        } else {
            IERC721(nftAddress).safeTransferFrom(
                address(this),
                _account,
                _tokenId
            );
        }
    }

    /// @notice stake you pills
    function stake(uint256[] calldata tokenIds) external nonReentrant {
        uint256 tokenId;
        totalStaked += tokenIds.length;
        IERC721 _nft = IERC721(nftAddress);
        IERC721 _partyPill = IERC721(partyPillAddress);
        for (uint256 i; i != tokenIds.length; i++) {
            tokenId = tokenIds[i];
            require(vault[tokenId].owner == address(0), "already staked");
            if (tokenIds[i] > partyPillStartIndex) {
                uint256 _tokenId = tokenId - partyPillStartIndex;
                _stakeTransfer(_partyPill, _tokenId);
            } else {
                _stakeTransfer(_nft, tokenIds[i]);
            }

            emit NFTStaked(msg.sender, tokenId, block.timestamp);

            vault[tokenId] = Stake({
                owner: msg.sender,
                tokenId: uint24(tokenId),
                timestamp: uint48(block.timestamp)
            });
        }
    }

    /// @notice cut distribution of $CHILL in half
    function halvening() internal {
        if (halveningCount < 3) {
            dailyStakeRate = dailyStakeRate / 2;
            ++halveningCount;
        }
    }

    /// @notice unstake pills
    function _unstakeMany(address account, uint256[] calldata tokenIds)
        internal
    {
        uint256 tokenId;
        totalStaked -= tokenIds.length;
        for (uint256 i; i != tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory staked = vault[tokenId];
            require(staked.owner == msg.sender, "not an owner");

            delete vault[tokenId];
            emit NFTUnstaked(account, tokenId, block.timestamp);
            _unstakeTransfer(tokenId, account);
        }
    }

    /// @notice claim $CHILL for self
    function claim(uint256[] calldata tokenIds) external nonReentrant {
        _claim(msg.sender, tokenIds, false);
    }

    /// @notice claim $CHILL for target address
    function claimForAddress(address account, uint256[] calldata tokenIds)
        external
        nonReentrant
    {
        _claim(account, tokenIds, false);
    }

    /// @notice claim $CHILL and unstake Pill
    function unstake(uint256[] calldata tokenIds) external nonReentrant {
        _claim(msg.sender, tokenIds, true);
    }

    /// @notice claim $CHILL and unstake Pill (optional)
    function _claim(
        address account,
        uint256[] calldata tokenIds,
        bool _unstake
    ) internal {
        uint256 tokenId;
        uint256 earned = 0;

        for (uint256 i; i != tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory staked = vault[tokenId];
            require(staked.owner == account, "not an owner");
            uint256 stakedAt = staked.timestamp;
            uint256 currentTime = block.timestamp;

            if (tokenId > partyPillStartIndex) {
                earned += calculateEarn(stakedAt) * partyPillMultiplier;
            } else {
                earned += calculateEarn(stakedAt);
            }

            vault[tokenId] = Stake({
                owner: account,
                tokenId: uint24(tokenId),
                timestamp: uint48(currentTime)
            });
        }
        if (earned > 0) {
            if (earned + chillToken.totalSupply() > maxSupply) {
                earned = maxSupply - chillToken.totalSupply();
            }
            chillToken.mint(account, earned);
            totalClaimed += earned;
        }
        if (chillToken.totalSupply() > maxSupply / (2 * (halveningCount + 1))) {
            halvening();
        }
        if (_unstake) {
            _unstakeMany(account, tokenIds);
        }
        emit Claimed(account, earned);
    }

    /// @notice returns amount of $CHILL earned by staking 1 pill for 1 second
    function secondStakeRate() public view returns (uint256) {
        return dailyStakeRate / 1 days + (dailyStakeRate % 1 days);
    }

    /// @notice calculate amount of unclaimed $CHILL
    function calculateEarn(uint256 stakedAt) internal view returns (uint256) {
        uint256 stakeDuration = block.timestamp - stakedAt;
        uint256 payout = stakeDuration * secondStakeRate();
        return payout;
    }

    /// @notice amount of unclaimed $CHILL
    function earningInfo(address account, uint256[] calldata tokenIds)
        external
        view
        returns (uint256)
    {
        uint256 tokenId;
        uint256 earned = 0;

        for (uint256 i; i != tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory staked = vault[tokenId];
            require(staked.owner == account, "not an owner");
            uint256 stakedAt = staked.timestamp;
            if (tokenId > partyPillStartIndex) {
                earned += calculateEarn(stakedAt) * partyPillMultiplier;
            } else {
                earned += calculateEarn(stakedAt);
            }
        }
        return earned;
    }

    /// @notice get number of tokens staked in account
    /// @dev DecentSDK compatible
    function balanceOf(address account) external view returns (uint256) {
        uint256 balance = 0;

        for (uint256 i = 0; i <= totalNftSupply + 1; i++) {
            if (vault[i].owner == account) {
                balance++;
            }
        }
        return balance;
    }

    /// @notice return nft tokens staked of owner
    function tokensOfOwner(address account)
        external
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256[] memory tmp = new uint256[](totalNftSupply);

        uint256 index = 0;
        for (uint256 tokenId = 0; tokenId <= totalNftSupply + 1; tokenId++) {
            if (vault[tokenId].owner == account) {
                tmp[index] = vault[tokenId].tokenId;
                index++;
            }
        }

        uint256[] memory tokens = new uint256[](index);
        for (uint256 i; i != index; i++) {
            tokens[i] = tmp[i];
        }

        return tokens;
    }

    /// @notice handles reciept of ERC721 tokens
    function onERC721Received(
        address,
        address,
        // address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        // require(from == address(0x0), "Cannot send nfts to Vault directly");
        return IERC721Receiver.onERC721Received.selector;
    }

    /// @notice erc20Address for $CHILL token
    /// @dev DecentSDK compatibility
    function erc20Address() public view returns (address) {
        return address(chillToken);
    }

    /// @notice updates party pill information
    function updatePartyPill(
        address _partyPillAddress,
        uint8 _stakeMultiplier,
        uint256 _count
    ) public onlyOwner {
        totalNftSupply = totalNftSupply - partyPillCount + _count;
        _updatePartyPill(_partyPillAddress, _stakeMultiplier, _count);
    }

    // fallback
    fallback() external payable {}

    // receive eth
    receive() external payable {}
}