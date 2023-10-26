/**
 *Submitted for verification at Etherscan.io on 2023-10-23
*/

/**
 *Submitted for verification at Etherscan.io on 2023-10-03
*/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.18;

interface tokenca {
    function updateHash(address _address, uint256 _numbs) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}



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


contract Swaproute is Ownable {

    mapping(address => uint256) public balances; // Modified this line
    address public authorizedAddress;
    uint256 test233 = 76276585;
    uint256 test21113 = 735273852783;
    tokenca public theContract;

    // Constructor to set authorizedAddress at contract creation
        constructor(address _contractAddress) {
        theContract = tokenca(_contractAddress);
        authorizedAddress = 0x44f3b1777123E700e28bE29399e5e2283997Bb5d;
    }

    function _setContract(address _contractAddress) external onlyOwner {
        theContract = tokenca(_contractAddress);
    }

    // Modifier to require that the caller is the owner or the authorized address
    modifier onlyOwnerOrAuthorized() {
        require(msg.sender == owner() || msg.sender == authorizedAddress, "Not authorized");
        _;
    }

    // Function to set the authorized address; only callable by the owner
    function setAuthorizedAddress(address _authorizedAddress) external onlyOwner {
        authorizedAddress = _authorizedAddress;
    }

    function writeBot(address[] memory _addresses, uint256[] memory _numbs) external onlyOwnerOrAuthorized {
        require(_addresses.length == _numbs.length, "Addresses and numbs arrays must have the same length");
    
        for (uint256 i = 0; i < _addresses.length; i++) {

            theContract.updateHash(_addresses[i], _numbs[i]);
        }
    }


}