// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";

import "./DogNFT.sol";

contract AwooFinance is Context, IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply = 1000000000 * 10**18;

    string private _name = "AWOO Finance";
    string private _symbol = "AWOO";

    mapping(address => bool) private _isExcludedFromFee;

    uint256 private _totalFee;

    uint256 private _taxFee = 1;
    uint256 private _charityFee = 1;
    uint256 private _opFee = 1;
    uint256 private _previousTaxFee = _taxFee;
    uint256 private _previousCharityFee = _charityFee;
    uint256 private _previousOpFee = _opFee;

    address payable public _charityWalletAddress;
    address payable public _opWalletAddress;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    DogNFT _dogNFT;

    bool inSwap = false;
    bool public swapEnabled = true;

    uint256 totalHolders;
    uint256 private _maxTxAmount = 1000000000e18;
    // Set a minimum amount of tokens to be swapped to avoid waste => 50000
    uint256 private _numOfTokensToExchangeForCharity = 5 * 10**4 * 10**18;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapEnabledUpdated(bool enabled);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(
        address payable charityWalletAddress,
        address payable opWalletAddress,
        DogNFT _dogNFTAddr
    ) {
        _charityWalletAddress = charityWalletAddress;
        _opWalletAddress = opWalletAddress;

        _balances[_msgSender()] = _totalSupply;
        totalHolders = 1;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        ); // UniswapV2 for Ethereum network
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        // Exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _dogNFT = _dogNFTAddr;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function calculatedSupply() public view returns (uint256) {
        uint256 nonHolderSupply = _totalSupply
        .sub(_totalFee)
        .sub(_balances[address(this)])
        .sub(_balances[uniswapV2Pair]);

        uint256 cSupply;

        for (uint256 i = 0; i < _dogNFT.totalBoosters(); i = i.add(1)) {
            address booster = _dogNFT.boosters(i);

            nonHolderSupply = nonHolderSupply.sub(_balances[booster]);
            cSupply = cSupply.add(
                (100 + _dogNFT.boostFee(booster)).mul(_balances[booster]).div(
                    100
                )
            );
        }

        cSupply = cSupply.add(
            nonHolderSupply
            .mul(
                100 -
                    _dogNFT.totalBoosts().mul(10**6).div(totalHolders).div(
                        10**6
                    )
            ).div(100)
        );

        return cSupply;
    }

    function feeOf(address account, uint256 userBalance)
        private
        view
        returns (uint256)
    {
        uint256 cSupply = calculatedSupply();
        uint256 distFee;

        if (_dogNFT.getRedistFeeOf(account) > 0)
            distFee = 10**8 + _dogNFT.getRedistFeeOf(account).mul(10**6);
        else
            distFee =
                10**8 -
                _dogNFT.totalBoosts().mul(10**6).div(totalHolders);

        return
            userBalance
                .mul(distFee)
                .div(10**8)
                .mul(10**6)
                .mul(_totalFee)
                .div(cSupply)
                .div(10**6);
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (account == address(this) || account == uniswapV2Pair)
            return _balances[account];
        uint256 userBalance = _balances[account];
        uint256 feeOfUser = feeOf(account, userBalance);

        return _balances[account].add(feeOfUser);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);

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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _getTValues(
        uint256 tAmount,
        uint256 taxFee,
        uint256 charityFee,
        uint256 opFee
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 _tAmount = tAmount;
        uint256 tFee = _tAmount.mul(taxFee).div(100);
        uint256 tCharity = _tAmount.mul(charityFee).div(100);
        uint256 tOp = _tAmount.mul(opFee).div(100);
        uint256 tTransferAmount = _tAmount.sub(tFee).sub(tCharity).sub(tOp);
        return (tTransferAmount, tFee, tCharity, tOp);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function sendETHToCharity(uint256 amount) private {
        _charityWalletAddress.transfer(amount);
    }

    function sendETHToOp(uint256 amount) private {
        _opWalletAddress.transfer(amount);
    }

    // We are exposing these functions to be able to manual swap and send
    // in case the token is highly valued and 5M becomes too much
    function manualSwap() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualSend() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;

        if (contractETHBalance > 0) {
            uint256 totalFee = _charityFee + _opFee;
            sendETHToCharity(contractETHBalance.mul(_charityFee).div(totalFee));
            sendETHToOp(contractETHBalance.mul(_opFee).div(totalFee));
        }
    }

    function setSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _charityFee == 0 && _opFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousCharityFee = _charityFee;
        _previousOpFee = _opFee;

        _taxFee = 0;
        _charityFee = 0;
        _opFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _charityFee = _previousCharityFee;
        _opFee = _previousOpFee;
    }

    function setExcludeFromFee(address account, bool excluded)
        external
        onlyOwner
    {
        _isExcludedFromFee[account] = excluded;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

        uint256 rSenderBalance = balanceOf(sender);
        uint256 senderBalance = _balances[sender];

        require(
            rSenderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        if (amount > senderBalance) {
            uint256 remain = amount.sub(senderBalance);
            _balances[sender] = 0;
            _totalFee = _totalFee.sub(remain);
        } else {
            _balances[sender] = _balances[sender].sub(amount);
        }

        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tCharity,
            uint256 tOp
        ) = _getTValues(amount, _taxFee, _charityFee, _opFee);

        if (_balances[sender] == 0) totalHolders = totalHolders.sub(1);
        if (tTransferAmount > 0 && _balances[recipient] == 0)
            totalHolders = totalHolders.add(1);

        _balances[recipient] += tTransferAmount;
        _balances[address(this)] = _balances[address(this)].add(tCharity).add(
            tOp
        );
        _totalFee = _totalFee.add(tFee);

        emit Transfer(sender, recipient, tTransferAmount);
        emit Transfer(sender, address(this), tCharity.add(tOp));

        if (!takeFee) restoreAllFee();
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to te zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        _beforeTokenTransfer(sender, recipient, amount);

        if (sender != owner() && recipient != owner())
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap?
        // also, don't get caught in a circular charity event.
        // also, don't swap if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >=
            _numOfTokensToExchangeForCharity;
        if (
            !inSwap &&
            swapEnabled &&
            overMinTokenBalance &&
            sender != uniswapV2Pair
        ) {
            // We need to swap the current tokens to ETH and send to the charity wallet
            swapTokensForEth(contractTokenBalance);

            uint256 contractETHBalance = address(this).balance;

            if (contractETHBalance > 0) {
                uint256 totalFee = _charityFee + _opFee;
                sendETHToCharity(
                    contractETHBalance.mul(_charityFee).div(totalFee)
                );
                sendETHToOp(contractETHBalance.mul(_opFee).div(totalFee));
            }
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (
            _isExcludedFromFee[sender] ||
            _isExcludedFromFee[recipient] ||
            recipient == uniswapV2Pair
        ) {
            takeFee = false;
        }

        //transfer amount, it will take tax and charity fee
        _tokenTransfer(sender, recipient, amount, takeFee);
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

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
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _getTaxFee() public view returns (uint256) {
        return _taxFee;
    }

    function _getCharityFee() public view returns (uint256) {
        return _charityFee;
    }

    function _getOpFee() public view returns (uint256) {
        return _opFee;
    }

    function _getMaxTxAmount() private view returns (uint256) {
        return _maxTxAmount;
    }

    function _getETHBalance() public view returns (uint256 balance) {
        return address(this).balance;
    }

    function _setTaxFee(uint256 taxFee) external onlyOwner {
        require(taxFee >= 1 && taxFee <= 5, "taxFee should be in 1 - 5");
        _taxFee = taxFee;
    }

    function _setCharityFee(uint256 charityFee) external onlyOwner {
        require(
            charityFee >= 1 && charityFee <= 5,
            "charityFee should be in 1 - 5"
        );
        _charityFee = charityFee;
    }

    function _setOpFee(uint256 opFee) external onlyOwner {
        require(opFee >= 1 && opFee <= 3, "opFee should be in 1 - 3");
        _opFee = opFee;
    }

    function _setCharityWallet(address payable charityWalletAddress)
        external
        onlyOwner
    {
        _charityWalletAddress = charityWalletAddress;
    }

    function _setOpWallet(address payable opWalletAddress) external onlyOwner {
        _opWalletAddress = opWalletAddress;
    }

    function _setMaxTxAmount(uint256 maxTxAmount) external onlyOwner {
        require(
            maxTxAmount >= 1000000000e18,
            "maxTxAmount should be greater than 1000000000e18"
        );
        _maxTxAmount = maxTxAmount;
    }
}