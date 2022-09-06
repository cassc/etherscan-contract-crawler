// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Interface/IRelayerRegistry.sol";
import "./Deposit.sol";

/**
 * @title Database for relayer dao
 * @notice this is a modified erc20 token because of saving gas.
 *         1. removed approve
 *         2. only able to transfer to or from exitQueueContract
 *         3. only transferFrom by exitQueueContract without approve
 * @notice  the token is the voucher of the deposit
 *          token/totalSupply  is the percentage of the user
 */
contract RootDB is OwnableUpgradeable, ERC20Upgradeable {
    /// the address of  exitQueue contract
    address public   exitQueueContract;
    /// the address of  deposit contract
    address public   depositContract;
    /// the address of  inCome contract
    address public   inComeContract;
    /// the address of  operator set by owner
    address public   operator;
    /// the address of  profitRecord contract
    address public   profitRecordContract;
    /// the max counter of  relayers
    uint256 public   MAX_RELAYER_COUNTER;
    /// mapping index to relayers address
    mapping(uint256 => address) public  mRelayers;

    /// the address of  torn token contract
    address immutable public TORN_CONTRACT;
    /// the address of  torn relayer registry
    address immutable public TORN_RELAYER_REGISTRY;

    /// the address of  Tornado multisig
    address immutable public TORNADO_MULTISIG;

    /**
     * @notice Called by the Owner to set operator
     * @param operator_ The address of the new operator
     */
    function setOperator(address operator_) external onlyOwner
    {
        operator = operator_;
    }

    /**
     * @param tornRelayerRegistry :the address of  torn relayer registry
     * @param tornContract : the address of  torn token contract
     */
    constructor(
        address tornRelayerRegistry,
        address tornContract,
        address tornadoMultisig
    ) {
        TORN_CONTRACT = tornContract;
        TORN_RELAYER_REGISTRY = tornRelayerRegistry;
        TORNADO_MULTISIG = tornadoMultisig;
    }



    function __RootDB_init(address inComeContract_, address depositContract_, address exitQueueContract_, address profitRecordContract_) public initializer {
        __RootDB_init_unchained(inComeContract_, depositContract_, exitQueueContract_, profitRecordContract_);
        __ERC20_init("relayer_dao", "relayer_dao_token");
        __Ownable_init();
    }

    function __RootDB_init_unchained(address inComeContract_, address depositContract_, address exitQueueContract_, address profitRecordContract_) public onlyInitializing {
        inComeContract = inComeContract_;
        depositContract = depositContract_;
        exitQueueContract = exitQueueContract_;
        profitRecordContract = profitRecordContract_;
    }


    /**
      * @notice addRelayer used to add relayers to the system call by Owner
      * @dev inorder to save gas designed a simple algorithm to manger the relayers
             it is not perfect
      * @param relayer address of relayers
                address can only added once
      * @param  index  of relayer
   **/
    function addRelayer(address relayer, uint256 index) external onlyOwner
    {
        require(index <= MAX_RELAYER_COUNTER, "too large index");

        uint256 counter = MAX_RELAYER_COUNTER;

        for (uint256 i = 0; i < counter; i++) {
            require(mRelayers[i] != relayer, "repeated");
        }

        if (index == MAX_RELAYER_COUNTER) {
            MAX_RELAYER_COUNTER += 1;
        }
        require(mRelayers[index] == address(0), "index err");
        mRelayers[index] = relayer;
    }


    /**
      * @notice removeRelayer used to remove relayers form  the system call by Owner
      * @dev inorder to save gas designed a simple algorithm to manger the relayers
             it is not perfect
             if remove the last one it will dec MAX_RELAYER_COUNTER
      * @param  index  of relayer
    **/
    function removeRelayer(uint256 index) external onlyOwner
    {
        require(index < MAX_RELAYER_COUNTER, "too large index");

        // save gas
        if (index + 1 == MAX_RELAYER_COUNTER) {
            MAX_RELAYER_COUNTER -= 1;
        }

        require(mRelayers[index] != address(0), "index err");
        delete mRelayers[index];
    }

    modifier onlyDepositContract() {
        require(msg.sender == depositContract, "Caller is not depositContract");
        _;
    }

    /**
      * @notice totalRelayerTorn used to calc all the relayers unburned torn
      * @return tornQty The number of total Relayer Torn
    **/
    function totalRelayerTorn() external view returns (uint256 tornQty){
        tornQty = 0;
        address relay;
        uint256 counter = MAX_RELAYER_COUNTER;
        //save gas
        for (uint256 i = 0; i < counter; i++) {
            relay = mRelayers[i];
            if (relay != address(0)) {
                tornQty += IRelayerRegistry(TORN_RELAYER_REGISTRY).getRelayerBalance(relay);
            }
        }
    }

    /**
    * @notice totalTorn used to calc all the torn in relayer dao
    * @dev it is sum of (Deposit contract torn + InCome contract torn + totalRelayersTorn)
    * @return tornQty The number of total Torn
   **/
    function totalTorn() public view returns (uint256 tornQty){
        tornQty = Deposit(depositContract).totalBalanceOfTorn();
        tornQty += ERC20Upgradeable(TORN_CONTRACT).balanceOf(inComeContract);
        tornQty += this.totalRelayerTorn();
    }

    /**
     * @notice safeMint used to calc token and mint to account
             this  is called when user deposit torn to the system
     * @dev  algorithm  :   qty / ( totalTorn() + qty) = to_mint/(totalSupply()+ to_mint)
            if is the first user to mint mint is 10
     * @param  account the user's address
     * @param  tornQty is  the user's torn to deposit
     * @return the number token to mint
    **/
    function safeMint(address account, uint256 tornQty) onlyDepositContract external returns (uint256) {
        uint256 total = totalSupply();
        uint256 to_mint;
        if (total == uint256(0)) {
            to_mint = 10 * 10 ** decimals();
        }
        else {// qty / ( totalTorn() + qty) = to_mint/(totalSupply()+ to_mint)
            to_mint = total * tornQty / this.totalTorn();
        }
        _mint(account, to_mint);
        return to_mint;
    }

    /**
    * @notice safeBurn used to _burn voucher token withdraw form the system
             this  is called when user deposit torn to the system
    * @param  account the user's address
    * @param  tokenQty is the  the user's voucher to withdraw
   **/
    function safeBurn(address account, uint256 tokenQty) onlyDepositContract external {
        _burn(account, tokenQty);
    }


    function balanceOfTorn(address account) public view returns (uint256){
        return valueForTorn(this.balanceOf(account));
    }

    function valueForTorn(uint256 tokenQty) public view returns (uint256){
        return tokenQty * (this.totalTorn()) / (totalSupply());
    }

    /**
      @dev See {IERC20-transfer}.
     *   overwite this function inorder to prevent user transfer voucher token
     *   Requirements:
     *   - `to` cannot be the zero address.
     *   - the caller must have a balance of at least `amount`.
     * @notice IMPORTANT: one of the former or target must been exitQueueContract
    **/
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        require(owner == exitQueueContract || to == exitQueueContract, "err transfer");
        _transfer(owner, to, amount);
        return true;
    }

    /**
    * @dev See {IERC20-transferFrom}.
     * Requirements:
     *
     * @notice IMPORTANT: inorder to saving gas we removed approve
       and the spender is fixed to exitQueueContract
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        // only approve to exitQueueContract to save gas
        require(_msgSender() == exitQueueContract, "err transferFrom");
        //_spendAllowance(from, spender, amount); to save gas
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @notice IMPORTANT: inorder to saving gas we removed approve
     */
    function approve(address /* spender */, uint256 /* amount */) public virtual override returns (bool ret) {
        ret = false;
        require(false, "err approve");
    }
}