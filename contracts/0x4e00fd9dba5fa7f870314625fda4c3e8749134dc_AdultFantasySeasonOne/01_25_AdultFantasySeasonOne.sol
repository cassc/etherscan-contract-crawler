/// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ConstantsAF.sol";
import "./IAFCharacter.sol";
import "./AFRoles.sol";
import "./IERC2981.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract AdultFantasySeasonOne is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    AFRoles,
    Ownable,
    IERC2981
{
    constructor(address characterContractAddress, address signingAddressIn)
        ERC721("AdultFantasySeasonOne", "AFC")
    {
        afCharacter = IAFCharacter(characterContractAddress);
        require(address(signingAddressIn) != address(0), "Address is zero");
        signingAddress = signingAddressIn;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// Required for verifying mint passes
    using ECDSA for bytes32;

    /// Reference to the character contract
    IAFCharacter afCharacter;

    uint256 public boardingGroup = 0; /// Sets the faction that can mint
    address public contractIdentifier; /// For verifying mint passes
    string public customBaseURI; /// For viewing metadata
    string public licenseAgreementURI; /// For viewing the license agreement
    bool public mintStarted = false; /// Sets if general sale minting is enabled
    uint256 public priceWEI; /// For setting price
    uint256 public reservedCardsAvailable = 1000; /// Sets number of reserved cards
    address public royaltyTarget; /// Adddress where royalties are to be sent
    address public signingAddress; /// For verifying mint passes

    /// All cards that have been minted
    mapping(uint256 => MintedCard) public mintedCards;

    /// Represents a minted card
    struct MintedCard {
        uint256 characterID;
        uint256 specialSauceCode;
        uint256 serialNumerator;
        uint256 mintTime;
    }

    /// Types of mints other than general sale
    enum MintMethods {
        Whitelist,
        Giveaway,
        Reserved
    }

    mapping(string => bool) private usedMintPasses;
    mapping(address => uint256) public mintCounts;

    event BoardingGroupChanged(uint256 newBoardingGroup);

    /// Override functions <-----

    function _baseURI() internal view override returns (string memory) {
        return customBaseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyTarget, (_salePrice * 15) / 200); /// To get 7.5%
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControlEnumerable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /// ----->

    /// Mints one token per mint pass provided
    /// Mint pass is comprised of mintMethod, messageBoardingGroup, guid, and signature
    function purchaseTokenMintPass(
        MintMethods mintMethod,
        uint256 messageBoardingGroup,
        string memory guid,
        bytes memory signature,
        uint256[] memory randomNumbers,
        bytes[] memory signedRandomNumbers
    ) external payable {
        require(
            isValidAccessMessage(
                mintMethod,
                messageBoardingGroup,
                guid,
                msg.sender,
                signature
            ),
            "Invalid token"
        );

        require(
            isValidSignedRandomNumber(randomNumbers[0], signedRandomNumbers[0], msg.sender),
            "Random number is invalid"
        );

        require(!usedMintPasses[guid], "Token has been used");

        require(
            messageBoardingGroup <= boardingGroup,
            "This boarding group is not yet active"
        );
        usedMintPasses[guid] = true;
        mintCounts[msg.sender]++;


        uint256 cost = 0 wei;
        if (mintMethod == MintMethods.Whitelist) {
            /// Otherwise free+gas
            cost = priceWEI;
        }

        /// Ensuring we haven't minted more than the max reserved count
        if (
            mintMethod == MintMethods.Reserved ||
            mintMethod == MintMethods.Giveaway
        ) {
            require(reservedCardsAvailable >= 5); /// 5 are special characters
            reservedCardsAvailable--;
        }
        /// Checking if correct amount sent, could be zero for reserved or giveaway
        require(msg.value == cost, ConstantsAF.INCORRECT_AMOUNT);
        mintMultiple(1, randomNumbers, msg.sender);
    }

    /// Mints number of tokens provided during general sale
    function purchaseToken(
        uint256 purchaseCount,
        uint256[] memory randomNumbers,
        bytes[] memory signedRandomNumbers
    ) external payable {
        /// Checking to make sure general sale is enabled
        require(mintStarted, ConstantsAF.MINT_BEFORE_START);
        /// Checking if general sale has sold out
        require(totalSupply() < 9000, ConstantsAF.MAIN_SALE_ENDED);
        /// Checking if correct amount sent
        require(
            msg.value == priceWEI * purchaseCount,
            ConstantsAF.INCORRECT_AMOUNT
        );
        /// Checking if purchaseCount is under or equals 10
        require(purchaseCount <= 10, ConstantsAF.PURCHACE_TOO_MANY);
        for (uint256 index = 0; index < signedRandomNumbers.length; index++) {
            uint256 randomNumber = randomNumbers[index];
            bytes memory signedRandomNumber = signedRandomNumbers[index];
            require(
                isValidSignedRandomNumber(randomNumber, signedRandomNumber, msg.sender),
                "Random Number is invalid"
            );
            mintCounts[msg.sender]++;
        }

        mintMultiple(purchaseCount, randomNumbers, msg.sender);
    }

    /// For minting a number of mint passes that come from the reserved cards
    function batchPurchaseReservedTokenMintPass(
        string[] memory guids,
        uint256[] memory boardingGroups,
        bytes[] memory signatures,
        address _addr,
        uint256[] memory randomNumbers,
        bytes[] memory signedRandomNumbers
    ) external payable {
        require(
            guids.length == signatures.length,
            "Guid length doesn't match signatures"
        );
        require(
            boardingGroups.length == signatures.length,
            "Boarding groups length doesn't match signatures"
        );

        require(
            randomNumbers.length == signatures.length,
            "Random numbers length doesn't match signatures"
        );

        /// Ensuring we haven't minted more than the max reserved count
        require(
            int256(reservedCardsAvailable) - int256(guids.length) >= 0,
            "Not enough reserved cards available"
        );

        /// Decrement the available reserved cards
        reservedCardsAvailable -= guids.length;

        /// Validating mint passes
        for (uint256 index = 0; index < guids.length; index++) {
            /// Validating mint each mint pass
            string memory guid = guids[index];
            bytes memory signature = signatures[index];
            uint256 messageBoardingGroup = boardingGroups[index];
            require(
                isValidAccessMessage(
                    MintMethods.Reserved,
                    messageBoardingGroup,
                    guid,
                    _addr,
                    signature
                ),
                "Access message is invalid"
            );

            uint256 randomNumber = randomNumbers[index];
            bytes memory signedRandomNumber = signedRandomNumbers[index];

            require(
                isValidSignedRandomNumber(randomNumber, signedRandomNumber, _addr),
                "Random number is invalid"
            );
            require(!usedMintPasses[guid], "Mint pass is used");

            require(
                boardingGroups[index] <= boardingGroup,
                "This boarding group is not yet active"
            );
            usedMintPasses[guid] = true;
            mintCounts[_addr]++;
        }

        mintMultiple(guids.length, randomNumbers, _addr);
    }

    /// Mint special characters not available during the presale nor general sale
    function mintSpecialCharacter(uint256 characterID, address targetAddress)
        external
        onlyEditor
    {
        /// Ensuring we haven't minted more than the max reserved count
        require(
            int256(reservedCardsAvailable) - 1 >= 0,
            "Not enough reserved cards available"
        );

        /// Decrement the available reserved cards
        reservedCardsAvailable -= 1;

        /// Recording the minted card
        uint256 _id = totalSupply() + 1;
        MintedCard storage card = mintedCards[_id];
        card.characterID = characterID;
        card.specialSauceCode = 0;
        card.serialNumerator = 1;

        /// Performing the mint
        _safeMint(targetAddress, _id);
    }

    /// Set baseURI for metadata
    function setBaseURI(string memory uri) external onlyEditor {
        customBaseURI = uri;
    }

    /// Set faction that is allowed to mint during presale
    function setBoardingGroup(uint256 newBoardingGroup) external onlyEditor {
        boardingGroup = newBoardingGroup;
        emit BoardingGroupChanged(newBoardingGroup);
    }

    /// Set contractIdentifier for validating mint passes
    function setContractIdentifier(address addr) external onlyEditor {
        require(address(addr) != address(0), "Address is zero");
        contractIdentifier = addr;
    }

    function setSigningAddress(address addr) external onlyEditor {
        require(address(addr) != address(0), "Address is zero");
        signingAddress = addr;
    }

    /// Set licenseURI for license information
    function setLicenseURI(string memory uri) external onlyEditor {
        licenseAgreementURI = uri;
    }

    /// Set mintStarted to enable and disable the general sale
    function setMintStarted(bool newMintStartedValue) external onlyEditor {
        mintStarted = newMintStartedValue;
    }

    /// Set price for the token
    function setPrice(uint256 price) external onlyEditor {
        priceWEI = price;
    }

    /// Set royaltyTarget for the address to receive royalties
    /// This is assuming marketplaces will adopt IERC2981
    function setRoyaltyTarget(address targetAddress) external onlyEditor {
        require(address(targetAddress) != address(0), "Address is zero");
        royaltyTarget = targetAddress;
    }

    /// Withdraw revenue to the contract owner's address
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    /// Get the card info for viewing on marketplaces
    function getCard(uint256 cardID) external view returns (MintedCard memory) {
        return mintedCards[cardID];
    }

    /// Validates mint passes
    function isValidAccessMessage(
        MintMethods mintMethod,
        uint256 messageBoardingGroup,
        string memory guid,
        address _addr,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                uint256(mintMethod),
                messageBoardingGroup,
                bytes(guid),
                contractIdentifier,
                _addr
            )
        );
        return
            signingAddress == hash.toEthSignedMessageHash().recover(signature);
    }

    function isValidSignedRandomNumber(
        uint256 randomNumber,
        bytes memory signedRandomNumber,
        address _addr
    ) public view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                randomNumber,
                contractIdentifier,
                mintCounts[_addr],
                _addr
            )
        );

        return
            signingAddress ==
            hash.toEthSignedMessageHash().recover(signedRandomNumber);
    }

    /// Primary minting function
    function mintMultiple(
        uint256 quantity,
        uint256[] memory randomNumbers,
        address targetAddress
    ) private {
        for (uint256 index = 0; index < quantity; index++) {
            ///Selecting random character
            uint256 totalRemaining = 9995 - totalSupply(); /// 5 are special characters
            uint256 characterID = afCharacter.takeRandomCharacter(
                randomNumbers[index], totalRemaining
            );

            /// Setting serial numerator
            uint256 serialNumerator = afCharacter.getCharacterSupply(
                characterID
            );

            /// Recording the minted card
            uint256 _id = totalSupply() + 1;
            MintedCard storage card = mintedCards[_id];
            card.characterID = characterID;
            card.specialSauceCode = randomNumbers[index];
            card.serialNumerator = serialNumerator;
            card.mintTime = block.timestamp;

            /// Delete variables
            delete serialNumerator;
            delete characterID;
            delete totalRemaining;

            /// Performing the mint
            _safeMint(targetAddress, _id);
        }
    }
}