// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Heir {

    address private constant wETHAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // wETH 컨트랙트 주소

    struct Deposit {
        address depositor;
        uint256 amount;
        uint256 unlockTime;
    }

    mapping(address => Deposit) public deposits;

    event DepositMade(address indexed depositor, uint256 amount, uint256 unlockTime);
    event WithdrawalMade(address indexed recipient, uint256 amount, uint256 timestamp);
    event UnlockTimeExtended(address indexed recipient, uint256 newUnlockTime);
    event TransferOwnership(address indexed currentOwner, address indexed newOwner);

    address private owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit(uint256 amount, uint256 unlockTime) external {
        require(unlockTime > block.timestamp, "Unlock time must be in the future");

        IERC20 wETH = IERC20(wETHAddress);
        require(wETH.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        Deposit memory newDeposit = Deposit(msg.sender, amount, unlockTime);
        deposits[msg.sender] = newDeposit;

        emit DepositMade(msg.sender, amount, unlockTime);
    }

    function withdraw() external {
        Deposit memory depositorDeposit = deposits[msg.sender];
        require(depositorDeposit.amount > 0, "No deposit found");
        require(block.timestamp >= depositorDeposit.unlockTime, "Withdrawal not yet available");

        IERC20 wETH = IERC20(wETHAddress);
        require(wETH.transfer(msg.sender, depositorDeposit.amount), "Transfer failed");

        emit WithdrawalMade(msg.sender, depositorDeposit.amount, block.timestamp);

        delete deposits[msg.sender];
    }

    function extendUnlockTime(uint256 newUnlockTime) external {
        Deposit storage depositorDeposit = deposits[msg.sender];
        require(depositorDeposit.amount > 0, "No deposit found");
        require(newUnlockTime > depositorDeposit.unlockTime, "New unlock time must be later than the current unlock time");

        depositorDeposit.unlockTime = newUnlockTime;

        emit UnlockTimeExtended(msg.sender, newUnlockTime);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        emit TransferOwnership(owner, newOwner);
        owner = newOwner;
    }
}