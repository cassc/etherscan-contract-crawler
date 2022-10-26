/**
 *Submitted for verification at Etherscan.io on 2022-10-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract ArrayHelpers {
    /**
     * @dev Internal function. Add an address into an 
     *      array of unique address.
     *
     * @param addAddress Address want to add.
     * @param addressArray Array of unique address.
     */
    function _addAddressToUniqueAddressArray(
        address addAddress, address[] storage addressArray
    ) internal {
        bool exist = false;
        for (uint i = 0; i< addressArray.length; i++){
            if(addressArray[i] == addAddress){
                exist = true;
                break;
            }
        }
        if(!exist){
            addressArray.push(addAddress);
        }
    }

    /**
     * @dev Internal function. Remove address from an 
     *      array of unique address.
     *
     * @param removeAddress Address want to remove.
     * @param addressArray Array of unique address.
     */
    function _removeAddressFromUniqueAddressArray(
        address removeAddress, address[] storage addressArray
    ) internal {
        for (uint i = 0; i< addressArray.length; i++){
            if(addressArray[i] == removeAddress){
                addressArray[i] = addressArray[addressArray.length - 1];
                addressArray.pop();
                break;
            }
            
        }
    }

    /**
     * @dev Internal function. Add an uint256 into an 
     *      array of unique uint256.
     *
     * @param addUint256 Uint256 want to add.
     * @param uint256Array Array of unique Uint256.
     */
    function _addUint256ToUniqueUint256Array(
        uint256 addUint256, uint256[] storage uint256Array
    ) internal {
        bool exist = false;
        for (uint i = 0; i< uint256Array.length; i++){
            if(uint256Array[i] == addUint256){
                exist = true;
                break;
            }
        }
        if(!exist){
            uint256Array.push(addUint256);
        }
    }

    /**
     * @dev Internal function. Remove uint256 from an 
     *      array of unique uint256.
     *
     * @param removeUint256 Uint256 want to remove.
     * @param uint256Array Array of unique Uint256.
     */
    function _removeUint256FromUniqueUint256Array(
        uint256 removeUint256, uint256[] storage uint256Array
    ) internal {
        for (uint i = 0; i< uint256Array.length; i++){
            if(uint256Array[i] == removeUint256){
                uint256Array[i] = uint256Array[uint256Array.length - 1];
                uint256Array.pop();
                break;
            }
            
        }
    }
}

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

pragma solidity ^0.8.0;
/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


pragma solidity ^0.8.0;
/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

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

pragma solidity ^0.8.0;
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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity ^0.8.0;
/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

pragma solidity ^0.8.0;
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.8.4;
/**
 * @dev An staking infomation contains 3 components: a staker is user who staked the nft, a staked time ( time where staker staked their 
 *      token(s) into smart contract. This data only valid when unStakedTime != 0 ), a unstaked time 
 *      ( time where staker unstake their token from smart contract. This data == 0 means token is 
 *      not being staked.)
 */
struct StakingInfo {
    address staker;
    uint stakedTime;
    uint unStakedTime;
}

pragma solidity ^0.8.4;

interface StakingErrorsAndEvents {
    /**
     * @dev Emit an event whenever user successfully stake (a) asset{s}
     *
     * @param staker New vault ID.
     * @param erc721Adds List of the ERC721 address
     * @param tokenIds List of the same ERC721 id
     * @param stakedTime List of the time user staked the asset
     */
    event StakeAssets(
       address staker,
       address[] erc721Adds,
       uint256[] tokenIds,
       uint256 stakedTime
    );

    /**
     * @dev Emit an event whenever user successfully unstake (a) asset{s}
     *
     * @param staker New vault ID.
     * @param erc721Adds List of the ERC721 address
     * @param tokenIds List of the same ERC721 id
     * @param unStakedTime The time user unstaked the asset
     */
    event UnstakeAssets(
       address staker,
       address[] erc721Adds,
       uint256[] tokenIds,
       uint unStakedTime
    );
   
   /**
     * @dev Revert with an error when list of ERC721 addresses not have the same length with list of tokenID
     */
   error InvalidAddressAndIDList();


   /**
     * @dev Revert with an error when an user are not the owner of ERC721.
     */
   error NotOwnerOfERC721();

  /**
     * @dev Revert with an error when an user are not the staker.
     */
   error NotStakerOfERC721();

   /**
     * @dev Revert with an error when an user are not the staker or asset already been unstaked.
     */
   error CannotUnstakeAsset();
}


pragma solidity ^0.8.4;
/**
 * @title StakingInterface
 * @author 0xHenry
 * @custom:version 1.0
 * @notice Staking is a protocol for tracking user staking NFT for off-chain rewards
 *
 * @dev StakingInterface contains all external function interfaces for
 *      Staking.
 */
interface StakingInterface {

    /**
     * @notice Staking single/multiple ERC721(s) by transfer token(s) to this 
     *         smart contract and store staking information.
     *
     * @param erc721Adds List of ERC721 addresses.
     * @param tokenIds List of TokenId.
     */
    function stakeAssets(address[] memory erc721Adds,uint256[] memory tokenIds) external;

    /**
     * @notice UnStaking single/multiple ERC721(s) by transfer back token(s) from this 
     *         smart contract and reset staking information.
     *
     * @param erc721Adds List of ERC721 addresses.
     * @param tokenIds List of TokenId.
     */
    function unStakeAssets(address[] memory erc721Adds,uint256[] memory tokenIds) external;

    /**
     * @notice Combine Stake and UnStaking single/multiple ERC721(s) to optimize price.
     *
     * @param stakeERC721Adds List of ERC721 addresses to stake.
     * @param stakeTokenIds List of TokenId of asset being staked.
     * @param stakeERC721Adds List of ERC721 addresses to unstake.
     * @param stakeTokenIds List of TokenId of asset being unstaked.
     */
    function optimizeStakeAndUnStakeAssets(
        address[] memory stakeERC721Adds,
        uint256[] memory stakeTokenIds,
        address[] memory unStakeERC721Adds,
        uint256[] memory unStakeTokenIds
    ) external;

    /**
     * @notice Retrieve specific user contribution of specific vault.
     *
     * @param erc721Add Address of ERC721 token.
     * @param tokenId Token ID.
     *
     * @return stakingInfo Includes staker, stakedTime, unStakedTime.
     */
    function getStakeInfo(address erc721Add,uint256 tokenId) external view returns(StakingInfo memory stakingInfo);

    /**
     * @notice Retrieve list of staked asset of specific NFT Collection
     *
     * @param erc721Add Address of ERC721 token.
     *
     * @return assetList list of staked asset of specific NFT Collection
     */
    function getStakedAssetList(address erc721Add) external view returns(uint256[] memory assetList);
}


pragma solidity ^0.8.4;
contract StakeInternal is ERC721Holder, Ownable, ReentrancyGuard, Pausable, StakingErrorsAndEvents, ArrayHelpers {

    mapping(address => mapping(uint256 => StakingInfo)) private stakedAssets;
    mapping(address => uint256[]) private stakedAssetList;

    /**
     * @dev Internal function to stake single/multiple ERC721(s).
     *
     * @param erc721Adds List of ERC721 addresses.
     * @param tokenIds List of TokenId.
     */
    function _stakeAssets(address[] memory erc721Adds,uint256[] memory tokenIds) internal {
        if(erc721Adds.length != tokenIds.length){
            revert InvalidAddressAndIDList();
        }
        for (uint i = 0; i < erc721Adds.length; i++){
            _stakeAsset(erc721Adds[i], tokenIds[i]);
        }


        emit StakeAssets(msg.sender, erc721Adds, tokenIds, block.timestamp);
    }

    /**
     * @dev Internal function to stake single ERC721(s) by transfer token to this 
     *         smart contract and set staking information.
     *
     * @param erc721Add ERC721 address.
     * @param tokenId TokenId.
     */
    function _stakeAsset(address erc721Add, uint256 tokenId) internal nonReentrant whenNotPaused{
        //To prevent if user approve NFT successfully then stake asset fail at some point. 
        //Attacker can leverage this.
        if(IERC721(erc721Add).ownerOf(tokenId) != msg.sender){
            revert NotOwnerOfERC721();
        }
        StakingInfo storage stakingInfo = stakedAssets[erc721Add][tokenId];
        stakingInfo.staker = msg.sender;
        stakingInfo.stakedTime = block.timestamp;
        stakingInfo.unStakedTime = 0;

        _addUint256ToUniqueUint256Array(tokenId, stakedAssetList[erc721Add]);
        IERC721(erc721Add).safeTransferFrom(msg.sender, address(this), tokenId);
    }

    /**
     * @dev Internal function to unStake single/multiple ERC721(s).
     *
     * @param erc721Adds List of ERC721 addresses.
     * @param tokenIds List of TokenId.
     */
    function _unStakeAssets(address[] memory erc721Adds,uint256[] memory tokenIds) internal {
        if(erc721Adds.length != tokenIds.length){
            revert InvalidAddressAndIDList();
        }
        for (uint i = 0; i < erc721Adds.length; i++){
            _unStakeAsset(erc721Adds[i], tokenIds[i]);
        }

        emit UnstakeAssets(msg.sender, erc721Adds, tokenIds, block.timestamp);
    }

    /**
     * @dev Internal function to stake single ERC721(s) by transfer back token from this 
     *         smart contract and set staking information.
     *
     * @param erc721Add ERC721 address.
     * @param tokenId TokenId.
     */
    function _unStakeAsset(address erc721Add, uint256 tokenId) internal nonReentrant whenNotPaused{
        StakingInfo storage stakingInfo = stakedAssets[erc721Add][tokenId];

        if(stakingInfo.stakedTime == 0){
            revert CannotUnstakeAsset();
        }

        if(stakingInfo.staker != msg.sender){
            revert NotStakerOfERC721(); 
        }

        stakingInfo.unStakedTime = block.timestamp;
        stakingInfo.stakedTime = 0;

        _removeUint256FromUniqueUint256Array(tokenId, stakedAssetList[erc721Add]);

        IERC721(erc721Add).safeTransferFrom(address(this), msg.sender,  tokenId);
    }

    /**
     * @dev Internal function to get stake information
     *
     * @param erc721Add ERC721 address.
     * @param tokenId TokenId.
     */
    function _getStakeInfo(address erc721Add,uint256 tokenId) internal view returns(StakingInfo memory stakingInfo){
        stakingInfo = stakedAssets[erc721Add][tokenId];  
    }

    /**
     * @dev Internal function to get list of staked asset of specific NFT Collection
     *
     * @param erc721Add ERC721 address.
     */
    function _getStakedAssetList(address erc721Add) internal view returns(uint256[] memory assetList){
        assetList = stakedAssetList[erc721Add];  
    }
}

pragma solidity ^0.8.4;
/**
 * @title StakingInterface
 * @author 0xHenry
 * @custom:version 1.0
 * @notice Staking is a protocol for tracking user staking NFT for off-chain rewards.
 *
 */

contract Staking is StakingInterface, StakeInternal{

    /**
     * @notice Staking single/multiple ERC721(s) by transfer token(s) to this 
     *         smart contract and store staking information.
     *
     * @param erc721Adds List of ERC721 addresses.
     * @param tokenIds List of TokenId.
     */
    function stakeAssets(address[] memory erc721Adds,uint256[] memory tokenIds) external override {
        _stakeAssets(erc721Adds,tokenIds); 
    }

    /**
     * @notice UnStaking single/multiple ERC721(s) by transfer back token(s) from this 
     *         smart contract and reset staking information.
     *
     * @param erc721Adds List of ERC721 addresses.
     * @param tokenIds List of TokenId.
     */
    function unStakeAssets(address[] memory erc721Adds,uint256[] memory tokenIds) external override {
        _unStakeAssets(erc721Adds,tokenIds);  
    }

    /**
     * @notice Combine Stake and UnStaking single/multiple ERC721(s) to optimize price.
     *
     * @param stakeERC721Adds List of ERC721 addresses to stake.
     * @param stakeTokenIds List of TokenId of asset being staked.
     * @param stakeERC721Adds List of ERC721 addresses to unstake.
     * @param stakeTokenIds List of TokenId of asset being unstaked.
     */
    function optimizeStakeAndUnStakeAssets(
        address[] memory stakeERC721Adds,
        uint256[] memory stakeTokenIds,
        address[] memory unStakeERC721Adds,
        uint256[] memory unStakeTokenIds
    ) external override {
        _stakeAssets(stakeERC721Adds,stakeTokenIds); 
        _unStakeAssets(unStakeERC721Adds,unStakeTokenIds); 
    }

    /**
     * @notice Retrieve specific user contribution of specific vault.
     *
     * @param erc721Add Address of ERC721 token.
     * @param tokenId Token ID.
     *
     * @return stakingInfo Includes staker, stakedTime, unStakedTime.
     */
    function getStakeInfo(address erc721Add,uint256 tokenId) external override view returns(StakingInfo memory stakingInfo){
        stakingInfo = _getStakeInfo(erc721Add,tokenId);   
    }

    /**
     * @notice Retrieve list of staked asset of specific NFT Collection
     *
     * @param erc721Add Address of ERC721 token.
     *
     * @return assetList list of staked asset of specific NFT Collection
     */
    function getStakedAssetList(address erc721Add) external override view returns(uint256[] memory assetList){
        assetList = _getStakedAssetList(erc721Add);
    }
}