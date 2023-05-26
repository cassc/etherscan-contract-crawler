// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { SafeMath } from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import { LibBytes } from "../libs/LibBytes.sol";
import { LibEIP712 } from "../libs/LibEIP712.sol";
import { LibPermit } from "../libs/LibPermit.sol";
import { SafeMath96 } from "../libs/SafeMath96.sol";
import { IInsuranceFund } from "../facets/interfaces/IInsuranceFund.sol";

/**
 * @title DIFundToken
 * @author DerivaDEX (Borrowed/inspired from Compound)
 * @notice This is the token contract for tokenized DerivaDEX insurance
 *         fund positions. It implements the ERC-20 standard, with
 *         additional functionality around snapshotting user and global
 *         balances.
 * @dev The contract makes use of some nonstandard types not seen in
 *      the ERC-20 standard. The DIFundToken makes frequent use of the
 *      uint96 data type, as opposed to the more standard uint256 type.
 *      Given the maintenance of arrays of balances and allowances, this
 *      allows us to more efficiently pack data together, thereby
 *      resulting in cheaper transactions.
 */
contract DIFundToken {
    using SafeMath96 for uint96;
    using SafeMath for uint256;
    using LibBytes for bytes;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;
    string private _version;
    uint8 private _decimals;

    /// @notice Address authorized to issue/mint DDX tokens
    address public issuer;

    mapping(address => mapping(address => uint96)) internal allowances;

    mapping(address => uint96) internal balances;

    /// @notice A checkpoint for marking vote count from given block
    struct Checkpoint {
        uint32 id;
        uint96 values;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint256) public numCheckpoints;

    mapping(uint256 => Checkpoint) totalCheckpoints;

    uint256 numTotalCheckpoints;

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @notice Emitted when a user account's balance changes
    event ValuesChanged(address indexed user, uint96 previousValue, uint96 newValue);

    /// @notice Emitted when a user account's balance changes
    event TotalValuesChanged(uint96 previousValue, uint96 newValue);

    /// @notice Emitted when transfer takes place
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice Emitted when approval takes place
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @notice Construct a new DIFundToken token
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address _issuer
    ) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _version = "1";

        // Set issuer to deploying address
        issuer = _issuer;
    }

    /**
     * @notice Returns the name of the token.
     * @return Name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @notice Returns the symbol of the token.
     * @return Symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     * @return Number of decimals.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
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
        require(_spender != address(0), "DIFT: approve to the zero address.");

        // Convert amount to uint96
        uint96 amount;
        if (_amount == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(_amount, "DIFT: amount exceeds 96 bits.");
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
        require(_spender != address(0), "DIFT: approve to the zero address.");

        // Convert amount to uint96
        uint96 amount;
        if (_addedValue == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(_addedValue, "DIFT: amount exceeds 96 bits.");
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
        require(_spender != address(0), "DIFT: approve to the zero address.");

        // Convert amount to uint96
        uint96 amount;
        if (_subtractedValue == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(_subtractedValue, "DIFT: amount exceeds 96 bits.");
        }

        // Decrease allowance
        allowances[msg.sender][_spender] = allowances[msg.sender][_spender].sub96(
            amount,
            "DIFT: decreased allowance below zero."
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
            amount = safe96(_amount, "DIFT: amount exceeds 96 bits.");
        }

        // Claim DDX rewards on behalf of the sender
        IInsuranceFund(issuer).claimDDXFromInsuranceMining(msg.sender);

        // Claim DDX rewards on behalf of the recipient
        IInsuranceFund(issuer).claimDDXFromInsuranceMining(_recipient);

        // Transfer tokens from sender to recipient
        _transferTokens(msg.sender, _recipient, amount);

        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param _sender The address of the source account
     * @param _recipient The address of the destination account
     * @param _amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external returns (bool) {
        uint96 spenderAllowance = allowances[_sender][msg.sender];

        // Convert amount to uint96
        uint96 amount;
        if (_amount == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(_amount, "DIFT: amount exceeds 96 bits.");
        }

        if (msg.sender != _sender && spenderAllowance != uint96(-1)) {
            // Tx sender is not the same as transfer sender and doesn't
            // have unlimited allowance.
            // Reduce allowance by amount being transferred
            uint96 newAllowance = spenderAllowance.sub96(amount);
            allowances[_sender][msg.sender] = newAllowance;

            emit Approval(_sender, msg.sender, newAllowance);
        }

        // Claim DDX rewards on behalf of the sender
        IInsuranceFund(issuer).claimDDXFromInsuranceMining(_sender);

        // Claim DDX rewards on behalf of the recipient
        IInsuranceFund(issuer).claimDDXFromInsuranceMining(_recipient);

        // Transfer tokens from sender to recipient
        _transferTokens(_sender, _recipient, amount);

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
        require(msg.sender == issuer, "DIFT: unauthorized mint.");

        // Convert amount to uint96
        uint96 amount;
        if (_amount == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(_amount, "DIFT: amount exceeds 96 bits.");
        }

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
            amount = safe96(_amount, "DIFT: amount exceeds 96 bits.");
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
            amount = safe96(_amount, "DIFT: amount exceeds 96 bits.");
        }

        if (msg.sender != _account && spenderAllowance != uint96(-1) && msg.sender != issuer) {
            // Tx sender is not the same as burn account and doesn't
            // have unlimited allowance.
            // Reduce allowance by amount being transferred
            uint96 newAllowance = spenderAllowance.sub96(amount, "DIFT: burn amount exceeds allowance.");
            allowances[_account][msg.sender] = newAllowance;

            emit Approval(_account, msg.sender, newAllowance);
        }

        // Burn tokens from account
        _transferTokensBurn(_account, amount);
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
        bytes32 eip712OrderParamsDomainHash = LibEIP712.hashEIP712Domain(_name, _version, getChainId(), address(this));
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

        require(recovered != address(0), "DIFT: invalid signature.");
        require(_nonce == nonces[recovered]++, "DIFT: invalid nonce.");
        require(block.timestamp <= _expiry, "DIFT: signature expired.");

        // Convert amount to uint96
        uint96 amount;
        if (_value == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(_value, "DIFT: amount exceeds 96 bits.");
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
     * @notice Get the total max supply of DDX tokens
     * @return The total max supply of DDX
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Determine the prior number of values for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param _account The address of the account to check
     * @param _blockNumber The block number to get the vote balance at
     * @return The number of values the account had as of the given block
     */
    function getPriorValues(address _account, uint256 _blockNumber) external view returns (uint96) {
        require(_blockNumber < block.number, "DIFT: block not yet determined.");

        uint256 numCheckpointsAccount = numCheckpoints[_account];
        if (numCheckpointsAccount == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[_account][numCheckpointsAccount - 1].id <= _blockNumber) {
            return checkpoints[_account][numCheckpointsAccount - 1].values;
        }

        // Next check implicit zero balance
        if (checkpoints[_account][0].id > _blockNumber) {
            return 0;
        }

        // Perform binary search to find the most recent token holdings
        uint256 lower = 0;
        uint256 upper = numCheckpointsAccount - 1;
        while (upper > lower) {
            // ceil, avoiding overflow
            uint256 center = upper - (upper - lower) / 2;
            Checkpoint memory cp = checkpoints[_account][center];
            if (cp.id == _blockNumber) {
                return cp.values;
            } else if (cp.id < _blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[_account][lower].values;
    }

    /**
     * @notice Determine the prior number of values for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param _blockNumber The block number to get the vote balance at
     * @return The number of values the account had as of the given block
     */
    function getTotalPriorValues(uint256 _blockNumber) external view returns (uint96) {
        require(_blockNumber < block.number, "DIFT: block not yet determined.");

        if (numTotalCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (totalCheckpoints[numTotalCheckpoints - 1].id <= _blockNumber) {
            return totalCheckpoints[numTotalCheckpoints - 1].values;
        }

        // Next check implicit zero balance
        if (totalCheckpoints[0].id > _blockNumber) {
            return 0;
        }

        // Perform binary search to find the most recent token holdings
        // leading to a measure of voting power
        uint256 lower = 0;
        uint256 upper = numTotalCheckpoints - 1;
        while (upper > lower) {
            // ceil, avoiding overflow
            uint256 center = upper - (upper - lower) / 2;
            Checkpoint memory cp = totalCheckpoints[center];
            if (cp.id == _blockNumber) {
                return cp.values;
            } else if (cp.id < _blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return totalCheckpoints[lower].values;
    }

    function _transferTokens(
        address _spender,
        address _recipient,
        uint96 _amount
    ) internal {
        require(_spender != address(0), "DIFT: cannot transfer from the zero address.");
        require(_recipient != address(0), "DIFT: cannot transfer to the zero address.");

        // Reduce spender's balance and increase recipient balance
        balances[_spender] = balances[_spender].sub96(_amount);
        balances[_recipient] = balances[_recipient].add96(_amount);
        emit Transfer(_spender, _recipient, _amount);

        // Move values from spender to recipient
        _moveTokens(_spender, _recipient, _amount);
    }

    function _transferTokensMint(address _recipient, uint96 _amount) internal {
        require(_recipient != address(0), "DIFT: cannot transfer to the zero address.");

        // Add to recipient's balance
        balances[_recipient] = balances[_recipient].add96(_amount);

        _totalSupply = _totalSupply.add(_amount);

        emit Transfer(address(0), _recipient, _amount);

        // Add value to recipient's checkpoint
        _moveTokens(address(0), _recipient, _amount);
        _writeTotalCheckpoint(_amount, true);
    }

    function _transferTokensBurn(address _spender, uint96 _amount) internal {
        require(_spender != address(0), "DIFT: cannot transfer from the zero address.");

        // Reduce the spender/burner's balance
        balances[_spender] = balances[_spender].sub96(_amount, "DIFT: not enough balance to burn.");

        // Reduce the circulating supply
        _totalSupply = _totalSupply.sub(_amount);
        emit Transfer(_spender, address(0), _amount);

        // Reduce value from spender's checkpoint
        _moveTokens(_spender, address(0), _amount);
        _writeTotalCheckpoint(_amount, false);
    }

    function _moveTokens(
        address _initUser,
        address _finUser,
        uint96 _amount
    ) internal {
        if (_initUser != _finUser && _amount > 0) {
            // Initial user address is different than final
            // user address and nonzero number of values moved
            if (_initUser != address(0)) {
                uint256 initUserNum = numCheckpoints[_initUser];

                // Retrieve and compute the old and new initial user
                // address' values
                uint96 initUserOld = initUserNum > 0 ? checkpoints[_initUser][initUserNum - 1].values : 0;
                uint96 initUserNew = initUserOld.sub96(_amount);
                _writeCheckpoint(_initUser, initUserOld, initUserNew);
            }

            if (_finUser != address(0)) {
                uint256 finUserNum = numCheckpoints[_finUser];

                // Retrieve and compute the old and new final user
                // address' values
                uint96 finUserOld = finUserNum > 0 ? checkpoints[_finUser][finUserNum - 1].values : 0;
                uint96 finUserNew = finUserOld.add96(_amount);
                _writeCheckpoint(_finUser, finUserOld, finUserNew);
            }
        }
    }

    function _writeCheckpoint(
        address _user,
        uint96 _oldValues,
        uint96 _newValues
    ) internal {
        uint32 blockNumber = safe32(block.number, "DIFT: exceeds 32 bits.");
        uint256 userNum = numCheckpoints[_user];
        if (userNum > 0 && checkpoints[_user][userNum - 1].id == blockNumber) {
            // If latest checkpoint is current block, edit in place
            checkpoints[_user][userNum - 1].values = _newValues;
        } else {
            // Create a new id, value pair
            checkpoints[_user][userNum] = Checkpoint({ id: blockNumber, values: _newValues });
            numCheckpoints[_user] = userNum.add(1);
        }

        emit ValuesChanged(_user, _oldValues, _newValues);
    }

    function _writeTotalCheckpoint(uint96 _amount, bool increase) internal {
        if (_amount > 0) {
            uint32 blockNumber = safe32(block.number, "DIFT: exceeds 32 bits.");
            uint96 oldValues = numTotalCheckpoints > 0 ? totalCheckpoints[numTotalCheckpoints - 1].values : 0;
            uint96 newValues = increase ? oldValues.add96(_amount) : oldValues.sub96(_amount);

            if (numTotalCheckpoints > 0 && totalCheckpoints[numTotalCheckpoints - 1].id == block.number) {
                // If latest checkpoint is current block, edit in place
                totalCheckpoints[numTotalCheckpoints - 1].values = newValues;
            } else {
                // Create a new id, value pair
                totalCheckpoints[numTotalCheckpoints].id = blockNumber;
                totalCheckpoints[numTotalCheckpoints].values = newValues;
                numTotalCheckpoints = numTotalCheckpoints.add(1);
            }

            emit TotalValuesChanged(oldValues, newValues);
        }
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