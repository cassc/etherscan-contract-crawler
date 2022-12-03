// SPDX-License-Identifier: gpl-3.0

pragma solidity 0.7.5;

import '@openzeppelin/contracts-upgradeable/proxy/Initializable.sol';

abstract contract ERC2612Upgradeable is Initializable {
    // --- EIP712 niceties ---
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
    bytes32 public PERMIT_TYPEHASH;

    string public version;
    mapping(address => uint256) public nonces;

    function __ERC2612_init(string memory _EIP712Name) internal initializer {
        version = '1';
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
                ),
                keccak256(bytes(_EIP712Name)),
                keccak256(bytes(version)),
                getChainId(),
                address(this)
            )
        );
        PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;
    }

    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual;

    function getChainId() public pure returns (uint256 chainId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }
}