// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMagpieCore.sol";
import "./interfaces/IMagpieRouter.sol";
import "./lib/LibAsset.sol";
import "./lib/LibSwap.sol";

contract MagpieGasStation is Ownable {
    using LibAsset for address;
    using LibSwap for IMagpieRouter.SwapArgs;
    address private magpieCoreAddress;

    constructor(address _magpieCoreAddress) {
        magpieCoreAddress = _magpieCoreAddress;
    }

    function updateMagpieCoreAddress(address _magpieCoreAddress)
        external
        onlyOwner
    {
        magpieCoreAddress = _magpieCoreAddress;
    }

    function swap(IMagpieRouter.SwapArgs calldata swapArgs)
        external
        returns (uint256 estimatedGas)
    {
        address fromAddress = swapArgs.getFromAssetAddress();
        uint256 amount = swapArgs.getAmountIn();

        fromAddress.transferFrom(msg.sender, address(this), amount);

        fromAddress.approve(magpieCoreAddress, amount);

        uint256 initialGas = gasleft();

        IMagpieCore(magpieCoreAddress).swap(swapArgs);

        estimatedGas = initialGas - gasleft();
    }

    function swapIn(IMagpieCore.SwapInArgs calldata args)
        external
        returns (uint256 estimatedGas)
    {
        address fromAddress = args.swapArgs.getFromAssetAddress();
        uint256 amount = args.swapArgs.getAmountIn();

        fromAddress.transferFrom(msg.sender, address(this), amount);

        fromAddress.approve(magpieCoreAddress, amount);

        uint256 initialGas = gasleft();

        IMagpieCore(magpieCoreAddress).swapIn(args);

        estimatedGas = initialGas - gasleft();
    }

    function swapOut(IMagpieCore.SwapOutArgs calldata args)
        external
        returns (uint256 estimatedGas)
    {
        uint256 initialGas = gasleft();

        IMagpieCore(magpieCoreAddress).swapOut(args);

        estimatedGas = initialGas - gasleft();
    }
}