// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    @dev AB: OZ override
    @dev Modification scope: getVotes, getPastVotes, delegate, delegateBySig
    @dev Modification scope (internal): _delegate, _transferVotingUnits, _moveDelegateVotes, _getVotingUnits
    @dev Modification scope (storage): _delegateCheckpoints
    @dev Added to the scope: ERC165 and supportsInterface

    ------------------------------

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

 **************************************/

// OZ Upgrades imports
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { CountersUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import { ECDSAUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

// OpenZeppelin imports
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

// Local OZ override
import { CheckpointsUpgradeable } from "./utils/CheckpointsUpgradeable.sol";
import { IVotesUpgradeable } from "./interfaces/IVotesUpgradeable.sol";

/**
 * @dev This is a base abstract contract that tracks voting units, which are a measure of voting power that can be
 * transferred, and provides a system of vote delegation, where an account can delegate its voting units to a sort of
 * "representative" that will pool delegated voting units from different accounts and can then use it to vote in
 * decisions. In fact, voting units _must_ be delegated in order to count as actual votes, and an account has to
 * delegate those votes to itself if it wishes to participate in decisions and does not have a trusted representative.
 *
 * This contract is often combined with a token contract such that voting units correspond to token units. For an
 * example, see {ERC721Votes}.
 *
 * The full history of delegate votes is tracked on-chain so that governance protocols can consider votes as distributed
 * at a particular block number to protect against flash loans and double voting. The opt-in delegate system makes the
 * cost of this history tracking optional.
 *
 * When using this module the derived contract must implement {_getVotingUnits} (for example, make it return
 * {ERC721-balanceOf}), and can use {_transferVotingUnits} to track a change in the distribution of those units (in the
 * previous example, it would be included in {ERC721-_beforeTokenTransfer}).
 *
 * _Available since v4.5._
 */
abstract contract VotesUpgradeable is Initializable, IVotesUpgradeable, ContextUpgradeable, EIP712Upgradeable, ERC165 {
    function __Votes_init() internal onlyInitializing {
    }

    function __Votes_init_unchained() internal onlyInitializing {
    }
    using CheckpointsUpgradeable for CheckpointsUpgradeable.History;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) private _delegation;
    mapping(address => mapping (bytes => CheckpointsUpgradeable.History)) private _delegateCheckpoints; // @dev AB: Changed to contain data
    CheckpointsUpgradeable.History private _totalCheckpoints;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(IVotesUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**************************************

        @notice Override of OZ getVotes

        ------------------------------

        @dev AB: added data arg
        @dev Example usage for ERC20: empty (value: 0x0)
        @dev Example usage for ERC1155: tokenId (type: bytes<uint256>)

        ------------------------------

        @param account Account that voted
        @param data Bytes encoding optional parameters

     **************************************/

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account, bytes memory data) public view virtual override
    returns (uint256) {
        return _delegateCheckpoints[account][data].latest();
    }

    /**************************************

        @notice Override of OZ getPastVotes

        ------------------------------

        @dev AB: added data arg
        @dev Example usage for ERC20: empty (value: 0x0)
        @dev Example usage for ERC1155: tokenId (type: bytes<uint256>)

        ------------------------------

        @param account Account that voted
        @param blockNumber number of block snapshot
        @param data Bytes encoding optional parameters

     **************************************/

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(address account, uint256 blockNumber, bytes memory data) public view virtual override
    returns (uint256) {
        return _delegateCheckpoints[account][data].getAtBlock(blockNumber);
    }

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "Votes: block not yet mined");
        return _totalCheckpoints.getAtBlock(blockNumber);
    }

    /**
     * @dev Returns the current total supply of votes.
     */
    function _getTotalSupply() internal view virtual returns (uint256) {
        return _totalCheckpoints.latest();
    }

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) public view virtual override returns (address) {
        return _delegation[account];
    }

    /**************************************

        @notice Override of OZ delegate

        ------------------------------

        @dev AB: added data arg
        @dev Example usage for ERC20: empty (value: 0x0)
        @dev Example usage for ERC1155: tokenId (type: bytes<uint256>)

        ------------------------------

        @param delegatee Account receiving delegation
        @param data Bytes encoding optional parameters

     **************************************/

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee, bytes memory data) public virtual override {
        address account = _msgSender();
        _delegate(account, delegatee, data);
    }

    /**************************************

        @notice Override of OZ delegateBySig

        ------------------------------

        @dev AB: added data arg
        @dev Example usage for ERC20: empty (value: 0x0)
        @dev Example usage for ERC1155: tokenId (type: bytes<uint256>)
        @dev Extended signature vrs to contain data

        ------------------------------

        @param delegatee Account receiving delegation
        @param nonce Number used once
        @param expiry Expiration timestamp
        @param v Part of signature
        @param r Part of signature
        @param s Part of signature
        @param data Bytes encoding optional parameters

     **************************************/

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        bytes memory data,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= expiry, "Votes: signature expired");
        address signer = ECDSAUpgradeable.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry, data))),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "Votes: invalid nonce");
        _delegate(signer, delegatee, data);
    }

    /**************************************

        @notice Override of OZ _delegate

        ------------------------------

        @dev AB: added data arg
        @dev AB: added custom validation for account, delegatee and data
        @dev Example usage for ERC20: empty (value: 0x0)
        @dev Example usage for ERC1155: tokenId (type: bytes<uint256>)

        ------------------------------

        @param account Account sending delegation
        @param delegatee Account receiving delegation
        @param data Bytes encoding optional parameters

     **************************************/

    /**
     * @dev Delegate all of `account`'s voting units to `delegatee`.
     *
     * Emits events {DelegateChanged} and {DelegateVotesChanged}.
     */

    function _delegate(address account, address delegatee, bytes memory data) internal virtual {

        // validate account and delegatee
        if (account == address(0) || delegatee == address(0)) revert CannotDelegateAddressZero();

        // revert if empty data
        if (data.length == 0) revert EmptyDataNotSupported();

        // decode
        (
            uint256 tokenId
        ) = abi.decode(
            data,
            (
                uint256
            )
        );

        // revert if incorrect token id
        if (tokenId < 1) revert DataDoesNotContainValidTokenId();

        // update delegatee
        address oldDelegate = delegates(account);
        _delegation[account] = delegatee;

        // emit and move votes
        emit DelegateChanged(account, oldDelegate, delegatee);
        _moveDelegateVotes(oldDelegate, delegatee, _getVotingUnits(account, data), data);

    }

    /**************************************

        @notice Override of OZ _transferVotingUnits

        ------------------------------

        @dev AB: added data arg
        @dev Example usage for ERC20: empty (value: 0x0)
        @dev Example usage for ERC1155: tokenId (type: bytes<uint256>)

        ------------------------------

        @param from Account sending voting units
        @param to Account receiving voting units
        @param amount Number of transferred voting units
        @param data Bytes encoding optional parameters

     **************************************/

    /**
     * @dev Transfers, mints, or burns voting units. To register a mint, `from` should be zero. To register a burn, `to`
     * should be zero. Total supply of voting units will be adjusted with mints and burns.
     */
    function _transferVotingUnits(
        address from,
        address to,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (from == address(0)) {
            _totalCheckpoints.push(_add, amount);
        }
        if (to == address(0)) {
            _totalCheckpoints.push(_subtract, amount);
        }
        _moveDelegateVotes(delegates(from), delegates(to), amount, data);
    }

    /**************************************

        @notice Override of OZ _moveDelegateVotes

        ------------------------------

        @dev AB: added data arg
        @dev Example usage for ERC20: empty (value: 0x0)
        @dev Example usage for ERC1155: tokenId (type: bytes<uint256>)

        ------------------------------

        @param from Account sending delegated votes
        @param to Account receiving delegated votes
        @param amount Number of transferred delegated votes
        @param data Bytes encoding optional parameters

     **************************************/

    /**
     * @dev Moves delegated votes from one delegate to another.
     */
    function _moveDelegateVotes(
        address from,
        address to,
        uint256 amount,
        bytes memory data
    ) private {
        if (from != to && amount > 0) {
            if (from != address(0)) {
                (uint256 oldValue, uint256 newValue) = _delegateCheckpoints[from][data].push(_subtract, amount);
                emit DelegateVotesChanged(from, oldValue, newValue);
            }
            if (to != address(0)) {
                (uint256 oldValue, uint256 newValue) = _delegateCheckpoints[to][data].push(_add, amount);
                emit DelegateVotesChanged(to, oldValue, newValue);
            }
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Consumes a nonce.
     *
     * Returns the current value and increments nonce.
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }

    /**
     * @dev Returns an address nonce.
     */
    function nonces(address owner) public view virtual returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev Returns the contract's {EIP712} domain separator.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**************************************

        @notice Override of OZ _getVotingUnits

        ------------------------------

        @dev AB: added data arg
        @dev Example usage for ERC20: empty (value: 0x0)
        @dev Example usage for ERC1155: tokenId (type: bytes<uint256>)

        ------------------------------

        @param account Account with voting units
        @param data Bytes encoding optional parameters

     **************************************/

    /**
     * @dev Must return the voting units held by an account.
     */
    function _getVotingUnits(address, bytes memory) internal view virtual returns (uint256);

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}