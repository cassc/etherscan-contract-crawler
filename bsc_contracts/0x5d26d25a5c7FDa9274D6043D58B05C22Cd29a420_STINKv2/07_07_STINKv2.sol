// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./interfaces/IUniswap.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract STINKv2 is ERC20, Ownable {
    // Mapping of addresses that are tax exempt
    mapping(address => bool) public taxExempt;
    // Mapping of addresses that are pairs
    mapping(address => bool) public pair;

    // Tax Related Wallets
    address public marketing;
    address public vault; // This address holds the STINKv2 tokens for staking
    address public liquidityVault; // This address holds the liquidity tokens

    uint public liquidityFee; // Amount collected that belongs to liquidity
    uint public marketingFee; // Amount collected that belongs to marketing

    uint public sellThreshold; // Amount of tokens needed in collection to trigger a swap

    uint public totalLiquidity; // total liquidity tokens created and sent to liquidity vault
    uint public totalStaking; // total STINKv2 tokens sent to staking vault
    uint public totalMarketing; // total ETH sent to marketing wallet

    // Taxes are: Marketing, Liquidity, Staking
    uint8[3] public buyTaxes = [1, 1, 1];
    uint8[3] public sellTaxes = [2, 1, 3];

    IUniswapV2Router02 public router; // PancakeSwap Router
    IUniswapV2Pair public mainPair; // Main pair for the token STINKv2 / BNB

    bool public swapping = false; // Prevents reentrancy

    event SwapAndLiquify(
        uint tokensSwapped,
        uint ethReceived,
        uint tokensIntoLiqudity
    );

    /// @notice Locks the contract for a single tx
    modifier lockTheSwap() {
        swapping = true;
        _;
        swapping = false;
    }

    constructor(
        address _marketing,
        address _vault,
        address _liquidityVault
    ) ERC20("STINKv2", "STINKv2") {
        _mint(msg.sender, 1_000_000_000 ether);
        sellThreshold = 100 ether;
        // SET DEFAULT INIT PAIR
        router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        IUniswapV2Factory pancakeFactory = IUniswapV2Factory(router.factory());
        address bnbPair = pancakeFactory.createPair(
            address(this),
            router.WETH()
        );
        mainPair = IUniswapV2Pair(bnbPair);
        pair[bnbPair] = true;

        taxExempt[msg.sender] = true;
        marketing = _marketing;
        vault = _vault;
        liquidityVault = _liquidityVault;
    }

    /// @notice Allowed to receive ETH
    receive() external payable {}

    /// @notice Execute transfer, if enought tokens, swap and distribute fes
    /// @param sender Sender address
    /// @param recipient Recipient address
    /// @param amount Amount of tokens to transfer
    /// @dev Override ERC20 transfer function
    /// @dev If the sender is not tax exempt, calculate the fees, substract from amount and transfer staking fee to vault
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        uint balance = balanceOf(address(this));
        // Cant distribute Fees on a BUY transaction
        if (balance > sellThreshold && !swapping && !pair[sender]) {
            distributeFees(balance);
        }

        if (swapping || taxExempt[sender] || taxExempt[recipient]) {
            super._transfer(sender, recipient, amount);
        } else {
            uint fees = getFees(sender, recipient, amount);
            amount -= fees;
            super._transfer(sender, recipient, amount);
        }
    }

    /// @notice Manually distribute fees
    /// @dev This function is to be called by anyone to distribute fees if they feel fees aren't being distributed
    function manualDistribute() external {
        uint balance = balanceOf(address(this));
        distributeFees(balance);
    }

    /// @notice Creates liquidity from current balance and sends ETH to marketing wallet
    /// @param amount Amount of tokens to swap
    /// @dev We always use the total amount of fees collected, if the amount is different, we calculate the percentage
    /// @dev we first create liquidity to stregthen the pool, then swap marketing for ETH and send to marketing wallet
    function distributeFees(uint amount) private lockTheSwap {
        uint totalFees = marketingFee + liquidityFee;

        uint mkt = marketingFee;
        uint liq = liquidityFee;

        if (totalFees != amount) {
            mkt = (marketingFee * amount) / totalFees;
            liq = amount - mkt;
        }
        if (liq > 0) {
            _swapAndLiquify(liq);
            liq = 0; // reset just in case
            liquidityFee = 0;
        }
        if (mkt > 0) {
            _swapForEth(mkt);
            liq = address(this).balance;
            totalMarketing += address(this).balance;
            marketingFee = 0;
        }
        // Send ETH to marketing wallet
        if (liq > 0) {
            (bool succ, ) = payable(marketing).call{
                value: address(this).balance
            }("");
            require(succ, "Marketing transfer failed");
        }
    }

    /// @notice Swap half tokens for ETH and create liquidity internally
    /// @param tokens Amount of tokens to swap
    /// @dev Please note that actual liquidity created vs amount allocated to liquidity vault is not 1:1 due to fees on creating liquidity
    function _swapAndLiquify(uint tokens) private {
        uint half = tokens / 2;
        uint otherHalf = tokens - half;

        uint initialBalance = address(this).balance;

        _swapForEth(half);

        uint newBalance = address(this).balance - initialBalance;

        _approve(address(this), address(router), otherHalf);
        (, , uint liquidity) = router.addLiquidityETH{value: newBalance}(
            address(this),
            otherHalf,
            0,
            0,
            liquidityVault,
            block.timestamp
        );

        totalLiquidity += liquidity;

        emit SwapAndLiquify(half, newBalance, liquidity);
    }

    /// @notice Swap tokens for ETH
    function _swapForEth(uint tokens) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokens);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokens,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    /// @notice Calculate fees for a transaction
    /// @param sender Sender address
    /// @param recipient Recipient address
    /// @param amount Amount of tokens to transfer
    /// @dev by determining wether the transaction is a buy or sell, we can apply the correct taxes
    function getFees(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint totalFee) {
        uint mktFee;
        uint liqFee;
        uint stakingFee;
        // BUY transaction
        if (pair[sender]) {
            mktFee += (amount * buyTaxes[0]) / 100;
            liqFee += (amount * buyTaxes[1]) / 100;
            stakingFee += (amount * buyTaxes[2]) / 100;
            totalFee = mktFee + liqFee + stakingFee;
            marketingFee += mktFee;
            liquidityFee += liqFee;
            totalStaking += stakingFee;
            super._transfer(sender, vault, stakingFee);
            super._transfer(sender, address(this), mktFee + liqFee);
        }
        // SELL transaction
        else if (pair[recipient]) {
            mktFee += (amount * sellTaxes[0]) / 100;
            liqFee += (amount * sellTaxes[1]) / 100;
            stakingFee += (amount * sellTaxes[2]) / 100;
            totalFee = mktFee + liqFee + stakingFee;
            marketingFee += mktFee;
            liquidityFee += liqFee;
            super._transfer(sender, address(this), mktFee + liqFee);
            super._transfer(sender, vault, stakingFee);
        }
        // DO NOTHING IF NONE
        else return 0;
    }

    /// @notice BURN tokens (Reduces total supply and removes tokens from circulation)
    /// @param amount amount of tokens to BURN
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /// @notice BURN tokens from another account (Reduces total supply and removes tokens from circulation)
    /// @param account account to burn tokens from
    /// @param amount amount of tokens to BURN
    function burnFrom(address account, uint256 amount) external {
        uint allowed = allowance(account, msg.sender);
        require(amount <= allowed, "STINKv2: Not enough allowance");
        uint256 decreasedAllowance = allowed - amount;
        _approve(account, msg.sender, decreasedAllowance);
        _burn(account, amount);
    }

    /// @notice Set Exempt status for a single address
    /// @param account Address to set exempt status for
    /// @param exempt Exempt status (True = exempt, False = not exempt)
    /// @dev only OWNER of contract can set exempt status
    function setTaxExempt(address account, bool exempt) external onlyOwner {
        require(account != address(0), "STINKv2: zero address");
        taxExempt[account] = exempt;
    }

    /// @notice Set the marketing wallet address
    /// @param account Address of the marketing wallet
    /// @dev only OWNER of contract can set marketing wallet address
    function setMarketingWallet(address account) external onlyOwner {
        require(account != address(0), "STINKv2: zero address");
        marketing = account;
    }

    /// @notice Set the vault address
    /// @param account Address of the vault
    /// @dev only OWNER of contract can set vault address
    function setVaultAddress(address account) external onlyOwner {
        require(account != address(0), "STINKv2: zero address");
        vault = account;
    }

    /// @notice Set the liquidity vault address
    /// @param account Address of the liquidity vault
    /// @dev only OWNER of contract can set liquidity vault address
    function setLiquidityVaultAddress(address account) external onlyOwner {
        require(account != address(0), "STINKv2: zero address");
        liquidityVault = account;
    }

    ///@notice get tokens sent "mistakenly" to the contract
    ///@param _token Address of the token to be recovered
    function recoverToken(address _token) external {
        require(_token != address(this), "Cannot withdraw SELF");
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        require(IERC20(_token).transfer(marketing, balance), "Transfer failed");
    }

    /// @notice recover ETH sent to the contract
    function recoverETH() external {
        (bool succ, ) = payable(marketing).call{value: address(this).balance}(
            ""
        );
        require(succ, "ETH transfer failed");
    }

    /// @notice Set the threshold to trigger tax distribution
    /// @param _threshold Amount of tokens to trigger tax distribution
    /// @dev only OWNER of contract can set threshold and threshold should be lower than 1% of total supply
    function setThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold <= (totalSupply() * 1) / 100, "Threshold too high");
        sellThreshold = _threshold;
    }
}