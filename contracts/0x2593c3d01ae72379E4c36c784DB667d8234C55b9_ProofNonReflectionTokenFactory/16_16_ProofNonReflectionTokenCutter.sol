// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../libraries/Ownable.sol";
import "../libraries/Context.sol";
import "../libraries/ProofNonReflectionTokenFees.sol";
import "../interfaces/IFACTORY.sol";
import "../interfaces/IDividendDistributor.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IProofNonReflectionTokenCutter.sol";

contract ProofNonReflectionTokenCutter is
    Context,
    IProofNonReflectionTokenCutter
{

    //This token was created with PROOF, and audited by Solidity Finance — https://proofplatform.io/projects
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;
    address payable public proofBurnerAddress;
    address public proofAdmin;
    uint256 public whitelistEndTime;

    bool public restrictWhales = true;

    mapping(address => bool) public userWhitelist;
    address[] public nftWhitelist;
    bool public whitelistMode = true;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) public isDividendExempt;

    uint256 public launchedAt;
    uint256 public proofFee = 2;

    uint256 public mainFee;
    uint256 public lpFee;
    uint256 public devFee;

    uint256 public mainFeeOnSell;
    uint256 public lpFeeOnSell;
    uint256 public devFeeOnSell;

    uint256 public totalFee;
    uint256 public totalFeeIfSelling;

    IUniswapV2Router02 public router;
    address public pair;
    address public factory;
    address public tokenOwner;
    address payable public devWallet;
    address payable public mainWallet;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public tradingStatus = true;

    mapping(address => bool) public bots;

    uint256 public _maxTxAmount;
    uint256 public _walletMax;
    uint256 public swapThreshold;

    constructor() {
        factory = msg.sender;
    }

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier onlyProofAdmin() {
        require(
            proofAdmin == _msgSender(),
            "Ownable: caller is not the proofAdmin"
        );
        _;
    }

    modifier onlyOwner() {
        require(tokenOwner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyFactory() {
        require(factory == _msgSender(), "Ownable: caller is not the factory");
        _;
    }

    function setBasicData(
        BaseData memory _baseData,
        ProofNonReflectionTokenFees.allFees memory fees
    ) external onlyFactory {
        _name = _baseData.tokenName;
        _symbol = _baseData.tokenSymbol;
        _totalSupply = _baseData.initialSupply;

        //Tx & Wallet Limits
        require(_baseData.percentToLP >= 70, "Too low");	
        _maxTxAmount = (_baseData.initialSupply * 5) / 1000;
        _walletMax = (_baseData.initialSupply * 1) / 100;
        swapThreshold = (_baseData.initialSupply * 5) / 4000;

        router = IUniswapV2Router02(_baseData.routerAddress);
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );

        _allowances[address(this)][address(router)] = type(uint256).max;

        userWhitelist[address(this)] = true;
        userWhitelist[factory] = true;
        userWhitelist[pair] = true;
        userWhitelist[_baseData.owner] = true;
        userWhitelist[_baseData.initialProofAdmin] = true;
        userWhitelist[_baseData.routerAddress] = true;
        _addWhitelist(_baseData.whitelists);
        nftWhitelist = _baseData.nftWhitelist;

        isFeeExempt[address(this)] = true;
        isFeeExempt[factory] = true;
        isFeeExempt[_baseData.owner] = true;

        isTxLimitExempt[_baseData.owner] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[factory] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[ZERO] = true;

        whitelistEndTime = _baseData.whitelistEndTime;

        //Fees
        lpFee = fees.lpFee;
        lpFeeOnSell = fees.lpFeeOnSell;
        devFee = fees.devFee;
        devFeeOnSell = fees.devFeeOnSell;
        mainFee = fees.mainFee;
        mainFeeOnSell = fees.mainFeeOnSell;

        totalFee = devFee + lpFee + mainFee + proofFee;
        totalFeeIfSelling =
            devFeeOnSell +
            lpFeeOnSell +
            mainFeeOnSell +
            proofFee;

        require(totalFee <= 12, "Too high fee");
        require(totalFeeIfSelling <= 17, "Too high sell fee");

        tokenOwner = _baseData.owner;
        devWallet = payable(_baseData.dev);
        mainWallet = payable(_baseData.main);
        proofAdmin = _baseData.initialProofAdmin;

        //Initial supply
        uint256 forLP = (_baseData.initialSupply * _baseData.percentToLP) / 100; //95%
        uint256 forOwner = _baseData.initialSupply - forLP; //5%

        _balances[msg.sender] += forLP;
        _balances[_baseData.owner] += forOwner;

        emit Transfer(address(0), msg.sender, forLP);
        emit Transfer(address(0), _baseData.owner, forOwner);
    }

    //proofAdmin functions

    function updateWhitelistEndTime(
        uint256 _whitelistEndTime
    ) external onlyProofAdmin {
        require(
            block.timestamp < _whitelistEndTime,
            "invalid whitelistEndTime"
        );
        whitelistEndTime = _whitelistEndTime;
        whitelistMode = true;
    }

    function updateProofAdmin(
        address newAdmin
    ) external virtual onlyProofAdmin {
        proofAdmin = newAdmin;
        userWhitelist[newAdmin] = true;
    }

    function updateProofBurnerAddress(
        address newproofBurnerAddress
    ) external onlyProofAdmin {
        proofBurnerAddress = payable(newproofBurnerAddress);
    }

    function setBots(address[] memory bots_) external onlyProofAdmin {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    //Factory functions
    function swapTradingStatus() external onlyFactory {
        tradingStatus = !tradingStatus;
    }

    function setLaunchedAt() external onlyFactory {
        require(launchedAt == 0, "already launched");
        launchedAt = block.timestamp;
    }

    function cancelToken() external onlyFactory {
        isFeeExempt[address(router)] = true;
        isTxLimitExempt[address(router)] = true;
        isTxLimitExempt[tokenOwner] = true;
        tradingStatus = true;
        restrictWhales = false;
        swapAndLiquifyEnabled = false;
    }

    //Owner functions
    function changeFees(
        uint256 initialMainFee,
        uint256 initialMainFeeOnSell,
        uint256 initialLpFee,
        uint256 initialLpFeeOnSell,
        uint256 initialDevFee,
        uint256 initialDevFeeOnSell
    ) external onlyOwner {
        mainFee = initialMainFee;
        lpFee = initialLpFee;
        devFee = initialDevFee;

        mainFeeOnSell = initialMainFeeOnSell;
        lpFeeOnSell = initialLpFeeOnSell;
        devFeeOnSell = initialDevFeeOnSell;

        totalFee = devFee + lpFee + proofFee + mainFee;
        totalFeeIfSelling =
            devFeeOnSell +
            lpFeeOnSell +
            proofFee +
            mainFeeOnSell;

        require(totalFee <= 12, "Too high fee");
        require(totalFeeIfSelling <= 17, "Too high fee");
    }

    function changeTxLimit(uint256 newLimit) external onlyOwner {
        require(launchedAt != 0, "!launched");
        require(newLimit >= (_totalSupply * 5) / 1000, "Min 0.5%");	
        require(newLimit <= (_totalSupply * 3) / 100, "Max 3%");
        _maxTxAmount = newLimit;
    }

    function changeWalletLimit(uint256 newLimit) external onlyOwner {
        require(launchedAt != 0, "!launched");
        require(newLimit >= (_totalSupply * 5) / 1000, "Min 0.5%");	
        require(newLimit <= (_totalSupply * 3) / 100, "Max 3%");
        _walletMax = newLimit;
    }

    function changeRestrictWhales(bool newValue) external onlyOwner {
        require(launchedAt != 0, "!launched");
        restrictWhales = newValue;
    }

    function changeIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function changeIsTxLimitExempt(
        address holder,
        bool exempt
    ) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function reduceProofFee() external onlyOwner {
        require(proofFee == 2, "!already reduced");
        require(launchedAt != 0, "!launched");
        require(block.timestamp >= launchedAt + 72 hours, "too soon");

        proofFee = 1;
        totalFee = devFee + lpFee + proofFee + mainFee;
        totalFeeIfSelling =
            devFeeOnSell +
            lpFeeOnSell +
            proofFee +
            mainFeeOnSell;
    }

    function adjustProofFee(uint256 _proofFee) external onlyProofAdmin {	
        require(launchedAt != 0, "!launched");	
        if (block.timestamp >= launchedAt + 72 hours) {	
            require(_proofFee <= 1);	
            proofFee = _proofFee;	
            totalFee = devFee + lpFee + proofFee + mainFee;	
            totalFeeIfSelling =	
                devFeeOnSell +	
                lpFeeOnSell +	
                proofFee +	
                mainFeeOnSell;	
        } else {	
            require(_proofFee <= 2);	
            proofFee = _proofFee;	
            totalFee = devFee + lpFee + proofFee + mainFee;	
            totalFeeIfSelling =	
                devFeeOnSell +	
                lpFeeOnSell +	
                proofFee +	
                mainFeeOnSell;	
        }	
    }

    function setDevWallet(address payable newDevWallet) external onlyOwner {
        devWallet = payable(newDevWallet);
    }

    function setMainWallet(address payable newMainWallet) external onlyOwner {
        mainWallet = newMainWallet;
    }

    function setOwnerWallet(address payable newOwnerWallet) external onlyOwner {
        tokenOwner = newOwnerWallet;
    }

    function changeSwapBackSettings(
        bool enableSwapBack,
        uint256 newSwapBackLimit
    ) external onlyOwner {
        swapAndLiquifyEnabled = enableSwapBack;
        swapThreshold = newSwapBackLimit;
    }

    function delBot(address notbot) external {
        address sender = _msgSender();
        require(
            sender == proofAdmin || sender == tokenOwner,
            "Owanble: caller doesn't have permission"
        );
        bots[notbot] = false;
    }

    function isWhitelisted(address user) public view returns (bool) {
        return userWhitelist[user];
    }
    function holdsSupportedNFT(address user) public view returns (bool) {
        for (uint256 i = 0; i < nftWhitelist.length; i++) {
            if (IERC721(nftWhitelist[i]).balanceOf(user) > 0) {
                return true;
            }
        }
        return false;
    }

    function getCirculatingSupply() external view returns (uint256) {
        return _totalSupply - balanceOf(DEAD) - balanceOf(ZERO);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view virtual override returns (uint8) {
        return 9;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address to,
        uint256 amount
    ) external virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 amount
    ) external virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     *
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(tradingStatus, "Trading Closed");
        require(!bots[sender] && !bots[recipient]);

        if(whitelistMode) {
            if (block.timestamp >= whitelistEndTime ) {
                whitelistMode = false;
            } else {
                if (sender == pair) { //buy
                    require(isWhitelisted(recipient) || holdsSupportedNFT(recipient), "Not whitelisted");
                } else if (recipient == pair) { //sell
                    require(isWhitelisted(sender) || holdsSupportedNFT(sender), "Not whitelisted");
                } else { //transfer
                    require((isWhitelisted(sender) || holdsSupportedNFT(sender)) && (isWhitelisted(recipient) || holdsSupportedNFT(recipient)), "Not Whitelisted");
                }
            }
        }

        if (inSwapAndLiquify) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (recipient == pair && restrictWhales) {	
            require(	
                amount <= _maxTxAmount ||	
                    (isTxLimitExempt[sender] && isTxLimitExempt[recipient]),	
                "Max TX"	
            );	
        }	
        if (!isTxLimitExempt[recipient] && restrictWhales) {	
            require(_balances[recipient] + amount <= _walletMax, "Max Wallet");	
        }

        if (
            sender != pair &&
            !inSwapAndLiquify &&
            swapAndLiquifyEnabled &&
            _balances[address(this)] >= swapThreshold
        ) {
            swapBack();
        }

        _balances[sender] = _balances[sender] - amount;
        uint256 finalAmount = amount;

        if (sender == pair || recipient == pair) {
            finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient]
                ? takeFee(sender, recipient, amount)
                : amount;
        }

        _balances[recipient] = _balances[recipient] + finalAmount;

        emit Transfer(sender, recipient, finalAmount);
        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeApplicable = pair == recipient
            ? totalFeeIfSelling
            : totalFee;
        uint256 feeAmount = (amount * feeApplicable) / 100;

        _balances[address(this)] = _balances[address(this)] + feeAmount;
        emit Transfer(sender, address(this), feeAmount);

        return amount - feeAmount;
    }

    function swapBack() internal lockTheSwap {
        uint256 tokensToLiquify = _balances[address(this)];

        uint256 amountToLiquify;
        uint256 devBalance;
        uint256 proofBalance;
        uint256 amountEthLiquidity;

        // Use sell ratios if buy tax too low
        if (totalFee <= 2) {
            amountToLiquify =
                (tokensToLiquify * lpFeeOnSell) /
                totalFeeIfSelling /
                2;
        } else {
            amountToLiquify = (tokensToLiquify * lpFee) / totalFee / 2;
        }

        uint256 amountToSwap = tokensToLiquify - amountToLiquify;
        if (amountToSwap == 0) return;

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

        uint256 amountETH = address(this).balance;

        // Use sell ratios if buy tax too low
        if (totalFee <= 2) {
            amountEthLiquidity =
                (amountETH * lpFeeOnSell) /
                totalFeeIfSelling /
                2;
        } else {
            amountEthLiquidity = (amountETH * lpFee) / totalFee / 2;
        }

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountEthLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                0x000000000000000000000000000000000000dEaD,
                block.timestamp
            );
        }

        uint256 amountETHafterLP = address(this).balance;

        // Use sell ratios if buy tax too low
        if (totalFee <= 2) {
            devBalance = (amountETHafterLP * devFeeOnSell) / totalFeeIfSelling;
            proofBalance = (amountETHafterLP * proofFee) / totalFeeIfSelling;
        } else {
            devBalance = (amountETHafterLP * devFee) / totalFee;
            proofBalance = (amountETHafterLP * proofFee) / totalFee;
        }

        uint256 amountEthMain = amountETHafterLP - devBalance - proofBalance;

        if (amountETH > 0) {
            if (proofBalance > 0) {
                uint256 revenueSplit = proofBalance / 2;
                (bool sent, ) = payable(IFACTORY(factory).proofRevenueAddress()).call{value: revenueSplit}("");
                require(sent);
                (bool sent1, ) = payable(IFACTORY(factory).proofRewardPoolAddress()).call{value: revenueSplit}("");
                require(sent1);
            }
            if (devBalance > 0) {
                (bool sent, ) = devWallet.call{value: devBalance}("");
                require(sent);
            }
            if (amountEthMain > 0) {
                (bool sent1, ) = mainWallet.call{value: amountEthMain}("");
                require(sent1);
            }
        }
    }

    function _addWhitelist(address[] memory _whitelists) internal {
        uint256 length = _whitelists.length;
        for (uint256 i = 0; i < length; i++) {
            userWhitelist[_whitelists[i]] = true;
        }
    }

    function addMoreToWhitelist(WhitelistAdd_ memory _WhitelistAdd) external onlyFactory {
        _addWhitelist(_WhitelistAdd.whitelists);
    }

    receive() external payable {}
}