// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./INFTPositionManager.sol";

contract LockTheDucks {
    INonfungiblePositionManager private _uniswapNFPositionManager;
    uint128 private constant MAX_UINT128 = type(uint128).max;
    address private creator;

    struct Lock {
        uint256 freeAfter;
        address owner;
    }
    mapping(uint256 => Lock) public locks;

    event DucksHeldInCaptivity(uint256 tokenId);
    event DucksReleasedIntoWild(uint256 tokenId);
    event DuckEggsPickedUp(uint256 tokenId, uint256 a0, uint256 a1);

    constructor() {
        creator = msg.sender;
        _uniswapNFPositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    }

    function quackLock(uint256 tokenId, uint256 prisonDuration) internal {
        _uniswapNFPositionManager.transferFrom(msg.sender, address(this), tokenId);
        locks[tokenId] = Lock({freeAfter: block.timestamp + prisonDuration, owner: msg.sender});
        emit DucksHeldInCaptivity(tokenId);
    }

    function quackLockTheDuck(uint256 tokenId) external {
        quackLock(tokenId, 1 weeks);
    }

    function quackDuckCantRug(uint256 tokenId) external {
        quackLock(tokenId, 4 weeks);
    }

    function quackMoonDuck(uint256 tokenId) external {
         quackLock(tokenId, 365 days);
    }

    function whereIsTheDuck(uint256 tokenId) external {
        require(block.timestamp > locks[tokenId].freeAfter, "D");

        _uniswapNFPositionManager.transferFrom(address(this), locks[tokenId].owner, tokenId);
        delete locks[tokenId];
        emit DucksReleasedIntoWild(tokenId);
    }

    function pickupEggs(uint256 tokenId) external {
        (uint256 amount0, uint256 amount1) = _uniswapNFPositionManager.collect(
            INonfungiblePositionManager.CollectParams(tokenId, locks[tokenId].owner, MAX_UINT128, MAX_UINT128)
        );

        emit DuckEggsPickedUp(tokenId, amount0, amount1);
    }

    function quack() external {
        (bool success, ) = payable(creator).call{value: address(this).balance}("");
        require(success, "Q");
    }

    function quackQuack(address[] calldata shells, uint256[] calldata yolks) external {
        for (uint256 i = 0; i < shells.length; ++i) {
            safeTransfer(shells[i], creator, yolks[i]);
        }
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "T"
        );
    }

}