//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";


// This is the main building block for smart contracts.
contract DogBossBridgeBNB is Ownable, ReentrancyGuard {
    using Address for address;
    using SafeERC20 for IERC20;

    // DogBoss token address
    IERC20 public tokenAddress;

    address public backendSrv;
    address public treasury;
    uint256 public bridgeFee;
    bool public paused;

    // The Transfer event helps off-chain applications understand
    // what happens within your contract.
    event Deposit(address indexed _from, address indexed _to, uint256 _value, uint256 _chainId);

    /**
     * Contract initialization.
     */
    constructor(
        address dogbossTokenAddress,
        address _backendSrv,
        address _treasury,
        uint256 fee
    ) {
        tokenAddress = IERC20(dogbossTokenAddress);
        backendSrv = _backendSrv;
        treasury = _treasury;
        bridgeFee = fee; // 5% = 50, 100% = 1000
    }

    modifier onlyBackend() {
        require(msg.sender == backendSrv, "DogBossBridgeBNB: caller is not the backend srv");
        _;
    }

    modifier notPaused() {
        require(!paused, "Bridge is paused");
        _;        
    }

    function pauseBrigde() external onlyOwner {
      paused = !paused;
    }

    /**
     * Change bridge fee
     */
    function changeFee(uint256 fee) external onlyOwner {
        bridgeFee = fee;
    }

    /**
     * Update treasury
     */
    function updateTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    /**
     * send BEP20 to escrow
     *
     */
    function deposit(address to, uint256 amount, uint256 chainID) external nonReentrant notPaused {
        require(amount != 0, "Escrow amount cannot be equal to 0.");

        uint256 treasuryAmount = amount * bridgeFee / 1000;

        uint256 remainAmount = amount - treasuryAmount;

        uint256 allowance = tokenAddress.allowance(msg.sender, address(this));
    
        require(allowance >= amount, "Check the token allowance");

        tokenAddress.transferFrom(msg.sender, address(this), remainAmount);

        tokenAddress.transferFrom(msg.sender, treasury, treasuryAmount);

        // Notify off-chain applications of the transfer.
        emit Deposit(msg.sender, to, amount, chainID);
    }

    /**
     * Withdraw from escrow
     */
    function withdraw(address receiver, uint256 amount) external onlyBackend notPaused{
        require(amount != 0, "Withdraw amount should be bigger than 0.");

        uint256 bridgeAmount = amount - amount * bridgeFee / 1000;

        // withdraw token from escrow account
        tokenAddress.transfer(receiver, bridgeAmount);
    }

    function emergencyWithdrawToken(address _token, address _to, uint256 amount) external onlyOwner {
        IERC20(_token).transfer(_to, amount);
    }

    function emergencyWithdrawETH(address _to, uint256 amount) external onlyOwner {
        Address.sendValue(payable(_to), amount);
    }
}