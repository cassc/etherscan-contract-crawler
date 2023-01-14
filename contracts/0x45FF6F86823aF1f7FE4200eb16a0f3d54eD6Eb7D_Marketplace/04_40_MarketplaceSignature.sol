// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract MarketplaceSignature {
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct SignData {
        uint256 price;
        uint256[] availableIds;
        uint256[] shares;
        address buyer;
        address packAddress;
        address[] shareAddresses;
        address tokenAddress;
        uint32 missionId;
        uint32 quantity;
        uint128 seed;
    }

    bytes32 private constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
        );

    bytes32 private constant SIGNDATA_TYPEHASH =
        keccak256(
            'SignData(uint256 price,uint256[] availableIds,uint256[] shares,address buyer,address packAddress,address[] shareAddresses,address tokenAddress,uint32 missionId,uint32 quantity,uint128 seed)'
        );
    bytes32 private EIP712DOMAIN_SEPARATOR;

    function __Signature_init(string memory _name, string memory _version) internal {
        EIP712DOMAIN_SEPARATOR = _hash(
            EIP712Domain({
                name: _name,
                version: _version,
                chainId: block.chainid,
                verifyingContract: address(this)
            })
        );
    }

    function _hash(EIP712Domain memory domain) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712DOMAIN_TYPEHASH,
                    keccak256(bytes(domain.name)),
                    keccak256(bytes(domain.version)),
                    domain.chainId,
                    domain.verifyingContract
                )
            );
    }

    function _hash(SignData memory signData) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    SIGNDATA_TYPEHASH,
                    signData.price,
                    keccak256(abi.encodePacked(signData.availableIds)),
                    keccak256(abi.encodePacked(signData.shares)),
                    signData.buyer,
                    signData.packAddress,
                    keccak256(abi.encodePacked(signData.shareAddresses)),
                    signData.tokenAddress,
                    signData.missionId,
                    signData.quantity,
                    signData.seed
                )
            );
    }

    function _getSigner(
        address buyer,
        SignData memory signData,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (address) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                EIP712DOMAIN_SEPARATOR,
                _hash(
                    SignData({
                        price: signData.price,
                        availableIds: signData.availableIds,
                        shares: signData.shares,
                        buyer: buyer,
                        packAddress: signData.packAddress,
                        shareAddresses: signData.shareAddresses,
                        tokenAddress: signData.tokenAddress,
                        missionId: signData.missionId,
                        quantity: signData.quantity,
                        seed: signData.seed
                    })
                )
            )
        );
        return ecrecover(digest, v, r, s);
    }
}