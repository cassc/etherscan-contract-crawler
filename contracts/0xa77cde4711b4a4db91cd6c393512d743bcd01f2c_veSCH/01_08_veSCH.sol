// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;
pragma abicoder v2;

import "./interfaces/IveSCH.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Vault.sol";
import "./interfaces/IVault.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract veSCH is IveSCH, Ownable, ReentrancyGuard {
    uint256 private id;

    uint256[5] private periods = [86400, 15778800, 31557600, 63115200, 126230400];
    uint256[5] private weights = [1, 5, 10, 20, 40];

    mapping (uint256 => address) private vaults;

    uint256 private constant lockerLimit = 99;

    uint256 private votingPower;

    address public bribes;

    struct Locker {
        uint256 id;
        address minter;
        address locker;
        uint256 created;
        uint256 unlocks;
        uint256 amount;
        bool locked;
        uint256 period;
    }

    mapping (uint256 => Locker) private lockers;
    mapping (address => Locker[]) private lockersByVoter;
    mapping (address => uint256) private lockersByVoterTotal;
    mapping (uint256 => uint256) private lockersByVoterIds;

    IERC20 private SCH;

    bool private initialized;

    constructor() {}

    function initialize(address _SCH, address _bribes) external onlyOwner {
        require(!initialized);
        initialized = true;
        SCH = IERC20(_SCH);
        for (uint256 _i = 0; _i < 5; _i++) {
            Vault _vault = new Vault(_SCH);
            vaults[_i] = address(_vault);
            SCH.approve(address(_vault), type(uint256).max);
        }
        bribes = _bribes;
    }

    function createLocker(uint256 _amount, uint256 _period) external nonReentrant returns (uint256) {
        require(initialized && _amount > 0 && (_period >= 0 && _period < 5) && lockersByVoterTotal[msg.sender] < lockerLimit);

        SCH.transferFrom(msg.sender, address(this), _amount);

        uint256 _id = id;
        id++;

        uint256 _balance = getBalances(msg.sender)[_period];

        uint256 _seconds = periods[_period];

        IVault(vaults[_period]).setBalance(msg.sender, _balance + 1);
        votingPower += _amount * weights[_period];

        Locker memory _locker = Locker(_id, msg.sender, address(0), block.timestamp, block.timestamp + _seconds, _amount, true, _period);
        lockers[_id] = _locker;
        lockersByVoter[msg.sender].push(_locker);
        lockersByVoterIds[_id] = lockersByVoterTotal[msg.sender];
        lockersByVoterTotal[msg.sender] = lockersByVoterTotal[msg.sender] + 1;

        return _id;
    }

    function claimFees(uint256 _id) external nonReentrant {
        Locker memory _locker = lockers[_id];
        require(_locker.minter == msg.sender);
        require(_locker.unlocks > block.timestamp);
        require(_locker.locked);

        _refresh(msg.sender, _locker.period, false);

        Locker memory _lockerNew = Locker(_id, _locker.minter, _locker.locker, _locker.created, _locker.unlocks, _locker.amount, _locker.locked, _locker.period);
        lockers[_id] = _lockerNew;
        lockersByVoter[msg.sender][lockersByVoterIds[_id]] = _lockerNew;
    }

    function _refresh(address _voter, uint256 _period, bool _slash) private {
        uint256[5] memory _balances = getBalances(_voter);
        uint256 _amount = IVault(vaults[_period]).claimFees(_voter);
        if (_amount > 0) {
            if (_slash) {
                uint256 _reward = _amount * 300 / 10000;
                (bool _success, ) = payable(msg.sender).call{value: _reward}("");
                require(_success);
                (_success, ) = payable(_voter).call{value: _amount - _reward}("");
                require(_success);
            } else {
                (bool _success, ) = payable(_voter).call{value: _amount}("");
                require(_success);
            }
        }
        IVault(vaults[_period]).setBalance(_voter, _balances[_period]);
    }

    function _unlockSCH(uint256 _id, bool _slash) private {
        Locker memory _locker = lockers[_id];
        require(_locker.unlocks <= block.timestamp && _locker.locked);
        _refresh(_locker.minter, _locker.period, _slash);
        uint256 _amount = _locker.amount;
        SCH.transfer(_locker.minter, _amount);
        Locker memory _lockerNew = Locker(_id, _locker.minter, msg.sender, _locker.created, _locker.unlocks, _amount, false, _locker.period);
        lockers[_id] = _lockerNew;
        lockersByVoter[_locker.minter][lockersByVoterIds[_id]] = _lockerNew;
        votingPower -= _amount * weights[_locker.period];
    }

    function unlockSCH(uint256 _id) external nonReentrant {
        require(lockers[_id].minter == msg.sender);
        _unlockSCH(_id, false);
    }

    function slashLocker(uint256 _id) external nonReentrant {
        Locker memory _locker = lockers[_id];
        require(_locker.unlocks <= block.timestamp && _locker.locked);
        _unlockSCH(_id, true);
    }

    function depositFees(uint256 _amount, uint256 _period) external payable nonReentrant {
        require(bribes == msg.sender);
        require(_period >= 0 && _period < 5);
        require(msg.value == _amount);
        (bool _success, ) = payable(vaults[_period]).call{value: _amount}("");
        if (_success) {
            IVault(vaults[_period]).deposit(_amount);
        }
    }

    function getVotingPowerTotal() external view returns (uint256) {
        return votingPower;
    }

    function getVotingPower(address _voter) external view returns (uint256) {
        uint256 _votingPower;
        uint256 _matches = lockersByVoterTotal[_voter];
        Locker[] memory _array = lockersByVoter[_voter];
        for (uint256 _i = 0; _i < _matches; _i++) {
            if (_array[_i].locked && _array[_i].unlocks > block.timestamp) _votingPower += _array[_i].amount * weights[_array[_i].period];
        }
        return _votingPower;
    }

    function getLocker(uint256 _id) external view returns (Locker memory) {
        return lockers[_id];
    }

    function getLockersByVoter(address _voter) external view returns (Locker[] memory) {
        return lockersByVoter[_voter];
    }

    function getLockersByVoterTotal(address _voter) external view returns (uint256) {
        return lockersByVoterTotal[_voter];
    }

    function getVaultContract(uint256 _period) external view returns (address) {
        return (vaults[periods[_period]]);
    }

    function getAllVaultContracts() external view returns (address, address, address, address, address) {
        return (vaults[periods[0]], vaults[periods[1]], vaults[periods[2]], vaults[periods[3]], vaults[periods[4]]);
    }

    function getBalances(address _voter) public view returns (uint[5] memory) {
        uint256[5] memory _balances;
        uint256 _matches = lockersByVoterTotal[_voter];
        Locker[] memory _array = lockersByVoter[_voter];
        for (uint256 _i = 0; _i < _matches; _i++) {
            if (_array[_i].locked && _array[_i].unlocks > block.timestamp) _balances[_array[_i].period] = _balances[_array[_i].period] + 1;
        }
        return _balances;
    }

    receive() external payable {}
}