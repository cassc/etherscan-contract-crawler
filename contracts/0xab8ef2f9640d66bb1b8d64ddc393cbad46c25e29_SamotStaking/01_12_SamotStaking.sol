// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin-solidity/contracts/utils/structs/EnumerableSet.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/security/Pausable.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";

// ██╗    ██╗██╗  ██╗ ██████╗     ██╗███████╗    ▄▄███▄▄· █████╗ ███╗   ███╗ ██████╗ ████████╗    ██████╗
// ██║    ██║██║  ██║██╔═══██╗    ██║██╔════╝    ██╔════╝██╔══██╗████╗ ████║██╔═══██╗╚══██╔══╝    ╚════██╗
// ██║ █╗ ██║███████║██║   ██║    ██║███████╗    ███████╗███████║██╔████╔██║██║   ██║   ██║         ▄███╔╝
// ██║███╗██║██╔══██║██║   ██║    ██║╚════██║    ╚════██║██╔══██║██║╚██╔╝██║██║   ██║   ██║         ▀▀══╝
// ╚███╔███╔╝██║  ██║╚██████╔╝    ██║███████║    ███████║██║  ██║██║ ╚═╝ ██║╚██████╔╝   ██║         ██╗
//  ╚══╝╚══╝ ╚═╝  ╚═╝ ╚═════╝     ╚═╝╚══════╝    ╚═▀▀▀══╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝    ╚═╝         ╚═╝

/**
 * @title Samot Staking
 * SamotStaking - a contract for the Samot NFT Staking
 */

abstract contract SamotToken {
    function claim(address _claimer, uint256 _reward) external {}

    function burn(address _from, uint256 _amount) external {}
}

abstract contract StakingV1 {
    function stakeOf(address _stakeholder)
        public
        view
        virtual
        returns (uint256[] memory);

    function stakeTimestampsOf(address _stakeholder)
        public
        view
        virtual
        returns (uint256[] memory);
}

abstract contract SamotNFT {
    function ownerOf(uint256 tokenId) public view virtual returns (address);

    function balanceOf(address owner)
        public
        view
        virtual
        returns (uint256 balance);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual;

    function isApprovedForAll(address owner, address operator)
        external
        view
        virtual
        returns (bool);
}

contract SamotStaking is Ownable, IERC721Receiver, ReentrancyGuard, Pausable {
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;
    //addresses
    address public nftAddress;
    address public erc20Address;
    address public stakingV1Address;

    //uint256's
    //rate governs how often you receive your token
    uint256 public rate;
    uint256 public startBlock = 13606743;
    uint256 public v1Rate;
    uint256 public v1RatePost;

    //smart contracts
    SamotToken token;
    SamotNFT nft;
    StakingV1 stakedV1;

    //bools
    bool public stakingV1IsActive = true;

    // mappings
    mapping(address => EnumerableSet.UintSet) private _deposits;
    mapping(address => mapping(uint256 => uint256)) public _depositBlocks;

    mapping(address => uint256) public v1Timestamp;
    mapping(address => bool) public hasClaimedDrop;

    constructor(
        address _nftAddress,
        uint256 _rate,
        address _erc20Address,
        address _stakingV1Address,
        uint256 _v1Rate
    ) {
        rate = _rate;
        v1Rate = _v1Rate;
        v1RatePost = _v1Rate;
        nftAddress = _nftAddress;
        token = SamotToken(_erc20Address);
        nft = SamotNFT(_nftAddress);
        stakedV1 = StakingV1(_stakingV1Address);
        _pause();
    }

    function setTokenContract(address _erc20Address) external onlyOwner {
        token = SamotToken(_erc20Address);
    }

    function setStakingV1Contract(address _stakingV1Address)
        external
        onlyOwner
    {
        stakedV1 = StakingV1(_stakingV1Address);
    }

    function setNFTContract(address _nftAddress) external onlyOwner {
        nft = SamotNFT(_nftAddress);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /* STAKING MECHANICS */

    // Set a multiplier for how many tokens to earn each time a block passes.
    // 1 $AMOT PER DAY
    // n Blocks per day= 6200, Token Decimal = 18
    // Rate = 161290322600000
    function setRate(uint256 _rate) public onlyOwner {
        rate = _rate;
    }

    //Checks staked amount
    function depositsOf(address account)
        public
        view
        returns (uint256[] memory)
    {
        EnumerableSet.UintSet storage depositSet = _deposits[account];
        uint256[] memory tokenIds = new uint256[](depositSet.length());

        for (uint256 i; i < depositSet.length(); i++) {
            tokenIds[i] = depositSet.at(i);
        }

        return tokenIds;
    }

    function totalStakes() public view returns (uint256 _totalStakes) {
        return nft.balanceOf(address(this));
    }

    //Calculate rewards amount by address/tokenIds[]
    function calculateRewards(address account, uint256[] memory tokenIds)
        public
        view
        returns (uint256[] memory rewards)
    {
        rewards = new uint256[](tokenIds.length);

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            rewards[i] =
                rate *
                (_deposits[account].contains(tokenId) ? 1 : 0) *
                (block.number - _depositBlocks[account][tokenId]);
        }

        return rewards;
    }

    //Reward amount by address/tokenId
    function calculateReward(address account, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        require(
            block.number > _depositBlocks[account][tokenId],
            "Invalid blocks"
        );
        return
            rate *
            (_deposits[account].contains(tokenId) ? 1 : 0) *
            (block.number - _depositBlocks[account][tokenId]);
    }

    //Returns the number of blocks that have passed since staking
    function calculateBlocks(address account, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return (block.number - _depositBlocks[account][tokenId]);
    }

    //Reward claim function
    function claimRewards(uint256[] memory tokenIds) public whenNotPaused {
        uint256 reward;
        uint256 blockCur = block.number;

        for (uint256 i; i < tokenIds.length; i++) {
            reward += calculateReward(msg.sender, tokenIds[i]);
            _depositBlocks[msg.sender][tokenIds[i]] = blockCur;
        }

        if (reward > 0) {
            token.claim(msg.sender, reward);
        }
    }

    //Claim rewards for V1 and V2
    function claimTotalRewards() public {
        uint256[] memory v2TokenIds = depositsOf(msg.sender);
        claimRewards(v2TokenIds);
        claimV1Rewards();
    }

    //Staking function
    function stake(uint256[] calldata tokenIds) external whenNotPaused {
        require(msg.sender != nftAddress, "Invalid address");
        require(
            nft.isApprovedForAll(msg.sender, address(this)),
            "This contract is not approved to transfer your NFT."
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                nft.ownerOf(tokenIds[i]) == msg.sender,
                "You do not own this NFT."
            );
        }

        claimRewards(tokenIds);
        for (uint256 i; i < tokenIds.length; i++) {
            IERC721(nftAddress).safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i],
                ""
            );
            _deposits[msg.sender].add(tokenIds[i]);
        }
    }

    //Unstaking function
    function unstake(uint256[] calldata tokenIds)
        external
        whenNotPaused
        nonReentrant
    {
        claimRewards(tokenIds);
        for (uint256 i; i < tokenIds.length; i++) {
            require(
                _deposits[msg.sender].contains(tokenIds[i]),
                "Staking: token not deposited"
            );
            _deposits[msg.sender].remove(tokenIds[i]);
            IERC721(nftAddress).safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i],
                ""
            );
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // Staking V1 mechanics
    // You should claim your tokens before UNSTAKING V1

    function setStartBlock(uint256 _startBlock) public onlyOwner {
        startBlock = _startBlock;
    }

    function setV1Rate(uint256 _v1Rate) public onlyOwner {
        v1Rate = _v1Rate;
    }

    function setV1RatePostV2(uint256 _v1RatePost) public onlyOwner {
        v1RatePost = _v1RatePost;
    }

    function flipStakingV1State() public onlyOwner {
        stakingV1IsActive = !stakingV1IsActive;
    }

    function calculateStakingBlocksV1(address _address)
        public
        view
        returns (uint256 _blocks)
    {
        require(stakingV1IsActive, "Staking V1 is deprecated");
        uint256 blocks;
        uint256 blockCur = block.number;
        if (hasClaimedDrop[_address] == false) {
            blocks = blockCur - startBlock;
        } else {
            blocks = blockCur - v1Timestamp[_address];
        }
        return blocks;
    }

    function calculateV1Rewards(address _address)
        public
        view
        returns (uint256 v1Rewards)
    {
        require(stakingV1IsActive, "Staking V1 is deprecated");
        uint256 rewards;
        uint256 blockCur = block.number;
        if (hasClaimedDrop[_address] == false) {
            rewards = (v1Rate * (blockCur - startBlock)).mul(
                stakedV1.stakeOf(_address).length
            );
        } else {
            rewards = (v1RatePost * (blockCur - v1Timestamp[_address])).mul(
                stakedV1.stakeOf(_address).length
            );
        }
        return rewards;
    }

    function numberStakedV1(address _address)
        public
        view
        returns (uint256 _numberStaked)
    {
        require(stakingV1IsActive, "Staking V1 is deprecated");
        return stakedV1.stakeOf(_address).length;
    }

    function claimV1Rewards() public whenNotPaused {
        require(stakingV1IsActive, "Staking V1 is deprecated");
        uint256 blockCur = block.number;
        if (hasClaimedDrop[msg.sender] == false) {
            token.claim(msg.sender, calculateV1Rewards(msg.sender));
            v1Timestamp[msg.sender] = blockCur;
            hasClaimedDrop[msg.sender] = true;
        } else {
            token.claim(msg.sender, calculateV1Rewards(msg.sender));
            v1Timestamp[msg.sender] = blockCur;
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}