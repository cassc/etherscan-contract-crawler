/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// SPDX-License-Identifier: GPL-3.0
// File: @openzeppelin/contracts/utils/Strings.sol

/// @title Staking
/// @author André Costa @ Terratecc

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File: @openzeppelin/contracts/utils/Strings.sol

pragma solidity ^0.8.0;






/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
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

    function transferToStakingPool(
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

}

contract Staking is Ownable {
    
    struct StakeInfo {
        bool staked; //list of all the tokens that are staked]
        uint256 startTime; //unix timestamp of end of staking
    }
    
    struct Reward {
        uint256 rewardId;
        address owner;
        address nftCollection;
        uint256 tokenId;
        uint256 ticketsPrice;
        bool claimed;
    }

    //get information for each token
    mapping(uint => StakeInfo) public idToStakedClown;
    mapping(uint => StakeInfo) public idToStakedJester;

    //get information for each reward
    mapping(uint => Reward) public idToReward;
    uint256 public lastRewardId;

    IERC721 public ChaosClownz;
    IERC721 public Jesters;

    uint256 public ticketsPerDayClownz = 2;
    uint256 public ticketsPerDayJesters = 1;

    mapping(address => uint256) public tickets;
    mapping(address => uint256) public ticketsSpent;

    constructor() {
        ChaosClownz = IERC721(0x90BF903a15EdcDEeb02E8FB4E7eDDF6A67823aA9);
        Jesters = IERC721(0x90BF903a15EdcDEeb02E8FB4E7eDDF6A67823aA9);
    }

    //set ERC721Enumerable
    function setChaosClownz(address newInterface) public onlyOwner {
        ChaosClownz = IERC721(newInterface);
    }

    function setJesters(address newInterface) public onlyOwner {
        Jesters = IERC721(newInterface);
    }

    function setTicketsPerDayClownz(uint256 newAmount) external onlyOwner {
        ticketsPerDayClownz = newAmount;
    }

    function setTicketsPerDayJesters(uint256 newAmount) external onlyOwner {
        ticketsPerDayJesters = newAmount;
    }

    function stake(uint256[] memory tokenIdsClownz, uint256[] memory tokenIdsJesters) external {
        uint256 loopLength = tokenIdsClownz.length > tokenIdsJesters.length ? tokenIdsClownz.length : tokenIdsJesters.length;
        for (uint i = 0; i < loopLength; i++) {
            if (i < tokenIdsClownz.length) {
                require(msg.sender == ChaosClownz.ownerOf(tokenIdsClownz[i]), "Sender must be owner");
                require(!idToStakedClown[tokenIdsClownz[i]].staked, "Token is already Staked!");
                
                idToStakedClown[tokenIdsClownz[i]].startTime = block.timestamp;
                //set the info for the stake
                idToStakedClown[tokenIdsClownz[i]].staked = true;
            }
            if (i < tokenIdsJesters.length) {
                require(msg.sender == Jesters.ownerOf(tokenIdsJesters[i]), "Sender must be owner");
                require(!idToStakedJester[tokenIdsJesters[i]].staked, "Token is already Staked!");
                
                idToStakedJester[tokenIdsJesters[i]].startTime = block.timestamp;
                //set the info for the stake
                idToStakedJester[tokenIdsJesters[i]].staked = true;
            }
        }
        
    }

    //unstake all nfts somebody has
    function unstake(uint[] calldata tokenIdsClownz, uint[] calldata tokenIdsJesters) external {
        uint256 loopLength = tokenIdsClownz.length > tokenIdsJesters.length ? tokenIdsClownz.length : tokenIdsJesters.length;
        uint256 newTickets;
        for (uint i = 0; i < loopLength; i++) {
            if (i < tokenIdsClownz.length) {
                require(msg.sender == ChaosClownz.ownerOf(tokenIdsClownz[i]), "Sender must be owner");
                require(idToStakedClown[tokenIdsClownz[i]].staked, "Token is not Staked!");

                //set the info for the stake
                idToStakedClown[tokenIdsClownz[i]].staked = false;

                newTickets += getTicketsClownz(tokenIdsClownz[i]);
                
            }
            if (i < tokenIdsJesters.length) {
                require(msg.sender == Jesters.ownerOf(tokenIdsJesters[i]), "Sender must be owner");
                require(idToStakedJester[tokenIdsJesters[i]].staked, "Token is not Staked!");

                //set the info for the stake
                idToStakedJester[tokenIdsJesters[i]].staked = false;

                newTickets += getTicketsJesters(tokenIdsJesters[i]);
            }
        }
        tickets[msg.sender] += newTickets;
        
    }

    function claim(uint[] calldata tokenIdsClownz, uint[] calldata tokenIdsJesters) external {
        uint256 loopLength = tokenIdsClownz.length > tokenIdsJesters.length ? tokenIdsClownz.length : tokenIdsJesters.length;
        uint256 newTickets;
        for (uint i = 0; i < loopLength; i++) {
            if (i < tokenIdsClownz.length) {
                require(msg.sender == ChaosClownz.ownerOf(tokenIdsClownz[i]), "Sender must be owner");
                require(idToStakedClown[tokenIdsClownz[i]].staked, "Token is not Staked!");

                newTickets += getTicketsClownz(tokenIdsClownz[i]);
                
            }
            if (i < tokenIdsJesters.length) {
                require(msg.sender == Jesters.ownerOf(tokenIdsJesters[i]), "Sender must be owner");
                require(idToStakedJester[tokenIdsJesters[i]].staked, "Token is not Staked!");

                newTickets += getTicketsClownz(tokenIdsJesters[i]);
            }
        }
        tickets[msg.sender] += newTickets;
    }

    function getTicketsClownz(uint256 tokenId) public view returns(uint256) {
        return ticketsPerDayClownz * ((block.timestamp - idToStakedClown[tokenId].startTime) / 86400);
    }

    function getTicketsJesters(uint256 tokenId) public view returns(uint256) {
        return ticketsPerDayJesters * ((block.timestamp - idToStakedJester[tokenId].startTime) / 86400);
    }

    function totalTickets(address staker) public view returns(uint256) {
        return tickets[staker] - ticketsSpent[staker];
    }

    /// 
    /// REWARDS
    ///

    function addRewards(address nftCollection, uint256[] calldata tokenIds, uint256[] calldata ticketsPrice) external onlyOwner {
        require(tokenIds.length == ticketsPrice.length, "Invalid Arrays!");
        
        for (uint i; i < tokenIds.length; i++) {
            require(IERC721(nftCollection).ownerOf(tokenIds[i]) == msg.sender, "Not Owner of Token!");
            lastRewardId++;

            idToReward[lastRewardId] = Reward(lastRewardId, msg.sender, nftCollection, tokenIds[i], ticketsPrice[i], false);
            //IERC721(nftCollection).transferFrom(msg.sender, address(this), tokenIds[i]);
        }

    }

    function removeRewards(uint256 rewardId) external onlyOwner {
        require(rewardId <= lastRewardId, "Invalid Reward Id!");
        require(!idToReward[rewardId].claimed, "Reward has already been claimed!");

        idToReward[rewardId].claimed = true;
    }

    function claimReward(uint256 rewardId) external {
        require(rewardId <= lastRewardId, "Invalid Reward Id!");
        require(!idToReward[rewardId].claimed, "Reward has already been claimed!");
        require(totalTickets(msg.sender) >= idToReward[rewardId].ticketsPrice, "Insufficient Tickets!");

        ticketsSpent[msg.sender] += idToReward[rewardId].ticketsPrice;
        idToReward[rewardId].claimed = true;
        IERC721(idToReward[rewardId].nftCollection).transferFrom(idToReward[rewardId].owner, msg.sender, idToReward[rewardId].tokenId);
    }



}