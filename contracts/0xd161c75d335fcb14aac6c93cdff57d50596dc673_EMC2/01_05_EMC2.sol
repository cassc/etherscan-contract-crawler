// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.11;

import "./interfaces/INFT.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IWETH is IERC20 {
    function withdraw(uint256 amount) external;
}

interface IToken is IERC20 {
    function burn() external;
}

contract EMC2 is Ownable {
    INonfungiblePositionManager public uniswapNFTmanager;
    IToken public token;
    IWETH public weth;
    mapping(uint256 => uint256) public locks;

    event LockNFT(address who, uint256 nftId, uint256 unlockAt);

    constructor(address _uniswapNFTmanager, address _token, address _weth) {
        uniswapNFTmanager = INonfungiblePositionManager(_uniswapNFTmanager);
        token = IToken(_token);
        weth = IWETH(_weth);
    }

    function lockNFT(uint256 id, uint256 duration) public onlyOwner {
        uniswapNFTmanager.transferFrom(msg.sender, address(this), id);
        locks[id] = block.timestamp + duration;
        emit LockNFT(msg.sender, id, locks[id]);
    }

    function extendLock(uint256 id, uint256 duration) public onlyOwner {
        uint256 lock = block.timestamp + duration;
        require(lock > locks[id], "lock shorter than previous");
        locks[id] = lock;
        emit LockNFT(msg.sender, id, locks[id]);
    }

    function increaseRewards(uint256 nftId) external {
        // set amount0Max and amount1Max to uint256.max to collect all fees
        // alternatively can set recipient to msg.sender and avoid another transaction in `sendToOwner`
        INonfungiblePositionManager.CollectParams
            memory params = INonfungiblePositionManager.CollectParams({
                tokenId: nftId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        uniswapNFTmanager.collect(params);

        // send eth fees back to the token contract
        weth.withdraw(weth.balanceOf(address(this)));
        payable(address(token)).transfer(address(this).balance);

        // burn rest of the tokens
        token.burn();
    }

    function withdraw(uint256 nftId) external onlyOwner {
        require(block.timestamp > locks[nftId], "nft is locked");
        uniswapNFTmanager.transferFrom(address(this), msg.sender, nftId);
    }
}