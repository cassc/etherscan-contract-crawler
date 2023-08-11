// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title EIP712Base
 * @author Aave
 * @notice Base contract implementation of EIP712.
 */
abstract contract EIP712Base {
    bytes public constant EIP712_REVISION = bytes("1");
    bytes32 internal constant EIP712_DOMAIN =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    uint256 internal immutable _chainId;

    /**
     * @dev Constructor.
     */
    constructor() public {
        // because assembly does not have access to immutable variable
        uint256 __chainId;
        assembly {
            __chainId := chainid()
        }
        _chainId = __chainId;
    }

    /**
     * @notice Get the domain separator for the token
     * @dev Return cached value if chainId matches cache, otherwise recomputes separator
     * @return The domain separator of the token at current chain
     */
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32);

    /**
     * @notice Returns the nonce value for address specified as parameter
     * @param owner The address for which the nonce is being returned
     * @return The nonce value for the input address`
     */
    function nonces(address owner) public view virtual returns (uint256);

    /**
     * @notice Compute the current domain separator
     * @return The domain separator for the token
     */
    function _calculateDomainSeparator() internal view returns (bytes32) {
        uint256 __chainId;
        assembly {
            __chainId := chainid()
        }
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN,
                    keccak256(bytes(_EIP712BaseId())),
                    keccak256(EIP712_REVISION),
                    __chainId,
                    address(this)
                )
            );
    }

    /**
     * @notice Returns the user readable name of signing domain (e.g. token name)
     * @return The name of the signing domain
     */
    function _EIP712BaseId() internal view virtual returns (string memory);
}