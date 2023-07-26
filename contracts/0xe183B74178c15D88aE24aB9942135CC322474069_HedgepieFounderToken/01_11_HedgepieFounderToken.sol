// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract HedgepieFounderToken is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct PayTokenInfo {
        address chainlinkPriceFeed; // address of chainlink price feed
        bool status; // listed status
    }

    // max supply
    uint256 public maxSupply = 5_000_000 ether; // 5 million

    // HPFT sale price in usd with 8 decimal
    uint256 public salePrice = 50_000_000; // $0.5

    // treasury address
    address public treasury;

    // payToken => PayTokenInfo
    mapping(address => PayTokenInfo) public payTokenList;

    event Purchased(address indexed buyer, uint256 amount, address payToken);

    /**
     * @notice Constructor
     * @param _treasury  address of treasury
     */
    constructor(address _treasury) ERC20("Hedgepie Founder Token", "HPFT") {
        require(_treasury != address(0), "Error: zero address");
        treasury = _treasury;
    }

    /**
     * @notice Add pay token to list by owner
     * @param _payToken address of pay token
     * @param _chainLinkPriceFeed address of chainlink price feed of pay token
     */
    function addPayToken(address _payToken, address _chainLinkPriceFeed) public onlyOwner {
        require(_chainLinkPriceFeed != address(0), "Error: zero address");
        payTokenList[_payToken] = PayTokenInfo({chainlinkPriceFeed: _chainLinkPriceFeed, status: true});
    }

    /**
     * @notice Remaining amount of Hedgepie founder token can be purchased
     */
    function availableCanPurchase() public view returns (uint256) {
        if (maxSupply >= totalSupply()) return maxSupply - totalSupply();
        return 0;
    }

    /**
     * @notice Get amount of pay token to purchase HPFT
     * @param _amount  amount of HPFT to purchase
     * @param _payToken address of pay token
     */
    function getPayTokenAmountFromSaleToken(uint256 _amount, address _payToken) public view returns (uint256) {
        PayTokenInfo memory payToken = payTokenList[_payToken];
        if (payToken.chainlinkPriceFeed != address(0)) {
            (, int payTokenPrice, , , ) = AggregatorV3Interface(payToken.chainlinkPriceFeed).latestRoundData();
            uint8 payTokenDecimal = _payToken == address(0) ? 18 : IERC20Metadata(_payToken).decimals();

            return ((10 ** payTokenDecimal) * (_amount * salePrice)) / uint256(payTokenPrice) / 1e18;
        }
        return 0;
    }

    /**
     * @notice Get amount of HPFT token from pay token
     * @param _amount  amount of pay token
     * @param _payToken address of pay token
     */
    function getSaleTokenAmountFromPayToken(uint256 _amount, address _payToken) public view returns (uint256) {
        PayTokenInfo memory payToken = payTokenList[_payToken];
        if (payToken.chainlinkPriceFeed != address(0)) {
            (, int payTokenPrice, , , ) = AggregatorV3Interface(payToken.chainlinkPriceFeed).latestRoundData();
            uint8 payTokenDecimal = _payToken == address(0) ? 18 : IERC20Metadata(_payToken).decimals();

            return (1e18 * _amount * uint256(payTokenPrice)) / salePrice / (10 ** payTokenDecimal);
        }
        return 0;
    }

    /**
     * @notice Purchase token
     * @param _amount  amount of HPFT to purchase
     * @param _payToken address of pay token
     */
    function purchase(uint256 _amount, address _payToken) public payable nonReentrant {
        require(payTokenList[_payToken].status, "Error: not listed token");
        require(availableCanPurchase() >= _amount, "Error: insufficient sale token");

        // get pay token amount
        uint256 payTokenAmount = getPayTokenAmountFromSaleToken(_amount, _payToken);

        // transfer pay token from sender to treasury
        if (_payToken == address(0)) {
            require(msg.value >= payTokenAmount, "Error: insufficient BNB");
            (bool success, ) = payable(treasury).call{value: msg.value}("");
            require(success, "Error: treasury transfer");
        } else {
            IERC20(_payToken).safeTransferFrom(msg.sender, treasury, payTokenAmount);
        }

        // mint token to sender
        _mint(msg.sender, _amount);

        // emit event
        emit Purchased(msg.sender, _amount, _payToken);
    }

    receive() external payable {}
}