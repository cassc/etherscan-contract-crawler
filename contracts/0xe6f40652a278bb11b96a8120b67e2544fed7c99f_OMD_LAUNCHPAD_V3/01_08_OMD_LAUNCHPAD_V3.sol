// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

interface IERC20Burnable {
    function burn(uint256 amount) external returns (bool);

    function burnFrom(address account, uint256 amount) external returns (bool);
}

interface IERC20Decimals {
    function decimals() external returns (uint8);
}

contract OMD_LAUNCHPAD_V3 is
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable
{
    bytes32[] private whitelistedSymbols;
    mapping(bytes32 => address) private whitelistedTokens;
    mapping(bytes32 => mapping(uint8 => uint256)) private priceTokens;

    mapping(bytes32 => bytes32) private swapPairs;
    mapping(bytes32 => address) private swapTokens;
    mapping(bytes32 => mapping(bytes32 => uint256)) private swapTokensPrice;

    bytes32[] private referalInflCodes;
    mapping(bytes32 => mapping(bytes32 => uint256)) private inflTokenSize;
    mapping(bytes32 => uint16) private inflReflPercent;
    mapping(bytes32 => address) private inflAddress;
    address private addrSafe;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    mapping(bytes32 => mapping(address => uint256)) private swapTokensUnlocked;

    function initialize() public initializer {
        swapTokens[bytes32("OMD")] = address(
            0xA4282798c2199a1C58843088297265acD748168c
        );
        swapTokens[bytes32("stOMD")] = address(
            0x497bdbA917430E72d09993a55cdBBD411763168B
        );
        __Context_init();
        __Ownable_init();
    }

    function getReferalCodes() external view returns (bytes32[] memory) {
        return referalInflCodes;
    }

    function getInflTokenSize(
        bytes32 referalCode,
        bytes32 symbol
    ) external view returns (uint256) {
        return inflTokenSize[referalCode][symbol];
    }

    function getInflFee(bytes32 referalCode) external view returns (uint16) {
        return inflReflPercent[referalCode];
    }

    function getInflAdr(bytes32 referalCode) external view returns (address) {
        return inflAddress[referalCode];
    }

    function getWhitelistedSymbols() external view returns (bytes32[] memory) {
        return whitelistedSymbols;
    }

    function getWhitelistedTokenAddress(
        bytes32 symbol
    ) external view returns (address) {
        return whitelistedTokens[symbol];
    }

    function getTierTokenPrice(
        bytes32 symbol,
        uint8 tier
    ) external view returns (uint256) {
        return priceTokens[symbol][tier];
    }

    function stringSymbolToByte32(
        string memory symbol
    ) public pure returns (bytes32) {
        return bytes32(bytes(symbol));
    }

    function byte32SymbolToString(
        bytes32 symbol
    ) public pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && symbol[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && symbol[i] != 0; i++) {
            bytesArray[i] = symbol[i];
        }
        return string(bytesArray);
    }

    function getSwapTokenAddress(
        bytes32 symbol
    ) external view returns (address) {
        return swapTokens[symbol];
    }

    function getSwapPair(bytes32 symbol) external view returns (bytes32) {
        return swapPairs[symbol];
    }

    function getSwapTokensUnlocked(
        bytes32 symbol,
        address account
    ) public view returns (uint256) {
        return swapTokensUnlocked[symbol][account];
    }

    function setWhitelistToken(
        bytes32 symbol,
        address tokenAddress,
        uint256 basePrice
    ) external onlyOwner {
        whitelistedSymbols.push(symbol);
        whitelistedTokens[symbol] = tokenAddress;
        priceTokens[symbol][0] = basePrice;
    }

    function setSwaplistToken(
        bytes32 symbolFrom,
        bytes32 symbolTo,
        uint256 price
    ) external onlyOwner {
        swapPairs[symbolFrom] = symbolTo;
        swapTokensPrice[symbolFrom][symbolTo] = price;
    }

    function setTierTokenPrice(
        bytes32 symbol,
        uint8 tier,
        uint256 price
    ) external onlyOwner {
        priceTokens[symbol][tier] = price;
    }

    function setSwapTokenAddress(
        bytes32 symbol,
        address addrToken
    ) external onlyOwner {
        require(addrToken != address(0), "ERC20: contract is the zero address");
        swapTokens[symbol] = addrToken;
    }

    function setSwapTokensUnlocked(
        bytes32 symbol,
        address[] memory arr_address,
        uint256[] memory unlockedAmount
    ) external onlyOwner {
        for (uint i = 0; i < arr_address.length; i++) {
            swapTokensUnlocked[symbol][arr_address[i]] = unlockedAmount[i];
        }
    }

    function setAddressSafe(address _addrSafe) external onlyOwner {
        addrSafe = _addrSafe;
    }

    // percent 1000 = 100% ; 1 = 0.001%
    function setReferalCode(
        bytes32 referalCode,
        uint16 percent,
        address addrInfl
    ) external onlyOwner {
        referalInflCodes.push(referalCode);
        inflReflPercent[referalCode] = percent;
        inflAddress[referalCode] = addrInfl;
    }

    function myPrice(
        address account,
        bytes32 symbol
    ) public view returns (uint256) {
        IERC20Upgradeable stOmd = IERC20Upgradeable(
            swapTokens[bytes32("stOMD")]
        );
        uint256 stake = stOmd.balanceOf(account);
        uint256 price = priceTokens[symbol][0];
        if (stake >= 100 && stake < 1000) price = priceTokens[symbol][1];
        if (stake >= 1000 && stake < 50000) price = priceTokens[symbol][2];
        if (stake >= 50000) price = priceTokens[symbol][3];
        if (price == 0) price = priceTokens[symbol][0];
        return price;
    }

    function mySwapPrice(bytes32 symbolFrom) public view returns (uint256) {
        return swapTokensPrice[symbolFrom][swapPairs[symbolFrom]];
    }

    // default referalCode byte32("base") 0x6261736500000000000000000000000000000000000000000000000000000000
    function buyToken(
        bytes32 symbol,
        uint256 _amount,
        bytes32 referalCode
    ) external {
        require(
            _amount >= 1 * 10 ** 6,
            "Amount must be greater than or equal to 1 OMD."
        );
        IERC20Upgradeable omd = IERC20Upgradeable(swapTokens[bytes32("OMD")]);
        if (addrSafe == address(0)) addrSafe = owner();
        uint256 ourAllowance = omd.allowance(_msgSender(), address(this));
        require(_amount <= ourAllowance, "Make sure to add enough allowance");
        uint256 safeAmount = _amount;
        if (referalCode != bytes32("base")) {
            if (inflAddress[referalCode] != address(0)) {
                require(
                    inflReflPercent[referalCode] > 0,
                    "inflReflPercent[referalCode] must be greater than 0"
                );
                uint256 refAmount = (_amount * inflReflPercent[referalCode]) /
                    1000;
                omd.transferFrom(
                    _msgSender(),
                    inflAddress[referalCode],
                    refAmount
                );
                safeAmount -= refAmount;
            }
            inflTokenSize[referalCode][symbol] += _amount;
        }
        bool success1 = omd.transferFrom(_msgSender(), addrSafe, safeAmount);
        require(
            success1,
            "Transfer failed! Please approve amount OMD for this contract."
        );
        IERC20Upgradeable launchToken = IERC20Upgradeable(
            whitelistedTokens[symbol]
        );
        uint256 price = myPrice(_msgSender(), symbol);
        uint256 amount = (_amount * 10 ** 6) / price;
        require(
            launchToken.balanceOf(address(this)) >= amount,
            "There are not so many tokens for sale."
        );
        bool success2 = launchToken.transfer(_msgSender(), amount);
        require(success2, "Transfer failed! No more tokens for sale.");
        address sender = _msgSender();
        string memory strSymbol = byte32SymbolToString(symbol);
        string memory strReferalCode = byte32SymbolToString(referalCode);
        emit BuyTokenRef(
            sender,
            _amount,
            strSymbol,
            price,
            strReferalCode,
            referalCode
        );
    }

    function swapToken(bytes32 symbolFrom, uint256 _amount) external {
        require(
            _amount >= 1 * 10 ** 6,
            "Amount must be greater than or equal to 1 token."
        );
        bytes32 symbolTo = swapPairs[symbolFrom];
        require(
            _amount <= getSwapTokensUnlocked(symbolTo, _msgSender()),
            "Amount must be less than or equal to swapTokensUnlocked value."
        );
        IERC20Burnable tokenFrom = IERC20Burnable(
            whitelistedTokens[symbolFrom]
        );
        bool success1 = tokenFrom.burnFrom(_msgSender(), _amount);
        require(
            success1,
            "Transfer failed! Please approve amount tokenFrom for this contract."
        );
        IERC20Upgradeable tokenTo = IERC20Upgradeable(swapTokens[symbolTo]);
        IERC20Decimals tokenToDecimals = IERC20Decimals(swapTokens[symbolTo]);
        uint8 tokenToDecimal = tokenToDecimals.decimals();
        uint256 amount = (((_amount * mySwapPrice(symbolFrom)) / 10 ** 6) *
            10 ** tokenToDecimal) / 10 ** 6;
        tokenTo.safeTransfer(_msgSender(), amount);
    }

    function withdrawToken(
        address _tokenContract,
        uint256 _amount
    ) external onlyOwner {
        require(
            _tokenContract != address(0),
            "ERC20: contract is the zero address"
        );
        IERC20Upgradeable tokenContract = IERC20Upgradeable(_tokenContract);
        tokenContract.safeTransfer(_msgSender(), _amount);
    }

    event BuyTokenRef(
        address indexed to,
        uint256 amount,
        string symbol,
        uint256 price,
        string referalCode,
        bytes32 indexed refCode
    );
}