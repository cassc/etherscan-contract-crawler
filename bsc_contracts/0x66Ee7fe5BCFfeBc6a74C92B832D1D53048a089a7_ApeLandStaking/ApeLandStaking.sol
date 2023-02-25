/**
 *Submitted for verification at BscScan.com on 2023-02-24
*/

// SPDX-License-Identifier: Unlicense
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: nftstaking.sol


pragma solidity 0.8.7;

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function walletOfOwner(address _owner) external view returns (uint256[] memory);
    
}


interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ApeLandStaking {
    using SafeMath for uint256;
    
    /// ERC721 NFT & ERC20 token Interfaces
    IERC20 public immutable rewardsToken;
    IERC721 public immutable nftCollection;

    /// Staked NFT INFO
    /// 2023.2.23 10:47 PM
    struct stakeNFTInfo{
        address owner;
        uint8 level;
        uint256 tokenID;
        bool isStaked;
        uint256 lastUpdatedTime;
        uint256 lackRewards;
    }
    uint256 private burnToken = 0;

    mapping(uint256 => stakeNFTInfo) public stakedNFTs;
    mapping(uint8 => uint256) private rewardsPerday;
    mapping(uint8 => uint256) private upgradeLevelBurnAmount;
    mapping(uint8 => uint256) private upgradeLevelMaxBurnAmount;

    constructor(IERC721 _sNFT, IERC20 _sToken){
        nftCollection = _sNFT;
        rewardsToken = _sToken;

        rewardsPerday[0] = 0.5 ether;
        // rewardsPerday[1] = 0.6 ether;
        // rewardsPerday[2] = 0.7 ether;
        // rewardsPerday[3] = 0.8 ether;
        // rewardsPerday[4] = 0.9 ether;

        // upgradeLevelBurnAmount[0] = 12 ether;
        // upgradeLevelBurnAmount[1] = 13 ether;
        // upgradeLevelBurnAmount[2] = 14 ether;
        // upgradeLevelBurnAmount[3] = 15 ether;

        // upgradeLevelMaxBurnAmount[0] = 20 ether;
        // upgradeLevelMaxBurnAmount[1] = 18 ether;
        // upgradeLevelMaxBurnAmount[2] = 16 ether;
        // upgradeLevelMaxBurnAmount[3] = 13 ether;

    }

    /// NFT staking function
    /// transfer NFTs to NFTstaking contract
    /// Create stakedNFT info and add to (stakedNFTs)mapping
    function stake(uint256[] calldata _tokenIDs) public {
        uint256 len = _tokenIDs.length;
        for(uint256 i; i < len; i++){
//            require(nftCollection.ownerOf(_tokenIDs[i]) == msg.sender, "You don't own this NFT");
            if(nftCollection.ownerOf(_tokenIDs[i]) == msg.sender && stakedNFTs[_tokenIDs[i]].isStaked == false){
                nftCollection.transferFrom(msg.sender, address(this), _tokenIDs[i]);
                
                stakedNFTs[_tokenIDs[i]].owner = msg.sender;
                stakedNFTs[_tokenIDs[i]].level = 0;
                stakedNFTs[_tokenIDs[i]].isStaked = true;
                stakedNFTs[_tokenIDs[i]].lastUpdatedTime = block.timestamp;
                stakedNFTs[_tokenIDs[i]].lackRewards = 0;
            }
        }
    }

    // If user has any ApeLand staked and if he tried to unStake 
    // At first calculate the rewards and ClaimRewards
    // ApeLands are returned to Staker
    function unStake(uint256[] calldata _tokenIDs) public {
        //require(getStakedNFTCount(msg.sender) > 0, "You have no staked NFTS");

        uint256 len = _tokenIDs.length;
        claimRewards(_tokenIDs);

        for(uint256 i; i < len; i++) {
            if(stakedNFTs[_tokenIDs[i]].owner == msg.sender && stakedNFTs[_tokenIDs[i]].isStaked == true){
                stakedNFTs[_tokenIDs[i]].isStaked = false;
                nftCollection.transferFrom(address(this), msg.sender, _tokenIDs[i]);
            }
        }
    }

    function claimRewards(uint256[] calldata _tokenIDs) public {
        uint256 len = _tokenIDs.length;
        uint256 rewards = 0;
        for(uint256 i; i < len; i++){
            if(stakedNFTs[_tokenIDs[i]].owner == msg.sender && stakedNFTs[_tokenIDs[i]].isStaked == true){
                rewards = rewards.add(calculateRewardsNFT(_tokenIDs[i]));
                stakedNFTs[_tokenIDs[i]].lastUpdatedTime = block.timestamp;
                stakedNFTs[_tokenIDs[i]].lackRewards = 0;
            }
        }
        require(rewardsToken.balanceOf(address(this)) > rewards, "not enough money, plz let the owner know");
        rewardsToken.transfer(msg.sender, rewards);
    }

    function UpgradeLevel(uint256 _tokenID) public {
        require(nftCollection.ownerOf(_tokenID) == address(this), "This NFT is not staked yet");
        require(stakedNFTs[_tokenID].isStaked == true, "This NFT is not staked yet");
        require(stakedNFTs[_tokenID].owner == msg.sender, "This is not your nft, you cannot modify this NFT info");

        uint8 currentLevel = stakedNFTs[_tokenID].level;

        require(currentLevel < 4, "You can no longer upgrade the level");
        require(rewardsToken.balanceOf(msg.sender) >= upgradeLevelBurnAmount[currentLevel], "You don't have enough token to Upgrade Level");

        stakedNFTs[_tokenID].lackRewards = calculateRewardsNFT(_tokenID);
        stakedNFTs[_tokenID].lastUpdatedTime = block.timestamp;

        burn(msg.sender, upgradeLevelBurnAmount[currentLevel]);
        stakedNFTs[_tokenID].level++;
    }

    function UpgradeLevelMax(uint256 _tokenID) public {
        require(nftCollection.ownerOf(_tokenID) == address(this), "This NFT is not staked yet");
        require(stakedNFTs[_tokenID].isStaked == true, "This NFT is not staked yet");
        require(stakedNFTs[_tokenID].owner == msg.sender, "It's your nft, you cannot modify this NFT info");
        uint8 currentLevel = stakedNFTs[_tokenID].level;

        require(currentLevel < 4, "You can no longer upgrade the level");
        require(rewardsToken.balanceOf(msg.sender) >= upgradeLevelMaxBurnAmount[currentLevel], "You don't have enough token to Upgrade Level");

        stakedNFTs[_tokenID].lackRewards = calculateRewardsNFT(_tokenID);
        stakedNFTs[_tokenID].lastUpdatedTime = block.timestamp;

        burn(msg.sender, upgradeLevelMaxBurnAmount[currentLevel]);
        stakedNFTs[_tokenID].level = 4;
    }

    function burn(address user, uint256 amount) internal{
        rewardsToken.transferFrom(user, address(0), amount);
        burnToken = burnToken.add(amount);
    }

    /* ========= VIEWS ========= */
    function calculateRewardsNFT(uint256 _tokenID) public view returns (uint256){
        require(stakedNFTs[_tokenID].isStaked == true, "This NFT is not staking now");
        // uint256 rewards = ((block.timestamp.sub(stakedNFTs[_tokenID].lastUpdatedTime)).mul(
        //     rewardsPerday[stakedNFTs[_tokenID].level])).add(stakedNFTs[_tokenID].lackRewards);
        uint256 rewards = (block.timestamp.sub(stakedNFTs[_tokenID].lastUpdatedTime)).mul(rewardsPerday[stakedNFTs[_tokenID].level]);
        rewards = (rewards.div(3600)).div(24);
        rewards = rewards.add(stakedNFTs[_tokenID].lackRewards);
        return rewards;
    }

    function getStakedNFTCount(address user) public view returns (uint256){
        uint256[] memory totalStakedNFTList = nftCollection.walletOfOwner(address(this));
        uint256 count = 0;
        for(uint256 i; i < totalStakedNFTList.length; i++){
            if(stakedNFTs[totalStakedNFTList[i]].owner == user && stakedNFTs[totalStakedNFTList[i]].isStaked == true){
                count++;
            }
        }
        return count;
    }

    function getStakedNFTList(address user) public view returns (uint256[] memory){
        uint256[] memory totalStakedNFTList = nftCollection.walletOfOwner(address(this));
        uint256[] memory stakedNFTList = new uint256[](getStakedNFTCount(user));
        uint256 j = 0;
        for(uint256 i; i < totalStakedNFTList.length; i++){
            if(stakedNFTs[totalStakedNFTList[i]].owner == user && stakedNFTs[totalStakedNFTList[i]].isStaked == true){
                stakedNFTList[j++] = totalStakedNFTList[i];
            }
        }
        return stakedNFTList;
    }
    
    function getTotalrewards(address user) public view returns(uint256){
        uint256[] memory stakedNFTList = getStakedNFTList(user);
        uint256 len = getStakedNFTCount(user);
        uint256 totalRewards = 0;
        for(uint256 i = 0; i < len; i++){
            totalRewards = totalRewards.add(calculateRewardsNFT(stakedNFTList[i]));
        }
        return totalRewards;
    }

    function getLevel(uint256 _tokenID) public view returns (uint256){
        return stakedNFTs[_tokenID].level;
    }

    function getTotalBurn() public view returns (uint256){
        return burnToken;
    }
}