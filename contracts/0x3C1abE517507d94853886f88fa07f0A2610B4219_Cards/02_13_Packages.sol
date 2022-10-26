// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

//only set to abstract for set up of project
contract Packages is ERC1155, Ownable, ERC1155Burnable {
    using Strings for uint256;

    address private _recipient;
    bool public saleActive = false;
    bool public whitelistSaleActive = false;

    uint256 public constant ONE_CARD_PACK_ID = 0;
    uint256 public constant FIVE_CARD_PACK_ID = 1;
    uint256 public constant TWENTY_CARD_PACK_ID = 2;

    /// @dev Package price
    mapping(uint256 => uint256) public packagePrice;

    /// @dev Total supply for each token.
    mapping(uint256 => uint256) public totalSupply;

    /// @dev Supply limit for each token.
    mapping(uint256 => uint256) public supplyLimit;

    mapping(address => bool) private whitelist; //mapping of address to card pack
    string private baseUri;

    // @dev Wallet to receive funds from contract
    address payable public payoutWallet;

    constructor(
        string memory baseUri_,
        uint256[3] memory supplyLimit_,
        uint256[3] memory packagePrice_,
        address payable payoutWallet_
    ) payable ERC1155("") {
        baseUri = baseUri_;
        payoutWallet = payoutWallet_;

        supplyLimit[ONE_CARD_PACK_ID] = supplyLimit_[ONE_CARD_PACK_ID];
        supplyLimit[FIVE_CARD_PACK_ID] = supplyLimit_[FIVE_CARD_PACK_ID];
        supplyLimit[TWENTY_CARD_PACK_ID] = supplyLimit_[TWENTY_CARD_PACK_ID];

        packagePrice[ONE_CARD_PACK_ID] = packagePrice_[ONE_CARD_PACK_ID];
        packagePrice[FIVE_CARD_PACK_ID] = packagePrice_[FIVE_CARD_PACK_ID];
        packagePrice[TWENTY_CARD_PACK_ID] = packagePrice_[TWENTY_CARD_PACK_ID];
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseUri = _baseURI;
        emit BaseUriSet(baseUri);
    }

    function setPackagePrices(uint256[3] memory packagePrices)
        public
        onlyOwner
    {
        require(packagePrices.length == 3, "Invalid array length");
        packagePrice[ONE_CARD_PACK_ID] = packagePrices[0];
        packagePrice[FIVE_CARD_PACK_ID] = packagePrices[1];
        packagePrice[TWENTY_CARD_PACK_ID] = packagePrices[2];
        emit PackagePricesSet(packagePrices);
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(totalSupply[_tokenId] > 0, "Token does not exist");
        return string(abi.encodePacked(baseUri, _tokenId.toString()));
    }

    function getNumberOfPackagesAvailable(uint256 cardPackType)
        public
        view
        returns (uint256)
    {
        return supplyLimit[cardPackType] - totalSupply[cardPackType];
    }

    function getTotalSupply() public view returns (uint256[3] memory) {
        return [
            totalSupply[ONE_CARD_PACK_ID],
            totalSupply[FIVE_CARD_PACK_ID],
            totalSupply[TWENTY_CARD_PACK_ID]
        ];
    }

    function getPackagePrices() public view returns (uint256[3] memory) {
        return [
            packagePrice[ONE_CARD_PACK_ID],
            packagePrice[FIVE_CARD_PACK_ID],
            packagePrice[TWENTY_CARD_PACK_ID]
        ];
    }

    function buyCardPacks(uint256[3] memory numberOfCardpacks) public payable {
        require(saleActive, "Sale is not active");
        mintCardPacks(numberOfCardpacks);
    }

    /// @dev Input an array of number of cards to mint for each pack type
    /// [Number of one card packs, Number of five card packs, Number of twenty card packs]

    function whiteListBuy(uint256[3] memory numberOfCardpacks) public payable {
        require(
            whitelistSaleActive || saleActive,
            "Whitelist sale is not active"
        );

        require(whitelist[msg.sender], "Not whitelisted");

        mintCardPacks(numberOfCardpacks);
    }

    function mintCardPacks(uint256[3] memory numberOfCardpacks) internal {
        require(
            (numberOfCardpacks[ONE_CARD_PACK_ID] > 0 ||
                numberOfCardpacks[FIVE_CARD_PACK_ID] > 0 ||
                numberOfCardpacks[TWENTY_CARD_PACK_ID] > 0),
            "You need to buy atleast one card pack"
        );
        require(
            msg.value >=
                ((packagePrice[ONE_CARD_PACK_ID] *
                    numberOfCardpacks[ONE_CARD_PACK_ID]) +
                    (packagePrice[FIVE_CARD_PACK_ID] *
                        numberOfCardpacks[FIVE_CARD_PACK_ID]) +
                    (packagePrice[TWENTY_CARD_PACK_ID] *
                        numberOfCardpacks[TWENTY_CARD_PACK_ID])),
            "Insufficient funds"
        );

        require(
            getNumberOfPackagesAvailable(ONE_CARD_PACK_ID) >=
                numberOfCardpacks[ONE_CARD_PACK_ID] &&
                getNumberOfPackagesAvailable(FIVE_CARD_PACK_ID) >=
                numberOfCardpacks[FIVE_CARD_PACK_ID] &&
                getNumberOfPackagesAvailable(TWENTY_CARD_PACK_ID) >=
                numberOfCardpacks[TWENTY_CARD_PACK_ID],
            "Not enough packages available"
        );

        for (uint256 i = 0; i < 3; i++) {
            if (numberOfCardpacks[i] > 0) {
                _mint(msg.sender, i, numberOfCardpacks[i], "");
                totalSupply[i] += numberOfCardpacks[i];
                emit CardPackMinted(msg.sender, i, numberOfCardpacks[i]);
            }
        }
    }

    function setSaleActive(bool saleActive_) public onlyOwner {
        saleActive = saleActive_;
        emit SaleActive(saleActive_);
    }

    function getSaleActive() public view returns (bool) {
        return saleActive;
    }

    function setWhitelistSaleActive(bool whitelistSaleActive_)
        external
        onlyOwner
    {
        whitelistSaleActive = whitelistSaleActive_;
        emit WhiteListSaleActive(whitelistSaleActive_);
    }

    function getWhitelistSaleActive() public view returns (bool) {
        return whitelistSaleActive;
    }

    function setPayoutWallet(address payable payoutWallet_) public onlyOwner {
        payoutWallet = payoutWallet_;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payoutWallet.transfer(balance);
    }

    function addtoWhiteList(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
        emit AddedToWhiteList(_addresses);
    }

    function removeFromWhiteList(address _address) public onlyOwner {
        whitelist[_address] = false;
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    function burnCardPackages(uint256[3] memory numberOfCardpacks)
        public
        returns (bool)
    {
        // Are there any way of burning someone elses card pack?
        uint256[3] memory cardPackBalances = [
            balanceOf(tx.origin, ONE_CARD_PACK_ID),
            balanceOf(tx.origin, FIVE_CARD_PACK_ID),
            balanceOf(tx.origin, TWENTY_CARD_PACK_ID)
        ];

        for (uint256 cardPackTypeId = 0; cardPackTypeId < 3; cardPackTypeId++) {
            require(
                cardPackBalances[cardPackTypeId] >=
                    numberOfCardpacks[cardPackTypeId],
                "Not enough card packs"
            );

            _burn(tx.origin, cardPackTypeId, numberOfCardpacks[cardPackTypeId]);

            emit CardPackBurned(
                tx.origin,
                numberOfCardpacks[cardPackTypeId],
                cardPackTypeId
            );
        }

        return true;
    }

    function giftCardPackages(
        address[] calldata walletAddressList,
        uint256[] calldata packageTypeId,
        uint256[] calldata numberOfCardpacks
    ) public onlyOwner {
        require(
            walletAddressList.length == packageTypeId.length &&
                walletAddressList.length == numberOfCardpacks.length,
            "Input arrays must be of same length"
        );

        uint256 nOnePacks = 0;
        uint256 nFivePacks = 0;
        uint256 nTwentyPacks = 0;

        for (uint256 i = 0; i < walletAddressList.length; i++) {
            if (packageTypeId[i] == ONE_CARD_PACK_ID) {
                nOnePacks += numberOfCardpacks[i];
            } else if (packageTypeId[i] == FIVE_CARD_PACK_ID) {
                nFivePacks += numberOfCardpacks[i];
            } else if (packageTypeId[i] == TWENTY_CARD_PACK_ID) {
                nTwentyPacks += numberOfCardpacks[i];
            } else {
                revert("Package type ID is not valid");
            }
        }

        require(
            nOnePacks <= getNumberOfPackagesAvailable(ONE_CARD_PACK_ID),
            "Not enough one card packs available"
        );
        require(
            nFivePacks <= getNumberOfPackagesAvailable(FIVE_CARD_PACK_ID),
            "Not enough five card packs available"
        );
        require(
            nTwentyPacks <= getNumberOfPackagesAvailable(TWENTY_CARD_PACK_ID),
            "Not enough twenty card packs available"
        );

        for (uint256 i = 0; i < walletAddressList.length; i++) {
            _mint(
                walletAddressList[i],
                packageTypeId[i],
                numberOfCardpacks[i],
                ""
            );
            totalSupply[packageTypeId[i]] += numberOfCardpacks[i];
            emit CardPackMintedWhitelist(
                walletAddressList[i],
                packageTypeId[i],
                numberOfCardpacks[i]
            );
        }

        emit GiftCardPackages(
            walletAddressList,
            packageTypeId,
            numberOfCardpacks
        );
    }

    event CardPackMinted(
        address indexed _address,
        uint256 cardPackType,
        uint256 amount
    );

    event CardPackMintedWhitelist(
        address indexed _address,
        uint256 cardPackType,
        uint256 amount
    );
    event GiftCardPackages(
        address[] indexed _address,
        uint256[] cardPackType,
        uint256[] numberOfPacks
    );

    event BaseUriSet(string baseUri);
    event SaleActive(bool saleActive_);
    event WhiteListSaleActive(bool whiteListSaleActive);
    event Withdraw(address address_);
    event AddedToWhiteList(address[] indexed _address);
    event CardPackBurned(
        address indexed _address,
        uint256 numberOfCardPacks,
        uint256 cardPackType
    );
    event PackagePricesSet(uint256[3] packagePrices_);
}