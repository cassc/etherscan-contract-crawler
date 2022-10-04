/**
 *Submitted for verification at BscScan.com on 2022-10-04
*/

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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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

// File: UpgradeStarOrb.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;




interface IERC721 {
	function ownerOf(uint256 tokenId) external view returns (address owner);
	
	function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IHolyPackage is IERC721 {
    struct Package {
        string holyType;
        uint256 createdAt;
    }

    function getPackage(uint256 _packageId) external returns (Package memory);
}

interface IOrb {
    struct Orb {
        uint8 star;
        uint8 rarity;
        uint8 classType;
        uint256 bornAt;
    }
}

interface IOrbNFT is IERC721, IOrb {
	function getOrb(uint256 _tokenId) external view returns (Orb memory);

    function updateStar(uint256 _orbId, uint8 _newStar) external;
}

interface IBEP20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract UpgradeStarOrb is IOrb, Ownable, Pausable {
    IOrbNFT public orbNft;

    IHolyPackage public holyPackage;

    struct Requirement {
        address token;
        uint256[] tokenRequire;
        uint8 holyPackageRequire;
        uint8[] successPercents;
    }

    mapping (uint8 => Requirement) requirements;

    event StarUpgrade(uint256 orbId, uint8 newStar, bool isSuccess);
        
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    address public feeAddress = 0x81F403fE697CfcF2c21C019bD546C6b36370458c;

    uint nonce = 0;

    mapping (uint256 => uint8) records;

    constructor(address _orbNft, address _holyPackage, address _feeAddress) {
        orbNft = IOrbNFT(_orbNft);
        holyPackage = IHolyPackage(_holyPackage);
        feeAddress = _feeAddress;
    }

    function upgradeStar(uint256 _orbId, uint256[] memory _holyPackageIds) external whenNotPaused {
        require(orbNft.ownerOf(_orbId) == _msgSender(), "require: must be owner");
        Orb memory orb = orbNft.getOrb(_orbId);
        Requirement memory requirement = requirements[orb.star];
        uint256 length = _holyPackageIds.length;
        require(length == requirement.holyPackageRequire, "require: number of holy packages not correct");
        string memory requiredHolyType = getRequiredHolyType(orb.classType);
        for (uint256 i = 0; i < length; i++) {
            require(holyPackage.ownerOf(_holyPackageIds[i]) == _msgSender(), "require: must be owner of holies");
            require(compareStrings(holyPackage.getPackage(_holyPackageIds[i]).holyType, requiredHolyType), "require: wrong holy type");
        }
        IBEP20(requirement.token).transferFrom(_msgSender(), feeAddress, getFee(orb.star, orb.rarity));
        for (uint256 k = 0; k < length; k++) {
            holyPackage.transferFrom(_msgSender(), deadAddress, _holyPackageIds[k]);
        }
        uint8 upgradeTimes = records[_orbId] + 1;
        bool isSuccess = false;
        if (upgradeTimes == requirement.successPercents.length) {
            isSuccess = true;
        } else {
            isSuccess = randomUpgrade(requirement.successPercents[upgradeTimes - 1]);
        }
        if (isSuccess) {
            records[_orbId] = 0;
            uint8 newStar = orb.star + 1;
            orbNft.updateStar(_orbId, newStar);
            emit StarUpgrade(_orbId, newStar, true);
        } else {
            records[_orbId] = upgradeTimes;
            emit StarUpgrade(_orbId, orb.star, false);
        }
    }

    function randomUpgrade(uint8 _successPercent) internal returns (bool) {
        uint random = getRandomNumber();
        uint seed = random % 100;
        if (seed < _successPercent) {
            return true;
        }
        return false;
    }
    
    function getRandomNumber() internal returns (uint) {
        nonce += 1;
        return uint(keccak256(abi.encodePacked(nonce, msg.sender, blockhash(block.number - 1))));
    }

    function updateOrbNft(address _newAddress) external onlyOwner {
        orbNft = IOrbNFT(_newAddress);
    }

    function updateFeeAddress(address _newAddress) external onlyOwner {
        feeAddress = _newAddress;
    }

    function getRequirement(uint8 _currentStar) public view returns (Requirement memory) {
        return requirements[_currentStar];
    }

    function getNextSuccessPercent(uint256 _orbId) public view returns (uint8) {
        Orb memory orb = orbNft.getOrb(_orbId);
        Requirement memory requirement = requirements[orb.star];
        return requirement.successPercents[records[_orbId]];
    }

    function getRequiredHolyType(uint8 _classType) public view returns (string memory) {
        if (_classType == 1) {
            return "blue";
        } else if (_classType == 2) {
            return "red";
        } else if (_classType == 3) {
            return "yellow";
        } else {
            return "green";
        }
    }

    function setRequirement(uint8 _star, address _token, uint256[] memory _tokenRequire, uint8 _holyPackageRequire, uint8[] memory _successPercents) public onlyOwner {
        requirements[_star] = Requirement({
            token: _token,
            tokenRequire: _tokenRequire,
            holyPackageRequire: _holyPackageRequire,
            successPercents: _successPercents
        });
    }

    function updateHolyPackage(address _holyPackage) external onlyOwner {
        holyPackage = IHolyPackage(_holyPackage);
    }

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function getFee(uint8 _star, uint8 _rarity) public view returns (uint256) {
        Requirement memory requirement = requirements[_star];
        return requirement.tokenRequire[_rarity - 1];
    }
}