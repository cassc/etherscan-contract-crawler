// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import { INounsSeeder } from "contracts/interfaces/INounsSeeder.sol";
import { INounsDescriptorMinimal } from "contracts/interfaces/INounsDescriptorMinimal.sol";
import { INounsDescriptorV2 } from "contracts/interfaces/INounsDescriptorV2.sol";
import { IRoboNounsVRGDA } from "contracts/interfaces/IRoboNounsVRGDA.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { VRGDA } from "contracts/lib/VRGDA.sol";
import { RoboNounsToken } from "contracts/RoboNounsToken.sol";
import { toWadUnsafe, toDaysWadUnsafe, wadLn } from "solmate/src/utils/SignedWadMath.sol";

contract RoboNounsVRGDA is IRoboNounsVRGDA, Ownable {
    address public constant nounsDAO = 0x0BC3807Ec262cB779b38D65b38158acC3bfedE10;

    /// @notice Time of sale of the first RoboNoun, used to calculate VRGDA price
    uint256 public startTime;

    /// @notice How often the VRGDA price will update to reflect VRGDA pricing rules
    uint256 public priceDecayInterval;

    /// @notice Time interval that serves as the basis for the target sale time
    uint256 public targetSaleInterval;

    /// @notice the last block at which the last roboNoun was sold
    uint256 public lastTokenBlock;

    /// @notice The minimum price accepted in an auction
    uint256 public reservePrice;

    /// @notice The Nouns ERC721 token contract
    RoboNounsToken public roboNounsToken;

    /// @notice Target price for a token, to be scaled according to sales pace.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 public targetPrice;

    /// @dev Precomputed constant that allows us to rewrite a pow() as an exp().
    /// @dev Represented as an 18 decimal fixed point number.
    int256 public decayConstant;

    /// @dev The total number of tokens to target selling every full unit of time.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 public perTimeUnit;

    constructor(
        uint256 _reservePrice,
        int256 _targetPrice,
        int256 _priceDecayPercent,
        int256 _perTimeUnit,
        uint256 _priceDecayInterval,
        uint256 _targetSaleInterval,
        address _token
    ) {
        decayConstant = wadLn(1e18 - _priceDecayPercent);
        require(decayConstant < 0, "NON_NEGATIVE_DECAY_CONSTANT");

        roboNounsToken = RoboNounsToken(_token);
        startTime = block.timestamp;
        reservePrice = _reservePrice;
        targetPrice = _targetPrice;
        perTimeUnit = _perTimeUnit;
        priceDecayInterval = _priceDecayInterval;
        targetSaleInterval = _targetSaleInterval;
        lastTokenBlock = block.number;
    }

    /// @param expectedBlockNumber The block number to specify the traits of the token
    function buyNow(uint256 expectedBlockNumber) external payable {
        // will allow to mint token with traits generated from 4 last blocks (starting from parent, because current has not hash yet),
        require(
            expectedBlockNumber <= block.number - 1 ||
                expectedBlockNumber > lastTokenBlock ||
                expectedBlockNumber >= block.number - 4,
            "Invalid block number"
        );

        // making it unable to get the a token with the traits for any previous token (pool is emptied when a noun is bought, this prevents buying duplicates)
        lastTokenBlock = expectedBlockNumber;

        // Validate the purchase request against the VRGDA rules.
        uint256 vrgdaPrice = getCurrentVRGDAPrice();
        uint256 price = vrgdaPrice > reservePrice ? vrgdaPrice : reservePrice;
        require(msg.value >= price, "Insufficient funds");

        // Call settleAuction on the roboNouns contract.
        uint256 mintedNounId = roboNounsToken.mint(expectedBlockNumber);

        // Sends token to caller.
        roboNounsToken.transferFrom(address(this), msg.sender, mintedNounId);

        // refund
        uint refund = msg.value - price;
        if (msg.value > price) {
            _sendETH(msg.sender, refund);
        }

        // Send funds to DAO.
        _sendETH(nounsDAO, msg.value - refund);

        emit AuctionSettled(mintedNounId, msg.sender, price);
    }

    /// @notice Set the auction reserve price.
    /// @dev Only callable by the owner.
    function setReservePrice(uint256 _reservePrice) external onlyOwner {
        reservePrice = _reservePrice;
        emit AuctionReservePriceUpdated(_reservePrice);
    }

    /// @notice Set the auction update interval.
    /// @dev Only callable by the owner.
    function setUpdateInterval(uint256 _priceDecayInterval) external onlyOwner {
        priceDecayInterval = _priceDecayInterval;
        emit AuctionPriceDecayIntervalUpdated(_priceDecayInterval);
    }

    /// @notice Set the auction target price.
    /// @dev Only callable by the owner.
    function setTargetPrice(int256 _targetPrice) external onlyOwner {
        targetPrice = _targetPrice;
        emit AuctionTargetPriceUpdated(_targetPrice);
    }

    /// @notice Set the auction price decay percent.
    /// @dev Only callable by the owner.
    function setPriceDecayPercent(int256 _priceDecayPercent) external onlyOwner {
        decayConstant = wadLn(1e18 - _priceDecayPercent);
        require(decayConstant < 0, "NON_NEGATIVE_DECAY_CONSTANT");
        emit AuctionPriceDecayPercentUpdated(_priceDecayPercent);
    }

    /// @notice Set the auction per time unit.
    /// @dev Only callable by the owner.
    function setPerTimeUnit(uint256 _perTimeUnit) external onlyOwner {
        perTimeUnit = toWadUnsafe(_perTimeUnit);
        emit AuctionPerTimeUnitUpdated(_perTimeUnit);
    }

    /// @notice Fetch data associated with the noun for sale
    /// @dev actual implementation of the fetchNoun function
    function fetchNoun(
        uint256 _blockNumber
    )
        external
        view
        returns (uint256 nounId, INounsSeeder.Seed memory seed, string memory svg, uint256 price, uint256 blockNumber)
    {
        uint256 nextId = roboNounsToken.currentNounId();
        INounsSeeder seeder = INounsSeeder(roboNounsToken.seeder());
        INounsDescriptorMinimal roboDescriptor = roboNounsToken.roboDescriptor();
        INounsDescriptorV2 descriptor = INounsDescriptorV2(address(roboNounsToken.roboDescriptor()));

        seed = seeder.generateSeed(nextId, roboDescriptor, _blockNumber);

        // Generate the SVG from seed using the descriptor.
        svg = descriptor.generateSVGImage(seed);

        // Calculate price based on VRGDA rules.
        uint256 vrgdaPrice = getCurrentVRGDAPrice();
        price = vrgdaPrice > reservePrice ? vrgdaPrice : reservePrice;

        return (nextId, seed, svg, price, _blockNumber);
    }

    /// @notice Fetch data associated with the noun for sale
    /// @dev actual implementation of the fetchNoun function
    function fetchNextNoun()
        external
        view
        returns (uint256 nounId, INounsSeeder.Seed memory seed, string memory svg, uint256 price, uint256 blockNumber)
    {
        uint256 nextId = roboNounsToken.currentNounId();
        INounsSeeder seeder = INounsSeeder(roboNounsToken.seeder());
        INounsDescriptorMinimal roboDescriptor = roboNounsToken.roboDescriptor();
        INounsDescriptorV2 descriptor = INounsDescriptorV2(address(roboNounsToken.roboDescriptor()));

        seed = seeder.generateSeed(nextId, roboDescriptor, block.number - 1);

        // Generate the SVG from seed using the descriptor.
        svg = descriptor.generateSVGImage(seed);

        // Calculate price based on VRGDA rules.
        uint256 vrgdaPrice = getCurrentVRGDAPrice();
        price = vrgdaPrice > reservePrice ? vrgdaPrice : reservePrice;

        return (nextId, seed, svg, price, block.number - 1);
    }

    /// @notice Get the current price according to the VRGDA rules.
    /// @return price The current price in Wei
    function getCurrentVRGDAPrice() public view returns (uint256) {
        uint256 nextId = roboNounsToken.currentNounId();
        uint256 absoluteTimeSinceStart = block.timestamp - startTime;
        return
            VRGDA.getVRGDAPrice(
                toTimeIntervalWadUnsafe(
                    (absoluteTimeSinceStart - (absoluteTimeSinceStart % priceDecayInterval)),
                    targetSaleInterval
                ),
                targetPrice,
                decayConstant,
                // Theoretically calling toWadUnsafe with sold can silently overflow but under
                // any reasonable circumstance it will never be large enough. We use sold + 1 as
                // the VRGDA formula's n param represents the nth token and sold is the n-1th token.
                VRGDA.getTargetSaleTimeLinear(toWadUnsafe(nextId), perTimeUnit)
            );
    }

    function toTimeIntervalWadUnsafe(uint256 timeSince, uint256 intervalTarget) public pure returns (int256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Multiply <timeSince> by 1e18 and then divide it by <intervalTarget>.
            r := div(mul(timeSince, 1000000000000000000), intervalTarget)
        }
    }

    function _sendETH(address to, uint256 _value) internal {
        (bool sent, ) = to.call{ value: _value }("");
        require(sent, "failed to send eth");
    }
}