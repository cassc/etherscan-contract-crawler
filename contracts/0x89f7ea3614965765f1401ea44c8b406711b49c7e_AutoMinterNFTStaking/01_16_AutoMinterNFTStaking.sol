// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

pragma solidity >=0.7.0 <0.9.0;

contract AutoMinterNFTStaking is Initializable, OwnableUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private erc20Token;
    address private erc721Token;
    uint256 private totalERC20Withdrawn;
    uint256 private totalStaked;
    mapping(address => uint256) stakerStakeCount;
    mapping(uint256 => StakedInfo) private tokenStakeInfo;

    struct StakedInfo {
        address stakeHolder;
        uint256 startingAmount; // the total ERC20 withdrawn + the current balance
    }

    event StakeAdded(
        address indexed stakeholder,
        uint256 token,
        uint256 timestamp
    );

    event StakeRemoved(
        address indexed stakeholder,
        uint256 token,
        uint256 timestamp
    );

    constructor() {}

    function initialize(address erc20Token_, address erc721Token_) public initializer {
        erc20Token = erc20Token_;
        erc721Token = erc721Token_;
        __Ownable_init_unchained();
    }

    /**
     * @notice stake NFT in the contract
     * @dev stake NFT in the contract
     * @param tokenId the NFT token ID being staked
     */
    function createStake(uint256 tokenId) public
    {
        // increment the total number of passes
        uint256 erc20Balance = IERC20Upgradeable(erc20Token).balanceOf(address(this));
        uint256 startingAmount = totalERC20Withdrawn + erc20Balance;

        // set the stake info based on current number of staked passes
        tokenStakeInfo[tokenId] = StakedInfo(msg.sender, startingAmount);

        // transfer the token to self
        IERC721Upgradeable(erc721Token).transferFrom(msg.sender, address(this), tokenId);

        // increment staked count
        totalStaked += 1;
        stakerStakeCount[msg.sender] += 1;

        // fire the stake event
        emit StakeAdded(msg.sender, tokenId, block.timestamp);
    }

    /**
     * @notice remove NFT from the contract
     * @dev remove NFT from the contract
     * @param tokenId the nft to withdraw from the contract
     */
    function removeStake(uint256 tokenId) public {
        require(tokenStakeInfo[tokenId].stakeHolder == msg.sender, "NFT must be staked by user");

        // get the total number of erc20 tokens earned (current balance + withdrawn amount - starting stake)
        uint256 erc20Balance = IERC20Upgradeable(erc20Token).balanceOf(address(this));
        uint256 startingAmount = tokenStakeInfo[tokenId].startingAmount;
        uint256 newTokens = erc20Balance + totalERC20Withdrawn - startingAmount;
        uint256 earnedTokens = newTokens/totalStaked;

        // transfer the number of tokens earned
        require(
            IERC20Upgradeable(erc20Token).transfer(msg.sender, earnedTokens),
            "ERC20 transfer failed"
        );

        // transfer the NFT to the user
        IERC721Upgradeable(erc721Token).transferFrom(address(this), msg.sender, tokenId);

        // reset the starting stakerHolderStakeInfo
        delete tokenStakeInfo[tokenId];
        totalERC20Withdrawn += earnedTokens;

        // decrement staked count
        totalStaked -= 1;
        stakerStakeCount[msg.sender] += 1;

        emit StakeRemoved(
            msg.sender,
            tokenId,
            block.timestamp
        );
    }
    
    /**
     * @notice get the number of NFTs staked by the stakeholder
     * @dev get the number of NFTs staked by the stakeholder
     * @param stakeholder the address staking the NFTs
     */
    function tokensStaked(address stakeholder) public view returns (uint256) {
        return stakerStakeCount[stakeholder];
    }
}