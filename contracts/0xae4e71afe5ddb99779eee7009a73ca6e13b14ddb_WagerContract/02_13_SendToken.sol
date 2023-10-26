// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Importing required OpenZeppelin Contracts
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; // Standard ERC20 Token Implementation
import "@openzeppelin/contracts/access/Ownable.sol"; // Access Control Contract
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // Protection against reentrant calls
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol"; // Uniswap Router Interface for performing swaps
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol"; // Uniswap Pair Interface
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol"; // Uniswap Factory Interface 

contract SENDToken is ERC20, Ownable, ReentrancyGuard {
    // Buy and Sell Tax
    uint256 public constant BUY_TAX = 5;
    uint256 public constant SELL_TAX = 5;

    // Uniswap Router and Pair
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    // Array to hold all unique holders
    address[] public holders;
    mapping(address => bool) public isHolder;
    mapping(address => uint256) public holderIndex;

    // Immutable addresses for Team, Reserve Fund, Marketing, and Tax
    address public immutable teamAddress;
    address public immutable reserveFundAddress;
    address public immutable marketingAddress;
    address public immutable taxAddress;
    address public revenueDistributionAddress; // Address where the revenue will be distributed

     // Initialize the token and mint initial supply to specified addresses
constructor(
    address _initialOwner,
    address _teamAddress,
    address _reserveFundAddress,
    address _marketingAddress,
    address _taxAddress,
    address _uniswapV2Router
) ERC20("Sendpicks", "SEND") Ownable(_initialOwner) {
    uint256 totalSupply = 100_000_000 * 10**18; // Total Supply of 100 million tokens with 18 decimals
    
    // Immutable addresses
    teamAddress = _teamAddress;
    reserveFundAddress = _reserveFundAddress;
    marketingAddress = _marketingAddress;
    taxAddress = _taxAddress;

    // Minting the initial supply
    _mint(teamAddress, totalSupply * 5 / 100); // 5% to Team
    _mint(reserveFundAddress, totalSupply * 5 / 100); // 5% to Reserve Fund
    _mint(marketingAddress, totalSupply * 5 / 100); // 5% to Marketing
    _mint(msg.sender, totalSupply * 85 / 100); // 85% to the owner

    // Uniswap Router and creating a Uniswap Pair
   uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
   uniswapV2Pair = address(
       IUniswapV2Factory(IUniswapV2Router02(_uniswapV2Router).factory()).createPair(address(this), uniswapV2Router.WETH())
   );
}

// Function to set the address where the revenue will be distributed
function setRevenueDistributionAddress(address _revenueDistributionAddress) external onlyOwner {
    require(_revenueDistributionAddress != address(0), "Invalid address");
    revenueDistributionAddress = _revenueDistributionAddress;
}

    // Function to add liquidity to Uniswap Pair
    function addLiquidity(uint256 tokenAmount) external onlyOwner nonReentrant {
        _approve(address(this), address(uniswapV2Router), tokenAmount); // Approve tokens for Uniswap Router
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    // Function to allow users to swap tokens for ETH
    function swapTokensForEth(uint256 tokenAmount) external {
        require(balanceOf(msg.sender) >= tokenAmount, "Insufficient tokens"); // Ensure sender has enough tokens
        _approve(msg.sender, address(uniswapV2Router), tokenAmount); // Approve Uniswap Router to spend tokens
        
        // Specify the Path for the swap, from this token to WETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of ETH
            path,
            msg.sender, // Send ETH to the sender
            block.timestamp
        );
    }


    // Override the _update function to include tax and maintain the holders list
    function _update(address from, address to, uint256 value) internal virtual override {
        uint256 taxAmount = 0;
        bool isExempt = _isExempt(from, to); // Check if the transfer is exempt from tax
        
        if (!isExempt) {
            // Determine tax amount based on whether it's a buy or sell
            if (to == uniswapV2Pair) {
                taxAmount = value * SELL_TAX / 100; // Sell Tax
            } else if (from == uniswapV2Pair) {
                taxAmount = value * BUY_TAX / 100; // Buy Tax
            }
            
            if (taxAmount > 0) {
                // Distributing tax
                uint256 amountAfterTax = value - taxAmount;
                uint256 revenueAmount = taxAmount * 2 / 100; // 2% of tax to Revenue Distribution
                uint256 remainingTax = taxAmount - revenueAmount; // Remaining tax to the Tax Address

                // Execute transfers
                super._update(from, revenueDistributionAddress, revenueAmount);
                super._update(from, taxAddress, remainingTax);
                super._update(from, to, amountAfterTax);

                // Manage Holders List
                _addHolder(from);
                _addHolder(to);
                if (balanceOf(from) == 0) _removeHolder(from);

                return;
            }
        }
        
        // If no tax or exempt, perform normal transfer
        super._update(from, to, value);

        // Manage Holders List
        _addHolder(from);
        _addHolder(to);
        if (balanceOf(from) == 0) _removeHolder(from);
    }


    // Check if the transfer is exempt from tax
    function _isExempt(address sender, address recipient) internal view returns (bool) {
        return sender == teamAddress || sender == reserveFundAddress || sender == marketingAddress ||
       recipient == teamAddress || recipient == reserveFundAddress || recipient == marketingAddress;
    }


    // Add a holder to the holders list
    function _addHolder(address account) internal {
        if (!isHolder[account] && account != address(this) && account != address(0) && account != uniswapV2Pair) {
            isHolder[account] = true;
            holders.push(account);
            holderIndex[account] = holders.length - 1;
        }
    }

    // Remove a holder from the holders list
    function _removeHolder(address account) internal {
        if (isHolder[account]) {
            uint256 index = holderIndex[account];
            if (index < holders.length - 1) {
                holders[index] = holders[holders.length - 1];
                holderIndex[holders[index]] = index;
            }
            holders.pop();
            delete holderIndex[account];
            isHolder[account] = false;
        }
    }
}