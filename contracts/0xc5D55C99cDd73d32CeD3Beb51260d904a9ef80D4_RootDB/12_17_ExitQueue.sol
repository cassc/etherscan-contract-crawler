// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./RootDB.sol";
import "./Deposit.sol";

/**
 * @title ExitQueue for Relayers DAO
 * @notice this is a simple queue for user exit when  liquidity shortage is not enough.
     1. inorder to save gas the code is not easy to understand ,it need same patience
     2. if preparedIndex >= addr2index[user_address] , it indicate the TORN is prepared
     3. in the waiting ,user can cancel his waiting
     4. user at most  add one withdraw in the queue
 */

contract ExitQueue is ReentrancyGuardUpgradeable {


    struct QUEUE_INFO {
        //
        /* @notice  the value of user in the queue
             the QUEUE_INFO.v when it is not prepared which stored is the value of voucher of the deposit
             after prepared, the v stored is the value of TORN what will been claimed.
        */
        uint256 v;
        // the address of user in the queue
        address addr;
    }
    /// the address of  torn ROOT_DB contract
    address immutable public ROOT_DB;
    /// the address of  torn token contract
    address immutable  public TORN_CONTRACT;

    /// the prepared index in the queue   @notice begin with 0
    uint256 public preparedIndex = 0;

    /// the max index of user in the queue
    /** @dev this variable will inc when user added a withdraw in the queue
     *       the NO. will never decrease
       @notice  begin with 0
     **/
    uint256 public maxIndex = 0;

    // address -> index  map
    mapping(address => uint256) public addr2index;
    // index -> queue_info map
    mapping(uint256 => QUEUE_INFO) public index2value;

    uint256 constant public  INDEX_ERR = 2 ** 256 - 1;
    uint256 constant public  MAX_QUEUE_CANCEL = 100;

    /// @notice An event emitted when user cancel queue
    /// @param  account The: address of user
    /// @param  tokenQty: voucher of the deposit canceled
    event CancelQueue(address account, uint256 tokenQty);

    /// @notice An event emitted when user add queue
    /// @param  account The: address of user
    /// @param  tokenQty: voucher of the deposit canceled
    event AddQueue(address  account,uint256 tokenQty);

    function __ExitQueue_init() public initializer {
        __ReentrancyGuard_init();
    }


    constructor(address tornContract, address rootDb) {
        TORN_CONTRACT = tornContract;
        ROOT_DB = rootDb;
    }

    /**
    * @notice because of cancel ,it will been some blank in the queue
      call this function to get the counter of  blank in the queue
      return
           1. the number of blanks
           2. INDEX_ERR  the he number of blanks is over MAX_QUEUE_CANCEL
   **/
    function nextSkipIndex() view public returns (uint256){

        uint256 temp_maxIndex = maxIndex;
        // save gas
        uint256 temp_preparedIndex = preparedIndex;
        // save gas

        uint256 next_index = 0;
        uint256 index;
        if (temp_maxIndex <= temp_preparedIndex) {
            return 0;
        }
        // MAX_QUEUE_CANCEL avoid out of gas
        for (index = 1; index < MAX_QUEUE_CANCEL; index++) {
            next_index = temp_preparedIndex + index;
            uint256 next_value = index2value[next_index].v;
            if (temp_maxIndex == next_index || next_value > 0) {
                return index;
            }
        }
        return INDEX_ERR;
    }


    // to avoid out of gas everyone would call this function to update the index
    // those codes are not elegant code ,is any better way?
    function UpdateSkipIndex() public nonReentrant {
        uint256 next_index = nextSkipIndex();
        require(next_index == INDEX_ERR, "skip is too short");
        // skip the index
        preparedIndex = preparedIndex + MAX_QUEUE_CANCEL -1;
    }

    /**
    * @notice addQueue
    * @param  tokenQty: the amount of voucher
   **/
    function addQueue(uint256 tokenQty) public nonReentrant {
        maxIndex += 1;
        require(tokenQty > 0, "error para");
        require(addr2index[msg.sender] == 0 && index2value[maxIndex].v == 0, "have pending");
        addr2index[msg.sender] = maxIndex;
        index2value[maxIndex] = QUEUE_INFO(tokenQty, msg.sender);
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(ROOT_DB), msg.sender, address(this), tokenQty);
        emit AddQueue(msg.sender, tokenQty);
    }

    /**
    * @notice cancelQueue
   **/
    function cancelQueue() external nonReentrant {
        uint256 index = addr2index[msg.sender];
        uint256 value = index2value[index].v;
        require(value > 0, "empty");
        require(index > preparedIndex, "prepared");
        delete addr2index[msg.sender];
        delete index2value[index];
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(ROOT_DB), msg.sender, value);
        emit CancelQueue(msg.sender, value);
    }
    /**
    * @notice when there are enough TORN call this function
              the user waiting status would change to  prepared
   **/
    function executeQueue() external nonReentrant {
        address deposit_addr = RootDB(ROOT_DB).depositContract();
        uint256 value = 0;
        require(maxIndex >= preparedIndex + 1, "no pending");
        uint256 next = nextSkipIndex();
        require(INDEX_ERR != next, "too many skips");
        preparedIndex += next;
        QUEUE_INFO memory info = index2value[preparedIndex];
        value = Deposit(deposit_addr).withdraw_for_exit(info.addr, info.v);
        index2value[preparedIndex].v = value;
    }

    /**
        * @notice get the next user in queue waiting's TORN
   **/
    function nextValue() view external returns (uint256 value) {
        uint256 next = nextSkipIndex();
        if (next == 0) {
            return 0;
        }
        require(INDEX_ERR != next, "too many skips");

        // avoid the last one had canceled;
        uint256 next_value = index2value[preparedIndex + next].v;
        if (next_value == 0)
        {
            return 0;
        }

        return RootDB(ROOT_DB).valueForTorn(next_value);
    }

    /**
    * @notice when the TORN is prepared call this function to claim
   **/
    function claim() external nonReentrant {
        uint256 index = addr2index[msg.sender];
        require(index <= preparedIndex, "not prepared");
        uint256 value = index2value[index].v;
        require(value > 0, "have no pending");
        delete addr2index[msg.sender];
        delete index2value[index];
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(TORN_CONTRACT), msg.sender, value);
    }

    /**
     * @notice get the queue infomation
     return
              v : the amount of voucher if  prepared == false  else the amount of TORN which can be claim
       prepared : prepared == true show that the TORN is prepared to claim
    **/
    function getQueueInfo(address _addr) view public returns (uint256 v, bool prepared){
        uint256 index = addr2index[_addr];
        v = index2value[index].v;
        prepared = preparedIndex >= index;
    }
}