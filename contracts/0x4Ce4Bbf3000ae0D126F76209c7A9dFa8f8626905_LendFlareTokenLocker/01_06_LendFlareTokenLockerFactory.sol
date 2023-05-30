// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LendFlareTokenLocker is ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public owner;
    address public token;
    uint256 public start_time;
    uint256 public end_time;

    mapping(address => uint256) public initial_locked;
    mapping(address => uint256) public total_claimed;
    mapping(address => uint256) public disabled_at;

    uint256 public initial_locked_supply;
    uint256 public unallocated_supply;

    event Fund(address indexed recipient, uint256 amount);
    event Claim(address indexed recipient, uint256 amount);
    event ToggleDisable(address recipient, bool disabled);
    event SetOwner(address owner);

    constructor(
        address _owner,
        address _token,
        uint256 _start_time,
        uint256 _end_time
    ) public {
        require(
            _start_time >= block.timestamp,
            "_start_time >= block.timestamp"
        );
        require(_end_time > _start_time, "_end_time > _start_time");

        owner = _owner;
        token = _token;
        start_time = _start_time;
        end_time = _end_time;
    }

    function setOwner(address _owner) external {
        require(
            msg.sender == owner,
            "LendFlareTokenLocker: !authorized setOwner"
        );

        owner = _owner;

        emit SetOwner(_owner);
    }

    function addTokens(uint256 _amount) public {
        require(
            msg.sender == owner,
            "LendFlareTokenLocker: !authorized addTokens"
        );

        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        unallocated_supply += _amount;
    }

    function fund(address[] memory _recipients, uint256[] memory _amounts)
        public
    {
        require(msg.sender == owner, "LendFlareTokenLocker: !authorized fund");
        require(
            _recipients.length == _amounts.length,
            "_recipients != _amounts"
        );

        uint256 _total_amount;

        for (uint256 i = 0; i < _amounts.length; i++) {
            uint256 amount = _amounts[i];
            address recipient = _recipients[i];

            if (recipient == address(0)) {
                break;
            }

            _total_amount += amount;

            initial_locked[recipient] += amount;
            emit Fund(recipient, amount);
        }

        initial_locked_supply += _total_amount;
        unallocated_supply -= _total_amount;
    }

    function toggleDisable(address _recipient) public {
        require(
            msg.sender == owner,
            "LendFlareTokenLocker: !authorized toggleDisable"
        );

        bool is_enabled = disabled_at[_recipient] == 0;

        if (is_enabled) {
            disabled_at[_recipient] = block.timestamp;
        } else {
            disabled_at[_recipient] = 0;
        }

        emit ToggleDisable(_recipient, is_enabled);
    }

    function claim() public nonReentrant {
        address recipient = msg.sender;
        uint256 t = disabled_at[recipient];

        if (t == 0) {
            t = block.timestamp;
        }

        uint256 claimable = _totalVestedOf(recipient, t) -
            total_claimed[recipient];

        total_claimed[recipient] += claimable;

        IERC20(token).safeTransfer(recipient, claimable);

        emit Claim(recipient, claimable);
    }

    function _totalVestedOf(address _recipient, uint256 _time)
        internal
        view
        returns (uint256)
    {
        if (_time == 0) _time = block.timestamp;

        uint256 locked = initial_locked[_recipient];

        if (_time < start_time) {
            return 0;
        }

        return
            min(
                (locked * (_time - start_time)) / (end_time - start_time),
                locked
            );
    }

    function vestedSupply() public view returns (uint256) {
        uint256 locked = initial_locked_supply;

        if (block.timestamp < start_time) {
            return 0;
        }

        return
            min(
                (locked * (block.timestamp - start_time)) /
                    (end_time - start_time),
                locked
            );
    }

    function lockedSupply() public view returns (uint256) {
        return initial_locked_supply - vestedSupply();
    }

    function availableOf(address _recipient) public view returns (uint256) {
        uint256 t = disabled_at[_recipient];

        if (t == 0) {
            t = block.timestamp;
        }

        return _totalVestedOf(_recipient, t) - total_claimed[_recipient];
    }

    function lockedOf(address _recipient) public view returns (uint256) {
        return
            initial_locked[_recipient] -
            _totalVestedOf(_recipient, block.timestamp);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract LendFlareTokenLockerFactory {
    uint256 public totalLockers;
    mapping(uint256 => address) public lockers;

    address public owner;

    event CreateLocker(
        uint256 indexed uniqueId,
        address indexed locker,
        string description
    );

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address _owner) external {
        require(
            msg.sender == owner,
            "LendFlareTokenLockerFactory: !authorized setOwner"
        );

        owner = _owner;
    }

    function createLocker(
        uint256 _uniqueId,
        address _token,
        uint256 _start_time,
        uint256 _end_time,
        address _owner,
        string calldata description
    ) external returns (address) {
        require(
            msg.sender == owner,
            "LendFlareTokenLockerFactory: !authorized createLocker"
        );
        require(lockers[_uniqueId] == address(0), "!_uniqueId");

        LendFlareTokenLocker locker = new LendFlareTokenLocker(
            _owner,
            _token,
            _start_time,
            _end_time
        );

        lockers[_uniqueId] = address(locker);

        totalLockers++;

        emit CreateLocker(_uniqueId, address(locker), description);
    }
}