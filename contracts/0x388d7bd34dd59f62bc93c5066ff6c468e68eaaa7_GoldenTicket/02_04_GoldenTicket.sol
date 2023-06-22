pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./IERC20.sol";
import "./Context.sol";
import "./Ownable.sol";

/**
 *
 * GoldenTicket Contract - NFTR's special name token
 * You need to spend (send to Registry Contract) one Golden Ticket
 * in addition to 365RNM to choose a name from the special names list
 * @dev Extends standard ERC20 contract
 */
contract GoldenTicket is Context, IERC20, Ownable {

    // Constants
    uint256 public constant MAX_SUPPLY = 1000;
    // For bonding curve
    uint256 constant a_times_sig = 1000;
    uint256 constant SIG_DIGITS = 4;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
    address private _owner;

    // NFTR Registry Contract address
    address public nftrAddress;

    // Funds reserved for burns
    uint256 public reserve = 0;
    // Accumulated mint fees (10% of every mint) that haven't been withdrawed
    uint256 public accumulatedFees = 0;
    // Number of tickets that have been used (sent, therefore locked in NFTR Contract) and whose "unclaimable reserves" / orphan funds have already been withdrawn
    uint256 private numberTicketsFundsClaimedFor = 0;

    // Events
    /**
     * @dev Emitted when a ticket is minted
     */
    event GoldenTicketsMinted(
        address indexed to,
        uint256 numTickets,
        uint256 pricePaid,
        uint256 nextMintPrice,
        uint256 nextBurnPrice,
        uint256 ticketSupply,
        uint256 mintFee,
        uint256 newReserve
    );

    /**
     * @dev Emitted when a ticket is burned
     */
    event GoldenTicketsBurned(
        address indexed to,
        uint256 numTickets,
        uint256 burnProceeds,
        uint256 nextMintPrice,
        uint256 nextBurnPrice,
        uint256 ticketSupply,
        uint256 newReserve
    );

    // Methods

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a value of 0 -- only whole tickets allowed. Sets the contract owner.
     *
     *
     * All values except owner are immutable: they can only be set once during
     * construction.
     */
    constructor (address ownerin, string memory namein, string memory symbolin) {
        name = namein;
        symbol = symbolin;
        _setupDecimals(0);
        _owner = ownerin;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        decimals = decimals_;
    }    

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }


    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address ownerin, address spender) public view virtual override returns (uint256) {
        return _allowances[ownerin][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        // Approval check is skipped if the caller of transferFrom is the NFTRegistry contract. For better UX.
        if (_msgSender() != nftrAddress) {
            require(_allowances[sender][_msgSender()] >= amount,"ERC20: transfer amount exceeds allowance");
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        }
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        require(_allowances[_msgSender()][spender] >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Callable only once. It is manually set right after deployment and verified.
     */
    function setNFTRegistryAddress(address _nftrAddress) public onlyOwner {
        require(nftrAddress == address(0), "Already set");
        
        nftrAddress = _nftrAddress;
    }

    /**
     * @dev Get amount of ETH in reserve
     */
    function getReserve() public view returns (uint256) {
        return reserve;
    }    

    /**
     * @dev Get accumulated fees
     */
    function getAccumulatedFees() public view returns (uint256) {
        return accumulatedFees;
    }   

    /**
     * @dev Get number of used tickets (i.e. tickets in NFTR contract balance)
     */
    function numberUsedTickets() public view returns (uint256 nftrTicketBalance) {
        if(nftrAddress == address(0)) {
            nftrTicketBalance = 0;
        }
        else {
            nftrTicketBalance = balanceOf(nftrAddress);
        }
    }

    /**
     * @dev Get accumulated orphan ticket extractable funds
     */
    function getOrphanedTicketFunds() public view returns (uint256) {
        uint256 unclaimedOrphanFunds = 0;
        if (nftrAddress != address(0)) { // NFTR contract has already been set and could have GTKs in its balance
            uint256 nftrTicketBalance = balanceOf(nftrAddress);
            uint256 orphanFundsWithdrawn = getOrphanFundsForUsedTicketNumber(numberTicketsFundsClaimedFor);
            uint256 totalOrphanFunds = getOrphanFundsForUsedTicketNumber(nftrTicketBalance);
            unclaimedOrphanFunds = totalOrphanFunds - orphanFundsWithdrawn;
        }
        return unclaimedOrphanFunds;
    }

    /**
     * @dev Returns mint price of the mintNumber golden ticket in wei
     *
     */
    function getSingleMintPrice(uint256 mintNumber) public pure returns (uint256 price) {
        require(mintNumber <= MAX_SUPPLY, "Maximum supply exceeded");
        require(mintNumber > 0, "Minting a supply of 0 tickets isn't valid");

        uint256 dec = 10 ** SIG_DIGITS;
        price = a_times_sig + (mintNumber * (mintNumber));

        price = price * (1 ether) / (dec);
    }

    /**
     * @dev Returns mint price of the next golden ticket in wei
     */
    function currentMintPrice(uint256 quantity) public view returns (uint256 price) {
        uint256 dec = 10 ** SIG_DIGITS;
        price = 0;
        uint256 mintNumber;
        for (uint i = 0; i < quantity; i++) {
            mintNumber = totalSupply() + (i + 1);
            price += a_times_sig + (mintNumber * (mintNumber));
        }
        price = price * (1 ether) / (dec);
    }
 
    /**
     * @dev Function to get funds received when burned
     * @param supply the golden ticket supply before buring. Ex. if there are 3 existing tickets, to get the funds
     * received on burn, supply should be 3
     */
    function getSingleBurnPrice(uint256 supply) public pure returns (uint256 price) {
        if (supply == 0) return 0;
        uint256 mintPrice = getSingleMintPrice(supply);
        price = mintPrice * (90) / (100);  // 90 % of mint price of last minted ticket (i.e. current supply)
    }    

    /**
     * @dev Function to get amount of funds received currently when ticket is burned
     */
    function currentBurnPrice(uint256 quantity) public view returns (uint256 price) {
        if (totalSupply() == 0) return 0;
        if (quantity > totalSupply()) return 0;
        uint256 mintPrice;
        for (uint i = 0; i < quantity; i++) {
            mintPrice += getSingleMintPrice(totalSupply() - i);
        }
        price = mintPrice * (90) / (100);  // 90 % of mint price of last minted ticket (i.e. current supply)
    }  

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

        _totalSupply = _totalSupply + (amount);
        _balances[account] = _balances[account] + (amount);
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

        require(_balances[account] >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - (amount);
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
    function _approve(address ownerin, address spender, uint256 amount) internal virtual {
        require(ownerin != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[ownerin][spender] = amount;
        emit Approval(ownerin, spender, amount);
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

        /**
     * @dev Hook that is called after any transfer of tokens. This includes
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

   /**
     * @dev Mints *quantity* Golden Tickets to the address of the sender
     * @param quantity The number of Golden Tickets to mint
     */
    function mintTickets(uint256 quantity)
        public
        payable
        returns (uint256)
    {
        require(quantity > 0, "Can't mint 0 Golden Tickets");
        require(_totalSupply + quantity <= MAX_SUPPLY, "That quantity of tickets takes supply over max supply");
        uint256 oldSupply = _totalSupply;
        // Get price to mint *quantity* tickets
        uint256 mintPrice = 0;
        for (uint i = 0; i < quantity; i++) {
            mintPrice += getSingleMintPrice(oldSupply + (i + 1));
        }
        
        require(msg.value >= mintPrice, "Insufficient funds");

        uint256 newSupply = _totalSupply + (quantity);

        // Update reserve - reserveCut == Price to burn next ticket
        uint256 reserveCut = 0;
        for (uint i = 0; i < quantity; i++) {
            reserveCut += getSingleBurnPrice(newSupply - i);
        }
        reserve = reserve + (reserveCut);
        accumulatedFees = accumulatedFees + (mintPrice) - (reserveCut);

        // Mint token
        _mint(msg.sender,  quantity);

        // If buyer sent extra ETH as padding in case another purchase was made they are refunded
        _refundSender(mintPrice, msg.value);

        emit GoldenTicketsMinted(msg.sender, quantity, mintPrice, getSingleMintPrice(newSupply + (1)), getSingleBurnPrice(newSupply), newSupply, mintPrice - (reserveCut), reserve);
        
        return newSupply;
    }    

    /**
     * @dev If sender sends more Ether than necessary when minting, refunds the extra funds
     *
     */
    function _refundSender(uint256 mintPrice, uint256 msgValue) internal {
        if (msgValue - (mintPrice) > 0) {
            (bool success, ) =
                msg.sender.call{value: msgValue - (mintPrice)}("");
            require(success, "Refund failed");
        }
    }

        /**
     * @dev Function to burn a ticket
     * @param minimumSupply The minimum token supply for burn to succeed, this is a way to set slippage. 
     * Set to 1 to allow burn to go through no matter what the price is.
     * @param quantity The number of Golden Tickets to burn
     */
    function burnTickets(uint256 minimumSupply, uint256 quantity) public returns (uint256) {
        uint256 oldSupply = _totalSupply;
        require(oldSupply >= minimumSupply, 'Min supply not met');
        require(quantity > 0, "Can't burn 0 Golden Tickets");
        require(quantity <= _totalSupply, "Can't burn more tickets than total supply");

        uint256 burnPrice = 0;
        for (uint i = 0; i < quantity; i++) {
            burnPrice += getSingleBurnPrice(oldSupply - i);
        }
        uint256 newSupply = _totalSupply - (quantity);

        // Update reserve
        reserve = reserve - (burnPrice);

        _burn(msg.sender, quantity);

        // Disburse funds
        (bool success, ) = msg.sender.call{value: burnPrice}("");
        require(success, "Burn payment failed");

        emit GoldenTicketsBurned(msg.sender, quantity, burnPrice, getSingleMintPrice(oldSupply - quantity + 1), getSingleBurnPrice(newSupply), newSupply, reserve);

        return newSupply;
    }     

    /**
     * @dev Function that calculates previously reserved exit (burn) liquidity 
     * that will be claimed by burning since they have already been used to 
     * name (i.e. they have been transferred to the NFTR Contract)
     */
    function getOrphanFundsForUsedTicketNumber(uint256 ticketNumber) internal pure returns (uint256 _orphanFunds) { 
        // Summing ticket mint prices from k = 1 to n, then multiplying by 9/10 (90%). Reduces to:
        _orphanFunds = 9 * ticketNumber * 10 ** 16 + ticketNumber * (ticketNumber + 1) * (2 * ticketNumber + 1) * 9 / 6 * 10 ** 13;
    } 

     /**
     * @dev Withdraw treasury ETH
     */
    function withdraw() public onlyOwner {
        uint256 unclaimedOrphanFunds = 0;
        if (nftrAddress != address(0)) { // NFTR contract has already been set and could have GTs in its balance
            uint256 nftrTicketBalance = balanceOf(nftrAddress);
            uint256 orphanFundsWithdrawn = getOrphanFundsForUsedTicketNumber(numberTicketsFundsClaimedFor);
            uint256 totalOrphanFunds = getOrphanFundsForUsedTicketNumber(nftrTicketBalance);
            unclaimedOrphanFunds = totalOrphanFunds - orphanFundsWithdrawn;
            numberTicketsFundsClaimedFor = nftrTicketBalance;
        }
        uint256 withdrawableFunds = accumulatedFees + (unclaimedOrphanFunds);
        accumulatedFees = 0;
        (bool success, ) = msg.sender.call{value: withdrawableFunds}("");
        require(success, "Withdraw failed");
    } 

}