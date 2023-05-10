// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableValidatorPool.sol";
import "contracts/interfaces/IValidatorPool.sol";

contract DutchAuction is Initializable, ImmutableFactory, ImmutableValidatorPool {
    uint256 private constant _START_PRICE = 1000000 * 10 ** 18;
    uint256 private constant _ETHDKG_VALIDATOR_COST = 1200000 * 2 * 100 * 10 ** 9; // Exit and enter ETHDKG aprox 1.2 M gas units at an estimated price of 100 gwei
    uint8 private constant _DECAY = 16;
    uint16 private constant _SCALE_PARAMETER = 100;
    uint256 private _startBlock;
    uint256 private _finalPrice;

    constructor() ImmutableFactory(msg.sender) {}

    //TODO add state checks and/or initializer guards
    function initialize() public {
        resetAuction();
    }

    /// @dev Re-starts auction defining auction's start block
    function resetAuction() public onlyFactory {
        _finalPrice =
            _ETHDKG_VALIDATOR_COST *
            IValidatorPool(_validatorPoolAddress()).getValidatorsCount();
        _startBlock = block.number;
    }

    /// @dev Returns dutch auction price for current block
    function getPrice() public view returns (uint256) {
        return _dutchAuctionPrice(block.number - _startBlock);
    }

    /// @notice Calculates dutch auction price for the specified period (number of blocks since auction initialization)
    /// @dev
    /// @param blocks blocks since the auction started
    function _dutchAuctionPrice(uint256 blocks) internal view returns (uint256 result) {
        uint256 _alfa = _START_PRICE - _finalPrice;
        uint256 t1 = _alfa * _SCALE_PARAMETER;
        uint256 t2 = _DECAY * blocks + _SCALE_PARAMETER ** 2;
        uint256 ratio = t1 / t2;
        return _finalPrice + ratio;
    }
}