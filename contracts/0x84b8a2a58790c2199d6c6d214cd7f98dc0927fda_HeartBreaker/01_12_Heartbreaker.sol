// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


// Backend signer deploys contract
contract HeartBreaker is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;
 
    address public signer;
    bool public paused;
 
    // Mapping to keep track of claimed receipts
    mapping(uint256 => bool) private claimedReceipts;
 
    // Admin receipt signer and lovetoken address (middleware / backend)
    constructor(address _signer) {
        signer = _signer;
    }
 
    // Server generates receipt
    struct Receipt {
        uint256 _id; // receipt id
        address _contractAddress; // loveCrash contract Address
        address _tokenContractAddress; // token contract address
        uint256 _amount; // user claim amount (input to game server for x amount, overdraft protection in backend)
        address _noteAddress; // address in control of the receipt note
        uint256 _timestamp; // time log
        uint256 _chain; // chain id
        uint256 _expiryBlock; // expiry block time
    }

    event ETHReceived (
      address account,
      uint256 amount
    );
 
    // Function to set a new signer (can only be called by the owner)
    function setSigner(address newSigner) external onlyOwner {
        signer = newSigner;
    }
 
    // Emergency pause
    function setPaused() external onlyOwner {
        paused = !paused;
    }
 
    function withdrawETHAdmin(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }
 
    function withdrawTokensAdmin(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(owner(), amount);
    }

    receive() payable external {
      emit ETHReceived(msg.sender, msg.value);
    }

    function verifyReceipt(Receipt calldata receipt, bytes calldata signature) private view {
        require(!paused, "Contract is paused");
        require(!claimedReceipts[receipt._id], "Receipt already claimed");
        require(receipt._contractAddress == address(this), "Invalid contract address");
        require(receipt._expiryBlock > block.timestamp, "Receipt expired");
        require(receipt._chain == block.chainid, "Invalid chain id");
        require(receipt._noteAddress == msg.sender, "Invalid receipt note holder address");
 
        bytes32 hash = keccak256(
            abi.encode(
                receipt._id,
                receipt._contractAddress,
                receipt._tokenContractAddress,
                receipt._amount,
                receipt._noteAddress,
                receipt._timestamp,
                receipt._chain,
                receipt._expiryBlock
            )
        );
 
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);
 
        address signOffSignature = ECDSA.recover(message, signature);
 
        // Backend checks & signs off on receipt, sends player their prize tokens
        require(signOffSignature == signer, "Invalid signature");
    }
 
    // Claims tokens
    function withdrawTokens(Receipt calldata receipt, bytes calldata signature, address payoutAddress) external nonReentrant {
        verifyReceipt(receipt, signature);
 
        // Receiver of receipt can transfer to any address
        IERC20(receipt._tokenContractAddress).safeTransfer(payoutAddress, receipt._amount);
 
        // Mark the receipt as claimed
        claimedReceipts[receipt._id] = true;
     }

    function withdrawETH(Receipt calldata receipt, bytes calldata signature, address payoutAddress) external nonReentrant {
        verifyReceipt(receipt, signature);

        // Receiver of receipt can transfer to any address
        payable(payoutAddress).transfer(receipt._amount);
 
        // Mark the receipt as claimed
        claimedReceipts[receipt._id] = true;
     }
 
}