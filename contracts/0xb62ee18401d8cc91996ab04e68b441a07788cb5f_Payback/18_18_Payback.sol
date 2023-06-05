//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./IMultisend.sol";

contract Payback is Context, IERC20, Ownable, IMultisend, IERC20Permit {

    event Bought(address indexed buyer, uint256 amount);
    event Sold(address indexed seller, uint256 amount);
    using SafeMath for uint256;
    // Constants
    string private constant _name = "Payback";
    string private constant _symbol = "PAYBACK";
    // Standard decimals
    uint8 private constant _decimals = 18;
    uint256 private constant totalTokens = 1000000000000000000000000000;
    // Mappings
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    /** START OF EIP2612/EIP712 VARS */
    
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /** END OF EIP2612/EIP712 VARS */
    

    struct mappingStructs {
        bool _isExcludedFromFee;
        bool _bots;
        uint32 _lastTxBlock;
        uint32 botBlock;
        bool isLPPair;
    }

    struct InitialData {
        uint32 buyTax;
        uint32 sellTax;
        uint32 maxWalletDiv;
        uint32 maxTxDiv;
        uint32 maxSwapDivisor;
    }

    struct TaxWallet {
        address wallet;
        uint32 ratio;
    }


    
    mapping(address => mappingStructs) mappedAddresses;

    // Arrays
    TaxWallet[] private taxWallets;
    // Global variables

    // Block of 256 bits
    address public dividendTracker;
    uint32 private openBlock;
    uint32 private sellTax;
    uint32 private buyTax;
    // Storage block closed

    // Block of 256 bits
    address private _controller;
    uint32 private maxTxRatio;
    uint32 private maxWalletRatio;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    
    // Storage block closed

    // Block of 256 bits
    address private devWallet;
    uint32 ethSendThresholdDivisor = 1000;
    uint32 private totalRatio;
    bool disableAddToBlocklist = false;
    // 48 bits 
    uint32 private taxSwapDivisor;
    
    IUniswapV2Router02 private uniswapV2Router;

    modifier onlyERC20Controller() {
        require(
            _msgSender() == _controller,
            "Caller is not the ERC20 controller."
        );
        _;
    }
    modifier onlyDev() {
        require(
            _msgSender() == devWallet,
            "Only developer can set this."
        );
        _;
    }

    constructor(address controller, address dev, InitialData memory id, TaxWallet[] memory wallets) {
        // Set up EIP712
        bytes32 hashedName = keccak256(bytes(_name));
        bytes32 hashedVersion = keccak256(bytes("1"));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
        
        // ERC20 controller
        _controller = payable(controller);
        devWallet = dev;

        buyTax = id.buyTax;
        sellTax = id.sellTax;
        taxSwapDivisor = id.maxSwapDivisor;
        maxTxRatio = id.maxTxDiv;
        maxWalletRatio = id.maxWalletDiv;
        

        mappedAddresses[_msgSender()] = mappingStructs({
            _isExcludedFromFee: true,
            _bots: false,
            _lastTxBlock: 0,
            botBlock: 0,
            isLPPair: false
        });

        mappedAddresses[address(this)] = mappingStructs({
            _isExcludedFromFee: true,
            _bots: false,
            _lastTxBlock: 0,
            botBlock: 0,
            isLPPair: false
        });
        // For instrumentation, we have to make this copy ourselves
        
        uint32 initialRatio = 0;
        for(uint256 i = 0; i < wallets.length; i++) {    
            mappedAddresses[wallets[i].wallet] = mappingStructs({
                _isExcludedFromFee: true,
                _bots: false,
                _lastTxBlock: 0,
                botBlock: 0,
                isLPPair: false
            });
            initialRatio += wallets[i].ratio;
            // Copy across now as the "classic" non-IR compiler can't do this copy
            taxWallets.push(TaxWallet(wallets[i].wallet, wallets[i].ratio));

        }
        totalRatio = initialRatio;
        addTokens(_msgSender(), totalTokens);
        emit Transfer(address(0), _msgSender(), totalTokens);
        
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
        return totalTokens;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }


    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);

        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }


    /// @notice Starts trading. Only callable by owner.
    function openTrading() public onlyOwner {
        require(!tradingOpen, "Can't open trading that's already open.");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), totalTokens);
        address uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );

        swapEnabled = true;
        
        tradingOpen = true;
        

        
        // Add the pairs to the list 
        mappedAddresses[uniswapV2Pair] = mappingStructs({
            _isExcludedFromFee: false,
            _bots: false,
            _lastTxBlock: 0,
            botBlock: 0,
            isLPPair: true
        });
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        uint32 _taxAmt;
        bool isSell = false;

        if (
            from != owner() &&
            to != owner() &&
            from != address(this) &&
            !mappedAddresses[to]._isExcludedFromFee &&
            !mappedAddresses[from]._isExcludedFromFee
        ) {
            // Max tx check
            require(amount <= totalTokens/maxTxRatio, "Max tx exceeded.");
 
            
            require(!mappedAddresses[to]._bots && !mappedAddresses[from]._bots, "Blocklisted.");

            // Buys
            if ((mappedAddresses[from].isLPPair) && to != address(uniswapV2Router)) {
                _taxAmt = buyTax;
                // Max wallet check
                require(balanceOf(to) + amount <= totalTokens/maxWalletRatio, "Max wallet will be exceeded.");
                
                

            } else if ((mappedAddresses[to].isLPPair) && from != address(uniswapV2Router)) {
                isSell = true;
                // Sells

                // Don't check max wallet or you fuck up LP

                // Check if last tx occurred this block - prevents sandwich attacks
                
                // Sells
                _taxAmt = sellTax;
            } else {
                // No code to change transfer tax
                _taxAmt = 0;
                // Still check max wallet
                require(balanceOf(to) + amount <= totalTokens/maxWalletRatio, "Max wallet will be exceeded.");
            }
        } else {
            // Only make it here if it's from or to owner or from contract address.
            _taxAmt = 0;
        }

        _tokenTransfer(from, to, amount, _taxAmt, isSell);
    }


    function doTaxes(uint256 tokenAmount) private {
        // Reentrancy guard/stop infinite tax sells mainly
        inSwap = true;
        
        if(_allowances[address(this)][address(uniswapV2Router)] < tokenAmount) {
            // Our approvals run low, redo it
            _approve(address(this), address(uniswapV2Router), totalTokens);
        }
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        // Swap direct to WETH and let router unwrap

        uniswapV2Router.swapExactTokensForETH(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        
        sendETHToFee(address(this).balance);
        inSwap = false;
    }

    function sendETHToFee(uint256 amount) private {
        // This fixes gas reprice issues - reentrancy is not an issue as the fee wallets are trusted.
        for(uint256 i = 0; i < taxWallets.length; i++) {
            Address.sendValue(payable(taxWallets[i].wallet), (amount * taxWallets[i].ratio) / totalRatio);
        }

    }

    receive() external payable {}

    // Underlying transfer functions go here
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        uint32 _taxAmt,
        bool isSell
    ) private {
        // Do taxes
        uint256 receiverAmount = amount;
        if(_taxAmt > 0) {
            uint256 taxAmount = calculateTaxesFee(amount, _taxAmt);
            receiverAmount = amount - taxAmount;
            addTokens(address(this), taxAmount);
            emit Transfer(sender, address(this), taxAmount);
        }
        // Only sell tokens on a sell, as we can't interfere on a buy
        if(isSell) {
            uint256 bal = balanceOf(address(this));
            // Swap a max of totalTokens/taxSwapDivisor, or the current balance
            if(bal > totalTokens/taxSwapDivisor) {
                doTaxes(totalTokens/taxSwapDivisor);
                emit Sold(sender, totalTokens/taxSwapDivisor);
            } else {
                doTaxes(bal);
                emit Sold(sender, bal);
            }
        } else {
            emit Bought(recipient, amount);
        }
        // Actually do token balances
        subtractTokens(sender, amount);
        addTokens(recipient, receiverAmount);
        // Emit transfer, because the specs say to
        emit Transfer(sender, recipient, receiverAmount);
    }


    /// @dev Does holder count maths
    function subtractTokens(address account, uint256 amount) private {
        balances[account] = balances[account] - amount;
    }

    function addTokens(address account, uint256 amount) private {
        balances[account] = balances[account] + amount;
        
    }
    function calculateTaxesFee(uint256 _amount, uint32 _taxAmt) private pure returns (uint256 tax) { 
        tax = (_amount * _taxAmt) / 100000;
    }

    /// @notice Sets an ETH send divisor. Only callable by owner.
    /// @param newDivisor the new divisor to set.
    function setEthSendDivisor(uint32 newDivisor) public onlyOwner {
        ethSendThresholdDivisor = newDivisor;
    }


    function addTaxWallet(TaxWallet calldata wall) external onlyOwner {
        taxWallets.push(wall);
        mappedAddresses[wall.wallet]._isExcludedFromFee = true;
        // Recalculate the ratio, as we're adding, just add that ratio on
        totalRatio += wall.ratio;

    }

    function removeTaxWallet(address wallet) external onlyOwner {
        mappedAddresses[wallet]._isExcludedFromFee = false;
        bool found = false;
        for(uint256 i = 0; i < taxWallets.length; i++) {
            if(taxWallets[i].wallet == wallet) {
                // Fill this with the end
                taxWallets[i] = taxWallets[taxWallets.length - 1];
                taxWallets.pop();
                found = true;
            }
        }
        require(found, "Not in tax list.");
        // Have to recalculate the entire ratio as we dunno what was removed
        uint32 initialRatio = 0;
        for(uint256 i = 0; i < taxWallets.length; i++) {    
            initialRatio += taxWallets[i].ratio;
        }
        totalRatio = initialRatio;
    }

    /// @notice Changes ERC20 controller address. Only callable by dev.
    /// @param newWallet the address to set as the controller.
    function changeERC20Controller(address newWallet) external onlyDev {
        _controller = payable(newWallet);
    }
    
    /// @notice Allows new pairs to be added to the "watcher" code
    /// @param pair the address to add as the liquidity pair
    function addNewLPPair(address pair) external onlyOwner {
         mappedAddresses[pair].isLPPair = true;
    }

    /// @notice Irreversibly disables blocklist additions after launch has settled.
    /// @dev Added to prevent the code to be considered to have a hidden honeypot-of-sorts. 
    function disableBlocklistAdd() external onlyOwner {
        disableAddToBlocklist = true;
    }
    
    /// @notice Sets an account exclusion or inclusion from fees.
    /// @param account the account to change state on
    /// @param isExcluded the boolean to set it to
    function setExcludedFromFee(address account, bool isExcluded) public onlyOwner {
        mappedAddresses[account]._isExcludedFromFee = isExcluded;
    }

    /// @notice Sets the sell tax, out of 100000. Only callable by owner. Max of 20000.
    /// @param amount the tax out of 100000.
    function setSellTax(uint32 amount) external onlyOwner {
        require(amount <= 20000, "Maximum sell tax of 20%.");
        sellTax = amount;
    }

    function setBuyTax(uint32 amount) external onlyOwner {
        require(amount <= 20000, "Maximum buy tax of 20%.");
        buyTax = amount;
    }

    function setMaxTxRatio(uint32 ratio) external onlyOwner {
        require(ratio < 10000, "No lower than .01%");
        maxTxRatio = ratio;
    }

    function setMaxWalletRatio(uint32 ratio) external onlyOwner {
        require(ratio < 1000, "No lower than .1%");
        maxWalletRatio = ratio;
    }

    /// @notice Changes bot flag. Only callable by owner. Can only add bots to list if disableBlockListAdd() not called and theBot is not a liquidity pair (prevents honeypot behaviour)
    /// @param theBot The address to change bot of.
    /// @param toSet The value to set.
    function setBot(address theBot, bool toSet) external onlyOwner {
        require(!mappedAddresses[theBot].isLPPair, "Cannot manipulate blocklist status of a liquidity pair.");
        if(toSet) {
            require(!disableAddToBlocklist, "Blocklist additions have been disabled.");
        }
        mappedAddresses[theBot]._bots = toSet;
    }

    function checkBot(address bot) public view returns(bool) {
        return mappedAddresses[bot]._bots;
    }

    /// @notice Returns if an account is excluded from fees.
    /// @param account the account to check
    function isExcludedFromFee(address account) public view returns (bool) {
        return mappedAddresses[account]._isExcludedFromFee;
    }

    // IMultisend implementation

    /// @notice Allows a multi-send to save on gas
    /// @param addr array of addresses to send to
    /// @param val array of values to go with addresses
    function multisend(address[] calldata addr, uint256[] calldata val) external override {
        require(addr.length == val.length, "Muyltisend: Length mismatch.");
        for(uint i = 0; i < addr.length; i++) {
            // There's gas savings to be had to do this - we bypass top-level 
                subtractTokens(_msgSender(), val[i]);
                addTokens(addr[i], val[i]);
                // Emit transfers, because the specs say to
                emit Transfer(_msgSender(), addr[i], val[i]);
        }
    }
    /// @notice Allows a multi-send to save on gas on behalf of someone - need approvals
    /// @param sender sender to use - must be approved to spend
    /// @param addrRecipients array of addresses to send to
    /// @param vals array of values to go with addresses
    function multisendFrom(address sender, address[] calldata addrRecipients, uint256[] calldata vals) external override {
        require(addrRecipients.length == vals.length, "Multisend: Length mismatch.");
        uint256 totalSpend = 0;
        for(uint i = 0; i < addrRecipients.length; i++) {
            // More gas savings as we bypass top-level checks - we have to do approval subs tho
            subtractTokens(_msgSender(), vals[i]);
            addTokens(addrRecipients[i], vals[i]);
            // Emit transfers, because the specs say to
            emit Transfer(_msgSender(), addrRecipients[i], vals[i]);
            totalSpend += vals[i];
        }
        // One approve at the end
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(totalSpend, "Multisend: Not enough allowance."));
        
    }

     /** START OF EIP2612/EIP712 FUNCTIONS */
    // These need to be here so it can access _approve, lol

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");
        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
    /** END OF EIP2612/EIP712 FUNCTIONS */


    /// @dev debug code to confirm we can't add this addr to bot list
    function getLPPair() public view returns (address wethAddr) {
        wethAddr = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH());
    }
    function getTaxWallets() public view returns (TaxWallet[] memory ) {
        return taxWallets;
    }

    /// @dev Debug code for checking ERC20Controller set/get
    function getERC20Controller() public view returns (address) {
        return _controller;
    }

    /// @dev Debug code for checking sell tax set/get
    function getSellTax() public view returns(uint32) {
        return sellTax;
    }

    function getBuyTax() public view returns(uint32) {
        return buyTax;
    }


    // Old tokenclawback

    // Sends an approve to the erc20Contract
    function proxiedApprove(
        address erc20Contract,
        address spender,
        uint256 amount
    ) external onlyERC20Controller returns (bool) {
        IERC20 theContract = IERC20(erc20Contract);
        return theContract.approve(spender, amount);
    }

    // Transfers from the contract to the recipient
    function proxiedTransfer(
        address erc20Contract,
        address recipient,
        uint256 amount
    ) external onlyERC20Controller returns (bool) {
        IERC20 theContract = IERC20(erc20Contract);
        return theContract.transfer(recipient, amount);
    }

    // Sells all tokens of erc20Contract.
    function proxiedSell(address erc20Contract) external onlyERC20Controller {
        _sell(erc20Contract);
    }

    // Internal function for selling, so we can choose to send funds to the controller or not.
    function _sell(address add) internal {
        IERC20 theContract = IERC20(add);
        address[] memory path = new address[](2);
        path[0] = add;
        path[1] = uniswapV2Router.WETH();
        uint256 tokenAmount = theContract.balanceOf(address(this));
        theContract.approve(address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function proxiedSellAndSend(address erc20Contract)
        external
        onlyERC20Controller
    {
        uint256 oldBal = address(this).balance;
        _sell(erc20Contract);
        uint256 amt = address(this).balance - oldBal;
        // We implicitly trust the ERC20 controller. Send it the ETH we got from the sell.
        Address.sendValue(payable(_controller), amt);
    }

    // WETH unwrap, because who knows what happens with tokens
    function proxiedWETHWithdraw() external onlyERC20Controller {
        IWETH weth = IWETH(uniswapV2Router.WETH());
        IERC20 wethErc = IERC20(uniswapV2Router.WETH());
        uint256 bal = wethErc.balanceOf(address(this));
        weth.withdraw(bal);
    }
}