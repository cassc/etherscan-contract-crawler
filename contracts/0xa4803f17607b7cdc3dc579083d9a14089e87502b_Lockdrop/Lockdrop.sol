/**
 *Submitted for verification at Etherscan.io on 2020-03-13
*/

pragma solidity 0.5.15;

contract Lock {
    // address owner; slot #0
    // address unlockTime; slot #1
    constructor (address owner, uint256 unlockTime) public payable {
        assembly {
            sstore(0x00, owner)
            sstore(0x01, unlockTime)
        }
    }

    /**
    * @dev        Withdraw function once timestamp has passed unlock time
    */
    function () external payable {
        assembly {
            switch gt(timestamp, sload(0x01))
            case 0 { revert(0, 0) }
            case 1 {
                switch call(gas, sload(0x00), balance(address), 0, 0, 0, 0)
                case 0 { revert(0, 0) }
            }
        }
    }
}

contract Lockdrop {
    // Time constants
    uint256 constant public LOCK_DROP_PERIOD = 30 days;
    uint256 public LOCK_START_TIME;
    uint256 public LOCK_END_TIME;

    // ETH locking events
    event Locked(uint256 indexed eth, uint256 indexed duration, address lock, address introducer);

    constructor(uint startTime) public {
        LOCK_START_TIME = startTime;
        LOCK_END_TIME = startTime + LOCK_DROP_PERIOD;
    }

    /**
     * @dev        Locks up the value sent to contract in a new Lock
     * @param      _days         The length of the lock up
     * @param      _introducer   The introducer of the user.
     */
    function lock(uint256 _days, address _introducer)
        external
        payable
        didStart
        didNotEnd
    {
        // Accept External Owned Accounts only
        require(msg.sender == tx.origin);

        // Accept only fixed set of durations
        require(_days == 30 || _days == 100 || _days == 300 || _days == 1000); 
        uint256 unlockTime = now + _days * 1 days;

        // Accept non-zero payments only
        require(msg.value > 0);
        uint256 eth = msg.value;

        // Create ETH lock contract
        Lock lockAddr = (new Lock).value(eth)(msg.sender, unlockTime);

        // ensure lock contract has all ETH, or fail
        assert(address(lockAddr).balance >= eth);

        emit Locked(eth, _days, address(lockAddr), _introducer);
    }

    /**
     * @dev        Ensures the lockdrop has started
     */
    modifier didStart() {
        require(now >= LOCK_START_TIME);
        _;
    }

    /**
     * @dev        Ensures the lockdrop has not ended
     */
    modifier didNotEnd() {
        require(now <= LOCK_END_TIME);
        _;
    }
}