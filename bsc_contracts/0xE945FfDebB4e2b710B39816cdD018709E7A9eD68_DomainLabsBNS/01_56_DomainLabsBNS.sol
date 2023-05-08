// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./bnbregistrar/BNBRegistrarControllerV11.sol";
import "./bnbregistrar/BaseRegistrarImplementation.sol";
import "./price-oracle/ISidPriceOracle.sol";

/**
 * @dev A DomainLabs controller for registering and renewing names at fixed cost.
 */

contract DomainLabsBNS is Ownable {
    BNBRegistrarControllerV11 registerController;
    BaseRegistrarImplementation baseController;
    AggregatorV3Interface internal usdOracle;

    struct domain {
        string name;
        uint256 duration;
        bytes32 secret;
    }

    event NameRegistered(domain[], address indexed owner);
    event NameRenewed(string name, bytes32 indexed label, uint duration);

    constructor(
        address _registerControllerAddress,
        address _baseControllerAddress
    ) {
        registerController = BNBRegistrarControllerV11(
            _registerControllerAddress
        );
        baseController = BaseRegistrarImplementation(_baseControllerAddress);
        usdOracle = AggregatorV3Interface(
            0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
        );
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            ,
            int price,
            ,
            ,
        ) = usdOracle.latestRoundData();
        return price;
    }

    function strlen(string memory s) internal pure returns (uint) {
        uint len;
        uint i = 0;
        uint bytelength = bytes(s).length;
        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }

    function rentPrice(
        string memory name,
        uint256 duration
    ) public view returns (uint256) {
        uint256 totalPrice = 0;
        ISidPriceOracle.Price memory price;
        price = registerController.rentPrice(name, duration);
        totalPrice += price.base + price.premium;
        uint len = strlen(name);
        if (len >= 5) {
            totalPrice =
                totalPrice +
                attoUSDToWei(1) *
                (duration / (365 * 24 * 3600));
        } else {
            totalPrice = (totalPrice * 110) / 100;
        }
        return totalPrice;
    }

    function rentPrices(
        domain[] memory domains
    ) public view returns (uint256, uint256[] memory) {
        uint256 totalPrice = 0;
        uint256 price = 0;
        uint256[] memory prices = new uint256[](domains.length);

        for (uint256 i = 0; i < domains.length; i++) {
            price = rentPrice(domains[i].name, domains[i].duration);
            prices[i] = price;
            totalPrice += price;
        }
        return (totalPrice, prices);
    }

    function attoUSDToWei(uint256 amount) internal view returns (uint256) {
        uint256 bnbPrice = uint256(getLatestPrice());
        return (amount * 10**26) / bnbPrice;
    }

    function commits(domain[] memory domains) public {
        address caller = msg.sender;
        for (uint256 i = 0; i < domains.length; i++) {
            bytes32 commitment = registerController.makeCommitment(
                domains[i].name,
                caller,
                domains[i].secret
            );
            registerController.commit(commitment);
        }
    }

    function registerBnb(domain[] memory domains, address resolver) external payable {
        address caller = msg.sender;
        uint256 len = domains.length;
        (uint256 totalPrices, uint256[] memory prices) = rentPrices(domains);
        require(msg.value >= totalPrices);
        for (uint256 i = 0; i < len; i++) {
            registerController.registerWithConfig{value: prices[i]}(
                domains[i].name,
                caller,
                domains[i].duration,
                domains[i].secret,
                resolver
            );
        }
        // Refund any extra payment
        if (msg.value > totalPrices) {
            payable(msg.sender).transfer(msg.value - totalPrices);
        }
        emit NameRegistered(domains, caller);
    }

    function renewBnb(string calldata name, uint duration) external payable {
        uint256 price = rentPrice(name, duration);
        require(msg.value >= price);
        registerController.renew{value: price}(name, duration);
        bytes32 label = keccak256(bytes(name));
        // Refund any extra payment
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
        emit NameRenewed(name, label, duration);
    }

    receive() external payable {}

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}