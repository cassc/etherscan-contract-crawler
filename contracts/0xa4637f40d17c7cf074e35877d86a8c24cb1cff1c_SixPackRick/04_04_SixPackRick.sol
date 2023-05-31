// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import {ERC20UniswapV2InternalSwaps, ERC20} from "./ERC20UniswapV2InternalSwaps.sol";
import {Owned} from "Owned.sol";

/**
 * @title 6 Pack Rick token contract
 *
 * @notice 6PR has a 2% transfer tax, with 50% of tax used for adding liquidity.
 * 6PR is launched as a fair launch with 132 ETH hardcap.
 *
 * https://6packrick.com
 */
contract SixPackRick is
    ERC20("6PackRick", "6PR", 18),
    ERC20UniswapV2InternalSwaps,
    Owned
{
    /** @notice The presale states. */
    enum PresaleState {
        CLOSED,
        OPEN_FOR_WHITELIST,
        OPEN_FOR_PUBLIC,
        COMPLETED
    }

    /** @notice Percentage of supply allocated for presale participants (50%). */
    uint256 public constant SHARE_PRESALE = 50;
    /** @notice Percentage of supply allocated for initial liquidity (30%).*/
    uint256 public constant SHARE_LIQUIDITY = 30;
    /** @notice Percentage of supply allocated for team, marketing, cex listings, etc. (20%). */
    uint256 public constant SHARE_OTHER = 20;
    /** @notice Hardcap in ETH for presale (132 ETH). */
    uint256 public constant PRESALE_HARDCAP = 132 ether;
    /** @notice Per account limit in ETH for presale (0.6 ETH). */
    uint256 public constant PRESALE_ACCOUNT_LIMIT = 0.6 ether;
    /** @notice Minimum threshold in ETH to trigger #swapTokensAndAddLiquidity. */
    uint256 public constant SWAP_THRESHOLD_ETH_MIN = 0.005 ether;
    /** @notice Maximum threshold in ETH to trigger #swapTokensAndAddLiquidity. */
    uint256 public constant SWAP_THRESHOLD_ETH_MAX = 50 ether;
    /** @notice Transfer tax in percent (2%). 50% of this fee is used to add liquidity. */
    uint256 public constant TRANSFER_TAX = 2;

    uint256 private constant _MAX_SUPPLY = 420_690_000_000_000 ether;
    uint256 private constant _SUPPLY_PRESALE =
        (_MAX_SUPPLY * SHARE_PRESALE) / 100;
    uint256 private constant _SUPPLY_LIQUIDITY =
        (_MAX_SUPPLY * SHARE_LIQUIDITY) / 100;
    uint256 private constant _SUPPLY_OTHER =
        _MAX_SUPPLY - _SUPPLY_PRESALE - _SUPPLY_LIQUIDITY;

    /** @notice Tax recipient wallet. */
    address public taxRecipient = 0x9134A698F674D3a0D9154Ce812662526E279A8EF;
    /** @notice Whether address is extempt from transfer tax. */
    mapping(address => bool) public taxFreeAccount;
    /** @notice Whether address is an exchange pool. */
    mapping(address => bool) public isExchangePool;
    /** @notice Threshold in ETH of tokens to collect before triggering #swapTokensAndAddLiquidity. */
    uint256 public swapThresholdEth = 0.1 ether;
    /** @notice Tax manager. @dev Can **NOT** change transfer taxes. */
    address public taxManager;
    /** @notice Whether address is whitelisted for early presale access. */
    mapping(address => bool) public presaleWhitelist;
    /** @notice Presale commitment in ETH per address. */
    mapping(address => uint256) public commitment;
    /** @notice Presale amount of claimed tokens per address. */
    mapping(address => uint256) public claimedTokens;
    /** @notice Presale total commitment in ETH. */
    uint256 public totalCommitments;
    /** @notice Presale total amount of claimed tokens. */
    uint256 public totalClaimed;
    /** @notice Current presale state. */
    PresaleState public presaleState;
    /** @notice Whether buys and sells in the same block are blocked to prevent sandwitch attacks. */
    bool public limitPerBlockTransfers = true;

    /** @notice Anti sniper bot measure for initial opening of trading. */
    uint256 private _tradeableAfterBlock = type(uint256).max;
    /** @notice Anti sandwitch bot measure while limitPerBlockTransfers is enabled. */
    mapping(bytes32 => bool) private _perBlock;

    event CommitedToPresale(address indexed account, uint256 amount);
    event PresaleOpened();
    event TradingEnabled();
    event PublicPresaleOpened();
    event PresaleCompleted(uint256 totalCommitments);
    event PresaleClaimed(address indexed account, uint256 amount);
    event TaxRecipientChanged(address indexed taxRecipient);
    event SwapThresholdChanged(uint256 swapThresholdEth);
    event TaxFreeStateChanged(address indexed account, bool indexed taxFree);
    event ExchangePoolStateChanged(
        address indexed account,
        bool indexed isExchangePool
    );
    event TaxManagerChanged(address indexed taxManager);
    event LimitPerBlockTransfersChangeed(bool indexed limitPerBlockTransfers);
    event SwappedTokensAndAddedLiquidity(
        uint256 tokensSwapped,
        uint256 tokensAddedToLiquidity,
        uint256 wethAddedToLiquidity,
        uint256 wethCollected
    );

    error TradingNotOpenYet();
    error MaxAccountLimitExceeded();
    error HardcapExceeded();
    error NotWhitelistedForPresale();
    error PresaleClosed();
    error PresaleNotCompleted();
    error AlreadyClaimed();
    error NothingCommitted();
    error Unauthorized();
    error InvalidSwapThreshold();
    error NoContract();
    error TradeAlreadyOpend();
    error InvalidBlockDelay();
    error InvalidParameters();
    error InvalidState();
    error NoSameBlockBuySell();
    error ZeroTransfer();
    error NoCommittments();
    error TransferToZeroAddress();

    modifier onlyTaxManager() {
        if (msg.sender != taxManager) {
            revert Unauthorized();
        }
        _;
    }

    constructor() Owned(msg.sender) {
        taxManager = msg.sender;
        emit TaxManagerChanged(msg.sender);

        taxFreeAccount[msg.sender] = true;
        emit TaxFreeStateChanged(msg.sender, true);
        taxFreeAccount[taxRecipient] = true;
        emit TaxFreeStateChanged(taxRecipient, true);
        isExchangePool[pair] = true;
        emit ExchangePoolStateChanged(pair, true);

        _mint(address(this), _SUPPLY_PRESALE + _SUPPLY_LIQUIDITY);
        _mint(msg.sender, _SUPPLY_OTHER);
    }

    /** @dev Users can send ETH directly to **this** contract to participate */
    receive() external payable {
        commitToPresale();
    }

    /** @notice IERC20#transfer */
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        if (amount == 0) {
            revert ZeroTransfer();
        }
        if (to == address(0)) {
            revert TransferToZeroAddress();
        }
        if (!taxFreeAccount[msg.sender] && !taxFreeAccount[to]) {
            if (block.number <= _tradeableAfterBlock) {
                revert TradingNotOpenYet();
            }
            if (limitPerBlockTransfers) {
                _enforceTransferLimit(msg.sender, to);
            }

            uint256 fee = (amount * TRANSFER_TAX) / 100;
            super.transfer(address(this), fee);
            unchecked {
                amount -= fee;
            }

            if (isExchangePool[to]) {
                _swapTokensAndAddLiquidity(swapThresholdToken());
            }
        }
        return super.transfer(to, amount);
    }

    /** @notice IERC20#transferFrom */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        if (amount == 0) {
            revert ZeroTransfer();
        }
        if (to == address(0)) {
            revert TransferToZeroAddress();
        }
        if (
            !taxFreeAccount[from] &&
            !taxFreeAccount[to] &&
            !taxFreeAccount[msg.sender]
        ) {
            if (block.number <= _tradeableAfterBlock) {
                revert TradingNotOpenYet();
            }
            if (limitPerBlockTransfers) {
                _enforceTransferLimit(from, to);
            }

            uint256 fee = (amount * TRANSFER_TAX) / 100;
            super.transferFrom(from, address(this), fee);
            unchecked {
                amount -= fee;
            }

            if (isExchangePool[to]) {
                _swapTokensAndAddLiquidity(swapThresholdToken());
            }
        }
        return super.transferFrom(from, to, amount);
    }

    // *** Tax Manager Interface ***

    /**
     * @notice Set `taxFree` state of `account`.
     * @param account account
     * @param taxFree true if `account` should be extempt from transfer taxes.
     * @dev Only callable by taxManager.
     */
    function setTaxFreeAccount(
        address account,
        bool taxFree
    ) external onlyTaxManager {
        if (taxFreeAccount[account] == taxFree) {
            revert InvalidParameters();
        }
        taxFreeAccount[account] = taxFree;
        emit TaxFreeStateChanged(account, taxFree);
    }

    /**
     * @notice Set `exchangePool` state of `account`
     * @param account account
     * @param exchangePool whether `account` is an exchangePool
     * @dev ExchangePool state is used to decide if transfer is a swap
     * and should trigger #swapTokensAndAddLiquidity.
     */
    function setExchangePool(
        address account,
        bool exchangePool
    ) external onlyTaxManager {
        if (isExchangePool[account] == exchangePool) {
            revert InvalidParameters();
        }
        isExchangePool[account] = exchangePool;
        emit ExchangePoolStateChanged(account, exchangePool);
    }

    /**
     * @notice Transfer taxManager role to `newTaxManager`.
     * @param newTaxManager new taxManager
     * @dev Only callable by taxManager.
     */
    function transferTaxManager(address newTaxManager) external onlyTaxManager {
        if (newTaxManager == taxManager) {
            revert InvalidParameters();
        }
        taxManager = newTaxManager;
        emit TaxManagerChanged(newTaxManager);
    }

    /**
     * @notice Change the amount of tokens collected via tax before a swap is triggered.
     * @param newSwapThresholdEth new threshold received in ETH
     * @dev Only callable by taxManager
     */
    function setSwapThresholdEth(
        uint256 newSwapThresholdEth
    ) external onlyTaxManager {
        if (
            newSwapThresholdEth < SWAP_THRESHOLD_ETH_MIN ||
            newSwapThresholdEth > SWAP_THRESHOLD_ETH_MAX ||
            newSwapThresholdEth == swapThresholdEth
        ) {
            revert InvalidSwapThreshold();
        }
        swapThresholdEth = newSwapThresholdEth;
        emit SwapThresholdChanged(newSwapThresholdEth);
    }

    /**
     * @notice Set whether or not to limit buy/sells to single per block to prevent
     * sandwitch attacks.
     * @param newLimitPerBlockTransfers new state
     * @dev Only callable by taxManager
     */
    function setLimitPerBlockTransfers(
        bool newLimitPerBlockTransfers
    ) external onlyTaxManager {
        if (newLimitPerBlockTransfers == limitPerBlockTransfers) {
            revert InvalidParameters();
        }
        limitPerBlockTransfers = newLimitPerBlockTransfers;
        emit LimitPerBlockTransfersChangeed(newLimitPerBlockTransfers);
    }

    /**
     * @notice Change the address receiving the 1% tax in WETH.
     * @param newTaxRecipient new adddress receiving the 1% tax in WETH.
     * @dev Only callable by taxManager.
     */
    function setTaxRecipient(address newTaxRecipient) external onlyTaxManager {
        if (newTaxRecipient == address(0) || taxRecipient == newTaxRecipient) {
            revert InvalidParameters();
        }
        taxRecipient = newTaxRecipient;
        emit TaxRecipientChanged(newTaxRecipient);
    }

    // *** presale interface ***

    /**
     * @notice Whitelist wallet addresses for ealry presale access.
     * @param accounts accounts to whitelist
     */
    function whitelistForPresale(
        address[] calldata accounts
    ) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; ++i) {
            presaleWhitelist[accounts[i]] = true;
        }
    }

    /**
     * @notice Open presale for whitelisted users.
     * @dev Called after #whitelistForPresale.
     */
    function openPresale() external onlyOwner {
        if (presaleState != PresaleState.CLOSED) {
            revert InvalidState();
        }
        presaleState = PresaleState.OPEN_FOR_WHITELIST;
        emit PresaleOpened();
    }

    /**
     * @notice Open presale for all users.
     * @dev Called after #openPresale.
     */
    function openPublicPresale() external onlyOwner {
        if (presaleState != PresaleState.OPEN_FOR_WHITELIST) {
            revert InvalidState();
        }
        presaleState = PresaleState.OPEN_FOR_PUBLIC;
        emit PublicPresaleOpened();
    }

    /**
     * @notice Complete the presale.
     * @dev Adds 60% of collected ETH with 30% of totalSupply to Liquidity.
     * Sends the remaining 40% of collected ETH to current owner.
     * Called after #openPublicPresale.
     */
    function completePresale() external onlyOwner {
        if (presaleState != PresaleState.OPEN_FOR_PUBLIC) {
            revert InvalidState();
        }
        if (totalCommitments == 0) {
            revert NoCommittments();
        }

        presaleState = PresaleState.COMPLETED;

        uint256 amountEthForLiquidity = (totalCommitments * _SUPPLY_LIQUIDITY) /
            _SUPPLY_PRESALE;
        _addInitialLiquidityEth(
            _SUPPLY_LIQUIDITY,
            amountEthForLiquidity,
            msg.sender
        );

        _sweepEth(msg.sender);

        emit PresaleCompleted(totalCommitments);
    }

    /**
     * @notice Enable trading.
     * @param blocksDelay variable number of blocks to delay the actual start of trading, [1-5].
     * @dev Exact start is delayed a variable amount of 1-5 blocks to make it harder for automated bots.
     * Called after #completePresale.
     */
    function enableTrading(uint256 blocksDelay) external onlyOwner {
        if (_tradeableAfterBlock != type(uint256).max) {
            revert TradeAlreadyOpend();
        }
        if (blocksDelay == 0 || blocksDelay > 5) {
            revert InvalidBlockDelay();
        }
        if (presaleState != PresaleState.COMPLETED) {
            revert PresaleNotCompleted();
        }
        _tradeableAfterBlock = block.number + blocksDelay;
        emit TradingEnabled();

        // renounce ownership
        transferOwnership(address(0));
    }

    /**
     * @notice Claim callers presale tokens.
     * @dev Callable once presaleCompleted.
     */
    function claimPresale() external {
        address account = msg.sender;

        if (_isContract(account)) {
            revert NoContract();
        }
        if (presaleState != PresaleState.COMPLETED) {
            revert PresaleNotCompleted();
        }
        if (commitment[account] == 0) {
            revert NothingCommitted();
        }
        if (claimedTokens[account] != 0) {
            revert AlreadyClaimed();
        }

        uint256 amountTokens = (_SUPPLY_PRESALE * commitment[account]) /
            totalCommitments;
        claimedTokens[account] = amountTokens;
        totalClaimed += amountTokens;

        _transferFromContractBalance(account, amountTokens);

        emit PresaleClaimed(account, amountTokens);
    }

    /** @notice Returns amount of tokens to be claimed by presale participants. */
    function unclaimedSupply() external view returns (uint256) {
        return _SUPPLY_PRESALE - totalClaimed;
    }

    /**
     * @notice Returns false if trading was not enabled yet.
     * Trading can not be paused once enabled.
     */
    function isTradeOpen() external view returns (bool) {
        return block.number > _tradeableAfterBlock;
    }

    /**
     * @notice Commit ETH to presale.
     * Presale supply is claimable proportionally for all presale participants.
     * Presale has a 132 ETH hardcap and 0.6 ETH per wallet limit.
     * Users can also send ETH directly to **this** contract to participate.
     * @dev Callable once presaleOpen.
     */
    function commitToPresale() public payable {
        address account = msg.sender;
        if (_isContract(account)) {
            revert NoContract();
        }
        if (
            presaleState == PresaleState.OPEN_FOR_WHITELIST &&
            !presaleWhitelist[account]
        ) {
            revert NotWhitelistedForPresale();
        }
        if (
            presaleState != PresaleState.OPEN_FOR_WHITELIST &&
            presaleState != PresaleState.OPEN_FOR_PUBLIC
        ) {
            revert PresaleClosed();
        }

        commitment[account] += msg.value;
        totalCommitments += msg.value;

        if (totalCommitments > PRESALE_HARDCAP) {
            revert HardcapExceeded();
        }
        if (commitment[account] > PRESALE_ACCOUNT_LIMIT) {
            revert MaxAccountLimitExceeded();
        }

        emit CommitedToPresale(account, msg.value);
    }

    /**
     * @notice Threshold of how many tokens to collect from tax before
     * calling #swapTokensAndAddLiquidity.
     * @dev Depends on swapThresholdEth which can be configured by taxManager.
     * Restricted to 5% of liquidity.
     */
    function swapThresholdToken() public view returns (uint256) {
        (uint reserveToken, uint reserveWeth) = _getReserve();
        uint256 maxSwapEth = (reserveWeth * 5) / 100;
        return
            _getAmountToken(
                swapThresholdEth > maxSwapEth ? maxSwapEth : swapThresholdEth,
                reserveToken,
                reserveWeth
            );
    }

    /**
     * @notice Swap 3/4 of `amountToken` collected from tax to WETH to add to
     * liquidity and send to taxRecipient.
     */
    function _swapTokensAndAddLiquidity(uint256 amountToken) internal {
        if (
            balanceOf[address(this)] + totalClaimed <
            amountToken + _SUPPLY_PRESALE
        ) {
            return;
        }

        uint256 amountToSell = (amountToken * 3) / 4;
        uint256 amountToAddToLiquidity = amountToken - amountToSell;

        _swapForWETH(amountToSell, address(this));

        uint256 amountWethAddedToLiquidity = _addLiquidity(
            amountToAddToLiquidity,
            address(0xdead)
        );
        uint256 amountWethCollected = _sweepWeth(taxRecipient);

        emit SwappedTokensAndAddedLiquidity(
            amountToSell,
            amountToAddToLiquidity,
            amountWethAddedToLiquidity,
            amountWethCollected
        );
    }

    /**
     * @dev Enforce a one buy/sell per block limit to prevent sandwitch attacks.
     * These checks come with a gas cost tradeoff and can be configured via
     * limitPerBlockTransfers.
     * @param from sender
     * @param to receiver
     */
    function _enforceTransferLimit(address from, address to) internal {
        bool toPool = isExchangePool[to];
        bool fromPool = isExchangePool[from];
        if (fromPool && !toPool) {
            bytes32 key = keccak256(abi.encodePacked(block.number, to));
            if (_perBlock[key]) {
                revert NoSameBlockBuySell();
            }
            _perBlock[key] = true;
        } else if (!fromPool && toPool) {
            bytes32 key = keccak256(abi.encodePacked(block.number, from));
            if (_perBlock[key]) {
                revert NoSameBlockBuySell();
            }
            _perBlock[key] = true;
        }
    }
}
