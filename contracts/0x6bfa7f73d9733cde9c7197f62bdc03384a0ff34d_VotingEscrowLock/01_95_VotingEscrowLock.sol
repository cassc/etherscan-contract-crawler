//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/EnumerableMap.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";

import "../../../core/governance/Governed.sol";
import "../../../core/governance/libraries/VotingEscrowToken.sol";
import "../../../core/governance/interfaces/IVotingEscrowLock.sol";

/**
 * @dev Voting Escrow Lock is the refactored solidity implementation of veCRV.
 *      The token lock is ERC721 and transferrable.
 *      Its original code https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/VotingEscrow.vy
 */

contract VotingEscrowLock is
    IVotingEscrowLock,
    ERC721,
    ReentrancyGuard,
    Initializable,
    Governed
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    uint256 public constant override MAXTIME = 4 * (365 days);

    address private _baseToken;
    address private _veToken;
    uint256 private _totalLockedSupply;

    mapping(uint256 => Lock) private _locks;

    mapping(address => EnumerableSet.UintSet) private _delegated;
    EnumerableMap.UintToAddressMap private _rightOwners;

    string private _name;
    string private _symbol;

    modifier onlyOwner(uint256 veLockId) {
        require(
            ownerOf(veLockId) == msg.sender,
            "Only the owner can call this function"
        );
        _;
    }

    constructor() ERC721("", "") {
        // this constructor will not be called since it'll be cloned by proxy pattern.
        // initalize() will be called instead.
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address baseToken_,
        address veToken_,
        address gov_
    ) public initializer {
        _baseToken = baseToken_;
        _veToken = veToken_;
        _name = name_;
        _symbol = symbol_;
        Governed.initialize(gov_);
    }

    function updateBaseUri(string memory baseURI_) public governed {
        _setBaseURI(baseURI_);
    }

    function createLock(uint256 amount, uint256 epochs) public override {
        uint256 until = block.timestamp.add(epochs.mul(1 weeks));
        createLockUntil(amount, until);
    }

    function createLockUntil(uint256 amount, uint256 lockEnd) public override {
        require(amount > 0, "should be greater than zero");
        uint256 veLockId =
            uint256(keccak256(abi.encodePacked(block.number, msg.sender)));
        require(!_exists(veLockId), "Already exists");
        _locks[veLockId].start = block.timestamp;
        _safeMint(msg.sender, veLockId);
        _updateLock(veLockId, amount, lockEnd);
        emit LockCreated(veLockId);
    }

    function increaseAmount(uint256 veLockId, uint256 amount)
        public
        override
        onlyOwner(veLockId)
    {
        require(amount > 0, "should be greater than zero");
        uint256 newAmount = _locks[veLockId].amount.add(amount);
        _updateLock(veLockId, newAmount, _locks[veLockId].end);
    }

    function extendLock(uint256 veLockId, uint256 epochs)
        public
        override
        onlyOwner(veLockId)
    {
        uint256 until = block.timestamp.add(epochs.mul(1 weeks));
        extendLockUntil(veLockId, until);
    }

    function extendLockUntil(uint256 veLockId, uint256 end)
        public
        override
        onlyOwner(veLockId)
    {
        _updateLock(veLockId, _locks[veLockId].amount, end);
    }

    function withdraw(uint256 veLockId) public override onlyOwner(veLockId) {
        Lock memory lock = _locks[veLockId];
        require(block.timestamp >= lock.end, "Locked.");
        // transfer
        IERC20(_baseToken).safeTransfer(msg.sender, lock.amount);
        _totalLockedSupply = _totalLockedSupply.sub(lock.amount);
        VotingEscrowToken(_veToken).checkpoint(veLockId, lock, Lock(0, 0, 0));
        _locks[veLockId].amount = 0;
        emit Withdraw(veLockId, lock.amount);
    }

    function delegate(uint256 veLockId, address to)
        external
        override
        onlyOwner(veLockId)
    {
        _delegate(veLockId, to);
    }

    function baseToken() public view override returns (address) {
        return _baseToken;
    }

    function veToken() public view override returns (address) {
        return _veToken;
    }

    function totalLockedSupply() public view override returns (uint256) {
        return _totalLockedSupply;
    }

    function delegateeOf(uint256 veLockId)
        public
        view
        override
        returns (address)
    {
        if (!_exists(veLockId)) {
            return address(0);
        }
        (bool delegated, address delegatee) = _rightOwners.tryGet(veLockId);
        return delegated ? delegatee : ownerOf(veLockId);
    }

    function delegatedRights(address voter)
        public
        view
        override
        returns (uint256)
    {
        require(
            voter != address(0),
            "VotingEscrowLock: delegate query for the zero address"
        );
        return _delegated[voter].length();
    }

    function delegatedRightByIndex(address voter, uint256 idx)
        public
        view
        override
        returns (uint256 veLockId)
    {
        require(
            voter != address(0),
            "VotingEscrowLock: delegate query for the zero address"
        );
        return _delegated[voter].at(idx);
    }

    function locks(uint256 veLockId)
        public
        view
        override
        returns (
            uint256 amount,
            uint256 start,
            uint256 end
        )
    {
        Lock memory lock = _locks[veLockId];
        return (lock.amount, lock.start, lock.end);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function _updateLock(
        uint256 veLockId,
        uint256 amount,
        uint256 end
    ) internal nonReentrant {
        Lock memory prevLock = _locks[veLockId];
        Lock memory newLock =
            Lock(amount, prevLock.start, (end / 1 weeks).mul(1 weeks));
        require(_exists(veLockId), "Lock does not exist.");
        require(
            prevLock.end == 0 || prevLock.end > block.timestamp,
            "Cannot update expired. Create a new lock."
        );
        require(
            newLock.end > block.timestamp,
            "Unlock time should be in the future"
        );
        require(
            newLock.end <= block.timestamp + MAXTIME,
            "Max lock is 4 years"
        );
        require(
            !(prevLock.amount == newLock.amount && prevLock.end == newLock.end),
            "No update"
        );
        require(
            prevLock.amount <= newLock.amount,
            "new amount should be greater than before"
        );
        require(
            prevLock.end <= newLock.end,
            "new end timestamp should be greater than before"
        );

        uint256 increment = (newLock.amount - prevLock.amount); // require prevents underflow
        // 2. transfer
        if (increment > 0) {
            IERC20(_baseToken).safeTransferFrom(
                msg.sender,
                address(this),
                increment
            );
            // 3. update lock amount
            _totalLockedSupply = _totalLockedSupply.add(increment);
        }
        _locks[veLockId] = newLock;

        // 4. updateCheckpoint
        VotingEscrowToken(_veToken).checkpoint(veLockId, prevLock, newLock);
        emit LockUpdate(veLockId, amount, newLock.end);
    }

    function _delegate(uint256 veLockId, address to) internal {
        address _voter = delegateeOf(veLockId);
        _delegated[_voter].remove(veLockId);
        _delegated[to].add(veLockId);
        _rightOwners.set(veLockId, to);
        emit VoteDelegated(veLockId, to);
    }

    function _beforeTokenTransfer(
        address,
        address to,
        uint256 veLockId
    ) internal override {
        _delegate(veLockId, to);
    }
}