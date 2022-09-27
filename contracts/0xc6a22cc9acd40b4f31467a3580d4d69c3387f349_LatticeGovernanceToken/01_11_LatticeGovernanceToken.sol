//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract LatticeGovernanceToken is ERC20, Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    IERC20 private ltxToken;

    struct LockupData {
        uint256 amountLocked;
        uint256 amountReleased;
        uint256 fromTimestamp;
        uint256 toTimestamp;
        bool withdrawn;
    }

    // Total LTX Locked
    uint256 private _totalLtxLockedSupply;

    // user => Total LTX Locked
    mapping(address => uint256) private _ltxLockedBalances;

    // lockupTime => tokenPercentageReleased
    mapping(uint256 => uint256) public lockupPoints;

    // user => slots.length
    mapping(address => uint256) public lockupSlots;

    // user => (slots[index] => lockupData)
    mapping(address => mapping(uint256 => LockupData)) public lockups;

    event Locked(
        address indexed user,
        uint256 indexed lockupTime,
        uint256 indexed lockupSlot,
        uint256 amountLocked,
        uint256 amountReleased,
        uint256 timestamp
    );

    event Unlocked(
        address indexed user,
        uint256 indexed lockupSlot,
        uint256 amountUnlocked,
        uint256 amountReturned,
        uint256 timestamp
    );

    event LockupPointSet(
        uint256 indexed lockupTime,
        uint256 indexed tokenPercentageReleased
    );

    constructor(IERC20 _ltxToken) ERC20("LatticeGovernanceToken", "veLTX") {
        ltxToken = _ltxToken;
    }

    function transfer(address to, uint256 amount)
        public
        pure
        virtual
        override
        returns (bool)
    {
        revert("veLTX: The Lattice veLTX token is not transferable");
    }

    function allowance(address owner, address spender)
        public
        pure
        virtual
        override
        returns (uint256)
    {
        revert("veLTX: The Lattice veLTX token is not transferable");
    }

    function approve(address spender, uint256 amount)
        public
        pure
        virtual
        override
        returns (bool)
    {
        revert("veLTX: The Lattice veLTX token is not transferable");
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public pure virtual override returns (bool) {
        revert("veLTX: The Lattice veLTX token is not transferable");
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        pure
        virtual
        override
        returns (bool)
    {
        revert("veLTX: The Lattice veLTX token is not transferable");
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        pure
        virtual
        override
        returns (bool)
    {
        revert("veLTX: The Lattice veLTX token is not transferable");
    }

    function totalLtxLockedSupply() public view virtual returns (uint256) {
        return _totalLtxLockedSupply;
    }

    function ltxLockedBalanceOf(address account)
        public
        view
        virtual
        returns (uint256)
    {
        return _ltxLockedBalances[account];
    }

    function getUserLockups(address user, bool completed)
        public
        view
        virtual
        returns (LockupData[] memory)
    {
        uint256 _userSlots = lockupSlots[user];
        uint256 _selectedLockups = 0;

        for (uint256 i = 0; i < _userSlots; i++) {
            LockupData memory _lockup = lockups[user][i];
            if (_lockup.withdrawn == completed) {
                _selectedLockups++;
            }
        }

        LockupData[] memory _lockups = new LockupData[](_selectedLockups);
        uint256 _lockupsLength = 0;

        for (uint256 i = 0; i < _userSlots; i++) {
            LockupData memory _lockup = lockups[user][i];
            if (_lockup.withdrawn == completed) {
                _lockups[_lockupsLength] = _lockup;
                _lockupsLength++;
            }
        }

        return _lockups;
    }

    function lock(uint256 _amount, uint256 _lockupTime)
        public
        nonReentrant
        whenNotPaused
    {
        require(
            lockupPoints[_lockupTime] != 0,
            "veLTX: Lockup point does not exist"
        );

        LockupData memory _lockupData;
        _lockupData.amountLocked = _amount;
        _lockupData.amountReleased = _amount * lockupPoints[_lockupTime];
        _lockupData.fromTimestamp = block.timestamp;
        _lockupData.toTimestamp = block.timestamp + _lockupTime;
        _lockupData.withdrawn = false;

        uint256 _lockupSlot = lockupSlots[address(msg.sender)];
        lockupSlots[address(msg.sender)] = _lockupSlot + 1;

        lockups[address(msg.sender)][_lockupSlot] = _lockupData;

        ltxToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _lockupData.amountLocked
        );

        _ltxLockedBalances[msg.sender] += _amount;
        _totalLtxLockedSupply += _amount;

        _mint(address(msg.sender), _lockupData.amountReleased);

        emit Locked(
            address(msg.sender),
            _lockupTime,
            _lockupSlot,
            _lockupData.amountLocked,
            _lockupData.amountReleased,
            block.timestamp
        );
    }

    function unlock(uint256 _lockupSlot) public nonReentrant whenNotPaused {
        require(
            lockupSlots[address(msg.sender)] > _lockupSlot,
            "veLTX: Lockup slot not found"
        );

        LockupData memory _lockupData = lockups[address(msg.sender)][
            _lockupSlot
        ];

        require(!_lockupData.withdrawn, "veLTX: Lockup slot already withdrawn");

        require(
            _lockupData.toTimestamp <= block.timestamp,
            "veLTX: Lockup still in progress"
        );

        require(
            ltxToken.balanceOf(address(this)) >= _lockupData.amountLocked,
            "veLTX: Funds pool exceeds balance limit"
        );

        _burn(address(msg.sender), _lockupData.amountReleased);

        _totalLtxLockedSupply -= _lockupData.amountLocked;
        _ltxLockedBalances[msg.sender] -= _lockupData.amountLocked;

        ltxToken.safeTransfer(address(msg.sender), _lockupData.amountLocked);

        _lockupData.withdrawn = true;
        lockups[address(msg.sender)][_lockupSlot] = _lockupData;

        emit Unlocked(
            address(msg.sender),
            _lockupSlot,
            _lockupData.amountLocked,
            _lockupData.amountReleased,
            block.timestamp
        );
    }

    function setLockupPoint(
        uint256 _lockupTime,
        uint256 _tokenPercentageReleased
    ) public onlyOwner {
        setLockupPoint(_lockupTime, _tokenPercentageReleased, false);
    }

    function setLockupPoint(
        uint256 _lockupTime,
        uint256 _tokenPercentageReleased,
        bool _force
    ) public onlyOwner {
        require(
            lockupPoints[_lockupTime] == 0 || _force,
            "veLTX: Lockup point is already set"
        );

        lockupPoints[_lockupTime] = _tokenPercentageReleased;

        emit LockupPointSet(_lockupTime, _tokenPercentageReleased);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}