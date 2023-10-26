// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "solmate/tokens/ERC20.sol";
import "solmate/auth/Owned.sol";
import "./IWETH.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Factory.sol";

contract GenericERC20Token is ERC20, Owned {
    TokenStorage public packedStorage;

    uint256 constant TRANSFER_LOCK_DURATION = 1 minutes; // 1 min

    uint256 public maxSupply;
    uint256 public sell_threshold;

    uint256 public max_transfer_size_per_tx;
    uint256 public max_holding_amount;

    address public WETH;
    address public tax_receiver;
    address public uni_factory;
    address public initial_liquidity_pool;

    mapping(address => bool) public routers;
    mapping(address => bool) public LPs;
    mapping(address => bool) public exclude_from_fees; // no fees if these addresses are transferred from
    mapping(address => bool) public exclude_from_limits; // excluded from max tx side and max holding

    enum EmberDebtStatus { IN_DEBT, DEFAULTED, PAID_OFF }
    struct TokenStorage {
        uint8 BuyTax; // measured in 0.1%.
        uint8 SellTax; // measured in 0.1%.
        uint8 BurnTax; // measured in 0.1%.
        uint40 DeployDate; // This should be good for the next 32000 years.
        bool InSwap;
        address SwapRouter; // Used to periodically sell tokens
        EmberDebtStatus EmberStatus; // 0 we are paying off debt, 1 we are cooked, 2 we are free
    }

    struct ConstructorCalldata {
        string Name;
        string Symbol;
        uint8 Decimals;

        uint256 TotalSupply;
        uint256 MaxSupply;

        uint8 BuyTax;
        uint8 SellTax;
        uint256 SellThreshold;
        uint8 TransferBurnTax;

        address UniV2Factory;
        address UniV2SwapRouter;

        uint256 MaxSizePerTx;
        uint256 MaxHoldingAmount;
    }

    constructor(ConstructorCalldata memory params, address _weth) ERC20(params.Name, params.Symbol, params.Decimals) Owned(msg.sender) {
        sell_threshold = params.SellThreshold;
        tax_receiver = address(this);

        require(params.MaxSupply >= params.TotalSupply, "Max supply must be higher than total supply.");
        maxSupply = params.MaxSupply;

        max_holding_amount = params.MaxHoldingAmount;
        max_transfer_size_per_tx = params.MaxSizePerTx;
        WETH = _weth;
        uni_factory = params.UniV2Factory;

        require(params.BuyTax <= 252 && params.SellTax <= 252, "Buy/sell tax cannot be higher than 25.2%");

        packedStorage = TokenStorage(params.BuyTax, params.SellTax, params.TransferBurnTax, uint40(block.timestamp), false, params.UniV2SwapRouter, EmberDebtStatus.IN_DEBT);

        routers[params.UniV2SwapRouter] = true;

        exclude_from_fees[msg.sender] = true;
		exclude_from_fees[address(0xDEAD)] = true;

        exclude_from_limits[msg.sender] = true;
		exclude_from_limits[address(0xDEAD)] = true;
        exclude_from_limits[params.UniV2SwapRouter] = true;

        allowance[msg.sender][params.UniV2SwapRouter] = type(uint).max; // Allow univ2 router access to all of the vault's tokens as they will be sold when claiming fees
        allowance[address(this)][params.UniV2SwapRouter] = type(uint).max; // Allow univ2 router access to all of this contract's tokens as they will be used when adding liq and tax swaps

        _mint(address(this), params.TotalSupply);
    }

    function addLiquidity(uint256 token_amount) external payable onlyOwner returns(address) {
        require(initial_liquidity_pool == address(0), "Liquidity already added");

        IUniswapV2Router01(packedStorage.SwapRouter).addLiquidityETH{value: msg.value}(
            address(this),
            token_amount,
            token_amount,
            msg.value,
            msg.sender,

            type(uint).max
        );

        address _initial_liquidity_pool = calculateUniV2Pair();
        initial_liquidity_pool = _initial_liquidity_pool;
        LPs[_initial_liquidity_pool] = true;

        return _initial_liquidity_pool;
    }

    function mint(address receiver, uint256 amount) public onlyOwner {
        require(maxSupply >= totalSupply + amount, "Total supply cannot exceed max supply");

        // Bypasses max_holding_amount and max_transfer_size_per_tx and all other checks
        _mint(receiver, amount);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        if (packedStorage.EmberStatus == EmberDebtStatus.DEFAULTED && msg.sender == initial_liquidity_pool && to == owner) {
            // Tokens are being transfered from LP to the Vault = LP burn.

            balanceOf[msg.sender] = balanceOf[msg.sender] - amount;
            balanceOf[to] = balanceOf[to] + amount;

            emit Transfer(msg.sender, to, amount);

            return true;
        }

        _transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        if (packedStorage.EmberStatus == EmberDebtStatus.DEFAULTED && msg.sender == owner) {
            // The vault contract is trying to burn the user's tokens to refund them eth.
            // The owner in this case is the ember vault for sure since packedStorage.EmberStatus can only be changed to EmberDebtStatus.DEFAULTED by the vault
            // And it can't be changed back after that.

            balanceOf[from] = balanceOf[from]- amount;
            balanceOf[to] = balanceOf[to] + amount;

            emit Transfer(from, to, amount);

            return true;
        }

        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.
        if (allowed != type(uint256).max) {
            allowance[from][msg.sender] = allowed - amount; // Will revert if allowance is not enough if solidity version is >=0.8.0
        }

        _transfer(from, to, amount);

        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        TokenStorage memory info = packedStorage;

        require(info.EmberStatus != EmberDebtStatus.DEFAULTED, "Token failed to pay off Ember debt. Transfers have been stopped, but claiming ETH is possible through the vault contract");

        // This branch will only ever be entered once, which is when the vault creates the token and adds LP, after that initial_liquidity_pool will be set to the actual LP addy
        if (initial_liquidity_pool == address(0)) {
            balanceOf[from] = balanceOf[from] - amount;
            balanceOf[to] = balanceOf[to] + amount;

            emit Transfer(from, to, amount);

            return;
        }

        // Disable transfers if 1 minute hasn't passed yet since deployment.
        if ((info.DeployDate + TRANSFER_LOCK_DURATION > block.timestamp) && from != owner && to != owner) {
            revert("You must wait 1 minute after deployment to be able to trade this token");
        }

        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        require(max_transfer_size_per_tx >= amount || exclude_from_limits[from], "Max size per tx exceeded");

        uint256 taxFee = 0;
        if (!exclude_from_fees[from] && !exclude_from_fees[to]) {
            if (LPs[from]) {
                if (info.BuyTax != 0) {
                    if (info.EmberStatus == EmberDebtStatus.PAID_OFF) {
                        taxFee = (amount * info.BuyTax) / 1000;
                    } else {
                        taxFee = (amount * (info.BuyTax + 3)) / 1000; // add 0.3% for protocol
                    }

                    balanceOf[address(this)] = balanceOf[address(this)] + taxFee;
                    emit Transfer(from, address(this), taxFee);
                }
            } else if (LPs[to]) {
                if (info.SellTax != 0) {
                    if (info.EmberStatus == EmberDebtStatus.PAID_OFF) {
                        taxFee = (amount * info.SellTax) / 1000;
                    } else {
                        taxFee = (amount * (info.SellTax + 3)) / 1000; // add 0.3% for protocol
                    }

                    balanceOf[address(this)] = balanceOf[address(this)] + taxFee;
                    emit Transfer(from, address(this), taxFee);
                }

                // If the owner completely removes tax, there will probably still be some tokens left in the contract that will have to be withdrawn and sold manually.
                if (info.BuyTax != 0 || info.SellTax != 0) {
                    uint256 balance = balanceOf[address(this)];
                    if (!info.InSwap && balance > sell_threshold) {
                        packedStorage.InSwap = true;

                        address[] memory path = new address[](2);
                        path[0] = address(this);
                        path[1] = WETH;

                        // Wrap in a try catch to prevent owner from rugging by setting invalid router
                        try IUniswapV2Router01(info.SwapRouter).swapExactTokensForETHSupportingFeeOnTransferTokens(
                            taxFee,
                            0,
                            path,
                            tax_receiver,
                            type(uint).max
                        ) { } catch {
                            // Ignore, to prevent trades from failing if owner sets an invalid router
                        }

                        packedStorage.InSwap = false;
                    }
                }
            } else if (info.BurnTax != 0) {
                // Only apply burn tax if buy/sell tax wasnt applied.
                taxFee = (amount * info.BurnTax) / 1000;

                balanceOf[address(0)] = balanceOf[address(0)] + taxFee;
                emit Transfer(from, address(0), taxFee);
            }
        }

        // Apply balance changes
        balanceOf[from] = balanceOf[from] - amount;
        balanceOf[to] = balanceOf[to] + (amount - taxFee);
        emit Transfer(from, to, amount - taxFee);

        require(balanceOf[to] <= max_holding_amount || exclude_from_limits[to], "Max holding per wallet exceeded");
    }

    // Withdraws token to owner's addy
    function withdrawTokens() onlyOwner external returns(uint) {
        uint256 balance = balanceOf[address(this)];
        if (balance == 0) return 0;

        balanceOf[msg.sender] = balanceOf[msg.sender] + balance;
        balanceOf[address(this)] = balanceOf[address(this)] - balance;

        emit Transfer(address(this), msg.sender, balance);

        return balance;
    }

    // Withdraws ETH to owner
    function withdrawEth() external onlyOwner returns (uint) {
        // native_balance should now include the previously unwrapped weth
        uint256 native_balance = address(this).balance;
        if (native_balance != 0) {
            (bool sent, ) = owner.call{value: native_balance}("");
            require(sent, "Failed to send Ether");
        }

        return native_balance;
    }

    // ============================== [START] Functions that are supposed to be called by the vault only ==============================
    // Called right after we pull liq and enable claims
    function disableTransfers() external onlyOwner {
        require(packedStorage.EmberStatus == EmberDebtStatus.IN_DEBT, "Can only disable transfers on a token that's currently in debt");
        packedStorage.EmberStatus = EmberDebtStatus.DEFAULTED;
    }

    // Called right after the Ember debt gets fully paid off
    function transferOwnershipToRealOwner(address _real_owner) external onlyOwner {
        require(packedStorage.EmberStatus == EmberDebtStatus.IN_DEBT, "EmberStatus is supposed to be IN_DEBT");

        // Change tax receiver to new owner
        tax_receiver = _real_owner;

        // Disables the 0.3% protocol fee and disable future liquidations
        packedStorage.EmberStatus = EmberDebtStatus.PAID_OFF; // we free

        transferOwnership(_real_owner);
    }

    // ============================== [END] Functions that are supposed to be called by the vault only ==============================

    function setInitialLiquidityPool(address _addy) public onlyOwner {
        initial_liquidity_pool = _addy;
    }

    function disableMinting() public onlyOwner {
        maxSupply = totalSupply;
    }

    receive() external payable {
        // Enable receiving eth for tax
    }

    function setLP(address _lp, bool _bool) onlyOwner external {
        require(_lp != address(0), "LP address cannot be 0");

        LPs[_lp] = _bool;
    }

    function setExcludedFromFees(address _address, bool _bool) onlyOwner external {
        exclude_from_fees[_address] = _bool;
    }

    function setExcludedFromLimits(address _address, bool _bool) onlyOwner external {
        exclude_from_limits[_address] = _bool;
    }

    function setTaxReceiver(address _tax_receiver) onlyOwner external {
        require(_tax_receiver != address(0), "Tax receiver address cannot be 0");

        tax_receiver = _tax_receiver;
    }

    function setRouter(address _router, address _factory) onlyOwner external {
        require(_router != address(0), "Router address cannot be 0");

        packedStorage.SwapRouter = _router;
        uni_factory = _factory;
    }

    function setTaxes(uint8 _buyTax, uint8 _sellTax) onlyOwner external {
        require(_buyTax <= 252, "buy tax cant be higher than 25.2%");
        require(_sellTax <= 252, "sell tax cant be higher than 25.2%");

        TokenStorage memory info = packedStorage;
        info.BuyTax = _buyTax;
        info.SellTax = _sellTax;
        packedStorage = info;
    }

	function setLimits(
        uint _max_holding,
        uint _max_transfer
    ) external onlyOwner {
        require(
            _max_holding >= totalSupply / 100,
            "Max Holding Limit cannot be less than 1% of total supply"
        );
        require(
            _max_transfer >= totalSupply / 100,
            "Max Transfer Limit cannot be less than 1% of total supply"
        );

        max_holding_amount = _max_holding;
        max_transfer_size_per_tx = _max_transfer;
    }

    // ================== packedStorage viewers =======================
    function buyTax() view public returns (uint) {
        return packedStorage.BuyTax;
    }

    function sellTax() view public returns (uint) {
        return packedStorage.SellTax;
    }

    function burnTax() view public returns (uint) {
        return packedStorage.BurnTax;
    }

    function deployDate() view public returns (uint) {
        return packedStorage.DeployDate;
    }

    function swapRouter() view public returns (address) {
        return packedStorage.SwapRouter;
    }

    function emberStatus() view public returns (EmberDebtStatus) {
        return packedStorage.EmberStatus;
    }

    function calculateUniV2Pair() public view returns (address) {
        return IUniswapV2Factory(uni_factory).getPair(address(this), WETH);
    }
}