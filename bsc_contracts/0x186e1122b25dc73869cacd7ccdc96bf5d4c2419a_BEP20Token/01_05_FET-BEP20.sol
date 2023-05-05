// SPDX-License-Identifier: MIT
pragma solidity >0.4.0 <=0.9.0;

import "./IBEP20.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract BEP20Token is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;

    // Customized
    mapping(address => bool) public swapPairList;

    address public rewardAddress; //Rewards distribution address
    address public adsAddress;   // Advertisment & marketing fee management address

    uint256 public buyFeeRate;
    uint256 public sellFeeRate;
    uint256 public buyBurnFeeRate;
    uint256 public sellBurnFeeRate;
    uint256 public buyAdsRate;
    uint256 public sellAdsRate;
    uint256 public RATE_DECIMAL = 10000;

    uint256 public baseSupply; // Bottom-line to stop burning.
    uint256 public batchTransferLimit = 1000;

    mapping(address => bool) public feeWhiteList; // rewardAddress, adsAddress, address(this), address(router), owner
    mapping(address => bool) public blackList;

    constructor(
        string memory Name,
        string memory Symbol,
        uint8 Decimals,
        uint256 Supply,
        uint256 BaseSupply,
        address RewardAddress,
        address AdsAddress,
        uint256[] memory Rates // BuyFeeRate, SellFeeRate, BuyBurnFeeRate, SellBurnFeeRate, BuyAdsRate, SellAdsRate
    ) {
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;
        _totalSupply = Supply * 10**Decimals;

        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);

        // Customized
        // set up addresses
        rewardAddress = RewardAddress;
        adsAddress = AdsAddress;

        // setup fee rate
        buyFeeRate = Rates[0];
        sellFeeRate = Rates[1];
        buyBurnFeeRate = Rates[2];
        sellBurnFeeRate = Rates[3];
        buyAdsRate = Rates[4];
        sellAdsRate = Rates[5];

        baseSupply = BaseSupply * 10**Decimals;

        // setup whitelist
        feeWhiteList[rewardAddress] = true;
        feeWhiteList[address(this)] = true;
        feeWhiteList[msg.sender] = true;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
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
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
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
    ) internal {
        require(!blackList[sender], "tx from blackList");

        uint256 balance = balanceOf(sender);
        require(balance >= amount, "BEP20: transfer amount exceeds balance");

        _balances[sender] = _balances[sender].sub(
            amount,
            "BEP20: transfer amount exceeds balance"
        );

        // if it is tx related to pancakeswap
        if (swapPairList[sender] || swapPairList[recipient]) {
            if (!feeWhiteList[sender] && !feeWhiteList[recipient]) {
                uint256 totalFee = 0;

                if (swapPairList[sender]) {
                    // buy == removeLp: transfer token from pair to user
                    totalFee = _takeFee(sender, amount, false);
                } else {
                    // sell == addLp: transfer token from user to pair
                    totalFee = _takeFee(sender, amount, true);
                }

                amount = amount.sub(totalFee);
            }
        }

        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(
            amount,
            "BEP20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
    ) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(
                amount,
                "BEP20: burn amount exceeds allowance"
            )
        );
    }

    // Customized
    receive() external payable {}

    function _takeFee(
        address sender,
        uint256 tAmount,
        bool isSell
    ) internal returns (uint256) {
        uint256 feeRate = isSell ? sellFeeRate : buyFeeRate;
        uint256 burnRate = isSell ? sellBurnFeeRate : buyBurnFeeRate;
        uint256 adsRate = isSell ? sellAdsRate : buyAdsRate;

        // total fee
        uint256 totalFee = tAmount.mul(feeRate).div(RATE_DECIMAL);
        if (totalFee == 0) {
            return 0;
        }

        // burn amount
        uint256 burnAmount = 0;
        if (burnRate > 0 && _totalSupply > baseSupply) {
            burnAmount = tAmount.mul(burnRate).div(RATE_DECIMAL);
            require(burnAmount <= tAmount, "invalid burn amount");

            uint256 maxBurn = _totalSupply.sub(baseSupply);
            burnAmount = burnAmount < maxBurn ? burnAmount : maxBurn;

            _totalSupply = _totalSupply.sub(burnAmount);
            _balances[address(0x0)] = _balances[address(0x0)].add(burnAmount);
            emit Transfer(sender, address(0), burnAmount);
        }

        // ads amount
        uint256 adsAmount = 0;
        if (adsRate > 0) {
            adsAmount = tAmount.mul(adsRate).div(RATE_DECIMAL);
            require(adsAmount <= tAmount, "invalid ads amount");

            _balances[adsAddress] = _balances[adsAddress].add(adsAmount);
            emit Transfer(sender, adsAddress, adsAmount);
        }

        // reward amount
        require(totalFee >= burnAmount.add(adsAmount), "invalid reward amount");
        uint256 rewardAmount = totalFee.sub(burnAmount).sub(adsAmount);
        _balances[rewardAddress] = _balances[rewardAddress].add(rewardAmount);
        emit Transfer(sender, rewardAddress, rewardAmount);       

        return totalFee;
    }

    function setBuyFeeRate(uint256 rate) external onlyOwner {
        require(rate <= RATE_DECIMAL, "invalid fee rate");
        buyFeeRate = rate;
    }

    function setSellFeeRate(uint256 rate) external onlyOwner {
        require(rate <= RATE_DECIMAL, "invalid fee rate");
        sellFeeRate = rate;
    }

    function setBuyBurnFeeRate(uint256 rate) external onlyOwner {
        require(rate <= RATE_DECIMAL, "invalid fee rate");
        buyBurnFeeRate = rate;
    }

    function setSellBurnFeeRate(uint256 rate) external onlyOwner {
        require(rate <= RATE_DECIMAL, "invalid fee rate");
        sellBurnFeeRate = rate;
    }

    function setBuyAdsRate(uint256 rate) external onlyOwner {
        require(rate <= RATE_DECIMAL, "invalid fee rate");
        buyAdsRate = rate;
    }

    function setSellAdsRate(uint256 rate) external onlyOwner {
        require(rate <= RATE_DECIMAL, "invalid fee rate");
        sellAdsRate = rate;
    }

    function setBaseSupply(uint256 limit) external onlyOwner {
        baseSupply = limit * 10**_decimals;
    }

    function setRewardAddress(address addr) external onlyOwner {
        rewardAddress = addr;
        feeWhiteList[addr] = true;
    }

    function setAdsAddress(address addr) external onlyOwner {
        adsAddress = addr;
        feeWhiteList[addr] = true;
    }

    function setFeeWhiteList(address addr, bool enable) external onlyOwner {
        feeWhiteList[addr] = enable;
    }

    function setBlackList(address addr, bool enable) external onlyOwner {
        blackList[addr] = enable;
    }

    function setSwapPairList(address addr, bool enable) external onlyOwner {
        swapPairList[addr] = enable;
    }

    function setBatchTransferLimit(uint256 limit) external onlyOwner {
        batchTransferLimit = limit;
    }

    function claimToken(
        address token,
        uint256 amount,
        address to
    ) external onlyOwner {
        IBEP20(token).transfer(to, amount);
    }

    function batchTransfer(
        address[] memory recipients,
        uint256[] memory amounts
    ) external returns (bool) {
        require(recipients.length == amounts.length, "Array length mismatch");
        require(
            recipients.length <= batchTransferLimit,
            "Array length too long"
        );
        for (uint256 i = 0; i < recipients.length; i++) {
            require(transfer(recipients[i], amounts[i]), "Transfer failed");
        }
        return true;
    }
}

// Metaforce's Force Engorgement Token
contract FETToken is BEP20Token {
    constructor(
        string memory Name,
        string memory Symbol,
        uint8 Decimals,
        uint256 Supply,
        uint256 BaseSupply,
        address RewardAddress,
        address AdsAddress,        
        uint256[] memory Rates // BuyFeeRate, SellFeeRate, BuyBurnFeeRate, SellBurnFeeRate, BuyAdsRate, SellAdsRate
    )
        BEP20Token(
            Name,
            Symbol,
            Decimals,
            Supply,
            BaseSupply,
            RewardAddress,
            AdsAddress,
            Rates
        )
    {}
}