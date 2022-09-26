// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./AggregatorV3Interface.sol";
import "./PokerC.sol";
import "forge-std/console.sol";

error IncorrectChainId();
error ExceedMaxSupply(uint256 allowAmount);
error ExceedRoundSupply(uint256 allowAmount);
error PriceNotEnough(uint256 price);

contract PokerP is ERC20, ERC20Burnable, Ownable {
    event Mint(address user, uint256 amount);

    AggregatorV3Interface bnbusdPriceFeed;
    uint256 public maxSupply;
    uint256 public currentUsdPrice;

    address private payoutAddress;
    address private feeAddress;

    uint8 public tokenDecimal = 8;
    uint8 public feePercentage = 1;
    uint8 public roundIndex = 0;
    uint8[] public roundPercentages;

    PokerC tokenC;
    mapping(address => bool) public adminMapping;

    constructor(address _payoutAddress, address _feeAddress)
        ERC20("Poker.P", "POKERP")
    {
        if (block.chainid != 56) revert IncorrectChainId();

        /**
         * Network: BSC
         * Aggregator: BNB/USD
         * Address: 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
         */
        bnbusdPriceFeed = AggregatorV3Interface(
            0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
        );
        payoutAddress = _payoutAddress;
        feeAddress = _feeAddress;

        maxSupply = 777_777_777 * (10**tokenDecimal);
        currentUsdPrice = (1 * (10**tokenDecimal)) / 100;
        roundPercentages = [7, 20, 60];
    }

    modifier onlyAdmin() {
        if (msg.sender != tx.origin) revert NonUser();
        if (!adminMapping[msg.sender] && msg.sender != owner())
            revert PermissionDenied();
        _;
    }

    function decimals() public view virtual override returns (uint8) {
        return tokenDecimal;
    }

    function mint(uint256 mintAmount) external payable {
        if (msg.sender != tx.origin) revert NonUser();
        if (mintAmount == 0) revert NonZeroAmount();

        uint256 expectSupply = mintAmount + totalSupply();
        uint256 roundSupply = (maxSupply * roundPercentages[roundIndex]) / 100;
        if (expectSupply > roundSupply)
            revert ExceedRoundSupply(roundSupply - totalSupply());
        if (expectSupply > maxSupply)
            revert ExceedMaxSupply(maxSupply - totalSupply());

        (uint256 mintPrice, uint256 usdPrice) = getMintPrice(mintAmount);
        if (msg.value < mintPrice) revert PriceNotEnough(mintPrice);

        tokenC.redeem(usdPrice, msg.sender);

        uint256 feeAmount = (msg.value * feePercentage) / 100;
        uint256 receiveAmount = msg.value - feeAmount;

        (bool feeSent, ) = feeAddress.call{value: feeAmount}("");
        (bool payoutSent, ) = payoutAddress.call{value: receiveAmount}("");
        if (!feeSent || !payoutSent) revert SendFundFail();

        _mint(msg.sender, mintAmount);
        emit Mint(msg.sender, mintAmount);
    }

    function getMintPrice(uint256 mintAmount)
        public
        view
        returns (uint256 _bnbPrice, uint256 _usdPrice)
    {
        // currentUsdPrice = 0.01 usd = 0.01 * 10^8
        // bnbUsdPrice = usd price / 10^8
        // bnb price = bnb price / 10^18
        // mintAmount = amount * 10^8
        // msg.value = currentUsdPrice / bnbUsdPrice * 10^(18 - 8) * (amount * 10^8)
        // usd price = currentUsdPrice * mintAmount / 10^8

        (, int256 bnbUsdPrice, , , ) = bnbusdPriceFeed.latestRoundData();

        uint256 usdPrice = (currentUsdPrice * mintAmount) / (10**decimals());
        uint256 bnbPrice = (usdPrice * (10**18)) / uint256(bnbUsdPrice);
        return (bnbPrice, usdPrice);
    }

    function issue(uint256 amount) public onlyAdmin {
        if (amount == 0) revert NonZeroAmount();

        if (amount + totalSupply() > maxSupply) {
            maxSupply = amount + totalSupply();
        }

        _mint(payoutAddress, amount);
        emit Mint(payoutAddress, amount);
    }

    function setUsdPrice(uint256 newUsdPrice) external onlyAdmin {
        currentUsdPrice = newUsdPrice;
    }

    function addAdmin(address adminAddress) external onlyOwner {
        adminMapping[adminAddress] = true;
    }

    function removeAdmin(address adminAddress) external onlyOwner {
        adminMapping[adminAddress] = false;
    }

    function setPokerC(address tokenCAddress) external onlyOwner {
        tokenC = PokerC(tokenCAddress);
    }

    function setRoundPercentage(uint8 _roundIndex, uint8 _newPercentage)
        external
        onlyAdmin
    {
        if (_roundIndex >= roundPercentages.length) {
            roundPercentages.push(_newPercentage);
        } else {
            roundPercentages[_roundIndex] = _newPercentage;
        }
    }

    function setRoundIndex(uint8 _roundIndex) external onlyAdmin {
        roundIndex = _roundIndex;
    }
}