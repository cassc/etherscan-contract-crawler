pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AssetSender {

    address constant public nativeCoinUnderlying = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    struct AssetAndAmount {
        address asset;
        uint amount;
    }

    function sendAssetsFromSender(AssetAndAmount[] calldata assetsAndAmounts, address to) external {
        address from = msg.sender;

        for (uint i = 0; i < assetsAndAmounts.length; i++) {
            sendAssetInternal(from, to, assetsAndAmounts[i]);
        }
    }

    function sendAssetInternal(address from, address to, AssetAndAmount calldata assetAndAmount) internal {
        if (assetAndAmount.asset == nativeCoinUnderlying) {
            payable(to).transfer(assetAndAmount.amount);
        } else {
            IERC20(assetAndAmount.asset).transferFrom(from, to, assetAndAmount.amount);
        }
    }
}