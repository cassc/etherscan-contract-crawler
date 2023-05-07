// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "solmate/tokens/ERC20.sol";
import "solmate/auth/Owned.sol";

interface LP {
    function sync() external;
}

contract HyprPepe is ERC20, Owned {
    constructor() ERC20("HyprPepe", "HYPR", 18) Owned(msg.sender) {
        _mint(msg.sender, 1e30);
        lastEpoch = block.timestamp;
    }

    uint256 public epochBps = 100;
    uint256 public lastEpoch;

    // **ONLY OWNABLE FUNCTION**
    // Allows dev to set what % of HYPR is removed from the LP every 15 minutes
    function setEpochBps(uint256 _bps) external onlyOwner {
        // Make sure dev cannot set bps above 10% per 15 minutes
        require(
            _bps <= 1000,
            "HyprPepe: BPS cannot be greater than 10% per epoch"
        );
        if (epochBps == 0) lastEpoch = block.timestamp;
        epochBps = _bps;
    }

    // Takes a fraction of the HYPR in the liquidity pool, burns half and distrubutes half to the HyprFarm
    function collectDividendsAndBurn() external {
        uint256 bps = epochBps;
        // Only if 15 minutes has past and bps is not 0
        if (bps > 0 && block.timestamp >= lastEpoch + 900) {
            uint256 epocsPast = (block.timestamp - lastEpoch) / 900;
            lastEpoch = lastEpoch + (epocsPast * 900);

            uint256 halfAmount = 1e18;
            for (uint256 i = 0; i < epocsPast; i++) {
                halfAmount = (halfAmount * (10000 - bps)) / 10000;
            }
            halfAmount = 1e18 - halfAmount;
            halfAmount =
                ((halfAmount *
                    balanceOf[0x69e665893cFf87C48ad29f9E092081449624dD91]) /
                    1e18) /
                2;

            // Burn half
            _burn(0x69e665893cFf87C48ad29f9E092081449624dD91, halfAmount);

            // Send half to HyprFarm
            balanceOf[0x69e665893cFf87C48ad29f9E092081449624dD91] -= halfAmount;
            unchecked {
                // Cannot overflow because the sum of all user
                // balances can't exceed the max uint256 value.
                balanceOf[
                    0xB41E92a9e115e823a2581B28f290b4ebb4F48822
                ] += halfAmount;
            }
            emit Transfer(
                0x69e665893cFf87C48ad29f9E092081449624dD91,
                0xB41E92a9e115e823a2581B28f290b4ebb4F48822,
                halfAmount
            );

            // Sync LP reserves
            LP(0x69e665893cFf87C48ad29f9E092081449624dD91).sync();
        }
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}