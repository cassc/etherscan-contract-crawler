// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./RootDB.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract ProfitRecord is ContextUpgradeable {

    /// the address of  torn ROOT_DB contract
    address immutable public ROOT_DB;
    /// the address of  torn token contract
    address immutable  public TORN_CONTRACT;


    struct PRICE_STORE {
        //weighted average price
        uint256 price;
        // amount
        uint256 amount;
    }
    // address -> PRICE_STORE  map
    mapping(address => PRICE_STORE) public profitStore;


    modifier onlyDepositContract() {
        require(msg.sender == RootDB(ROOT_DB).depositContract(), "Caller is not depositContract");
        _;
    }

    constructor(address tornContract, address rootDb) {
        TORN_CONTRACT = tornContract;
        ROOT_DB = rootDb;
    }

    function __ProfitRecord_init() public initializer {
        __Context_init();
    }


    /**
    * @notice Deposit used to record the price
             this  is called when user deposit torn to the system
    * @param  addr the user's address
    * @param  tornQty is the  the user's to deposit amount
    * @param  tokenQty is amount of voucher which the user get
      @dev    if the user Deposit more than once function will calc weighted average
   **/
    function deposit(address addr, uint256 tornQty, uint256 tokenQty) onlyDepositContract public {
        PRICE_STORE memory userStore = profitStore[addr];
        if (userStore.amount == 0) {
            uint256 new_price = tornQty * (10 ** 18) / tokenQty;
            profitStore[addr].price = new_price;
            profitStore[addr].amount = tokenQty;
        } else {
            // calc weighted average
            profitStore[addr].price = (userStore.amount * userStore.price + tornQty * (10 ** 18)) / (tokenQty + userStore.amount);
            profitStore[addr].amount = tokenQty + userStore.amount;
        }

    }

    /**
     * @notice withDraw used to clean record
             this  is called when user withDraw
     * @param  addr the user's address
     * @param  tokenQty is amount of voucher which the user want to withdraw
   **/
    function withDraw(address addr, uint256 tokenQty) onlyDepositContract public returns (uint256 profit) {
        profit = getProfit(addr, tokenQty);
        if (profitStore[addr].amount > tokenQty) {
            profitStore[addr].amount -= tokenQty;
        }
        else {
            delete profitStore[addr];
        }
    }

    /**
     * @notice getProfit used to calc profit
     * @param  addr the user's address
     * @param  tokenQty is amount of voucher which the user want to calc
     * @dev  RootDB(ROOT_DB).valueForTorn(_token_qty) only calc the torn and ignored  eth and other tokens
             so before operator swap to torn it  will been defective then we have to return profit 0
   **/
    function getProfit(address addr, uint256 tokenQty) public view returns (uint256 profit){
        PRICE_STORE memory userStore = profitStore[addr];
        require(userStore.amount >= tokenQty, "err root token");
        uint256 now_value = RootDB(ROOT_DB).valueForTorn(tokenQty);
        uint256 last_value = userStore.price * tokenQty / 10 ** 18;
        if(now_value > last_value){
            profit = now_value - last_value;
        }else{
           profit = 0;
        }
    }

}