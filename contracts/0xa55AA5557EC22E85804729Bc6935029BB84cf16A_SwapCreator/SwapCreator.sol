/**
 *Submitted for verification at Etherscan.io on 2023-05-02
*/

// SPDX-License-Identifier: LGPLv3
pragma solidity ^0.8.19;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


contract Secp256k1 {
    // solhint-disable-next-line
    uint256 private constant gx =
        0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    // solhint-disable-next-line
    uint256 private constant m = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    // mulVerify returns true if `Q = s * G` on the secp256k1 curve
    // qKeccak is defined as uint256(keccak256(abi.encodePacked(qx, qy))
    function mulVerify(uint256 scalar, uint256 qKeccak) public pure returns (bool) {
        address qRes = ecrecover(0, 27, bytes32(gx), bytes32(mulmod(scalar, gx, m)));
        return uint160(qKeccak) == uint160(qRes);
    }
}

contract SwapCreator is Secp256k1 {
    // Swap state is PENDING when the swap is first created and funded
    // Alice sets Stage to READY when she sees the funds locked on the other chain.
    // this prevents Bob from withdrawing funds without locking funds on the other chain first
    // Stage is set to COMPLETED upon the swap value being claimed or refunded.
    enum Stage {
        INVALID,
        PENDING,
        READY,
        COMPLETED
    }

    struct Swap {
        // the swap initiator, Alice
        // address allowed to refund the ether for this swap
        address payable owner;
        // address allowed to claim the ether for this swap, Bob
        address payable claimer;
        // the keccak256 hash of the expected public key derived from the secret `s_b`.
        // this public key is a point on the secp256k1 curve
        bytes32 pubKeyClaim;
        // the keccak256 hash of the expected public key derived from the secret `s_a`.
        // this public key is a point on the secp256k1 curve
        bytes32 pubKeyRefund;
        // timestamp before which Alice can call either `setReady` or `refund`
        uint256 timeout1;
        // timestamp after which Bob cannot claim, only Alice can refund
        uint256 timeout2;
        // the asset being swapped: equal to address(0) for ETH, or an ERC-20 token address
        address asset;
        // the value of this swap
        uint256 value;
        // choose random
        uint256 nonce;
    }

    // RelaySwap contains additional information required for relayed transactions.
    // This entire structure is encoded and signed by the swap claimer, and the signature is
    // passed to the `claimRelayer` function.
    struct RelaySwap {
        // the swap the transaction is for
        Swap swap;
        // the fee, in wei, paid to the relayer
        uint256 fee;
        // hash of (relayer's payout address || 4-byte salt)
        bytes32 relayerHash;
        // address of the swap contract this transaction is meant for
        address swapCreator;
    }

    mapping(bytes32 => Stage) public swaps;

    event New(
        bytes32 swapID,
        bytes32 claimKey,
        bytes32 refundKey,
        uint256 timeout1,
        uint256 timeout2,
        address asset,
        uint256 value
    );
    event Ready(bytes32 indexed swapID);
    event Claimed(bytes32 indexed swapID, bytes32 indexed s);
    event Refunded(bytes32 indexed swapID, bytes32 indexed s);

    // returned when trying to initiate a swap with a zero value
    error ZeroValue();

    // returned when the pubKeyClaim or pubKeyRefund parameters for `newSwap` are zero
    error InvalidSwapKey();

    // returned when the claimer parameter for `newSwap` is the zero address
    error InvalidClaimer();

    // returned when the timeout1 or timeout2 parameters for `newSwap` are zero
    error InvalidTimeout();

    // returned when the ether sent with a `newSwap` transaction does not match the value parameter
    error InvalidValue();

    // returned when trying to initiate a swap with an ID that already exists
    error SwapAlreadyExists();

    // returned when trying to call `setReady` on a swap that is not in the PENDING stage
    error SwapNotPending();

    // returned when the caller of `setReady` or `refund` is not the swap owner
    error OnlySwapOwner();

    // returned when the signer of the relayed transaction is not the swap's claimer
    error OnlySwapClaimer();

    // returned when trying to call `claim` or `refund` on an invalid swap
    error InvalidSwap();

    // returned when trying to call `claim` or `refund` on a swap that's already completed
    error SwapCompleted();

    // returned when trying to call `claim` on a swap that's not set to ready or the first timeout has not been reached
    error TooEarlyToClaim();

    // returned when trying to call `claim` on a swap where the second timeout has been reached
    error TooLateToClaim();

    // returned when it's the counterparty's turn to claim and refunding is not allowed
    error NotTimeToRefund();

    // returned when the provided secret does not match the expected public key
    error InvalidSecret();

    // returned when the signature of a `RelaySwap` is invalid
    error InvalidSignature();

    // returned when the SwapCreator address is a `RelaySwap` is not the addres of this contract
    error InvalidContractAddress();

    // returned when the hash of the relayer address and salt passed to `claimRelayer`
    // does not match the relayer hash in `RelaySwap`
    error InvalidRelayerAddress();

    // newSwap creates a new Swap instance with the given parameters.
    // it returns the swap's ID.
    // _timeoutDuration0: duration between the current timestamp and timeout1
    // _timeoutDuration1: duration between timeout1 and timeout2
    function newSwap(
        bytes32 _pubKeyClaim,
        bytes32 _pubKeyRefund,
        address payable _claimer,
        uint256 _timeoutDuration1,
        uint256 _timeoutDuration2,
        address _asset,
        uint256 _value,
        uint256 _nonce
    ) public payable returns (bytes32) {
        if (_value == 0) revert ZeroValue();
        if (_asset == address(0)) {
            if (_value != msg.value) revert InvalidValue();
        } else {
            // transfer ERC-20 token into this contract
            // WARN: fee-on-transfer tokens are not supported
            IERC20(_asset).transferFrom(msg.sender, address(this), _value);
        }

        if (_pubKeyClaim == 0 || _pubKeyRefund == 0) revert InvalidSwapKey();
        if (_claimer == address(0)) revert InvalidClaimer();
        if (_timeoutDuration1 == 0 || _timeoutDuration2 == 0) revert InvalidTimeout();

        Swap memory swap = Swap({
            owner: payable(msg.sender),
            pubKeyClaim: _pubKeyClaim,
            pubKeyRefund: _pubKeyRefund,
            claimer: _claimer,
            timeout1: block.timestamp + _timeoutDuration1,
            timeout2: block.timestamp + _timeoutDuration1 + _timeoutDuration2,
            asset: _asset,
            value: _value,
            nonce: _nonce
        });

        bytes32 swapID = keccak256(abi.encode(swap));

        // make sure this isn't overriding an existing swap
        if (swaps[swapID] != Stage.INVALID) revert SwapAlreadyExists();

        emit New(
            swapID,
            _pubKeyClaim,
            _pubKeyRefund,
            swap.timeout1,
            swap.timeout2,
            swap.asset,
            swap.value
        );
        swaps[swapID] = Stage.PENDING;
        return swapID;
    }

    // Alice should call setReady() before timeout1 once she verifies the XMR has been locked
    function setReady(Swap memory _swap) public {
        bytes32 swapID = keccak256(abi.encode(_swap));
        if (swaps[swapID] != Stage.PENDING) revert SwapNotPending();
        if (_swap.owner != msg.sender) revert OnlySwapOwner();
        swaps[swapID] = Stage.READY;
        emit Ready(swapID);
    }

    // Bob can call claim if either of these hold true:
    // (1) Alice has set the swap to `ready` and it's before timeout1
    // (2) It is between timeout0 and timeout1
    function claim(Swap memory _swap, bytes32 _secret) public {
        if (msg.sender != _swap.claimer) revert OnlySwapClaimer();
        _claim(_swap, _secret);

        // send ether to swap claimer
        if (_swap.asset == address(0)) {
            _swap.claimer.transfer(_swap.value);
        } else {
            // WARN: this will FAIL for fee-on-transfer or rebasing tokens if the token
            // transfer reverts (i.e. if this contract does not contain _swap.value tokens),
            // exposing Bob's secret while giving him nothing.
            IERC20(_swap.asset).transfer(_swap.claimer, _swap.value);
        }
    }

    // Anyone can call claimRelayer if they receive a signed _relaySwap object
    // from Bob. The same rules for when Bob can call claim() apply here when a
    // 3rd party relays a claim for Bob. This version of claiming transfers a
    // _relaySwap.fee to _relayer. To prevent front-running, while not requiring
    // Bob to know the relayer's payout address, Bob only signs a salted hash of
    // the relayer's payout address in _relaySwap.relayerHash.
    // Note: claimRelayer will revert if the swap value is less than the relayer
    // fee; in that case, Bob must call claim directly.
    function claimRelayer(
        RelaySwap memory _relaySwap,
        bytes32 _secret,
        address payable _relayer,
        uint32 _salt,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        address signer = ecrecover(keccak256(abi.encode(_relaySwap)), v, r, s);
        if (signer != _relaySwap.swap.claimer) revert InvalidSignature();
        if (address(this) != _relaySwap.swapCreator) revert InvalidContractAddress();
        if (keccak256(abi.encodePacked(_relayer, _salt)) != _relaySwap.relayerHash)
            revert InvalidRelayerAddress();

        _claim(_relaySwap.swap, _secret);

        // send ether to swap claimer, subtracting the relayer fee
        if (_relaySwap.swap.asset == address(0)) {
            _relaySwap.swap.claimer.transfer(_relaySwap.swap.value - _relaySwap.fee);
            payable(_relayer).transfer(_relaySwap.fee);
        } else {
            // WARN: this will FAIL for fee-on-transfer or rebasing tokens if the token
            // transfer reverts (i.e. if this contract does not contain _swap.value tokens),
            // exposing Bob's secret while giving him nothing.
            IERC20(_relaySwap.swap.asset).transfer(
                _relaySwap.swap.claimer,
                _relaySwap.swap.value - _relaySwap.fee
            );
            IERC20(_relaySwap.swap.asset).transfer(_relayer, _relaySwap.fee);
        }
    }

    function _claim(Swap memory _swap, bytes32 _secret) internal {
        bytes32 swapID = keccak256(abi.encode(_swap));
        Stage swapStage = swaps[swapID];
        if (swapStage == Stage.INVALID) revert InvalidSwap();
        if (swapStage == Stage.COMPLETED) revert SwapCompleted();
        if (block.timestamp < _swap.timeout1 && swapStage != Stage.READY) revert TooEarlyToClaim();
        if (block.timestamp >= _swap.timeout2) revert TooLateToClaim();

        verifySecret(_secret, _swap.pubKeyClaim);
        emit Claimed(swapID, _secret);
        swaps[swapID] = Stage.COMPLETED;
    }

    // Alice can claim a refund:
    // - Until timeout1 unless she calls setReady
    // - After timeout2
    function refund(Swap memory _swap, bytes32 _secret) public {
        bytes32 swapID = keccak256(abi.encode(_swap));
        Stage swapStage = swaps[swapID];
        if (swapStage == Stage.INVALID) revert InvalidSwap();
        if (swapStage == Stage.COMPLETED) revert SwapCompleted();
        if (_swap.owner != msg.sender) revert OnlySwapOwner();
        if (
            block.timestamp < _swap.timeout2 &&
            (block.timestamp > _swap.timeout1 || swapStage == Stage.READY)
        ) revert NotTimeToRefund();

        verifySecret(_secret, _swap.pubKeyRefund);
        emit Refunded(swapID, _secret);

        // send asset back to swap owner
        swaps[swapID] = Stage.COMPLETED;
        if (_swap.asset == address(0)) {
            _swap.owner.transfer(_swap.value);
        } else {
            IERC20(_swap.asset).transfer(_swap.owner, _swap.value);
        }
    }

    function verifySecret(bytes32 _secret, bytes32 _hashedPubkey) internal pure {
        if (!mulVerify(uint256(_secret), uint256(_hashedPubkey))) revert InvalidSecret();
    }
}