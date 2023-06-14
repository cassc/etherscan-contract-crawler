// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { SafeMath } from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import { LibBytes } from "../libs/LibBytes.sol";
import { LibEIP712 } from "../libs/LibEIP712.sol";
import { LibDelegation } from "../libs/LibDelegation.sol";
import { LibPermit } from "../libs/LibPermit.sol";
import { SafeMath96 } from "../libs/SafeMath96.sol";

/**
 * @title DDX
 * @author DerivaDEX (Borrowed/inspired from Compound)
 * @notice This is the native token contract for DerivaDEX. It
 *         implements the ERC-20 standard, with additional
 *         functionality to efficiently handle the governance aspect of
 *         the DerivaDEX ecosystem.
 * @dev The contract makes use of some nonstandard types not seen in
 *      the ERC-20 standard. The DDX token makes frequent use of the
 *      uint96 data type, as opposed to the more standard uint256 type.
 *      Given the maintenance of arrays of balances, allowances, and
 *      voting checkpoints, this allows us to more efficiently pack
 *      data together, thereby resulting in cheaper transactions.
 */
contract DDX {
    using SafeMath96 for uint96;
    using SafeMath for uint256;
    using LibBytes for bytes;

    /// @notice ERC20 token name for this token
    string public constant name = "DerivaDAO"; // solhint-disable-line const-name-snakecase

    /// @notice ERC20 token symbol for this token
    string public constant symbol = "DDX"; // solhint-disable-line const-name-snakecase

    /// @notice ERC20 token decimals for this token
    uint8 public constant decimals = 18; // solhint-disable-line const-name-snakecase

    /// @notice Version number for this token. Used for EIP712 hashing.
    string public constant version = "1"; // solhint-disable-line const-name-snakecase

    /// @notice Max number of tokens to be issued (100 million DDX)
    uint96 public constant MAX_SUPPLY = 100000000e18;

    /// @notice Total number of tokens in circulation (50 million DDX)
    uint96 public constant PRE_MINE_SUPPLY = 50000000e18;

    /// @notice Issued supply of tokens
    uint96 public issuedSupply;

    /// @notice Current total/circulating supply of tokens
    uint96 public totalSupply;

    /// @notice Whether ownership has been transferred to the DAO
    bool public ownershipTransferred;

    /// @notice Address authorized to issue/mint DDX tokens
    address public issuer;

    mapping(address => mapping(address => uint96)) internal allowances;

    mapping(address => uint96) internal balances;

    /// @notice A record of each accounts delegate
    mapping(address => address) public delegates;

    /// @notice A checkpoint for marking vote count from given block
    struct Checkpoint {
        uint32 id;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint256) public numCheckpoints;

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @notice Emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice Emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint96 previousBalance, uint96 newBalance);

    /// @notice Emitted when transfer takes place
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice Emitted when approval takes place
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @notice Construct a new DDX token
     */
    constructor() public {
        // Set issuer to deploying address
        issuer = msg.sender;

        // Issue pre-mine token supply to deploying address and
        // set the issued and circulating supplies to pre-mine amount
        _transferTokensMint(msg.sender, PRE_MINE_SUPPLY);
    }

    /**
     * @notice Transfer ownership of DDX token from the deploying
     *         address to the DerivaDEX Proxy/DAO
     * @param _derivaDEXProxy DerivaDEX Proxy address
     */
    function transferOwnershipToDerivaDEXProxy(address _derivaDEXProxy) external {
        // Ensure deploying address is calling this, destination is not
        // the zero address, and that ownership has never been
        // transferred thus far
        require(msg.sender == issuer, "DDX: unauthorized transfer of ownership.");
        require(_derivaDEXProxy != address(0), "DDX: transferring to zero address.");
        require(!ownershipTransferred, "DDX: ownership already transferred.");

        // Set ownership transferred boolean flag and the new authorized
        // issuer
        ownershipTransferred = true;
        issuer = _derivaDEXProxy;
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param _spender The address of the account which may transfer tokens
     * @param _amount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address _spender, uint256 _amount) external returns (bool) {
        require(_spender != address(0), "DDX: approve to the zero address.");

        // Convert amount to uint96
        uint96 amount;
        if (_amount == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(_amount, "DDX: amount exceeds 96 bits.");
        }

        // Set allowance
        allowances[msg.sender][_spender] = amount;

        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     * Emits an {Approval} event indicating the updated allowance.
     * Requirements:
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool) {
        require(_spender != address(0), "DDX: approve to the zero address.");

        // Convert amount to uint96
        uint96 amount;
        if (_addedValue == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(_addedValue, "DDX: amount exceeds 96 bits.");
        }

        // Increase allowance
        allowances[msg.sender][_spender] = allowances[msg.sender][_spender].add96(amount);

        emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     * Emits an {Approval} event indicating the updated allowance.
     * Requirements:
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool) {
        require(_spender != address(0), "DDX: approve to the zero address.");

        // Convert amount to uint96
        uint96 amount;
        if (_subtractedValue == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(_subtractedValue, "DDX: amount exceeds 96 bits.");
        }

        // Decrease allowance
        allowances[msg.sender][_spender] = allowances[msg.sender][_spender].sub96(
            amount,
            "DDX: decreased allowance below zero."
        );

        emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param _account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address _account) external view returns (uint256) {
        return balances[_account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param _recipient The address of the destination account
     * @param _amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address _recipient, uint256 _amount) external returns (bool) {
        // Convert amount to uint96
        uint96 amount;
        if (_amount == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(_amount, "DDX: amount exceeds 96 bits.");
        }

        // Transfer tokens from sender to recipient
        _transferTokens(msg.sender, _recipient, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param _from The address of the source account
     * @param _recipient The address of the destination account
     * @param _amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address _from,
        address _recipient,
        uint256 _amount
    ) external returns (bool) {
        uint96 spenderAllowance = allowances[_from][msg.sender];

        // Convert amount to uint96
        uint96 amount;
        if (_amount == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(_amount, "DDX: amount exceeds 96 bits.");
        }

        if (msg.sender != _from && spenderAllowance != uint96(-1)) {
            // Tx sender is not the same as transfer sender and doesn't
            // have unlimited allowance.
            // Reduce allowance by amount being transferred
            uint96 newAllowance = spenderAllowance.sub96(amount);
            allowances[_from][msg.sender] = newAllowance;

            emit Approval(_from, msg.sender, newAllowance);
        }

        // Transfer tokens from sender to recipient
        _transferTokens(_from, _recipient, amount);
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     *      the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function mint(address _recipient, uint256 _amount) external {
        require(msg.sender == issuer, "DDX: unauthorized mint.");

        // Convert amount to uint96
        uint96 amount;
        if (_amount == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(_amount, "DDX: amount exceeds 96 bits.");
        }

        // Ensure the mint doesn't cause the issued supply to exceed
        // the total supply that could ever be issued
        require(issuedSupply.add96(amount) <= MAX_SUPPLY, "DDX: cap exceeded.");

        // Mint tokens to recipient
        _transferTokensMint(_recipient, amount);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, decreasing
     *      the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function burn(uint256 _amount) external {
        // Convert amount to uint96
        uint96 amount;
        if (_amount == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(_amount, "DDX: amount exceeds 96 bits.");
        }

        // Burn tokens from sender
        _transferTokensBurn(msg.sender, amount);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     *      the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function burnFrom(address _account, uint256 _amount) external {
        uint96 spenderAllowance = allowances[_account][msg.sender];

        // Convert amount to uint96
        uint96 amount;
        if (_amount == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(_amount, "DDX: amount exceeds 96 bits.");
        }

        if (msg.sender != _account && spenderAllowance != uint96(-1)) {
            // Tx sender is not the same as burn account and doesn't
            // have unlimited allowance.
            // Reduce allowance by amount being transferred
            uint96 newAllowance = spenderAllowance.sub96(amount, "DDX: burn amount exceeds allowance.");
            allowances[_account][msg.sender] = newAllowance;

            emit Approval(_account, msg.sender, newAllowance);
        }

        // Burn tokens from account
        _transferTokensBurn(_account, amount);
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param _delegatee The address to delegate votes to
     */
    function delegate(address _delegatee) external {
        _delegate(msg.sender, _delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param _delegatee The address to delegate votes to
     * @param _nonce The contract state required to match the signature
     * @param _expiry The time at which to expire the signature
     * @param _signature Signature
     */
    function delegateBySig(
        address _delegatee,
        uint256 _nonce,
        uint256 _expiry,
        bytes memory _signature
    ) external {
        // Perform EIP712 hashing logic
        bytes32 eip712OrderParamsDomainHash = LibEIP712.hashEIP712Domain(name, version, getChainId(), address(this));
        bytes32 delegationHash =
            LibDelegation.getDelegationHash(
                LibDelegation.Delegation({ delegatee: _delegatee, nonce: _nonce, expiry: _expiry }),
                eip712OrderParamsDomainHash
            );

        // Perform sig recovery
        uint8 v = uint8(_signature[0]);
        bytes32 r = _signature.readBytes32(1);
        bytes32 s = _signature.readBytes32(33);
        address recovered = ecrecover(delegationHash, v, r, s);

        require(recovered != address(0), "DDX: invalid signature.");
        require(_nonce == nonces[recovered]++, "DDX: invalid nonce.");
        require(block.timestamp <= _expiry, "DDX: signature expired.");

        // Delegate votes from recovered address to delegatee
        _delegate(recovered, _delegatee);
    }

    /**
     * @notice Permits allowance from signatory to `spender`
     * @param _spender The spender being approved
     * @param _value The value being approved
     * @param _nonce The contract state required to match the signature
     * @param _expiry The time at which to expire the signature
     * @param _signature Signature
     */
    function permit(
        address _spender,
        uint256 _value,
        uint256 _nonce,
        uint256 _expiry,
        bytes memory _signature
    ) external {
        // Perform EIP712 hashing logic
        bytes32 eip712OrderParamsDomainHash = LibEIP712.hashEIP712Domain(name, version, getChainId(), address(this));
        bytes32 permitHash =
            LibPermit.getPermitHash(
                LibPermit.Permit({ spender: _spender, value: _value, nonce: _nonce, expiry: _expiry }),
                eip712OrderParamsDomainHash
            );

        // Perform sig recovery
        uint8 v = uint8(_signature[0]);
        bytes32 r = _signature.readBytes32(1);
        bytes32 s = _signature.readBytes32(33);

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }

        address recovered = ecrecover(permitHash, v, r, s);

        require(recovered != address(0), "DDX: invalid signature.");
        require(_nonce == nonces[recovered]++, "DDX: invalid nonce.");
        require(block.timestamp <= _expiry, "DDX: signature expired.");

        // Convert amount to uint96
        uint96 amount;
        if (_value == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(_value, "DDX: amount exceeds 96 bits.");
        }

        // Set allowance
        allowances[recovered][_spender] = amount;
        emit Approval(recovered, _spender, _value);
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param _account The address of the account holding the funds
     * @param _spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address _account, address _spender) external view returns (uint256) {
        return allowances[_account][_spender];
    }

    /**
     * @notice Gets the current votes balance.
     * @param _account The address to get votes balance.
     * @return The number of current votes.
     */
    function getCurrentVotes(address _account) external view returns (uint96) {
        uint256 numCheckpointsAccount = numCheckpoints[_account];
        return numCheckpointsAccount > 0 ? checkpoints[_account][numCheckpointsAccount - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param _account The address of the account to check
     * @param _blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address _account, uint256 _blockNumber) external view returns (uint96) {
        require(_blockNumber < block.number, "DDX: block not yet determined.");

        uint256 numCheckpointsAccount = numCheckpoints[_account];
        if (numCheckpointsAccount == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[_account][numCheckpointsAccount - 1].id <= _blockNumber) {
            return checkpoints[_account][numCheckpointsAccount - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[_account][0].id > _blockNumber) {
            return 0;
        }

        // Perform binary search to find the most recent token holdings
        // leading to a measure of voting power
        uint256 lower = 0;
        uint256 upper = numCheckpointsAccount - 1;
        while (upper > lower) {
            // ceil, avoiding overflow
            uint256 center = upper - (upper - lower) / 2;
            Checkpoint memory cp = checkpoints[_account][center];
            if (cp.id == _blockNumber) {
                return cp.votes;
            } else if (cp.id < _blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[_account][lower].votes;
    }

    function _delegate(address _delegator, address _delegatee) internal {
        // Get the current address delegator has delegated
        address currentDelegate = _getDelegatee(_delegator);

        // Get delegator's DDX balance
        uint96 delegatorBalance = balances[_delegator];

        // Set delegator's new delegatee address
        delegates[_delegator] = _delegatee;

        emit DelegateChanged(_delegator, currentDelegate, _delegatee);

        // Move votes from currently-delegated address to
        // new address
        _moveDelegates(currentDelegate, _delegatee, delegatorBalance);
    }

    function _transferTokens(
        address _spender,
        address _recipient,
        uint96 _amount
    ) internal {
        require(_spender != address(0), "DDX: cannot transfer from the zero address.");
        require(_recipient != address(0), "DDX: cannot transfer to the zero address.");

        // Reduce spender's balance and increase recipient balance
        balances[_spender] = balances[_spender].sub96(_amount);
        balances[_recipient] = balances[_recipient].add96(_amount);
        emit Transfer(_spender, _recipient, _amount);

        // Move votes from currently-delegated address to
        // recipient's delegated address
        _moveDelegates(_getDelegatee(_spender), _getDelegatee(_recipient), _amount);
    }

    function _transferTokensMint(address _recipient, uint96 _amount) internal {
        require(_recipient != address(0), "DDX: cannot transfer to the zero address.");

        // Add to recipient's balance
        balances[_recipient] = balances[_recipient].add96(_amount);

        // Increase the issued supply and circulating supply
        issuedSupply = issuedSupply.add96(_amount);
        totalSupply = totalSupply.add96(_amount);

        emit Transfer(address(0), _recipient, _amount);

        // Add delegates to recipient's delegated address
        _moveDelegates(address(0), _getDelegatee(_recipient), _amount);
    }

    function _transferTokensBurn(address _spender, uint96 _amount) internal {
        require(_spender != address(0), "DDX: cannot transfer from the zero address.");

        // Reduce the spender/burner's balance
        balances[_spender] = balances[_spender].sub96(_amount, "DDX: not enough balance to burn.");

        // Reduce the total supply
        totalSupply = totalSupply.sub96(_amount);
        emit Transfer(_spender, address(0), _amount);

        // MRedduce delegates from spender's delegated address
        _moveDelegates(_getDelegatee(_spender), address(0), _amount);
    }

    function _moveDelegates(
        address _initDel,
        address _finDel,
        uint96 _amount
    ) internal {
        if (_initDel != _finDel && _amount > 0) {
            // Initial delegated address is different than final
            // delegated address and nonzero number of votes moved
            if (_initDel != address(0)) {
                uint256 initDelNum = numCheckpoints[_initDel];

                // Retrieve and compute the old and new initial delegate
                // address' votes
                uint96 initDelOld = initDelNum > 0 ? checkpoints[_initDel][initDelNum - 1].votes : 0;
                uint96 initDelNew = initDelOld.sub96(_amount);
                _writeCheckpoint(_initDel, initDelOld, initDelNew);
            }

            if (_finDel != address(0)) {
                uint256 finDelNum = numCheckpoints[_finDel];

                // Retrieve and compute the old and new final delegate
                // address' votes
                uint96 finDelOld = finDelNum > 0 ? checkpoints[_finDel][finDelNum - 1].votes : 0;
                uint96 finDelNew = finDelOld.add96(_amount);
                _writeCheckpoint(_finDel, finDelOld, finDelNew);
            }
        }
    }

    function _writeCheckpoint(
        address _delegatee,
        uint96 _oldVotes,
        uint96 _newVotes
    ) internal {
        uint32 blockNumber = safe32(block.number, "DDX: exceeds 32 bits.");
        uint256 delNum = numCheckpoints[_delegatee];
        if (delNum > 0 && checkpoints[_delegatee][delNum - 1].id == blockNumber) {
            // If latest checkpoint is current block, edit in place
            checkpoints[_delegatee][delNum - 1].votes = _newVotes;
        } else {
            // Create a new id, vote pair
            checkpoints[_delegatee][delNum] = Checkpoint({ id: blockNumber, votes: _newVotes });
            numCheckpoints[_delegatee] = delNum.add(1);
        }

        emit DelegateVotesChanged(_delegatee, _oldVotes, _newVotes);
    }

    function _getDelegatee(address _delegator) internal view returns (address) {
        if (delegates[_delegator] == address(0)) {
            return _delegator;
        }
        return delegates[_delegator];
    }

    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint256 n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}