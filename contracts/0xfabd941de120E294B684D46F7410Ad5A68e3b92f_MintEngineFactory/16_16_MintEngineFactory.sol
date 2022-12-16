// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ERC721MinterProxy.sol";
import "./IERC721Mintable.sol";
import "./ERC721Minter.sol";

contract MintEngineFactory {
    address public minterImplementation;

    event MintContractDeployed(
        address minter,
        address indexed owner,
        IERC721Mintable indexed nft,
        uint256 price,
        bytes32 merkleRoot
    );

    constructor(address _minterImplementation) {
        minterImplementation = _minterImplementation;
    }

    function deployMintContract(
        address owner,
        IERC721Mintable nft,
        uint256 price,
        bytes32 merkleRoot,
        uint256 nonce
    ) external returns (address minter) {
        bytes32 _salt = keccak256(abi.encodePacked(owner, nft, price, merkleRoot, nonce));

        // This syntax is a newer way to invoke create2 without assembly, you just need to pass salt
        // https://docs.soliditylang.org/en/latest/control-structures.html#salted-contract-creations-create2
        minter = address(new ERC721MinterProxy{salt: _salt}(address(minterImplementation)));
        ERC721Minter(minter).initialize(owner, nft, price, merkleRoot);

        emit MintContractDeployed(minter, owner, nft, price, merkleRoot);
    }

    function getProxyAddressFor(
        address owner,
        IERC721Mintable nft,
        uint256 price,
        bytes32 merkleRoot,
        uint256 nonce
    ) external view returns (address minter) {
        bytes32 _salt = keccak256(abi.encodePacked(owner, nft, price, merkleRoot, nonce));
        minter = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            _salt,
                            keccak256(
                                abi.encodePacked(type(ERC721MinterProxy).creationCode, abi.encode(minterImplementation))
                            )
                        )
                    )
                )
            )
        );
    }
}