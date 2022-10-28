// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {Initializable} from "./Initializable.sol";

contract InitializablePermittable is Initializable {

    /* ============ Variables ============ */

    string public version;

    // solhint-disable-next-line
    bytes32 public DOMAIN_SEPARATOR;

    mapping (address => uint256) public nonces;

    /* ============ Constants ============ */

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /* solhint-disable-next-line */
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /* ============ Constructor ============ */

    function _init(
        string memory _name,
        string memory _version
    )
        internal
        initializer    
    {
        version = _version;
        DOMAIN_SEPARATOR = _initDomainSeparator(_name, _version);
    }

    /**
     * @dev Initializes EIP712 DOMAIN_SEPARATOR based on the current contract and chain ID.
     */
    function _initDomainSeparator(
        string memory _name,
        string memory _version
    )
        internal
        view
        returns (bytes32)
    {
        uint256 chainID;
        /* solhint-disable-next-line */
        assembly {
            chainID := chainid()
        }

        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(_name)),
                keccak256(bytes(_version)),
                chainID,
                address(this)
            )
        );
    }

    /**
    * @dev Approve by signature.
    *      Caution: If an owner signs a permit with no deadline, the corresponding spender
    *      can call permit at any time in the future to mess with the nonce, invalidating
    *      signatures to other spenders, possibly making their transactions fail.
    *
    * Adapted from Uniswap's UniswapV2ERC20 and MakerDAO's Dai contracts:
    * https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol
    * https://github.com/makerdao/dss/blob/master/src/dai.sol
    */
    function _permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        internal
    {
        require(
            deadline == 0 || deadline >= block.timestamp,
            "Permittable: Permit expired"
        );

        require(
            spender != address(0),
            "Permittable: spender cannot be 0x0"
        );

        bytes32 digest = keccak256(
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
        ));

        address recoveredAddress = ecrecover(
            digest,
            v,
            r,
            s
        );

        require(
            recoveredAddress != address(0) && owner == recoveredAddress,
            "Permittable: Signature invalid"
        );

    }

}