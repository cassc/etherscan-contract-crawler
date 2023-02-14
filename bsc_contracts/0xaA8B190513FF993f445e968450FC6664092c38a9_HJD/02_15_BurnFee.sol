// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Owned.sol";
import "./ERC20.sol";
import "./IERC20.sol";

abstract contract BurnFee is Owned, ERC20 {
    uint256 constant burnFee = 10;
    uint256 private randomSeed = 0;

    function _takeBurn(
        address sender,
        uint256 amount,
        address distributor
    ) internal returns (uint256) {
        uint256 burnAmount = (amount * 1e8 * burnFee) / 1000 / 1e8;
        uint256 blindAmount = burnAmount / 10;
        if (blindAmount > 5000) {
            _blindToken(sender, blindAmount, 5, distributor);
            super._transfer(
                sender,
                address(0xdead),
                (burnAmount - blindAmount)
            );
        } else {
            super._transfer(sender, address(0xdead), burnAmount);
        }
        return burnAmount;
    }

    function _blindToken(
        address sender,
        uint256 tokenAmount,
        uint256 number,
        address distributor
    ) internal {
        uint256 total = 0;
        for (uint256 i = 0; i < number; i++) {
            uint256 amount = _createRandom(100, 1000);
            address tempAddress = _createAddress(i, amount);
            super._transfer(sender, tempAddress, amount);
            total = total + amount;
        }
        if (tokenAmount > total) {
            super._transfer(
                sender,
                address(distributor),
                (tokenAmount - total)
            );
        }
    }

    function _createAddress(uint256 number1, uint256 number2)
        internal
        view
        returns (address)
    {
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(number1, number2, block.timestamp)
                        )
                    )
                )
            );
    }

    function _createRandom(uint256 minValue, uint256 maxValue)
        internal
        returns (uint256)
    {
        require(maxValue > minValue, "minValue<maxValue");
        randomSeed = randomSeed + 1;
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    randomSeed,
                    block.gaslimit,
                    block.coinbase,
                    block.timestamp
                )
            )
        );
        randomNumber = (randomNumber % (maxValue - minValue)) + minValue;
        return randomNumber;
    }
}
