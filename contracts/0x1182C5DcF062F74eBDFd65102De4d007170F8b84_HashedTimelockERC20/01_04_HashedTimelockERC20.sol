// SPDX-License-Identifier: Blockchain Commodities
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
/**
* Hashed Timelock Contracts (HTLCs) on Ethereum ERC20 tokens.
*
* This contract provides a way to create and keep HTLCs for ERC20 tokens.
*
* See HashedTimelock.sol for a contract that provides the same functions
* for the native ETH token.
*
* Protocol:
*
*  1) newContract(receiver, hashlock, timelock, tokenContract, amount) - a
*      sender calls this to create a new HTLC on a given token (tokenContract)
*       for a given amount. A 32 byte contract id is returned
*  2) withdraw(contractId, preimage) - once the receiver knows the preimage of
*      the hashlock hash they can claim the tokens with this function
*  3) refund() - after timelock has expired and if the receiver did not
*      withdraw the tokens the sender / creator of the HTLC can get their tokens
*      back with this function.
 */
contract HashedTimelockERC20 {

    using SafeERC20 for IERC20;

    // PARAMS
    uint32 public feeNumerator;
    uint32 public feeDenominator;
    address public feeReceiver;
    address public owner;
    bytes32 private emptyLockContractHash;

    /**
     * Setting initial values for the smart contract when it is deployed, all these values can be configured later
     */
    constructor(address initialOwner, address initialFeeReceiver, uint32 initialFeeNumerator, uint32 initialFeeDenominator) {
        require(initialOwner != address(0), "40207: INVALID OWNER");
        require(initialFeeDenominator != 0, "40209: INVALID DENOMINATOR");
        owner = initialOwner;
        feeReceiver = initialFeeReceiver;
        feeNumerator = initialFeeNumerator;
        feeDenominator = initialFeeDenominator;
        emptyLockContractHash = getEmptyContractHash();
    }

    struct LockContract {
        uint256 amount;
        bytes32 hashLock;
        bytes32 preimage;
        uint32 timeLock;
        address sender;
        address receiver;
        address tokenContract;
        bool collected;
    }

    mapping(bytes32 => LockContract) public contracts;

    event HTLCERC20New(
        bytes32 indexed contractId,
        bytes32 hashlock,
        uint32 timelock,
        address indexed sender,
        address indexed receiver,
        address tokenContract,
        uint256 amount
    );
    event HTLCERC20Withdraw(bytes32 indexed contractId);
    event HTLCERC20Refund(bytes32 indexed contractId);
    event HTLCERC20NewOwner(address owner);
    event HTLCERC20NewFeeReceiver(address feeReceiver);
    event HTLCFeeUpdated(uint32 feeNumerator, uint32 feeDenominator);

    modifier onlyOwner() {
        require(msg.sender == owner, "40301: FORBIDDEN");
        _;
    }

    modifier onlyFeeReceiver() {
        require(msg.sender == feeReceiver, "40302: FORBIDDEN");
        _;
    }

    modifier tokensTransferable(address token, address sender, uint256 amount) {
        require(amount > 0, "40201: FUNDS REQUIRED");
        require(
            IERC20(token).allowance(sender, address(this)) >= amount, "40203: FUNDS REFUSAL"
        );
        _;
    }
    modifier futureTimeLock(uint32 time) {
        // only requirement is the time lock time is after the last block time (now).
        // probably want something a bit further in the future then this.
        // but this is still a useful sanity check:
        require(time > block.timestamp, "40011: INVALID VALUE");
        _;
    }
    modifier contractExists(bytes32 contractId) {
        require(haveContract(contractId), "40400: NOT FOUND");
        _;
    }
    modifier hashLockMatches(bytes32 contractId, bytes32 x) {
        require(
            contracts[contractId].hashLock == keccak256(abi.encodePacked(x)), "40100: UNAUTHORIZED"
        );
        _;
    }
    modifier withdrawable(bytes32 contractId) {
        require(contracts[contractId].receiver == msg.sender, "40303: FORBIDDEN");
        require(!contracts[contractId].collected, "40900: CONFLICT");
        _;
    }
    modifier refundable(bytes32 _contractId) {
        require(contracts[_contractId].sender == msg.sender, "40304: FORBIDDEN");
        require(!contracts[_contractId].collected, "40900: CONFLICT");
        require(contracts[_contractId].timeLock <= block.timestamp, "40101: UNAUTHORIZED");
        _;
    }


    /**
     * Sender / Payer sets up a new hash time lock contract depositing the
     * funds and providing the reciever and terms.
     *
     * NOTE: _receiver must first call approve() on the token contract.
     *       See allowance check in tokensTransferable modifier.

     * @param receiver Receiver of the tokens.
     * @param hashLock A keccak256 hash hashlock.
     * @param timeLock UNIX epoch seconds time that the lock expires at.
     *                  Refunds can be made after this time.
     * @param tokenContract ERC20 Token contract address.
     * @param amount Amount of the token to lock up.
     * @return contractId Id of the new HTLC. This is needed for subsequent
     *                    calls.
     */
    function newContract(
        address receiver,
        bytes32 hashLock,
        uint32 timeLock,
        address tokenContract,
        uint256 amount
    )
    external
    tokensTransferable(tokenContract, msg.sender, amount)
    futureTimeLock(timeLock)
    returns (bytes32 contractId)
    {
        contractId = keccak256(
            abi.encodePacked(
                msg.sender,
                receiver,
                tokenContract,
                amount,
                hashLock,
                timeLock
            )
        );

        // Reject if a contract already exists with the same parameters. The
        // sender must change one of these parameters (ideally providing a
        // different _hashLock).
        if (haveContract(contractId))
            revert("40901: CONFLICT");

        contracts[contractId] = LockContract(
            amount,
            hashLock,
            0x0,
            timeLock,
            msg.sender,
            receiver,
            tokenContract,
            false
        );

        emit HTLCERC20New(
            contractId,
            hashLock,
            timeLock,
            msg.sender,
            receiver,
            tokenContract,
            amount
        );

        // This contract becomes the temporary owner of the tokens
        IERC20(tokenContract).safeTransferFrom(msg.sender, address(this), amount);

        return contractId;
    }

    /**
    * Called by the receiver once they know the preimage of the hashlock.
    * This will transfer ownership of the locked tokens to their address.
    *
    * @param contractId Id of the HTLC.
    * @param preimage keccak256(_preimage) should equal the contract hashlock.
    * @return bool true on success
     */
    function withdraw(bytes32 contractId, bytes32 preimage)
    external
    contractExists(contractId)
    hashLockMatches(contractId, preimage)
    withdrawable(contractId)
    returns (bool)
    {
        uint256 amount = contracts[contractId].amount;
        address tokenContract = contracts[contractId].tokenContract;
        address receiver = contracts[contractId].receiver;
        contracts[contractId].preimage = preimage;
        contracts[contractId].collected = true;
        delete contracts[contractId].amount;
        delete contracts[contractId].hashLock;
        delete contracts[contractId].timeLock;
        delete contracts[contractId].sender;
        delete contracts[contractId].receiver;
        delete contracts[contractId].tokenContract;
        emit HTLCERC20Withdraw(contractId);
        if (feeReceiver != address(0)) {
            uint fee = amount * feeNumerator / feeDenominator;
            uint withdrawalAmount = amount - fee;
            IERC20(tokenContract).safeTransfer(receiver, withdrawalAmount);
            IERC20(tokenContract).safeTransfer(feeReceiver, fee);
        } else {
            IERC20(tokenContract).safeTransfer(receiver, amount);
        }
        return true;
    }

    /**
     * Called by the sender if there was no withdraw AND the time lock has
     * expired. This will restore ownership of the tokens to the sender.
     *
     * @param contractId Id of HTLC to refund from.
     * @return bool true on success
     */
    function refund(bytes32 contractId)
    external
    contractExists(contractId)
    refundable(contractId)
    returns (bool)
    {
        uint256 amount = contracts[contractId].amount;
        address tokenContract = contracts[contractId].tokenContract;
        address sender = contracts[contractId].sender;
        contracts[contractId].collected = true;
        delete contracts[contractId].amount;
        delete contracts[contractId].hashLock;
        delete contracts[contractId].timeLock;
        delete contracts[contractId].sender;
        delete contracts[contractId].receiver;
        delete contracts[contractId].tokenContract;
        emit HTLCERC20Refund(contractId);
        IERC20(tokenContract).safeTransfer(sender, amount);
        return true;
    }

    /**
     * Get contract details.
     * @param contractId HTLC contract id
     */
    function getContract(bytes32 contractId)
    external
    view
    returns (
        uint256 amount,
        bytes32 hashlock,
        bytes32 preimage,
        uint32 timelock,
        address sender,
        address receiver,
        address tokenContract,
        bool collected
    )
    {
        if (!haveContract(contractId))
            return (0, 0, 0, 0, address(0), address(0), address(0), false);
        LockContract memory fetchedContract = contracts[contractId];
        return (
        fetchedContract.amount,
        fetchedContract.hashLock,
        fetchedContract.preimage,
        fetchedContract.timeLock,
        fetchedContract.sender,
        fetchedContract.receiver,
        fetchedContract.tokenContract,
        fetchedContract.collected
        );
    }

    /**
     * Is there a contract with id _contractId.
     * @param contractId Id into contracts mapping.
     */
    function haveContract(bytes32 contractId)
    internal
    view
    returns (bool exists)
    {
        return keccak256(abi.encodePacked(contracts[contractId].amount,
            contracts[contractId].hashLock,
            contracts[contractId].preimage,
            contracts[contractId].timeLock,
            contracts[contractId].sender,
            contracts[contractId].receiver,
            contracts[contractId].tokenContract,
            contracts[contractId].collected))
        != emptyLockContractHash;
    }

    /**
     * This method return a keccak256 hash of an empty Lock contract.
     */
    function getEmptyContractHash() pure private returns (bytes32) {
        uint256 u256 = 0;
        bytes32 b32 = 0;
        uint32 u32 = 0;
        address add = address(0);
        bool b = false;
        return keccak256(abi.encodePacked(u256, b32, b32, u32, add, add, add, b));
    }


    /**
     * This method will update the feeTo address who can withdraw the
     * fee collected on this smart contract
     * @param feeReceiverAddress - address of new fee collector
     */
    function updateFeeReceiver(address feeReceiverAddress) onlyOwner external {
        feeReceiver = feeReceiverAddress;
        emit HTLCERC20NewFeeReceiver(feeReceiver);
    }

    /**
     * This method will update the owner address on this smart contract
     * @param ownerAddress - address of new owner
     */
    function updateOwner(address ownerAddress) onlyOwner external {
        require(ownerAddress != address(0), "40207: INVALID OWNER");
        owner = ownerAddress;
        emit HTLCERC20NewOwner(owner);
    }

    /**
     * This method will allow owner to update the fee charged upon successful withdrawal
     * @param updatedFeeNumerator - new fee numerator
     * @param updatedFeeDenominator - new fee denominator
     */
    function updateFee(uint32 updatedFeeNumerator, uint32 updatedFeeDenominator) onlyOwner external {
        require(updatedFeeNumerator != 0, "40208: INVALID NUMERATOR");
        require(updatedFeeDenominator != 0, "40209: INVALID DENOMINATOR");
        feeNumerator = updatedFeeNumerator;
        feeDenominator = updatedFeeDenominator;
        emit HTLCFeeUpdated(feeNumerator, feeDenominator);
    }

}