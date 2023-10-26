pragma solidity ^0.5.0;

import "hardhat/console.sol";

import "./CleverProtocol.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/access/roles/MinterRole.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @dev Implementation of the ERC20 CleverToken
 *
 * At construction, the deployer of the contract is the only owner, 
 * which will be used to solely set the Protocol and then renounce,
 * bricking any onlyOwner functions in this token. Additionally, the
 * owner is set as the only minter, and should revoke minting ability 
 * 
 */
contract CleverToken is Ownable, MinterRole, IERC20 {
    using SafeMath for uint256;
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    // Used for authentication of distribution
    address payable public Protocol;
    address payable private _admin;

    event LogCycleDistribution(uint256 indexed cycle, uint256 newly_added_tokens);
    event LogProtocolSet(address Protocol);

    uint256 private fragsPerToken;
    uint256 private lastCyclePaid = 0;
    
    uint256 private DECIMALS = 18;
    uint256 private constant MAX_UINT256 = ~uint256(0);

    uint256 private totalFrags = 1e60;
    
    bool private lockedSwap = false;
    uint256 internal _cap;
    
    uint256 private _totalSupply;
    mapping (address => uint256) private _fragBalances;
    mapping (address => mapping (address => uint256)) private _allowances;

    modifier onlyProtocol() {
        require(msg.sender == Protocol,"Sender is not the Protocol!");
        _;
    }
    
    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;

        _totalSupply = 0;
        fragsPerToken = 1e30;
        _cap = uint256(1_000_000_000_000).mul(1e18); //1 trillion tokens
    }
    
    function distribute(uint256 _cycle, uint256 _percentageFactor,uint256 _bonusPercentageFactor) external onlyProtocol {
        //Protocol ensures that this will not be called prior to swap/minting phase ending
        //require this cycle to be +1 to the last cycle paid
        require(_cycle > lastCyclePaid, "Cycle attempting to be paid out is in the past!");

        if(!lockedSwap){
            //set the contract constants based on the _totalSupply at the time of the first distrubtion
            //totalFrags from here forth is permanent-- this locks in the proper % distributions
            // 1e30 is the maximum resolution required since max_supply is 1e12
            totalFrags = _totalSupply.mul(uint256(1e30));
            
            //lock Minting from here
            lockedSwap = true;
        }

        require(lockedSwap,"Swapping phase is not over!");
        
        //retrieve the initial supply
        uint256 initial_total_supply = _totalSupply;
        
        //factor is percentage taken out of 1e5, therefore if factor is 1 then the percentage is 0.00001
        //since the max supply is 1e12*1e18, instability is not taken into account
        uint256 delta = (initial_total_supply.mul(_percentageFactor)).div(1e5);
        require(delta > 0, "supply delta was not greater than 0");
        
        //set the internal supply of the CLVA token
        _totalSupply = _totalSupply.add(delta);
        
        //distribute the bonus if applicable
        if(_bonusPercentageFactor > 0) {
            //calculate initial supply
            uint256 initial_total_supply_two = _totalSupply;

            uint256 delta_two = (initial_total_supply_two.mul(_bonusPercentageFactor)).div(1e5);
            require(delta_two > 0, "supply delta was not greater than 0");

            //set the internal supply of the CLVA token
            _totalSupply = _totalSupply.add(delta_two);
        }

        //if cap is ever reached, simply set the supply in circulation equal to that and continue
        if (_totalSupply > _cap) {
            _totalSupply = _cap;
        } else{
            
            fragsPerToken = totalFrags.div(_totalSupply);

            //send to admin as long as cap is not met
            //admin receives 0.1% of new total supply
            uint256 forAdmin = (_totalSupply.mul(1e2)).div(1e5);

            //update total supply AND total frags so that the rate does not change
            _totalSupply = _totalSupply.add(forAdmin);
            totalFrags = totalFrags.add(forAdmin.mul(fragsPerToken));

            _fragBalances[_admin] = _fragBalances[_admin].add(forAdmin.mul(fragsPerToken));

            fragsPerToken = totalFrags.div(_totalSupply);
        }
        
        
        lastCyclePaid = lastCyclePaid.add(1);
        
        emit LogCycleDistribution(lastCyclePaid, delta);
    }
    
    function setProtocol(address payable _protocol) external onlyOwner {
        Protocol = _protocol;
        CleverProtocol protocolContract = CleverProtocol(Protocol);
        _admin = protocolContract.admin();

        emit LogProtocolSet(Protocol);
    }
    
    function protocol() public view returns(address){
        return Protocol;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _fragBalances[account].div(fragsPerToken);
    }

    function fragsOf(address account) public view returns (uint256){
        return _fragBalances[account];
    }

    function admin() public view returns(address){
        return _admin;
    }
    
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        require(totalSupply().add(amount) <= _cap, "CLVA in circulation has reached 1 trillion!");
        if(lockedSwap){
            // different minting funciton
            _mintAfterSwap(account,amount);
        } else{
            _mint(account, amount);    
        }
        
        return true;
    }
    
     /**
     * @dev Override interal mint function
     * @param account The account to receive newly minted coins
     * @param amount The amount to be transferred.
     */
     
    function _mint(address account, uint256 amount) internal {
        require(!lockedSwap, "minting phase is over");
        require(account != address(0), "ERC20: mint to the zero address");
        
        _totalSupply = _totalSupply.add(amount);
        
        _fragBalances[account] = _fragBalances[account].add(amount.mul(fragsPerToken));
        emit Transfer(address(0), account, amount);
    }
    
    function _mintAfterSwap(address account, uint256 amount) internal{
        require(account != address(0), "ERC20: mint to the zero address");
        
        //add amount to total supply
        _totalSupply = _totalSupply.add(amount);
        
        //calculate the number of frags this is
        uint256 fragAmount = amount.mul(fragsPerToken);
        
        //add this frag amount to the address account
        _fragBalances[account] = _fragBalances[account].add(fragAmount);    
        
        //fragsPerToken ~ 1e60 - O(totalSupply), amount ~ O(totalSupply), therefore fragAmount~ 1e48 - O(totalSupply) + O(totalSupply) ~ 1e48 
        require(amount < _totalSupply, "amount < totalSupply -- bounding this ensures no inflationary issues in regards to the internal FRAG denomination -- will always be O(e60)");
        
        //update total frags
        totalFrags = totalFrags.add(fragAmount);
        
        //update fragsPerToken
        fragsPerToken = totalFrags.div(_totalSupply);
        
        emit Transfer(address(0), account, amount);
    }
    
    function adminDistribute(uint256 _percentageFactor) external onlyOwner {
        //Protocol ensures that this will not be called prior to swap/minting phase ending
        //require this cycle to be +1 to the last cycle paid
        if(!lockedSwap){
            revert("no distribution available while in intial minting phase.");
        }
        
        require(lockedSwap,"Swapping phase is not over!");
        
        if (_totalSupply > _cap) {
            revert("max supply has been reached!");
        }
        //retrieve the initial supply
        uint256 initial_total_supply = _totalSupply;
        
        //factor is percentage taken out of 1e5, therefore if factor is 1 then the percentage is 0.00001
        //since the max supply is 1e12*1e18, instability is not taken into account
        uint256 delta = (initial_total_supply.mul(_percentageFactor)).div(1e5);
        require(delta > 0, "supply delta was not greater than 0");
        
        //set the internal supply of the CLVA token
        _totalSupply = _totalSupply.add(delta);
        
        //if cap is ever reached, simply set the supply in circulation equal to that
        if (_totalSupply > _cap) {
            _totalSupply = _cap;
        }
        
        fragsPerToken = totalFrags.div(_totalSupply);
        
        emit LogCycleDistribution(999, delta);
    }
    
    /**
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
    function transfer(address to, uint256 value)
        public
        returns (bool)
    {
        require(to != address(0), "ERC20: transfer from the zero address");

        uint256 fragValue = value.mul(fragsPerToken);
        _fragBalances[msg.sender] = _fragBalances[msg.sender].sub(fragValue);
        _fragBalances[to] = _fragBalances[to].add(fragValue);
        emit Transfer(msg.sender, to, value);
        return true;
    }    
    
     /**
     * Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param value The amount of tokens to be transferred.
     */
    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool)
    {
        require(to != address(0), "ERC20: transfer from the zero address");
        require(from != address(0), "ERC20: transfer from the zero address");
        
        _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);

        uint256 fragValue = value.mul(fragsPerToken);
        _fragBalances[from] = _fragBalances[from].sub(fragValue);
        _fragBalances[to] = _fragBalances[to].add(fragValue);
        emit Transfer(from, to, value);

        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner_][spender];
    }
    
    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value)
        public
        returns (bool)
    {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0), "ERC20: zero address");

        _allowances[msg.sender][spender] = _allowances[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0), "ERC20: zero address");
        _allowances[msg.sender][spender] = _allowances[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }


    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev Returns the token's total supply.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
        /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    
}