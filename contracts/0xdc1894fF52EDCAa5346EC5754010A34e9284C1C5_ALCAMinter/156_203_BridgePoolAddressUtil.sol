// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library BridgePoolAddressUtil {
    /**
     * @notice calculates salt for a BridgePool contract based on ERC contract's address, tokenType, chainID and version_
     * @param tokenContractAddr_ address of ERC contract of BridgePool
     * @param tokenType_ type of token (0=ERC20, 1=ERC721, 2=ERC1155)
     * @param version_ version of the implementation
     * @param chainID_ chain ID
     * @return calculated calculated salt
     */
    function getBridgePoolSalt(
        address tokenContractAddr_,
        uint8 tokenType_,
        uint256 chainID_,
        uint16 version_
    ) internal pure returns (bytes32) {
        return
            keccak256(
                bytes.concat(
                    keccak256(abi.encodePacked(tokenContractAddr_)),
                    keccak256(abi.encodePacked(tokenType_)),
                    keccak256(abi.encodePacked(chainID_)),
                    keccak256(abi.encodePacked(version_))
                )
            );
    }

    function getBridgePoolAddress(
        bytes32 bridgePoolSalt_,
        address bridgeFactory_
    ) internal pure returns (address) {
        // works: 5880818283335afa3d82833e3d82f3
        bytes32 initCodeHash = 0xf231e946a2f88d89eafa7b43271c54f58277304b93ac77d138d9b0bb3a989b6d;
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(hex"ff", bridgeFactory_, bridgePoolSalt_, initCodeHash)
                        )
                    )
                )
            );
    }
}