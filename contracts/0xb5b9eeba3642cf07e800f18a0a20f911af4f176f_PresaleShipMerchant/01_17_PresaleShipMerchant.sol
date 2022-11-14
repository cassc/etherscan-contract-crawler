// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

/**
 *__/\\\______________/\\\_____/\\\\\\\\\_______/\\\\\\\\\______/\\\\\\\\\\\\\___
 * _\/\\\_____________\/\\\___/\\\\\\\\\\\\\___/\\\///////\\\___\/\\\/////////\\\_
 *  _\/\\\_____________\/\\\__/\\\/////////\\\_\/\\\_____\/\\\___\/\\\_______\/\\\_
 *   _\//\\\____/\\\____/\\\__\/\\\_______\/\\\_\/\\\\\\\\\\\/____\/\\\\\\\\\\\\\/__
 *    __\//\\\__/\\\\\__/\\\___\/\\\\\\\\\\\\\\\_\/\\\//////\\\____\/\\\/////////____
 *     ___\//\\\/\\\/\\\/\\\____\/\\\/////////\\\_\/\\\____\//\\\___\/\\\_____________
 *      ____\//\\\\\\//\\\\\_____\/\\\_______\/\\\_\/\\\_____\//\\\__\/\\\_____________
 *       _____\//\\\__\//\\\______\/\\\_______\/\\\_\/\\\______\//\\\_\/\\\_____________
 *        ______\///____\///_______\///________\///__\///________\///__\///______________
 **/

// @openzeppelin
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol';
// helpers
import '../helpers/WarpBaseUpgradeable.sol';
// Interfaces
import '../interfaces/IERC20Burnable.sol';
import '../interfaces/IERC20Decimals.sol';
import '../interfaces/IStarship.sol';
import '../interfaces/IPresaleShipMerchant.sol';

/** Pioneer index is 11 */

contract PresaleShipMerchant is IPresaleShipMerchant, WarpBaseUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    //** ====== Events ====== *//
    event PresaleBuildShip(
        address indexed to,
        uint256 tokenId,
        string name,
        address principle,
        uint256 archetype,
        uint256 cost,
        bool bonus
    );

    event RandomBuildShip(
        address indexed to,
        uint256 tokenId,
        address principle,
        uint256 cost,
        bool bonus
    );

    //** ====== Struct ====== *//

    /** @notice used for getter to get all principles */
    struct Principle {
        address token;
        uint256 multiplier;
    }

    //** ====== Variables ====== *//
    address fund;
    address starship;

    // Costs
    uint256 public baseCost;
    uint256 public whitelistDiscount;
    uint256 public current;

    EnumerableSetUpgradeable.AddressSet principles;
    AggregatorV3Interface internal priceFeed;
    mapping(address => bool) verifiers;
    address public presaleToken;

    mapping(address => uint256) public purchased;

    /** ====== Initialize ====== */
    function initialize(
        address _fund,
        address _starship,
        uint256 _current
    ) public initializer {
        __WarpBase_init();

        fund = _fund;
        starship = _starship;

        baseCost = 200.0 ether;
        whitelistDiscount = 50.0 ether;

        current = _current;
    }

    // function buyShipExternal(
    //     address _principle,
    //     uint256 _value,
    //     address _to
    // ) external override whenNotPaused {
    //     require(msg.sender == presaleToken, 'Forbidden');

    //     uint256 _archetype = uint256(
    //         keccak256(abi.encodePacked(block.timestamp, block.number, block.difficulty))
    //     ) % 11;

    //     current += 1;
    //     IStarship(starship).mint(_to, current, false);
    //     emit PresaleBuildShip(_to, current, '', _principle, _archetype, _value, false);
    // }

    /** @dev buy ship
        @param _principle {address}
        @param _signature {bytes}
     */
    function buyShip(
        uint256 amount,
        address _principle,
        bytes memory _signature
    ) public whenNotPaused {
        require(amount > 0, 'Amount must be greater then 0');
        purchased[msg.sender] += amount;
        require(purchased[msg.sender] <= 3, "Don't be greedy, 3 is the max.");
        // Get cost
        uint256 cost = viewCost(_principle, isWhitelisted(_signature)) * amount;

        // Transfer
        IERC20Upgradeable(_principle).safeTransferFrom(msg.sender, address(this), cost); // Transfer from sender, then deposit to treasury and sendout grwoth fee

        for (uint256 i = 0; i < amount; i++) {
            // Mint
            current += 1;
            IStarship(starship).mint(msg.sender, current, false);
            emit RandomBuildShip(msg.sender, current, _principle, cost / amount, true);
        }
    }

    /** @dev buy ship payable
        @param _signature {bytes}
     */
    function buyShipPayable(uint256 amount, bytes memory _signature) public payable whenNotPaused {
        require(amount > 0, 'Amount must be greater then 0');
        purchased[msg.sender] += amount;
        require(purchased[msg.sender] <= 3, "Don't be greedy, 3 is the max.");

        //** Get msg.value cost */
        uint256 payment = payableUSD(msg.value);

        //** Get cost of the starship */
        uint256 cost = baseCost * amount;
        if (isWhitelisted(_signature)) cost -= (whitelistDiscount * amount);

        //** Ensure payment > cost */
        require(payment >= cost, 'Invalid cost');

        /** Build ship */
        for (uint256 i = 0; i < amount; i++) {
            // Mint
            current += 1;
            IStarship(starship).mint(msg.sender, current, false);
            emit RandomBuildShip(msg.sender, current, address(0), cost / amount, true);
        }
    }

    /** @dev set allowed principle
        @param _principle {address}
        @param _allowed {bool}
     */
    function setAllowedPrinciples(address _principle, bool _allowed) external onlyOwner {
        if (_allowed) {
            principles.add(_principle);
        } else principles.remove(_principle);
    }

    /** @notice update fund */
    function setAddress(uint256 _idx, address _address) external onlyOwner {
        if (_idx == 0) {
            fund = _address;
        } else if (_idx == 1) {
            priceFeed = AggregatorV3Interface(_address);
        } else if (_idx == 2) {
            presaleToken = _address;
        }
    }

    /** @notice sets an integer depending on idx */
    function setInteger(uint256 _idx, uint256 _value) external onlyOwner {
        if (_idx == 0) {
            baseCost = _value;
        } else if (_idx == 1) {
            whitelistDiscount = _value;
        } else if (_idx == 2) {
            current = _value;
        }
    }

    /** @notice Remove or add a verifier */
    function setVerifier(address _verifier, bool _isVerifier) external onlyOwner {
        verifiers[_verifier] = _isVerifier;
    }

    /** @notice View cost of starship based on ship strength */
    function viewCost(address _principle, bool _whitelisted) public view returns (uint256 cost) {
        require(principles.contains(_principle), 'Unallowed principle.');

        cost = baseCost;
        if (_whitelisted) cost -= whitelistDiscount;
        // Convert to match principle decimals
        cost /= (1e18 / 10**IERC20Decimals(_principle).decimals());
    }

    /** @notice View cost based on msg.value amount */
    function payableUSD(uint256 value) public view returns (uint256) {
        if (block.chainid == 3) {
            /** Just pretend eth is 1200$ on ropsten */
            return value * 1200;
        } else {
            (, int256 basePrice, , , ) = priceFeed.latestRoundData();
            uint8 baseDecimals = priceFeed.decimals();
            uint256 payment = (uint256(basePrice) * value) / uint256(10**baseDecimals);
            return payment;
        }
    }

    /** @notice get principles */
    function getPrinciples() public view returns (address[] memory) {
        address[] memory addresses = new address[](principles.length());

        for (uint256 i = 0; i < principles.length(); i++) {
            addresses[i] = principles.at(i);
        }

        return addresses;
    }

    /** @notice view function to get values for UI */
    function getValues()
        public
        view
        returns (
            uint256,
            uint256,
            address[] memory
        )
    {
        return (baseCost, whitelistDiscount, getPrinciples());
    }

    function isWhitelisted(bytes memory _signature) internal view returns (bool) {
        bytes32 messageHash = sha256(abi.encode(msg.sender));
        address signedAddress = ECDSAUpgradeable.recover(messageHash, _signature);
        return verifiers[signedAddress];
    }

    /** @notice withdraw tokens stuck in contract */
    function withdrawTokens(address token) external onlyOwner {
        if (token == address(0)) {
            safeTransferETH(fund, address(this).balance);
        } else {
            IERC20Upgradeable(token).safeTransfer(
                fund,
                IERC20Upgradeable(token).balanceOf(address(this))
            );
        }
    }

    /** @notice safe transfer eth */
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    /** AUX */
    function estimateCost(bytes memory _signature, uint256 value)
        public
        view
        returns (
            uint256,
            uint256,
            bool,
            bool
        )
    {
        //** Get msg.value cost */
        uint256 payment = payableUSD(value);

        //** Get cost of the starship */
        uint256 cost = baseCost;
        bool _isWhitelisted = isWhitelisted(_signature);
        if (_isWhitelisted) cost -= whitelistDiscount;

        return (payment, cost, _isWhitelisted, payment >= cost);
    }
}