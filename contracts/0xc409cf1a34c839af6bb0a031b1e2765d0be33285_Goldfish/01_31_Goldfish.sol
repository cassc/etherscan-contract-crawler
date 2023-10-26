// SPDX-License-Identifier: NONE
pragma solidity ^0.8.18;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IUniV3/IPosMgr.sol";
//import "./V3/NonfungiblePositionManager.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "hardhat/console.sol";

contract Goldfish is ERC20, ERC20Permit, Ownable {

    struct FlagData {
        bool isBlocklisted;
        bool isExcluded;
    }
    struct TickData {
        int24 minTick;
        int24 maxTick;
        uint24 fee;
    }
    string private constant _name = "Goldfish";
    string private constant _symbol = "FISH";
    // Standard decimals
    uint8 private constant _decimals = 18;
    uint256 private constant totalTokens = 1000000000000000000000000000000;

    uint32 private maxTxDivisor;
    uint32 private maxWalletDivisor;
    bool private tradingOpen = false;
    bool private blocklistEnabled = true;
    bool private limitsEnabled = true;
    mapping(address => FlagData) private flags;
    
    address private defaultLPPool;
    address private constant nonfungposman = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    
    constructor(uint32 maxWalletDiv, uint32 maxTxDiv) ERC20(_name, _symbol) ERC20Permit(_name) {
        // Do the initial token mint
        flags[_msgSender()] = FlagData({isBlocklisted: false, isExcluded: true});
        flags[address(this)] = FlagData({isBlocklisted: false, isExcluded: true});
        maxTxDivisor = maxTxDiv;
        maxWalletDivisor = maxWalletDiv;
        // only time we call mint...
        _mint(_msgSender(), totalTokens);

    }

    receive() external payable {
        require(_msgSender() == owner(), "Only owner sends ETH.");
    }
    /// @notice Sets max txn ratio. Can only be called before disableMaximums is caled. Only callable by owner.
    /// @param ratio the ratio to set
    function setMaxTxRatio(uint32 ratio) external onlyOwner {
        require(maxTxDivisor > 1, "Can't re-set ratios.");
        require(ratio < 10000, "No lower than 0.01%");
        maxTxDivisor = ratio;
    }

    function setMaxWalletRatio(uint32 ratio) external onlyOwner {
        require(maxWalletDivisor > 1, "Can't re-set ratios.");
        require(ratio < 1000, "No lower than .1%");
        maxWalletDivisor = ratio;
    }

    function disableMaximums() external onlyOwner {
        maxTxDivisor = 1;
        maxWalletDivisor = 1;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (!tradingOpen) {
            // Allow all transfers until trade opens
            return;
        }
        // Perform the blocklist check
        require(!flags[from].isBlocklisted && !flags[to].isBlocklisted, "Blocklisted.");
        // Perform max tx
        
        if(!flags[from].isExcluded && !flags[to].isExcluded) {
            require(amount <= totalTokens/maxTxDivisor, "Over max txn.");
        }
        
        if(!flags[to].isExcluded) {
            // Max tx
            require(balanceOf(to)+amount <= totalTokens/maxWalletDivisor, "Will result in to being over max wallet.");
        }
    }

    /// @notice Open trading. Only callable once. Only callable by owner. Deliberately vague to prevent jeetdev copying.
    /// @param sqrt The sqrt for univ3.
    /// @param x The x for univ3.
    /// @param y the y for univ3.
    /// @param fee the fee amount for univ3.
    function openTrading(uint160 sqrt, uint256 x, uint256 y, TickData calldata fee) public onlyOwner {
        require(!tradingOpen, "Trading already open.");
        
        address token0;
        address token1;
        INonfungiblePositionManager posMgr = INonfungiblePositionManager(nonfungposman);
        // Run the pool creation
        {
            
            IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            address weth = _uniswapV2Router.WETH();
            // Deposit WETH while we've got the addy
            IWETH(weth).deposit{value: address(this).balance}();
            // Token0 must be the lower
            (token0, token1) = weth < address(this) ? (weth, address(this)) : (address(this), weth);
            defaultLPPool = posMgr.createAndInitializePoolIfNecessary(token0, token1, fee.fee, sqrt);
        }
        // Mint into the pool
        
        {
            IERC20Metadata tokA = IERC20Metadata(token0);
            IERC20Metadata tokB = IERC20Metadata(token1);
            uint256 tokABal = tokA.balanceOf(address(this));
            uint256 tokBBal = tokB.balanceOf(address(this));
            // Approve the manager to spend our tokens
            tokA.approve(nonfungposman, tokABal);
            tokB.approve(nonfungposman, tokBBal);
            // Create pool params
            INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({token0: token0, token1: token1, fee: fee.fee, tickLower: fee.minTick, tickUpper: fee.maxTick, amount0Desired: x, amount1Desired: y, amount0Min: 0, amount1Min: 0, recipient: _msgSender(), deadline: block.timestamp});
            flags[nonfungposman] = FlagData({isBlocklisted: false, isExcluded: true});
            flags[defaultLPPool] = FlagData({isBlocklisted: false, isExcluded: true});
            // Mint the position
            (,, uint256 amount0, uint256 amount1) = posMgr.mint(params);
            // Refund remainders - might be some due to how sqrt is calculated
            if(amount0 < tokABal) {
                tokA.approve(nonfungposman, 0);
                tokA.transfer(_msgSender(), tokABal - amount0);
            }
            if(amount1 < tokBBal) {
                tokB.approve(nonfungposman, 0);
                tokB.transfer(_msgSender(), tokBBal - amount1);
            }
        }
        tradingOpen = true;
        
    }

    /// @notice Disables blocklist addition and removal permanently. Only callable by owner.
    function disableBlocklistAdd() external onlyOwner {
        blocklistEnabled = false;
    }
    /// @notice Adds an account to blocklist. Requires blocklist to be enabled. Only callable by owner.
    /// @param theBot the address to block
    /// @param toSet the bool to set
    function setBot(address theBot, bool toSet) public onlyOwner {
        if (toSet) {
            require(blocklistEnabled, "Blocklist is disabled.");
        }
        flags[theBot].isBlocklisted = toSet;
    }
    function checkBot(address bot) public view returns (bool) {
        return flags[bot].isBlocklisted;
    }

    /// @notice Sets an account exclusion or inclusion from limits.
    /// @param account the account to change state on
    /// @param isExcluded the boolean to set it to
    function setExcludedFromFee(address account, bool isExcluded) public onlyOwner {
        flags[account].isExcluded = isExcluded;
    }
 /// @notice Returns if an account is excluded from fees.
    /// @param account the account to check
    function isExcludedFromFee(address account) public view returns (bool) {
        return flags[account].isExcluded;
    }

    function decimals() public pure override returns(uint8) {
        return _decimals;
    }


}