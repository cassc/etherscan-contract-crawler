/**
 *Submitted for verification at Etherscan.io on 2023-10-11
*/

pragma solidity >=0.8.2 <0.9.0;

/// @param v Part of the ECDSA signature
/// @param r Part of the ECDSA signature
/// @param s Part of the ECDSA signature
/// @param request Identifier for verifying the packet is what is desired
/// , rather than a packet for some other function/contract
/// @param deadline The Unix timestamp (in seconds) after which the packet
/// should be rejected by the contract
/// @param payload The payload of the packet
struct TrustusPacket {
    uint8 v;
    bytes32 r;
    bytes32 s;
    bytes32 request;
    uint256 deadline;
    bytes payload;
}

// Define the DustSweeper contract interface
interface DustSweeper {
    function sweepDust(address[] calldata makers, address[] calldata tokenAddresses, TrustusPacket calldata packet) external payable;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract TakerBot {
    address public constant DUSTSWEEPER_ADDRESS = 0x78106f7db3EbCEe3D2CFAC647f0E4c9b06683B39;
    address public constant ONE_INCH_ROUTER = 0x1111111254EEB25477B68fb85Ed929f73A960582;

    receive() external payable {}
    mapping(address => mapping(address => bool)) public isApproved;

    address public owner;
    address public futureOwner;

    constructor() {
        owner = msg.sender;
    }

    /// @notice Modifier to ensure that only the owner can call a function
    modifier onlyOwner() {
      require(msg.sender == owner, "Only the owner can call this function");
      _;
    }

    /// @notice Compare the current balance of the contract with the balance
    /// of the specified token address, and if the balance is greater than 0,
    /// swap the token for ETH using 1inch
    /// @param tokenAddress The address of the token to swap
    /// @param oneinchData The 1inch call data for the token
    /// @return Whether the swap was successful
    function compareAndSwap(address tokenAddress, bytes calldata oneinchData) private returns (bool) {
        uint256 amount = IERC20(tokenAddress).balanceOf(address(this));
        
        if (amount > 0) {
            // Make sure the router is approved to transfer the coin
            if (!isApproved[ONE_INCH_ROUTER][tokenAddress]) {
                // Check the current allowance of the router contract for the token
                uint256 currentAllowance = IERC20(tokenAddress).allowance(address(this), ONE_INCH_ROUTER);

                if (currentAllowance < amount) {
                    // Approve the router contract to spend the required amount of tokens
                    bool approvalSuccess = IERC20(tokenAddress).approve(ONE_INCH_ROUTER, amount);
                    require(approvalSuccess, "Approval failed");
                }

                isApproved[ONE_INCH_ROUTER][tokenAddress] = true;
            }

             (bool swapSuccess,) = ONE_INCH_ROUTER.call{value: 0}(
                oneinchData
            );
            require(swapSuccess, "1INCH_SWAP_FAIL");
      }

        return true;
    }

    /// @notice Run a sweep of the specified token addresses
    /// @param makers The addresses of the makers to sweep
    /// @param tokenAddresses The addresses of the tokens to sweep
    /// @param packet The packet to verify
    /// @param uniqueTokenAddresses The addresses of the unique tokens to swap
    /// @param oneinchCallDataByToken The 1inch call data for each token
    function runSweep(
      address[] calldata makers,
      address[] calldata tokenAddresses,
      TrustusPacket calldata packet,
      address[] calldata uniqueTokenAddresses,
      bytes[] calldata oneinchCallDataByToken
    ) public payable {
        DustSweeper dustSweeper = DustSweeper(DUSTSWEEPER_ADDRESS);

        // Call the sweepDust function on the DustSweeper contract
        dustSweeper.sweepDust{value: msg.value}(makers, tokenAddresses, packet);


        // Iterate through token addresses and call compare_and_swap
        for (uint256 i = 0; i < uniqueTokenAddresses.length; i++) {
          compareAndSwap(uniqueTokenAddresses[i], oneinchCallDataByToken[i]);
        }
    }
    
    /// @notice Transfer ownership of the contract to a new address
    /// @param _futureOwner The address of the new owner
    function commitOwnershipTransfer(address _futureOwner) external onlyOwner returns (bool) {
        futureOwner = _futureOwner;
        return true;
    }

    /// @notice Accept ownership of the contract
    function acceptOwnershipTransfer() external returns (bool) {
        require(msg.sender == futureOwner, "Only the future owner can accept ownership transfer");
        owner = msg.sender;
        return true;
    }

    /// @notice Payout the ETH balance of the contract to the owner
    function payoutEth() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}