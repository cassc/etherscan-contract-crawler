// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IERC20WithEIP3009.sol";
import "./interfaces/IRootChainManager.sol";
import "./EnumerableSet.sol";

contract DepositRouter is Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    /* EVENTS */
    event RegisterRelay(address indexed relay, string url);

    // sender is the account that called the function
    event DeregisterRelay(address indexed relay, address sender);
    event DepositRelayed(address indexed relayer, address indexed depositor, uint256 amount, uint256 fee);

    /* EXTERNAL CONTRACTS */

    IRootChainManager public rootChainManager;
    IERC20WithEIP3009 public rootToken;
    address public predicateContract;

    /* RELAYER INFO */

    // collected fees for each relayer
    mapping(address => uint256) public collectedFees;

    // stake required to become a relayer
    uint256 public stakeAmount;

    EnumerableSet.AddressSet private _relayers;

    mapping(address => string) public relayerUrl;

    // because stake amount can be changed by owner we need to track how much each staked
    mapping(address => uint256) public relayerStake;

    mapping(address => bool) public blacklisted;

    /* EIP712 */

    mapping(address => uint256) public depositNonces;

    bytes32 public domainSeparator;

    // The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
    );

    // The EIP-712 typehash for the deposit id struct
    bytes32 public constant DEPOSIT_TYPEHASH = keccak256(
        "Deposit(address relayer,address depositRecipient,uint256 fee,uint256 maxBlock,uint256 nonce)"
    );

    string public constant NAME = "Polymarket Deposit Router";

    /* STRUCTS */

    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /* CONSTRUCTOR */

    constructor(
        IERC20WithEIP3009 _rootToken,
        IRootChainManager _rootChainManager,
        address _predicateContract,
        address owner,
        uint256 _stakeAmount
    ) {
        rootToken = _rootToken;
        rootChainManager = _rootChainManager;
        predicateContract = _predicateContract;

        // hit predicateContract with a max approval
        rootToken.approve(predicateContract, type(uint256).max);

        stakeAmount = _stakeAmount;

        transferOwnership(owner);

        domainSeparator = keccak256(abi.encode(
            DOMAIN_TYPEHASH,
            keccak256(bytes(NAME)),
            _getChainIdInternal(),
            address(this)
        ));
    }

    /* VIEW FUNCTIONS */

    function getRelayers() public view returns (address[] memory) {
        return _relayers.values();
    }

    function getRelayersWithUrls() external view returns (bytes[] memory relayerInfo) {
        uint256 length = _relayers.length();
        relayerInfo = new bytes[](length);

        for (uint i = 0; i < length; i++) {
            address relayer = _relayers.at(i);

            relayerInfo[i] = abi.encode(relayer, relayerUrl[relayer]);
        }
    }

    function isRegistered(address maybeRelay) external view returns (bool) {
        return _relayers.contains(maybeRelay);
    }

    /* ADMIN FUNCTIONS */

    function setStakeAmount(uint256 newAmount) external onlyOwner {
        stakeAmount = newAmount;
    }

    function adminDeregister(address relay) external onlyOwner {
        _blacklist(relay);
        _deregister(relay);
    }

    function blacklist(address relay) external onlyOwner {
        _blacklist(relay);
    }

    function unBlacklist(address relay) external onlyOwner {
        blacklisted[relay] = false;
    }

    /* RELAYER FUNCTIONS */

    function register(string calldata url) external payable nonReentrant {
        require(!blacklisted[msg.sender], "DepositRouter::register: relay has been blacklisted");
        require(!_relayers.contains(msg.sender), "DepositRouter::register: relay already registered");
        require(msg.value >= stakeAmount, "DepositRouter:register: insufficient stake amount");

        relayerStake[msg.sender] += stakeAmount;
        _relayers.add(msg.sender);
        relayerUrl[msg.sender] = url;

        // refund dust eth if any
        if (msg.value > stakeAmount) {
            (bool success, ) = msg.sender.call{ value: msg.value - stakeAmount }("");
            require(success, "DepositRouter:register: refund failed.");
        }

        emit RegisterRelay(msg.sender, url);
    }

    function setRelayerUrl(string calldata url) external {
        require(_relayers.contains(msg.sender), "DepositRouter::setRelayerUrl: relay must be registered to change its url");

        relayerUrl[msg.sender] = url;
    }

    function deregister() external {
        _deregister(msg.sender);
    }

    function claimFees(address to, uint256 amount) external {
        require(collectedFees[msg.sender] >= amount, "DepositRouter::claimFees: cannot claim more fees than the accout has");

        unchecked {
            collectedFees[msg.sender] -= amount;
        }

        rootToken.transfer(to, amount);
    }

    /* DEPOSIT INTO MATIC */

    /**
     * @dev deposit funds to Matic. Since this is expected to be called in a meta transaction and
     * `IRootChainManager.depositFor` relies on msg.sender, we transfer funds to this contract
     * and then `depositFor` on this contract to the `depositRecipient` on matic.
     * Note: RootChainManager has an `executeMetaTransaction` function but this method to deposit uses less gas.
     *
     * @param from - the address executing the deposit
     * @param depositRecipient - the address to receive the deposit on matic
     * @param totalValue - the amount to deposit
     * @param fee - the fee to pay for gas.
     * @param validBefore - the deadline for executing the deposit
     * @param nonce - a unique random nonce for receiveWithAuthorization (NOT a sequential nonce see
     *      https://eips.ethereum.org/EIPS/eip-3009#unique-random-nonce-instead-of-sequential-nonce)
     * @param maxBlock - the maximum block that the deposit can be included in to prevent relayers
     *      from waiting until transaction fee decreases to submit the transaction
     * @param receiveSig - the EIP712 signature for `IERC20WithEIP3009.receiveWithAuthorization`
     * @param depositSig - the EIP712 signature for the deposit
     */
    function deposit(
        address from,
        address depositRecipient,
        uint256 totalValue,
        uint256 fee,
        uint256 validBefore,
        bytes32 nonce,
        uint256 maxBlock,
        Sig calldata receiveSig,
        Sig calldata depositSig
    ) external {
        // require relayer is registered
        require(_relayers.contains(msg.sender), "DepositRouter::deposit: relayer is not registered");
        require(block.number <= maxBlock, "DepositRouter::deposit: cannot relay transaction after max block");

        // verify the user has agreed to the deposit
        _verifyDepositSig(from, depositRecipient, fee, maxBlock, depositSig);

        /**
         * receiveWithAuthorization rather than transferWithAuthorization to prevent front-running
         * attack where someone takes a transferWithAuthorization signature before the transaction has been mined
         * and executes the transfer so that this depositCall would fail and the funds would be stuck in
         * this contract.
         */
        rootToken.receiveWithAuthorization(
            from,
            address(this),
            totalValue,
            0,
            validBefore,
            nonce,
            receiveSig.v,
            receiveSig.r,
            receiveSig.s
        );

        uint256 depositAmount = totalValue - fee; // will revert on underflow

        rootChainManager.depositFor(
            depositRecipient,
            address(rootToken),
            abi.encode(depositAmount) 
        );

        collectedFees[msg.sender] += fee;

        emit DepositRelayed(msg.sender, from, depositAmount, fee);
    }

    /* INTERNAL FUNCTIONS */

    function _deregister(address relay) internal nonReentrant {
        require(_relayers.contains(relay), "DepositRouter::deregister: relay is not already registered");

        uint256 previousStake = relayerStake[relay];

        relayerStake[relay] = 0;
        _relayers.remove(relay);
        delete relayerUrl[relay];

        (bool success, ) = relay.call{ value: previousStake }("");
        require(success, "DepositRouter::deregister: refund stake failed");

        emit DeregisterRelay(relay, msg.sender);
    }

    function _getChainIdInternal() internal view returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    function _verifyDepositSig(address from, address depositRecipient, uint256 fee, uint256 maxBlock, Sig calldata sig) internal {
        bytes32 structHash = keccak256(abi.encode(DEPOSIT_TYPEHASH, msg.sender, depositRecipient, fee, maxBlock, depositNonces[from]++));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        
        require(from == ECDSA.recover(digest, sig.v, sig.r, sig.s), "DepositRouter::_verifyDepositSig: unable to verify deposit sig");
    }

    function _blacklist(address relay) internal {
        blacklisted[relay] = true;
    }
}