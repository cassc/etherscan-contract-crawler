// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IIkaniERC20 {

    //---------------- Events ----------------//

    event Minted(
        address indexed to,
        uint256 amount,
        bytes32 indexed receipt,
        bytes receiptData
    );

    event Burned(
        address indexed from,
        uint256 amount,
        bytes32 indexed receipt,
        bytes receiptData
    );

    //---------------- Functions ----------------//

    function mint(
        address to,
        uint256 amount,
        bytes32 receipt,
        bytes calldata receiptData
    )
        external;

    function burn(
        address from,
        uint256 amount,
        bytes32 receipt,
        bytes calldata receiptData
    )
        external;

    function burnWithPermit(
        address from,
        uint256 amount,
        bytes32 receipt,
        bytes calldata receiptData,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external;

    function burnFrom(
        address from,
        uint256 amount,
        bytes32 receipt,
        bytes calldata receiptData
    )
        external;
}