// SPDX-License-Identifier: MIT

pragma solidity >=0.4.21 <0.7.0;

/* import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; */
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Must is ERC20Burnable {
    using Counters for Counters.Counter;
    mapping (address => Counters.Counter) private _nonces;

    string constant public NAME = "Must";
    string constant public SYMBOL = "MUST";
    uint8 constant public DECIMALS = 18;
    uint256 constant public INITIAL_SUPPLY = 1000000*(10**uint256(DECIMALS));

    bytes32 public DOMAIN_SEPARATOR;

    bytes32 public immutable PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    constructor(address owner) ERC20(NAME, SYMBOL) public {
        _setupDecimals(DECIMALS);
        _mint(owner, INITIAL_SUPPLY);

        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(address verifyingContract,uint256 chainId)"),
            address(this),
            getChainId()
        ));
    }

    function getChainId() public pure returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = permitMessage(owner, spender, value, deadline);

        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
        address signer = recover(hash, v, r, s);

        require(signer == owner, "ERC20Permit: invalid signature");

        _nonces[owner].increment();
        _approve(owner, spender, value);
    }

    function nonces(address owner) public view returns (uint256) {
        return _nonces[owner].current();
    }

    function permitMessage(address owner, address spender, uint256 value, uint256 deadline) public view returns (bytes32) {
        return keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                _nonces[owner].current(),
                deadline
            )
        );
    }

    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }
}