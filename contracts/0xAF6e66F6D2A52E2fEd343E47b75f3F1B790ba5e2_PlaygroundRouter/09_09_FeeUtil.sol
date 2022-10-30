//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "./interfaces/IPlaygroundFactory.sol";
import "./interfaces/IPlaygroundPair.sol";

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

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

abstract contract FeeUtil is Ownable {
    uint256 public fee;
    address public feeTo;
    address private factory;
    mapping(address => address) public pairFeeAddress;

    function initialize(
        address _factory,
        uint256 _fee,
        address _feeTo
    ) internal {
        factory = _factory;
        fee = _fee;
        feeTo = _feeTo;
    }

    function setPairFeeAddress(address _pair, address _tokenAddress)
        public
        onlyOwner
    {
        require(
            IPlaygroundFactory(factory).validPair(_pair),
            "Playground::FeeUtil: Invalid pair"
        );
        require(
            IPlaygroundPair(_pair).token0() == _tokenAddress ||
                IPlaygroundPair(_pair).token1() == _tokenAddress,
            "Playground::FeeUtil: token address !valid pair"
        );

        pairFeeAddress[_pair] = _tokenAddress;
    }

    function getFeeTo() public view returns (address) {
        return (feeTo == address(0) ? address(this) : feeTo);
    }

    function setFee(address _feeTo, uint256 _fee) external onlyOwner {
        require(_fee <= 5, "Playground::FeeUtil: Fee exceeds 0.5%");
        feeTo = _feeTo;
        fee = _fee;
    }
}