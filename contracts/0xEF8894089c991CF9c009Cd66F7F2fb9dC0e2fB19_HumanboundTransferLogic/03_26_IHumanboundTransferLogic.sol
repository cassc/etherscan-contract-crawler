// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@violetprotocol/erc721extendable/contracts/extensions/base/transfer/TransferLogic.sol";

interface IHumanboundTransferLogic {
    function transferFrom(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 expiry,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 expiry,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 expiry,
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external;
}

abstract contract HumanboundTransferExtension is IHumanboundTransferLogic, TransferLogic {
    /**
     * @dev see {IExtension-getSolidityInterface}
     */
    function getSolidityInterface() public pure virtual override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    super.getSolidityInterface(),
                    "function transferFrom(uint8 v, bytes32 r, bytes32 s, uint256 expiry, address from, address to, uint256 tokenId) external;\n"
                    "function safeTransferFrom(uint8 v, bytes32 r, bytes32 s, uint256 expiry, address from, address to, uint256 tokenId) external;\n"
                    "function safeTransferFrom(uint8 v, bytes32 r, bytes32 s, uint256 expiry, address from, address to, uint256 tokenId, bytes memory data) external;\n"
                )
            );
    }

    /**
     * @dev see {IExtension-getInterface}
     */
    function getInterface() public virtual override returns (Interface[] memory interfaces) {
        interfaces = new Interface[](2);

        bytes4[] memory functions = new bytes4[](3);
        functions[0] = IHumanboundTransferLogic.transferFrom.selector;
        functions[1] = bytes4(keccak256("safeTransferFrom(uint8,bytes32,bytes32,uint256,address,address,uint256)"));
        functions[2] = bytes4(
            keccak256("safeTransferFrom(uint8,bytes32,bytes32,uint256,address,address,uint256,bytes)")
        );

        interfaces[0] = super.getInterface()[0];
        interfaces[1] = Interface(type(IHumanboundTransferLogic).interfaceId, functions);
    }
}