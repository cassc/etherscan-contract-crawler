// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SportX is ERC20 {
    // --- EIP712 niceties ---
    string public constant version = "1";
    bytes32 public EIP712_DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address holder,address spender,uint256 nonce,uint256 expiry,uint256 amount)"
        );
    bytes2 private constant EIP191_HEADER = 0x1901;
    uint256 private constant INITIAL_SUPPLY = 10**9 * 10**18;

    mapping(address => uint256) public nonces;

    // bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;
    constructor(uint256 _chainId) ERC20("SportX", "SX") {
        EIP712_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("SportX")),
                keccak256(bytes(version)),
                _chainId,
                address(this)
            )
        );
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    // --- Approve by signature ---
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    EIP191_HEADER,
                    EIP712_DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            holder,
                            spender,
                            nonce,
                            expiry,
                            amount
                        )
                    )
                )
            );

        require(holder != address(0), "SportX/invalid-address-0");
        require(holder == ecrecover(digest, v, r, s), "SportX/invalid-permit");
        require(expiry == 0 || block.timestamp <= expiry, "SportX/permit-expired");
        require(nonce == nonces[holder]++, "SportX/invalid-nonce");
        _approve(holder, spender, amount);
    }
}