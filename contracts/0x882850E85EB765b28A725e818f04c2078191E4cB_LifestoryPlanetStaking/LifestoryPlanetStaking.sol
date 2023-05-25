/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// File: contracts/IRewardToken.sol


pragma solidity ^0.8.0;

/**
 * @title IRewardToken
 * IRewardToken - define for future use when LIFC reward token is listed
 */
interface IRewardToken {
    /**
     * @dev this function called to send tokens rewards after unstake
     * @dev only LifestoryPlanetStaking Contract can called this function
     * @param to address to send reward
     * @param amount number of LIFC to send
     */
    function sendRewards(address to, uint256 amount) external;
}
// File: contracts/LifestoryPlanetStaking.sol


pragma solidity ^0.8.0;






// @author: Abderrahmane Bouali for Lifestory


/**
 * @title LifestoryPlanetStaking
 * LifestoryPlanetStaking - a contract for Lifestory to stake planets.
 */
contract LifestoryPlanetStaking is Ownable {
    // LifestoryPlanets contract
    IERC721 public planetContract;

    // LifestoryReward contract to be implemented in the future
    IRewardToken public rewardTokenContract;

    // allow or disable new staking
    bool public allowStaking = true;

    // number of LIFC to be allocated
    uint256 public totalRewardSupply = 0;

    // Constant define one year in timestamp
    uint256 constant YEARTIME = 365 days;
    
    struct Staker {
        // Array of planet ID staked
        uint256[] planetIds;

        // Mapping of planet ID to release date of staking
        mapping(uint256 => uint256) planetStakingReleaseDate;

        // Mapping of planet ID to period of staking
        mapping(uint256 => uint8) planetPeriods;
    }

    /**
     * @dev constructor of LifestoryPlanetStaking 
     * @param _planet address of ERC721 contract of LIFV Planets
     */
    constructor(IERC721 _planet) {
        planetContract = _planet;
    }

    // Mapping from staker address to Staker structure
    mapping(address => Staker) private stakers;

    // Mapping from planet ID to owner address
    mapping(uint256 => address) public planetOwner;

    /**
     * @dev Emitted when `user` stake `planetId`
     */
    event Staked(address user, uint256 planetId);

    /**
     * @dev Emitted when `user` unstake `planetId`
     */
    event Unstaked(address user, uint256 planetId);

    /**
     * @dev pure function to get number of LIFC depending on staking periode 
     * @param _nbYears number of year of staking
     */
    function getRewarding(uint8 _nbYears)
        public
        pure
        returns (uint16)
    {
        if(_nbYears == 1) return 1800;
        if(_nbYears == 2) return 4800;
        if(_nbYears == 3) return 10800;
        return 0;
    }

    /**
     * @dev view function to get planets staked by user 
     * @param _user address of user
     */
    function getStakedPlanets(address _user)
        public
        view
        returns (uint256[] memory planetIds)
    {
        return stakers[_user].planetIds;
    }

    /**
     * @dev view function to get planet staked period in years 
     * @param _user address of user
     * @param _planetId id of planet
     */
    function getPlanetStakedPeriod(address _user, uint256 _planetId)
        public
        view
        returns (uint256)
    {
        return stakers[_user].planetPeriods[_planetId];
    }

    /**
     * @dev view function to get release date in timestamp 
     * @param _user address of user
     * @param _planetId id of planet
     */
    function getStakedPlanetReleaseDate(address _user, uint256 _planetId)
        public
        view
        returns (uint256)
    {
        return stakers[_user].planetStakingReleaseDate[_planetId];
    }

    /**
     * @dev public function to stake planet 
     * @dev this contract needs to have access to transfer your Planets from your wallet to staking contract 
     * @param _planetId id of planet
     * @param _nbYears period of staking in years
     */
    function stake(uint256 _planetId, uint8 _nbYears) public {
        _stake(msg.sender, _planetId, _nbYears);
    }

    /**
     * @dev public function to stake multiple planets 
     * @dev this contract needs to have access to transfer your Planets from your wallet to staking contract 
     * @param _planetIds array of planets id 
     * @param _nbYears period of staking in years
     */
    function stakeBatch(uint256[] memory _planetIds, uint8 _nbYears) public {
        for (uint256 i = 0; i < _planetIds.length; i++) {
            stake(_planetIds[i], _nbYears);
        }
    }

    /**
     * @dev internal function to stake planet
     * @dev this contract needs to have access to transfer your Planets from your wallet to staking contract 
     * @param _user array of planets id 
     * @param _planetId id of planet
     * @param _nbYears period of staking in years
     */
    function _stake(address _user, uint256 _planetId, uint8 _nbYears) internal {
        require(allowStaking, "LIFPS: the new stake is blocked by the admin");
        require(
            planetContract.ownerOf(_planetId) == _user,
            "LIFPS: user must be the owner of the planet"
        );
        require(
            getRewarding(_nbYears) > 0,
            "LIFPS: you can not stake under one year or above 3 years"
        );
        Staker storage staker = stakers[_user];

        staker.planetIds.push(_planetId);
        staker.planetStakingReleaseDate[_planetId] = block.timestamp + (_nbYears * YEARTIME);
        staker.planetPeriods[_planetId] = _nbYears;
        planetOwner[_planetId] = _user;
        planetContract.transferFrom(_user, address(this), _planetId);
        totalRewardSupply += getRewarding(_nbYears);

        emit Staked(_user, _planetId);
    }

    /**
     * @dev public function to unstake planet and claim rewards
     * @param _planetId id of planet
     */
    function unstake(uint256 _planetId) public {
        require(
            planetOwner[_planetId] == msg.sender,
            "LIFPS: user must be the owner of the staked planet"
        );
        _unstake(planetOwner[_planetId], planetOwner[_planetId], _planetId);
    }

    /**
     * @dev public function to unstake mutiple planets and claim rewards
     * @param _planetIds array of planets id 
     */
    function unstakeBatch(uint256[] memory _planetIds) public {
        for (uint256 i = 0; i < _planetIds.length; i++) {
            if (planetOwner[_planetIds[i]] == msg.sender) {
                unstake(_planetIds[i]);
            }
        }
    }

    /**
     * @dev internal function to unstake planet and give rewards
     * @dev internal function can be called only by this contract
     * @dev user ownership is check in calling function (public function unstake)
     * @param _user address of user 
     * @param _transferTo address to transfer planet and rewards  
     * @param _planetId id of planet to unstake 
     */
    function _unstake(address _user, address _transferTo, uint256 _planetId) internal {
        Staker storage staker = stakers[_user];
        require(
            block.timestamp > staker.planetStakingReleaseDate[_planetId],
            "LIFPS: cooldown not complete"
        );

        for (uint256 i; i<staker.planetIds.length; i++) {
            if (staker.planetIds[i] == _planetId) {
                staker.planetIds[i] = staker.planetIds[staker.planetIds.length - 1];
                staker.planetIds.pop();
                break;
            }
        }
        delete planetOwner[_planetId];
        totalRewardSupply -= getRewarding(staker.planetPeriods[_planetId]);

        planetContract.safeTransferFrom(address(this), _transferTo, _planetId);
        
        if (rewardTokenContract != IRewardToken(address(0)) ) {
            rewardTokenContract.sendRewards(_transferTo, getRewarding(staker.planetPeriods[_planetId]));
        }
        emit Unstaked(_transferTo, _planetId);
    }

    /**
     * @dev onlyOwner function to unstake lost planet
     * @dev planet not claimed within one year after release date
     * @param _planetId id of planet lost  
     */
    function unstakeLost(uint256 _planetId) public onlyOwner {
        address user = planetOwner[_planetId];
        Staker storage staker = stakers[user];
        require(
            block.timestamp > staker.planetStakingReleaseDate[_planetId] + 365 days,
            "LIFPS: this Planet is not yet considered lost"
        );
        _unstake(user, msg.sender, _planetId);
    }

    /**
     * @dev onlyOwner function to disable new Staker
     * @param _allow boolean true to enable and false to disable 
     */
    function setAllowStaking(bool _allow) public onlyOwner {
        allowStaking = _allow;
    }

    /**
     * @dev onlyOwner function to set address of reward contract
     * @dev when LIFC is listed and reward contract is implemented
     * @param _rewardContractAddress address of reward contract  
     */
    function setRewardContract(IRewardToken _rewardContractAddress) public onlyOwner {
        rewardTokenContract = _rewardContractAddress;
    }
}