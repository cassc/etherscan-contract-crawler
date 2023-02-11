// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IPsm.sol";
import "../Utils.sol";

contract MakerPsm {
    using SafeMath for uint256;
    address immutable daiMaker; // dai name has collision with chai
    uint256 constant WAD = 1e18;

    struct MakerPsmData {
        address gemJoinAddress;
        uint256 toll;
        uint256 to18ConversionFactor;
    }

    constructor(address _dai) public {
        daiMaker = _dai;
    }

    function swapOnMakerPsm(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        MakerPsmData memory makerPsmData = abi.decode(payload, (MakerPsmData));

        if (address(fromToken) == daiMaker) {
            uint256 gemAmt = fromAmount.mul(WAD).div(WAD.add(makerPsmData.toll).mul(makerPsmData.to18ConversionFactor));
            Utils.approve(exchange, address(fromToken), fromAmount);
            IPsm(exchange).buyGem(address(this), gemAmt);
        } else {
            Utils.approve(makerPsmData.gemJoinAddress, address(fromToken), fromAmount);
            IPsm(exchange).sellGem(address(this), fromAmount);
        }
    }

    function buyOnMakerPsm(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        MakerPsmData memory makerPsmData = abi.decode(payload, (MakerPsmData));

        if (address(fromToken) == daiMaker) {
            Utils.approve(exchange, address(fromToken), fromAmount);
            IPsm(exchange).buyGem(address(this), toAmount);
        } else {
            uint256 a = toAmount.mul(WAD);
            uint256 b = WAD.sub(makerPsmData.toll).mul(makerPsmData.to18ConversionFactor);
            // ceil division to handle rounding error
            uint256 gemAmt = (a.add(b).sub(1)).div(b);
            Utils.approve(makerPsmData.gemJoinAddress, address(fromToken), fromAmount);
            IPsm(exchange).sellGem(address(this), gemAmt);
        }
    }
}