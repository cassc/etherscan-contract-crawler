/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// todo function delete payee and set shares. OORRR assign the new array to old, i.e. overwrite

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../token/ERC20/IERC20.sol";
import "../utils/Address.sol";

/*************************************************************
 * @title PaymentSplitter                                    *
 *                                                           *
 * @notice This contract allows to split Ether payments      *
 * among a group of accounts. The sender does not need to    *
 * be aware that the Ether will be split in this way, since  *
 * it is handled transparently by the contract.              *
 *                                                           *
 * @dev The split can be in equal parts or in any other      *
 * arbitrary proportion. The distribution of shares is set   *
 * at the time ofcontract deployment, but can also be        *
 * updated, unlike the OZ `PaymentSplitter` contract.        *
 * `PaymentSplitter` follows a _push payment_ model, i.e.    *
 * that payments are automatically forwarded to the accounts.*
 * Does not support ERC20 tokens.                            *
 *                                                           *
 * @custom:security-contact [email protected]                    *
 *************************************************************/
contract PaymentSplitter {
    address private immutable _factory;
    // _owner is used for access control in setter functions.
    // Can only be set when initializing contract; the token seller can chose to which address to send funds, therefore they are the only ones who should control this contract.
    address private _owner; // todo is there an equivalent to `immutable` keyword for proxies that can't use the constructor?
    uint256 private _totalShares;

    mapping(address => uint256) private _shares;

    uint256 public gasLeft;
    uint256 public initialGas;

    address[] private _payees;
    // todo enumerablemap?
    // or two arrays of same length

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    /**
     * @dev equivalent to `initializer` modifier but cheaper because the clones won't need to write `initialized = true;` to storage each time
     * @dev only called in the master copy, never in clones
     * @dev todo hardcode a constant factory address preferibly and remove constructor.
     * @dev I.e. deploy factory first, then deploy master contract with harcoded address, then use a setter function in factory contract to set the master address
     */
    constructor(address factory_) {
        _factory = factory_;
    }

    /**
     * @dev Creates an instance of `PaymentSplitter` where each _account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     * @dev  _accounts and shares length MUST match and there should be more than one payee address, e.g. 'require( _accounts.length > 1 ? _accounts.length == shares_.length : false)'
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     * @param _data _totalShares saves having increment _totalShares at each loop like so: `_totalShares += shares_`. Instead assigns the total value to `_totalShares` directly once the loop is finished.

     */
    function initialize(bytes calldata _data) external {
        require(msg.sender == _factory);

        address[] memory accounts_;
        uint256[] memory shares_;

        (accounts_, shares_, _totalShares, _owner) = abi.decode(
            _data,
            (address[], uint256[], uint256, address)
        );

        // _owner = msg.sender; // there is no parameter currently for allowing to set the contract _owner to a different address, doesn't seem very useful

        // Storing `_payees.length` in memory may not be a massive gas saving (if not more expensive?) compared to looking it up in every loop of a for-loop, as the arrays are stored in memory
        uint256 i = accounts_.length;
        // using `do...while` loop instead of `while` because we know that the arrays must have at least one element, i.e. we save some gas by not checking the condition on the first loop
        // the caller can only be `_owner` address and therefore it is unnecessary to verify it.
        do {
            // ++i costs less gas compared to i++ or i += 1
            // decrement first because the `length` property is the array elements count, i.e. a starts at 0, i.e. index = length - 1
            --i;
            _payees.push(accounts_[i]);
            _shares[accounts_[i]] = shares_[i];
        } while (i > 0);
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * TODO do we need to use this.balanceOf instead of msg.value? in case ether is sent via selfdestruct for example, otherwise there would be no other way to withdraw such ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable {
        for (uint256 i; i < _payees.length; i++) {
            address account = _payees[i];
            uint256 payment = (msg.value * _shares[account]) / _totalShares;
            Address.sendValue(payable(account), payment);
        }
    }

    /**
     * @notice function to change one or more existing payees, i.e. only the shares receiver account(s), not the shares amount(s)
     * @param totalShares_ is the value that `_totalShares` should be after calling this function.
     +        This avoids calculating the total's difference inside of the function's code, which would be very expensive.
     *
     * MUST:
     *
     * - `_index` MUST be less or equal to `_shares.length - 1`.
     *
     * SHOULD:
     *
     *   - `require(payees[index] != address(0));` i.e. must overwrite an existing account at the specified array index, else `_shares[_account]` will be 0 by default as not initialized.
     *   - `_payees[_index]` must be different from `_account` otherwise the change will have no effect and waste gas
     *   - `_account` should not exist in the array already, else the entire shares calculation may be affected and the duplicated account will be paid twice.
     *   - array arguments `_index` and `_account` must have the same length (number of array items), or else the function may revert with an "index out of bounds" error
     */
    function setSharesAndPayees(
        address[] calldata _accounts,
        uint256[] calldata shares_,
        uint256 totalShares_
    ) external onlyOwner {
        uint256 i = _accounts.length;

        do {
            --i; // ++i costs less gas compared to i++ or i += 1, decrement first because the `length` property is the array elements count, i.e. a starts at 0, i.e. index = length - 1
            _shares[_accounts[i]] = shares_[i];
        } while (i > 0); // using `do...while` loop instead of `while` because we know that the arrays must have at least one element, i.e. we save some gas by not checking the condition on the first loop

        _payees = _accounts;

        _totalShares = totalShares_;
    }

    /***************************
     * External View Functions *
     **************************/

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() external view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the amount of shares held by an _account.
     */
    function shares(address _account) external view returns (uint256) {
        return _shares[_account];
    }

    function payee(uint256 _index) external view returns (address) {
        return _payees[_index];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function getSplitterSettings()
        external
        view
        returns (address[] memory, uint256[] memory, uint256)
    {
        uint256 i = _payees.length;
        uint256[] memory shares_ = new uint256[](i);
        do {
            --i;
            shares_[i] = _shares[_payees[i]];
        } while (i > 0);
        return (_payees, shares_, _totalShares);
    }

    function deleteSplitter() external onlyOwner {
        selfdestruct(payable(_owner));
    }
}