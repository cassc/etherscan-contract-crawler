// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import {IInvestmentEarnings} from "./IInvestmentEarnings.sol";
import {IPool} from "./IPool.sol";
import {WTHToken} from "./WTHToken.sol";


/**
 * @title WealthPool contract
 *
 * @notice Main point of interaction with an Wealth protocol's market
 * - Users can:
 *   # Supply
 *   # Withdraw
 *   # Borrow
 *   # Repay
 *   # Swap their loans between variable and stable rate
 *   # Enable/disable their supplied assets as collateral rebalance stable rate borrow positions
 *   # Liquidate positions
 *   # Execute Flash Loans
 * @dev To be covered by a proxy contract, owned by the PoolAddressesProvider of the specific market
 * @dev All admin functions are callable by the PoolConfigurator contract defined also in the
 *   PoolAddressesProvider
 **/
contract WealthPool is WTHToken, IPool {
    uint256 public constant POOL_REVISION = 0x2;
    IInvestmentEarnings public immutable INVESTMENT_EARNINGS_CONTRACT;
    address public immutable SRC_TOKEN; // 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE stands for ETH

    uint256 public constant MAX_OWNER_COUNT = 9;

    // The N addresses which control the funds in this contract. The
    // owners of M of these addresses will need to both sign a message
    // allowing the funds in this contract to be spent.
    mapping(address => bool) private isOwner;
    address[] private owners;
    uint256 private immutable required;

    // The contract nonce is not accessible to the contract so we
    // implement a nonce-like variable for replay protection.
    uint256 private spendNonce = 0;
    uint256 public allowInternalCall = 1;

    bytes4 private constant TRANSFER_SELECTOR =
        bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 private constant TRANSFER_FROM_SELECTOR =
        bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));

    address private constant ETH_CONTRACT =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // An event sent when funds are received.
    event Funded(address from, uint256 value);

    // An event sent when a setAllowInternalCall is triggered.
    event AllowInternalCallUpdated(uint256 value);

    // An event sent when a spend is triggered to the given address.
    event Spent(address to, uint256 transfer);

    // An event sent when a spendERC20 is triggered to the given address.
    event SpentERC20(address erc20contract, address to, uint256 transfer);

    modifier validRequirement(uint256 ownerCount, uint256 _required) {
        require(
            ownerCount <= MAX_OWNER_COUNT &&
                _required <= ownerCount &&
                _required >= 1
        );
        _;
    }

    /**
     * @dev Constructor.
     * @param _owners List of initial owners.
     * @param _required Number of required confirmations.
     */
    constructor(
        IInvestmentEarnings investmentEarnings,
        address srcToken,
        address[] memory _owners,
        uint256 _required
    ) validRequirement(_owners.length, _required) {
        INVESTMENT_EARNINGS_CONTRACT = investmentEarnings;
        SRC_TOKEN = srcToken;
        for (uint256 i = 0; i < _owners.length; i++) {
            //onwer should be distinct, and non-zero
            if (isOwner[_owners[i]] || _owners[i] == address(0x0)) {
                revert();
            }
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    /**
     * @dev Leaves the contract without owners. It will not be possible to call
     * with signature check anymore. Can only be called by the current owners.
     *
     * NOTE: Renouncing ownership will leave the contract without owners,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership(
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) external {
        bytes32 renounceOwnershipTypeHash = keccak256(
            "RenounceOwnership(uint256 spendNonce)"
        );
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(renounceOwnershipTypeHash, spendNonce))
            )
        );
        require(_validMsgSignature(digest, vs, rs, ss), "invalid signatures");
        for (uint256 i = 0; i < owners.length; i++) {
            isOwner[owners[i]] = false;
        }
        delete owners;
    }

    // The receive function for this contract.
    receive() external payable {
        if (msg.value > 0) {
            emit Funded(msg.sender, msg.value);
        }
    }

    // @dev Returns list of owners.
    // @return List of owner addresses.
    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function getSpendNonce() external view returns (uint256) {
        return spendNonce;
    }

    function getRequired() external view returns (uint256) {
        return required;
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(TRANSFER_SELECTOR, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "WealthPool: TRANSFER_FAILED"
        );
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(TRANSFER_FROM_SELECTOR, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "WealthPool: TRANSFER_FROM_FAILED"
        );
    }

    // Generates the message to sign given the output destination address and amount.
    // includes this contract's address and a nonce for replay protection.
    // One option to independently verify: https://leventozturk.com/engineering/sha3/ and select keccak
    function generateMessageToSign(
        address erc20Contract,
        address destination,
        uint256 value
    ) private view returns (bytes32) {
        require(destination != address(this));
        //the sequence should match generateMultiSigV2 in JS
        bytes32 message = keccak256(
            abi.encodePacked(
                address(this),
                erc20Contract,
                destination,
                value,
                spendNonce
            )
        );
        return message;
    }

    function _messageToRecover(
        address erc20Contract,
        address destination,
        uint256 value
    ) private view returns (bytes32) {
        bytes32 hashedUnsignedMessage = generateMessageToSign(
            erc20Contract,
            destination,
            value
        );
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, hashedUnsignedMessage));
    }

    /**
     * @param _allowInternalCall: the new allowInternalCall value.
     * @param vs, rs, ss: the signatures
     */
    function setAllowInternalCall(
        uint256 _allowInternalCall,
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) external {
        require(
            _validSignature(
                address(this),
                msg.sender,
                _allowInternalCall,
                vs,
                rs,
                ss
            ),
            "invalid signatures"
        );
        spendNonce = spendNonce + 1;
        allowInternalCall = _allowInternalCall;
        emit AllowInternalCallUpdated(allowInternalCall);
    }

    /**
     * @param destination: the ether receiver address.
     * @param value: the ether value, in wei.
     * @param vs, rs, ss: the signatures
     */
    function spend(
        address destination,
        uint256 value,
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) external {
        require(destination != address(this), "Not allow sending to yourself");
        require(
            address(this).balance >= value && value > 0,
            "balance or spend value invalid"
        );
        require(
            _validSignature(address(0x0), destination, value, vs, rs, ss),
            "invalid signatures"
        );
        spendNonce = spendNonce + 1;
        (bool success, ) = destination.call{value: value}("");
        require(success, "transfer fail");
        emit Spent(destination, value);
    }

    /**
     * @param erc20contract: the erc20 contract address.
     * @param destination: the token receiver address.
     * @param value: the token value, in token minimum unit.
     * @param vs, rs, ss: the signatures
     */
    function spendERC20(
        address destination,
        address erc20contract,
        uint256 value,
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) external {
        require(destination != address(this), "Not allow sending to yourself");
        //transfer erc20 token
        require(value > 0, "Erc20 spend value invalid");
        require(
            _validSignature(erc20contract, destination, value, vs, rs, ss),
            "invalid signatures"
        );
        spendNonce = spendNonce + 1;
        // transfer tokens from this contract to the destination address
        _safeTransfer(erc20contract, destination, value);
        emit SpentERC20(erc20contract, destination, value);
    }

    /**
     * @param destination: the token receiver address.
     * @param value: the token value, in token minimum unit.
     */
    function redemption(address destination, uint256 value) external {
        require(destination != address(this), "Not allow sending to yourself");
        //transfer erc20 token
        require(value > 0, "withdraw value invalid");
        _burn(msg.sender, value);
        if (SRC_TOKEN == ETH_CONTRACT) {
            // transfer ETH
            (bool success, ) = destination.call{value: value}("");
            require(success, "transfer fail");
        } else {
            // transfer erc20 token
            _safeTransfer(SRC_TOKEN, destination, value);
        }
        emit Redeemed(msg.sender, destination, SRC_TOKEN, value);
    }

    function mint(address destination, uint256 value) external payable {
        require(destination != address(0), "ERC20: mint to the zero address");
        uint256 mintAmount = msg.value;
        if (SRC_TOKEN != ETH_CONTRACT) {
            // transfer erc20 token
            mintAmount = value;
            _safeTransferFrom(SRC_TOKEN, msg.sender, address(this), mintAmount);
        }
        _mint(destination, mintAmount);
        emit Mint(msg.sender, destination, mintAmount);
    }

    function mint(
        address destination,
        uint256 value,
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) external {
        require(destination != address(this), "Not allow sending to yourself");
        //transfer erc20 token
        require(value > 0, "Erc20 spend value invalid");
        require(
            _validSignature(address(this), destination, value, vs, rs, ss),
            "invalid signatures"
        );
        spendNonce = spendNonce + 1;
        // transfer tokens from this contract to the destination address
        // _safeTransfer(erc20contract, destination, value);

        _mint(destination, value);
        emit Mint(msg.sender, destination, value);
    }

    function cancelReinvest(string calldata orderId) external {
        uint256 size;
        address callerAddress = msg.sender;
        assembly {
            size := extcodesize(callerAddress)
        }
        require(size == 0 || allowInternalCall == 1, "forbidden");
        INVESTMENT_EARNINGS_CONTRACT.noteCancelReinvest(orderId);
    }

    function withdrawalIncome(uint64[] calldata recordIds) external {
        uint256 size;
        address callerAddress = msg.sender;
        assembly {
            size := extcodesize(callerAddress)
        }
        require(size == 0 || allowInternalCall == 1, "forbidden");
        for (uint256 i = 0; i < recordIds.length; i++) {
            require(recordIds[i] > 0, "invalid record id");
            for (uint256 j = 0; j < i; j++) {
                if (recordIds[i] == recordIds[j]) {
                    revert("duplicate record id");
                }
            }
        }
        INVESTMENT_EARNINGS_CONTRACT.noteWithdrawal(recordIds);
    }

    // Confirm that the signature triplets (v1, r1, s1) (v2, r2, s2) ...
    // authorize a spend of this contract's funds to the given destination address.
    function _validMsgSignature(
        bytes32 message,
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) private view returns (bool) {
        require(vs.length == rs.length);
        require(rs.length == ss.length);
        require(vs.length <= owners.length);
        require(vs.length >= required);
        address[] memory addrs = new address[](vs.length);
        for (uint256 i = 0; i < vs.length; i++) {
            //recover the address associated with the public key from elliptic curve signature or return zero on error
            addrs[i] = ecrecover(message, vs[i] + 27, rs[i], ss[i]);
        }
        require(_distinctOwners(addrs));
        return true;
    }

    // Confirm that the signature triplets (v1, r1, s1) (v2, r2, s2) ...
    // authorize a spend of this contract's funds to the given destination address.
    function _validSignature(
        address erc20Contract,
        address destination,
        uint256 value,
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) private view returns (bool) {
        bytes32 message = _messageToRecover(erc20Contract, destination, value);
        return _validMsgSignature(message, vs, rs, ss);
    }

    // Confirm the addresses as distinct owners of this contract.
    function _distinctOwners(
        address[] memory addrs
    ) private view returns (bool) {
        if (addrs.length > owners.length) {
            return false;
        }
        for (uint256 i = 0; i < addrs.length; i++) {
            if (!isOwner[addrs[i]]) {
                return false;
            }
            //address should be distinct
            for (uint256 j = 0; j < i; j++) {
                if (addrs[i] == addrs[j]) {
                    return false;
                }
            }
        }
        return true;
    }
}