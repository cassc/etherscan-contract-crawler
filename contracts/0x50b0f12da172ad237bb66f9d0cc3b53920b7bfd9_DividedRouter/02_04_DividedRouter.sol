// SPDX-License-Identifier: MIT
// Author: Daniel Von Fange (@DanielVF)

import {ERC721} from "solmate/tokens/ERC721.sol";
import {IDividedFactory} from "./interfaces/IDividedFactory.sol";
import {IDividedPool} from "./interfaces/IDividedPool.sol";

pragma solidity ^0.8.16;

contract DividedRouter {
    IDividedFactory public immutable factory;
    int128 constant PLUS = 100e18;
    int128 constant MINUS = -100e18;
    bytes32 immutable POOL_BYTECODE_HASH;

    constructor(address _factory) {
        factory = IDividedFactory(_factory);
        POOL_BYTECODE_HASH = factory.POOL_BYTECODE_HASH();
    }

    function nftIn(address collection, uint256 tokenId, address to) external {
        IDividedPool pool = _getPool(collection);
        ERC721(collection).transferFrom(msg.sender, address(pool), tokenId);
        int128 delta = pool.swap(new uint256[](0), msg.sender, to);
        require(delta >= PLUS);
    }

    function nftOut(address collection, uint256 tokenId, address to) external {
        IDividedPool pool = _getPool(collection);
        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;
        int128 delta = pool.swap(ids, msg.sender, to);
        require(delta >= MINUS);
    }

    function nftSwap(address collection, uint256 tokenIn, uint256 tokenOut, address to) external {
        IDividedPool pool = _getPool(collection);
        ERC721(collection).transferFrom(msg.sender, address(pool), tokenIn);
        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenOut;
        int128 delta = pool.swap(ids, msg.sender, to);
        require(delta >= 0);
    }

    function batchNftIn(address collection, uint256[] calldata tokenIds, address to) external {
        IDividedPool pool = _getPool(collection);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            ERC721(collection).transferFrom(msg.sender, address(pool), tokenIds[i]);
        }
        int128 delta = pool.swap(new uint256[](0), msg.sender, to);
        require(delta >= int128(uint128(tokenIds.length)) * PLUS);
    }

    function batchNftOut(address collection, uint256[] calldata tokenIds, address to) external {
        IDividedPool pool = _getPool(collection);
        int128 delta = pool.swap(tokenIds, msg.sender, to);
        require(delta >= int128(uint128(tokenIds.length)) * MINUS);
    }

    function batchNftSwap(address collection, uint256[] calldata tokenIns, uint256[] calldata tokenOuts, address to)
        external
    {
        IDividedPool pool = _getPool(collection);
        for (uint256 i = 0; i < tokenIns.length; i++) {
            ERC721(collection).transferFrom(msg.sender, address(pool), tokenIns[i]);
        }
        int128 delta = pool.swap(tokenOuts, msg.sender, to);
        int256 nftDelta = (int256(tokenIns.length) - int256(tokenOuts.length));
        require(delta >= nftDelta * PLUS);
    }

    function pools(address collection) external view returns (address) {
        return address(_getPool(collection));
    }

    function _getPool(address collection) internal view returns (IDividedPool) {
        address predictedAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff), address(factory), keccak256(abi.encode(collection)), POOL_BYTECODE_HASH
                        )
                    )
                )
            )
        );
        return IDividedPool(predictedAddress);
    }
}