// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol';

import '../libs/GluwacoinModels.sol';
import '../libs/Validate.sol';
import './SignerNonce.sol';

contract EthlessReservable is ERC20Upgradeable, SignerNonce {
    enum ReservationStatus {
        Active,
        Reclaimed,
        Completed
    }

    struct Reservation {
        uint256 _amount;
        uint256 _fee;
        address _recipient;
        address _executor;
        uint256 _startBlockNum;
        uint256 _expiryBlockNum;
        ReservationStatus _status;
    }

    struct RsvCheckpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    // Total amount of reserved balance for address
    mapping(address => uint256) private _totalReserved;

    // Address mapping to mapping of nonce to amount and expiry for that nonce.
    mapping(address => mapping(uint256 => Reservation)) private _reserved;

    // Address mapping to RsvCheckpoint of reservations to calculate tokens reserved at a given block number.
    mapping(address => RsvCheckpoint[]) private _checkpoints;

    /**
     * @dev Allow a account to reserve tokens of a account that allow it via ERC191 signature and collect fee
     */
    function reserve(
        address sender,
        address recipient,
        address executor,
        uint256 amount,
        uint256 fee,
        uint256 gluwaNonce,
        uint256 expiryBlockNum,
        bytes memory sig
    ) external virtual returns (bool success) {
        require(executor != address(0), 'EthlessReservable: cannot execute from zero address');
        require(expiryBlockNum > block.number, 'EthlessReservable: invalid block expiry number');
        _useNonce(sender, gluwaNonce);

        bytes32 hash = keccak256(
            abi.encodePacked(
                GluwacoinModels.SigDomain.Reserve,
                block.chainid,
                address(this),
                sender,
                recipient,
                executor,
                amount,
                fee,
                gluwaNonce,
                expiryBlockNum
            )
        );
        Validate.validateSignature(hash, sender, sig);
        return _reserve(sender, recipient, executor, amount, fee, gluwaNonce, expiryBlockNum);
    }

    /**
     * @dev Return a reservation for a sender and nonce.
     */
    function getReservation(address sender, uint256 gluwaNonce)
        public
        view
        virtual
        returns (
            uint256 amount,
            uint256 fee,
            address recipient,
            address executor,
            uint256 expiryBlockNum,
            ReservationStatus status
        )
    {
        unchecked {
            Reservation memory reservation = _reserved[sender][gluwaNonce];

            amount = reservation._amount;
            fee = reservation._fee;
            recipient = reservation._recipient;
            executor = reservation._executor;
            expiryBlockNum = reservation._expiryBlockNum;
            status = reservation._status;
        }
    }

    /**
     * @dev Returns the amount of tokens owned by `account` deducted by the reserved amount.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _unreservedBalance(account);
    }

    /**
     * @dev Returns the total amount of tokens reserved from `account`.
     */
    function reservedOf(address account) public view virtual returns (uint256 amount) {
        return _totalReserved[account];
    }

    /**
     * @dev Internal function for reserving tokens.
     */
    function _reserve(
        address sender,
        address recipient,
        address executor,
        uint256 amount,
        uint256 fee,
        uint256 gluwaNonce,
        uint256 expiryBlockNum
    ) private returns (bool success) {
        require(_reserved[sender][gluwaNonce]._expiryBlockNum == 0, 'EthlessReservable: the sender used the nonce already');
        require(amount >= 0, 'EthlessReservable: invalid reserve amount');
        uint256 total;
        unchecked {
            total = amount + fee;
            require(_unreservedBalance(sender) >= total, 'EthlessReservable: insufficient unreserved balance');

            _reserved[sender][gluwaNonce] = Reservation(amount, fee, recipient, executor, block.number, expiryBlockNum, ReservationStatus.Active);
            _totalReserved[sender] += total;
        }

        _writeRsvCheckpoint(_checkpoints[sender], _addRsv, total);
        return true;
    }

    /**
     * @dev Execute a reservation defined by the sender and nonce.
     */
    function execute(address sender, uint256 gluwaNonce) external virtual returns (bool success) {
        unchecked {
            Reservation storage reservation = _reserved[sender][gluwaNonce];
            require(reservation._expiryBlockNum != 0, 'Reserveable: reservation does not exist');
            require(reservation._executor == _msgSender() || sender == _msgSender(), 'Reserveable: this address is not authorized to execute this reservation');
            require(reservation._expiryBlockNum > block.number, 'Reserveable: reservation has expired and cannot be executed');
            require(reservation._status == ReservationStatus.Active, 'Reserveable: invalid reservation status to execute');

            reservation._status = ReservationStatus.Completed;
            _totalReserved[sender] -= (reservation._amount + reservation._fee);

            _writeRsvCheckpoint(_checkpoints[sender], _subtractRsv, (reservation._amount + reservation._fee));
            _transfer(sender, reservation._executor, reservation._fee);
            _transfer(sender, reservation._recipient, reservation._amount);
            return true;
        }
    }

    /**
     * @dev Reclaim (cancel) a reservation defined by the sender and nonce, if the reservation is not executed and expired, or the caller is the executor or the sender.
     */
    function reclaim(address sender, uint256 gluwaNonce) external returns (bool success) {
        unchecked {
            Reservation storage reservation = _reserved[sender][gluwaNonce];

            require(reservation._expiryBlockNum != 0, 'Reserveable: reservation does not exist');
            require(reservation._status == ReservationStatus.Active, 'Reserveable: invalid reservation status to reclaim');
            if (_msgSender() != reservation._executor) {
                require(_msgSender() == sender, 'Reserveable: only the sender or the executor can reclaim the reservation back to the sender');
                require(
                    reservation._expiryBlockNum <= block.number,
                    'Reserveable: reservation has not expired or you are not the executor and cannot be reclaimed'
                );
            }

            reservation._status = ReservationStatus.Reclaimed;
            _totalReserved[sender] -= (reservation._amount + reservation._fee);

            _writeRsvCheckpoint(_checkpoints[sender], _subtractRsv, (reservation._amount + reservation._fee));
            return true;
        }
    }

    /**
     * @dev Internal function to return the total reserved at a specific block number.
     */
    function _pastReservedOf(address account, uint256 blockNumber) internal view virtual returns (uint256 totalReserved) {
        RsvCheckpoint[] storage ckpts = _checkpoints[account];
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.
        uint256 high = ckpts.length;
        uint256 low;
        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : ckpts[high - 1].votes;
    }

    /**
     * @dev Internal function to return the unreserved balance of an address.
     */
    function _unreservedBalance(address account) internal view virtual returns (uint256) {
        return ERC20Upgradeable.balanceOf(account) - _totalReserved[account];        
    }

    /**
     * @dev Internal function to validate the current unreserved balance of an address is higher than the amount.
     */
    function _checkUnreservedBalance(address from, uint256 amount) internal view virtual {
        if (from != address(0)) {
            require(_unreservedBalance(from) >= amount, 'Reserveable: transfer amount exceeds unreserved balance');
        }
    }

    function _writeRsvCheckpoint(
        RsvCheckpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].votes = SafeCastUpgradeable.toUint224(newWeight);
        } else {
            ckpts.push(RsvCheckpoint({ fromBlock: SafeCastUpgradeable.toUint32(block.number), votes: SafeCastUpgradeable.toUint224(newWeight) }));
        }
    }

    function _addRsv(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtractRsv(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}