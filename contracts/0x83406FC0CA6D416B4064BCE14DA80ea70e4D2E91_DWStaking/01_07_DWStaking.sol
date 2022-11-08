// SPDX-License-Identifier: The MIT License (MIT)






//  __/\\\\\\\\\\\\_______/\\\\\\\\\______/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\\____________/\\\\_        
//   _\/\\\////////\\\___/\\\///////\\\___\/\\\///////////____/\\\\\\\\\\\\\__\/\\\\\\________/\\\\\\_       
//    _\/\\\______\//\\\_\/\\\_____\/\\\___\/\\\______________/\\\/////////\\\_\/\\\//\\\____/\\\//\\\_      
//     _\/\\\_______\/\\\_\/\\\\\\\\\\\/____\/\\\\\\\\\\\_____\/\\\_______\/\\\_\/\\\\///\\\/\\\/_\/\\\_     
//      _\/\\\_______\/\\\_\/\\\//////\\\____\/\\\///////______\/\\\\\\\\\\\\\\\_\/\\\__\///\\\/___\/\\\_    
//       _\/\\\_______\/\\\_\/\\\____\//\\\___\/\\\_____________\/\\\/////////\\\_\/\\\____\///_____\/\\\_   
//        _\/\\\_______/\\\__\/\\\_____\//\\\__\/\\\_____________\/\\\_______\/\\\_\/\\\_____________\/\\\_  
//         _\/\\\\\\\\\\\\/___\/\\\______\//\\\_\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\_____________\/\\\_ 
//          _\////////////_____\///________\///__\///////////////__\///________\///__\///______________\///__
//  _____/\\\\\\\\\\\____/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\________/\\\__/\\\\\\\\\\\\\\\_             
//   ___/\\\/////////\\\_\///////\\\/////____/\\\\\\\\\\\\\__\/\\\_____/\\\//__\/\\\///////////__            
//    __\//\\\______\///________\/\\\________/\\\/////////\\\_\/\\\__/\\\//_____\/\\\_____________           
//     ___\////\\\_______________\/\\\_______\/\\\_______\/\\\_\/\\\\\\//\\\_____\/\\\\\\\\\\\_____          
//      ______\////\\\____________\/\\\_______\/\\\\\\\\\\\\\\\_\/\\\//_\//\\\____\/\\\///////______         
//       _________\////\\\_________\/\\\_______\/\\\/////////\\\_\/\\\____\//\\\___\/\\\_____________        
//        __/\\\______\//\\\________\/\\\_______\/\\\_______\/\\\_\/\\\_____\//\\\__\/\\\_____________       
//         _\///\\\\\\\\\\\/_________\/\\\_______\/\\\_______\/\\\_\/\\\______\//\\\_\/\\\\\\\\\\\\\\\_      
//          ___\///////////___________\///________\///________\///__\///________\///__\///////////////__  





pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IToken {
    function mint(address to, uint256 amount) external;
}


/**
 * @title DreamWorld Staking
 * 
 * @notice The official Dream World NFT staking contract.
 * 
 * @author M. Burke
 * 
 * @custom:security-contact [email protected]
 */
contract DWStaking is Ownable, ReentrancyGuard {
    IToken immutable ZZZs;
    IERC721 immutable DWnft;
    uint256 immutable INITIAL_BLOCK;

    mapping(address => StakeCommitment[]) public commitments;

    event StakeNft(address indexed _staker, uint256 indexed _tokenId);
    event UnstakeNft(
        address indexed _staker,
        uint256 indexed _tokenId,
        uint256 _rewardTokens
    );

    /** 
     * @dev     blockStakedAdjusted will be updated as users withdraw rewards from staked nfts
     * 
     * @param   blockStakedAdjusted is the calculated value => block.number - INITIAL_BLOCK
     *           (which is set on deployment). This is allows the struct to use uint32
     *           rather than uint256.
     *
     * @param   tokenId is the token id from the Dream World NFT contract associated with the
     *           NFT to be staked.
     */
    struct StakeCommitment {
        uint32 blockStakedAdjusted;
        uint256 tokenId;
    }

    constructor(address _erc20Token, address _erc721Token) {
        ZZZs = IToken(_erc20Token);
        DWnft = IERC721(_erc721Token);
        INITIAL_BLOCK = block.number;
    }

    //------------------------------------USER FUNCS-------------------------------------------\\
    /** @dev     The use of safeTransferFrom ensures the caller either owns the NFT or has
     *           been approved.
     *
     *  @param   _tokenId is the token id from the Dream World NFT contract associated with the
     *           NFT to be staked.
     */
    function stakeNft(uint256 _tokenId) external {
        DWnft.safeTransferFrom(msg.sender, address(this), _tokenId);
    }

    /** 
     * @notice  'stakeMultipleNfts' is to be used only for staking multiple NFTs.
     *           While using it to stake one, is possible, unnecessary gas
     *           costs will occure.
     *
     * @param   _tokenIds is an array of Dream World NFT ids to be staked.
     */
    function stakeMultipleNfts(uint256[] memory _tokenIds) external {
        require(
            DWnft.isApprovedForAll(msg.sender, address(this)) == true,
            "DWStaking: Staking contract is not approved for all."
        );

        uint256 len = _tokenIds.length;

        for (uint256 i = 0; i < len; ) {
            DWnft.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**  
     * @notice 'withdrawAvailableRewards' is to be called by user wishing to withdraw ZZZs.
     *
     * @dev    Note that 'blockStakedAdjusted' will be updated to reflect no available
     *          reward on withdraw.
     */
    function withdrawAvailableRewards() external nonReentrant {
        StakeCommitment[] memory commitmentsArr = commitments[msg.sender];
        uint256 availableRewards = _getAvailableRewards(msg.sender);
        uint256 currentAdjustedBlock = block.number - INITIAL_BLOCK;
        uint256 len = commitmentsArr.length;

        for (uint256 i = 0; i < len; ) {
            commitments[msg.sender][i].blockStakedAdjusted = uint32(
                currentAdjustedBlock
            );

            unchecked {
                ++i;
            }
        }

        _mintTo(msg.sender, availableRewards);
    }

    /** 
     * @notice  A variation of 'unstakeNft' is available below: 'unstakeNftOptions'.
     *           Calling `unstakeNft` with a single arg (_tokenId) assumes the caller is the owner
     *           and does not wish to specify an alternate beneficiary.
     *
     * @dev     Users can view an array of staked NFTs via `getStakingCommitments`.
     *
     * @param   _tokenId is the token id from the Dream World NFT contract associated with the
     *           NFT to be unstaked.
     */
    function unstakeNft(uint256 _tokenId) external nonReentrant {
        _unStakeNft(_tokenId, msg.sender, msg.sender);
    }

    /**
     * @notice  See function definition above for simple use case.
     *           Caling `unstakeNftOptions` with three args (_tokenId, _owner, _beneficiary)
     *           assumes the caller may not be the owner (an approvedForAll check will be made).
     *           It also gives the approved user or owner the opportunity to specify a beneficiary.
     *
     * @dev     User can view array of staked NFTs via `getStakingCommitments`.
     *
     * @param   _tokenId is the token id from the Dream World NFT contract associated with the
     *           NFT to be unstaked.
     *
     * @param  _owner The address of the Nft's owner at time of stkaing.
     *
     * @param  _beneficiary The address of an alternate wallet to send BOTH the ERC20 ZZZs
     *          staking rewards and the original ERC721 staked NFT.
     */
    function unstakeNftOptions(
        uint256 _tokenId,
        address _owner,
        address _beneficiary
    ) external nonReentrant {
        require(
            DWnft.isApprovedForAll(_owner, msg.sender),
            "Caller is not approved for all. See ERC721 spec."
        );
        _unStakeNft(_tokenId, _owner, _beneficiary);
    }

    /** 
     * @dev '_unStakeNft' may be called either `unstakeNft` or 'unstakeNftOptions'
     *   
     * @dev '_unStakeNft' will iterate through the array of an owners staked tokens. If 
     *       correct commitment is found, any commitsments following will be shifted down
     *       to overwrite and the last commitment will be zeroed out in O(n) time. 
     */
    function _unStakeNft(
        uint256 _tokenId,
        address _owner,
        address _beneficiary
    ) private {
        StakeCommitment[] memory existingCommitmentsArr = commitments[_owner];
        uint256 len = existingCommitmentsArr.length;
        uint256 rewardsAmount = 0;
        bool includesId = false;

        for (uint256 i = 0; i < len; ) {
            uint256 elTokenId = existingCommitmentsArr[i].tokenId;

            if (includesId == true && i < len-1) {
                commitments[_owner][i] = existingCommitmentsArr[i+1];
            }

            if (elTokenId == _tokenId) {
                includesId = true;
                rewardsAmount = _calculateRewards(existingCommitmentsArr[i].blockStakedAdjusted);

                if (i < len-1) {
                    commitments[_owner][i] = existingCommitmentsArr[i+1];
                }
            }

            unchecked {
                ++i;
            }
        }

        // Zero out last commitment
        require(includesId, "Token not found");

        delete commitments[_owner][len-1];
        _mintTo(_beneficiary, rewardsAmount);
        DWnft.safeTransferFrom(address(this), _beneficiary, _tokenId);

        emit UnstakeNft(_beneficiary, _tokenId, rewardsAmount);
    }

    //-----------------------------------------------------------------------------------------\\

    /**
     * @notice 'onERC721Received' will be called to validate the staking process
     *          (See ERC721 docs: `safeTransferFrom`).
     *
     * @dev    Business logic of staking is within 'onERC721Received'
     */
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) public returns (bytes4) {
        require(
            _operator == address(this),
            "Must transfer valid nft via stake function."
        );
        require(
            DWnft.ownerOf(_tokenId) == address(this),
            "Must transfer token from DW collection"
        );
        uint256 currentBlock = block.number;

        StakeCommitment memory newCommitment;
        newCommitment = StakeCommitment({
            blockStakedAdjusted: uint32(currentBlock - INITIAL_BLOCK),
            tokenId: _tokenId
        });

        uint256 numberOfCommits = commitments[_from].length;

        // If user previously unstaked a token, last el will have been zeroed out. 
        // This overwrites last el only in this situation.

        if (numberOfCommits == 0 || commitments[_from][numberOfCommits-1].blockStakedAdjusted != 0) {
            commitments[_from].push(newCommitment);
        } else if (commitments[_from][numberOfCommits-1].blockStakedAdjusted == 0) {
            commitments[_from][numberOfCommits-1] = newCommitment;
        }

        emit StakeNft(_from, _tokenId);

        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @notice `_getStakedIds` is used internally for fetching account data
     *          but it also made available for users.
     *
     * @dev    Returns an array of ERC721 token Ids that an
     *          account has staked.
     *
     * @param  _account is the wallet address of the user, who's data is to be fetched.
     */
    function _getStakedIds(address _account)
        public
        view
        returns (uint256[] memory)
    {
        StakeCommitment[] memory commitmentsArr = commitments[_account];
        uint256 len = commitmentsArr.length;
        uint256[] memory tokenIdArray = new uint256[](len);

        for (uint256 i = 0; i < len; ) {
            tokenIdArray[i] = commitmentsArr[i].tokenId;

            unchecked {
                ++i;
            }
        }

        return tokenIdArray;
    }

    /**
     * @notice `_getAvailableRewards` is used internally for fetching account data
     *          but it also made available for users.
     *
     * @dev    '_getAvailableRewards' will return the sum of available rewards.
     *
     * @param   _account is the wallet address of the user, who's data is to be fetched.
     */
    function _getAvailableRewards(address _account)
        public
        view
        returns (uint256)
    {
        StakeCommitment[] memory commitmentsArr = commitments[_account];
        uint256 len = commitmentsArr.length;
        uint256 rewards = 0;

        for (uint256 i = 0; i < len; ) {
            rewards += _calculateRewards(commitmentsArr[i].blockStakedAdjusted);

            unchecked {
                ++i;
            }
        }

        return rewards;
    }

    //------------------------------------UTILS------------------------------------------------\\

    /// @notice '_mintTo' is used internally for interfacing w/ the ERC20 ZZZs rewards token.
    function _mintTo(address _user, uint256 _amount) private {
        ZZZs.mint(_user, _amount);
    }

    /** 
     * @dev '_calculateRewards' is used in calculating the amount of ERC20 ZZZs rewards token
     *       to issue to the beneficiary durring the unstaking process.
     */
    function _calculateRewards(uint32 _stakedAtAdjusted)
        private
        view
        returns (uint256)
    {
        if (_stakedAtAdjusted == 0) {
            return 0;
        }

        uint256 availableBlocks = block.number - INITIAL_BLOCK;
        uint256 rewardBlocks = availableBlocks - _stakedAtAdjusted;

        // Where one token staked for one day should receive ~ 72 ZZZs
        return rewardBlocks * 10 ** 16 ;
    }
}