// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "ERC20.sol";

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface PancakeSwapFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface PancakeSwapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

// abstract contract Context {
//     function _msgSender() internal view virtual returns (address payable) {
//         return payable(msg.sender);
//     }

//     function _msgData() internal view virtual returns (bytes memory) {
//         this;
//         return msg.data;
//     }
// }

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        authorizations[_owner] = true;
        emit OwnershipTransferred(address(0), msgSender);
    }

    mapping(address => bool) internal authorizations;

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract LootyBox is Ownable, IBEP20 {
    using SafeMath for uint256;

    uint8 private constant _decimals = 9;
    uint256 public _maxSupplyPossible = 1200000000000 * (10**_decimals);
    uint256 private _totalSupply = 1000000000000 * (10**_decimals);
    uint256 public _maxTxAmount = (_totalSupply * 15) / 1000;
    uint256 public _walletMax = (_totalSupply * 25) / 1000;

    address private constant DEAD_WALLET =
        0x000000000000000000000000000000000000dEaD;
    address private constant ZERO_WALLET =
        0x0000000000000000000000000000000000000000;

    address private pancakeAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    string private constant _name = "BootyLox";
    string private constant _symbol = "BTLX";

    bool public restrictWhales = true;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;

    uint256 public liquidityFee = 3;
    uint256 public marketingFee = 3;
    uint256 public devFee = 4;
    uint256 public poolFee = 0;

    uint256 public totalFee = 0;
    uint256 public totalFeeIfSelling = 0;

    bool public takeBuyFee = true;
    bool public takeSellFee = true;
    bool public takeTransferFee = false;

    address private autoLiquidityReceiver;
    address private marketingWallet;
    address private devWallet;
    address private poolWallet;

    PancakeSwapRouter public router;
    address public pair;

    uint256 public launchedAt;
    bool public tradingOpen = false;
    bool public blacklistMode = true;
    bool public canUseBlacklist = true;
    mapping(address => bool) public isBlacklisted;

    mapping(address => bool) public isAuthorizedForTokenMints;

    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyByLimitOnly = false;

    uint256 public swapThreshold = (_totalSupply * 4) / 2000;

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event tokensMinted(uint256 amount, address mintedTo, address mintedBy);
    event tokensBurned(uint256 amount, address mintedTo, address mintedBy);
    event accountAuthorized(address account, bool status);
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        router = PancakeSwapRouter(pancakeAddress);
        pair = PancakeSwapFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        _allowances[address(this)][address(router)] = type(uint256).max;
        _allowances[address(this)][address(pair)] = type(uint256).max;
        isAuthorizedForTokenMints[msg.sender] = true;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[DEAD_WALLET] = true;
        isFeeExempt[poolWallet] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[DEAD_WALLET] = true;
        isTxLimitExempt[poolWallet] = true;

        autoLiquidityReceiver = msg.sender;
        marketingWallet = msg.sender;
        devWallet = msg.sender;
        poolWallet = msg.sender;

        isFeeExempt[marketingWallet] = true;
        totalFee = liquidityFee.add(marketingFee).add(devFee).add(poolFee);
        totalFeeIfSelling = totalFee;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function getOwner() external view override returns (address) {
        return owner();
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function getCirculatingSupply() public view returns (uint256) {
        return
            _totalSupply.sub(balanceOf(DEAD_WALLET)).sub(
                balanceOf(ZERO_WALLET)
            );
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }

    function mintTokens(uint256 amount, address account) external {
        require(isAuthorizedForTokenMints[msg.sender], "Not Authorized");
        require(
            _totalSupply + amount <= _maxSupplyPossible,
            "Tokens Minted Above Max Limit"
        );
        _balances[account] += amount;
        _totalSupply += amount;
        emit tokensMinted(amount, account, msg.sender);
        emit Transfer(address(0), account, amount);
    }

    function burnTokens(uint256 amount, address account) external {
        require(isAuthorizedForTokenMints[msg.sender], "Not Authorized");
        require(
            _balances[account] >= amount,
            "Account does not have enough balance to burn"
        );
        _balances[account] -= amount;
        _totalSupply -= amount;
        emit tokensBurned(amount, account, msg.sender);
        emit Transfer(account, address(0), amount);
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(
            amount <= _maxTxAmount || isTxLimitExempt[sender],
            "TX Limit Exceeded"
        );
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwapAndLiquify) {
            return _basicTransfer(sender, recipient, amount);
        }
        if (!authorizations[sender] && !authorizations[recipient]) {
            require(tradingOpen, "Trading not open yet");
        }

        require(
            amount <= _maxTxAmount || isTxLimitExempt[sender],
            "TX Limit Exceeded"
        );
        if (
            msg.sender != pair &&
            !inSwapAndLiquify &&
            swapAndLiquifyEnabled &&
            _balances[address(this)] >= swapThreshold
        ) {
            marketingAndLiquidity();
        }
        if (!launched() && recipient == pair) {
            require(_balances[sender] > 0, "Zero balance violated!");
            launch();
        }

        // Blacklist
        if (blacklistMode) {
            require(!isBlacklisted[sender], "Blacklisted");
        }

        //Exchange tokens
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        if (!isTxLimitExempt[recipient] && restrictWhales) {
            require(
                _balances[recipient].add(amount) <= _walletMax,
                "Max wallet violated!"
            );
        }

        uint256 finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient]
            ? extractFee(sender, recipient, amount)
            : amount;
        _balances[recipient] = _balances[recipient].add(finalAmount);

        emit Transfer(sender, recipient, finalAmount);
        return true;
    }

    function extractFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeApplicable = 0;
        uint256 poolAmount = 0;
        if (recipient == pair && takeSellFee) {
            feeApplicable = totalFeeIfSelling.sub(poolFee);
        }
        if (sender == pair && takeBuyFee) {
            feeApplicable = totalFee.sub(poolFee);
        }
        if (sender != pair && recipient != pair) {
            if (takeTransferFee) {
                feeApplicable = totalFeeIfSelling.sub(poolFee);
            } else {
                feeApplicable = 0;
            }
        }
        if (feeApplicable > 0 && poolFee > 0) {
            poolAmount = amount.mul(poolFee).div(100);
            _balances[poolWallet] = _balances[poolWallet].add(poolAmount);
        }
        uint256 feeAmount = amount.mul(feeApplicable).div(100);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount).sub(poolAmount);
    }

    function marketingAndLiquidity() internal lockTheSwap {
        uint256 tokensToLiquify = _balances[address(this)];
        uint256 amountToLiquify = tokensToLiquify
            .mul(liquidityFee)
            .div(totalFee.sub(poolFee))
            .div(2);
        uint256 amountToSwap = tokensToLiquify.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance;

        uint256 totalBNBFee = totalFee.sub(poolFee).sub(liquidityFee.div(2));

        uint256 amountBNBLiquidity = amountBNB
            .mul(liquidityFee)
            .div(totalBNBFee)
            .div(2);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(
            totalBNBFee
        );
        uint256 amountBNBDev = amountBNB.mul(devFee).div(totalBNBFee);

        (bool tmpSuccess1, ) = payable(marketingWallet).call{
            value: amountBNBMarketing,
            gas: 30000
        }("");
        tmpSuccess1 = false;

        (tmpSuccess1, ) = payable(devWallet).call{
            value: amountBNBDev,
            gas: 30000
        }("");
        tmpSuccess1 = false;

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    function setMaxSupplyPossible(uint256 newLimit) external onlyOwner {
        _maxSupplyPossible = newLimit;
    }

    function changeAuthorization(address _address, bool _status)
        external
        onlyOwner
    {
        isAuthorizedForTokenMints[_address] = _status;
        emit accountAuthorized(_address, _status);
    }

    function setWalletLimit(uint256 newLimit) external onlyOwner {
        require(newLimit >= 5, "Wallet Limit needs to be at least 0.5%");
        _walletMax = (_totalSupply * newLimit) / 1000;
    }

    function setTxLimit(uint256 newLimit) external onlyOwner {
        require(newLimit >= 5, "Wallet Limit needs to be at least 0.5%");
        _maxTxAmount = (_totalSupply * newLimit) / 1000;
    }

    function tradingStatus(bool newStatus) public onlyOwner {
        require(canUseBlacklist, "Dev can no longer pause trading");
        tradingOpen = newStatus;
    }

    function openTrading() public onlyOwner {
        tradingOpen = true;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        isTxLimitExempt[holder] = exempt;
    }

    function fullWhitelist(address target) public onlyOwner {
        authorizations[target] = true;
        isFeeExempt[target] = true;
        isTxLimitExempt[target] = true;
    }

    function setFees(
        uint256 newLiqFee,
        uint256 newMarketingFee,
        uint256 newDevFee,
        uint256 newPoolFee,
        uint256 extraSellFee
    ) external onlyOwner {
        liquidityFee = newLiqFee;
        marketingFee = newMarketingFee;
        devFee = newDevFee;
        poolFee = newPoolFee;

        totalFee = liquidityFee.add(marketingFee).add(devFee).add(poolFee);
        totalFeeIfSelling = totalFee + extraSellFee;
        require(totalFeeIfSelling < 25);
    }

    function enable_blacklist(bool _status) public onlyOwner {
        require(canUseBlacklist, "Dev can no longer add blacklists");
        blacklistMode = _status;
    }

    function manage_blacklist(address[] calldata addresses, bool status)
        public
        onlyOwner
    {
        require(canUseBlacklist, "Dev can no longer add blacklists");
        for (uint256 i; i < addresses.length; ++i) {
            isBlacklisted[addresses[i]] = status;
        }
    }

    function isAuth(address _address, bool status) public onlyOwner {
        authorizations[_address] = status;
    }

    function renounceBlacklist() public onlyOwner {
        canUseBlacklist = false;
    }

    function disableBlacklistDONTUSETHIS() public onlyOwner {
        blacklistMode = false;
    }

    function setTakeBuyfee(bool status) public onlyOwner {
        takeBuyFee = status;
    }

    function setTakeSellfee(bool status) public onlyOwner {
        takeSellFee = status;
    }

    function setTakeTransferfee(bool status) public onlyOwner {
        takeTransferFee = status;
    }

    function setSwapbackSettings(bool status, uint256 newAmount)
        public
        onlyOwner
    {
        swapAndLiquifyEnabled = status;
        swapThreshold = newAmount;
    }

    function setFeeReceivers(
        address newMktWallet,
        address newDevWallet,
        address newLpWallet,
        address newPoolWallet
    ) public onlyOwner {
        autoLiquidityReceiver = newLpWallet;
        marketingWallet = newMktWallet;
        devWallet = newDevWallet;
        poolWallet = newPoolWallet;
    }

    function rescueToken(address tokenAddress, uint256 tokens)
        public
        onlyOwner
        returns (bool success)
    {
        require(tokenAddress != address(this), "Cant remove the native token");
        return IBEP20(tokenAddress).transfer(msg.sender, tokens);
    }

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer((amountETH * amountPercentage) / 100);
    }
}

contract LootBoxes {
    address payable public owner;

    uint256 public gameCount;
    uint256 public caseCountMax = 20;
    uint256 public bobMaxBet;
    address public bobAddress;
    address payable public tokenAddress;
    bool public startGames = true;
    bool public callBobGames = true;
    bool public withdrawEnabled = true;
    mapping(address => uint256) public unclaimedRewardsOfUser;
    mapping(address => uint256) public promotionalBalanceOfUser;
    mapping(uint256 => bool) public resolvedBlocks;
    mapping(address => bool) public resolverAddresses;
    mapping(uint256 => lobbyStruct) public lobbyDataFromId;
    mapping(uint256 => uint256) public lobbyIdFromGameId;
    mapping(uint256 => bool) public activeLobbyId;
    mapping(uint256 => uint256) public blockNumberGameCount;
    mapping(uint256 => mapping(uint256 => uint256))
        public lobbyIdFromBlockNumberAndItter;
    mapping(uint256 => mapping(uint256 => uint256))
        public caseIdFromLobbyIdRoundId;
    mapping(uint256 => caseData) public caseDataFromId;

    // path from caseId to prizes
    mapping(uint256 => mapping(uint256 => prizeData))
        public prizeDataFromCaseIdPrizeId;
    struct prizeData {
        uint256 lowTicket;
        uint256 highTicket;
        uint256 prizeAmount;
    }
    struct caseData {
        uint256 prizeCount;
        uint256 caseCost;
    }
    struct lobbyStruct {
        uint8 gameType; // 0 for solo, 1 for 1v1, 2 for 2v2, 3 for 1v1v1
        uint8 gameState; // 1 means placed by challenger, 2 means initialized , 3 means resolved
        uint16 numberOfCases;
        uint256 gameId; //Id of the game
        uint256 gameCost; //Total cost of the game
        uint256 blockInitialized;
        address creator;
        address caller1;
        address caller2;
        address caller3;
    }
    event winningsAdded(address winner, uint256 amount);
    event gameCancelled(uint256 gameCount);
    event lobbyJoined(address caller, uint256 gameCount, uint256 position);
    event lobbyLeft(address caller, uint256 gameCount, uint256 position);

    event gameStarted(
        uint256 gameCount,
        uint256 blockNumberInitialized,
        address creator,
        address caller1,
        address caller2,
        address caller3
    );
    event gameResolved(
        uint256 gameCount,
        uint256 winningAmount,
        address winner,
        address winner2,
        bytes32 resolutionSeed
    );
    event roundResolved(
        uint256 gameCount,
        uint256 roundCount,
        uint256 numberRolled1,
        uint256 numberRolled2,
        uint256 numberRolled3,
        uint256 numberRolled4
    );
    event lobbyMade(
        uint256 lobbyId,
        uint256 gameId,
        uint8 gameType,
        uint256[] caseIds,
        address lobbyCreator,
        uint256 lobbyCost,
        bool pvp
    );
    event claimedWinnings(address winner, uint256 amount);

    event caseAdded(uint256 caseId, uint256 caseCost);
    event prizeAdded(
        uint256 caseId,
        uint256 lowTicket,
        uint256 highTicket,
        uint256 prizeAmount
    );

    constructor(address _tokenAddress) {
        owner = payable(msg.sender);
        tokenAddress = payable(_tokenAddress);
        resolverAddresses[msg.sender] = true;
    }

    function alterCaseData(
        uint256 _caseId,
        uint256 _caseCost,
        uint256[] calldata _lowTickets,
        uint256[] calldata _highTickets,
        uint256[] calldata _prizeAmounts
    ) external {
        require(msg.sender == owner, "only owner");
        require(
            _lowTickets.length == _highTickets.length &&
                _highTickets.length == _prizeAmounts.length,
            "Lists are not equal lengths"
        );
        emit caseAdded(_caseId, _caseCost);
        for (uint256 i = 0; i < _lowTickets.length; i++) {
            emit prizeAdded(
                _caseId,
                _lowTickets[i],
                _highTickets[i],
                _prizeAmounts[i]
            );
            prizeDataFromCaseIdPrizeId[_caseId][i] = prizeData(
                _lowTickets[i],
                _highTickets[i],
                _prizeAmounts[i]
            );
        }
        caseDataFromId[_caseId] = caseData(_lowTickets.length, _caseCost);
    }

    function enableGames(bool _enable) external {
        require(msg.sender == owner, "only owner");
        startGames = _enable;
    }

    function addPromoBalance(address user, uint256 amount) external {
        require(
            resolverAddresses[msg.sender],
            "not permissioned to add promo balance"
        );
        promotionalBalanceOfUser[user] += amount;
    }

    function enableBob(bool _enable) external {
        require(msg.sender == owner, "only owner");
        callBobGames = _enable;
    }

    function enableWithdraw(bool _enable) external {
        require(msg.sender == owner, "only owner");
        withdrawEnabled = _enable;
    }

    function changeResolver(address _address, bool _bool) external {
        require(msg.sender == owner, "only owner");
        resolverAddresses[_address] = _bool;
    }

    function changeBobAddress(address _address) external {
        require(msg.sender == owner, "only owner");
        bobAddress = _address;
    }

    function rescueTokens(address _token, uint256 _amount) external payable {
        require(msg.sender == owner, "only owner");
        if (_token == address(0)) {
            (bool successUser, ) = msg.sender.call{value: _amount}("");
            require(successUser, "Transfer to user failed");
        } else {
            IBEP20 tokenContract = IBEP20(_token);
            tokenContract.transfer(msg.sender, _amount);
        }
    }

    function viewBalance(address _token) public view returns (uint256) {
        if (_token == address(0)) {
            return address(this).balance;
        } else {
            IBEP20 tokenContract = IBEP20(_token);
            tokenContract.balanceOf(address(this));
        }
    }

    function callBob(uint256 _gameId) public {
        uint256 _lobbyId = lobbyIdFromGameId[_gameId];
        address _bobAddress = bobAddress;
        lobbyStruct memory tempLobby = lobbyDataFromId[_lobbyId];
        require(tempLobby.gameState == 1, "Bob can only join placed lobbys");
        require(
            tempLobby.creator == msg.sender,
            "Only lobby creator can call bob"
        );
        lobbyDataFromId[_lobbyId].gameState = 2;
        if (tempLobby.gameType == 1) {
            lobbyDataFromId[_lobbyId].caller1 = _bobAddress;
            lobbyDataFromId[_lobbyId].blockInitialized = block.number;
            uint256 currentGameCountOfBlock = blockNumberGameCount[
                block.number
            ];
            blockNumberGameCount[block.number]++;
            lobbyIdFromBlockNumberAndItter[block.number][
                currentGameCountOfBlock
            ] = _lobbyId;
            emit lobbyJoined(_bobAddress, _gameId, 2);
            emit gameStarted(
                _gameId,
                block.number,
                tempLobby.creator,
                _bobAddress,
                address(0),
                address(0)
            );
        } else if (tempLobby.gameType == 2) {
            if (tempLobby.caller1 == address(0)) {
                lobbyDataFromId[_lobbyId].caller1 = _bobAddress;
                emit lobbyJoined(_bobAddress, _gameId, 2);
            }
            if (tempLobby.caller2 == address(0)) {
                lobbyDataFromId[_lobbyId].caller2 = _bobAddress;
                emit lobbyJoined(_bobAddress, _gameId, 3);
            }
            if (tempLobby.caller3 == address(0)) {
                lobbyDataFromId[_lobbyId].caller3 = _bobAddress;
                emit lobbyJoined(_bobAddress, _gameId, 4);
            }

            lobbyDataFromId[_lobbyId].blockInitialized = block.number;
            uint256 currentGameCountOfBlock = blockNumberGameCount[
                block.number
            ];
            blockNumberGameCount[block.number]++;
            lobbyIdFromBlockNumberAndItter[block.number][
                currentGameCountOfBlock
            ] = _lobbyId;
            emit gameStarted(
                _gameId,
                block.number,
                lobbyDataFromId[_lobbyId].creator,
                lobbyDataFromId[_lobbyId].caller1,
                lobbyDataFromId[_lobbyId].caller2,
                lobbyDataFromId[_lobbyId].caller3
            );
        } else if (tempLobby.gameType == 3) {
            if (tempLobby.caller1 == address(0)) {
                lobbyDataFromId[_lobbyId].caller1 = _bobAddress;
                emit lobbyJoined(_bobAddress, _gameId, 2);
            }
            if (tempLobby.caller2 == address(0)) {
                lobbyDataFromId[_lobbyId].caller2 = _bobAddress;
                emit lobbyJoined(_bobAddress, _gameId, 3);
            }

            lobbyDataFromId[_lobbyId].blockInitialized = block.number;
            uint256 currentGameCountOfBlock = blockNumberGameCount[
                block.number
            ];
            blockNumberGameCount[block.number]++;
            lobbyIdFromBlockNumberAndItter[block.number][
                currentGameCountOfBlock
            ] = _lobbyId;
            emit gameStarted(
                _gameId,
                block.number,
                lobbyDataFromId[_lobbyId].creator,
                lobbyDataFromId[_lobbyId].caller1,
                lobbyDataFromId[_lobbyId].caller2,
                address(0)
            );
        }
    }

    function addPlayerToLobby(
        address _user,
        uint256 _gameId,
        uint256 _position
    ) external {
        require(
            resolverAddresses[msg.sender],
            "not permissioned to add free battles"
        );
        require(_position >= 2 && _position <= 4, "choose valid position 2-4");
        uint256 _lobbyId = lobbyIdFromGameId[_gameId];
        lobbyStruct memory tempLobby = lobbyDataFromId[_lobbyId];
        require(tempLobby.gameState == 1, "Can only join placed lobbys");
        if (tempLobby.gameType == 1) {
            lobbyDataFromId[_lobbyId].caller1 = _user;
            lobbyDataFromId[_lobbyId].blockInitialized = block.number;
            lobbyDataFromId[_lobbyId].gameState = 2;
            emit lobbyJoined(_user, _gameId, 2);
            emit gameStarted(
                _gameId,
                block.number,
                tempLobby.creator,
                _user,
                address(0),
                address(0)
            );
        } else if (tempLobby.gameType == 2) {
            if (_position == 2) {
                require(
                    tempLobby.caller1 == address(0),
                    "Position already filled"
                );
                lobbyDataFromId[_lobbyId].caller1 = _user;
            } else if (_position == 3) {
                require(
                    tempLobby.caller2 == address(0),
                    "Position already filled"
                );
                lobbyDataFromId[_lobbyId].caller2 = _user;
            } else if (_position == 4) {
                require(
                    tempLobby.caller3 == address(0),
                    "Position already filled"
                );
                lobbyDataFromId[_lobbyId].caller3 = _user;
            }
            emit lobbyJoined(_user, _gameId, _position);
            if (isLobbyFull(_lobbyId)) {
                lobbyDataFromId[_lobbyId].blockInitialized = block.number;
                lobbyDataFromId[_lobbyId].gameState = 2;
                uint256 currentGameCountOfBlock = blockNumberGameCount[
                    block.number
                ];
                blockNumberGameCount[block.number]++;
                lobbyIdFromBlockNumberAndItter[block.number][
                    currentGameCountOfBlock
                ] = _lobbyId;
                emit gameStarted(
                    _gameId,
                    block.number,
                    lobbyDataFromId[_lobbyId].creator,
                    lobbyDataFromId[_lobbyId].caller1,
                    lobbyDataFromId[_lobbyId].caller2,
                    lobbyDataFromId[_lobbyId].caller3
                );
            }
        } else if (tempLobby.gameType == 3) {
            require(_position < 4, "invalid position");
            if (_position == 2) {
                require(
                    tempLobby.caller1 == address(0),
                    "Position already filled"
                );
                lobbyDataFromId[_lobbyId].caller1 = _user;
            } else if (_position == 3) {
                require(
                    tempLobby.caller2 == address(0),
                    "Position already filled"
                );
                lobbyDataFromId[_lobbyId].caller2 = _user;
            }
            emit lobbyJoined(_user, _gameId, _position);
            if (isLobbyFull3(_lobbyId)) {
                lobbyDataFromId[_lobbyId].blockInitialized = block.number;
                lobbyDataFromId[_lobbyId].gameState = 2;
                uint256 currentGameCountOfBlock = blockNumberGameCount[
                    block.number
                ];
                blockNumberGameCount[block.number]++;
                lobbyIdFromBlockNumberAndItter[block.number][
                    currentGameCountOfBlock
                ] = _lobbyId;
                emit gameStarted(
                    _gameId,
                    block.number,
                    lobbyDataFromId[_lobbyId].creator,
                    lobbyDataFromId[_lobbyId].caller1,
                    lobbyDataFromId[_lobbyId].caller2,
                    address(0)
                );
            }
        }
    }

    function joinLobby(
        uint256 _gameId,
        uint8 _position,
        bool _promo
    ) external {
        require(_position >= 2 && _position <= 4, "choose valid position 2-4");
        uint256 _lobbyId = lobbyIdFromGameId[_gameId];
        lobbyStruct memory tempLobby = lobbyDataFromId[_lobbyId];
        require(tempLobby.gameState == 1, "Can only join placed lobbys");
        if (!_promo) {
            LootyBox tokenContract = LootyBox(tokenAddress);
            tokenContract.burnTokens(tempLobby.gameCost, msg.sender);
        } else {
            require(
                promotionalBalanceOfUser[msg.sender] >= tempLobby.gameCost,
                "Not enough promo balance to join lobby"
            );
            promotionalBalanceOfUser[msg.sender] -= tempLobby.gameCost;
        }

        if (tempLobby.gameType == 1) {
            lobbyDataFromId[_lobbyId].caller1 = msg.sender;
            lobbyDataFromId[_lobbyId].blockInitialized = block.number;
            lobbyDataFromId[_lobbyId].gameState = 2;
            emit lobbyJoined(msg.sender, _gameId, 2);
            emit gameStarted(
                _gameId,
                block.number,
                tempLobby.creator,
                msg.sender,
                address(0),
                address(0)
            );
        } else if (tempLobby.gameType == 2) {
            if (_position == 2) {
                require(
                    tempLobby.caller1 == address(0),
                    "Position already filled"
                );
                lobbyDataFromId[_lobbyId].caller1 = msg.sender;
            } else if (_position == 3) {
                require(
                    tempLobby.caller2 == address(0),
                    "Position already filled"
                );
                lobbyDataFromId[_lobbyId].caller2 = msg.sender;
            } else if (_position == 4) {
                require(
                    tempLobby.caller3 == address(0),
                    "Position already filled"
                );
                lobbyDataFromId[_lobbyId].caller3 = msg.sender;
            }
            emit lobbyJoined(msg.sender, _gameId, _position);
            if (isLobbyFull(_lobbyId)) {
                lobbyDataFromId[_lobbyId].blockInitialized = block.number;
                lobbyDataFromId[_lobbyId].gameState = 2;
                uint256 currentGameCountOfBlock = blockNumberGameCount[
                    block.number
                ];
                blockNumberGameCount[block.number]++;
                lobbyIdFromBlockNumberAndItter[block.number][
                    currentGameCountOfBlock
                ] = _lobbyId;
                emit gameStarted(
                    _gameId,
                    block.number,
                    lobbyDataFromId[_lobbyId].creator,
                    lobbyDataFromId[_lobbyId].caller1,
                    lobbyDataFromId[_lobbyId].caller2,
                    lobbyDataFromId[_lobbyId].caller3
                );
            }
        } else if (tempLobby.gameType == 3) {
            require(_position < 4, "invalid position");
            if (_position == 2) {
                require(
                    tempLobby.caller1 == address(0),
                    "Position already filled"
                );
                lobbyDataFromId[_lobbyId].caller1 = msg.sender;
            } else if (_position == 3) {
                require(
                    tempLobby.caller2 == address(0),
                    "Position already filled"
                );
                lobbyDataFromId[_lobbyId].caller2 = msg.sender;
            }
            emit lobbyJoined(msg.sender, _gameId, _position);
            if (isLobbyFull3(_lobbyId)) {
                lobbyDataFromId[_lobbyId].blockInitialized = block.number;
                lobbyDataFromId[_lobbyId].gameState = 2;
                uint256 currentGameCountOfBlock = blockNumberGameCount[
                    block.number
                ];
                blockNumberGameCount[block.number]++;
                lobbyIdFromBlockNumberAndItter[block.number][
                    currentGameCountOfBlock
                ] = _lobbyId;
                emit gameStarted(
                    _gameId,
                    block.number,
                    lobbyDataFromId[_lobbyId].creator,
                    lobbyDataFromId[_lobbyId].caller1,
                    lobbyDataFromId[_lobbyId].caller2,
                    address(0)
                );
            }
        }
    }

    function isLobbyFull(uint256 _lobbyId) public view returns (bool) {
        lobbyStruct memory tempLobby = lobbyDataFromId[_lobbyId];
        if (tempLobby.caller1 == address(0)) {
            return false;
        }
        if (tempLobby.caller2 == address(0)) {
            return false;
        }
        if (tempLobby.caller3 == address(0)) {
            return false;
        }
        return true;
    }

    function isLobbyFull3(uint256 _lobbyId) public view returns (bool) {
        lobbyStruct memory tempLobby = lobbyDataFromId[_lobbyId];
        if (tempLobby.caller1 == address(0)) {
            return false;
        }
        if (tempLobby.caller2 == address(0)) {
            return false;
        }
        return true;
    }

    function resolveBlock(uint256 _blockNumber, bytes32 _resolutionSeed)
        external
    {
        require(
            resolverAddresses[msg.sender],
            "Only resolvers can resolve blocks"
        );
        require(!resolvedBlocks[_blockNumber], "Block Already resolved");
        require(blockNumberGameCount[_blockNumber] > 0, "No games to resolve");
        require(_blockNumber < block.number, "Block not reached yet");
        uint256 tempWinnings;
        address tempWinner;
        address tempWinner2;
        resolvedBlocks[_blockNumber] = true;
        for (uint256 i = 0; i < blockNumberGameCount[_blockNumber]; i++) {
            uint256 currentGameId = lobbyIdFromBlockNumberAndItter[
                _blockNumber
            ][i];
            lobbyStruct memory tempGame = lobbyDataFromId[currentGameId];
            if (tempGame.gameState != 2) continue;
            lobbyDataFromId[currentGameId].gameState = 3;
            if (tempGame.gameType == 0) {
                tempWinnings = getWinningsFromSoloOpening(
                    _resolutionSeed,
                    currentGameId
                );
                unclaimedRewardsOfUser[tempGame.creator] += tempWinnings;
                emit gameResolved(
                    tempGame.gameId,
                    tempWinnings,
                    tempGame.creator,
                    address(0),
                    _resolutionSeed
                );
                emit winningsAdded(tempGame.creator, tempWinnings);
            } else if (tempGame.gameType == 1) {
                (tempWinnings, tempWinner) = getWinningsFrom1v1(
                    _resolutionSeed,
                    currentGameId
                );
                if (tempWinner != bobAddress) {
                    unclaimedRewardsOfUser[tempWinner] += tempWinnings;
                    emit winningsAdded(tempWinner, tempWinnings);
                }
                emit gameResolved(
                    tempGame.gameId,
                    tempWinnings,
                    tempWinner,
                    address(0),
                    _resolutionSeed
                );
            } else if (tempGame.gameType == 2) {
                (tempWinnings, tempWinner, tempWinner2) = getWinningsFrom2v2(
                    _resolutionSeed,
                    currentGameId
                );
                if (tempWinner != bobAddress) {
                    unclaimedRewardsOfUser[tempWinner] += tempWinnings;
                    emit winningsAdded(tempWinner, tempWinnings);
                }
                if (tempWinner2 != bobAddress) {
                    unclaimedRewardsOfUser[tempWinner2] += tempWinnings;
                    emit winningsAdded(tempWinner2, tempWinnings);
                }
                emit gameResolved(
                    tempGame.gameId,
                    tempWinnings,
                    tempWinner,
                    tempWinner2,
                    _resolutionSeed
                );
            } else if (tempGame.gameType == 3) {
                (tempWinnings, tempWinner) = getWinningsFrom1v1v1(
                    _resolutionSeed,
                    currentGameId
                );
                if (tempWinner != bobAddress) {
                    unclaimedRewardsOfUser[tempWinner] += tempWinnings;
                    emit winningsAdded(tempWinner, tempWinnings);
                }
                emit gameResolved(
                    tempGame.gameId,
                    tempWinnings,
                    tempWinner,
                    address(0),
                    _resolutionSeed
                );
            }

            activeLobbyId[currentGameId] = false;
        }
    }

    function withdrawTokenWinnings() external {
        require(withdrawEnabled, "Withdraws are not enabled");
        uint256 currentRewards = unclaimedRewardsOfUser[msg.sender];
        require(currentRewards > 1, "No pending rewards");
        unclaimedRewardsOfUser[msg.sender] = 0;
        LootyBox tokenContract = LootyBox(tokenAddress);
        tokenContract.mintTokens(currentRewards, msg.sender);
        tokenContract.mintTokens(currentRewards / 20, owner);
        emit claimedWinnings(msg.sender, currentRewards);
    }

    function getCostOfLootboxes(uint256[] calldata _lootboxIds)
        public
        view
        returns (uint256)
    {
        uint256 tempTotal;
        for (uint256 i = 0; i < _lootboxIds.length; i++) {
            uint256 tempCost = caseDataFromId[_lootboxIds[i]].caseCost;
            require(tempCost > 0, "case has no cost");
            tempTotal += tempCost;
        }
        return tempTotal;
    }

    function getPrizeFromTicket(uint256 _caseId, uint256 _ticket)
        public
        view
        returns (uint256)
    {
        uint256 prizeCountTemp = caseDataFromId[_caseId].prizeCount;
        for (uint256 i = 0; i < prizeCountTemp; i++) {
            prizeData memory tempPrize = prizeDataFromCaseIdPrizeId[_caseId][i];
            if (
                tempPrize.lowTicket <= _ticket &&
                tempPrize.highTicket >= _ticket
            ) {
                return tempPrize.prizeAmount;
            }
        }
        return 0;
    }

    function getWinningsFrom1v1v1(bytes32 resolutionSeed, uint256 lobbyId)
        internal
        returns (uint256, address)
    {
        lobbyStruct memory tempGame = lobbyDataFromId[lobbyId];
        uint256 tempTotal1;
        uint256 tempTotal2;
        uint256 tempTotal3;
        for (uint256 i = 0; i < tempGame.numberOfCases; i++) {
            uint256 caseId = caseIdFromLobbyIdRoundId[lobbyId][i];
            uint256 rolledTicket = uint256(
                keccak256(abi.encodePacked(resolutionSeed, lobbyId, i))
            ) % 100000;
            uint256 rolledTicket2 = uint256(
                keccak256(abi.encodePacked(resolutionSeed, lobbyId, 100 - i))
            ) % 100000;
            uint256 rolledTicket3 = uint256(
                keccak256(abi.encodePacked(resolutionSeed, lobbyId, 200 - i))
            ) % 100000;

            emit roundResolved(
                tempGame.gameId,
                i,
                rolledTicket,
                rolledTicket2,
                rolledTicket3,
                0
            );
            tempTotal1 += getPrizeFromTicket(caseId, rolledTicket);
            tempTotal2 += getPrizeFromTicket(caseId, rolledTicket2);
            tempTotal3 += getPrizeFromTicket(caseId, rolledTicket3);
        }
        uint256 tempWinnings = tempTotal1 + tempTotal2 + tempTotal3;
        if (tempTotal1 == tempTotal2 && tempTotal1 == tempTotal3) {
            uint256 tieBreak = uint256(
                keccak256(abi.encodePacked(resolutionSeed, tempGame.gameId))
            ) % 3;
            if (tieBreak == 0) {
                return (tempWinnings, tempGame.creator);
            } else if (tieBreak == 1) {
                return (tempWinnings, tempGame.caller1);
            } else if (tieBreak == 2) {
                return (tempWinnings, tempGame.caller2);
            }
        } else if (tempTotal1 > tempTotal2 && tempTotal1 > tempTotal3) {
            return (tempWinnings, tempGame.creator);
        } else if (tempTotal2 > tempTotal1 && tempTotal2 > tempTotal3) {
            return (tempWinnings, tempGame.caller1);
        } else if (tempTotal3 > tempTotal1 && tempTotal3 > tempTotal2) {
            return (tempWinnings, tempGame.caller2);
        } else {
            if (tempTotal1 == tempTotal2) {
                if (tieBreaker(resolutionSeed, tempGame.gameId)) {
                    return (tempWinnings, tempGame.creator);
                } else {
                    return (tempWinnings, tempGame.caller1);
                }
            } else if (tempTotal3 == tempTotal2) {
                if (tieBreaker(resolutionSeed, tempGame.gameId)) {
                    return (tempWinnings, tempGame.caller1);
                } else {
                    return (tempWinnings, tempGame.caller2);
                }
            } else {
                if (tieBreaker(resolutionSeed, tempGame.gameId)) {
                    return (tempWinnings, tempGame.creator);
                } else {
                    return (tempWinnings, tempGame.caller2);
                }
            }
        }
    }

    function getWinningsFrom2v2(bytes32 resolutionSeed, uint256 lobbyId)
        internal
        returns (
            uint256,
            address,
            address
        )
    {
        lobbyStruct memory tempGame = lobbyDataFromId[lobbyId];
        uint256 tempTotal1;
        uint256 tempTotal2;
        for (uint256 i = 0; i < tempGame.numberOfCases; i++) {
            uint256 caseId = caseIdFromLobbyIdRoundId[lobbyId][i];
            uint256 rolledTicket = uint256(
                keccak256(abi.encodePacked(resolutionSeed, lobbyId, i))
            ) % 100000;
            uint256 rolledTicket2 = uint256(
                keccak256(abi.encodePacked(resolutionSeed, lobbyId, 100 - i))
            ) % 100000;
            uint256 rolledTicket3 = uint256(
                keccak256(abi.encodePacked(resolutionSeed, lobbyId, 200 - i))
            ) % 100000;
            uint256 rolledTicket4 = uint256(
                keccak256(abi.encodePacked(resolutionSeed, lobbyId, 300 - i))
            ) % 100000;

            emit roundResolved(
                tempGame.gameId,
                i,
                rolledTicket,
                rolledTicket2,
                rolledTicket3,
                rolledTicket4
            );
            tempTotal1 += getPrizeFromTicket(caseId, rolledTicket);
            tempTotal1 += getPrizeFromTicket(caseId, rolledTicket2);
            tempTotal2 += getPrizeFromTicket(caseId, rolledTicket3);
            tempTotal2 += getPrizeFromTicket(caseId, rolledTicket4);
        }
        bool creatorWinner;
        if (tempTotal1 == tempTotal2) {
            creatorWinner = tieBreaker(resolutionSeed, tempGame.gameId);
        } else {
            creatorWinner = tempTotal1 > tempTotal2;
        }
        uint256 tempWinnings = (tempTotal1 + tempTotal2) / 2;
        if (creatorWinner) {
            return (tempWinnings, tempGame.creator, tempGame.caller1);
        } else {
            return (tempWinnings, tempGame.caller2, tempGame.caller3);
        }
    }

    function getWinningsFromSoloOpening(bytes32 resolutionSeed, uint256 lobbyId)
        internal
        returns (uint256)
    {
        lobbyStruct memory tempGame = lobbyDataFromId[lobbyId];
        uint256 tempTotal;
        for (uint256 i = 0; i < tempGame.numberOfCases; i++) {
            uint256 caseId = caseIdFromLobbyIdRoundId[lobbyId][i];
            uint256 rolledTicket = uint256(
                keccak256(abi.encodePacked(resolutionSeed, lobbyId, i))
            ) % 100000;

            emit roundResolved(tempGame.gameId, i, rolledTicket, 0, 0, 0);
            tempTotal += getPrizeFromTicket(caseId, rolledTicket);
        }
        return tempTotal;
    }

    function getWinningsFrom1v1(bytes32 resolutionSeed, uint256 lobbyId)
        internal
        returns (uint256, address)
    {
        lobbyStruct memory tempGame = lobbyDataFromId[lobbyId];
        uint256 tempTotal1;
        uint256 tempTotal2;
        for (uint256 i = 0; i < tempGame.numberOfCases; i++) {
            uint256 caseId = caseIdFromLobbyIdRoundId[lobbyId][i];
            uint256 rolledTicket = uint256(
                keccak256(abi.encodePacked(resolutionSeed, lobbyId, i))
            ) % 100000;
            uint256 rolledTicket2 = uint256(
                keccak256(abi.encodePacked(resolutionSeed, lobbyId, 100 - i))
            ) % 100000;

            emit roundResolved(
                tempGame.gameId,
                i,
                rolledTicket,
                rolledTicket2,
                0,
                0
            );
            tempTotal1 += getPrizeFromTicket(caseId, rolledTicket);
            tempTotal2 += getPrizeFromTicket(caseId, rolledTicket2);
        }
        bool creatorWinner;
        if (tempTotal1 == tempTotal2) {
            creatorWinner = tieBreaker(resolutionSeed, tempGame.gameId);
        } else {
            creatorWinner = tempTotal1 > tempTotal2;
        }
        if (creatorWinner) {
            return (tempTotal1 + tempTotal2, tempGame.creator);
        } else {
            return (tempTotal1 + tempTotal2, tempGame.caller1);
        }
    }

    function tieBreaker(bytes32 resolutionSeed, uint256 gameId)
        public
        view
        returns (bool)
    {
        return
            uint256(keccak256(abi.encodePacked(resolutionSeed, gameId))) % 2 ==
            0;
    }

    function startFreeLobby(
        uint8 _gameType, // 0 for solo, 1 for 1v1, 2 for 2v2, 3 for 1v1v1
        uint256[] calldata _lootboxIds,
        address player1,
        address player2,
        address player3,
        address player4
    ) external {
        require(
            resolverAddresses[msg.sender],
            "not permissioned to add free battles"
        );
        require(
            _lootboxIds.length <= caseCountMax && _lootboxIds.length > 0,
            "Too many lootboxes"
        );
        require(_gameType <= 3, "Select correct gametype");
        uint256 counter = 1;
        uint256 _gameCount = gameCount;
        uint256 lobbyCost = getCostOfLootboxes(_lootboxIds);
        while (true) {
            if (activeLobbyId[counter]) {
                counter += 1;
                continue;
            } else {
                activeLobbyId[counter] = true;
                lobbyIdFromGameId[_gameCount] = counter;

                for (uint256 i = 0; i < _lootboxIds.length; i++) {
                    caseIdFromLobbyIdRoundId[counter][i] = _lootboxIds[i];
                }
                lobbyDataFromId[counter] = lobbyStruct(
                    _gameType,
                    2,
                    uint16(_lootboxIds.length),
                    _gameCount,
                    lobbyCost,
                    block.number,
                    player1,
                    player2,
                    player3,
                    player4
                );
                emit lobbyMade(
                    counter,
                    _gameCount,
                    _gameType,
                    _lootboxIds,
                    msg.sender,
                    lobbyCost,
                    true
                );
                emit lobbyJoined(player2, _gameCount, 2);
                emit lobbyJoined(player3, _gameCount, 3);
                emit lobbyJoined(player4, _gameCount, 4);
                emit gameStarted(
                    _gameCount,
                    block.number,
                    player1,
                    player2,
                    player3,
                    player4
                );
                uint256 currentGameCountOfBlock = blockNumberGameCount[
                    block.number
                ];
                blockNumberGameCount[block.number]++;
                lobbyIdFromBlockNumberAndItter[block.number][
                    currentGameCountOfBlock
                ] = counter;
                break;
            }
        }

        gameCount++;
    }

    function startLobby(
        uint8 _gameType, // 0 for solo, 1 for 1v1, 2 for 2v2, 3 for 1v1v1
        uint256[] calldata _lootboxIds,
        bool _pvp,
        bool _promo
    ) external {
        require(startGames, "Games are not enabled");
        require(
            _lootboxIds.length <= caseCountMax && _lootboxIds.length > 0,
            "Too many lootboxes"
        );
        require(_gameType <= 3, "Select correct gametype");
        uint256 counter = 1;
        uint256 _gameCount = gameCount;
        uint256 lobbyCost = getCostOfLootboxes(_lootboxIds);
        if (!_promo) {
            LootyBox tokenContract = LootyBox(tokenAddress);
            tokenContract.burnTokens(lobbyCost, msg.sender);
        } else {
            require(
                promotionalBalanceOfUser[msg.sender] >= lobbyCost,
                "Not enough promo balance to start lobby"
            );
            promotionalBalanceOfUser[msg.sender] -= lobbyCost;
        }

        while (true) {
            if (activeLobbyId[counter]) {
                counter += 1;
                continue;
            } else {
                activeLobbyId[counter] = true;
                lobbyIdFromGameId[_gameCount] = counter;

                for (uint256 i = 0; i < _lootboxIds.length; i++) {
                    caseIdFromLobbyIdRoundId[counter][i] = _lootboxIds[i];
                }
                lobbyDataFromId[counter] = lobbyStruct(
                    _gameType,
                    1,
                    uint16(_lootboxIds.length),
                    _gameCount,
                    lobbyCost,
                    0,
                    msg.sender,
                    address(0),
                    address(0),
                    address(0)
                );
                emit lobbyMade(
                    counter,
                    _gameCount,
                    _gameType,
                    _lootboxIds,
                    msg.sender,
                    lobbyCost,
                    _pvp
                );
                break;
            }
        }
        if (_gameType == 0) {
            emit gameStarted(
                _gameCount,
                block.number,
                msg.sender,
                address(0),
                address(0),
                address(0)
            );
            lobbyDataFromId[counter].blockInitialized = block.number;
            lobbyDataFromId[counter].gameState = 2;
            uint256 currentGameCountOfBlock = blockNumberGameCount[
                block.number
            ];
            blockNumberGameCount[block.number]++;
            lobbyIdFromBlockNumberAndItter[block.number][
                currentGameCountOfBlock
            ] = counter;
        } else if (!_pvp) {
            callBob(_gameCount);
        }
        gameCount++;
    }
}