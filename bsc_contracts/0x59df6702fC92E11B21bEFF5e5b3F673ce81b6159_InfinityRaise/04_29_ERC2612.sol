// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../ERC20.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import './IERC2612.sol';

/**
 * Implementation adapted from
 * https://github.com/albertocuestacanada/ERC20Permit/blob/master/contracts/ERC20Permit.sol.
 */
abstract contract ERC2612 is ERC165, ERC20, IERC2612 {
    mapping(address => uint256) public override nonces;

    bytes32 public immutable PERMIT_TYPEHASH =
        keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');
    bytes32 public immutable TRANSFER_TYPEHASH =
        keccak256('Transfer(address owner,address to,uint256 value,uint256 nonce,uint256 deadline)');
    bytes32 public override DOMAIN_SEPARATOR;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name_)),
                keccak256(bytes(version())),
                chainId,
                address(this)
            )
        );
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IERC2612).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Setting the version as a function so that it can be overriden
     */
    function version() public pure virtual returns (string memory) {
        return '1';
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override {
        verifyPermit(PERMIT_TYPEHASH, owner, spender, value, deadline, v, r, s);
        _approve(owner, spender, value);
    }

    function transferWithPermit(
        address owner,
        address to,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (bool) {
        verifyPermit(TRANSFER_TYPEHASH, owner, to, value, deadline, v, r, s);
        _transfer(owner, to, value);
        return true;
    }

    function verifyPermit(
        bytes32 typehash,
        address owner,
        address to,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        require(block.timestamp <= deadline, 'ERC20Permit: Expired permit');

        bytes32 hashStruct = keccak256(abi.encode(typehash, owner, to, value, nonces[owner]++, deadline));

        require(
            verifyEIP712(owner, hashStruct, v, r, s) || verifyPersonalSign(owner, hashStruct, v, r, s),
            'ERC20Permit: invalid signature'
        );
    }

    function verifyEIP712(
        address owner,
        bytes32 hashStruct,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, hashStruct));
        address signer = ecrecover(hash, v, r, s);
        return (signer != address(0) && signer == owner);
    }

    function verifyPersonalSign(
        address owner,
        bytes32 hashStruct,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bool) {
        bytes32 hash = prefixed(hashStruct);
        address signer = ecrecover(hash, v, r, s);
        return (signer != address(0) && signer == owner);
    }

    /**
     * @dev Builds a prefixed hash to mimic the behavior of eth_sign.
     */
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', hash));
    }
}