// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "./ERC20.sol";
import "./CErc20.sol";
import "./Comptroller.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract TreasuryAdaptor {
    /** Custom errors **/

    error Unauthorized();
    error ReusedKnownNonce();
    error NotEnoughSigners();
    error NotActiveWithdrawalAddress();
    error NotActiveOperator();
    error DuplicateSigners();
    error SignatureExpired();
    error DuplicatedAddress();
    error Erc20TransferError();
    /// @dev RedeemError to indicate if CErc20(cUsdc).redeemUnderlying(amount) is
    /// successful, otherwise revert with the error code which is specified in ErrorReporter.sol of CErc20 repo
    /// (https://github.com/compound-finance/compound-protocol/blob/master/contracts/ErrorReporter.sol)
    error CErc20RedeemError(uint256 errorCode);
    /// @dev CErc20MintError to indicate if CErc20(cUsdc).mint(amount) is
    /// successful, otherwise revert with the error code which is specified in ErrorReporter.sol of CErc20 repo
    /// (https://github.com/compound-finance/compound-protocol/blob/master/contracts/ErrorReporter.sol)
    error CErc20MintError(uint256 errorCode);

    /** Custom events */
    event Pushed(uint256 amount);
    event AddedNewOperator(address indexed addr, uint256 timelock);
    event RemovedOperator(address indexed addr, uint256 timelock);
    event AddedNewWithdrawalAddress(address indexed addr, uint256 timelock);
    event RemovedWithdrawalAddress(address indexed addr, uint256 timelock);
    event WithdrewFundsTo(uint256 amount, address indexed dest);
    event WithdrewCompTo(uint256 amount, address indexed dest);

    /** Public constants **/

    /// @notice The address of the USDC contract
    address public immutable usdc;

    /// @notice The address of the cUSDC contract
    address public immutable cUsdc;

    /// @notice The address of the COMP contract
    address public immutable comp;

    /// @notice The address of the Comptroller contract
    address public immutable comptroller;

    /// @notice Operational user mapping
    /// Operational users can transfer back to the withdrawal address with a threshold of operatorThreshold
    mapping(address => uint256) public operators;

    /// @notice The Operator block list
    /// Will be unavailable delay after set by admin
    mapping(address => uint256) public operatorsBlocklist;

    /// @notice Admin for changing the operators in an emergency
    address public immutable admin;

    /// @notice The withdrawal address set by admin
    /// Circle Withdrawal wallet, with availability for further use during a migration
    /// Available delay after Admin listing
    mapping(address => uint256) public withdrawalAddresses;

    /// @notice The Withdrawal Address block list
    /// Unavailable delay after set by admin
    mapping(address => uint256) public withdrawalAddressesBlocklist;

    /// @notice The used nonces record mapping
    /// Just need to make sure the same nonce never get used twice
    mapping(bytes32 => uint256) public knownNonces;

    /// @notice Threshold for executing operator command of withdrawing to withdrawal address
    uint256 public immutable operatorThreshold;

    /// @notice inline delay
    uint256 public immutable delay;

    /// --- Below is parameters need to make signing process of this contract to compatible with EIP-712 ---
    /// @notice The name of this contract
    string public constant name = "Treasury Adaptor";

    /// @notice The major version of this contract
    string public constant version = "0";

    /** Internal constants **/

    /// @dev The EIP-712 typehash for the contract's domain
    bytes32 internal constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /// @dev The EIP-712 typehash for operator authorization
    /// amount, destination address, and nonce
    bytes32 internal constant AUTHORIZATION_TYPEHASH =
        keccak256(
            "Authorization(uint256 amount,address destination,uint256 expiry,bytes32 nonce)"
        );

    /// @notice Construct of TreasusryAdaptor
    /// @param cUsdcAddr The address of cToken of USDC that's supported by compound protocol
    /// @param compAddr The address of COMP token
    /// @param adminMultisig The address of the admin multi sig wallet
    /// @param initialOperators list of initial operator addresses
    /// @param initialWithdrawalAddresses list of initial withdrawal addresses
    /// @param opThreshold number of operators required to trigger withdraw actions
    /// @param delayTime time delay required for admin changes
    constructor(
        address cUsdcAddr,
        address compAddr,
        address adminMultisig,
        address[] memory initialOperators,
        address[] memory initialWithdrawalAddresses,
        uint256 opThreshold,
        uint256 delayTime
    ) {
        admin = adminMultisig;
        cUsdc = cUsdcAddr;
        comptroller = address(CErc20(cUsdc).comptroller());
        comp = compAddr;
        usdc = CErc20(cUsdc).underlying();
        ERC20(usdc).approve(cUsdc, type(uint256).max);
        operatorThreshold = opThreshold;
        delay = delayTime;

        // Add initial operators and withdrawal addresses
        for (uint256 i = 0; i < initialOperators.length; i++) {
            operators[initialOperators[i]] = block.timestamp;
            emit AddedNewOperator(initialOperators[i], block.timestamp);
        }
        for (uint256 i = 0; i < initialWithdrawalAddresses.length; i++) {
            withdrawalAddresses[initialWithdrawalAddresses[i]] = block
                .timestamp;
            emit AddedNewWithdrawalAddress(
                initialWithdrawalAddresses[i],
                block.timestamp
            );
        }
    }

    /// @notice Push fund that this contract holds to compound protocol
    /// Anyone can invoke this function, since it won't have risk to be called by other people
    function push() external {
        uint256 amount = ERC20(usdc).balanceOf(address(this));
        uint256 code = CErc20(cUsdc).mint(amount);
        if (code != 0) revert CErc20MintError(code);
        emit Pushed(amount);
    }

    /// @notice Add oeprator to the list by adding the address to operators list
    /// @param newOperator new operator address to add
    function addOperator(address newOperator) external {
        if (msg.sender != admin) revert Unauthorized();
        if (operators[newOperator] != 0) revert DuplicatedAddress();
        uint256 timestamp = block.timestamp + delay;
        operators[newOperator] = timestamp;
        emit AddedNewOperator(newOperator, timestamp);
    }

    /// @notice Remove operator from the list by adding the address to operatorsBlocklist
    /// @param oldOperator operator address to remove
    function removeOperator(address oldOperator) external {
        if (msg.sender != admin) revert Unauthorized();
        if (operatorsBlocklist[oldOperator] != 0) revert DuplicatedAddress();
        uint256 timestamp = operators[oldOperator] >= block.timestamp
            ? block.timestamp // Set timelock delay timestamp to now, to block the pending active address right away
            : block.timestamp + delay;
        operatorsBlocklist[oldOperator] = timestamp;
        emit RemovedOperator(oldOperator, timestamp);
    }

    /// @notice Withdraw fund from compound protocol
    /// Required at least <operatorThreshold> operators signatures to proceed
    /// Withdrawal fund will be sent to destination address
    /// Destination address has to been added and active in withdrawalAddresses list
    /// @param amount amount of fund to withdraw
    /// @param destination destination address to withdraw to, the address has to be added to withdrawal address list
    /// @param signatures signatures that operator signed with their key
    /// @param expiry expiration of the signature
    /// @param nonce nonce of the signature, to prevent replay attack
    function withdraw(
        uint256 amount,
        address destination,
        uint256 expiry,
        bytes32 nonce,
        bytes[] memory signatures
    ) external {
        if (knownNonces[nonce] != 0) revert ReusedKnownNonce();
        if (block.timestamp >= expiry) revert SignatureExpired();
        if (signatures.length < operatorThreshold) revert NotEnoughSigners();
        if (
            !isActive(
                withdrawalAddresses[destination],
                withdrawalAddressesBlocklist[destination]
            )
        ) revert NotActiveWithdrawalAddress();
        bytes32 digest = createDigestMessage(
            amount,
            destination,
            expiry,
            nonce
        );
        // Verify address are unique
        // Address recovered from signatures must be strictly increasing, in order to prevent duplicates
        address lastSignerAddr = address(0); // cannot have address(0) as an ownerx
        for (uint256 i = 0; i < signatures.length; i++) {
            address recoveredSigner = ECDSA.recover(digest, signatures[i]);
            if (recoveredSigner <= lastSignerAddr) revert DuplicateSigners();
            if (
                !isActive(
                    operators[recoveredSigner],
                    operatorsBlocklist[recoveredSigner]
                )
            ) revert NotActiveOperator();
            lastSignerAddr = recoveredSigner;
        }
        // Mark nonce with block.timestamp
        knownNonces[nonce] = block.timestamp;
        uint256 code = CErc20(cUsdc).redeemUnderlying(amount);
        if (code != 0) revert CErc20RedeemError(code);
        bool success = ERC20(usdc).transfer(destination, amount);
        if (!success) revert Erc20TransferError();
        emit WithdrewFundsTo(amount, destination);
    }

    /// @notice Generage digest message with EIP-712 typehash info
    /// @param amount the amount to withdraw
    /// @param destination withdrawal address
    /// @param expiry expiration of the signature
    /// @param nonce current nonce of the contract
    /// @return message to sign later on
    function createDigestMessage(
        uint256 amount,
        address destination,
        uint256 expiry,
        bytes32 nonce
    ) public view returns (bytes32) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                block.chainid,
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(
                AUTHORIZATION_TYPEHASH,
                amount,
                destination,
                expiry,
                nonce
            )
        );
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
    }

    /// @notice Withdraw comp to admin wallet
    /// There is no risk for anyone calling it, since it only withdraw comp to admin's wallet
    /// So it won't check on the authorization on the caller
    function withdrawComp() external {
        Comptroller(comptroller).claimComp(address(this));
        uint256 amount = ERC20(comp).balanceOf(address(this));
        bool success = ERC20(comp).transfer(admin, amount);
        if (!success) revert Erc20TransferError();
        emit WithdrewCompTo(amount, admin);
    }

    /// @notice Add withdrawal address to allow list with delay activation timestamp
    /// The address will only be usable after the specified delay elapsed
    /// Only admin can proceed this action
    /// @param recipient the address to add
    function addWithdrawalAddress(address recipient) external {
        if (msg.sender != admin) revert Unauthorized();
        if (withdrawalAddresses[recipient] != 0) revert DuplicatedAddress();
        uint256 timestamp = block.timestamp + delay;
        withdrawalAddresses[recipient] = timestamp;
        emit AddedNewWithdrawalAddress(recipient, timestamp);
    }

    /// @dev Remove withdrawal address via adding it to block list with delay activation timestamp
    /// The address will only be blocked after the specified delay elapsed
    /// Only admin can proceed this action
    /// @param recipient address to remove from the list
    function removeWithdrawalAddress(address recipient) external {
        if (msg.sender != admin) revert Unauthorized();
        if (withdrawalAddressesBlocklist[recipient] != 0)
            revert DuplicatedAddress();
        uint256 timestamp = withdrawalAddresses[recipient] >= block.timestamp
            ? block.timestamp // Set timelock delay timestamp to now, to block the pending active address right away
            : block.timestamp + delay;
        withdrawalAddressesBlocklist[recipient] = timestamp;
        emit RemovedWithdrawalAddress(recipient, timestamp);
    }

    /// @dev Check if the target address is active or not by comparing the timestamp in allow list and block list
    /// Active means when the address has been added to the allow list and has not been blocked yet
    /// @param allowlistTimestamp timestamp in allow list
    /// @param blocklistTimestamp timestamp in block list
    /// @return boolean to indicate if the address is active (completedTimelock(allow_list) && !completedTimelock(block_list))
    function isActive(uint256 allowlistTimestamp, uint256 blocklistTimestamp)
        public
        view
        returns (bool)
    {
        return
            completedTimelock(allowlistTimestamp) &&
            !completedTimelock(blocklistTimestamp);
    }

    /// @dev Helper function to check if the current timestamp has pass the specified timestamp or not
    /// @param timestamp timestamp to check if it has passed the block.timestamp or not
    /// @return bool to show if timestamp has passed the block.timestamp
    function completedTimelock(uint256 timestamp) private view returns (bool) {
        return timestamp != 0 && timestamp < block.timestamp;
    }

    /// @dev Helper function to check if address is operator or not
    /// @param addr address to check
    /// @return bool to indicate if the address is active oeprator or not
    function isOperator(address addr) external view returns (bool) {
        return isActive(operators[addr], operatorsBlocklist[addr]);
    }

    /// @dev Helper function to check if addres is withdrawal address
    /// @param addr address to check
    /// @return bool to indicate if the address is active withdrawal address or not
    function isWithdrawalAddress(address addr) external view returns (bool) {
        return
            isActive(
                withdrawalAddresses[addr],
                withdrawalAddressesBlocklist[addr]
            );
    }
}