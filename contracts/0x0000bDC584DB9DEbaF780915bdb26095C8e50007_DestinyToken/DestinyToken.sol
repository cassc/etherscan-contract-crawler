/**
 *Submitted for verification at Etherscan.io on 2023-05-19
*/

/*=======================================================================================================================
#                                                           ..                                                          #
#                                                           ::                                                          #
#                                                           !!                                                          #
#                                                          .77.                                                         #
#                                                          ~77~                                                         #
#                                                         .7777.                                                        #
#                                                         !7777!                                                        #
#                                                        ^777777^                                                       #
#                                                       ^77777777^                                                      #
#                                                      ^777!~~!777^                                                     #
#                                                     ^7777!::!7777^                                                    #
#                                                   .~77777!  !77777~.                                                  #
#                                                  :!77777!:  :!77777!:                                                 #
#                                                 ~777777!^    ^!777777~                                                #
#                                               :!7777777^      ^7777777!:                                              #
#                                             :!77777777:        :77777777!:                                            #
#                                           :!77777777!.          .!77777777!:                                          #
#                                        .^!77777777!^              ^!77777777!^.                                       #
#                                      :~7777777777^.       ..       .^7777777777~:                                     #
#                                   .^!777777777!^.         ^^         .^!777777777!^.                                  #
#                               .:~!777777777!~:           :77:           :~!777777777!~:.                              #
#                           .:^!7777777777!~:             ^7777^             :~!7777777777!^:.                          #
#                     ..:^~!77777777!!~^:.             .^!777777!^.             .:^~!!77777777!~^:..                    #
#           ...::^^~!!77777777~~^^:..              .:^!777777777777!^:.              ..:^^~~77777777!!~^^::...          #
#           ...::^^~!!77777777~~^^:..              .:^!777777777777!^:.              ..:^^~~77777777!!~^^::...          #
#                     ..:^~!77777777!!~^:.             .^!777777!^.             .:^~!!77777777!~^:..                    #
#                           .:^!7777777777!~:             ^7777^             :~!7777777777!^:.                          #
#                               .:~!777777777!~:           :77:           :~!777777777!~:.                              #
#                                   .^!777777777!^.         ^^         .^!777777777!^.                                  #
#                                      :~7777777777^.       ..       .^7777777777~:                                     #
#                                        .^!77777777!^              ^!77777777!^.                                       #
#                                           :!77777777!.          .!77777777!:                                          #
#                                             :!77777777:        :77777777!:                                            #
#                                               :!7777777^      ^7777777!:                                              #
#                                                 ~777777!^    ^!777777~                                                #
#                                                  :!77777!:  :!77777!:                                                 #
#                                                   .~77777!  !77777~.                                                  #
#                                                     ^7777!::!7777^                                                    #
#                                                      ^777!~~!777^                                                     #
#                                                       ^77777777^                                                      #
#                                                        ^777777^                                                       #
#                                                         !7777!                                                        #
#                                                         .7777.                                                        #
#                                                          ~77~                                                         #
#                                                          .77.                                                         #
#                                                           !!                                                          #
#                                                           ::                                                          #
#                                                           ..                                                          #
#                                                                                                                       #
/*=======================================================================================================================
#                                                                                                                       #
#     ██████╗ ███████╗███████╗████████╗██╗███╗   ██╗██╗   ██╗████████╗███████╗███╗   ███╗██████╗ ██╗     ███████╗       #   
#     ██╔══██╗██╔════╝██╔════╝╚══██╔══╝██║████╗  ██║╚██╗ ██╔╝╚══██╔══╝██╔════╝████╗ ████║██╔══██╗██║     ██╔════╝       #
#     ██║  ██║█████╗  ███████╗   ██║   ██║██╔██╗ ██║ ╚████╔╝    ██║   █████╗  ██╔████╔██║██████╔╝██║     █████╗         #
#     ██║  ██║██╔══╝  ╚════██║   ██║   ██║██║╚██╗██║  ╚██╔╝     ██║   ██╔══╝  ██║╚██╔╝██║██╔═══╝ ██║     ██╔══╝         #
#     ██████╔╝███████╗███████║   ██║   ██║██║ ╚████║   ██║      ██║   ███████╗██║ ╚═╝ ██║██║     ███████╗███████╗       #
#     ╚═════╝ ╚══════╝╚══════╝   ╚═╝   ╚═╝╚═╝  ╚═══╝   ╚═╝      ╚═╝   ╚══════╝╚═╝     ╚═╝╚═╝     ╚══════╝╚══════╝       #
#                                                                                                                       #
========================================================================================================================*/
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);
    
    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);
    
    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);
    
    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
pragma solidity ^0.8.10;
/// @notice Main,Destiny Governance Token.
contract DestinyToken is IERC20{
    address immutable private deployer;
    address private _destinySwap;
    bool initialized;
    address public constant LIQUIDITY = 0x7777777777777777777777777777777777777777;
	address constant internal DESTINY_RECORDER = 0x99995D080A1bfa91d065dD14C567089D103BfBB9;
    address constant internal KIYOMIYA = 0x00001C1D6ab92F943eD4A31dA8F447Fd96589960;
    address constant internal BLACK_HOLE = 0x000000000000000000000000000000000000dEaD;
    uint constant internal RATE = 7777;

    string constant private NAME = "DestinyToken";
    string constant private SYMBOL = "DIY";
    uint constant private DECIMALS = 2;
    uint256 private _totalSupply = (7777 * 19 + 7) * RATE;
    mapping (address => uint256) private  _balances;
    mapping (address => mapping (address => uint256)) private  _allowances;

    modifier onlyDeployer(){
        require(msg.sender == deployer);
        _;
    }
    modifier initialize(){
        require(!initialized,"initialized.");
        initialized = true;
        _;
    }
    modifier onlyDestinySwap() {
        require(msg.sender == _destinySwap,"ERC20: Msg.sender not DestinySwap.");
        _;
    }
    modifier verifyBalance(uint _balance,uint256 value){
        require(_balance >= value,"ERC20: transfer amount exceeds balance.");
        _;
    }
    modifier verifyallowance(address from,uint _value){
        require(_allowances[from][msg.sender] >= _value || from == msg.sender,"ERC20: transfer amount exceeds allowance.");
        _;
    }
    modifier isOwnerOrApproved(address from,uint256 value){
        require(_allowances[from][tx.origin] >= value || from == tx.origin,"ERC20: transfer amount exceeds allowance");
        _;
    }

    constructor() {
        deployer = tx.origin;
    }

    function initialization(address destinySwap, address[] memory initialExecutors) public onlyDeployer initialize{ 
        _destinySwap = destinySwap;

        _allowances[LIQUIDITY][_destinySwap] = _totalSupply * 7777777 * RATE;
        emit Approval(LIQUIDITY, _destinySwap, _totalSupply * 7777777 * RATE);
        _balances[LIQUIDITY] += 2 * 7777 * RATE + 8 * 7777 * RATE;
        emit Transfer(address(0), LIQUIDITY, 2 * 7777 * RATE + 8 * 7777 * RATE);

        _balances[BLACK_HOLE] += 7777 * RATE;
        emit Transfer(address(0), BLACK_HOLE, 7777 * RATE);

        for(uint i=0;i<initialExecutors.length;i++){
            _balances[initialExecutors[i]] += 865 * RATE;
            emit Transfer(address(0), initialExecutors[i], 865 * RATE);
        }

        _balances[DESTINY_RECORDER] += 7777 * RATE;
        emit Transfer(address(0), DESTINY_RECORDER, 7777 * RATE);
        _balances[KIYOMIYA] += 7776 * RATE;
        emit Transfer(address(0), KIYOMIYA, 7776 * RATE);
        _balances[tx.origin] += 5 * 7777 * RATE;
        emit Transfer(address(0), tx.origin, 5 * 7777 * RATE);
    }
    function owner() external pure returns (address) {
        return address(0);
    }
    function name() external pure returns (string memory) {
        return NAME;
    }
    function symbol() external pure returns (string memory) {
        return SYMBOL;
    }
    function decimals() external pure returns (uint) {
        return DECIMALS;
    }
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address _owner) external view returns (uint256) {
        return _balances[_owner];
    }
    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        return _allowances[_owner][_spender];
    }
    /// @notice Transfer _value amount of tokens to recipient;
    function transfer(address to, uint256 _value) external verifyBalance(_balances[msg.sender],_value)  returns (bool success) {
        _balances[msg.sender] -= _value;
        _balances[to] += _value;

        emit Transfer(msg.sender, to, _value);
        return true;
    }
    ///@notice Transfer _value tokens from the sender who has authorized you to the recipient.
    function transferFrom(address from, address to, uint256 _value) external verifyBalance(_balances[from],_value) verifyallowance(from,_value) returns (bool success) {        
        _balances[from] -= _value;
        _balances[to] += _value;
        if(from != msg.sender){
            _allowances[from][msg.sender] -= _value;
        }
        emit Transfer(from, to, _value);
        return true;
    }
    /// @notice Grant _spender the right to control your _value amount of the token.
    function approve(address to, uint256 amount) external returns (bool success) {
        _allowances[msg.sender][to] = amount;
        emit Approval(msg.sender, to, amount);
        return true;
    }

    /**
     *  @notice Allows minting the input amount of tokens to the specified address.
     *  @dev onlyDestinySwap: Only allow minting via the redeem DST function of the destinyswap contract.
     */
    function mint(address to, uint amount) public onlyDestinySwap returns (bool success) {
        _totalSupply += amount;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
        return true;
    }

    /**
     *  @notice Allows to destroy the input amount of tokens from the specified address.
     *  @dev The specified address needs to approve you to allow access to a sufficient amount of tokens.
     *       Or you are destroying the address yourself.
     */
    function burn(address from, uint amount) public verifyBalance(_balances[from], amount) isOwnerOrApproved(from,amount) returns (bool success) {
        _balances[from] -= amount;
        _totalSupply -= amount;
        if(from != tx.origin){
            _allowances[from][tx.origin] -= amount;
        }
        emit Transfer(from, address(0), amount);
        return true;
    }
}
/*=======================================================================================================================
#                                                                                                                       #
#     ██████╗ ███████╗███████╗████████╗██╗███╗   ██╗██╗   ██╗████████╗███████╗███╗   ███╗██████╗ ██╗     ███████╗       #
#     ██╔══██╗██╔════╝██╔════╝╚══██╔══╝██║████╗  ██║╚██╗ ██╔╝╚══██╔══╝██╔════╝████╗ ████║██╔══██╗██║     ██╔════╝       #
#     ██║  ██║█████╗  ███████╗   ██║   ██║██╔██╗ ██║ ╚████╔╝    ██║   █████╗  ██╔████╔██║██████╔╝██║     █████╗         #
#     ██║  ██║██╔══╝  ╚════██║   ██║   ██║██║╚██╗██║  ╚██╔╝     ██║   ██╔══╝  ██║╚██╔╝██║██╔═══╝ ██║     ██╔══╝         #
#     ██████╔╝███████╗███████║   ██║   ██║██║ ╚████║   ██║      ██║   ███████╗██║ ╚═╝ ██║██║     ███████╗███████╗       #
#     ╚═════╝ ╚══════╝╚══════╝   ╚═╝   ╚═╝╚═╝  ╚═══╝   ╚═╝      ╚═╝   ╚══════╝╚═╝     ╚═╝╚═╝     ╚══════╝╚══════╝       #
#                                                                                                                       #
*=======================================================================================================================*
#                                                           ..                                                          #
#                                                           ::                                                          #
#                                                           !!                                                          #
#                                                          .77.                                                         #
#                                                          ~77~                                                         #
#                                                         .7777.                                                        #
#                                                         !7777!                                                        #
#                                                        ^777777^                                                       #
#                                                       ^77777777^                                                      #
#                                                      ^777!~~!777^                                                     #
#                                                     ^7777!::!7777^                                                    #
#                                                   .~77777!  !77777~.                                                  #
#                                                  :!77777!:  :!77777!:                                                 #
#                                                 ~777777!^    ^!777777~                                                #
#                                               :!7777777^      ^7777777!:                                              #
#                                             :!77777777:        :77777777!:                                            #
#                                           :!77777777!.          .!77777777!:                                          #
#                                        .^!77777777!^              ^!77777777!^.                                       #
#                                      :~7777777777^.       ..       .^7777777777~:                                     #
#                                   .^!777777777!^.         ^^         .^!777777777!^.                                  #
#                               .:~!777777777!~:           :77:           :~!777777777!~:.                              #
#                           .:^!7777777777!~:             ^7777^             :~!7777777777!^:.                          #
#                     ..:^~!77777777!!~^:.             .^!777777!^.             .:^~!!77777777!~^:..                    #
#           ...::^^~!!77777777~~^^:..              .:^!777777777777!^:.              ..:^^~~77777777!!~^^::...          #
#           ...::^^~!!77777777~~^^:..              .:^!777777777777!^:.              ..:^^~~77777777!!~^^::...          #
#                     ..:^~!77777777!!~^:.             .^!777777!^.             .:^~!!77777777!~^:..                    #
#                           .:^!7777777777!~:             ^7777^             :~!7777777777!^:.                          #
#                               .:~!777777777!~:           :77:           :~!777777777!~:.                              #
#                                   .^!777777777!^.         ^^         .^!777777777!^.                                  #
#                                      :~7777777777^.       ..       .^7777777777~:                                     #
#                                        .^!77777777!^              ^!77777777!^.                                       #
#                                           :!77777777!.          .!77777777!:                                          #
#                                             :!77777777:        :77777777!:                                            #
#                                               :!7777777^      ^7777777!:                                              #
#                                                 ~777777!^    ^!777777~                                                #
#                                                  :!77777!:  :!77777!:                                                 #
#                                                   .~77777!  !77777~.                                                  #
#                                                     ^7777!::!7777^                                                    #
#                                                      ^777!~~!777^                                                     #
#                                                       ^77777777^                                                      #
#                                                        ^777777^                                                       #
#                                                         !7777!                                                        #
#                                                         .7777.                                                        #
#                                                          ~77~                                                         #
#                                                          .77.                                                         #
#                                                           !!                                                          #
#                                                           ::                                                          #
#                                                           ..                                                          #
#                                                                                                                       #
========================================================================================================================*/