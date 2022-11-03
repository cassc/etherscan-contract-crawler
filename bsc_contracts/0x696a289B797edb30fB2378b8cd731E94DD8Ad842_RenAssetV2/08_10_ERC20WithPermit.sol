// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line
pragma solidity ^0.8.0;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract ERC20WithPermitState {
    mapping(address => uint256) internal _nonces;

    // If the token is redeployed, the version is increased to prevent a permit
    // signature being used on both token instances.
    string internal _version;

    // --- EIP712 niceties ---
    bytes32 internal _domainSeparator;

    // Leave a gap so that storage values added in future upgrages don't corrupt
    // the storage of contracts that inherit from this contract.
    uint256[47] private __gap;
}

/// Taken from the DAI token (https://github.com/makerdao/dss/blob/c8d4c806691dacb903ff281b81f316bea974e4c7/src/dai.sol)
/// See also EIP-2612 (https://eips.ethereum.org/EIPS/eip-2612).
contract ERC20WithPermit is Initializable, ERC20Upgradeable, ERC20WithPermitState {
    // PERMIT_TYPEHASH is the value returned from
    // keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)")
    bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    function __ERC20WithPermit_init(
        uint256 chainId,
        string calldata version_,
        string calldata name_,
        string calldata symbol_
    ) public initializer {
        __ERC20_init(name_, symbol_);
        _version = version_;
        _domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name())),
                keccak256(bytes(version_)),
                chainId,
                address(this)
            )
        );
    }

    function nonces(address holder) public view returns (uint256) {
        return _nonces[holder];
    }

    function version() external view returns (string memory) {
        return _version;
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return _domainSeparator;
    }

    // --- Approve by signature ---
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(abi.encode(PERMIT_TYPEHASH, holder, spender, nonce, expiry, allowed))
            )
        );

        require(holder != address(0), "ERC20WithRate: address must not be 0x0");
        require(holder == ecrecover(digest, v, r, s), "ERC20WithRate: invalid signature");
        require(expiry == 0 || block.timestamp <= expiry, "ERC20WithRate: permit has expired");
        require(nonce == nonces(holder), "ERC20WithRate: invalid nonce");
        _nonces[holder] = nonce + 1;
        uint256 amount = allowed ? uint256(int256(-1)) : 0;

        // Approve
        _approve(holder, spender, amount);
    }
}