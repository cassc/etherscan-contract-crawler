// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract GPO is ERC20PresetFixedSupply, Pausable, Ownable, AccessControl {
    
    // TokenSwaped event is emitted anytime there is a swap between GPO and USDC on the GoldPesa.com decentralized exchange powered by Uniswap
    event TokensSwaped(
        address indexed purchaser,
        uint256 amountIn,
        uint256 amountOut,
        bool direction // false: GPO-X, true: X-GPO
    );

    // FeeSplit stores the "recipient" wallet address and the respective percentage of the feeOnSwap which are to be sent to it.  
    struct FeeSplit {
        address recipient;
        uint16 fee;
    }

    // Token Name
    string public _name = "GoldPesa Option";
    // Token Symbol
    string public _symbol = "GPO";
    // GPO Hard Cap
    uint256 public constant fixedSupply = 100_000_000;
    // Wallet Hard Cap
    uint256 public constant capOnWallet = 100_000;
    // GoldPesa fee on swap percentage
    uint256 public feeOnSwap = 10;
    // Uniswap Router Address
    ISwapRouter public immutable swapRouter;
    // USDC ERC20 token Address
    address public addrUSDC;
    // Uniswap V3 Pool Fee * 10000 = 1 %
    uint24 private swapPoolFee = 10000;
    // Uniswap V3 GPO/USDC liquidity pool address
    address public authorizedPool;
    // Time when Pre-Sale and Sale tokens will be unlocked (Unix Time)
    uint256 public walletsTimelockedUntil;
    // When freeTrade is true the token bypasses the hard cap on wallet and can be traded freely on any exchange
    bool public freeTrade = false;
    // The feeOnSwap percentage is distributed to the addresses and their respective percentage which are held in the feeSplits array
    FeeSplit[] public feeSplits;
    // Keeps a record of the number of addresses in the feeSplits array 
    uint256 public feeSplitsLength;

    // Defines an Access Control role called "CAN_LOCK" which is granted to addresses which are allowed to lock wallet addresses during the Sale and Pre-Sale phase
    bytes32 public constant AUTHORIZED_LOCK =
        keccak256("CAN_LOCK");
    modifier authorizedLocker() {
        require(hasRole(AUTHORIZED_LOCK, _msgSender()));
        _;
    }
    // Mapping which holds information of the wallet addresses which are locked (true) /unlocked (false)
    mapping(address => bool) public lockedWallets;
    // Mapping which holds details of the wallet addresses which bypass the wallet hard cap and are able to swap with the Uniswap GPO/USDC liquidity pool
    mapping(address => bool) public whitelistedWallets;
    // Mapping which holds details of the amount of GPO tokens are locked in the lockedWallets mapping 
    mapping(address => uint256) public lockedWalletsAmount;
    bool public swapEnabled = false;

    // Upon deployment, the constructor is only executed once
    constructor(
        ISwapRouter _swapRouter,
        uint256 _walletsTimelockedUntil
    ) ERC20PresetFixedSupply(_name, _symbol, hardCapOnToken(), address(this)) {
        swapRouter = _swapRouter;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        walletsTimelockedUntil = _walletsTimelockedUntil;
        whitelistedWallets[address(0x0)] = true;
        whitelistedWallets[address(this)] = true;
    }

    // Enables GoldPesa to manually transfer GPO tokens from the GPO contract to another wallet address
    function transferTokensTo(address _to, uint256 amount) public onlyOwner {
        _transfer(address(this), _to, amount);
    }
    // Enables GoldPesa to manually add or remove wallet addresses from the whitelistedWallets mapping
    function changeWalletWhitelist(address _addr, bool yesOrNo) public onlyOwner {
        whitelistedWallets[_addr] = yesOrNo;
    }
    // Sets the USDC contract address, the Uniswap pool fee and accordingly includes the derived Uniswap liquidity pool address to the whitelistedWallets mapping
    function setPoolParameters(address USDC, uint24 poolFee) public onlyOwner {
        addrUSDC = USDC;
        swapPoolFee = poolFee;
        whitelistedWallets[authorizedPool] = false;

        // taken from @uniswap/v3-periphery/contracts/libraries/PoolAddress.sol
        address token0 = address(this);
        address token1 = USDC;
        if (token0 > token1) (token0, token1) = (token1, token0);

        authorizedPool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            0x1F98431c8aD98523631AE4a59f267346ea31F984,
                            keccak256(abi.encode(token0, token1, poolFee)),
                            bytes32(0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54)
                        )
                    )
                )
            )
        );
        whitelistedWallets[authorizedPool] = true;
    }
    // Enables GoldPesa to set the state of the contract to "freeTrade" 
    function switchFreeTrade() public onlyOwner {
        freeTrade = !freeTrade;
    }

    function switchSwapEnabled() public onlyOwner {
        swapEnabled = !swapEnabled;
    }

    // Enables GoldPesa to set the feeOnSwap 
    function setFeeOnSwap(uint24 _feeOnSwap) public onlyOwner {
        feeOnSwap = _feeOnSwap;
    }
    // Enables GoldPesa to set the "feeOnSwap" distribution details 
    function setFeeSplits(FeeSplit[] memory _feeSplits) public onlyOwner {
        uint256 grandTotal = 0;
        for (uint256 i = 0; i < _feeSplits.length; i++) {
            FeeSplit memory f = _feeSplits[i];
            grandTotal += f.fee;
        }
        require(_feeSplits.length == 0 || grandTotal == 100);
        // temporarily allow 0 fee splits for tests for manual fee distribution
        delete feeSplits;
        for (uint256 i = 0; i < _feeSplits.length; i++) {
            feeSplits.push(_feeSplits[i]);
        }
        feeSplitsLength = _feeSplits.length;
    }
    // Distributes the feeOnSwap amount collected during any swap transaction to the addresses defined in the "feeSplits" array
    function distributeFee(uint256 amount) internal {
        uint256 grandTotal = 0;
        for (uint256 i = 0; i < feeSplits.length; i++) {
            FeeSplit storage f = feeSplits[i];
            uint256 distributeAmount = amount * f.fee / 100;
            IERC20(addrUSDC).transfer(f.recipient, distributeAmount);
            grandTotal += distributeAmount;
        }
        if (grandTotal != amount && feeSplits.length > 0) {
            FeeSplit storage f = feeSplits[0];
            IERC20(addrUSDC).transfer(f.recipient, amount - grandTotal);
        }
    }
    // Defines the rules that must be satisfied before GPO can be transferred
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        // Ensures that GPO token holders cannot burn their own tokens
        require(to != address(0x0) || whitelistedWallets[from], "GPO_ERR: Cannot burn");
        // Ensures that GPO token holders cannot execute a swap directly with the GPO/USDC liquidity pool on Uniswap. All swaps must be executed on the GoldPesa DEX unless 
        // "freeTrade" has be enabled
        if (authorizedPool != address(0x0) && (from == authorizedPool || to == authorizedPool)) 
            require(freeTrade || (whitelistedWallets[to] && whitelistedWallets[from]), "GPO_ERR: UniswapV3 functionality is only allowed through GPO's protocol"); 
        // Unless "freeTrade" has been enabled this require statement rejects any transfers to wallets which will break the 100,000 GPO wallet hard cap unless the 
        // receiving wallet address is a "whitelistedWallet"
        require(
            freeTrade || 
            from == address(0x0) ||
            whitelistedWallets[to] || 
            balanceOf(to) + amount <= hardCapOnWallet(),
            "GPO_ERR: Hard cap on wallet reached"
        );
        // Disables all GPO transfers if the token has been paused by GoldPesa
        require(!paused(), "ERC20Pausable: token transfer while paused");
        // Rejects transfers made from locked wallets which are greater than the wallet's "lockedWalletsAmount" until the date where all tokens are unlocked
        require(block.timestamp >= walletsTimelockedUntil || 
            !lockedWallets[from] || 
            (lockedWallets[from] && amount <= (balanceOf(from) - lockedWalletsAmount[from])), "Cannot transfer token as the wallet is locked");
    }
    // Internal mint function which cannot be called externally after the GPO contract is deployed ensuring that the GPO token hard cap of 100,000,000 is not breached
    function _mint(address account, uint256 amount) internal virtual override {
        // Ensures that GPO token hard cap of 100,000,000 is not breached even if the mint function is called internally
        require(
            ERC20.totalSupply() + amount <= hardCapOnToken(),
            "ERC20Capped: cap exceeded"
        );
        super._mint(account, amount);
    }

    // Returns the GPO token hard cap ("fixedSupply") in wei
    function hardCapOnToken() public view returns (uint256) {
        return fixedSupply * (10**(uint256(decimals())));
    }
    // Returns the GPO token wallet hard cap ("capOnWallet") in wei
    function hardCapOnWallet() public view returns (uint256) {
        return capOnWallet * (10**(uint256(decimals())));
    }
    // Returns the GoldPesa feeOnSwap in USDC which is used in the swap functions
    function calculateFeeOnSwap(uint256 amount)
        internal
        view
        returns (uint256)
    {
        return amount * feeOnSwap / 100;
    }
    // Enables GoldPesa to lock and unlock wallet address manually 
    function lockUnlockWallet(address account, bool yesOrNo, uint256 amount) public authorizedLocker {
        lockedWallets[account] = yesOrNo;
        if (yesOrNo) {
            uint256 lockedValue = lockedWalletsAmount[account] + amount;
            require(lockedValue <= balanceOf(account));
            lockedWalletsAmount[account] = lockedValue;
        } else {
            lockedWalletsAmount[account] = 0;
        }
    }
    // Pause the GPO token transfers
    function pause() public onlyOwner {
        _pause();
    }
    // Unpause the GPO token transfer
    function unpause() public onlyOwner {
        _unpause();
    }

    // User defines the exact amount of USDC they would like to receive while swaping GPO for USDC using the GPO/USDC Uniswap V3 liquidity pool.
    // Any extra GPO tokens not used in the Swap are returned back to the user.
    function swapToExactOutput(uint256 amountInMaximum, uint256 amountOut, uint256 deadline) external returns (uint256 amountIn) {
        require(swapEnabled || whitelistedWallets[_msgSender()]);
        
        _transfer(_msgSender(), address(this), amountInMaximum);
        _approve(address(this), address(swapRouter), amountInMaximum);

        if (deadline == 0)
            deadline = block.timestamp + 30*60;
        
        ISwapRouter.ExactOutputSingleParams memory params =
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: address(this),
                tokenOut: addrUSDC,
                fee: swapPoolFee,
                recipient: address(this),
                deadline: deadline,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });
        amountIn = swapRouter.exactOutputSingle(params);
        uint256 fee = calculateFeeOnSwap(amountOut);
        uint256 amountSwap = amountOut - fee;
        
        TransferHelper.safeTransfer(addrUSDC, _msgSender(), amountSwap);
        distributeFee(fee); 

        if (amountIn < amountInMaximum) {
            _transfer(address(this), _msgSender(), amountInMaximum - amountIn);
        } 
        emit TokensSwaped(_msgSender(), amountIn, amountOut, false);
    }
    // User defines the exact amount of GPO they would like to spend while swaping GPO for USDC using the GPO/USDC Uniswap V3 liquidity pool.
    function swapToExactInput(uint256 amountIn, uint256 amountOutMinimum, uint256 deadline ) external returns (uint256 amountOut) {
        require(swapEnabled || whitelistedWallets[_msgSender()]);

        _transfer(_msgSender(), address(this), amountIn);
        _approve(address(this), address(swapRouter), amountIn);

        if (deadline == 0)
            deadline = block.timestamp + 30*60;

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(this),
                tokenOut: addrUSDC,
                fee: swapPoolFee,
                recipient: address(this),
                deadline: deadline,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);

        uint256 fee = calculateFeeOnSwap(amountOut);
        uint256 amountSwap = amountOut - fee;

        TransferHelper.safeTransfer(addrUSDC, _msgSender(), amountSwap);
        distributeFee(fee);

        emit TokensSwaped(_msgSender(), amountIn, amountOut, false);

        return amountSwap;
    }
    // User defines the exact amount of GPO they would like to receive while swaping USDC for GPO using the GPO/USDC Uniswap V3 liquidity pool.
    // Any extra USDC tokens not used in the Swap are returned back to the user.
    function swapFromExactOutput(uint256 amountInMaximum, uint256 amountOut, uint256 deadline) external returns (uint256 amountIn) {
        require(swapEnabled || whitelistedWallets[_msgSender()]);

        TransferHelper.safeTransferFrom(addrUSDC, _msgSender(), address(this), amountInMaximum);
        uint256 fee = calculateFeeOnSwap(amountInMaximum);
        uint256 amountSwap = amountInMaximum - fee;
        distributeFee(fee);

        
        if (deadline == 0)
            deadline = block.timestamp + 30*60;
        
        TransferHelper.safeApprove(addrUSDC, address(swapRouter), amountSwap);
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
                tokenIn: addrUSDC,
                tokenOut: address(this),
                fee: swapPoolFee,
                recipient: address(this),
                deadline: deadline,
                amountOut: amountOut,
                amountInMaximum: amountSwap,
                sqrtPriceLimitX96: 0
        });
        amountIn = swapRouter.exactOutputSingle(params);
        
        _transfer(address(this), _msgSender(), amountOut);

        if (amountIn < amountSwap) {
            TransferHelper.safeTransfer(addrUSDC, _msgSender(), amountSwap - amountIn);
        } 

        emit TokensSwaped(_msgSender(), amountIn, amountOut, true);
    }
    // User defines the exact amount of USDC they would like to spend while swaping USDC for GPO using the GPO/USDC Uniswap V3 liquidity pool.
    function swapFromExactInput(uint256 amountIn, uint256 amountOutMinimum, uint256 deadline) external returns (uint256 amountOut) {
        require(swapEnabled || whitelistedWallets[_msgSender()]);

        uint256 fee = calculateFeeOnSwap(amountIn);
        TransferHelper.safeTransferFrom(addrUSDC, _msgSender(), address(this), amountIn);
        uint256 amountSwap = amountIn - fee;
        distributeFee(fee);
        TransferHelper.safeApprove(addrUSDC, address(swapRouter), amountSwap);

        if (deadline == 0)
            deadline = block.timestamp + 30*60;

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: addrUSDC,
                tokenOut: address(this),
                fee: swapPoolFee,
                recipient: address(this),
                deadline: deadline,
                amountIn: amountSwap,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });
        amountOut = swapRouter.exactInputSingle(params);
        _transfer(address(this), _msgSender(), amountOut);

        emit TokensSwaped(_msgSender(), amountIn, amountOut, true);
    }


}