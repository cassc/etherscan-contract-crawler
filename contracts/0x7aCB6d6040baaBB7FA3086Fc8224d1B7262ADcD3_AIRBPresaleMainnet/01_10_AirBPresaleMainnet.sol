// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin-contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin-contracts/security/ReentrancyGuard.sol";
import {Address} from "@openzeppelin-contracts/utils/Address.sol";

import {AggregatorV3Interface} from "@chainlink-contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {IAIRBPresaleMainnet} from "../interfaces/IAirBPresaleMainnet.sol";

/**
 *
 *          _____   .___ __________ __________
 *         /  _  \  |   |\______   \\______   \
 *        /  /_\  \ |   | |       _/ |    |  _/
 *       /    |    \|   | |    |   \ |    |   \
 *       \____|__  /|___| |____|_  / |______  /
 *               \/              \/         \/
 *
 * @title AIRBPresale contract on Ethereum Mainnet
 * @author InnoPlatforms - BillionAir.com
 * @notice Presale contract for BillionAir $AIRB AIRB
 * @notice This contract collects payments for the presale
 *         of $AIRB tokens that is also available on the BSC network
 *
 */
contract AIRBPresaleMainnet is Ownable, ReentrancyGuard, IAIRBPresaleMainnet {
    using SafeERC20 for IERC20;

    using Address for address payable;

    // ERC-20 address => AggregatorV3Interface
    mapping(address => AggregatorV3Interface) public paymentTokenToPriceFeed;

    // tokensBought[address] = number of tokens bought by address
    mapping(address => uint256) public tokensBought;

    uint256 public tokensSold;

    // Supported payment methods
    address[] public supportedPaymentMethods;

    // Is supported payment method
    mapping(address => bool) public isSupportedPaymentMethod;

    uint256 public tokenPrice;

    uint256 public startTime;

    uint256 public endTime;

    // Treasury address
    address public immutable treasury;

    // Events
    event TokensBought(
        address indexed buyer,
        address indexed paymentToken,
        uint256 numberOfTokens,
        address indexed referrer
    );

    /*
        _______________  ___________________________________  _______      _____  .____     
        \_   _____/\   \/  /\__    ___/\_   _____/\______   \ \      \    /  _  \ |    |    
        |    __)_  \     /   |    |    |    __)_  |       _/ /   |   \  /  /_\  \|    |    
        |        \ /     \   |    |    |        \ |    |   \/    |    \/    |    \    |___ 
        /_______  //___/\  \  |____|   /_______  / |____|_  /\____|__  /\____|__  /_______ \
                \/       \_/                   \/         \/         \/         \/        \/
    */

    /**
     *
     * @notice Throws if called when presale is not active
     * @param paymentToken the method of payment
     * @param numberOfTokens the number of tokens to buy
     * @param referrer  the referrer address
     */
    function buyTokens(
        IERC20 paymentToken,
        uint256 numberOfTokens,
        address referrer
    ) external payable whenSaleIsActive nonReentrant {
        if (msg.value > 0) {
            require(
                address(paymentToken) == address(0),
                "Cannot have both ETH and BEP-20 payment"
            );

            // Payment is in ETH
            uint256 cost = getCost(paymentToken, numberOfTokens);
            require(msg.value >= cost, "Not enough ETH sent");
            _buyTokens(numberOfTokens, referrer);

            (bool sent, ) = payable(treasury).call{value: cost}("");
            require(sent, "Failed to send ETH");
            uint256 remainder = msg.value - cost;
            if (remainder > 0) {
                (sent, ) = payable(msg.sender).call{value: remainder}("");
                require(sent, "Failed to refund extra ETH");
            }
        } else {
            // Payment is in BEP-20
            uint256 cost = getCost(paymentToken, numberOfTokens);
            require(
                paymentToken.allowance(msg.sender, address(this)) >= cost,
                "Not enough allowance"
            );
            _buyTokens(numberOfTokens, referrer);
            paymentToken.safeTransferFrom(msg.sender, treasury, cost);
        }

        // Emit event
        emit TokensBought(
            msg.sender,
            address(paymentToken),
            numberOfTokens,
            referrer
        );
    }

    function _buyTokens(uint256 numberOfTokens, address referrer) internal {
        tokensBought[msg.sender] += numberOfTokens;
        tokensSold += numberOfTokens;

        // Check if we have to give a bonus to the referrer
        if (referrer != address(0)) {
            require(referrer != msg.sender, "You cannot refer yourself");
            uint256 bonusTokens = (numberOfTokens * 5) / 100;

            tokensBought[referrer] += bonusTokens;
            tokensSold += bonusTokens;
        }
    }

    /**
     * @notice List all supported payment methods
     */
    function listSupportedPaymentMethods()
        external
        view
        returns (address[] memory)
    {
        return supportedPaymentMethods;
    }

    /**
     * @notice Preview the estimated cost of buying a given number of tokens
     * with a given payment method
     * @param paymentToken the method of payment
     * @param numberOfTokens the number of tokens to buy
     */
    function previewCost(
        IERC20 paymentToken,
        uint256 numberOfTokens
    ) external view returns (uint256) {
        return getCost(paymentToken, numberOfTokens);
    }

    /*
        __________________________________________.___ _______    ________  _________
        /   _____/\_   _____/\__    ___/\__    ___/|   |\      \  /  _____/ /   _____/
        \_____  \  |    __)_   |    |     |    |   |   |/   |   \/   \  ___ \_____  \ 
        /        \ |        \  |    |     |    |   |   /    |    \    \_\  \/        \
        /_______  //_______  /  |____|     |____|   |___\____|__  /\______  /_______  /
                \/         \/                                   \/        \/        \/ 
    */

    /**
     *
     * @param _tokenPrice AIRB token price (in USD)
     * @param _treasury treasury address
     */
    constructor(uint256 _tokenPrice, address _treasury) {
        tokenPrice = _tokenPrice;
        treasury = _treasury;

        startTime = block.timestamp;
        endTime = 0;
        tokensSold = 0;
    }

    /**
     * @notice Modifier to check if presale is active
     */
    modifier whenSaleIsActive() {
        require(
            block.timestamp >= startTime && endTime == 0,
            "Presale is not active"
        );
        _;
    }

    /**
     * Calculate the cost of buying a number of tokens (AIRB)
     * @param paymentToken method of payment
     * @param numberOfTokens number of tokens to buy
     */
    function getCost(
        IERC20 paymentToken,
        uint256 numberOfTokens
    ) internal view returns (uint256) {
        AggregatorV3Interface dataFeed = paymentTokenToPriceFeed[
            address(paymentToken)
        ];
        require(address(dataFeed) != address(0), "Invalid data feed");
        require(
            isSupportedPaymentMethod[address(dataFeed)],
            "Unsupported payment method"
        );

        (, int256 answer, , , ) = dataFeed.latestRoundData();
        require(answer > 0, "Answer cannot be <= 0");
        require(dataFeed.decimals() == 8, "Unexpected decimals");
        uint256 price = uint256(answer) * 10 ** 10;

        require(tokenPrice > 0, "Invalid token price");
        uint256 cost = (numberOfTokens * tokenPrice) / price;
        require(cost > 0, "Cost cannot be zero");

        return cost;
    }

    /**
     * @notice Set the current price of the token (in USD terms)
     * @param _tokenPrice new price of the token
     */
    function setTokenPrice(uint256 _tokenPrice) external onlyOwner {
        require(tokenPrice > 0, "Invalid token price");

        tokenPrice = _tokenPrice;
    }

    /**
     * @notice Set a price feed for a given payment method
     * @param paymentToken IERC20 token to set price feed for
     * @param dataFeed  AggregatorV3Interface price feed for the token
     */
    function setPriceFeed(
        address paymentToken,
        AggregatorV3Interface dataFeed
    ) external onlyOwner {
        if (!isSupportedPaymentMethod[address(dataFeed)]) {
            paymentTokenToPriceFeed[paymentToken] = dataFeed;
            supportedPaymentMethods.push(paymentToken);
            isSupportedPaymentMethod[address(dataFeed)] = true;
        }
    }

    /**
     * @notice Unset a price feed for a given payment method
     * @param paymentToken IERC20 token to set price feed for
     * @param dataFeed  AggregatorV3Interface price feed for the token
     */
    function unsetPriceFeed(
        address paymentToken,
        AggregatorV3Interface dataFeed
    ) external onlyOwner {
        isSupportedPaymentMethod[address(dataFeed)] = false;
        paymentTokenToPriceFeed[paymentToken] = AggregatorV3Interface(
            address(0)
        );

        // Create new supported payment method array without the removed payment method
        address[] memory newSupportedPaymentMethods = new address[](
            supportedPaymentMethods.length - 1
        );
        uint256 j = 0;
        for (uint256 i = 0; i < supportedPaymentMethods.length; ++i) {
            if (supportedPaymentMethods[i] != address(dataFeed)) {
                newSupportedPaymentMethods[j] = supportedPaymentMethods[i];
                ++j;
            }
        }
        supportedPaymentMethods = newSupportedPaymentMethods;
    }

    /**
     * @notice End the presale
     */
    function endSale() external onlyOwner {
        require(endTime == 0, "Presale has already ended");

        endTime = block.timestamp;
    }

    /**
     * @notice Transfer ownership of the contract to a new owner after the presale ends
     * @param newOwner new owner of the contract
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        Ownable.transferOwnership(newOwner);
    }

    /**
     * Revert any ETH directly sent to the contract
     */
    receive() external payable {
        revert();
    }
}