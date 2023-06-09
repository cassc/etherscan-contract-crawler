// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2020 Gemini Trust Company LLC. All Rights Reserved
pragma solidity ^0.7.0;

import "./CustodianUpgradeable.sol";
import "./ERC20Proxy.sol";
import "./ERC20Store.sol";

/** @title  ERC20 compliant token intermediary contract holding core logic.
  *
  * @notice  This contract serves as an intermediary between the exposed ERC20
  * interface in ERC20Proxy and the store of balances in ERC20Store. This
  * contract contains core logic that the proxy can delegate to
  * and that the store is called by.
  *
  * @dev  This contract contains the core logic to implement the
  * ERC20 specification as well as several extensions.
  * 1. Changes to the token supply.
  * 2. Batched transfers.
  * 3. Relative changes to spending approvals.
  * 4. Delegated transfer control ('sweeping').
  *
  * @author  Gemini Trust Company, LLC
  */
contract ERC20Impl is CustodianUpgradeable {

    // TYPES
    /// @dev  The struct type for pending increases to the token supply (print).
    struct PendingPrint {
        address receiver;
        uint256 value;
        bytes32 merkleRoot;
    }

    // MEMBERS
    /// @dev  The reference to the proxy.
    ERC20Proxy immutable public erc20Proxy;

    /// @dev  The reference to the store.
    ERC20Store immutable public erc20Store;

    address immutable public implOwner;

    /// @dev  The map of lock ids to pending token increases.
    mapping (bytes32 => PendingPrint) public pendingPrintMap;

    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    bytes32 private immutable _PERMIT_TYPEHASH;


    // CONSTRUCTOR
    constructor(
          address _erc20Proxy,
          address _erc20Store,
          address _custodian,
          address _implOwner
    )
        CustodianUpgradeable(_custodian)
    {
        erc20Proxy = ERC20Proxy(_erc20Proxy);
        erc20Store = ERC20Store(_erc20Store);
        implOwner = _implOwner;

        bytes32 hashedName = keccak256(bytes(ERC20Proxy(_erc20Proxy).name()));
        bytes32 hashedVersion = keccak256(bytes("1"));
        bytes32 typeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"); 
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = _getChainId();
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion, _erc20Proxy);
        _TYPE_HASH = typeHash;

        _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    }

    // MODIFIERS
    modifier onlyProxy {
        require(msg.sender == address(erc20Proxy), "unauthorized");
        _;
    }

    modifier onlyImplOwner {
        require(msg.sender == implOwner, "unauthorized");
        _;
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    )
        private
    {
        require(_spender != address(0), "zero address"); // disallow unspendable approvals
        erc20Store.setAllowance(_owner, _spender, _amount);
        erc20Proxy.emitApproval(_owner, _spender, _amount);
    }

    /** @notice  Core logic of the ERC20 `approve` function.
      *
      * @dev  This function can only be called by the referenced proxy,
      * which has an `approve` function.
      * Every argument passed to that function as well as the original
      * `msg.sender` gets passed to this function.
      * NOTE: approvals for the zero address (unspendable) are disallowed.
      *
      * @param  _sender  The address initiating the approval in proxy.
      */
    function approveWithSender(
        address _sender,
        address _spender,
        uint256 _value
    )
        external
        onlyProxy
        returns (bool success)
    {
        _approve(_sender, _spender, _value);
        return true;
    }

    /** @notice  Core logic of the `increaseApproval` function.
      *
      * @dev  This function can only be called by the referenced proxy,
      * which has an `increaseApproval` function.
      * Every argument passed to that function as well as the original
      * `msg.sender` gets passed to this function.
      * NOTE: approvals for the zero address (unspendable) are disallowed.
      *
      * @param  _sender  The address initiating the approval.
      */
    function increaseApprovalWithSender(
        address _sender,
        address _spender,
        uint256 _addedValue
    )
        external
        onlyProxy
        returns (bool success)
    {
        require(_spender != address(0), "zero address"); // disallow unspendable approvals
        uint256 currentAllowance = erc20Store.allowed(_sender, _spender);
        uint256 newAllowance = currentAllowance + _addedValue;

        require(newAllowance >= currentAllowance, "overflow");

        erc20Store.setAllowance(_sender, _spender, newAllowance);
        erc20Proxy.emitApproval(_sender, _spender, newAllowance);
        return true;
    }

    /** @notice  Core logic of the `decreaseApproval` function.
      *
      * @dev  This function can only be called by the referenced proxy,
      * which has a `decreaseApproval` function.
      * Every argument passed to that function as well as the original
      * `msg.sender` gets passed to this function.
      * NOTE: approvals for the zero address (unspendable) are disallowed.
      *
      * @param  _sender  The address initiating the approval.
      */
    function decreaseApprovalWithSender(
        address _sender,
        address _spender,
        uint256 _subtractedValue
    )
        external
        onlyProxy
        returns (bool success)
    {
        require(_spender != address(0), "zero address"); // disallow unspendable approvals
        uint256 currentAllowance = erc20Store.allowed(_sender, _spender);
        uint256 newAllowance = currentAllowance - _subtractedValue;

        require(newAllowance <= currentAllowance, "overflow");

        erc20Store.setAllowance(_sender, _spender, newAllowance);
        erc20Proxy.emitApproval(_sender, _spender, newAllowance);
        return true;
    }

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(owner != address(0x0), "zero address");
        require(block.timestamp <= deadline, "expired");

        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                erc20Store.getNonceAndIncrement(owner),
                deadline
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparatorV4(),
                structHash
            )
        );

        address signer = ecrecover(hash, v, r, s);
        require(signer == owner, "invalid signature");

        _approve(owner, spender, value);
    }
    function nonces(address owner) external view returns (uint256) {
      return erc20Store.nonces(owner);
    }
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
      return _domainSeparatorV4();
    }

    /** @notice  Requests an increase in the token supply, with the newly created
      * tokens to be added to the balance of the specified account.
      *
      * @dev  Returns a unique lock id associated with the request.
      * Anyone can call this function, but confirming the request is authorized
      * by the custodian.
      * NOTE: printing to the zero address is disallowed.
      *
      * @param  _receiver  The receiving address of the print, if confirmed.
      * @param  _value  The number of tokens to add to the total supply and the
      * balance of the receiving address, if confirmed.
      *
      * @return  lockId  A unique identifier for this request.
      */
    function requestPrint(address _receiver, uint256 _value, bytes32 _merkleRoot) external returns (bytes32 lockId) {
        require(_receiver != address(0), "zero address");

        (bytes32 preLockId, uint256 lockRequestIdx) = generatePreLockId();
        lockId = keccak256(
            abi.encodePacked(
                preLockId,
                this.requestPrint.selector,
                _receiver,
                _value,
                _merkleRoot
            )
        );

        pendingPrintMap[lockId] = PendingPrint({
            receiver: _receiver,
            value: _value,
            merkleRoot: _merkleRoot
        });

        emit PrintingLocked(lockId, _receiver, _value, lockRequestIdx);
    }

    function _executePrint(address _receiver, uint256 _value, bytes32 _merkleRoot) private {
        uint256 supply = erc20Store.totalSupply();
        uint256 newSupply = supply + _value;
        if (newSupply >= supply) {
          erc20Store.setTotalSupplyAndAddBalance(newSupply, _receiver, _value);

          erc20Proxy.emitTransfer(address(0), _receiver, _value);
          emit AuditPrint(_merkleRoot);
        }
    }

    function executePrint(address _receiver, uint256 _value, bytes32 _merkleRoot) external onlyCustodian {
        _executePrint(_receiver, _value, _merkleRoot);
    }

    /** @notice  Confirms a pending increase in the token supply.
      *
      * @dev  When called by the custodian with a lock id associated with a
      * pending increase, the amount requested to be printed in the print request
      * is printed to the receiving address specified in that same request.
      * NOTE: this function will not execute any print that would overflow the
      * total supply, but it will not revert either.
      *
      * @param  _lockId  The identifier of a pending print request.
      */
    function confirmPrint(bytes32 _lockId) external onlyCustodian {
        PendingPrint storage print = pendingPrintMap[_lockId];

        // reject ‘null’ results from the map lookup
        // this can only be the case if an unknown `_lockId` is received
        address receiver = print.receiver;
        require (receiver != address(0), "no such lockId");
        uint256 value = print.value;
        bytes32 merkleRoot = print.merkleRoot;

        delete pendingPrintMap[_lockId];

        emit PrintingConfirmed(_lockId, receiver, value);
        _executePrint(receiver, value, merkleRoot);
    }

    /** @notice  Burns the specified value from the sender's balance.
      *
      * @dev  Sender's balanced is subtracted by the amount they wish to burn.
      *
      * @param  _value  The amount to burn.
      *
      * @return  success  true if the burn succeeded.
      */
    function burn(uint256 _value, bytes32 _merkleRoot) external returns (bool success) {
        uint256 balanceOfSender = erc20Store.balances(msg.sender);
        require(_value <= balanceOfSender, "insufficient balance");

        erc20Store.setBalanceAndDecreaseTotalSupply(
            msg.sender,
            balanceOfSender - _value,
            _value
        );

        erc20Proxy.emitTransfer(msg.sender, address(0), _value);
        emit AuditBurn(_merkleRoot);

        return true;
    }

    /** @notice  A function for a sender to issue multiple transfers to multiple
      * different addresses at once. This function is implemented for gas
      * considerations when someone wishes to transfer, as one transaction is
      * cheaper than issuing several distinct individual `transfer` transactions.
      *
      * @dev  By specifying a set of destination addresses and values, the
      * sender can issue one transaction to transfer multiple amounts to
      * distinct addresses, rather than issuing each as a separate
      * transaction. The `_tos` and `_values` arrays must be equal length, and
      * an index in one array corresponds to the same index in the other array
      * (e.g. `_tos[0]` will receive `_values[0]`, `_tos[1]` will receive
      * `_values[1]`, and so on.)
      * NOTE: transfers to the zero address are disallowed.
      *
      * @param  _tos  The destination addresses to receive the transfers.
      * @param  _values  The values for each destination address.
      * @return  success  If transfers succeeded.
      */
    function batchTransfer(address[] calldata _tos, uint256[] calldata _values) external returns (bool success) {
        require(_tos.length == _values.length, "inconsistent length");

        uint256 numTransfers = _tos.length;
        uint256 senderBalance = erc20Store.balances(msg.sender);

        for (uint256 i = 0; i < numTransfers; i++) {
          address to = _tos[i];
          require(to != address(0), "zero address");
          uint256 v = _values[i];
          require(senderBalance >= v, "insufficient balance");

          if (msg.sender != to) {
            senderBalance -= v;
            erc20Store.addBalance(to, v);
          }
          erc20Proxy.emitTransfer(msg.sender, to, v);
        }

        erc20Store.setBalance(msg.sender, senderBalance);

        return true;
    }

    /** @notice  Core logic of the ERC20 `transferFrom` function.
      *
      * @dev  This function can only be called by the referenced proxy,
      * which has a `transferFrom` function.
      * Every argument passed to that function as well as the original
      * `msg.sender` gets passed to this function.
      * NOTE: transfers to the zero address are disallowed.
      *
      * @param  _sender  The address initiating the transfer in proxy.
      */
    function transferFromWithSender(
        address _sender,
        address _from,
        address _to,
        uint256 _value
    )
        external
        onlyProxy
        returns (bool success)
    {
        require(_to != address(0), "zero address"); // ensure burn is the cannonical transfer to 0x0

        (uint256 balanceOfFrom, uint256 senderAllowance) = erc20Store.balanceAndAllowed(_from, _sender);
        require(_value <= balanceOfFrom, "insufficient balance");
        require(_value <= senderAllowance, "insufficient allowance");

        erc20Store.setBalanceAndAllowanceAndAddBalance(
            _from, balanceOfFrom - _value,
            _sender, senderAllowance - _value,
            _to, _value
        );

        erc20Proxy.emitTransfer(_from, _to, _value);

        return true;
    }

    /** @notice  Core logic of the ERC20 `transfer` function.
      *
      * @dev  This function can only be called by the referenced proxy,
      * which has a `transfer` function.
      * Every argument passed to that function as well as the original
      * `msg.sender` gets passed to this function.
      * NOTE: transfers to the zero address are disallowed.
      *
      * @param  _sender  The address initiating the transfer in proxy.
      */
    function transferWithSender(
        address _sender,
        address _to,
        uint256 _value
    )
        external
        onlyProxy
        returns (bool success)
    {
        require(_to != address(0), "zero address"); // ensure burn is the cannonical transfer to 0x0

        uint256 balanceOfSender = erc20Store.balances(_sender);
        require(_value <= balanceOfSender, "insufficient balance");

        erc20Store.setBalanceAndAddBalance(
            _sender, balanceOfSender - _value,
            _to, _value
        );

        erc20Proxy.emitTransfer(_sender, _to, _value);

        return true;
    }

    // METHODS (ERC20 sub interface impl.)
    /// @notice  Core logic of the ERC20 `totalSupply` function.
    function totalSupply() external view returns (uint256) {
        return erc20Store.totalSupply();
    }

    /// @notice  Core logic of the ERC20 `balanceOf` function.
    function balanceOf(address _owner) external view returns (uint256 balance) {
        return erc20Store.balances(_owner);
    }

    /// @notice  Core logic of the ERC20 `allowance` function.
    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        return erc20Store.allowed(_owner, _spender);
    }

    function executeCallInProxy(
        address contractAddress,
        bytes calldata callData
    ) external onlyImplOwner {
        erc20Proxy.executeCallWithData(contractAddress, callData);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() private view returns (bytes32) {
        if (_getChainId() == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION, address(erc20Proxy));
        }
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version, address verifyingContract) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                _getChainId(),
                verifyingContract
            )
        );
    }

    function _getChainId() private view returns (uint256 chainId) {
        // SEE:
        //   - https://github.com/ethereum/solidity/issues/8854#issuecomment-629436203
        //   - https://github.com/ethereum/solidity/issues/10090
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }

    // EVENTS
    /// @dev  Emitted by successful `requestPrint` calls.
    event PrintingLocked(bytes32 _lockId, address _receiver, uint256 _value, uint256 _lockRequestIdx);
    /// @dev Emitted by successful `confirmPrint` calls.
    event PrintingConfirmed(bytes32 _lockId, address _receiver, uint256 _value);

    event AuditBurn(bytes32 merkleRoot);
    event AuditPrint(bytes32 merkleRoot);
}