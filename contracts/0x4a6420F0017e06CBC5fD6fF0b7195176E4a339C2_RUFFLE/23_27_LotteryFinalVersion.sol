//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./ILottery.sol";
import "./SortitionSumTreeFactory.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./AdvancedTaxFinal.sol";
import "./Multisig.sol";

import "./IPermissions.sol";

contract RUFFLE is ERC20, AdvancedTax {
    using SafeMath for uint256;

    modifier lockSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    modifier liquidityAdd() {
        _inLiquidityAdd = true;
        _;
        _inLiquidityAdd = false;
    }

    //Token
    uint256 public constant MAX_SUPPLY = 1_000_000_000 ether;
    uint256 public constant maxWallet = 10_000_000 ether; //1%

    mapping(address => uint256) private _balances;
    mapping(address => uint256) private lastBuy;

    /// @notice Contract RUFFLE balance threshold before `_swap` is invoked
    uint256 public minTokenBalance = 9_490_000 ether; //This is the max amount you can win with a 500k buy to not go over max wallet
    bool public swapFees = true;

    //Uniswap
    IUniswapV2Router02 internal _router = IUniswapV2Router02(address(0));
    address internal _pair;
    bool internal _inSwap = false;
    bool internal _inLiquidityAdd = false;
    bool public tradingActive = false;
    uint256 public tradingActiveBlock;
    uint256 public deadBlocks = 2;
    uint256 public cooldown = 45;

    IPermissions public permission;

    event EnableTrading(bool tradingEnabled);
    event RescueLottery(address to, uint256 amount);
    event RescueMarketing(address to, uint256 amount);
    event SetCooldown(uint256 oldCooldown, uint256 newCooldown);
    event SetMinTokenBalance(
        uint256 oldMinTokenBalance,
        uint256 newMinTokenBalance
    );
    event SetSwapFees(bool newValue);
    event Win0SellTax(address indexed winner, bool won);

    event PermissionChanged(address previousPermission, address nextPermission);

    constructor(
        address _uniswapFactory,
        address _uniswapRouter,
        address payable _lotteryWallet,
        address payable _marketingWallet,
        address payable _apadWallet,
        address payable _acapWallet
    ) ERC20("Ruffle Inu", "RUFFLE") Ownable() {
        addTaxExcluded(owner());
        addTaxExcluded(address(0));
        addTaxExcluded(_lotteryWallet);
        addTaxExcluded(_apadWallet);
        addTaxExcluded(_acapWallet);
        addTaxExcluded(address(this));
        addTaxExcluded(_marketingWallet);
        setChanceToWinSellTax(100);
        setChanceToWinLastBuy(200);
        setChanceToWin0SellTax(50);
        _mint(address(this), MAX_SUPPLY);
        lotteryWallet = _lotteryWallet;
        marketingWallet = _marketingWallet;
        acapWallet = _acapWallet;
        apadWallet = _apadWallet;
        _router = IUniswapV2Router02(_uniswapRouter);
        IUniswapV2Factory uniswapContract = IUniswapV2Factory(_uniswapFactory);
        _pair = uniswapContract.createPair(address(this), _router.WETH());
        _secretNumber = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, block.difficulty, msg.sender)
            )
        );
    }

    //receive function
    receive() external payable {}

    /// @notice Add liquidity to uniswap
    /// @param tokens The number of tokens to add liquidity is added
    function addLiquidity(uint256 tokens)
        external
        payable
        onlyOwner
        liquidityAdd
    {
        _approve(address(this), address(_router), tokens);
        _router.addLiquidityETH{value: msg.value}(
            address(this),
            tokens,
            0,
            0,
            owner(),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );
    }

    /// @notice a function to mint and airdrop tokens to an array of accounts
    /// @dev Only use this before adding liquidity and enable trade. Protected by multisig
    function airdrop(address[] memory accounts, uint256[] memory amounts)
        external
        onlyOwner
    {
        require(accounts.length == amounts.length, "array lengths must match");
        for (uint256 i = 0; i < accounts.length; i++) {
            _rawTransfer(address(this), accounts[i], amounts[i]);
        }
    }

    /// @notice Disables trading on Uniswap
    function disableTrading() external onlyOwner {
        require(tradingActive);
        tradingActive = false;
        emit EnableTrading(false);
    }

    /// @notice Enables trading on Uniswap
    /// @param _deadBlocks the number of deadBlocks before trading is open
    function enableTrading(uint256 _deadBlocks) external onlyOwner {
        require(!tradingActive);
        tradingActive = true;
        tradingActiveBlock = block.number;
        deadBlocks = _deadBlocks;
        emit EnableTrading(true);
    }

    /// @notice Rescue ruffle from the lottery
    /// @dev Should only be used in an emergency. Protected by multisig apad
    /// @param amount The amount of ruffle to rescue
    /// @param recipient The recipient of the rescued ruffle
    function rescueLotteryTokens(uint256 amount, address recipient)
        external
        onlyMultisig
    {
        require(
            amount <= totalLottery,
            "Amount cannot be greater than totalLottery"
        );
        _rawTransfer(address(this), recipient, amount);
        totalLottery = totalLottery.sub(amount);
        emit RescueLottery(recipient, amount);
    }

    /// @notice Rescue ruffle from marketing
    /// @dev Should only be used in an emergency. Protected by multisig APAD
    /// @param amount The amount of ruffle to rescue
    /// @param recipient The recipient of the rescued ruffle
    function rescueMarketingTokens(uint256 amount, address recipient)
        external
        onlyMultisig
    {
        require(
            amount <= totalMarketing,
            "Amount cannot be greater than totalMarketing"
        );
        _rawTransfer(address(this), recipient, amount);
        totalMarketing = totalMarketing.sub(amount);
        emit RescueMarketing(recipient, amount);
    }

    /// @notice Change the cooldown for buys
    /// @param _cooldown The new cooldown in seconds
    function setCooldown(uint256 _cooldown) external onlyOwner {
        uint256 _oldValue = cooldown;
        cooldown = _cooldown;
        emit SetCooldown(_oldValue, _cooldown);
    }

    /// @notice Change the minimum contract ruffle balance before `_swap` gets invoked
    /// @param _minTokenBalance The new minimum balance
    function setMinimumTokenBalance(uint256 _minTokenBalance)
        external
        onlyOwner
    {
        require(
            _minTokenBalance < maxWallet,
            "the minimum token balance cannot exceed the maximum wallet"
        );
        uint256 _oldValue = minTokenBalance;
        minTokenBalance = _minTokenBalance;
        emit SetMinTokenBalance(_oldValue, _minTokenBalance);
    }

    /// @notice Enable or disable whether swap occurs during `_transfer`
    /// @param _swapFees If true, enables swap during `_transfer`
    function setSwapFees(bool _swapFees) external onlyOwner {
        swapFees = _swapFees;
        emit SetSwapFees(_swapFees);
    }

    /// @notice Change the whitelist
    /// @param _permission The new whitelist contract
    function setPermissions(IPermissions _permission) external onlyOwner {
        emit PermissionChanged(address(permission), address(_permission));
        permission = _permission;
    }

    /// @notice A function to swap the tokens to eth and send them to marketing,lottery,acap and apad
    /// @notice keeps a minimum balance of tokens in the contract to pay out winners
    function swapAll() external onlyOwner {
        uint256 contractTokenBalance = balanceOf(address(this));

        if (!_inSwap) {
            uint256 _amountAboveMinimumBalance = contractTokenBalance.sub(
                minTokenBalance
            );
            _swap(_amountAboveMinimumBalance);
        }
    }

    /// @notice Function to withdraw all ETH funds from the contract balance
    /// @dev Only in emergency. Protected by multisig APAD
    function withdrawEth() external onlyMultisig {
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Function to withdraw the ERC20 from the contract balance
    /// @dev Only in emergency. Protected by multisig APAD
    function withdrawTokens() external onlyMultisig {
        _rawTransfer(address(this), msg.sender, balanceOf(address(this)));
    }

    /// @notice Gets the token balance of an address
    /// @param account The address that we want to get the token balance for
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function _addBalance(address account, uint256 amount) internal {
        _balances[account] = _balances[account].add(amount);
    }

    function _subtractBalance(address account, uint256 amount) internal {
        _balances[account] = _balances[account].sub(amount);
    }

    /// @notice A function that overrides the standard transfer function and takes into account the taxes
    /// @param sender The sender of the tokens
    /// @param recipient The receiver of the tokens
    /// @param amount The number of tokens that is being sent
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (isTaxExcluded(sender) || isTaxExcluded(recipient)) {
            _rawTransfer(sender, recipient, amount);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= minTokenBalance;

        if (sender != _pair && recipient != _pair) {
            uint256 _lotteryUserBalance = ILottery(lotteryWallet).getBalance(
                recipient
            );
            require(
                amount.add(balanceOf(recipient)).add(_lotteryUserBalance) <
                    maxWallet,
                "the recipient cannot own more than 1 percent of all tokens"
            );
            _rawTransfer(sender, recipient, amount);
        }
        if (overMinTokenBalance && !_inSwap && sender != _pair && swapFees) {
            uint256 _amountAboveMinimumBalance = contractTokenBalance -
                minTokenBalance;
            _swap(_amountAboveMinimumBalance);
        }
        if (address(permission) != address(0)) {
            require(
                permission.isWhitelisted(recipient),
                "User is not whitelisted to buy"
            );
            require(
                amount <= permission.buyLimit(recipient),
                "Buy limit exceeded"
            );
        }
        require(tradingActive, "Trading is not yet active");
        if (sender == _pair) {
            if (cooldown > 0) {
                require(
                    lastBuy[recipient] + cooldown <= block.timestamp,
                    "Cooldown is still active"
                );
            }
            _buyOrder(sender, recipient, amount);
        } else if (recipient == _pair) {
            _sellOrder(sender, recipient, amount);
        }
    }

    /// @notice A function that is being run when someone buys the token
    /// @param sender The pair
    /// @param recipient The receiver of the tokens
    /// @param amount The number of tokens that is being sent
    function _buyOrder(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        uint256 send = amount;
        uint256 marketing;
        uint256 lottery;
        uint256 acap;
        uint256 apad;
        uint256 buyTax;

        (send, buyTax, marketing, lottery, acap, apad) = _getBuyTaxInfo(
            amount,
            recipient
        );
        taxPercentagePaidByUser[recipient] = buyTax;
        if (buyWinnersActive && amount >= minimumBuyToWin) {
            uint256 amountWon = _getAmountWonOnBuy(recipient, amount, send);
            uint256 amountToTransfer;
            if (amountWon <= totalLottery) {
                amountToTransfer = amountWon;
            } else {
                amountToTransfer = totalLottery;
            }
            _rawTransfer(address(this), recipient, amountToTransfer);
            totalLottery = totalLottery.sub(amountToTransfer);
            amountWonOnBuy[recipient] += amountToTransfer;
            if (amountToTransfer != 0) {
                totalWinners += 1;
                lastAmountWon = amountToTransfer;
                totalTokensWon = totalTokensWon.add(amountToTransfer);
                lastBuyWinner = recipient;
                //               emit BuyWinner(recipient, amountToTransfer);
            }
        }
        require(
            send.add(balanceOf(recipient)).add(
                ILottery(lotteryWallet).getBalance(recipient)
            ) <= maxWallet,
            "you cannot own more than 1 percent of the tokens per wallet"
        );
        _rawTransfer(sender, recipient, send);
        _takeTaxes(sender, marketing, lottery, acap, apad);
        lastBuyAmount = amount;
        lastBuy[recipient] = block.timestamp;
    }

    function _getAmountToMaxWallet(address recipient, uint256 send)
        internal
        returns (uint256)
    {
        uint256 _amountToMaxWallet = maxWallet
            .sub(send)
            .sub(balanceOf(recipient))
            .sub(ILottery(lotteryWallet).getBalance(recipient));
        return _amountToMaxWallet;
    }

    function _getAmountWonOnBuy(
        address recipient,
        uint256 amount,
        uint256 send
    ) internal returns (uint256) {
        uint256 _randomNumberBuyAmount = _getPseudoRandomNumber(
            chanceToWinLastBuy,
            send,
            recipient
        );
        uint256 _randomNumberLastSellTax = _getPseudoRandomNumber(
            chanceToWinSellTax,
            send,
            recipient
        );
        uint256 _winningNumberBuy = _secretNumber.mod(chanceToWinLastBuy);
        uint256 _winningNumberSellTax = _secretNumber.mod(chanceToWinSellTax);
        uint256 amountToMaxWallet = _getAmountToMaxWallet(recipient, send);
        uint256 amountWonToTransfer;
        if (
            _randomNumberBuyAmount == _winningNumberBuy &&
            wonLastBuy[recipient] == false
        ) {
            if (lastBuyAmount <= amountToMaxWallet) {
                amountWonToTransfer = lastBuyAmount;
            } else {
                amountWonToTransfer = amountToMaxWallet;
            }
            wonLastBuy[recipient] = true;
        } else if (_randomNumberLastSellTax == _winningNumberSellTax) {
            if (lastSellTax <= amountToMaxWallet) {
                amountWonToTransfer = lastSellTax;
            } else {
                amountWonToTransfer = amountToMaxWallet;
            }
        }
        return amountWonToTransfer;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _mint(address account, uint256 amount) internal override {
        require(_totalSupply.add(amount) <= MAX_SUPPLY, "Max supply exceeded");
        _totalSupply = _totalSupply.add(amount);
        _addBalance(account, amount);
        emit Transfer(address(0), account, amount);
    }

    function _rawTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");

        uint256 senderBalance = balanceOf(sender);
        require(senderBalance >= amount, "transfer amount exceeds balance");
        unchecked {
            _subtractBalance(sender, amount);
        }
        _addBalance(recipient, amount);

        emit Transfer(sender, recipient, amount);
    }

    /// @notice A function that is being run when someone sells a token
    /// @param sender The sender of the tokens
    /// @param recipient the uniswap pair
    /// @param amount The number of tokens that is being sent
    function _sellOrder(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        uint256 send = amount;
        uint256 marketing;
        uint256 lottery;
        uint256 totalTax;
        uint256 acap;
        uint256 apad;
        (send, totalTax, marketing, lottery, acap, apad) = _getSellTaxInfo(
            amount,
            recipient
        );
        if (totalTax == 0) {
            won0SellTax[sender] = true;
            _rawTransfer(sender, recipient, send);
            totalWinners += 1;
            emit Win0SellTax(sender, true);
        } else {
            _rawTransfer(sender, recipient, send);
            _takeTaxes(sender, marketing, lottery, acap, apad);
            uint256 _sellTaxRefundPercentage = _getSellTaxPercentage(
                amount,
                recipient
            );
            uint256 refund;
            refund = _sellTaxRefundPercentage.mul(amount).div(100);
            if (refund <= totalLottery) {
                lastSellTax = totalTax.sub(refund);
                totalLottery = totalLottery.sub(refund);
                if (refund != 0) {
                    _rawTransfer(address(this), recipient, refund);
                }
            }
        }
    }

    /// @notice Perform a Uniswap v2 swap from ruffle to ETH and handle tax distribution
    /// @param amount The amount of ruffle to swap in wei
    /// @dev `amount` is always <= this contract's ETH balance. Calculate and distribute marketing taxes
    function _swap(uint256 amount) internal lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        _approve(address(this), address(_router), amount);

        uint256 contractEthBalance = address(this).balance;

        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 tradeValue = address(this).balance.sub(contractEthBalance);

        uint256 totalTaxes = totalMarketing
            .add(totalLottery)
            .add(totalAcap)
            .add(totalApad);
        uint256 marketingAmount = amount.mul(totalMarketing).div(totalTaxes);
        uint256 lotteryAmount = amount.mul(totalLottery).div(totalTaxes);
        uint256 acapAmount = amount.mul(totalAcap).div(totalTaxes);
        uint256 apadAmount = amount.mul(totalApad).div(totalTaxes);

        uint256 marketingEth = tradeValue.mul(totalMarketing).div(totalTaxes);
        uint256 lotteryEth = tradeValue.mul(totalLottery).div(totalTaxes);
        uint256 acapEth = tradeValue.mul(totalAcap).div(totalTaxes);
        uint256 apadEth = tradeValue.mul(totalApad).div(totalTaxes);

        if (marketingEth > 0) {
            marketingWallet.transfer(marketingEth);
        }
        if (lotteryEth > 0) {
            lotteryWallet.transfer(lotteryEth);
        }
        if (acapEth > 0) {
            acapWallet.transfer(acapEth);
        }
        if (apadEth > 0) {
            apadWallet.transfer(apadEth);
        }
        totalMarketing = totalMarketing.sub(marketingAmount);
        totalLottery = totalLottery.sub(lotteryAmount);
        totalAcap = totalAcap.sub(acapAmount);
        totalApad = totalApad.sub(apadAmount);
    }

    /// @notice Transfers ruffle from an account to this contract for taxes
    /// @param _account The account to transfer ruffle from
    /// @param _marketingAmount The amount of marketing tax to transfer
    /// @param _lotteryAmount The amount of treasury tax to transfer
    function _takeTaxes(
        address _account,
        uint256 _marketingAmount,
        uint256 _lotteryAmount,
        uint256 _acapAmount,
        uint256 _apadAmount
    ) internal {
        require(_account != address(0), "taxation from the zero address");

        uint256 totalAmount = _marketingAmount
            .add(_lotteryAmount)
            .add(_acapAmount)
            .add(_apadAmount);
        _rawTransfer(_account, address(this), totalAmount);
        totalMarketing = totalMarketing.add(_marketingAmount);
        totalLottery = totalLottery.add(_lotteryAmount);
        totalAcap = totalAcap.add(_acapAmount);
        totalApad = totalApad.add(_apadAmount);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
}

import "./SortitionSumTreeFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Lottery is Ownable, VRFConsumerBaseV2, IERC721Receiver, Multisig {
    using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    mapping(address => bool) internal _whitelistedServices;

    IERC721 public nft721;
    uint256 public nftId;
    IERC20 public customToken;
    IERC20 public ruffle;

    address payable[] public selectedWinners;
    address[] public lastWinners;
    uint256[] public winningNumbers;
    uint256 public jackpot;
    uint256 public lastJackpot;
    uint256 public totalEthPaid;
    uint256 public totalWinnersPaid;
    uint256[] public percentageOfJackpot = [75, 18, 7];
    mapping(address => uint256) public amountWonByUser;

    enum Status {
        NotStarted,
        Started,
        WinnersSelected,
        WinnerPaid
    }
    Status public status;

    enum LotteryType {
        NotStarted,
        Ethereum,
        Token,
        NFT721
    }
    LotteryType public lotteryType;

    //Staking
    uint256 public totalStaked;
    mapping(address => uint256) public balanceOf;
    bool public stakingEnabled;

    //Variables used for the sortitionsumtrees
    bytes32 private constant TREE_KEY = keccak256("Lotto");
    uint256 private constant MAX_TREE_LEAVES = 5;

    // Ticket-weighted odds
    SortitionSumTreeFactory.SortitionSumTrees internal sortitionSumTrees;

    // Chainlink
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    uint64 s_subscriptionId;

    // Mainnet coordinator. 0x271682DEB8C4E0901D1a1550aD2e64D568E69909
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address constant vrfCoordinator =
        0x271682DEB8C4E0901D1a1550aD2e64D568E69909;

    // Mainnet LINK token contract. 0x514910771af9ca656af840dff83e8264ecf986ca
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address constant link = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

    // 200 gwei Key Hash lane for chainlink mainnet
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 constant keyHash =
        0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;

    uint32 constant callbackGasLimit = 500000;
    uint16 constant requestConfirmations = 3;

    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 3;

    uint256[] public s_randomWords;
    uint256 public s_requestId;
    address s_owner;

    event AddWhitelistedService(address newWhitelistedAddress);
    event RemoveWhitelistedService(address removedWhitelistedAddress);
    event SetCustomToken(IERC20 tokenAddress);
    event SetRuffleInuToken(IERC20 ruffleInuTokenAddress);
    event Staked(address indexed account, uint256 amount);
    event Unstaked(address indexed account, uint256 amount);
    event SetERC721(IERC721 nft);
    event SetPercentageOfJackpot(
        uint256[] newJackpotPercentages,
        uint256 newNumWords
    );
    event UpdateSubscription(
        uint256 oldSubscriptionId,
        uint256 newSubscriptionId
    );
    event EthLotteryStarted(uint256 jackpot, uint256 numberOfWinners);
    event TokenLotteryStarted(uint256 jackpot, uint256 numberOfWinners);
    event NFTLotteryStarted(uint256 nftId);
    event PayWinnersEth(address[] winners);
    event PayWinnersTokens(address[] winners);
    event PayWinnerNFT(address[] winners);
    event SetStakingEnabled(bool stakingEnabled);

    constructor(uint64 subscriptionId, address payable _gelatoOp)
        VRFConsumerBaseV2(vrfCoordinator)
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
        sortitionSumTrees.createTree(TREE_KEY, MAX_TREE_LEAVES);
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
        addWhitelistedService(_gelatoOp);
        addWhitelistedService(msg.sender);
    }

    modifier onlyWhitelistedServices() {
        require(
            _whitelistedServices[msg.sender] == true,
            "onlyWhitelistedServices can perform this action"
        );
        _;
    }

    modifier lotteryNotStarted() {
        require(
            status == Status.NotStarted || status == Status.WinnerPaid,
            "lottery has already started"
        );
        require(
            lotteryType == LotteryType.NotStarted,
            "the previous winner has to be paid before starting a new lottery"
        );
        _;
    }

    modifier winnerPayable() {
        require(
            status == Status.WinnersSelected,
            "the winner is not yet selected"
        );
        _;
    }

    //Receive function
    receive() external payable {}

    /// @notice Add new service that can call payWinnersEth and startEthLottery.
    /// @param _service New service to add
    function addWhitelistedService(address _service) public onlyOwner {
        require(
            _whitelistedServices[_service] != true,
            "TaskTreasury: addWhitelistedService: whitelisted"
        );
        _whitelistedServices[_service] = true;
        emit AddWhitelistedService(_service);
    }

    /// @notice Remove old service that can call startEthLottery and payWinnersEth
    /// @param _service Old service to remove
    function removeWhitelistedService(address _service) external onlyOwner {
        require(
            _whitelistedServices[_service] == true,
            "addWhitelistedService: !whitelisted"
        );
        _whitelistedServices[_service] = false;
        emit RemoveWhitelistedService(_service);
    }

    /// @notice a function to cancel the current lottery in case the chainlink vrf fails
    /// @dev only call this when the chainlink vrf fails

    function cancelLottery() external onlyOwner {
        require(
            status == Status.Started || status == Status.WinnersSelected,
            "you can only cancel a lottery if one has been started or if something goes wrong after selection"
        );
        jackpot = 0;
        setStakingEnabled(true);
        status = Status.WinnerPaid;
        lotteryType = LotteryType.NotStarted;
        delete selectedWinners;
    }

    /// @notice draw the winning addresses from the Sum Tree
    function draw() external onlyOwner {
        require(status == Status.Started, "lottery has not yen been started");
        for (uint256 i = 0; i < s_randomWords.length; i++) {
            uint256 winningNumber = s_randomWords[i] % totalStaked;
            selectedWinners.push(
                payable(
                    address(
                        uint160(
                            uint256(
                                sortitionSumTrees.draw(TREE_KEY, winningNumber)
                            )
                        )
                    )
                )
            );
            winningNumbers.push(winningNumber);
        }
        status = Status.WinnersSelected;
    }

    /// @notice function needed to receive erc721 tokens in the contract
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    /// @notice pay the winners of the lottery
    function payWinnersTokens() external onlyOwner winnerPayable {
        require(
            lotteryType == LotteryType.Token,
            "the lottery that has been drawn is not a custom lottery"
        );

        delete lastWinners;
        for (uint256 i = 0; i < selectedWinners.length; i++) {
            uint256 _amountWon = jackpot.mul(percentageOfJackpot[i]).div(100);
            customToken.safeTransfer(selectedWinners[i], _amountWon);
            lastWinners.push(selectedWinners[i]);
            amountWonByUser[selectedWinners[i]] += _amountWon;
        }
        lastJackpot = jackpot;
        totalWinnersPaid += selectedWinners.length;
        delete selectedWinners;
        jackpot = 0;
        setStakingEnabled(true);
        status = Status.WinnerPaid;
        lotteryType = LotteryType.NotStarted;
        emit PayWinnersTokens(lastWinners);
    }

    /// @notice pay the winners of the lottery
    function payWinnersEth() external onlyWhitelistedServices winnerPayable {
        require(
            lotteryType == LotteryType.Ethereum,
            "the lottery that has been drawn is not an eth lottery"
        );

        delete lastWinners;
        for (uint256 i = 0; i < selectedWinners.length; i++) {
            uint256 _amountWon = jackpot.mul(percentageOfJackpot[i]).div(100);
            selectedWinners[i].transfer(_amountWon);
            lastWinners.push(selectedWinners[i]);
            amountWonByUser[selectedWinners[i]] += _amountWon;
        }
        lastJackpot = jackpot;
        totalEthPaid += jackpot;
        totalWinnersPaid += selectedWinners.length;
        delete selectedWinners;
        jackpot = 0;
        setStakingEnabled(true);
        status = Status.WinnerPaid;
        lotteryType = LotteryType.NotStarted;
        emit PayWinnersEth(lastWinners);
    }

    /// @notice pay the winners of the lottery
    function payWinnersERC721() external onlyOwner winnerPayable {
        require(
            lotteryType == LotteryType.NFT721,
            "the lottery that has been drawn is not a ERC721 lottery"
        );

        delete lastWinners;
        nft721.safeTransferFrom(address(this), selectedWinners[0], nftId);
        lastWinners.push(selectedWinners[0]);
        totalWinnersPaid += 1;
        delete selectedWinners;
        setStakingEnabled(true);
        status = Status.WinnerPaid;
        lotteryType = LotteryType.NotStarted;
        emit PayWinnerNFT(lastWinners);
    }

    /// @notice a function to add a custom token for a custom token lottery
    /// @param customTokenAddress the address of the custom token that we want to add to the contract
    function setCustomToken(IERC20 customTokenAddress) external onlyOwner {
        customToken = IERC20(customTokenAddress);

        emit SetCustomToken(customTokenAddress);
    }

    /// @notice a function to set the address of the ruffle token
    /// @param ruffleAddress is the address of the ruffle token
    function setRuffleInuToken(IERC20 ruffleAddress) external onlyOwner {
        ruffle = IERC20(ruffleAddress);
        emit SetRuffleInuToken(ruffleAddress);
    }

    /// @notice add erc721 token to the contract for the next lottery
    function setERC721(IERC721 _nft) external onlyOwner {
        nft721 = IERC721(_nft);
        emit SetERC721(_nft);
    }

    /// @notice a function to set the jackpot distribution
    /// @param percentages an array of the percentage distribution
    function setPercentageOfJackpot(uint256[] memory percentages)
        external
        onlyOwner
    {
        require(
            status == Status.NotStarted || status == Status.WinnerPaid,
            "you can only change the jackpot percentages if the lottery is not running"
        );
        delete percentageOfJackpot;
        uint256 _totalSum = 0;
        for (uint256 i; i < percentages.length; i++) {
            percentageOfJackpot.push(percentages[i]);
            _totalSum = _totalSum.add(percentages[i]);
        }
        require(_totalSum == 100, "the sum of the percentages has to be 100");
        numWords = uint32(percentages.length);
        emit SetPercentageOfJackpot(percentages, numWords);
    }

    /// @notice Stakes tokens. NOTE: Staking and unstaking not possible during lottery draw
    /// @param amount Amount to stake and lock
    function stake(uint256 amount) external {
        require(stakingEnabled, "staking is not open");
        if (balanceOf[msg.sender] == 0) {
            sortitionSumTrees.set(
                TREE_KEY,
                amount,
                bytes32(uint256(uint160(address(msg.sender))))
            );
        } else {
            uint256 _newValue = balanceOf[msg.sender].add(amount);
            sortitionSumTrees.set(
                TREE_KEY,
                _newValue,
                bytes32(uint256(uint160(address(msg.sender))))
            );
        }
        ruffle.safeTransferFrom(msg.sender, address(this), amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        totalStaked = totalStaked.add(amount);
        emit Staked(msg.sender, amount);
    }

    /// @notice Start a new lottery
    /// @param _amount in tokens to add to this lottery
    function startTokenLottery(uint256 _amount)
        external
        onlyOwner
        lotteryNotStarted
    {
        require(
            _amount <= customToken.balanceOf(address(this)),
            "The jackpot has to be less than or equal to the tokens in the contract"
        );

        delete winningNumbers;
        delete s_randomWords;
        setStakingEnabled(false);
        requestRandomWords();
        jackpot = _amount;
        status = Status.Started;
        lotteryType = LotteryType.Token;
        emit TokenLotteryStarted(jackpot, numWords);
    }

    /// @notice Start a new lottery
    /// @param _amount The amount in eth to add to this lottery
    function startEthLottery(uint256 _amount)
        external
        onlyWhitelistedServices
        lotteryNotStarted
    {
        require(
            _amount <= address(this).balance,
            "You can maximum add all the eth in the contract balance"
        );
        delete winningNumbers;
        delete s_randomWords;
        setStakingEnabled(false);
        requestRandomWords();
        jackpot = _amount;
        status = Status.Started;
        lotteryType = LotteryType.Ethereum;
        emit EthLotteryStarted(jackpot, numWords);
    }

    /// @notice Start a new nft lottery
    /// @param _tokenId the id of the nft you want to give away in the lottery
    /// @dev set the jackpot to 1 winner [100] before calling this function
    function startERC721Lottery(uint256 _tokenId)
        external
        onlyOwner
        lotteryNotStarted
    {
        require(nft721.ownerOf(_tokenId) == address(this));
        require(
            percentageOfJackpot.length == 1,
            "jackpot has to be set to 1 winner first, percentageOfJackpot = [100]"
        );
        delete winningNumbers;
        delete s_randomWords;
        nftId = _tokenId;
        setStakingEnabled(false);
        requestRandomWords();
        status = Status.Started;
        lotteryType = LotteryType.NFT721;
        emit NFTLotteryStarted(nftId);
    }

    /// @notice Withdraws staked tokens
    /// @param _amount Amount to withdraw
    function unstake(uint256 _amount) external {
        require(stakingEnabled, "staking is not open");
        require(
            _amount <= balanceOf[msg.sender],
            "you cannot unstake more than you have staked"
        );
        uint256 _newStakingBalance = balanceOf[msg.sender].sub(_amount);
        sortitionSumTrees.set(
            TREE_KEY,
            _newStakingBalance,
            bytes32(uint256(uint160(address(msg.sender))))
        );
        balanceOf[msg.sender] = _newStakingBalance;
        totalStaked = totalStaked.sub(_amount);
        ruffle.safeTransfer(msg.sender, _amount);

        emit Unstaked(msg.sender, _amount);
    }

    /// @notice function to update the chainlink subscription
    /// @param subscriptionId Amount to withdraw
    function updateSubscription(uint64 subscriptionId) external {
        uint256 _oldValue = s_subscriptionId;
        s_subscriptionId = subscriptionId;
        emit UpdateSubscription(_oldValue, subscriptionId);
    }

    /// @notice Emergency withdraw only call when problems or after community vote
    /// @dev Only in emergency cases. Protected by multisig APAD
    function withdraw() external onlyMultisig {
        payable(msg.sender).transfer(address(this).balance);
    }

    /// @notice The chance a user has of winning the lottery. Tokens staked by user / total tokens staked
    /// @param account The account that we want to get the chance of winning for
    /// @return chanceOfWinning The chance a user has to win
    function chanceOf(address account)
        external
        view
        returns (uint256 chanceOfWinning)
    {
        return
            sortitionSumTrees.stakeOf(
                TREE_KEY,
                bytes32(uint256(uint160(address(account))))
            );
    }

    /// @notice get the staked ruffle balance of an address
    function getBalance(address staker)
        external
        view
        returns (uint256 balance)
    {
        return balanceOf[staker];
    }

    /// @notice a function to set open/close staking
    function setStakingEnabled(bool _stakingEnabled)
        public
        onlyWhitelistedServices
    {
        stakingEnabled = _stakingEnabled;
        emit SetStakingEnabled(_stakingEnabled);
    }

    /// @notice Request random words from Chainlink VRF V2
    function requestRandomWords() internal {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    /// @notice fulfill the randomwords from chainlink
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        s_randomWords = randomWords;
        if (s_randomWords.length <= 5) {
            for (uint256 i = 0; i < s_randomWords.length; i++) {
                uint256 winningNumber = s_randomWords[i] % totalStaked;
                selectedWinners.push(
                    payable(
                        address(
                            uint160(
                                uint256(
                                    sortitionSumTrees.draw(
                                        TREE_KEY,
                                        winningNumber
                                    )
                                )
                            )
                        )
                    )
                );
                winningNumbers.push(winningNumber);
            }
            status = Status.WinnersSelected;
        }
    }
}