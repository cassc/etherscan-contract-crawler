//SPDX-License-Identifier: MIT

/**
ChameleonGO - The Coin That Changes Daily
Tracked SmartCoins Swap

Website: https://chameleongo.org
Twitter: https://twitter.com/ChameleonGO
Telegram: https://t.me/ChameleonGO

 ██████╗██╗  ██╗ █████╗ ███╗   ███╗███████╗██╗     ███████╗ ██████╗ ███╗   ██╗     ██████╗  ██████╗
██╔════╝██║  ██║██╔══██╗████╗ ████║██╔════╝██║     ██╔════╝██╔═══██╗████╗  ██║    ██╔════╝ ██╔═══██╗
██║     ███████║███████║██╔████╔██║█████╗  ██║     █████╗  ██║   ██║██╔██╗ ██║    ██║  ███╗██║   ██║
██║     ██╔══██║██╔══██║██║╚██╔╝██║██╔══╝  ██║     ██╔══╝  ██║   ██║██║╚██╗██║    ██║   ██║██║   ██║
╚██████╗██║  ██║██║  ██║██║ ╚═╝ ██║███████╗███████╗███████╗╚██████╔╝██║ ╚████║    ╚██████╔╝╚██████╔╝
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝     ╚═════╝  ╚═════╝

*/



import "@openzeppelin/contracts/utils/Context.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@looksrare/contracts-libs/contracts/ReentrancyGuard.sol";

pragma solidity 0.8.20;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract CHAM is ERC20, Context, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private isBlacklisted;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public transferDelayEnabled = false;
    address payable private _taxWallet;

    uint256 private _startBT=10; //Initial Buy Tax
    uint256 private _startST=25; //Initial Sell Tax
    uint256 private _medBuyTax=3; //First 10 days Buy Tax
    uint256 private _medSellTax=3; //First 10 days Sell Tax
    uint256 private _finalBuyTax=1; //Final Buy Tax
    uint256 private _finalSellTax=1; //Final Sell Tax
    uint256 private _buyCount=0;

    uint256 private _avatarCreatorTax=4; //This is the tax the avatar creator gets when they are traded through Chameleon SWAP

    uint256 private _preventSwapBefore=20;

    uint8 private constant _decimals = 10;
    uint256 private constant _totalSupply = 1_000_000_000 * 10**_decimals;
    string private constant _name = "ChameleonGO";
    string private constant _symbol = "CHAM";
    uint256 public _maxTxAmount =   _totalSupply * 15 / 1000; // 1.5% of total supply
    uint256 public _maxWalletAmount = _totalSupply * 15 / 1000; // 1.5% of total supply
    uint256 public _taxSwapThreshold = _totalSupply * 2000; // 0.1% of total supply
    uint256 public _maxTaxSwap = _totalSupply * 3 / 1000; // 0.3% of total supply

    //The price in ETH to create an avatar 0.05 ETH
    uint256 public _avatarCreationFee = 5 * 10**16;

    //Holds all created avatars and their respective supplies
    mapping(uint256 => Avatar) private _avatars;

    //User Balances _balances divided between each avatar. _userAvatarBalances[userAddress][avatarNumber];
    mapping (address => mapping (uint256 => uint256)) private _userAvatarBalances;

    //User selected avatar that will be transfered.
    //This only works after _launchIsOver = true
    mapping(address => uint256) private _userSelectedTradeAvatar;

    mapping(address => TradeAuthorization) private _authorizedTrades;

    uint256 public _deployDate;
    uint256 public _launchBlock;
    bool private _launchIsOver = false;
    bool private _intermediateFee = false;
    uint256 public _lastCreatedAvatarId = 0;

    IDEXRouter private router;
    address private pair;
    bool private tradingOpen = false;
    bool private inSwap = false;
    bool private swapEnabled = false;
    uint256 private firstBlock;

    event AvatarCreated(address creator, string name, string symbol, uint256 supply, uint256 supplyFromAvatarId);
    event MaxTxAmountUpdated(uint _maxTxAmount);
    event UserUpdatedTradeAvatar(address user, uint256 avatarId);
    event ChameleonTradeAllowed(
        address traders,
        uint256 sendAmount,
        uint256 sendAvatarId,
        uint256 receiveAmount,
        uint256 receiveAvatarId
    );
    event ChameleonTradePerformed(
        address trader1,
        address trader2,
        uint256 trader1SendAmount,
        uint256 trader1SendAvatarId,
        uint256 trader1ReceiveAmount,
        uint256 trader1ReceiveAvatarId
    );

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    struct Avatar {
        string name;
        string symbol;
        uint256 supply;
        address creator;
        uint256 creationDate;
    }

    struct TradeAuthorization {
        uint256 sendAmount;
        uint256 sendAvatarId;
        uint256 receiveAmount;
        uint256 receiveAvatarId;
        bool allowed;
    }

    //Max avatar name length in bytes
    uint256 public constant _maxAvatarNameBytes = 20;

    //Max avatar symbol length in bytes
    uint256 public constant _maxAvatarSymbolBytes = 7;

    function _stringsMatch(string memory _a, string memory _b) private pure returns (bool) {
        return keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    /*
        Creating an avatar
    */
    function createAvatar(
        string memory avatarName,
        string memory avatarSymbol,
        uint256 supply,
        uint256 supplyFromAvatarId
    ) external payable nonReentrant returns (uint256) {
        bool isOwner = msg.sender == owner();
        if(!isOwner) {
            require(_launchIsOver, "Public avatar creation is only allowed after the launch is over");
            require(msg.value >= _avatarCreationFee, "Avatar creation tax invalid");
        }
        /*
            During the launch, the 10 original avatars will have dynamic supply
            But supply isn't created, it is transformed from the main avatar id 0
        */
        if(_launchIsOver) {
            require(_userAvatarBalances[msg.sender][supplyFromAvatarId] >= supply, "Not enough balance of the selected avatar");
        }
        require(bytes(avatarName).length <= _maxAvatarNameBytes, "Name too big");
        require(bytes(avatarSymbol).length <= _maxAvatarSymbolBytes, "Symbol too big");
        require(!_stringsMatch(avatarSymbol, "CHAM"), "Cannot use this symbol name");

        ++_lastCreatedAvatarId;

        Avatar storage a = _avatars[_lastCreatedAvatarId];
        a.name = avatarName;
        a.name = avatarSymbol;
        a.supply = _launchIsOver ? supply : 0;
        a.creator = _launchIsOver ? msg.sender : address(this);
        a.creationDate = block.timestamp;

        if(_launchIsOver) {
            _userAvatarBalances[msg.sender][supplyFromAvatarId] -= supply;
            _avatars[supplyFromAvatarId].supply -= supply;

            _userAvatarBalances[msg.sender][_lastCreatedAvatarId] += supply;
        }

        emit AvatarCreated(
            msg.sender,
            avatarName,
            avatarSymbol,
            supply,
            supplyFromAvatarId
        );

        return _lastCreatedAvatarId;
    }

    constructor () {

        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IDEXFactory(router.factory()).createPair(address(this), router.WETH());

        _deployDate = block.timestamp;
        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _totalSupply;

        //Initialize main avatar 0 with all the coins
        Avatar storage a = _avatars[0];
        a.name = "Chameleon";
        a.symbol = "CHAM";
        a.supply = _totalSupply;
        a.creator = address(this);
        a.creationDate = block.timestamp;

        _userAvatarBalances[_msgSender()][0] = _totalSupply;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function getOwner() external view override returns (address) {
        return owner();
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function totalAvatarSupply(uint256 avatarId) public view returns (uint256) {
        return _avatars[avatarId].supply;
    }

    function setSelectedTradeAvatar(uint256 avatarId) external {
        _userSelectedTradeAvatar[_msgSender()] = avatarId;
        emit UserUpdatedTradeAvatar(_msgSender(), avatarId);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool isFromUser = (
            from != address(this)
            && from != address(router)
            && from != address(pair)
        );

        bool isToUser = (
            to != address(this)
            && to != address(router)
            && to != address(pair)
        );

        uint256 soldAvatarId = 0;
        uint256 receivedAvatarId = 0;
        if(isFromUser) {
            soldAvatarId = _userSelectedTradeAvatar[from];
            require(_userAvatarBalances[from][soldAvatarId] >= amount, "Not enough balance of the selected avatar");
        }
        if(isFromUser && isToUser) {
            receivedAvatarId = soldAvatarId;
        }
        //All transfers TO the contract through uniswap burns the avatar and returns in main CHAM id 0;
        if(!_launchIsOver && isToUser) {
            receivedAvatarId = _lastCreatedAvatarId;
        }

        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            require(!isBlacklisted[from]);

            if (transferDelayEnabled) {
                if (to != address(router) && to != address(pair)) {
                    require(_holderLastTransferTimestamp[tx.origin] < block.number,"Only one transfer per block allowed.");
                    _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            if (from == pair && to != address(router) && ! _isExcludedFromFee[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletAmount, "Exceeds the maxWalletSize.");
                if (firstBlock + 3  > block.number) {
                    isBlacklisted[to] = true;
                }
                _buyCount++;
            }

            taxAmount = amount.mul(
                isBlacklisted[to] ? 49 :
                _launchIsOver ? _finalBuyTax
                    : _intermediateFee ? _medBuyTax
                        : _startBT
            ).div(100);

            if(to == pair && from!= address(this) ){
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                taxAmount = amount.mul(
                    isBlacklisted[from] ? 49 :
                    _launchIsOver ? _finalSellTax
                        : _intermediateFee ? _medSellTax
                            : _startST
                ).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == pair && swapEnabled && contractTokenBalance>_taxSwapThreshold && _buyCount>_preventSwapBefore) {
                swapTokensForEth(min(amount,min(contractTokenBalance,_maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if(taxAmount>0){
            _balances[address(this)]=_balances[address(this)].add(taxAmount);
            emit Transfer(from, address(this),taxAmount);
        }

        uint256 transferredMinusTax = amount.sub(taxAmount);

        _balances[from]= _balances[from].sub(amount);
        _balances[to]= _balances[to].add(transferredMinusTax);

        if (isFromUser) {
            _userAvatarBalances[from][soldAvatarId] -= amount;
            _avatars[soldAvatarId].supply -= amount;
        } else {
            _avatars[0].supply -= amount;
        }

        if(isToUser) {
            _userAvatarBalances[to][receivedAvatarId] += transferredMinusTax;
            _avatars[receivedAvatarId].supply += transferredMinusTax;
        } else {
            _avatars[0].supply += transferredMinusTax;
        }

        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function chameleonSwapAllowAndTrade(
        address with,
        uint256 sendAmount,
        uint256 sendAvatarId,
        uint256 receiveAmount,
        uint256 receiveAvatarId
    ) public returns (bool) {
        require(_launchIsOver, "Chameleon Swap not enabled yet. Wait for the launch to end");
        require(
            chameleonSwapAllowTrade(
                sendAmount,
                sendAvatarId,
                receiveAmount,
                receiveAvatarId
            ),
            "Invalid Trade Authorization"
        );
        require(
            chameleonSwapPerformTrade(with),
            "Error trading"
        );

        return true;
    }

    function chameleonSwapPerformTrade(
        address with
    ) public nonReentrant returns (bool) {
        require(_launchIsOver, "Chameleon Swap not enabled yet. Wait for the launch to end");
        require(with != address(0), "ERC20: transfer to the zero address");

        TradeAuthorization storage senderTA = _authorizedTrades[msg.sender];
        TradeAuthorization storage receiverTA = _authorizedTrades[with];

        require(
            senderTA.allowed && receiverTA.allowed,
            "Authorization has not been allowed or initiated"
        );
        require(
            senderTA.sendAmount == receiverTA.receiveAmount
            && senderTA.sendAvatarId == receiverTA.receiveAvatarId
            && senderTA.receiveAmount == receiverTA.sendAmount
            && senderTA.receiveAvatarId == receiverTA.sendAvatarId,
            "Invalid trade"
        );

        require(senderTA.sendAmount > 0 && receiverTA.sendAmount > 0, "Transfer amount must be greater than zero");

        require(_userAvatarBalances[msg.sender][senderTA.sendAvatarId] >= senderTA.sendAmount, "Insufficient balance of the sender");
        require(_userAvatarBalances[with][receiverTA.sendAvatarId] >= receiverTA.sendAmount, "Insufficient balance of the receiver");

        uint256 senderTaxAmount = 0;
        uint256 receiverTaxAmount = 0;

        address trader1ReceivedAvatarCreator = _avatars[senderTA.receiveAvatarId].creator;
        address trader2ReceivedAvatarCreator = _avatars[receiverTA.receiveAvatarId].creator;

        if(
            msg.sender != address(this)
            || msg.sender != trader1ReceivedAvatarCreator
        ) {
            senderTaxAmount = senderTA.receiveAmount.mul(_avatarCreatorTax).div(100);
        }

        if(
            with != address(this)
            || with != trader2ReceivedAvatarCreator
        ) {
            receiverTaxAmount = receiverTA.receiveAmount.mul(_avatarCreatorTax).div(100);
        }

        _balances[msg.sender] = _balances[msg.sender].sub(senderTA.sendAmount).add(receiverTA.sendAmount.sub(senderTaxAmount));
        _userAvatarBalances[msg.sender][senderTA.sendAvatarId] = _userAvatarBalances[msg.sender][senderTA.sendAvatarId].sub(senderTA.sendAmount);
        _userAvatarBalances[msg.sender][senderTA.receiveAvatarId] = _userAvatarBalances[msg.sender][senderTA.receiveAvatarId].add(receiverTA.sendAmount.sub(senderTaxAmount));

        if(senderTaxAmount > 0) {
            _balances[trader1ReceivedAvatarCreator] = _balances[trader1ReceivedAvatarCreator].add(senderTaxAmount);
            _userAvatarBalances[trader1ReceivedAvatarCreator][senderTA.receiveAvatarId] = _userAvatarBalances[trader1ReceivedAvatarCreator][senderTA.receiveAvatarId].add(senderTaxAmount);
        }

        _balances[with] = _balances[with].sub(receiverTA.sendAmount).add(senderTA.sendAmount.sub(receiverTaxAmount));
        _userAvatarBalances[with][receiverTA.sendAvatarId] = _userAvatarBalances[with][receiverTA.sendAvatarId].sub(receiverTA.sendAmount);
        _userAvatarBalances[with][receiverTA.receiveAvatarId] = _userAvatarBalances[with][receiverTA.receiveAvatarId].add(senderTA.sendAmount.sub(receiverTaxAmount));

        if(receiverTaxAmount > 0) {
            _balances[trader2ReceivedAvatarCreator] = _balances[trader2ReceivedAvatarCreator].add(receiverTaxAmount);
            _userAvatarBalances[trader2ReceivedAvatarCreator][receiverTA.receiveAvatarId] = _userAvatarBalances[trader2ReceivedAvatarCreator][receiverTA.receiveAvatarId].add(receiverTaxAmount);
        }

        senderTA.allowed = false;
        receiverTA.allowed = false;

        emit ChameleonTradePerformed(
            msg.sender,
            with,
            senderTA.sendAmount,
            senderTA.sendAvatarId,
            senderTA.receiveAmount,
            senderTA.receiveAvatarId
        );

        return true;
    }

    function chameleonSwapAllowTrade(
        uint256 sendAmount,
        uint256 sendAvatarId,
        uint256 receiveAmount,
        uint256 receiveAvatarId
    ) public nonReentrant returns (bool) {
        require(_launchIsOver, "Chameleon Swap not enabled yet. Wait for the launch to end");
        require(sendAmount > 0, "Send amount must be greater than zero");
        require(receiveAmount > 0, "Receive amount must be greater than zero");
        require(sendAvatarId != receiveAvatarId, "Traded avatars must be different");
        require(_userAvatarBalances[msg.sender][sendAvatarId] >= sendAmount, "Insufficient balance of the sender");

        TradeAuthorization storage ta = _authorizedTrades[msg.sender];
        ta.sendAvatarId = sendAvatarId;
        ta.sendAmount = sendAmount;
        ta.receiveAmount = receiveAmount;
        ta.receiveAvatarId = receiveAvatarId;
        ta.allowed = true;

        emit ChameleonTradeAllowed(
            msg.sender,
            sendAmount,
            sendAvatarId,
            receiveAmount,
            receiveAvatarId
        );

        return true;
    }


    function min(uint256 a, uint256 b) private pure returns (uint256){
        return (a>b)?b:a;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        if(tokenAmount==0){return;}
        if(!tradingOpen){return;}
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function removeLimits() external onlyOwner {
        _maxTxAmount = _totalSupply;
        _maxWalletAmount=_totalSupply;
        transferDelayEnabled=false;
        emit MaxTxAmountUpdated(_totalSupply);
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function isBot(address a) public view returns (bool){
        return isBlacklisted[a];
    }

    function manageList(address[] memory isBlacklisted_) external onlyOwner{
        for (uint i = 0; i < isBlacklisted_.length; i++) {
            isBlacklisted[isBlacklisted_[i]] = true;
        }
    }

    function reduceFee(uint256 _newBuyFee,uint256 _newSellFee) external onlyOwner{
        _finalBuyTax=_newBuyFee;
        _finalSellTax=_newSellFee;
    }

    function setLaunchOver() external onlyOwner {
        _launchIsOver = true;
    }

    function setIntermediateFee() external onlyOwner {
        _intermediateFee = true;
    }

    function setInitialBuySellTax(uint256 newBuyTax, uint256 newSellTax) external onlyOwner {
        _startBT = newBuyTax;
        _startST = newSellTax;
    }

    function setMedBuySellTax(uint256 newBuyTax, uint256 newSellTax) external onlyOwner {
        _medBuyTax = newBuyTax;
        _medSellTax = newSellTax;
    }

    function setAvatarCreatorTax(uint256 newTax) external onlyOwner {
        _avatarCreatorTax = newTax;
    }

    //Update Fee in ETH
    function setAvatarCreationFee(uint256 newFee) external onlyOwner {
        _avatarCreationFee = newFee;
    }

    function openTrading() external onlyOwner {
        require(!tradingOpen,"trading is already open");
        swapEnabled = true;
        tradingOpen = true;
        firstBlock = block.number;
    }

    function avatarBalanceOf(address user, uint256 avatarId) public view returns (uint256) {
        return _userAvatarBalances[user][avatarId];
    }

    function getAvatar(uint256 avatarId) public view returns (Avatar memory) {
        return _avatars[avatarId];
    }

    function userSelectedTradeAvatarId(address user) public view returns (uint256) {
        return _userSelectedTradeAvatar[user];
    }

    function isLaunchOver() public view returns (bool) {
        return _launchIsOver;
    }

    function cancelAuthorizations() public nonReentrant {
        require(_launchIsOver, "Chameleon Swap not enabled yet");
        _authorizedTrades[msg.sender].allowed = false;
    }

    receive() external payable {}

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function manualSwap() external {
        require(_msgSender()==_taxWallet);
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance>0){
            swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
            sendETHToFee(ethBalance);
        }
    }
}