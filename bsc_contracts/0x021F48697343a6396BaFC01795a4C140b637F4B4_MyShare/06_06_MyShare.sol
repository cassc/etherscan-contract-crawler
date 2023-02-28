// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


interface IMyInkMinter {
    function fundByMyShare(uint256 amount) external;
}

/**
 * @title The magical MyShare token contract.
 * @author int(200/0), slidingpanda
 */
contract MyShare is Context, Ownable, IERC20Metadata, ReentrancyGuard {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public liqPool;
    mapping(address => uint256) public lastTransaction;
    
    uint256 private _totalSupply;
    uint256 public totalBurned;
    uint256 public notRealisedMints;

    address public daoWallet;
    address public oldToken;

    string private _name;
    string private _symbol;

    uint256 private txnFee = 10;
    uint256 private stakeFee = 5;
    uint256 public constant FEE_DIVISOR = 1000;

    struct Minter {
        uint256 lastEmission;
        uint256 maxMintable;
        uint256 alreadyMinted;
        bool isMinter;
        bool isActive;
    }

    mapping(address => Minter) private _minter;
    mapping(address => bool) public isFactory;
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public isBlacklisted;

    uint256 public activeMinterCount;
    uint256 public notActiveMinterCount;

    uint256 public startTime;
    uint256 public constant START_EMISSION = 1e24; // 1mio * 10**18
    uint256 public YEAR_PERIOD = 31557600;
    uint256 public emissionPerSecondPerMinter;
    uint256 public lastEmissionCalculation;

    address public myExLiqPool;

    uint8 public lastEpoch = 1;

    address public _myInkMinterAddr;

    event SetMyInkMinter(address oldMinterAddress, address newMinterAddress);
    event SetTxnFee(uint oldTxnFee, uint newTxnFee);
    event SetStakeFee(uint oldStakeFee, uint newStakeFee);
    event SetLiqPool(address liqPoolAddress, bool state);
    event SetIsBlacklisted(address userAddress, bool state);
    event SetIsWhitelisted(address userAddress, bool state);
    event ChangeDaoWallet(address daoWallet);
    event SetMyExLP(address lpAddress);
    event SetFactory(address factoryAddress, bool state);
    event AddMinter(address minter);
    event SetMinterActivity(address minter, bool state);
    event RemoveMinter(address minter);
    

    /**
     * Creates the myShare token and activates the first "staking pool" the minter for the dao.
     * The emission is fixed.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address mintTo,
        address daoWallet_
    ) public {
        _name = name_;
        _symbol = symbol_;
        startTime = block.timestamp;
        lastEmissionCalculation = startTime;
        _mint(mintTo, 2 * START_EMISSION, 0);
        isWhitelisted[mintTo] = true;
        daoWallet = daoWallet_;
        _minter[daoWallet_].isMinter = true;
        _minter[daoWallet_].isActive = true;
        _minter[daoWallet_].maxMintable = 0;
        _minter[daoWallet_].alreadyMinted = 0;
        _minter[daoWallet_].lastEmission = 1;
        activeMinterCount += 1;
    }

    /**
     * Sets MyInkMinter.
	 *
     * @param myInkMinterAddr Address of MyInkMinter
     */
    function setMyInkMinter(address myInkMinterAddr) external {
        require(msg.sender == daoWallet || msg.sender == owner(), "You are not allowed to change the lp state");

        address oldAddr = _myInkMinterAddr;

        _myInkMinterAddr = myInkMinterAddr;

        emit SetMyInkMinter(oldAddr, _myInkMinterAddr);
    }

    /**
     * Changes the transaction fee.
     * The divisor of the fee calculation is 1000, so 1000 is the maximum and means 100%.
	 *
     * @param fee multiplier of the fee
     */
    function setTxnFee(uint256 fee) external onlyOwner {
        require(fee + stakeFee <= FEE_DIVISOR, "Max fee == 1000 -> 100%");

        uint oldFee = txnFee;

        txnFee = fee;

        emit SetTxnFee(oldFee, txnFee);
    }

    /**
     * Changes the stake fee.
     * The divisor of the fee calculation is 1000, so 1000 is the maximum and means 100%.
	 *
     * @param fee multiplier of the fee
     */
    function setStakeFee(uint256 fee) external onlyOwner {
        require(fee + txnFee <= FEE_DIVISOR, "Max fee == 1000 -> 100%");

        uint oldFee = stakeFee;

        stakeFee = fee;

        emit SetStakeFee(oldFee, stakeFee);
    }

    /**
     * Sets liquidity pool state.
	 *
     * @param liqPoolAddr address of the lp token
     * @param state lp state
     */
    function setLiqPool(address liqPoolAddr, bool state) external {
        require(msg.sender == daoWallet || msg.sender == owner(), "You are not allowed to change the lp state");

        liqPool[liqPoolAddr] = state;

        emit SetLiqPool(liqPoolAddr, state);
    }

    /**
     * Changes isBlacklisted (true = not possible to receive tokens, false = possible to receive tokens).
	 *
     * @param user address of the user
     * @param state blacklisted state
     */
    function setIsBlacklisted(address user, bool state) external {
        require(msg.sender == daoWallet || msg.sender == owner(), "You are not allowed to change the blacklist");

        isBlacklisted[user] = state;

        emit SetIsBlacklisted(user, state);
    }

    /**
     * Changes isWhitelisted (true = no fees, false = fees).
	 *
     * @param user address of the user
     * @param state whitelisted state
     */
    function setIsWhitelisted(address user, bool state) external {
        require(msg.sender == daoWallet || msg.sender == owner(), "You are not allowed to change the whitelist");

        isWhitelisted[user] = state;

        emit SetIsWhitelisted(user, state);
    }

    /**
     * Changes the dao wallet which is allowed to mint depending on the amount of the activated minter and the actual emission.
     * If you want to stop that emission, you can do it by passing the zero address as an owner here or as the contract which is the last dao wallet.
	 *
     * @param newDAOWallet address of the new dao wallet
     */
    function changeDaoWallet(address newDAOWallet) external onlyOwner {
        updateEmission();

        _minter[daoWallet].isMinter = false;
        _minter[daoWallet].isActive = false;
        _minter[daoWallet].lastEmission = emissionPerSecondPerMinter;

        daoWallet = newDAOWallet;

        if (newDAOWallet != address(0)) {
            _minter[daoWallet].isMinter = true;
            _minter[daoWallet].isActive = true;
            _minter[daoWallet].lastEmission = emissionPerSecondPerMinter;

            emit ChangeDaoWallet(daoWallet);
        }
    }

    /**
     * The liquidity pool of myExchange tokens has a special fee and it is only settable once.
     * @param inAddr address of lp tokens
     */
    function setMyExLP(address inAddr) external onlyOwner {
        require(myExLiqPool == address(0), "Already set");

        myExLiqPool = inAddr;
        liqPool[inAddr] = true;

        emit SetMyExLP(inAddr);
    }

    /**
     * Sets a staking factory.
	 *
     * @notice - A factory is capable to add new minters (staking contracts)
     *         - A factory can also be deactivated with this function
	 *
     * @param factoryAddr address of the factory
     * @param state true -> is a factory / false -> is not a factory
     */
    function setFactory(address factoryAddr, bool state) external onlyOwner {
        isFactory[factoryAddr] = state;

        emit SetFactory(factoryAddr, state);
    }

    /**
     * Adds a minter.
	 *
     * @notice - A minter can mint a fragment of the defined emission, so no "overminting" is possible
     *         - A factory or the owner (DAO) can add a minter
     *         - A minter is not activated by default, so it cannot mint by default. -> The minter or the owner has to activate itself
     *         - This is designed so that there is no minting without any stakes
	 *
     * @param minter_ address of the new minter
     */
    function addMinter(address minter_) external {
        require(isFactory[msg.sender] == true || msg.sender == owner(), "Only an authorized factory or owner can add a minter");
        require(_minter[minter_].isMinter == false, "Minter is already set");

        updateEmission();

        _minter[minter_].isMinter = true;
        _minter[minter_].maxMintable = 0;
        _minter[minter_].alreadyMinted = 0;
        _minter[minter_].lastEmission = emissionPerSecondPerMinter;

        notActiveMinterCount += 1;

        emit AddMinter(minter_);
    }

    /**
     * Activates/Deactivates a minter.
	 *
     * @notice - Only the minter or the owner can activate the minter
     *         - If a minter is not active there is no emission from it which happens if the minter/staking contract has no stakers which calls this function
	 *
     * @param activate true -> active / false -> inactive
     */
    function setMinterActivity(address toSetMinter, bool activate) external {
        require(_minter[msg.sender].isMinter == true || msg.sender == owner(), "Only an authorized minter or owner can add a minter");

        if (msg.sender != owner()) {
            toSetMinter = msg.sender;
        }
        
        require(_minter[toSetMinter].isMinter == true, "The address which should be activated is not a minter");

        updateEmission();
        updateMinter(toSetMinter);

        if (activate != _minter[toSetMinter].isActive) {
            _minter[toSetMinter].isActive = activate;

            if (activate) {
                activeMinterCount += 1;
                notActiveMinterCount -= 1;
            } else {
                activeMinterCount -= 1;
                notActiveMinterCount += 1;
            }
        }

        emit SetMinterActivity(toSetMinter, activate);
    }

    /**
     * Removes a minter if the address is a minter.
	 *
     * @notice - Checks if the minter is active
     *         - If a minter is removed, it is losing the possibility to mint and every unminted emission
     *         - If it should not lose unminted emission (old staking pool which has stakers), deactivate the minter and remove it after all stakers left
	 *
     * @param minter_ address of the minter
     */
    function removeMinter(address minter_) external {
        require(isFactory[msg.sender] == true || msg.sender == owner(), "Only an authorized factory or owner can remove a minter");
        require(_minter[minter_].isMinter == true, "The given address is not a minter.");

        updateEmission();
        updateMinter(minter_);

        
        _minter[minter_].isMinter = false;
        if (_minter[minter_].isActive) {
            activeMinterCount -= 1;
            _minter[minter_].isActive = false;
        } else {
            notActiveMinterCount -= 1;
        }

        emit RemoveMinter(minter_);
        
    }

    /**
     * Returns the minter state of an address.
	 *
     * @param toCheck address which is checked
     * @return returnState true -> is a minter / false -> is not a minter
     */
    function isMinter(address toCheck) public view returns (bool returnState) {
        returnState = _minter[toCheck].isMinter;
    }

    /**
     * Returns the minter activity state.
	 *
     * @param toCheck address which is checked
     * @return returnState true -> is active / false -> is not active
     */
    function isActiveMinter(address toCheck) public view returns (bool returnState) {
        returnState = _minter[toCheck].isActive;
    }

    /**
     * Returns the last global emission of a minter which was calculated.
	 *
     * @param toCheck address which is checked
     * @return returnAmount last calculated emission of a minter
     */
    function lastEmissionOfMinter(address toCheck) public view returns (uint256 returnAmount) {
        returnAmount = _minter[toCheck].lastEmission;
    }

    /**
     * Returns the last global emission of a minter per second.
	 *
     * @notice Every minter fragments the emission.
     *         - X = minter
     *         - EPS = Emission per year divided by seconds per year
     *         - returns EPS / X
	 *
     * @return returnAmount actual emission per sencond and minter
     */
    function emissionPerMinterPerSecond() public view returns (uint256 returnAmount) {
        if (activeMinterCount == 0) {
            returnAmount = 0;
        } else {
            uint256 emissionPerSecond = actualEmissionPerSecond();
            returnAmount = emissionPerSecond / activeMinterCount;
        }
    }

    /**
     * Returns the end time of a given epoch.
	 *
     * @notice - Epochs <1 have no endTime (zero)
     *         - After Epoch 4 (>4) the epoch lasts forever (2**256)
	 *
     * @param epoch epoch which is checked
     * @return endTime last second of the epoch (timestamp)
     */
    function endOfEpoch(uint8 epoch) public view returns (uint256 endTime) {
        if (epoch < 1) {
            endTime = 0;
        } else if (epoch > 5) {
            endTime = type(uint256).max;
        } else {
            endTime = startTime + YEAR_PERIOD * epoch;
        }
    }

    /**
     * Checks which epoch is the actual epoch right now.
	 *
     * @notice There are only epochs 1-5 (>= 5 are endless)
	 *
     * @return aEpoch actual epoch
     */
    function actualEpoch() public view returns (uint8 aEpoch) {
        uint256 epoch = block.timestamp - startTime;

        if (epoch / YEAR_PERIOD == 0) {
            aEpoch = 1;
        } else if (epoch / YEAR_PERIOD == 1) {
            aEpoch = 2;
        } else if (epoch / YEAR_PERIOD == 2) {
            aEpoch = 3;
        } else if (epoch / YEAR_PERIOD == 3) {
            aEpoch = 4;
        } else if (epoch / YEAR_PERIOD == 4) {
            aEpoch = 5;
        } else if (epoch / YEAR_PERIOD >= 5) {
            aEpoch = 6;
        }
    }

    /**
     * Returns a divisor for the emission calculation.
	 *
     * @notice The divisor is doubled with each epoch which means the emission is halved until 3.125 % from the beginning emission.
	 *
     * @param cEpoch epoch which is checked
     * @return divisor divisor of the given epoch
     */
    function emissionOfEpoch(uint256 cEpoch) public pure returns (uint8 divisor) {
        require(cEpoch > 0 && cEpoch <= 6, "There are only 1 to 6 epochs");

        if (cEpoch == 1) {
            divisor = 1;
        } else if (cEpoch == 2) {
            divisor = 2;
        } else if (cEpoch == 3) {
            divisor = 4;
        } else if (cEpoch == 4) {
            divisor = 8;
        } else if (cEpoch == 5) {
            divisor = 16;
        } else if (cEpoch == 6) {
            divisor = 32;
        }
    }

    /**
     * Returns the actual emission of the actual epoch.
	 *
     * @notice The divisor is doubled with each epoch which means the emission is halved until 3.125 % from the beginning emission.
	 *
     * @return emissionPerSecond of the given epoch
     */
    function actualEmissionPerSecond() public view returns (uint256 emissionPerSecond) {
        uint8 multiplier = emissionOfEpoch(actualEpoch());

        emissionPerSecond = START_EMISSION / (multiplier * YEAR_PERIOD);
    }

    /**
     * Returns the emission of the given epoch.
	 *
     * @notice The divisor is doubled with each epoch which means the emission is halved until 3.125 % from the beginning emission.
	 *
     * @return emissionPerSecond of the given epoch
     */
    function emissionPerSecondOfEpoch(uint256 cEpoch) public view returns (uint256 emissionPerSecond) {
        uint8 multiplier = emissionOfEpoch(cEpoch);

        emissionPerSecond = START_EMISSION / (multiplier * YEAR_PERIOD);
    }

    /**
     * Calculates the emission per second so far minus the already calculated emission.
	 *
     * @notice Checks if there was a shift in the epochs in the meantime.
	 *
     * @return uncalc uncalculated emission
     */
    function uncalculatedEmission() public view returns (uint256 uncalc) {
        uint256 period0 = 0;
        uint256 period1 = 0;
        uint256 justNow = block.timestamp;
        uint256 actualEmission = emissionPerMinterPerSecond();

        uint8 actEpoch = actualEpoch();

        if (actEpoch != lastEpoch) {
            uint256 tempEndOfEpoch = endOfEpoch(lastEpoch);

            period0 = tempEndOfEpoch - lastEmissionCalculation;
            period1 = justNow - tempEndOfEpoch;

            uncalc = period0 * emissionPerSecondOfEpoch(lastEpoch);
        } else {
            period1 = justNow - lastEmissionCalculation;
        }

        uncalc += period1 * actualEmission;
    }

    /**
     * Calculates the emission since the last calculation and updates the state.
     */
    function updateEmission() public {
        emissionPerSecondPerMinter += uncalculatedEmission();
        lastEmissionCalculation = block.timestamp;

        uint8 actEpoch = actualEpoch();
        lastEpoch = actEpoch;
    }

    /**
     * Calculates the maximal mintable amount for a given minter.
	 *
     * @notice - Uncalculated emission + the already calculated emission
     *         - The real mintable amount is the result from this funtion minus the already minted amount
	 *
	 * @param minterAddr minter address
     * @return maxMintable uncalculated emission
     */
    function uncalculatedMaxEmissionForMinter(address minterAddr) public view returns (uint256 maxMintable) {
        if (_minter[minterAddr].lastEmission != 0) {
            uint256 tempEmissionPerMinter;
            uint256 availableEmission;

            if (_minter[minterAddr].isActive) {
                tempEmissionPerMinter = uncalculatedEmission();
                availableEmission = emissionPerSecondPerMinter + tempEmissionPerMinter - _minter[minterAddr].lastEmission;
            }

            maxMintable = _minter[minterAddr].maxMintable + availableEmission;
        }
    }

    /**
     * Calculates the maximal mintable amount for a given minter minus the already minted amount.
	 *
     * @notice The return is the "real" mintable amount for a minter.
	 *
	 * @param minterAddr minter address
     * @return mintable uncalculated emission
     */
    function maxMintableForMinter(address minterAddr) public view returns (uint256 mintable) {
        uint256 maxMintable = uncalculatedMaxEmissionForMinter(minterAddr);

        mintable = maxMintable - _minter[minterAddr].alreadyMinted;
    }

    /**
     * Changes the state of a minter with the uncalculated amounts.
     */
    function updateMinter(address minterAddr) public {
        if (isMinter(minterAddr)) {
            updateEmission();

            _minter[minterAddr].maxMintable = uncalculatedMaxEmissionForMinter(minterAddr);
            _minter[minterAddr].lastEmission = emissionPerSecondPerMinter;
        }
    }

    /**
     * Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * Returns the symbol of the token, usually a shorter version of the name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * Returns the number of decimals used to get its user representation.
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
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = msg.sender;
        _checkTransfer(owner, to, amount);
        return true;
    }

    /**
     * See {IERC20-allowance}.
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
     * See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
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
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * See {IERC20-transferFrom}.
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
    ) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _checkTransfer(from, to, amount);
        return true;
    }

    /**
     * Atomically increases the allowance granted to `spender` by the caller.
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
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * Atomically decreases the allowance granted to `spender` by the caller.
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
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * Substracts the amount of the from address and adds the burnt amount minus the transaction fees to the recipient address (to).
	 * Funds minter contract.
	 *
     * @notice The liquidity pool of myShare and myExchange has a 50% transaction fee if there are myExchange tokens swapped for myShare tokens.
	 *
	 * @param from from address
	 * @param to to address
	 * @param amount token amount
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        uint256 tFee = (amount * txnFee) / FEE_DIVISOR;
        uint256 sFee = (amount * stakeFee) / FEE_DIVISOR;

        // by increasing the fee of the MyEx lp, the sell pressure is dramatically taken away
        // myXXX(1.2%) -> MyEx -> MyS(50%) -> BUSD === 51.2% fee
        // myXXX(1.2%) -> MyEx -> myYYY(1.2%) -> BUSD === 2.4% fee
        // this keeps MyEx tokens in the system of myXXX tokens
        if (from == myExLiqPool) {
            tFee = amount / 2;
            tFee = tFee - sFee;
        }

        uint256 afterFee = amount - tFee - sFee;
        _burn(from, tFee);

        unchecked {
            _balances[from] = fromBalance - amount;
        }
		
        _balances[to] += afterFee;
        _balances[_myInkMinterAddr] += sFee;

        IMyInkMinter(_myInkMinterAddr).fundByMyShare(sFee);

        emit Transfer(from, to, afterFee);

        _afterTokenTransfer(from, to, afterFee);
    }

    /**
     * Substracts the amount of the from address and adds the amount without transaction fees to the recipient address (to).
	 *
	 * @param from from address
	 * @param to to address
	 * @param amount token amount
     */
    function _transferFeeless(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /**
     * Checks if a transfer should happen without fees or with fees.
	 *
	 * @param from from address
	 * @param to to address
	 * @param amount token amount
     */
    function _checkTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        uint blockNr = block.number;
        require(amount > 0, "Amount need to be greater than zero.");
        require(isBlacklisted[to] == false, "NO");
        require(lastTransaction[to] != blockNr, "Only one transaction per block and recipient allowed");
        require(lastTransaction[from] != blockNr, "Only one transaction per block and sender allowed");

        if (isWhitelisted[from] == true || isWhitelisted[to] == true) {
            _transferFeeless(from, to, amount);
        } else {
            _transfer(from, to, amount);
        }

        lastTransaction[from] = liqPool[from] ? 0 : blockNr;
        lastTransaction[to] = liqPool[to] ? 0 : blockNr;
    }

    /**
     * Mints a specific amount of tokens if the caller is a minter.
	 *
     * @param to recipient address
     * @param amount mint amount
	 * @param notRealised not realised amount
     */
    function mint(
        address to,
        uint256 amount,
        uint256 notRealised
    ) external nonReentrant {
        address minterAddr = msg.sender;

        updateMinter(minterAddr);

        if (isMinter(minterAddr)) {
            if (_minter[minterAddr].maxMintable >= _minter[minterAddr].alreadyMinted + amount) {
                _mint(to, amount, notRealised);
                _minter[minterAddr].alreadyMinted += amount;
            }
        }
    }

    /** Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(
        address account,
        uint256 amount,
        uint256 notRealised
    ) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        notRealisedMints += notRealised;

        _totalSupply += amount;
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * Triggers the global reflow and burns a specific amount of tokens.
	 *
     * @param amount burn amount
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /**
     * Destroys `amount` tokens from `account`, reducing the
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
        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        totalBurned += amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * Sets `amount` as the allowance of `spender` over the `owner` s tokens.
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
     * Updates `owner` s allowance for `spender` based on spent `amount`.
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
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * Withdraws ERC20 tokens from the contract.
	 * This contract should not be the owner of any other token.
	 *
     * @param tokenAddr address of the IERC20 token
     * @param to address of the recipient
     */
    function withdrawERC(address tokenAddr, address to) external onlyOwner {
        IERC20(tokenAddr).transfer(to, IERC20(tokenAddr).balanceOf(address(this)));
    }

    /**
     * Gives the owner the possibility to withdraw ETH which are airdroped or send by mistake to this contract.
	 *
     * @param to recipient of the tokens
     */
    function daoWithdrawETH(address to) external onlyOwner {

        (bool sent,) = to.call{value: address(this).balance}("");
		
        require(sent, "Failed to send ETH");
    }

    /**
     * Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
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

    /**
     * Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}