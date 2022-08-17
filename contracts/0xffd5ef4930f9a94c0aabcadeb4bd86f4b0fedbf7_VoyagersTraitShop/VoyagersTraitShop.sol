/**
 *Submitted for verification at Etherscan.io on 2022-08-16
*/

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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/VoyagersTraitShop.sol



pragma solidity ^0.8.7;


interface IVoyagers {
    function ownerOf(uint256 tokenId) external view returns (address);
    function traitCount(uint256 traitType) external view returns (uint256);
    function awardTrait(uint256 tokenId, uint256 traitType, uint256 traitNumber) external;
    function spendPoints(uint256 tokenId, uint256 quantity) external;
    function getPoints(uint256 tokenId) external view returns (uint256);
}

contract VoyagersTraitShop is Ownable {

    address public voyagersContract = 0x4591c791790f352685a29111eca67Abdc878863E;

    uint256 public spaceCost = 1000000;
    uint256 public planetCost = 1000000;
    uint256 public shipCost = 1000000;
    uint256 public lightWeaponCost = 1000000;
    uint256 public heavyWeaponCost = 1000000;
    uint256 public roleCost = 1000000;

    // PURCHASE ---------------------------------------------

    function purchaseTrait(uint256 tokenId, uint256 traitType, uint256 traitNumber) public {
        require(IVoyagers(voyagersContract).ownerOf(tokenId) == msg.sender, "You do not own that token.");
        require(traitType > 0 && traitType <= 6, "Invalid trait type.");
        require(traitNumber > 0 && traitNumber <= IVoyagers(voyagersContract).traitCount(traitType), "Invalid trait number.");

        uint256 cost;

        if(traitType == 1) {
            require(spaceCost <= IVoyagers(voyagersContract).getPoints(tokenId), "You do not have enough points.");
            cost = spaceCost;
        } else if (traitType == 2) {
            require(planetCost <= IVoyagers(voyagersContract).getPoints(tokenId), "You do not have enough points.");
            cost = planetCost;
        } else if (traitType == 3) {
            require(shipCost <= IVoyagers(voyagersContract).getPoints(tokenId), "You do not have enough points.");
            cost = shipCost;
        } else if (traitType == 4) {
            require(lightWeaponCost <= IVoyagers(voyagersContract).getPoints(tokenId), "You do not have enough points.");
            cost = lightWeaponCost;
        } else if (traitType == 5) {
            require(heavyWeaponCost <= IVoyagers(voyagersContract).getPoints(tokenId), "You do not have enough points.");
            cost = heavyWeaponCost;
        } else if (traitType == 6) {
            require(roleCost <= IVoyagers(voyagersContract).getPoints(tokenId), "You do not have enough points.");
            cost = roleCost;
        }

        IVoyagers(voyagersContract).spendPoints(tokenId, cost);
        IVoyagers(voyagersContract).awardTrait(tokenId, traitType, traitNumber);
    }

    // SHOP MANAGEMENT ---------------------------------------------

    function updatePrice(uint256 traitType, uint256 newCost) public onlyOwner {
        require(traitType > 0 && traitType <= 6, "Invalid trait type.");
        require(newCost > 0, "Cost must be greater than 0 points.");

        if(traitType == 1) {
            spaceCost = newCost;
        } else if (traitType == 2) {
            planetCost = newCost;
        } else if (traitType == 3) {
            shipCost = newCost;
        } else if (traitType == 4) {
            lightWeaponCost = newCost;
        } else if (traitType == 5) {
            heavyWeaponCost = newCost;
        } else if (traitType == 6) {
            roleCost = newCost;
        }
    }

    // CONTRACT MANAGEMENT ---------------------------------------------
  
    function setVoyagersContract(address _address) public onlyOwner {
        voyagersContract = _address;
    }

    // WITHDRAW ---------------------------------------------

    function withdraw() public onlyOwner {
      (bool success,) = msg.sender.call{value: address(this).balance}("");
      require(success, "Failed to withdraw ETH.");
  }
}