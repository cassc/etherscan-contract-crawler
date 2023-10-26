// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "../interfaces/IPendleBaseToken.sol";
import "../interfaces/IPendleRouter.sol";

/**
 *   @title PendleBaseToken
 *   @dev The contract implements the standard ERC20 functions, plus some
 *        Pendle specific fields and functions, namely:
 *          - expiry
 *
 *        This abstract contract is inherited by PendleFutureYieldToken
 *        and PendleOwnershipToken contracts.
 **/
abstract contract PendleBaseToken is ERC20 {
    using SafeMath for uint256;

    uint256 public immutable start;
    uint256 public immutable expiry;
    IPendleRouter public immutable router;

    //// Start of EIP-2612 related part, exactly the same as UniswapV2ERC20.sol
    bytes32 public immutable DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    //// End of EIP-2612 related part

    constructor(
        address _router,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _start,
        uint256 _expiry
    ) ERC20(_name, _symbol) {
        _setupDecimals(_decimals);
        start = _start;
        expiry = _expiry;
        router = IPendleRouter(_router);

        //// Start of EIP-2612 related part, exactly the same as UniswapV2ERC20.sol, except for the noted parts below
        uint256 chainId;
        assembly {
            chainId := chainid() // chainid() is a function in assembly in this solidity version
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(_name)), // use our own _name here
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
        //// End of EIP-2612 related part
    }

    //// Start of EIP-2612 related part, exactly the same as UniswapV2ERC20.sol
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "PERMIT_EXPIRED");
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner,
                            spender,
                            value,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );
        address recoveredAddress = ECDSA.recover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }

    //// End of EIP-2612 related part

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal virtual override {
        require(to != address(this), "SEND_TO_TOKEN_CONTRACT");
        require(to != from, "SEND_TO_SELF");
    }
}