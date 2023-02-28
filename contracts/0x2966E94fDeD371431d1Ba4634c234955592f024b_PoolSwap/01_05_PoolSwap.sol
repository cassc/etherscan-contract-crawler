// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IERC721PoolFactory.sol";
import "./interfaces/IERC721Pool.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract PoolSwap {
    IERC721PoolFactory POOL_FACTORY = IERC721PoolFactory(0xb67dc4B5A296C3068E8eEc16f02CdaE4c9A255e5);

    error ArrayLengthMismatch();
    error NoTokensSent();
    error PoolDoesNotExist();

    function swapTokens(address collectionAddress, uint256[] calldata tokensToSend, uint256[] calldata tokensToReceive) external {
        address poolAddress = POOL_FACTORY.getPool(collectionAddress);

        if(tokensToSend.length != tokensToReceive.length) { revert ArrayLengthMismatch(); }
        if(tokensToSend.length == 0) { revert NoTokensSent(); }
        if(poolAddress == address(0)) { revert PoolDoesNotExist(); }

        IERC721 nftContract = IERC721(collectionAddress);
        IERC721Pool nftPool = IERC721Pool(poolAddress);

        if(!nftContract.isApprovedForAll(address(this), poolAddress)) {
            nftContract.setApprovalForAll(poolAddress, true);
        }

        for(uint256 i = 0;i < tokensToReceive.length;) {
            nftContract.transferFrom(msg.sender, address(this), tokensToSend[i]);
            unchecked {
                ++i;
            }
        }

        nftPool.deposit(tokensToSend);
        nftPool.withdraw(tokensToReceive);

        for(uint256 i = 0;i < tokensToReceive.length;) {
            nftContract.transferFrom(address(this), msg.sender, tokensToReceive[i]);
            unchecked {
                ++i;
            }
        }
    }
}