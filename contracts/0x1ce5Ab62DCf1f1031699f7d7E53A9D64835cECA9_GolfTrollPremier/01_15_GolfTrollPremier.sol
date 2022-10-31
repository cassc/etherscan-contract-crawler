// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

error GolfTrollPremier_TransferFailed();

contract GolfTrollPremier is ERC721, ReentrancyGuard, Pausable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    uint256 private _premiumMintPriceEth;
    uint256 private _baseMintPriceEth;
    uint256 private _whiteListDiscountEth;
    uint256 private _ambassadorAllowListDiscountEth;
    uint256 private immutable i_premiumMaxSupply;
    uint256 private immutable i_baseMaxSupply;
    string private baseURI;
    bool private isSaleActive = false;
    bool private isWhitelistSaleActive = false;
    bool private isAmbassadorCodeActive = false;
    bool private isAllowListSaleActive = false;
    Counters.Counter s_baseTokenCounter;
    Counters.Counter s_premiumTokenCounter;

    mapping(string => bool) private ambassadorCodeToIsCodeValid;
    mapping(string => bool) private ambassadorCodeToIsDiscount;
    mapping(address => bool) private addressToIsWhitelist;
    mapping(address => bool) private addressToIsAllowList;

    //struct code use and array only store when valid code is used Address, code, TrollType, TrollCount
    struct ambassadorCodeLog {
        address newTrollHome;
        string ambassadorCode;
        bool isPremier;
        uint256 trollCount;
    }

    ambassadorCodeLog[] private ambassadorCodeLogs;

    //"Golf Troll 777", "GT777"
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        string memory customBaseURI,
        uint256 premiumMintPriceEth,
        uint256 baseMintPriceEth,
        uint256 whiteListDiscountEth,
        uint256 ambassadorAllowListDiscountEth,
        uint256 premiumMaxSupply,
        uint256 baseMaxSupply
    ) ERC721(tokenName, tokenSymbol) {
        baseURI = customBaseURI;
        _premiumMintPriceEth = premiumMintPriceEth;
        _baseMintPriceEth = baseMintPriceEth;
        _whiteListDiscountEth = whiteListDiscountEth;
        _ambassadorAllowListDiscountEth = ambassadorAllowListDiscountEth;
        i_premiumMaxSupply = premiumMaxSupply;
        i_baseMaxSupply = baseMaxSupply;
    }

    //need only owner version
    //0 through 221
    function mintPremiumNFT(
        uint256 trollsRequested,
        address newTrollHome,
        string memory ambassadorCode
    ) public payable nonReentrant whenNotPaused {
        require(isSaleActive, "Troll Sales Closed");
        if (isWhitelistSaleActive) {
            require(
                addressToIsWhitelist[newTrollHome],
                "Address is not on whitelist"
            );
        }
        if (isAmbassadorCodeActive || isAllowListSaleActive) {
            require(
                ambassadorCodeToIsCodeValid[ambassadorCode] ||
                    addressToIsAllowList[newTrollHome],
                "Invalid Ambassador Code or Address is not on allow list"
            );
        }
        require(
            s_premiumTokenCounter.current().add(trollsRequested) <
                i_premiumMaxSupply,
            "Exceeds max supply"
        );
        require(
            msg.value >=
                getPremiumMintPrice(
                    trollsRequested,
                    newTrollHome,
                    ambassadorCode
                ),
            "Insufficient payment"
        );

        for (uint256 i = 0; i < trollsRequested; i++) {
            _safeMint(newTrollHome, s_premiumTokenCounter.current());
            s_premiumTokenCounter.increment();
        }

        if (ambassadorCodeToIsCodeValid[ambassadorCode]) {
            ambassadorCodeLogs.push(
                ambassadorCodeLog(
                    newTrollHome,
                    ambassadorCode,
                    true,
                    trollsRequested
                )
            );
        }
    }

    function airdropPremiumNFT(uint256 trollsRequested, address newTrollHome)
        public
        nonReentrant
        onlyOwner
        whenNotPaused
    {
        require(
            s_premiumTokenCounter.current().add(trollsRequested) <
                i_premiumMaxSupply,
            "Exceeds max supply"
        );

        for (uint256 i = 0; i < trollsRequested; i++) {
            _safeMint(newTrollHome, s_premiumTokenCounter.current());
            s_premiumTokenCounter.increment();
        }
    }

    //222-776
    function mintBaseNFT(
        uint256 trollsRequested,
        address newTrollHome,
        string memory ambassadorCode
    ) public payable nonReentrant whenNotPaused {
        require(isSaleActive, "Troll Sales Closed");
        if (isWhitelistSaleActive) {
            require(
                addressToIsWhitelist[newTrollHome],
                "Address is not on whitelist"
            );
        }
        if (isAmbassadorCodeActive || isAllowListSaleActive) {
            require(
                ambassadorCodeToIsCodeValid[ambassadorCode] ||
                    addressToIsAllowList[newTrollHome],
                "Invalid Ambassador Code or Address is not on allow list"
            );
        }

        require(
            s_baseTokenCounter.current().add(trollsRequested) < i_baseMaxSupply,
            "Exceeds max supply"
        );
        require(
            msg.value >=
                getBaseMintPrice(trollsRequested, newTrollHome, ambassadorCode),
            "Insufficient payment"
        );

        for (uint256 i = 0; i < trollsRequested; i++) {
            _safeMint(
                newTrollHome,
                s_baseTokenCounter.current().add(i_premiumMaxSupply)
            );
            s_baseTokenCounter.increment();
        }

        if (ambassadorCodeToIsCodeValid[ambassadorCode]) {
            ambassadorCodeLogs.push(
                ambassadorCodeLog(
                    newTrollHome,
                    ambassadorCode,
                    false,
                    trollsRequested
                )
            );
        }
    }

    function airdropBaseNFT(uint256 trollsRequested, address newTrollHome)
        public
        nonReentrant
        onlyOwner
        whenNotPaused
    {
        require(
            s_baseTokenCounter.current().add(trollsRequested) < i_baseMaxSupply,
            "Exceeds max supply"
        );

        for (uint256 i = 0; i < trollsRequested; i++) {
            _safeMint(
                newTrollHome,
                s_baseTokenCounter.current().add(i_premiumMaxSupply)
            );
            s_baseTokenCounter.increment();
        }
    }

    function setBaseURI(string memory customBaseURI) public onlyOwner {
        baseURI = customBaseURI;
    }

    function setTrollPricesEth(
        uint256 newPremiumPriceEth,
        uint256 newBasePriceEth
    ) public onlyOwner {
        _premiumMintPriceEth = newPremiumPriceEth;
        _baseMintPriceEth = newBasePriceEth;
    }

    function setTrollDiscounts(
        uint256 newWhiteListDiscountEth,
        uint256 newAmbassadorDiscountEth
    ) public onlyOwner {
        _whiteListDiscountEth = newWhiteListDiscountEth;
        _ambassadorAllowListDiscountEth = newAmbassadorDiscountEth;
    }

    function toggleIsSaleActive() public onlyOwner returns (bool) {
        if (isSaleActive) {
            isSaleActive = false;
        } else {
            isSaleActive = true;
        }

        return isSaleActive;
    }

    function toggleIsWhitelistSaleActive() public onlyOwner returns (bool) {
        if (isWhitelistSaleActive) {
            isWhitelistSaleActive = false;
        } else {
            isWhitelistSaleActive = true;
        }

        return isWhitelistSaleActive;
    }

    function toggleIsAmbassadorCodeSaleActive()
        public
        onlyOwner
        returns (bool)
    {
        if (isAmbassadorCodeActive) {
            isAmbassadorCodeActive = false;
        } else {
            isAmbassadorCodeActive = true;
        }

        return isAmbassadorCodeActive;
    }

    function toggleIsAllowListSaleActive() public onlyOwner returns (bool) {
        if (isAllowListSaleActive) {
            isAllowListSaleActive = false;
        } else {
            isAllowListSaleActive = true;
        }

        return isAllowListSaleActive;
    }

    function togglePause() public onlyOwner returns (bool) {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }

        return paused();
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert GolfTrollPremier_TransferFailed();
        }
    }

    function setWhitelistAddresses(address[] memory newAddresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < newAddresses.length; i++) {
            addressToIsWhitelist[newAddresses[i]] = true;
        }
    }

    function removeWhitelistAddresses(address[] memory removeAddresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < removeAddresses.length; i++) {
            addressToIsWhitelist[removeAddresses[i]] = false;
        }
    }

    function setAllowListAddresses(address[] memory newAddresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < newAddresses.length; i++) {
            addressToIsAllowList[newAddresses[i]] = true;
        }
    }

    function removeAllowListAddresses(address[] memory removeAddresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < removeAddresses.length; i++) {
            addressToIsAllowList[removeAddresses[i]] = false;
        }
    }

    function setAmbassadorGiftCodes(string[] memory ambassadorCodes)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < ambassadorCodes.length; i++) {
            ambassadorCodeToIsCodeValid[ambassadorCodes[i]] = true;
        }
    }

    function removeAmbassadorGiftCodes(string[] memory ambassadorCodes)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < ambassadorCodes.length; i++) {
            ambassadorCodeToIsCodeValid[ambassadorCodes[i]] = false;
        }
    }

    function setAmbassadorDiscountCodes(string[] memory ambassadorCodes)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < ambassadorCodes.length; i++) {
            ambassadorCodeToIsCodeValid[ambassadorCodes[i]] = true;
            ambassadorCodeToIsDiscount[ambassadorCodes[i]] = true;
        }
    }

    function removeAmbassadorDiscountCodes(string[] memory ambassadorCodes)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < ambassadorCodes.length; i++) {
            ambassadorCodeToIsCodeValid[ambassadorCodes[i]] = false;
            ambassadorCodeToIsDiscount[ambassadorCodes[i]] = false;
        }
    }

    function getIsSaleActive() public view returns (bool) {
        if (paused()) {
            return false;
        } else {
            return isSaleActive;
        }
    }

    function getIsWhitelistSaleActive() public view returns (bool) {
        if (paused()) {
            return false;
        } else {
            return isWhitelistSaleActive;
        }
    }

    function getIsAmbassadorCodeSaleActive() public view returns (bool) {
        if (paused()) {
            return false;
        } else {
            return isAmbassadorCodeActive;
        }
    }

    function getIsAllowListSaleActive() public view returns (bool) {
        if (paused()) {
            return false;
        } else {
            return isAllowListSaleActive;
        }
    }

    function getTokenCounter() public view returns (uint256) {
        return
            s_baseTokenCounter.current().add(s_premiumTokenCounter.current());
    }

    function getPremiumTokenCounter() public view returns (uint256) {
        return s_premiumTokenCounter.current();
    }

    function getBaseTokenCounter() public view returns (uint256) {
        return s_baseTokenCounter.current();
    }

    function getPremiumMintPrice(
        uint256 trollsRequested,
        address newTrollHome,
        string memory promoCode
    ) public view returns (uint256) {
        require(trollsRequested > 0, "Zero Trolls Requested");
        uint256 trollPrice = _premiumMintPriceEth;
        uint256 ownedTrolls = balanceOf(newTrollHome);
        trollsRequested = trollsRequested.sub(1);

        if (isWhitelistSaleActive && ownedTrolls == 0) {
            trollPrice = trollPrice.sub(_whiteListDiscountEth);
            trollPrice = trollPrice.add(
                _premiumMintPriceEth.mul(trollsRequested)
            );
        } else if (
            isAmbassadorCodeActive &&
            ambassadorCodeToIsDiscount[promoCode] &&
            ownedTrolls == 0
        ) {
            trollPrice = trollPrice.sub(_ambassadorAllowListDiscountEth);
            trollPrice = trollPrice.add(
                _premiumMintPriceEth.mul(trollsRequested)
            );
        } else if (
            isAllowListSaleActive &&
            addressToIsAllowList[newTrollHome] &&
            ownedTrolls == 0
        ) {
            trollPrice = trollPrice.sub(_ambassadorAllowListDiscountEth);
            trollPrice = trollPrice.add(
                _premiumMintPriceEth.mul(trollsRequested)
            );
        } else {
            trollPrice = trollPrice.add(
                _premiumMintPriceEth.mul(trollsRequested)
            );
        }

        return trollPrice;
    }

    function getBaseMintPrice(
        uint256 trollsRequested,
        address newTrollHome,
        string memory promoCode
    ) public view returns (uint256) {
        require(trollsRequested > 0, "Zero Trolls Requested");
        uint256 trollPrice = _baseMintPriceEth;
        uint256 ownedTrolls = balanceOf(newTrollHome);
        trollsRequested = trollsRequested.sub(1);

        if (isWhitelistSaleActive && ownedTrolls == 0) {
            trollPrice = trollPrice.sub(_whiteListDiscountEth);
            trollPrice = trollPrice.add(_baseMintPriceEth.mul(trollsRequested));
        } else if (
            isAmbassadorCodeActive &&
            ambassadorCodeToIsDiscount[promoCode] &&
            ownedTrolls == 0
        ) {
            trollPrice = trollPrice.sub(_ambassadorAllowListDiscountEth);
            trollPrice = trollPrice.add(_baseMintPriceEth.mul(trollsRequested));
        } else if (
            isAllowListSaleActive &&
            addressToIsAllowList[newTrollHome] &&
            ownedTrolls == 0
        ) {
            trollPrice = trollPrice.sub(_ambassadorAllowListDiscountEth);
            trollPrice = trollPrice.add(_baseMintPriceEth.mul(trollsRequested));
        } else {
            trollPrice = trollPrice.add(_baseMintPriceEth.mul(trollsRequested));
        }

        return trollPrice;
    }

    function isAmbassadorCodeValid(string memory ambassadorCode)
        public
        view
        returns (bool)
    {
        return ambassadorCodeToIsCodeValid[ambassadorCode];
    }

    function isAmbassadorCodeDiscount(string memory ambassadorCode)
        public
        view
        returns (bool)
    {
        return ambassadorCodeToIsDiscount[ambassadorCode];
    }

    function isAddressWhiteListed(address toCheck) public view returns (bool) {
        return addressToIsWhitelist[toCheck];
    }

    function isAddressAllowListed(address toCheck) public view returns (bool) {
        return addressToIsAllowList[toCheck];
    }

    function isAddressTokenOwner(address potentialOwner, uint256 tokenId)
        public
        view
        returns (bool)
    {
        bool isTokenOwner = false;

        if (ownerOf(tokenId) == potentialOwner) {
            isTokenOwner = true;
        }

        return isTokenOwner;
    }

    function getMaxSupply() public view returns (uint256) {
        return i_baseMaxSupply.add(i_premiumMaxSupply);
    }

    function getRemainingBaseSupply() public view returns (uint256) {
        return i_baseMaxSupply.sub(s_baseTokenCounter.current());
    }

    function getRemainingPremiumSupply() public view returns (uint256) {
        return i_premiumMaxSupply.sub(s_premiumTokenCounter.current());
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function getAmbassadorCodeLogs()
        public
        view
        onlyOwner
        returns (ambassadorCodeLog[] memory)
    {
        return ambassadorCodeLogs;
    }
}