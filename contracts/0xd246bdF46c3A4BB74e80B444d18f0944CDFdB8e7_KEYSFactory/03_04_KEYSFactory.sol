// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "contracts/lib/IMintableNft.sol";

contract KEYSFactory {
    IMintableNft public nft;
    uint256 public price = 1e16;
    address _rewardAddress;

    constructor(address nftAddress) {
        nft = IMintableNft(nftAddress);
        _rewardAddress = msg.sender;
    }

    function mint(address to, uint256 count) external payable {
        uint256 needEth = this.priceOf(count);
        require(msg.value >= needEth, "not enough eth");
        for (uint256 i = 0; i < count; ++i) nft.mint(to);
        sendEth(_rewardAddress, needEth);
        sendEth(msg.sender, msg.value - needEth);
    }

    function priceOf(uint256 count) external view returns (uint256) {
        return count * price;
    }

    function sendEth(address addr, uint256 ethCount) internal {
        if (ethCount <= 0) return;
        (bool sent, ) = addr.call{value: ethCount}("");
        require(sent, "ethereum is not sent");
    }
}