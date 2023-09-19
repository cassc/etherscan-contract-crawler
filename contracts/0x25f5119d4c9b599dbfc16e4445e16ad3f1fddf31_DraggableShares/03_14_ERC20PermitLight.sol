// SPDX-License-Identifier: MIT
// Copied from https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol
// and modified it.

pragma solidity ^0.8.0;

import "./ERC20Flaggable.sol";
import "./IERC20Permit.sol";

abstract contract ERC20PermitLight is ERC20Flaggable, IERC20Permit {
   
   /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public override nonces;

  /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        unchecked { // unchecked to save a little gas with the nonce increment...
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                                bytes32(0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");
            _approve(recoveredAddress, spender, value);
        }
    }

    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    //keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");
                    bytes32(0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218),
                    block.chainid,
                    address(this)
                )
            );
    }

}