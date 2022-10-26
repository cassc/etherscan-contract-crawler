// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./Packages.sol";

contract Cards is IERC1155MetadataURI, Ownable, ERC1155Burnable {
    using Strings for uint256;

    address private _recipient;

    /// @dev Addess of the package contract
    Packages packages;

    /// @dev Token pack IDs
    uint256 public constant ONE_CARD_PACK_ID = 0;
    uint256 public constant FIVE_CARD_PACK_ID = 1;
    uint256 public constant TWENTY_CARD_PACK_ID = 2;

    /// @dev supplyLimit.
    mapping(uint256 => uint256) public supplyLimit;

    /// @dev Total supply for each token.
    mapping(uint256 => uint256) public totalSupply;

    /// @dev Number of unique cards in existence.
    uint256 public numberOfUniqueCards;

    /// @dev Total number of minted cards.
    uint256 public totalNumberOfMintedCards;

    /// @dev Total supply of cards
    uint256 public totalSupplyOfCards;

    /// @dev Union worker token ID
    uint256 UNION_WORKER_CARD_ID = 26;
    uint256 UNION_CARD_SUPPLY_LIMIT = 25;

    // @dev Wallet to receive funds from contract
    address payable public payoutWallet;

    string private baseUri;

    bool public openPackageActive;

    constructor(
        address _packages,
        uint256[] memory _supplyLimit,
        address payable payoutWallet_,
        string memory baseUri_
    ) ERC1155("") {
        packages = Packages(_packages);

        payoutWallet = payoutWallet_;
        baseUri = baseUri_;

        uint256 _totalSupplyOfCards = 0;
        for (uint256 i = 0; i < _supplyLimit.length; i++) {
            supplyLimit[i] = _supplyLimit[i];
            _totalSupplyOfCards += _supplyLimit[i];
        }

        totalSupplyOfCards = _totalSupplyOfCards;

        numberOfUniqueCards = uint256(_supplyLimit.length);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseUri = _baseURI;
        emit SetBaseUri(baseUri);
    }

    function setOpenPackageActive(bool _openPackageActive) public onlyOwner {
        openPackageActive = _openPackageActive;
        emit SetOpenPackageActive(openPackageActive);
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(totalSupply[_tokenId] > 0, "Token does not exist");
        return string(abi.encodePacked(baseUri, _tokenId.toString()));
    }

    function openCardPackages(uint256[3] memory numberOfCardpacks) external {
        require(openPackageActive, "Open package is not active");
        require(msg.sender == tx.origin, "Contracts cannot call this function");

        // Burn msg.sender's packages
        require(
            packages.burnCardPackages(numberOfCardpacks),
            "Failed to burn packs"
        );

        // Get number of cards to mint from package type
        uint256 numberOfCardsToOpen = numberOfCardpacks[ONE_CARD_PACK_ID] +
            numberOfCardpacks[FIVE_CARD_PACK_ID] *
            5 +
            numberOfCardpacks[TWENTY_CARD_PACK_ID] *
            20;

        // Get random card IDs to mint
        uint256[] memory cardIds = _getRandomCardIds(numberOfCardsToOpen);

        // Array of number of cards to mint for each card ID (all 1)
        uint256[] memory cardAmounts = new uint256[](numberOfCardsToOpen);
        for (uint256 i = 0; i < numberOfCardsToOpen; i++) {
            cardAmounts[i] = 1;
        }

        _mintBatch(msg.sender, cardIds, cardAmounts, "");
    }

    // Function to get n random values from one random value
    function expand(uint256 randomValue, uint256 n)
        public
        pure
        returns (uint256[] memory expandedValues)
    {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }

    /// @dev Function for getting random valid card IDs

    function _getRandomCardIds(uint256 nRandomNumbers)
        internal
        returns (uint256[] memory)
    {
        uint256 randomValue = uint256(
            keccak256(abi.encodePacked(block.difficulty, block.timestamp))
        );

        uint256[] memory randomValues = expand(randomValue, nRandomNumbers);
        uint256[] memory tokenIdsToMint = new uint256[](nRandomNumbers);

        for (
            uint256 tokenIdsToMintIndex = 0;
            tokenIdsToMintIndex < nRandomNumbers;
            tokenIdsToMintIndex++
        ) {
            // numberOfCardsLeft is the total number of cards left in the collection not minted yet
            uint256 numberOfCardsLeft = totalSupplyOfCards -
                totalNumberOfMintedCards;

            // Get random number between 0 and numberOfCardsLeft
            uint256 randomCardNumber = uint256(
                randomValues[tokenIdsToMintIndex] % numberOfCardsLeft
            );

            // To get a valid card ID, we loop through the remaining supply of each card aggregate it.
            // When we reach a aggregated supply that is greater than the random number that is between 0 and numberOfCardsLeft.
            // We add the card ID to the array of card IDs to mint and increase the supply of that card by 1.
            uint256 aggregatedSupply = 0;
            for (
                uint256 tokenID = 0;
                tokenID < numberOfUniqueCards;
                tokenID++
            ) {
                aggregatedSupply += supplyLimit[tokenID] - totalSupply[tokenID];

                if (randomCardNumber < aggregatedSupply) {
                    tokenIdsToMint[tokenIdsToMintIndex] = tokenID;
                    totalNumberOfMintedCards += 1;
                    totalSupply[tokenID] += 1;
                    break;
                }
            }
        }
        return tokenIdsToMint;
    }

    function mintUnionCard(address[] memory receivers) public onlyOwner {
        require(
            totalSupply[UNION_WORKER_CARD_ID] + receivers.length <=
                UNION_CARD_SUPPLY_LIMIT,
            "The union does not accept new members"
        );

        // Increase supply of union woprkers length of receivers
        totalSupply[UNION_WORKER_CARD_ID] += receivers.length;

        for (uint256 i = 0; i < receivers.length; i++) {
            _mint(receivers[i], UNION_WORKER_CARD_ID, 1, "");
        }
        emit MintUnionCard(msg.sender);
    }

    function setPayoutWallet(address payable payoutWallet_) public onlyOwner {
        payoutWallet = payoutWallet_;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payoutWallet.transfer(balance);
    }

    event SetBaseUri(string baseUri_);
    event MintUnionCard(address indexed receiver);
    event SetOpenPackageActive(bool openPackageActive_);
}