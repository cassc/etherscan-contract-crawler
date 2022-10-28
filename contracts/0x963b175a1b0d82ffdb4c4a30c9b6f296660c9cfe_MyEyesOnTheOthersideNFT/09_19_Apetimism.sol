pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Apetimism is Context {
    address private _apetimismAddress;
    uint256 private _apetimismFee = 500;
    uint256 public totalRevenueShared = 0;

    event ApetimismAddressTransferred(address indexed previousAddress, address indexed newAddress);

    /**
     * @dev Initializes the contract setting the initial apetimism address.
     */
    constructor(address _address, uint256 _fee) {
        _transferApetimism(_address);
        _apetimismFee = _fee;
    }

    /**
     * @dev Throws if called by any account other than the apetimism address.
     */
    modifier onlyApetimism() {
        _checkApetimismAddress();
        _;
    }

    /**
     * @dev Returns the address of the current apetimism address.
     */
    function apetimismAddress() public view virtual returns (address) {
        return _apetimismAddress;
    }

    /**
     * @dev Throws if the sender is not the apetimism address.
     */
    function _checkApetimismAddress() internal view virtual {
        require(apetimismAddress() == _msgSender(), "Apetimism: caller is not the apetimism address");
    }

    /**
     * @dev Leaves the contract without apetimism address. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current apetimism address.
     */
    function renounceApetimism() public virtual onlyApetimism {
        _transferApetimism(address(0));
    }

    /**
     * @dev Transfers apetimism address of the contract to a new address (`newAddress`).
     * Can only be called by the current apetimism address.
     */
    function transferApetimism(address newAddress) public virtual onlyApetimism {
        require(newAddress != address(0), "Apetimism: new address is the zero address");
        _transferApetimism(newAddress);
    }

    /**
     * @dev Transfers apetimism address of the contract to a new address (`newAddress`).
     * Internal function without access restriction.
     */
    function _transferApetimism(address newAddress) internal virtual {
        address oldAddress = _apetimismAddress;
        _apetimismAddress = newAddress;
        emit ApetimismAddressTransferred(oldAddress, newAddress);
    }

    function apetimismFee() public view virtual returns (uint256) {
        return _apetimismFee;
    }

    function setApetimismFee(uint256 newFee) public onlyApetimism {
      _apetimismFee = newFee;
    }
}