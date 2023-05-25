// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/ERC1363Spec.sol";
import "../interfaces/EIP2612.sol";
import "../interfaces/EIP3009.sol";
import "../utils/AccessControl.sol";
import "../lib/AddressUtils.sol";
import "../lib/ECDSA.sol";

/**
 * @title Artificial Liquid Intelligence ERC20 Token (Alethea, ALI)
 *
 * @notice ALI is the native utility token of the Alethea AI Protocol.
 *      It serves as protocol currency, participates in iNFTs lifecycle,
 *      (locked when iNFT is created, released when iNFT is destroyed,
 *      consumed when iNFT is upgraded).
 *      ALI token powers up the governance protocol (Alethea DAO)
 *
 * @notice Token Summary:
 *      - Symbol: ALI
 *      - Name: Artificial Liquid Intelligence Token
 *      - Decimals: 18
 *      - Initial/maximum total supply: 10,000,000,000 ALI
 *      - Initial supply holder (initial holder) address: // TODO: [DEFINE]
 *      - Not mintable: new tokens cannot be created
 *      - Burnable: existing tokens may get destroyed, total supply may decrease
 *      - DAO Support: supports voting delegation
 *
 * @notice Features Summary:
 *      - Supports atomic allowance modification, resolves well-known ERC20 issue with approve (arXiv:1907.00903)
 *      - Voting delegation and delegation on behalf via EIP-712 (like in Compound CMP token) - gives ALI token
 *        powerful governance capabilities by allowing holders to form voting groups by electing delegates
 *      - Unlimited approval feature (like in 0x ZRX token) - saves gas for transfers on behalf
 *        by eliminating the need to update “unlimited” allowance value
 *      - ERC-1363 Payable Token - ERC721-like callback execution mechanism for transfers,
 *        transfers on behalf and approvals; allows creation of smart contracts capable of executing callbacks
 *        in response to transfer or approval in a single transaction
 *      - EIP-2612: permit - 712-signed approvals - improves user experience by allowing to use a token
 *        without having an ETH to pay gas fees
 *      - EIP-3009: Transfer With Authorization - improves user experience by allowing to use a token
 *        without having an ETH to pay gas fees
 *
 * @dev Even though smart contract has mint() function which is used to mint initial token supply,
 *      the function is disabled forever after smart contract deployment by revoking `TOKEN_CREATOR`
 *      permission from the deployer account
 *
 * @dev Token balances and total supply are effectively 192 bits long, meaning that maximum
 *      possible total supply smart contract is able to track is 2^192 (close to 10^40 tokens)
 *
 * @dev Smart contract doesn't use safe math. All arithmetic operations are overflow/underflow safe.
 *      Additionally, Solidity 0.8.7 enforces overflow/underflow safety.
 *
 * @dev Multiple Withdrawal Attack on ERC20 Tokens (arXiv:1907.00903) - resolved
 *      Related events and functions are marked with "arXiv:1907.00903" tag:
 *        - event Transfer(address indexed _by, address indexed _from, address indexed _to, uint256 _value)
 *        - event Approve(address indexed _owner, address indexed _spender, uint256 _oldValue, uint256 _value)
 *        - function increaseAllowance(address _spender, uint256 _value) public returns (bool)
 *        - function decreaseAllowance(address _spender, uint256 _value) public returns (bool)
 *      See: https://arxiv.org/abs/1907.00903v1
 *           https://ieeexplore.ieee.org/document/8802438
 *      See: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
 *
 * @dev Reviewed
 *      ERC-20   - according to https://eips.ethereum.org/EIPS/eip-20
 *      ERC-1363 - according to https://eips.ethereum.org/EIPS/eip-1363
 *      EIP-2612 - according to https://eips.ethereum.org/EIPS/eip-2612
 *      EIP-3009 - according to https://eips.ethereum.org/EIPS/eip-3009
 *
 * @dev ERC20: contract has passed
 *      - OpenZeppelin ERC20 tests
 *        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/test/token/ERC20/ERC20.behavior.js
 *        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/test/token/ERC20/ERC20.test.js
 *      - Ref ERC1363 tests
 *        https://github.com/vittominacori/erc1363-payable-token/blob/master/test/token/ERC1363/ERC1363.behaviour.js
 *      - OpenZeppelin EIP2612 tests
 *        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/test/token/ERC20/extensions/draft-ERC20Permit.test.js
 *      - Coinbase EIP3009 tests
 *        https://github.com/CoinbaseStablecoin/eip-3009/blob/master/test/EIP3009.test.ts
 *      - Compound voting delegation tests
 *        https://github.com/compound-finance/compound-protocol/blob/master/tests/Governance/CompTest.js
 *        https://github.com/compound-finance/compound-protocol/blob/master/tests/Utils/EIP712.js
 *      - OpenZeppelin voting delegation tests
 *        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/test/token/ERC20/extensions/ERC20Votes.test.js
 *      See adopted copies of all the tests in the project test folder
 *
 * @dev Compound-like voting delegation functions', public getters', and events' names
 *      were changed for better code readability (Alethea Name <- Comp/Zeppelin name):
 *      - votingDelegates           <- delegates
 *      - votingPowerHistory        <- checkpoints
 *      - votingPowerHistoryLength  <- numCheckpoints
 *      - totalSupplyHistory        <- _totalSupplyCheckpoints (private)
 *      - usedNonces                <- nonces (note: nonces are random instead of sequential)
 *      - DelegateChanged (unchanged)
 *      - VotingPowerChanged        <- DelegateVotesChanged
 *      - votingPowerOf             <- getCurrentVotes
 *      - votingPowerAt             <- getPriorVotes
 *      - totalSupplyAt             <- getPriorTotalSupply
 *      - delegate (unchanged)
 *      - delegateWithAuthorization <- delegateBySig
 * @dev Compound-like voting delegation improved to allow the use of random nonces like in EIP-3009,
 *      instead of sequential; same `usedNonces` EIP-3009 mapping is used to track nonces
 *
 * @dev Reference implementations "used":
 *      - Atomic allowance:    https://github.com/OpenZeppelin/openzeppelin-contracts
 *      - Unlimited allowance: https://github.com/0xProject/protocol
 *      - Voting delegation:   https://github.com/compound-finance/compound-protocol
 *                             https://github.com/OpenZeppelin/openzeppelin-contracts
 *      - ERC-1363:            https://github.com/vittominacori/erc1363-payable-token
 *      - EIP-2612:            https://github.com/Uniswap/uniswap-v2-core
 *      - EIP-3009:            https://github.com/centrehq/centre-tokens
 *                             https://github.com/CoinbaseStablecoin/eip-3009
 *      - Meta transactions:   https://github.com/0xProject/protocol
 *
 * @dev Includes resolutions for ALI ERC20 Audit by Miguel Palhas, https://hackmd.io/@naps62/alierc20-audit
 */
contract AliERC20v2 is ERC1363, EIP2612, EIP3009, AccessControl {
	/**
	 * @dev Smart contract unique identifier, a random number
	 *
	 * @dev Should be regenerated each time smart contact source code is changed
	 *      and changes smart contract itself is to be redeployed
	 *
	 * @dev Generated using https://www.random.org/bytes/
	 */
	uint256 public constant TOKEN_UID = 0x8d4fb97da97378ef7d0ad259aec651f42bd22c200159282baa58486bb390286b;

	/**
	 * @notice Name of the token: Artificial Liquid Intelligence Token
	 *
	 * @notice ERC20 name of the token (long name)
	 *
	 * @dev ERC20 `function name() public view returns (string)`
	 *
	 * @dev Field is declared public: getter name() is created when compiled,
	 *      it returns the name of the token.
	 */
	string public constant name = "Artificial Liquid Intelligence Token";

	/**
	 * @notice Symbol of the token: ALI
	 *
	 * @notice ERC20 symbol of that token (short name)
	 *
	 * @dev ERC20 `function symbol() public view returns (string)`
	 *
	 * @dev Field is declared public: getter symbol() is created when compiled,
	 *      it returns the symbol of the token
	 */
	string public constant symbol = "ALI";

	/**
	 * @notice Decimals of the token: 18
	 *
	 * @dev ERC20 `function decimals() public view returns (uint8)`
	 *
	 * @dev Field is declared public: getter decimals() is created when compiled,
	 *      it returns the number of decimals used to get its user representation.
	 *      For example, if `decimals` equals `6`, a balance of `1,500,000` tokens should
	 *      be displayed to a user as `1,5` (`1,500,000 / 10 ** 6`).
	 *
	 * @dev NOTE: This information is only used for _display_ purposes: it in
	 *      no way affects any of the arithmetic of the contract, including balanceOf() and transfer().
	 */
	uint8 public constant decimals = 18;

	/**
	 * @notice Total supply of the token: initially 10,000,000,000,
	 *      with the potential to decline over time as some tokens may get burnt but not minted
	 *
	 * @dev ERC20 `function totalSupply() public view returns (uint256)`
	 *
	 * @dev Field is declared public: getter totalSupply() is created when compiled,
	 *      it returns the amount of tokens in existence.
	 */
	uint256 public override totalSupply; // is set to 10 billion * 10^18 in the constructor

	/**
	 * @dev A record of all the token balances
	 * @dev This mapping keeps record of all token owners:
	 *      owner => balance
	 */
	mapping(address => uint256) private tokenBalances;

	/**
	 * @notice A record of each account's voting delegate
	 *
	 * @dev Auxiliary data structure used to sum up an account's voting power
	 *
	 * @dev This mapping keeps record of all voting power delegations:
	 *      voting delegator (token owner) => voting delegate
	 */
	mapping(address => address) public votingDelegates;

	/**
	 * @notice Auxiliary structure to store key-value pair, used to store:
	 *      - voting power record (key: block.timestamp, value: voting power)
	 *      - total supply record (key: block.timestamp, value: total supply)
	 * @notice A voting power record binds voting power of a delegate to a particular
	 *      block when the voting power delegation change happened
	 *         k: block.number when delegation has changed; starting from
	 *            that block voting power value is in effect
	 *         v: cumulative voting power a delegate has obtained starting
	 *            from the block stored in blockNumber
	 * @notice Total supply record binds total token supply to a particular
	 *      block when total supply change happened (due to mint/burn operations)
	 */
	struct KV {
		/*
		 * @dev key, a block number
		 */
		uint64 k;

		/*
		 * @dev value, token balance or voting power
		 */
		uint192 v;
	}

	/**
	 * @notice A record of each account's voting power historical data
	 *
	 * @dev Primarily data structure to store voting power for each account.
	 *      Voting power sums up from the account's token balance and delegated
	 *      balances.
	 *
	 * @dev Stores current value and entire history of its changes.
	 *      The changes are stored as an array of checkpoints (key-value pairs).
	 *      Checkpoint is an auxiliary data structure containing voting
	 *      power (number of votes) and block number when the checkpoint is saved
	 *
	 * @dev Maps voting delegate => voting power record
	 */
	mapping(address => KV[]) public votingPowerHistory;

	/**
	 * @notice A record of total token supply historical data
	 *
	 * @dev Primarily data structure to store total token supply.
	 *
	 * @dev Stores current value and entire history of its changes.
	 *      The changes are stored as an array of checkpoints (key-value pairs).
	 *      Checkpoint is an auxiliary data structure containing total
	 *      token supply and block number when the checkpoint is saved
	 */
	KV[] public totalSupplyHistory;

	/**
	 * @dev A record of nonces for signing/validating signatures in EIP-2612 `permit`
	 *
	 * @dev Note: EIP2612 doesn't imply a possibility for nonce randomization like in EIP-3009
	 *
	 * @dev Maps delegate address => delegate nonce
	 */
	mapping(address => uint256) public override nonces;

	/**
	 * @dev A record of used nonces for EIP-3009 transactions
	 *
	 * @dev A record of used nonces for signing/validating signatures
	 *      in `delegateWithAuthorization` for every delegate
	 *
	 * @dev Maps authorizer address => nonce => true/false (used unused)
	 */
	mapping(address => mapping(bytes32 => bool)) private usedNonces;

	/**
	 * @notice A record of all the allowances to spend tokens on behalf
	 * @dev Maps token owner address to an address approved to spend
	 *      some tokens on behalf, maps approved address to that amount
	 * @dev owner => spender => value
	 */
	mapping(address => mapping(address => uint256)) private transferAllowances;

	/**
	 * @notice Enables ERC20 transfers of the tokens
	 *      (transfer by the token owner himself)
	 * @dev Feature FEATURE_TRANSFERS must be enabled in order for
	 *      `transfer()` function to succeed
	 */
	uint32 public constant FEATURE_TRANSFERS = 0x0000_0001;

	/**
	 * @notice Enables ERC20 transfers on behalf
	 *      (transfer by someone else on behalf of token owner)
	 * @dev Feature FEATURE_TRANSFERS_ON_BEHALF must be enabled in order for
	 *      `transferFrom()` function to succeed
	 * @dev Token owner must call `approve()` first to authorize
	 *      the transfer on behalf
	 */
	uint32 public constant FEATURE_TRANSFERS_ON_BEHALF = 0x0000_0002;

	/**
	 * @dev Defines if the default behavior of `transfer` and `transferFrom`
	 *      checks if the receiver smart contract supports ERC20 tokens
	 * @dev When feature FEATURE_UNSAFE_TRANSFERS is enabled the transfers do not
	 *      check if the receiver smart contract supports ERC20 tokens,
	 *      i.e. `transfer` and `transferFrom` behave like `unsafeTransferFrom`
	 * @dev When feature FEATURE_UNSAFE_TRANSFERS is disabled (default) the transfers
	 *      check if the receiver smart contract supports ERC20 tokens,
	 *      i.e. `transfer` and `transferFrom` behave like `transferFromAndCall`
	 */
	uint32 public constant FEATURE_UNSAFE_TRANSFERS = 0x0000_0004;

	/**
	 * @notice Enables token owners to burn their own tokens
	 *
	 * @dev Feature FEATURE_OWN_BURNS must be enabled in order for
	 *      `burn()` function to succeed when called by token owner
	 */
	uint32 public constant FEATURE_OWN_BURNS = 0x0000_0008;

	/**
	 * @notice Enables approved operators to burn tokens on behalf of their owners
	 *
	 * @dev Feature FEATURE_BURNS_ON_BEHALF must be enabled in order for
	 *      `burn()` function to succeed when called by approved operator
	 */
	uint32 public constant FEATURE_BURNS_ON_BEHALF = 0x0000_0010;

	/**
	 * @notice Enables delegators to elect delegates
	 * @dev Feature FEATURE_DELEGATIONS must be enabled in order for
	 *      `delegate()` function to succeed
	 */
	uint32 public constant FEATURE_DELEGATIONS = 0x0000_0020;

	/**
	 * @notice Enables delegators to elect delegates on behalf
	 *      (via an EIP712 signature)
	 * @dev Feature FEATURE_DELEGATIONS_ON_BEHALF must be enabled in order for
	 *      `delegateWithAuthorization()` function to succeed
	 */
	uint32 public constant FEATURE_DELEGATIONS_ON_BEHALF = 0x0000_0040;

	/**
	 * @notice Enables ERC-1363 transfers with callback
	 * @dev Feature FEATURE_ERC1363_TRANSFERS must be enabled in order for
	 *      ERC-1363 `transferFromAndCall` functions to succeed
	 */
	uint32 public constant FEATURE_ERC1363_TRANSFERS = 0x0000_0080;

	/**
	 * @notice Enables ERC-1363 approvals with callback
	 * @dev Feature FEATURE_ERC1363_APPROVALS must be enabled in order for
	 *      ERC-1363 `approveAndCall` functions to succeed
	 */
	uint32 public constant FEATURE_ERC1363_APPROVALS = 0x0000_0100;

	/**
	 * @notice Enables approvals on behalf (EIP2612 permits
	 *      via an EIP712 signature)
	 * @dev Feature FEATURE_EIP2612_PERMITS must be enabled in order for
	 *      `permit()` function to succeed
	 */
	uint32 public constant FEATURE_EIP2612_PERMITS = 0x0000_0200;

	/**
	 * @notice Enables meta transfers on behalf (EIP3009 transfers
	 *      via an EIP712 signature)
	 * @dev Feature FEATURE_EIP3009_TRANSFERS must be enabled in order for
	 *      `transferWithAuthorization()` function to succeed
	 */
	uint32 public constant FEATURE_EIP3009_TRANSFERS = 0x0000_0400;

	/**
	 * @notice Enables meta transfers on behalf (EIP3009 transfers
	 *      via an EIP712 signature)
	 * @dev Feature FEATURE_EIP3009_RECEPTIONS must be enabled in order for
	 *      `receiveWithAuthorization()` function to succeed
	 */
	uint32 public constant FEATURE_EIP3009_RECEPTIONS = 0x0000_0800;

	/**
	 * @notice Token creator is responsible for creating (minting)
	 *      tokens to an arbitrary address
	 * @dev Role ROLE_TOKEN_CREATOR allows minting tokens
	 *      (calling `mint` function)
	 */
	uint32 public constant ROLE_TOKEN_CREATOR = 0x0001_0000;

	/**
	 * @notice Token destroyer is responsible for destroying (burning)
	 *      tokens owned by an arbitrary address
	 * @dev Role ROLE_TOKEN_DESTROYER allows burning tokens
	 *      (calling `burn` function)
	 */
	uint32 public constant ROLE_TOKEN_DESTROYER = 0x0002_0000;

	/**
	 * @notice ERC20 receivers are allowed to receive tokens without ERC20 safety checks,
	 *      which may be useful to simplify tokens transfers into "legacy" smart contracts
	 * @dev When `FEATURE_UNSAFE_TRANSFERS` is not enabled addresses having
	 *      `ROLE_ERC20_RECEIVER` permission are allowed to receive tokens
	 *      via `transfer` and `transferFrom` functions in the same way they
	 *      would via `unsafeTransferFrom` function
	 * @dev When `FEATURE_UNSAFE_TRANSFERS` is enabled `ROLE_ERC20_RECEIVER` permission
	 *      doesn't affect the transfer behaviour since
	 *      `transfer` and `transferFrom` behave like `unsafeTransferFrom` for any receiver
	 * @dev ROLE_ERC20_RECEIVER is a shortening for ROLE_UNSAFE_ERC20_RECEIVER
	 */
	uint32 public constant ROLE_ERC20_RECEIVER = 0x0004_0000;

	/**
	 * @notice ERC20 senders are allowed to send tokens without ERC20 safety checks,
	 *      which may be useful to simplify tokens transfers into "legacy" smart contracts
	 * @dev When `FEATURE_UNSAFE_TRANSFERS` is not enabled senders having
	 *      `ROLE_ERC20_SENDER` permission are allowed to send tokens
	 *      via `transfer` and `transferFrom` functions in the same way they
	 *      would via `unsafeTransferFrom` function
	 * @dev When `FEATURE_UNSAFE_TRANSFERS` is enabled `ROLE_ERC20_SENDER` permission
	 *      doesn't affect the transfer behaviour since
	 *      `transfer` and `transferFrom` behave like `unsafeTransferFrom` for any receiver
	 * @dev ROLE_ERC20_SENDER is a shortening for ROLE_UNSAFE_ERC20_SENDER
	 */
	uint32 public constant ROLE_ERC20_SENDER = 0x0008_0000;

	/**
	 * @notice EIP-712 contract's domain typeHash,
	 *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
	 *
	 * @dev Note: we do not include version into the domain typehash/separator,
	 *      it is implied version is concatenated to the name field, like "AliERC20v2"
	 */
	// keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)")
	bytes32 public constant DOMAIN_TYPEHASH = 0x8cad95687ba82c2ce50e74f7b754645e5117c3a5bec8151c0726d5857980a866;

	/**
	 * @notice EIP-712 contract's domain separator,
	 *      see https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator
	 */
	bytes32 public immutable override DOMAIN_SEPARATOR;

	/**
	 * @notice EIP-712 delegation struct typeHash,
	 *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
	 */
	// keccak256("Delegation(address delegate,uint256 nonce,uint256 expiry)")
	bytes32 public constant DELEGATION_TYPEHASH = 0xff41620983935eb4d4a3c7384a066ca8c1d10cef9a5eca9eb97ca735cd14a755;

	/**
	 * @notice EIP-712 permit (EIP-2612) struct typeHash,
	 *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
	 */
	// keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
	bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

	/**
	 * @notice EIP-712 TransferWithAuthorization (EIP-3009) struct typeHash,
	 *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
	 */
	// keccak256("TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
	bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH = 0x7c7c6cdb67a18743f49ec6fa9b35f50d52ed05cbed4cc592e13b44501c1a2267;

	/**
	 * @notice EIP-712 ReceiveWithAuthorization (EIP-3009) struct typeHash,
	 *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
	 */
	// keccak256("ReceiveWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
	bytes32 public constant RECEIVE_WITH_AUTHORIZATION_TYPEHASH = 0xd099cc98ef71107a616c4f0f941f04c322d8e254fe26b3c6668db87aae413de8;

	/**
	 * @notice EIP-712 CancelAuthorization (EIP-3009) struct typeHash,
	 *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
	 */
	// keccak256("CancelAuthorization(address authorizer,bytes32 nonce)")
	bytes32 public constant CANCEL_AUTHORIZATION_TYPEHASH = 0x158b0a9edf7a828aad02f63cd515c68ef2f50ba807396f6d12842833a1597429;

	/**
	 * @dev Fired in mint() function
	 *
	 * @param by an address which minted some tokens (transaction sender)
	 * @param to an address the tokens were minted to
	 * @param value an amount of tokens minted
	 */
	event Minted(address indexed by, address indexed to, uint256 value);

	/**
	 * @dev Fired in burn() function
	 *
	 * @param by an address which burned some tokens (transaction sender)
	 * @param from an address the tokens were burnt from
	 * @param value an amount of tokens burnt
	 */
	event Burnt(address indexed by, address indexed from, uint256 value);

	/**
	 * @dev Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (arXiv:1907.00903)
	 *
	 * @dev Similar to ERC20 Transfer event, but also logs an address which executed transfer
	 *
	 * @dev Fired in transfer(), transferFrom() and some other (non-ERC20) functions
	 *
	 * @param by an address which performed the transfer
	 * @param from an address tokens were consumed from
	 * @param to an address tokens were sent to
	 * @param value number of tokens transferred
	 */
	event Transfer(address indexed by, address indexed from, address indexed to, uint256 value);

	/**
	 * @dev Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (arXiv:1907.00903)
	 *
	 * @dev Similar to ERC20 Approve event, but also logs old approval value
	 *
	 * @dev Fired in approve(), increaseAllowance(), decreaseAllowance() functions,
	 *      may get fired in transfer functions
	 *
	 * @param owner an address which granted a permission to transfer
	 *      tokens on its behalf
	 * @param spender an address which received a permission to transfer
	 *      tokens on behalf of the owner `_owner`
	 * @param oldValue previously granted amount of tokens to transfer on behalf
	 * @param value new granted amount of tokens to transfer on behalf
	 */
	event Approval(address indexed owner, address indexed spender, uint256 oldValue, uint256 value);

	/**
	 * @dev Notifies that a key-value pair in `votingDelegates` mapping has changed,
	 *      i.e. a delegator address has changed its delegate address
	 *
	 * @param source delegator address, a token owner, effectively transaction sender (`by`)
	 * @param from old delegate, an address which delegate right is revoked
	 * @param to new delegate, an address which received the voting power
	 */
	event DelegateChanged(address indexed source, address indexed from, address indexed to);

	/**
	 * @dev Notifies that a key-value pair in `votingPowerHistory` mapping has changed,
	 *      i.e. a delegate's voting power has changed.
	 *
	 * @param by an address which executed delegate, mint, burn, or transfer operation
	 *      which had led to delegate voting power change
	 * @param target delegate whose voting power has changed
	 * @param fromVal previous number of votes delegate had
	 * @param toVal new number of votes delegate has
	 */
	event VotingPowerChanged(address indexed by, address indexed target, uint256 fromVal, uint256 toVal);

	/**
	 * @dev Deploys the token smart contract,
	 *      assigns initial token supply to the address specified
	 *
	 * @param _initialHolder owner of the initial token supply
	 */
	constructor(address _initialHolder) {
		// verify initial holder address non-zero (is set)
		require(_initialHolder != address(0), "_initialHolder not set (zero address)");

		// build the EIP-712 contract domain separator, see https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator
		// note: we specify contract version in its name
		DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes("AliERC20v2")), block.chainid, address(this)));

		// mint initial supply
		mint(_initialHolder, 10_000_000_000e18);
	}

	/**
	 * @inheritdoc ERC165
	 */
	function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
		// reconstruct from current interface(s) and super interface(s) (if any)
		return interfaceId == type(ERC165).interfaceId
		    || interfaceId == type(ERC20).interfaceId
		    || interfaceId == type(ERC1363).interfaceId
		    || interfaceId == type(EIP2612).interfaceId
		    || interfaceId == type(EIP3009).interfaceId;
	}

	// ===== Start: ERC-1363 functions =====

	/**
	 * @notice Transfers some tokens and then executes `onTransferReceived` callback on the receiver
	 *
	 * @inheritdoc ERC1363
	 *
	 * @dev Called by token owner (an address which has a
	 *      positive token balance tracked by this smart contract)
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * same as `_from` address (self transfer)
	 *          * EOA or smart contract which doesn't support ERC1363Receiver interface
	 * @dev Returns true on success, throws otherwise
	 *
	 * @param _to an address to transfer tokens to,
	 *      must be a smart contract, implementing ERC1363Receiver
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @return true unless throwing
	 */
	function transferAndCall(address _to, uint256 _value) public override returns (bool) {
		// delegate to `transferFromAndCall` passing `msg.sender` as `_from`
		return transferFromAndCall(msg.sender, _to, _value);
	}

	/**
	 * @notice Transfers some tokens and then executes `onTransferReceived` callback on the receiver
	 *
	 * @inheritdoc ERC1363
	 *
	 * @dev Called by token owner (an address which has a
	 *      positive token balance tracked by this smart contract)
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * same as `_from` address (self transfer)
	 *          * EOA or smart contract which doesn't support ERC1363Receiver interface
	 * @dev Returns true on success, throws otherwise
	 *
	 * @param _to an address to transfer tokens to,
	 *      must be a smart contract, implementing ERC1363Receiver
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @param _data [optional] additional data with no specified format,
	 *      sent in onTransferReceived call to `_to`
	 * @return true unless throwing
	 */
	function transferAndCall(address _to, uint256 _value, bytes memory _data) public override returns (bool) {
		// delegate to `transferFromAndCall` passing `msg.sender` as `_from`
		return transferFromAndCall(msg.sender, _to, _value, _data);
	}

	/**
	 * @notice Transfers some tokens on behalf of address `_from' (token owner)
	 *      to some other address `_to` and then executes `onTransferReceived` callback on the receiver
	 *
	 * @inheritdoc ERC1363
	 *
	 * @dev Called by token owner on his own or approved address,
	 *      an address approved earlier by token owner to
	 *      transfer some amount of tokens on its behalf
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * same as `_from` address (self transfer)
	 *          * EOA or smart contract which doesn't support ERC1363Receiver interface
	 * @dev Returns true on success, throws otherwise
	 *
	 * @param _from token owner which approved caller (transaction sender)
	 *      to transfer `_value` of tokens on its behalf
	 * @param _to an address to transfer tokens to,
	 *      must be a smart contract, implementing ERC1363Receiver
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @return true unless throwing
	 */
	function transferFromAndCall(address _from, address _to, uint256 _value) public override returns (bool) {
		// delegate to `transferFromAndCall` passing empty data param
		return transferFromAndCall(_from, _to, _value, "");
	}

	/**
	 * @notice Transfers some tokens on behalf of address `_from' (token owner)
	 *      to some other address `_to` and then executes a `onTransferReceived` callback on the receiver
	 *
	 * @inheritdoc ERC1363
	 *
	 * @dev Called by token owner on his own or approved address,
	 *      an address approved earlier by token owner to
	 *      transfer some amount of tokens on its behalf
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * same as `_from` address (self transfer)
	 *          * EOA or smart contract which doesn't support ERC1363Receiver interface
	 * @dev Returns true on success, throws otherwise
	 *
	 * @param _from token owner which approved caller (transaction sender)
	 *      to transfer `_value` of tokens on its behalf
	 * @param _to an address to transfer tokens to,
	 *      must be a smart contract, implementing ERC1363Receiver
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @param _data [optional] additional data with no specified format,
	 *      sent in onTransferReceived call to `_to`
	 * @return true unless throwing
	 */
	function transferFromAndCall(address _from, address _to, uint256 _value, bytes memory _data) public override returns (bool) {
		// ensure ERC-1363 transfers are enabled
		require(isFeatureEnabled(FEATURE_ERC1363_TRANSFERS), "ERC1363 transfers are disabled");

		// first delegate call to `unsafeTransferFrom` to perform the unsafe token(s) transfer
		unsafeTransferFrom(_from, _to, _value);

		// after the successful transfer - check if receiver supports
		// ERC1363Receiver and execute a callback handler `onTransferReceived`,
		// reverting whole transaction on any error
		_notifyTransferred(_from, _to, _value, _data, false);

		// function throws on any error, so if we're here - it means operation successful, just return true
		return true;
	}

	/**
	 * @notice Approves address called `_spender` to transfer some amount
	 *      of tokens on behalf of the owner, then executes a `onApprovalReceived` callback on `_spender`
	 *
	 * @inheritdoc ERC1363
	 *
	 * @dev Caller must not necessarily own any tokens to grant the permission
	 *
	 * @dev Throws if `_spender` is an EOA or a smart contract which doesn't support ERC1363Spender interface
	 *
	 * @param _spender an address approved by the caller (token owner)
	 *      to spend some tokens on its behalf
	 * @param _value an amount of tokens spender `_spender` is allowed to
	 *      transfer on behalf of the token owner
	 * @return success true on success, throws otherwise
	 */
	function approveAndCall(address _spender, uint256 _value) public override returns (bool) {
		// delegate to `approveAndCall` passing empty data
		return approveAndCall(_spender, _value, "");
	}

	/**
	 * @notice Approves address called `_spender` to transfer some amount
	 *      of tokens on behalf of the owner, then executes a callback on `_spender`
	 *
	 * @inheritdoc ERC1363
	 *
	 * @dev Caller must not necessarily own any tokens to grant the permission
	 *
	 * @param _spender an address approved by the caller (token owner)
	 *      to spend some tokens on its behalf
	 * @param _value an amount of tokens spender `_spender` is allowed to
	 *      transfer on behalf of the token owner
	 * @param _data [optional] additional data with no specified format,
	 *      sent in onApprovalReceived call to `_spender`
	 * @return success true on success, throws otherwise
	 */
	function approveAndCall(address _spender, uint256 _value, bytes memory _data) public override returns (bool) {
		// ensure ERC-1363 approvals are enabled
		require(isFeatureEnabled(FEATURE_ERC1363_APPROVALS), "ERC1363 approvals are disabled");

		// execute regular ERC20 approve - delegate to `approve`
		approve(_spender, _value);

		// after the successful approve - check if receiver supports
		// ERC1363Spender and execute a callback handler `onApprovalReceived`,
		// reverting whole transaction on any error
		_notifyApproved(_spender, _value, _data);

		// function throws on any error, so if we're here - it means operation successful, just return true
		return true;
	}

	/**
	 * @dev Auxiliary function to invoke `onTransferReceived` on a target address
	 *      The call is not executed if the target address is not a contract; in such
	 *      a case function throws if `allowEoa` is set to false, succeeds if it's true
	 *
	 * @dev Throws on any error; returns silently on success
	 *
	 * @param _from representing the previous owner of the given token value
	 * @param _to target address that will receive the tokens
	 * @param _value the amount mount of tokens to be transferred
	 * @param _data [optional] data to send along with the call
	 * @param allowEoa indicates if function should fail if `_to` is an EOA
	 */
	function _notifyTransferred(address _from, address _to, uint256 _value, bytes memory _data, bool allowEoa) private {
		// if recipient `_to` is EOA
		if (!AddressUtils.isContract(_to)) {
			// ensure EOA recipient is allowed
			require(allowEoa, "EOA recipient");

			// exit if successful
			return;
		}

		// otherwise - if `_to` is a contract - execute onTransferReceived
		bytes4 response = ERC1363Receiver(_to).onTransferReceived(msg.sender, _from, _value, _data);

		// expected response is ERC1363Receiver(_to).onTransferReceived.selector
		// bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))
		require(response == ERC1363Receiver(_to).onTransferReceived.selector, "invalid onTransferReceived response");
	}

	/**
	 * @dev Auxiliary function to invoke `onApprovalReceived` on a target address
	 *      The call is not executed if the target address is not a contract; in such
	 *      a case function throws if `allowEoa` is set to false, succeeds if it's true
	 *
	 * @dev Throws on any error; returns silently on success
	 *
	 * @param _spender the address which will spend the funds
	 * @param _value the amount of tokens to be spent
	 * @param _data [optional] data to send along with the call
	 */
	function _notifyApproved(address _spender, uint256 _value, bytes memory _data) private {
		// ensure recipient is not EOA
		require(AddressUtils.isContract(_spender), "EOA spender");

		// otherwise - if `_to` is a contract - execute onApprovalReceived
		bytes4 response = ERC1363Spender(_spender).onApprovalReceived(msg.sender, _value, _data);

		// expected response is ERC1363Spender(_to).onApprovalReceived.selector
		// bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))
		require(response == ERC1363Spender(_spender).onApprovalReceived.selector, "invalid onApprovalReceived response");
	}
	// ===== End: ERC-1363 functions =====

	// ===== Start: ERC20 functions =====

	/**
	 * @notice Gets the balance of a particular address
	 *
	 * @inheritdoc ERC20
	 *
	 * @param _owner the address to query the the balance for
	 * @return balance an amount of tokens owned by the address specified
	 */
	function balanceOf(address _owner) public view override returns (uint256 balance) {
		// read the balance and return
		return tokenBalances[_owner];
	}

	/**
	 * @notice Transfers some tokens to an external address or a smart contract
	 *
	 * @inheritdoc ERC20
	 *
	 * @dev Called by token owner (an address which has a
	 *      positive token balance tracked by this smart contract)
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * self address or
	 *          * smart contract which doesn't support ERC20
	 *
	 * @param _to an address to transfer tokens to,
	 *      must be either an external address or a smart contract,
	 *      compliant with the ERC20 standard
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @return success true on success, throws otherwise
	 */
	function transfer(address _to, uint256 _value) public override returns (bool success) {
		// just delegate call to `transferFrom`,
		// `FEATURE_TRANSFERS` is verified inside it
		return transferFrom(msg.sender, _to, _value);
	}

	/**
	 * @notice Transfers some tokens on behalf of address `_from' (token owner)
	 *      to some other address `_to`
	 *
	 * @inheritdoc ERC20
	 *
	 * @dev Called by token owner on his own or approved address,
	 *      an address approved earlier by token owner to
	 *      transfer some amount of tokens on its behalf
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * same as `_from` address (self transfer)
	 *          * smart contract which doesn't support ERC20
	 *
	 * @param _from token owner which approved caller (transaction sender)
	 *      to transfer `_value` of tokens on its behalf
	 * @param _to an address to transfer tokens to,
	 *      must be either an external address or a smart contract,
	 *      compliant with the ERC20 standard
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @return success true on success, throws otherwise
	 */
	function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
		// depending on `FEATURE_UNSAFE_TRANSFERS` we execute either safe (default)
		// or unsafe transfer
		// if `FEATURE_UNSAFE_TRANSFERS` is enabled
		// or receiver has `ROLE_ERC20_RECEIVER` permission
		// or sender has `ROLE_ERC20_SENDER` permission
		if(isFeatureEnabled(FEATURE_UNSAFE_TRANSFERS)
			|| isOperatorInRole(_to, ROLE_ERC20_RECEIVER)
			|| isSenderInRole(ROLE_ERC20_SENDER)) {
			// we execute unsafe transfer - delegate call to `unsafeTransferFrom`,
			// `FEATURE_TRANSFERS` is verified inside it
			unsafeTransferFrom(_from, _to, _value);
		}
		// otherwise - if `FEATURE_UNSAFE_TRANSFERS` is disabled
		// and receiver doesn't have `ROLE_ERC20_RECEIVER` permission
		else {
			// we execute safe transfer - delegate call to `safeTransferFrom`, passing empty `_data`,
			// `FEATURE_TRANSFERS` is verified inside it
			safeTransferFrom(_from, _to, _value, "");
		}

		// both `unsafeTransferFrom` and `safeTransferFrom` throw on any error, so
		// if we're here - it means operation successful,
		// just return true
		return true;
	}

	/**
	 * @notice Transfers some tokens on behalf of address `_from' (token owner)
	 *      to some other address `_to` and then executes `onTransferReceived` callback
	 *      on the receiver if it is a smart contract (not an EOA)
	 *
	 * @dev Called by token owner on his own or approved address,
	 *      an address approved earlier by token owner to
	 *      transfer some amount of tokens on its behalf
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * same as `_from` address (self transfer)
	 *          * smart contract which doesn't support ERC1363Receiver interface
	 * @dev Returns true on success, throws otherwise
	 *
	 * @param _from token owner which approved caller (transaction sender)
	 *      to transfer `_value` of tokens on its behalf
	 * @param _to an address to transfer tokens to,
	 *      must be either an external address or a smart contract,
	 *      implementing ERC1363Receiver
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @param _data [optional] additional data with no specified format,
	 *      sent in onTransferReceived call to `_to` in case if its a smart contract
	 * @return true unless throwing
	 */
	function safeTransferFrom(address _from, address _to, uint256 _value, bytes memory _data) public returns (bool) {
		// first delegate call to `unsafeTransferFrom` to perform the unsafe token(s) transfer
		unsafeTransferFrom(_from, _to, _value);

		// after the successful transfer - check if receiver supports
		// ERC1363Receiver and execute a callback handler `onTransferReceived`,
		// reverting whole transaction on any error
		_notifyTransferred(_from, _to, _value, _data, true);

		// function throws on any error, so if we're here - it means operation successful, just return true
		return true;
	}

	/**
	 * @notice Transfers some tokens on behalf of address `_from' (token owner)
	 *      to some other address `_to`
	 *
	 * @dev In contrast to `transferFromAndCall` doesn't check recipient
	 *      smart contract to support ERC20 tokens (ERC1363Receiver)
	 * @dev Designed to be used by developers when the receiver is known
	 *      to support ERC20 tokens but doesn't implement ERC1363Receiver interface
	 * @dev Called by token owner on his own or approved address,
	 *      an address approved earlier by token owner to
	 *      transfer some amount of tokens on its behalf
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * same as `_from` address (self transfer)
	 * @dev Returns silently on success, throws otherwise
	 *
	 * @param _from token sender, token owner which approved caller (transaction sender)
	 *      to transfer `_value` of tokens on its behalf
	 * @param _to token receiver, an address to transfer tokens to
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 */
	function unsafeTransferFrom(address _from, address _to, uint256 _value) public {
		// make an internal transferFrom - delegate to `__transferFrom`
		__transferFrom(msg.sender, _from, _to, _value);
	}

	/**
	 * @dev Powers the meta transactions for `unsafeTransferFrom` - EIP-3009 `transferWithAuthorization`
	 *      and `receiveWithAuthorization`
	 *
	 * @dev See `unsafeTransferFrom` and `transferFrom` soldoc for details
	 *
	 * @param _by an address executing the transfer, it can be token owner itself,
	 *      or an operator previously approved with `approve()`
	 * @param _from token sender, token owner which approved caller (transaction sender)
	 *      to transfer `_value` of tokens on its behalf
	 * @param _to token receiver, an address to transfer tokens to
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 */
	function __transferFrom(address _by, address _from, address _to, uint256 _value) private {
		// if `_from` is equal to sender, require transfers feature to be enabled
		// otherwise require transfers on behalf feature to be enabled
		require(_from == _by && isFeatureEnabled(FEATURE_TRANSFERS)
		     || _from != _by && isFeatureEnabled(FEATURE_TRANSFERS_ON_BEHALF),
		        _from == _by? "transfers are disabled": "transfers on behalf are disabled");

		// non-zero source address check - Zeppelin
		// obviously, zero source address is a client mistake
		// it's not part of ERC20 standard but it's reasonable to fail fast
		// since for zero value transfer transaction succeeds otherwise
		require(_from != address(0), "transfer from the zero address");

		// non-zero recipient address check
		require(_to != address(0), "transfer to the zero address");

		// sender and recipient cannot be the same
		require(_from != _to, "sender and recipient are the same (_from = _to)");

		// sending tokens to the token smart contract itself is a client mistake
		require(_to != address(this), "invalid recipient (transfer to the token smart contract itself)");

		// according to ERC-20 Token Standard, https://eips.ethereum.org/EIPS/eip-20
		// "Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event."
		if(_value == 0) {
			// emit an ERC20 transfer event
			emit Transfer(_from, _to, _value);

			// don't forget to return - we're done
			return;
		}

		// no need to make arithmetic overflow check on the _value - by design of mint()

		// in case of transfer on behalf
		if(_from != _by) {
			// read allowance value - the amount of tokens allowed to transfer - into the stack
			uint256 _allowance = transferAllowances[_from][_by];

			// verify sender has an allowance to transfer amount of tokens requested
			require(_allowance >= _value, "transfer amount exceeds allowance");

			// we treat max uint256 allowance value as an "unlimited" and
			// do not decrease allowance when it is set to "unlimited" value
			if(_allowance < type(uint256).max) {
				// update allowance value on the stack
				_allowance -= _value;

				// update the allowance value in storage
				transferAllowances[_from][_by] = _allowance;

				// emit an improved atomic approve event
				emit Approval(_from, _by, _allowance + _value, _allowance);

				// emit an ERC20 approval event to reflect the decrease
				emit Approval(_from, _by, _allowance);
			}
		}

		// verify sender has enough tokens to transfer on behalf
		require(tokenBalances[_from] >= _value, "transfer amount exceeds balance");

		// perform the transfer:
		// decrease token owner (sender) balance
		tokenBalances[_from] -= _value;

		// increase `_to` address (receiver) balance
		tokenBalances[_to] += _value;

		// move voting power associated with the tokens transferred
		__moveVotingPower(_by, votingDelegates[_from], votingDelegates[_to], _value);

		// emit an improved transfer event (arXiv:1907.00903)
		emit Transfer(_by, _from, _to, _value);

		// emit an ERC20 transfer event
		emit Transfer(_from, _to, _value);
	}

	/**
	 * @notice Approves address called `_spender` to transfer some amount
	 *      of tokens on behalf of the owner (transaction sender)
	 *
	 * @inheritdoc ERC20
	 *
	 * @dev Transaction sender must not necessarily own any tokens to grant the permission
	 *
	 * @param _spender an address approved by the caller (token owner)
	 *      to spend some tokens on its behalf
	 * @param _value an amount of tokens spender `_spender` is allowed to
	 *      transfer on behalf of the token owner
	 * @return success true on success, throws otherwise
	 */
	function approve(address _spender, uint256 _value) public override returns (bool success) {
		// make an internal approve - delegate to `__approve`
		__approve(msg.sender, _spender, _value);

		// operation successful, return true
		return true;
	}

	/**
	 * @dev Powers the meta transaction for `approve` - EIP-2612 `permit`
	 *
	 * @dev Approves address called `_spender` to transfer some amount
	 *      of tokens on behalf of the `_owner`
	 *
	 * @dev `_owner` must not necessarily own any tokens to grant the permission
	 * @dev Throws if `_spender` is a zero address
	 *
	 * @param _owner owner of the tokens to set approval on behalf of
	 * @param _spender an address approved by the token owner
	 *      to spend some tokens on its behalf
	 * @param _value an amount of tokens spender `_spender` is allowed to
	 *      transfer on behalf of the token owner
	 */
	function __approve(address _owner, address _spender, uint256 _value) private {
		// non-zero spender address check - Zeppelin
		// obviously, zero spender address is a client mistake
		// it's not part of ERC20 standard but it's reasonable to fail fast
		require(_spender != address(0), "approve to the zero address");

		// read old approval value to emmit an improved event (arXiv:1907.00903)
		uint256 _oldValue = transferAllowances[_owner][_spender];

		// perform an operation: write value requested into the storage
		transferAllowances[_owner][_spender] = _value;

		// emit an improved atomic approve event (arXiv:1907.00903)
		emit Approval(_owner, _spender, _oldValue, _value);

		// emit an ERC20 approval event
		emit Approval(_owner, _spender, _value);
	}

	/**
	 * @notice Returns the amount which _spender is still allowed to withdraw from _owner.
	 *
	 * @inheritdoc ERC20
	 *
	 * @dev A function to check an amount of tokens owner approved
	 *      to transfer on its behalf by some other address called "spender"
	 *
	 * @param _owner an address which approves transferring some tokens on its behalf
	 * @param _spender an address approved to transfer some tokens on behalf
	 * @return remaining an amount of tokens approved address `_spender` can transfer on behalf
	 *      of token owner `_owner`
	 */
	function allowance(address _owner, address _spender) public view override returns (uint256 remaining) {
		// read the value from storage and return
		return transferAllowances[_owner][_spender];
	}

	// ===== End: ERC20 functions =====

	// ===== Start: Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (arXiv:1907.00903) =====

	/**
	 * @notice Increases the allowance granted to `spender` by the transaction sender
	 *
	 * @dev Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (arXiv:1907.00903)
	 *
	 * @dev Throws if value to increase by is zero or too big and causes arithmetic overflow
	 *
	 * @param _spender an address approved by the caller (token owner)
	 *      to spend some tokens on its behalf
	 * @param _value an amount of tokens to increase by
	 * @return success true on success, throws otherwise
	 */
	function increaseAllowance(address _spender, uint256 _value) public returns (bool) {
		// read current allowance value
		uint256 currentVal = transferAllowances[msg.sender][_spender];

		// non-zero _value and arithmetic overflow check on the allowance
		unchecked {
			// put operation into unchecked block to display user-friendly overflow error message for Solidity 0.8+
			require(currentVal + _value > currentVal, "zero value approval increase or arithmetic overflow");
		}

		// delegate call to `approve` with the new value
		return approve(_spender, currentVal + _value);
	}

	/**
	 * @notice Decreases the allowance granted to `spender` by the caller.
	 *
	 * @dev Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (arXiv:1907.00903)
	 *
	 * @dev Throws if value to decrease by is zero or is greater than currently allowed value
	 *
	 * @param _spender an address approved by the caller (token owner)
	 *      to spend some tokens on its behalf
	 * @param _value an amount of tokens to decrease by
	 * @return success true on success, throws otherwise
	 */
	function decreaseAllowance(address _spender, uint256 _value) public returns (bool) {
		// read current allowance value
		uint256 currentVal = transferAllowances[msg.sender][_spender];

		// non-zero _value check on the allowance
		require(_value > 0, "zero value approval decrease");

		// verify allowance decrease doesn't underflow
		require(currentVal >= _value, "ERC20: decreased allowance below zero");

		// delegate call to `approve` with the new value
		return approve(_spender, currentVal - _value);
	}

	// ===== End: Resolution for the Multiple Withdrawal Attack on ERC20 Tokens (arXiv:1907.00903) =====

	// ===== Start: Minting/burning extension =====

	/**
	 * @dev Mints (creates) some tokens to address specified
	 * @dev The value specified is treated as is without taking
	 *      into account what `decimals` value is
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_CREATOR` permission
	 *
	 * @dev Throws on overflow, if totalSupply + _value doesn't fit into uint256
	 *
	 * @param _to an address to mint tokens to
	 * @param _value an amount of tokens to mint (create)
	 */
	function mint(address _to, uint256 _value) public {
		// check if caller has sufficient permissions to mint tokens
		require(isSenderInRole(ROLE_TOKEN_CREATOR), "access denied");

		// non-zero recipient address check
		require(_to != address(0), "zero address");

		// non-zero _value and arithmetic overflow check on the total supply
		// this check automatically secures arithmetic overflow on the individual balance
		unchecked {
			// put operation into unchecked block to display user-friendly overflow error message for Solidity 0.8+
			require(totalSupply + _value > totalSupply, "zero value or arithmetic overflow");
		}

		// uint192 overflow check (required by voting delegation)
		require(totalSupply + _value <= type(uint192).max, "total supply overflow (uint192)");

		// perform mint:
		// increase total amount of tokens value
		totalSupply += _value;

		// increase `_to` address balance
		tokenBalances[_to] += _value;

		// update total token supply history
		__updateHistory(totalSupplyHistory, add, _value);

		// create voting power associated with the tokens minted
		__moveVotingPower(msg.sender, address(0), votingDelegates[_to], _value);

		// fire a minted event
		emit Minted(msg.sender, _to, _value);

		// emit an improved transfer event (arXiv:1907.00903)
		emit Transfer(msg.sender, address(0), _to, _value);

		// fire ERC20 compliant transfer event
		emit Transfer(address(0), _to, _value);
	}

	/**
	 * @dev Burns (destroys) some tokens from the address specified
	 *
	 * @dev The value specified is treated as is without taking
	 *      into account what `decimals` value is
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_DESTROYER` permission
	 *      or FEATURE_OWN_BURNS/FEATURE_BURNS_ON_BEHALF features to be enabled
	 *
	 * @dev Can be disabled by the contract creator forever by disabling
	 *      FEATURE_OWN_BURNS/FEATURE_BURNS_ON_BEHALF features and then revoking
	 *      its own roles to burn tokens and to enable burning features
	 *
	 * @param _from an address to burn some tokens from
	 * @param _value an amount of tokens to burn (destroy)
	 */
	function burn(address _from, uint256 _value) public {
		// check if caller has sufficient permissions to burn tokens
		// and if not - check for possibility to burn own tokens or to burn on behalf
		if(!isSenderInRole(ROLE_TOKEN_DESTROYER)) {
			// if `_from` is equal to sender, require own burns feature to be enabled
			// otherwise require burns on behalf feature to be enabled
			require(_from == msg.sender && isFeatureEnabled(FEATURE_OWN_BURNS)
			     || _from != msg.sender && isFeatureEnabled(FEATURE_BURNS_ON_BEHALF),
			        _from == msg.sender? "burns are disabled": "burns on behalf are disabled");

			// in case of burn on behalf
			if(_from != msg.sender) {
				// read allowance value - the amount of tokens allowed to be burnt - into the stack
				uint256 _allowance = transferAllowances[_from][msg.sender];

				// verify sender has an allowance to burn amount of tokens requested
				require(_allowance >= _value, "burn amount exceeds allowance");

				// we treat max uint256 allowance value as an "unlimited" and
				// do not decrease allowance when it is set to "unlimited" value
				if(_allowance < type(uint256).max) {
					// update allowance value on the stack
					_allowance -= _value;

					// update the allowance value in storage
					transferAllowances[_from][msg.sender] = _allowance;

					// emit an improved atomic approve event (arXiv:1907.00903)
					emit Approval(msg.sender, _from, _allowance + _value, _allowance);

					// emit an ERC20 approval event to reflect the decrease
					emit Approval(_from, msg.sender, _allowance);
				}
			}
		}

		// at this point we know that either sender is ROLE_TOKEN_DESTROYER or
		// we burn own tokens or on behalf (in latest case we already checked and updated allowances)
		// we have left to execute balance checks and burning logic itself

		// non-zero burn value check
		require(_value != 0, "zero value burn");

		// non-zero source address check - Zeppelin
		require(_from != address(0), "burn from the zero address");

		// verify `_from` address has enough tokens to destroy
		// (basically this is a arithmetic overflow check)
		require(tokenBalances[_from] >= _value, "burn amount exceeds balance");

		// perform burn:
		// decrease `_from` address balance
		tokenBalances[_from] -= _value;

		// decrease total amount of tokens value
		totalSupply -= _value;

		// update total token supply history
		__updateHistory(totalSupplyHistory, sub, _value);

		// destroy voting power associated with the tokens burnt
		__moveVotingPower(msg.sender, votingDelegates[_from], address(0), _value);

		// fire a burnt event
		emit Burnt(msg.sender, _from, _value);

		// emit an improved transfer event (arXiv:1907.00903)
		emit Transfer(msg.sender, _from, address(0), _value);

		// fire ERC20 compliant transfer event
		emit Transfer(_from, address(0), _value);
	}

	// ===== End: Minting/burning extension =====

	// ===== Start: EIP-2612 functions =====

	/**
	 * @inheritdoc EIP2612
	 *
	 * @dev Executes approve(_spender, _value) on behalf of the owner who EIP-712
	 *      signed the transaction, i.e. as if transaction sender is the EIP712 signer
	 *
	 * @dev Sets the `_value` as the allowance of `_spender` over `_owner` tokens,
	 *      given `_owner` EIP-712 signed approval
	 *
	 * @dev Inherits the Multiple Withdrawal Attack on ERC20 Tokens (arXiv:1907.00903)
	 *      vulnerability in the same way as ERC20 `approve`, use standard ERC20 workaround
	 *      if this might become an issue:
	 *      https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit
	 *
	 * @dev Emits `Approval` event(s) in the same way as `approve` does
	 *
	 * @dev Requires:
	 *     - `_spender` to be non-zero address
	 *     - `_exp` to be a timestamp in the future
	 *     - `v`, `r` and `s` to be a valid `secp256k1` signature from `_owner`
	 *        over the EIP712-formatted function arguments.
	 *     - the signature to use `_owner` current nonce (see `nonces`).
	 *
	 * @dev For more information on the signature format, see the
	 *      https://eips.ethereum.org/EIPS/eip-2612#specification
	 *
	 * @param _owner owner of the tokens to set approval on behalf of,
	 *      an address which signed the EIP-712 message
	 * @param _spender an address approved by the token owner
	 *      to spend some tokens on its behalf
	 * @param _value an amount of tokens spender `_spender` is allowed to
	 *      transfer on behalf of the token owner
	 * @param _exp signature expiration time (unix timestamp)
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function permit(address _owner, address _spender, uint256 _value, uint256 _exp, uint8 v, bytes32 r, bytes32 s) public override {
		// verify permits are enabled
		require(isFeatureEnabled(FEATURE_EIP2612_PERMITS), "EIP2612 permits are disabled");

		// derive signer of the EIP712 Permit message, and
		// update the nonce for that particular signer to avoid replay attack!!! --------->>> ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
		address signer = __deriveSigner(abi.encode(PERMIT_TYPEHASH, _owner, _spender, _value, nonces[_owner]++, _exp), v, r, s);

		// perform message integrity and security validations
		require(signer == _owner, "invalid signature");
		require(block.timestamp < _exp, "signature expired");

		// delegate call to `__approve` - execute the logic required
		__approve(_owner, _spender, _value);
	}

	// ===== End: EIP-2612 functions =====

	// ===== Start: EIP-3009 functions =====

	/**
	 * @inheritdoc EIP3009
	 *
	 * @notice Checks if specified nonce was already used
	 *
	 * @dev Nonces are expected to be client-side randomly generated 32-byte values
	 *      unique to the authorizer's address
	 *
	 * @dev Alias for usedNonces(authorizer, nonce)
	 *
	 * @param _authorizer an address to check nonce for
	 * @param _nonce a nonce to check
	 * @return true if the nonce was used, false otherwise
	 */
	function authorizationState(address _authorizer, bytes32 _nonce) public override view returns (bool) {
		// simply return the value from the mapping
		return usedNonces[_authorizer][_nonce];
	}

	/**
	 * @inheritdoc EIP3009
	 *
	 * @notice Execute a transfer with a signed authorization
	 *
	 * @param _from token sender and transaction authorizer
	 * @param _to token receiver
	 * @param _value amount to be transferred
	 * @param _validAfter signature valid after time (unix timestamp)
	 * @param _validBefore signature valid before time (unix timestamp)
	 * @param _nonce unique random nonce
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function transferWithAuthorization(
		address _from,
		address _to,
		uint256 _value,
		uint256 _validAfter,
		uint256 _validBefore,
		bytes32 _nonce,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public override {
		// ensure EIP-3009 transfers are enabled
		require(isFeatureEnabled(FEATURE_EIP3009_TRANSFERS), "EIP3009 transfers are disabled");

		// derive signer of the EIP712 TransferWithAuthorization message
		address signer = __deriveSigner(abi.encode(TRANSFER_WITH_AUTHORIZATION_TYPEHASH, _from, _to, _value, _validAfter, _validBefore, _nonce), v, r, s);

		// perform message integrity and security validations
		require(signer == _from, "invalid signature");
		require(block.timestamp > _validAfter, "signature not yet valid");
		require(block.timestamp < _validBefore, "signature expired");

		// use the nonce supplied (verify, mark as used, emit event)
		__useNonce(_from, _nonce, false);

		// delegate call to `__transferFrom` - execute the logic required
		__transferFrom(signer, _from, _to, _value);
	}

	/**
	 * @inheritdoc EIP3009
	 *
	 * @notice Receive a transfer with a signed authorization from the payer
	 *
	 * @dev This has an additional check to ensure that the payee's address
	 *      matches the caller of this function to prevent front-running attacks.
	 *
	 * @param _from token sender and transaction authorizer
	 * @param _to token receiver
	 * @param _value amount to be transferred
	 * @param _validAfter signature valid after time (unix timestamp)
	 * @param _validBefore signature valid before time (unix timestamp)
	 * @param _nonce unique random nonce
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function receiveWithAuthorization(
		address _from,
		address _to,
		uint256 _value,
		uint256 _validAfter,
		uint256 _validBefore,
		bytes32 _nonce,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public override {
		// verify EIP3009 receptions are enabled
		require(isFeatureEnabled(FEATURE_EIP3009_RECEPTIONS), "EIP3009 receptions are disabled");

		// derive signer of the EIP712 ReceiveWithAuthorization message
		address signer = __deriveSigner(abi.encode(RECEIVE_WITH_AUTHORIZATION_TYPEHASH, _from, _to, _value, _validAfter, _validBefore, _nonce), v, r, s);

		// perform message integrity and security validations
		require(signer == _from, "invalid signature");
		require(block.timestamp > _validAfter, "signature not yet valid");
		require(block.timestamp < _validBefore, "signature expired");
		require(_to == msg.sender, "access denied");

		// use the nonce supplied (verify, mark as used, emit event)
		__useNonce(_from, _nonce, false);

		// delegate call to `__transferFrom` - execute the logic required
		__transferFrom(signer, _from, _to, _value);
	}

	/**
	 * @inheritdoc EIP3009
	 *
	 * @notice Attempt to cancel an authorization
	 *
	 * @param _authorizer transaction authorizer
	 * @param _nonce unique random nonce to cancel (mark as used)
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function cancelAuthorization(
		address _authorizer,
		bytes32 _nonce,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public override {
		// derive signer of the EIP712 ReceiveWithAuthorization message
		address signer = __deriveSigner(abi.encode(CANCEL_AUTHORIZATION_TYPEHASH, _authorizer, _nonce), v, r, s);

		// perform message integrity and security validations
		require(signer == _authorizer, "invalid signature");

		// cancel the nonce supplied (verify, mark as used, emit event)
		__useNonce(_authorizer, _nonce, true);
	}

	/**
	 * @dev Auxiliary function to verify structured EIP712 message signature and derive its signer
	 *
	 * @param abiEncodedTypehash abi.encode of the message typehash together with all its parameters
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function __deriveSigner(bytes memory abiEncodedTypehash, uint8 v, bytes32 r, bytes32 s) private view returns(address) {
		// build the EIP-712 hashStruct of the message
		bytes32 hashStruct = keccak256(abiEncodedTypehash);

		// calculate the EIP-712 digest "\x19\x01" ‖ domainSeparator ‖ hashStruct(message)
		bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct));

		// recover the address which signed the message with v, r, s
		address signer = ECDSA.recover(digest, v, r, s);

		// return the signer address derived from the signature
		return signer;
	}

	/**
	 * @dev Auxiliary function to use/cancel the nonce supplied for a given authorizer:
	 *      1. Verifies the nonce was not used before
	 *      2. Marks the nonce as used
	 *      3. Emits an event that the nonce was used/cancelled
	 *
	 * @dev Set `_cancellation` to false (default) to use nonce,
	 *      set `_cancellation` to true to cancel nonce
	 *
	 * @dev It is expected that the nonce supplied is a randomly
	 *      generated uint256 generated by the client
	 *
	 * @param _authorizer an address to use/cancel nonce for
	 * @param _nonce random nonce to use
	 * @param _cancellation true to emit `AuthorizationCancelled`, false to emit `AuthorizationUsed` event
	 */
	function __useNonce(address _authorizer, bytes32 _nonce, bool _cancellation) private {
		// verify nonce was not used before
		require(!usedNonces[_authorizer][_nonce], "invalid nonce");

		// update the nonce state to "used" for that particular signer to avoid replay attack
		usedNonces[_authorizer][_nonce] = true;

		// depending on the usage type (use/cancel)
		if(_cancellation) {
			// emit an event regarding the nonce cancelled
			emit AuthorizationCanceled(_authorizer, _nonce);
		}
		else {
			// emit an event regarding the nonce used
			emit AuthorizationUsed(_authorizer, _nonce);
		}
	}

	// ===== End: EIP-3009 functions =====

	// ===== Start: DAO Support (Compound-like voting delegation) =====

	/**
	 * @notice Gets current voting power of the account `_of`
	 *
	 * @param _of the address of account to get voting power of
	 * @return current cumulative voting power of the account,
	 *      sum of token balances of all its voting delegators
	 */
	function votingPowerOf(address _of) public view returns (uint256) {
		// get a link to an array of voting power history records for an address specified
		KV[] storage history = votingPowerHistory[_of];

		// lookup the history and return latest element
		return history.length == 0? 0: history[history.length - 1].v;
	}

	/**
	 * @notice Gets past voting power of the account `_of` at some block `_blockNum`
	 *
	 * @dev Throws if `_blockNum` is not in the past (not the finalized block)
	 *
	 * @param _of the address of account to get voting power of
	 * @param _blockNum block number to get the voting power at
	 * @return past cumulative voting power of the account,
	 *      sum of token balances of all its voting delegators at block number `_blockNum`
	 */
	function votingPowerAt(address _of, uint256 _blockNum) public view returns (uint256) {
		// make sure block number is not in the past (not the finalized block)
		require(_blockNum < block.number, "block not yet mined"); // Compound msg not yet determined

		// `votingPowerHistory[_of]` is an array ordered by `blockNumber`, ascending;
		// apply binary search on `votingPowerHistory[_of]` to find such an entry number `i`, that
		// `votingPowerHistory[_of][i].k <= _blockNum`, but in the same time
		// `votingPowerHistory[_of][i + 1].k > _blockNum`
		// return the result - voting power found at index `i`
		return __binaryLookup(votingPowerHistory[_of], _blockNum);
	}

	/**
	 * @dev Reads an entire voting power history array for the delegate specified
	 *
	 * @param _of delegate to query voting power history for
	 * @return voting power history array for the delegate of interest
	 */
	function votingPowerHistoryOf(address _of) public view returns(KV[] memory) {
		// return an entire array as memory
		return votingPowerHistory[_of];
	}

	/**
	 * @dev Returns length of the voting power history array for the delegate specified;
	 *      useful since reading an entire array just to get its length is expensive (gas cost)
	 *
	 * @param _of delegate to query voting power history length for
	 * @return voting power history array length for the delegate of interest
	 */
	function votingPowerHistoryLength(address _of) public view returns(uint256) {
		// read array length and return
		return votingPowerHistory[_of].length;
	}

	/**
	 * @notice Gets past total token supply value at some block `_blockNum`
	 *
	 * @dev Throws if `_blockNum` is not in the past (not the finalized block)
	 *
	 * @param _blockNum block number to get the total token supply at
	 * @return past total token supply at block number `_blockNum`
	 */
	function totalSupplyAt(uint256 _blockNum) public view returns(uint256) {
		// make sure block number is not in the past (not the finalized block)
		require(_blockNum < block.number, "block not yet mined");

		// `totalSupplyHistory` is an array ordered by `k`, ascending;
		// apply binary search on `totalSupplyHistory` to find such an entry number `i`, that
		// `totalSupplyHistory[i].k <= _blockNum`, but in the same time
		// `totalSupplyHistory[i + 1].k > _blockNum`
		// return the result - value `totalSupplyHistory[i].v` found at index `i`
		return __binaryLookup(totalSupplyHistory, _blockNum);
	}

	/**
	 * @dev Reads an entire total token supply history array
	 *
	 * @return total token supply history array, a key-value pair array,
	 *      where key is a block number and value is total token supply at that block
	 */
	function entireSupplyHistory() public view returns(KV[] memory) {
		// return an entire array as memory
		return totalSupplyHistory;
	}

	/**
	 * @dev Returns length of the total token supply history array;
	 *      useful since reading an entire array just to get its length is expensive (gas cost)
	 *
	 * @return total token supply history array
	 */
	function totalSupplyHistoryLength() public view returns(uint256) {
		// read array length and return
		return totalSupplyHistory.length;
	}

	/**
	 * @notice Delegates voting power of the delegator `msg.sender` to the delegate `_to`
	 *
	 * @dev Accepts zero value address to delegate voting power to, effectively
	 *      removing the delegate in that case
	 *
	 * @param _to address to delegate voting power to
	 */
	function delegate(address _to) public {
		// verify delegations are enabled
		require(isFeatureEnabled(FEATURE_DELEGATIONS), "delegations are disabled");
		// delegate call to `__delegate`
		__delegate(msg.sender, _to);
	}

	/**
	 * @dev Powers the meta transaction for `delegate` - `delegateWithAuthorization`
	 *
	 * @dev Auxiliary function to delegate delegator's `_from` voting power to the delegate `_to`
	 * @dev Writes to `votingDelegates` and `votingPowerHistory` mappings
	 *
	 * @param _from delegator who delegates his voting power
	 * @param _to delegate who receives the voting power
	 */
	function __delegate(address _from, address _to) private {
		// read current delegate to be replaced by a new one
		address _fromDelegate = votingDelegates[_from];

		// read current voting power (it is equal to token balance)
		uint256 _value = tokenBalances[_from];

		// reassign voting delegate to `_to`
		votingDelegates[_from] = _to;

		// update voting power for `_fromDelegate` and `_to`
		__moveVotingPower(_from, _fromDelegate, _to, _value);

		// emit an event
		emit DelegateChanged(_from, _fromDelegate, _to);
	}

	/**
	 * @notice Delegates voting power of the delegator (represented by its signature) to the delegate `_to`
	 *
	 * @dev Accepts zero value address to delegate voting power to, effectively
	 *      removing the delegate in that case
	 *
	 * @dev Compliant with EIP-712: Ethereum typed structured data hashing and signing,
	 *      see https://eips.ethereum.org/EIPS/eip-712
	 *
	 * @param _to address to delegate voting power to
	 * @param _nonce nonce used to construct the signature, and used to validate it;
	 *      nonce is increased by one after successful signature validation and vote delegation
	 * @param _exp signature expiration time
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function delegateWithAuthorization(address _to, bytes32 _nonce, uint256 _exp, uint8 v, bytes32 r, bytes32 s) public {
		// verify delegations on behalf are enabled
		require(isFeatureEnabled(FEATURE_DELEGATIONS_ON_BEHALF), "delegations on behalf are disabled");

		// derive signer of the EIP712 Delegation message
		address signer = __deriveSigner(abi.encode(DELEGATION_TYPEHASH, _to, _nonce, _exp), v, r, s);

		// perform message integrity and security validations
		require(block.timestamp < _exp, "signature expired"); // Compound msg

		// use the nonce supplied (verify, mark as used, emit event)
		__useNonce(signer, _nonce, false);

		// delegate call to `__delegate` - execute the logic required
		__delegate(signer, _to);
	}

	/**
	 * @dev Auxiliary function to move voting power `_value`
	 *      from delegate `_from` to the delegate `_to`
	 *
	 * @dev Doesn't have any effect if `_from == _to`, or if `_value == 0`
	 *
	 * @param _by an address which executed delegate, mint, burn, or transfer operation
	 *      which had led to delegate voting power change
	 * @param _from delegate to move voting power from
	 * @param _to delegate to move voting power to
	 * @param _value voting power to move from `_from` to `_to`
	 */
	function __moveVotingPower(address _by, address _from, address _to, uint256 _value) private {
		// if there is no move (`_from == _to`) or there is nothing to move (`_value == 0`)
		if(_from == _to || _value == 0) {
			// return silently with no action
			return;
		}

		// if source address is not zero - decrease its voting power
		if(_from != address(0)) {
			// get a link to an array of voting power history records for an address specified
			KV[] storage _h = votingPowerHistory[_from];

			// update source voting power: decrease by `_value`
			(uint256 _fromVal, uint256 _toVal) = __updateHistory(_h, sub, _value);

			// emit an event
			emit VotingPowerChanged(_by, _from, _fromVal, _toVal);
		}

		// if destination address is not zero - increase its voting power
		if(_to != address(0)) {
			// get a link to an array of voting power history records for an address specified
			KV[] storage _h = votingPowerHistory[_to];

			// update destination voting power: increase by `_value`
			(uint256 _fromVal, uint256 _toVal) = __updateHistory(_h, add, _value);

			// emit an event
			emit VotingPowerChanged(_by, _to, _fromVal, _toVal);
		}
	}

	/**
	 * @dev Auxiliary function to append key-value pair to an array,
	 *      sets the key to the current block number and
	 *      value as derived
	 *
	 * @param _h array of key-value pairs to append to
	 * @param op a function (add/subtract) to apply
	 * @param _delta the value for a key-value pair to add/subtract
	 */
	function __updateHistory(
		KV[] storage _h,
		function(uint256,uint256) pure returns(uint256) op,
		uint256 _delta
	) private returns(uint256 _fromVal, uint256 _toVal) {
		// init the old value - value of the last pair of the array
		_fromVal = _h.length == 0? 0: _h[_h.length - 1].v;
		// init the new value - result of the operation on the old value
		_toVal = op(_fromVal, _delta);

		// if there is an existing voting power value stored for current block
		if(_h.length != 0 && _h[_h.length - 1].k == block.number) {
			// update voting power which is already stored in the current block
			_h[_h.length - 1].v = uint192(_toVal);
		}
		// otherwise - if there is no value stored for current block
		else {
			// add new element into array representing the value for current block
			_h.push(KV(uint64(block.number), uint192(_toVal)));
		}
	}

	/**
	 * @dev Auxiliary function to lookup for a value in a sorted by key (ascending)
	 *      array of key-value pairs
	 *
	 * @dev This function finds a key-value pair element in an array with the closest key
	 *      to the key of interest (not exceeding that key) and returns the value
	 *      of the key-value pair element found
	 *
	 * @dev An array to search in is a KV[] key-value pair array ordered by key `k`,
	 *      it is sorted in ascending order (`k` increases as array index increases)
	 *
	 * @dev Returns zero for an empty array input regardless of the key input
	 *
	 * @param _h an array of key-value pair elements to search in
	 * @param _k key of interest to look the value for
	 * @return the value of the key-value pair of the key-value pair element with the closest
	 *      key to the key of interest (not exceeding that key)
	 */
	function __binaryLookup(KV[] storage _h, uint256 _k) private view returns(uint256) {
		// if an array is empty, there is nothing to lookup in
		if(_h.length == 0) {
			// by documented agreement, fall back to a zero result
			return 0;
		}

		// check last key-value pair key:
		// if the key is smaller than the key of interest
		if(_h[_h.length - 1].k <= _k) {
			// we're done - return the value from the last element
			return _h[_h.length - 1].v;
		}

		// check first voting power history record block number:
		// if history was never updated before the block of interest
		if(_h[0].k > _k) {
			// we're done - voting power at the block num of interest was zero
			return 0;
		}

		// left bound of the search interval, originally start of the array
		uint256 i = 0;

		// right bound of the search interval, originally end of the array
		uint256 j = _h.length - 1;

		// the iteration process narrows down the bounds by
		// splitting the interval in a half oce per each iteration
		while(j > i) {
			// get an index in the middle of the interval [i, j]
			uint256 k = j - (j - i) / 2;

			// read an element to compare it with the value of interest
			KV memory kv = _h[k];

			// if we've got a strict equal - we're lucky and done
			if(kv.k == _k) {
				// just return the result - pair value at index `k`
				return kv.v;
			}
			// if the value of interest is larger - move left bound to the middle
			else if (kv.k < _k) {
				// move left bound `i` to the middle position `k`
				i = k;
			}
			// otherwise, when the value of interest is smaller - move right bound to the middle
			else {
				// move right bound `j` to the middle position `k - 1`:
				// element at position `k` is greater and cannot be the result
				j = k - 1;
			}
		}

		// reaching that point means no exact match found
		// since we're interested in the element which is not larger than the
		// element of interest, we return the lower bound `i`
		return _h[i].v;
	}

	/**
	 * @dev Adds a + b
	 *      Function is used as a parameter for other functions
	 *
	 * @param a addition term 1
	 * @param b addition term 2
	 * @return a + b
	 */
	function add(uint256 a, uint256 b) private pure returns(uint256) {
		// add `a` to `b` and return
		return a + b;
	}

	/**
	 * @dev Subtracts a - b
	 *      Function is used as a parameter for other functions
	 *
	 * @dev Requires a ≥ b
	 *
	 * @param a subtraction term 1
	 * @param b subtraction term 2, b ≤ a
	 * @return a - b
	 */
	function sub(uint256 a, uint256 b) private pure returns(uint256) {
		// subtract `b` from `a` and return
		return a - b;
	}

	// ===== End: DAO Support (Compound-like voting delegation) =====

}