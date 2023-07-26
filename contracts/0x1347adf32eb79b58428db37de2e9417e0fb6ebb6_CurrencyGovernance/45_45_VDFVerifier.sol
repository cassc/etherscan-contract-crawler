// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BigNumber.sol";
import "./IsPrime.sol";
import "../policy/PolicedUtils.sol";

/** @title On-the-chain verification for RSA 2K VDF
 */
contract VDFVerifier is PolicedUtils, IsPrime {
    using BigNumber for BigNumber.Instance;

    /* 2048-bit modulus from RSA-2048 challenge
     * https://en.wikipedia.org/wiki/RSA_Factoring_Challenge
     * The security assumptions rely on RSA challenge rules:
     * No attacker knows or can obtain the factorization
     * Factorization wasn't recorded on generation of the number.
     */

    bytes public constant N =
        hex"c7970ceedcc3b0754490201a7aa613cd73911081c790f5f1a8726f463550bb5b7ff0db8e1ea1189ec72f93d1650011bd721aeeacc2acde32a04107f0648c2813a31f5b0b7765ff8b44b4b6ffc93384b646eb09c7cf5e8592d40ea33c80039f35b4f14a04b51f7bfd781be4d1673164ba8eb991c2c4d730bbbe35f592bdef524af7e8daefd26c66fc02c479af89d64d373f442709439de66ceb955f3ea37d5159f6135809f85334b5cb1813addc80cd05609f10ac6a95ad65872c909525bdad32bc729592642920f24c61dc5b3c3b7923e56b16a4d9d373d8721f24a3fc0f1b3131f55615172866bccc30f95054c824e733a5eb6817f7bc16399d48c6361cc7e5";
    uint256 public constant MIN_BYTES = 64;

    /* The State is a data structure that tracks progress of a logical single verification session
     * from a single verifier. Once verification is complete,
     * state is removed, and (if succesfully verified) replaced by a entry
     * in verified
     */
    struct State {
        uint256 progress; // progress: 1 .. t-1
        uint256 t;
        uint256 x;
        bytes32 concatHash;
        BigNumber.Instance y;
        BigNumber.Instance xi;
        BigNumber.Instance yi;
    }

    // Mapping from verifier to state
    mapping(address => State) private state;

    /** @notice Mapping from keccak256(t, x) to keccak256(y)
     */
    mapping(bytes32 => bytes32) public verified;

    /* Event to be emitted when verification is complete.
     */
    event SuccessfulVerification(uint256 x, uint256 t, bytes y);

    /**
     * @notice Construct the contract with global parameters.
     */
    // solhint-disable-next-line no-empty-blocks
    constructor(Policy _policy) PolicedUtils(_policy) {
        // uses PolicedUtils constructor
    }

    /**
     * @notice Start the verification process
     * This starts the submission of a proof that (x^(2^(2^t+1)))==y
     * @notice The caller should have already set the prime number, _x, to use in the random inflation
     * contract.
     */
    function start(
        uint256 _x,
        uint256 _t,
        bytes calldata _ybytes
    ) external {
        require(
            verified[keccak256(abi.encode(_t, _x))] == bytes32(0),
            "this _x, _t combination has already been verified"
        );

        require(_t >= 2, "t must be at least 2");

        require(_x > 1, "The commitment (x) must be > 1");

        BigNumber.Instance memory n = BigNumber.from(N);
        BigNumber.Instance memory x = BigNumber.from(_x);
        BigNumber.Instance memory y = BigNumber.from(_ybytes);
        BigNumber.Instance memory x2 = BigNumber.multiply(x, x);

        require(
            y.minimalByteLength() >= MIN_BYTES,
            "The secret (y) must be at least 64 bytes long"
        );
        require(BigNumber.cmp(y, n) == -1, "y must be less than N");

        State storage currentState = state[msg.sender];

        currentState.progress = 1; // reset the contract
        currentState.t = _t;

        currentState.x = _x;
        currentState.y = y;

        currentState.xi = x2; // the time-lock-puzzle is for x2 = x^2; x2 is a QR mod n
        currentState.yi = y;
        currentState.concatHash = keccak256(
            abi.encodePacked(_x, y.asBytes(n.byteLength()))
        );
    }

    /**
     * @notice Submit next step of proof
     * To be continuously called with progress = 1 ... t-1 and corresponding u, inclusively.
     * progress input parameter indicates the expected value of progress after the successful processing of this step.
     *
     * So, it starts with s.progress == 0 and call with progress=1, ... t-1. Once you set s.progress = t-1, this has
     * completed the verification successfully.
     *
     * In other words, the input is effectively (i, U_sqrt[i]).
     */
    function update(bytes calldata _ubytes) external {
        State storage s = state[msg.sender]; // saves gas

        require(s.progress > 0, "process has not yet been started");

        BigNumber.Instance memory n = BigNumber.from(N); // save in memory
        BigNumber.Instance memory one = BigNumber.from(1);
        BigNumber.Instance memory two = BigNumber.from(2);

        BigNumber.Instance memory u = BigNumber.from(_ubytes);
        BigNumber.Instance memory u2 = BigNumber.modexp(u, two, n); // u2 = u^2 mod n

        require(BigNumber.cmp(u, one) == 1, "u must be greater than 1");
        require(BigNumber.cmp(u, n) == -1, "u must be less than N");
        require(BigNumber.cmp(u2, one) == 1, "u*u must be greater than 1");

        uint256 nlen = n.byteLength();

        uint256 nextProgress = s.progress;

        BigNumber.Instance memory r = BigNumber.from(
            uint256(
                keccak256(
                    abi.encodePacked(
                        s.concatHash,
                        u.asBytes(nlen),
                        nextProgress
                    )
                )
            )
        );

        nextProgress++;

        BigNumber.Instance memory xi = BigNumber.modmul(
            BigNumber.modexp(s.xi, r, n),
            u2,
            n
        ); // xi^r * u^2
        BigNumber.Instance memory yi = BigNumber.modmul(
            BigNumber.modexp(u2, r, n),
            s.yi,
            n
        ); // u^2*r * y

        if (nextProgress != s.t) {
            // Intermediate step
            s.xi = xi;
            s.yi = yi;

            s.progress = nextProgress; // this becomes t-1 for the last step
        } else {
            // Final step. Finalize calculations.
            xi = xi.modexp(BigNumber.from(4), n); // xi^4. Must match yi

            require(
                BigNumber.cmp(xi, yi) == 0,
                "Verification failed in the last step"
            );

            // Success! Fall through

            verified[keccak256(abi.encode(s.t, s.x))] = keccak256(
                s.y.asBytes(nlen)
            );

            emit SuccessfulVerification(s.x, s.t, s.y.asBytes());
            delete (state[msg.sender]);
        }
    }

    /**
     * @notice Return verified state
     * @return true iff (x^(2^(2^t+1)))==y has been proven
     */
    function isVerified(
        uint256 _x,
        uint256 _t,
        bytes calldata _ybytes
    ) external view returns (bool) {
        BigNumber.Instance memory y = BigNumber.from(_ybytes);
        uint256 nlen = N.length;
        return
            verified[keccak256(abi.encode(_t, _x))] ==
            keccak256(y.asBytes(nlen));
    }
}