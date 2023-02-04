// Copyright (c) 2023 EG Global Ltd. All rights reserved.
// EG licenses this file to you under the MIT license.

/*

EG is a community token making a difference by maximising crypto's impact in a purposeful ecosystem.

The EG Token powers the EG Ecosystem that includes:

* Salesforce Exchange for Enterprise
* EGTrade
* EGSwap (DEX)
* EGMigrate
* Gator Gang NFT Collection
* Burn Party Platform
* Blockchain Alliance for Global Good (BAGG)
* EG Social Impact Portal
* EG Blockchain Agency
* and many more dApps & utilities to come.

 _______   _______    .___________.  ______    __  ___  _______ .__   __. 
|   ____| /  _____|   |           | /  __  \  |  |/  / |   ____||  \ |  | 
|  |__   |  |  __     `---|  |----`|  |  |  | |  '  /  |  |__   |   \|  | 
|   __|  |  | |_ |        |  |     |  |  |  | |    <   |   __|  |  . `  | 
|  |____ |  |__| |        |  |     |  `--'  | |  .  \  |  |____ |  |\   | 
|_______| \______|        |__|      \______/  |__|\__\ |_______||__| \__| 


From education initiatives to disaster relief, the EG community has 
defied the limits of an online movement by donating over $3.7 Million
in direct aid, around the world.

Learn more about EG and our Ecosystem by visting
https://www.EGToken.io

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

// helper methods for discovering LP pair addresses
library PairHelper {
    bytes private constant token0Selector =
        abi.encodeWithSelector(IUniswapV2Pair.token0.selector);
    bytes private constant token1Selector =
        abi.encodeWithSelector(IUniswapV2Pair.token1.selector);

    function token0(address pair) internal view returns (address) {
        return token(pair, token0Selector);
    }

    function token1(address pair) internal view returns (address) {
        return token(pair, token1Selector);
    }

    function token(address pair, bytes memory selector)
        private
        view
        returns (address)
    {
        // Do not check if pair is not a contract to avoid warning in transaction log
        if (!isContract(pair)) return address(0);

        (bool success, bytes memory data) = pair.staticcall(selector);

        if (success && data.length >= 32) {
            return abi.decode(data, (address));
        }

        return address(0);
    }

    function isContract(address account) private view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }

        return (codehash != accountHash && codehash != 0x0);
    }
}

contract EG is IERC20Upgradeable, OwnableUpgradeable {
    using PairHelper for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct TransferDetails {
        uint112 balance0; // balance of token0
        uint112 balance1; // balance of token1
        uint32 blockNumber; // block number of  transfer
        address to; // receive address of transfer
        address origin; // submitter address of transfer
    }

    uint256 public totalSupply; // total supply

    uint8 public constant decimals = 18; // decimals of token

    string public constant name = "EG Token"; // name of token
    string public constant symbol = "EG"; // symbol of token

    IUniswapV2Router02 public uniswapV2Router; // uniswap router
    address public uniswapV2Pair; // uniswap pair

    uint256 public buyFee; // buy fee
    uint256 public sellFee; // sell fee
    uint256 public transferFee; // transfer fee

    address public marketingWallet; // marketing wallet address
    address public liquidityWallet; // liquidity wallet address
    address public techWallet; // tech wallet address
    address public donationsWallet; // donations wallet address
    address public stakingRewardsWallet; // staking rewards wallet address

    uint256 public marketingWalletFee; // marketing wallet fee
    uint256 public liquidityWalletFee; // liquidity wallet fee
    uint256 public techWalletFee; // tech wallet fee
    uint256 public donationsWalletFee; // donations wallet fee
    uint256 public stakingRewardsWalletFee; // staking rewards wallet fee

    uint256 public maxTransactionAmount; // max transaction amount, can be 0 if no limit
    uint256 public maxTransactionCoolDownAmount; // max transaction amount during cooldown

    mapping(address => uint256) private _balances; // balances of token

    mapping(address => mapping(address => uint256)) private _allowances; // allowances of token

    uint256 private constant MAX = ~uint256(0); // max uint256

    uint256 private _tradingStart; // trading start time
    uint256 private _tradingStartCooldown; // trading start time during cooldown

    bool private _checkingTokens; // checking tokens flag

    TransferDetails private _lastTransfer; // last transfer details

    mapping(address => uint256) private _lastCoolDownTrade; // last cooldown trade time
    mapping(address => bool) public whiteList; // white list => excluded from fee
    mapping(address => bool) public blackList; // black list => disable _transfer

    modifier tokenCheck() {
        require(!_checkingTokens);
        _checkingTokens = true;
        _;
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _checkingTokens = false;
    }

    event TradingEnabled();
    event RouterAddressUpdated(address prevAddress, address newAddress);
    event MarketingWalletUpdated(address prevAddress, address newAddress);
    event MarketingWalletFeeUpdated(uint256 prevFee, uint256 newFee);
    event LiquidityWalletUpdated(address prevAddress, address newAddress);
    event LiquidityWalletFeeUpdated(uint256 prevFee, uint256 newFee);
    event TechWalletUpdated(address prevAddress, address newAddress);
    event TechWalletFeeUpdated(uint256 prevFee, uint256 newFee);
    event DonationsWalletUpdated(address prevAddress, address newAddress);
    event DonationsWalletFeeUpdated(uint256 prevFee, uint256 newFee);
    event StakingRewardsWalletUpdated(address prevAddress, address newAddress);
    event StakingRewardsWalletFeeUpdated(uint256 prevFee, uint256 newFee);

    event BuyFeeUpdated(uint256 prevValue, uint256 newValue);
    event SellFeeUpdated(uint256 prevValue, uint256 newValue);
    event TransferFeeUpdated(uint256 prevValue, uint256 newValue);

    event AddClientsToWhiteList(address[] account);
    event RemoveClientsFromWhiteList(address[] account);

    event WithdrawTokens(uint256 amount);
    event WithdrawAlienTokens(
        address indexed token,
        address indexed to,
        uint256 amount
    );
    event WithdrawNativeTokens(address indexed to, uint256 amount);
    event MaxTransactionAmountUpdated(uint256 prevValue, uint256 nextValue);
    event MaxTransactionCoolDownAmountUpdated(
        uint256 prevValue,
        uint256 nextValue
    );
    event AddClientsToBlackList(address[] accounts);
    event RemoveClientsFromBlackList(address[] accounts);

    /**
     * @param _routerAddress BSC MAIN 0x10ed43c718714eb63d5aa57b78b54704e256024e
     * @param _routerAddress BSC TEST 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
     **/
    function initialize(address _routerAddress) external initializer {
        require(
            _routerAddress != address(0),
            "EG: routerAddress should not be the zero address"
        );

        __Ownable_init();

        _tradingStart = MAX; // trading start time
        _tradingStartCooldown = MAX; // trading start time during cooldown

        totalSupply = 6 * 10**9 * 10**decimals; // total supply of token (6 billion)

        maxTransactionCoolDownAmount = totalSupply / 1000; // 0.1% of total supply

        buyFee = 5; // 5%
        sellFee = 5; // 5%
        transferFee = 0; // 0%

        marketingWalletFee = 20; // 20%
        liquidityWalletFee = 20; // 20%
        techWalletFee = 30; // 30%
        donationsWalletFee = 10; // 10%
        stakingRewardsWalletFee = 20; // 20%

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            _routerAddress
        );
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        _balances[msg.sender] = totalSupply;

        whiteList[owner()] = true;
        whiteList[address(this)] = true;

        emit Transfer(address(0), _msgSender(), totalSupply);
    }

    /**
     * @dev Function to receive ETH when msg.data is empty
     * @dev Receives ETH from uniswapV2Router when swapping
     **/
    receive() external payable {}

    /**
     * @dev Fallback function to receive ETH when msg.data is not empty
     **/
    fallback() external payable {}

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function allowance(address from, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[from][spender];
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        uint256 balance0 = _balanceOf(account);
        if (
            _lastTransfer.blockNumber == uint32(block.number) &&
            account == _lastTransfer.to
        ) {
            // Balance being checked is the same address that did the last _transfer_in
            // check if likely same transaction. If True, then it is a Liquidity Add
            _validateIfLiquidityAdd(account, uint112(balance0));
        }

        return balance0;
    }

    /**
     * @param accounts list of clients to whitelist so they do not pay tax on buy or sell
     *
     * @dev exclude a wallet from paying tax
     **/
    function addClientsToWhiteList(address[] calldata accounts)
        external
        onlyOwner
    {
        for (uint256 i; i < accounts.length; i++) {
            require(
                accounts[i] != address(0),
                "EG: Zero address can't be added to whitelist"
            );
        }

        for (uint256 i; i < accounts.length; i++) {
            if (!whiteList[accounts[i]]) {
                whiteList[accounts[i]] = true;
            }
        }

        emit AddClientsToWhiteList(accounts);
    }

    /**
     * @param accounts list of clients to remove from whitelist so they start paying tax on buy or sell
     *
     * @dev include a wallet to pay tax
     **/
    function removeClientsFromWhiteList(address[] calldata accounts)
        external
        onlyOwner
    {
        for (uint256 i; i < accounts.length; i++) {
            if (whiteList[accounts[i]]) {
                whiteList[accounts[i]] = false;
            }
        }

        emit RemoveClientsFromWhiteList(accounts);
    }

    /**
     * @param accounts list of clients to add to blacklist (trading not allowed)
     *
     * @dev add clients to blacklist
     **/
    function addClientsToBlackList(address[] calldata accounts)
        external
        onlyOwner
    {
        for (uint256 i; i < accounts.length; i++) {
            require(
                accounts[i] != address(0),
                "EG: Zero address can't be added to blacklist"
            );
        }

        for (uint256 i; i < accounts.length; i++) {
            if (!blackList[accounts[i]]) {
                blackList[accounts[i]] = true;
            }
        }

        emit AddClientsToBlackList(accounts);
    }

    /**
     * @param accounts list to remove from blacklist
     *
     * @dev remove accounts from blacklist
     **/
    function removeClientsFromBlackList(address[] calldata accounts)
        external
        onlyOwner
    {
        for (uint256 i; i < accounts.length; i++) {
            if (blackList[accounts[i]]) {
                blackList[accounts[i]] = false;
            }
        }

        emit RemoveClientsFromBlackList(accounts);
    }

    /**
     * @dev check trading enabled
     *
     **/
    function isTradingEnabled() public view returns (bool) {
        // Trading has been set and time buffer has elapsed
        return _tradingStart < block.timestamp;
    }

    /**
     * @dev check trading start cool down
     *
     **/
    function inTradingStartCoolDown() public view returns (bool) {
        // Trading has been started and the cool down period has elapsed
        return _tradingStartCooldown >= block.timestamp;
    }

    /**
     * @param to receiver address
     * @param from sender address
     *
     * @dev Multiple trades in same block from the same source are not allowed during trading start cooldown period
     **/
    function validateDuringTradingCoolDown(address to, address from) private {
        address pair = uniswapV2Pair;
        bool disallow;

        // Disallow multiple same source trades in same block
        if (from == pair) {
            disallow =
                _lastCoolDownTrade[to] == block.number ||
                _lastCoolDownTrade[tx.origin] == block.number;
            _lastCoolDownTrade[to] = block.number;
            _lastCoolDownTrade[tx.origin] = block.number;
        } else if (to == pair) {
            disallow =
                _lastCoolDownTrade[from] == block.number ||
                _lastCoolDownTrade[tx.origin] == block.number;
            _lastCoolDownTrade[from] = block.number;
            _lastCoolDownTrade[tx.origin] = block.number;
        }

        require(
            !disallow,
            "EG: Multiple trades in same block from the same source are not allowed during trading start cooldown"
        );
    }

    /**
     * @param _tradeStartDelay trade delay (uint is minute)
     * @param _tradeStartCoolDown cooldown delay (unit is minute)
     *
     * @dev This function can only be called once
     **/
    function setTradingEnabled(
        uint256 _tradeStartDelay,
        uint256 _tradeStartCoolDown
    ) external onlyOwner {
        require(
            _tradeStartDelay < 10,
            "EG: tradeStartDelay should be less than 10 minutes"
        );
        require(
            _tradeStartCoolDown < 120,
            "EG: tradeStartCoolDown should be less than 120 minutes"
        );
        require(
            _tradeStartDelay < _tradeStartCoolDown,
            "EG: tradeStartDelay must be less than tradeStartCoolDown"
        );
        // This can only be called once
        require(
            _tradingStart == MAX && _tradingStartCooldown == MAX,
            "EG: Trading has started already"
        );

        _tradingStart = block.timestamp + _tradeStartDelay * 1 minutes;
        _tradingStartCooldown = _tradingStart + _tradeStartCoolDown * 1 minutes;
        // Announce to the blockchain immediately, even though trading
        // can't start until delay passes (stop those sniping bots!)
        emit TradingEnabled();
    }

    /**
     * @param routerAddress SWAP router address
     *
     * @dev set swap router address
     **/
    function setRouterAddress(address routerAddress) external onlyOwner {
        require(
            routerAddress != address(0),
            "routerAddress should not be the zero address"
        );

        address prevAddress = address(uniswapV2Router);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(
            address(this),
            _uniswapV2Router.WETH()
        );

        uniswapV2Router = _uniswapV2Router;
        emit RouterAddressUpdated(prevAddress, routerAddress);
    }

    /**
     * @param _wallet, marketing wallet address
     *
     * @dev set Marketing Wallet Address
     **/
    function setMarketingWallet(address _wallet) external onlyOwner {
        require(
            _wallet != address(0),
            "EG: The marketing wallet should not be the zero address"
        );

        address prevAddress = marketingWallet;

        marketingWallet = _wallet;
        emit MarketingWalletUpdated(prevAddress, marketingWallet);
    }

    /**
     * @param _fee, marketing wallet fee
     *
     * @dev set Marketing Wallet fee percent
     **/
    function setMarketingWalletFee(uint256 _fee) external onlyOwner {
        require(_fee <= 100, "EG: The fee should be less than 100%");

        uint256 prevFee = marketingWalletFee;

        marketingWalletFee = _fee;
        emit MarketingWalletFeeUpdated(prevFee, marketingWalletFee);
    }

    /**
     * @param _wallet, liquidity wallet address
     *
     * @dev set Liquidity Wallet Address
     **/
    function setLiquidityWallet(address _wallet) external onlyOwner {
        require(
            _wallet != address(0),
            "EG: The liquidity wallet should not be the zero address"
        );

        address prevAddress = liquidityWallet;

        liquidityWallet = _wallet;
        emit LiquidityWalletUpdated(prevAddress, liquidityWallet);
    }

    /**
     * @param _fee, liquidity wallet fee
     *
     * @dev set Liquidity Wallet fee percent
     **/
    function setLiquidityWalletFee(uint256 _fee) external onlyOwner {
        require(_fee <= 100, "EG: The fee should be less than 100%");

        uint256 prevFee = liquidityWalletFee;

        liquidityWalletFee = _fee;
        emit LiquidityWalletFeeUpdated(prevFee, liquidityWalletFee);
    }

    /**
     * @param _wallet, tech wallet address
     *
     * @dev set Tech Wallet Address
     **/
    function setTechWallet(address _wallet) external onlyOwner {
        require(
            _wallet != address(0),
            "EG: The tech wallet should not be the zero address"
        );

        address prevAddress = techWallet;

        techWallet = _wallet;

        emit TechWalletUpdated(prevAddress, techWallet);
    }

    /**
     * @param _fee, tech wallet fee
     *
     * @dev set Tech Wallet fee percent
     **/
    function setTechWalletFee(uint256 _fee) external onlyOwner {
        require(_fee <= 100, "EG: The fee should be less than 100%");

        uint256 prevFee = techWalletFee;

        techWalletFee = _fee;

        emit TechWalletFeeUpdated(prevFee, techWalletFee);
    }

    /**
     * @param _wallet, donation wallet address
     *
     * @dev set Donation Wallet Address
     **/
    function setDonationsWallet(address _wallet) external onlyOwner {
        require(
            _wallet != address(0),
            "EG: The donation wallet should not be the zero address"
        );

        address prevAddress = donationsWallet;

        donationsWallet = _wallet;
        emit DonationsWalletUpdated(prevAddress, donationsWallet);
    }

    /**
     * @param _fee, donation wallet fee
     *
     * @dev set Donation Wallet fee percent
     **/
    function setDonationsWalletFee(uint256 _fee) external onlyOwner {
        require(_fee <= 100, "EG: The fee should be less than 100%");

        uint256 prevFee = donationsWalletFee;

        donationsWalletFee = _fee;
        emit DonationsWalletFeeUpdated(prevFee, donationsWalletFee);
    }

    /**
     * @param _wallet, staking rewards wallet address
     *
     * @dev set Staking Rewards Wallet Address
     **/
    function setStakingRewardsWallet(address _wallet) external onlyOwner {
        require(
            _wallet != address(0),
            "EG: The staking wallet should not be the zero address"
        );

        address prevAddress = stakingRewardsWallet;

        stakingRewardsWallet = _wallet;
        emit StakingRewardsWalletUpdated(prevAddress, stakingRewardsWallet);
    }

    /**
     * @param _fee, staking rewards fee
     *
     * @dev set Staking Reward Wallet fee percent
     **/
    function setStakingRewardsWalletFee(uint256 _fee) external onlyOwner {
        require(_fee <= 100, "EG: The fee should be less than 100%");

        uint256 prevFee = stakingRewardsWalletFee;

        stakingRewardsWalletFee = _fee;
        emit StakingRewardsWalletFeeUpdated(prevFee, stakingRewardsWalletFee);
    }

    /**
     * @param amount Max txn amount
     *
     * @dev Max Amount allowed per Buy/Sell/Transfer transaction
     **/
    function setMaxTransactionAmount(uint256 amount) external onlyOwner {
        uint256 _prevAmount = maxTransactionAmount;
        maxTransactionAmount = amount;

        emit MaxTransactionAmountUpdated(_prevAmount, maxTransactionAmount);
    }

    /**
     * @param amount Max cooldown txn amount
     *
     * @dev Max transaction amount allowed during cooldown period
     **/
    function setMaxTransactionCoolDownAmount(uint256 amount)
        external
        onlyOwner
    {
        require(amount > 0, "EG: Amount should be a positive number.");
        if (maxTransactionAmount > 0) {
            require(
                amount < maxTransactionAmount,
                "EG: Amount should be less than maxTransactionAmount."
            );
        }

        uint256 _prevAmount = maxTransactionCoolDownAmount;
        maxTransactionCoolDownAmount = amount;

        emit MaxTransactionCoolDownAmountUpdated(
            _prevAmount,
            maxTransactionCoolDownAmount
        );
    }

    /**
     * @param _amount amount
     *
     * @dev calculate buy fee
     **/
    function calculateBuyFee(uint256 _amount) private view returns (uint256) {
        return (_amount * buyFee) / 100;
    }

    /**
     * @param _amount amount
     *
     * @dev calculate sell fee
     **/
    function calculateSellFee(uint256 _amount) private view returns (uint256) {
        return (_amount * sellFee) / 100;
    }

    /**
     * @param _amount amount
     *
     * @dev calculate transfer fee
     **/
    function calculateTransferFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return (_amount * transferFee) / 100;
    }

    /**
     * @param _buyFee. Buy fee percent (0% ~ 99%)
     *
     **/
    function setBuyFee(uint256 _buyFee) external onlyOwner {
        require(_buyFee < 100, "EG: buyFeeRate should be less than 100%");

        uint256 prevValue = buyFee;
        buyFee = _buyFee;
        emit BuyFeeUpdated(prevValue, buyFee);
    }

    /**
     * @param _sellFee. Sell fee percent (0% ~ 99%)
     *
     **/
    function setSellFee(uint256 _sellFee) external onlyOwner {
        require(_sellFee < 100, "EG: sellFeeRate should be less than 100%");

        uint256 prevValue = sellFee;
        sellFee = _sellFee;
        emit SellFeeUpdated(prevValue, sellFee);
    }

    /**
     * @param _transferFee. Transfer fee pcercent (0% ~ 99%)
     *
     **/
    function setTransferFee(uint256 _transferFee) external onlyOwner {
        require(
            _transferFee < 100,
            "EG: transferFeeRate should be less than 100%"
        );

        uint256 prevValue = transferFee;
        transferFee = _transferFee;
        emit TransferFeeUpdated(prevValue, transferFee);
    }

    /**
     * @param account receiver address of transfer
     * @param balance0 token0 balance of account
     * @dev test to see if this tx is part of a Liquidity Add not by Owner
     **/
    function _validateIfLiquidityAdd(address account, uint112 balance0)
        private
        view
    {
        // using the data recorded in _transfer
        if (_lastTransfer.origin == tx.origin) {
            // May be same transaction as _transfer, check LP balances
            address token1 = account.token1();

            if (token1 == address(this)) {
                // Switch token so token1 is always on the other side of pair
                token1 = account.token0();
            }

            // Not LP pair
            if (token1 == address(0)) return;

            uint112 balance1 = uint112(IERC20(token1).balanceOf(account));

            if (
                balance0 > _lastTransfer.balance0 &&
                balance1 > _lastTransfer.balance1
            ) {
                // Both pair balances have increased, this is a Liquidty Add
                require(false, "EG: Liquidity can be added by the owner only");
            } else if (
                balance0 < _lastTransfer.balance0 &&
                balance1 < _lastTransfer.balance1
            ) {
                // Both pair balances have decreased, this is a Liquidty Remove
                require(
                    false,
                    "EG: Liquidity can be removed by the owner only"
                );
            }
        }
    }

    function _balanceOf(address account) private view returns (uint256) {
        return _balances[account];
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(
            !blackList[from] || to == owner(), // allow blacklisted user to send token only to contract owner
            "EG: transfer from the blacklist address is not allowed"
        );
        require(
            !blackList[to],
            "EG: transfer to the blacklist address is not allowed"
        );
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: Transfer amount must be greater than zero");
        require(
            _balances[from] >= amount,
            "ERC20: tokens balance is insufficient"
        );
        require(from != to, "ERC20: Transfer to and from address are the same");
        require(
            !inTokenCheck(),
            "Invalid reentrancy from token0/token1 balanceOf check"
        );

        address _owner = owner();
        bool isIgnoredAddress = from == _owner || to == _owner;

        bool _isTradingEnabled = isTradingEnabled();

        if (!(isIgnoredAddress || whiteList[from])) {
            // allow whitelisted user to transfer unlimited tokens during cooldown.
            if (inTradingStartCoolDown()) {
                // cooldown
                require(
                    amount <= maxTransactionCoolDownAmount,
                    "EG: Transfer amount exceeds the maxTransactionCoolDownAmount"
                );
            } else if (maxTransactionAmount > 0) {
                // after cooldown
                require(
                    amount <= maxTransactionAmount,
                    "EG: Transfer amount exceeds the maxTransactionAmount"
                );
            }
        }

        address _pair = uniswapV2Pair;
        require(
            _isTradingEnabled ||
                isIgnoredAddress ||
                (from != _pair && to != _pair),
            "EG: Trading is not enabled"
        );

        if (
            _isTradingEnabled && inTradingStartCoolDown() && !isIgnoredAddress
        ) {
            validateDuringTradingCoolDown(to, from);
        }

        uint256 takeFee = 0;

        // check buy
        bool _isBuy = from == _pair;
        // check sell
        bool _isSell = to == _pair;
        // is exclude fee
        bool _isNotExcludeFee = !(whiteList[from] || whiteList[to]);

        if (_isNotExcludeFee) {
            if (_isBuy) {
                // liquidity ( buy / sell ) fee
                takeFee = calculateBuyFee(amount);
            } else if (_isSell) {
                // liquidity ( buy / sell ) fee
                takeFee = calculateSellFee(amount);
            } else {
                // transfer fee
                takeFee = calculateTransferFee(amount);
            }
        }

        if (isIgnoredAddress) {
            // Clear transfer data
            _clearTransferIfNeeded();
        } else {
            // Not in a swap during a LP add, so record the transfer details
            _recordPotentialLiquidityAddTransaction(to);
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    /**
     * @dev not a Liquidity Add or isOwner, clear data from same block to allow balanceOf
     *
     **/
    function _clearTransferIfNeeded() private {
        if (_lastTransfer.blockNumber == uint32(block.number)) {
            // Don't need to clear if different block
            _lastTransfer = TransferDetails({
                balance0: 0,
                balance1: 0,
                blockNumber: 0,
                to: address(0),
                origin: address(0)
            });
        }
    }

    /**
     * @dev record the transfer details, will be used to check LP not added by owner
     *
     **/
    function _recordPotentialLiquidityAddTransaction(address to)
        private
        tokenCheck
    {
        uint112 balance0 = uint112(_balanceOf(to));
        address token1 = to.token1();
        if (token1 == address(this)) {
            // Switch token so token1 is always other side of pair
            token1 = to.token0();
        }

        uint112 balance1;
        if (token1 == address(0)) {
            // Not a LP pair, or not yet (contract being created)
            balance1 = 0;
        } else {
            balance1 = uint112(IERC20(token1).balanceOf(to));
        }

        _lastTransfer = TransferDetails({
            balance0: balance0,
            balance1: balance1,
            blockNumber: uint32(block.number),
            to: to,
            origin: tx.origin
        });
    }

    /**
     * @param sender sender
     * @param recipient recipient
     * @param amount amount
     * @param takeFee fee
     *
     * @dev update balances of sender and receiver, add fee to contract balance
     **/
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        uint256 takeFee
    ) private {
        uint256 senderBefore = _balances[sender];
        uint256 senderAfter = senderBefore - amount;
        _balances[sender] = senderAfter;

        uint256 tTransferAmount = amount;

        if (takeFee > 0) {
            _balances[address(this)] = _balances[address(this)] + takeFee;
            tTransferAmount = amount - takeFee;
        }

        uint256 recipientBefore = _balances[recipient];
        uint256 recipientAfter = recipientBefore + tTransferAmount;
        _balances[recipient] = recipientAfter;

        emit Transfer(sender, recipient, tTransferAmount);
    }

    /**
     * @dev withdraw and distribute fee accumulated in smart contract to EG wallets
     **/
    function withdrawTokens() external onlyOwner {
        uint256 amount = _balanceOf(address(this));
        require(amount > 0, "EG: There are no tokens to withdraw.");
        require(
            marketingWalletFee +
                liquidityWalletFee +
                techWalletFee +
                donationsWalletFee +
                stakingRewardsWalletFee <=
                100,
            "EG: Total Fees should not be greater than 100."
        );
        require(
            marketingWallet != address(0),
            "EG: The Marketing wallet is not set."
        );
        require(
            liquidityWallet != address(0),
            "EG: The Liquidity wallet is not set."
        );
        require(techWallet != address(0), "EG: The Tech wallet is not set.");
        require(
            donationsWallet != address(0),
            "EG: The Donations wallet is not set."
        );
        require(
            stakingRewardsWallet != address(0),
            "EG: The Staking Rewards wallet is not set."
        );

        _transfer(
            address(this),
            marketingWallet,
            (amount * marketingWalletFee) / 100
        );
        _transfer(
            address(this),
            liquidityWallet,
            (amount * liquidityWalletFee) / 100
        );
        _transfer(address(this), techWallet, (amount * techWalletFee) / 100);
        _transfer(
            address(this),
            donationsWallet,
            (amount * donationsWalletFee) / 100
        );
        _transfer(
            address(this),
            stakingRewardsWallet,
            (amount * stakingRewardsWalletFee) / 100
        );

        emit WithdrawTokens(amount);
    }

    /**
     * @param token token address
     * @param to receive address
     * @param amount token amount
     *
     * @dev Withdraw any tokens that are sent to the contract address
     **/
    function withdrawAlienTokens(
        address token,
        address payable to,
        uint256 amount
    ) external onlyOwner {
        require(
            token != address(0),
            "EG: The zero address should not be a token."
        );
        require(
            to != address(0),
            "EG: The zero address should not be a transfer address."
        );
        require(
            token != address(this),
            "EG: The token should not be the same as the contract address."
        );

        require(amount > 0, "EG: Amount should be a postive number.");
        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            "EG: Out of balance."
        );

        IERC20Upgradeable(token).safeTransfer(to, amount);

        emit WithdrawAlienTokens(token, to, amount);
    }

    /**
     * @param to receive address
     * @param amount token amount
     *
     * @dev You can withdraw native tokens (BNB) accumulated in the contract address
     **/
    function withdrawNativeTokens(address payable to, uint256 amount)
        external
        onlyOwner
    {
        require(
            to != address(0),
            "EG: The zero address should not be a transfer address."
        );
        require(amount > 0, "EG: Amount should be a postive number.");
        require(
            address(this).balance >= amount,
            "EG: Out of native token balance."
        );

        (bool success, ) = (to).call{value: amount}("");
        require(success, "EG: Withdraw failed");

        emit WithdrawNativeTokens(to, amount);
    }

    function inTokenCheck() private view returns (bool) {
        return _checkingTokens;
    }
}