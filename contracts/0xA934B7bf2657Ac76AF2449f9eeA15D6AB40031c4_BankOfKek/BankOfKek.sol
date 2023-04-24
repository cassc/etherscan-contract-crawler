/**
 *Submitted for verification at Etherscan.io on 2023-04-24
*/

pragma solidity ^0.8.0;

//SPDX-License-Identifier: Unlicensed

/**
 * ERC20 standard interface.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * Allows for contract ownership along with multi-address authorization
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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

contract BankOfKek is Ownable {
    address public immutable kek_address = 0xE62cA71C56fa13717925d7600C10B29089dE2E00; 

    address public immutable cSigner = 0x06B417d938c3e8eD3e82c1f378A5578110097261;
    IERC20 private kek_contract; 

    uint256 public deadline;

    mapping (address => uint256) private claimed;

    constructor () {
        kek_contract = IERC20(kek_address);

        deadline = block.timestamp + 7 days;

    }

    function claimedBalanceOf (address holder) public view returns (uint256) {
        return claimed[holder];
    }

    function withdraw() external onlyOwner {
        require (block.timestamp > deadline);
        uint256 kekBalance = kek_contract.balanceOf(address(this));
        kek_contract.transfer(_msgSender(), kekBalance);
    }

    function claim(uint256 amount, uint8 v, bytes32 r, bytes32 s) external  {
        require(claimedBalanceOf(msg.sender) == 0, "BankOfKek: Already claimed");
        bytes32 _hashedMessage = keccak256(abi.encodePacked(msg.sender,"-",amount));
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));      
        require(ecrecover(prefixedHashMessage, v, r, s) == cSigner, "BankOfKek: Invalid signer");
        claimed[msg.sender] = amount;
        kek_contract.transfer(_msgSender(), amount);       
    }

   
}