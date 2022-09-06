/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

// SPDX-License-Identifier: MIT
//**  Marketplace Contract trade by ETH */
//** Author Ishanshahzad: LooBr Marketplace Contract 2022.8 */

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


// File contracts/interfaces/IMRConfig.sol



pragma solidity ^0.8.0;

interface IMRConfig {
    function getRevenueAddress() external view returns (address);
    function getMrNftAddress() external view returns (address);
    function getRoyalityFeeRate() external view returns (uint256);
    function getMinDuration() external view returns (uint256);
    function getMaxDuration() external view returns (uint256);
}


// File contracts/MRConfig.sol



//** MR Config Contract */
//** Author ishanshahzad :  Config Contract 2022.4 */

pragma solidity ^0.8.0;


contract LoobrConfig is Ownable, IMRConfig {
    uint256 public constant FEE_RATE_BASE = 10000;

    uint256 public constant MAXIMUM_ROYALTIES_FEE_RATE = 5000;

    // The royalties fee rate
    uint256 public royaltiesFeeRate = 500;

    // The MR NFT contract address
    address public mrNftContractAddress;

    // the Revenue address
    address public revenueAddress;
    // The minimum duration
    uint256 public minDuration = 1 days;

    // The maximum duration
    uint256 public maxDuration = 7 days;

    event UpdatedRoyaltiesFeeRate(uint256 rate);
    event UpdatedMrNftContractAddress(address addr);
    event UpdatedRevenueAddress(address addr);
    event UpdatedMinDuration(uint256 duration);
    event UpdatedMaxDuration(uint256 duration);

    constructor(
        address _owner,
        address _revenueAddress
    ) {
        require(_owner != address(0), "Invalid owner address");
        _transferOwnership(_owner);

        require(_revenueAddress != address(0), "Invalid revenue address");
        revenueAddress = _revenueAddress;
    }

    function setRoyaltiesFeeRate(uint256 rate) external onlyOwner {
        require(rate <= MAXIMUM_ROYALTIES_FEE_RATE, "Invalid royalities fee rate");
        royaltiesFeeRate = rate;
        emit UpdatedRoyaltiesFeeRate(rate);
    }

    function setMrNftContractAddress(address _address) external onlyOwner {
        mrNftContractAddress = _address;
        emit UpdatedMrNftContractAddress(_address);
    }

    function setRevenueAddress(address _address) external onlyOwner {
        require(_address != address(0), "Invalid revenue address");
        revenueAddress = _address;
        emit UpdatedRevenueAddress(_address);
    }

    function setMinDuration(uint256 _duration) external onlyOwner {
        require(_duration > 0 && _duration < maxDuration, "Invalid minimum duration");
        minDuration = _duration;
        emit UpdatedMinDuration(_duration);
    }

    function setMaxDuration(uint256 _duration) external onlyOwner {
        require(_duration > minDuration, "Invalid maximum duration");

        maxDuration = _duration;
        emit UpdatedMaxDuration(_duration);
    }


    function getRevenueAddress() external view override returns (address) {
        return revenueAddress;
    }

    function getMrNftAddress() external view override returns (address) {
        return mrNftContractAddress;
    }

    function getRoyalityFeeRate() external view override returns (uint256) {
        return royaltiesFeeRate;
    }


    function getMinDuration() external view override returns (uint256) {
        return minDuration;
    }

    function getMaxDuration() external view override returns (uint256) {
        return maxDuration;
    }
}