// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 */
contract MoneyHandler is Context, AccessControl{
    using SafeMath for uint256;

    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);
    
    IERC20 private token;
    // uint256 public _totalShares;
    uint256 public _totalReleased;
   // uint256 public amu = 1;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    mapping(address => uint256) public collectionMoney;

    address[] private _payees;
    uint256 private _totalCllcAmnt;
    
    bytes32 public constant COLLECTION_ROLE = bytes32(keccak256("COLLECTION_ROLE"));


    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
     
    /**
     * @dev Getter for the total shares held by payees.
     */
    // function totalShares() public view returns (uint256) {
    //     return _totalShares;
    // }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    function collecMny(address collection) public view returns (uint256) {
        return collectionMoney[collection];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    function updateCollecMny(address collection, uint256 amount) public onlyRole(COLLECTION_ROLE) {
        collectionMoney[collection] = collectionMoney[collection].add(amount);
    }
    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address account, address collection, address _token) private  {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        _released[account] = _released[account].add(_shares[account]);
        _totalReleased = _totalReleased.add(_shares[account]);

        IERC20 token = IERC20(_token);
        token.transfer(account, _shares[account]);
        
        collectionMoney[collection] = collectionMoney[collection].sub(_shares[account]);

        emit PaymentReleased(account, _shares[account]);
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * // shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 sharePerc_, address collection, address _token) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");


        
        uint256 shares_ = getAmountPer(_totalCllcAmnt,sharePerc_);
        _shares[account] = shares_;
        _payees.push(account);

        release(account, collection, _token);
       // emit PayeeAdded(account, shares_);
    }

    //Get amount per person
    function getAmountPer(uint256 totalAmount,uint256 sharePerc) private pure returns(uint256){
        uint256 sharesmul_ = SafeMath.mul(totalAmount,sharePerc);
        uint256 shares_ = SafeMath.div(sharesmul_,10**18);
        return shares_;
    }
    
      function recoverToken(address _token)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {   
      
        uint amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, amount);
    }
   
    function redeem (address collection, address _token, address[] memory payees, uint256 [] memory sharePerc_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(payees.length > 0, "redeem: no payees");
        require(payees.length == sharePerc_.length, "redeem: no payees");

        _totalCllcAmnt = collectionMoney[collection];

        require(_totalCllcAmnt > 0,"redeem: insufficient funds");
        
        uint256 totalShareAmount;
    
        for (uint256 i = 0; i < sharePerc_.length; i++) {

             totalShareAmount = totalShareAmount.add(getAmountPer(_totalCllcAmnt, sharePerc_[i]));
        }
        
        require(_totalCllcAmnt >= totalShareAmount, "redeem: the total amount in the contract must be equal to or greater than the amount to be withdraw"); 

        for (uint256 i = 0; i < payees.length; i++) {
            
            _addPayee(payees[i], sharePerc_[i], collection, _token);
        }
    }
}