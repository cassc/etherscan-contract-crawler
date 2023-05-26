// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TimePiecesRoboto is ERC1155, Ownable {
    using Strings for uint256;

    modifier contractIsNotFrozen() {
        require(isFrozen == false, "This function can not be called anymore");
        _;
    }

    uint8 constant RED_BORDER_TOKEN_ID = 0;
    uint8 constant WHITE_BORDER_TOKEN_ID = 1;

    uint8 constant ROBOTO_RED = 0;
    uint8 constant ENTERTAINER_RED = 1;
    uint8 constant BUSINESS_PERSON_RED = 2;
    uint8 constant ATHLETE_RED = 3;
    uint8 constant HERO_RED = 4;

    uint8 constant ROBOTO_WHITE = 5;
    uint8 constant ENTERTAINER_WHITE = 6;
    uint8 constant BUSINESS_PERSON_WHITE = 7;
    uint8 constant ATHLETE_WHITE = 8;
    uint8 constant HERO_WHITE = 9;

    uint16[10] availableTokens;
    mapping(uint8 => uint8[]) availableTokensIds;

    bool private isFrozen = false;

    string public name = "TIMEPieces x Robotos";

    constructor() ERC1155("ipfs://QmPosCiufY9iMArMJw78FpLvoGgGWt1XQMnroUfqYEDAgh/") {
        availableTokensIds[RED_BORDER_TOKEN_ID] = [ROBOTO_RED, BUSINESS_PERSON_RED, ENTERTAINER_RED, ATHLETE_RED, HERO_RED];
        availableTokens[ROBOTO_RED] = 536;
        availableTokens[BUSINESS_PERSON_RED] = 536;
        availableTokens[ENTERTAINER_RED] = 536;
        availableTokens[ATHLETE_RED] = 536;
        availableTokens[HERO_RED] = 536;


        availableTokensIds[WHITE_BORDER_TOKEN_ID] = [ROBOTO_WHITE, BUSINESS_PERSON_WHITE, ENTERTAINER_WHITE, ATHLETE_WHITE, HERO_WHITE];
        availableTokens[ROBOTO_WHITE] = 1080;
        availableTokens[BUSINESS_PERSON_WHITE] = 1080;
        availableTokens[ENTERTAINER_WHITE] = 1080;
        availableTokens[ATHLETE_WHITE] = 1080;
        availableTokens[HERO_WHITE] = 1080;
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC1155.uri(_tokenId), _tokenId.toString()));
    }

    // ONLY OWNER

    /**
     * @dev Sets the base URI for the API that provides the NFT data.
     */
    function setURI(string memory _uri) external onlyOwner contractIsNotFrozen {
        _setURI(_uri);
    }

    /**
     * @dev Gives one piece of each to the artist
     */
    function devMintTokensToArtist(address _artistAddress) external onlyOwner contractIsNotFrozen {
        for (uint256 i = 0; i < 10; i++) {
            _mint(_artistAddress, i, 1, "");
        }
    }

    /**
     * @dev Gives a random token to the provided address
     */
    function devMintTokensToAddresses(uint8 _tokenBorderId, address[] memory _addresses) external onlyOwner contractIsNotFrozen {
        require(_addresses.length > 0, "At least one token should be minted");
        require(getAvailableTokens(_tokenBorderId) >= _addresses.length, "Not enough tokens available");

        uint16[10] memory tmpAvailableTokens = availableTokens;

        for (uint256 i; i < _addresses.length; i++) {
            uint8 tokenTypeIndex = _getRandomNumber(availableTokensIds[_tokenBorderId].length, i);

            _mint(_addresses[i], availableTokensIds[_tokenBorderId][tokenTypeIndex], 1, "");

            tmpAvailableTokens[availableTokensIds[_tokenBorderId][tokenTypeIndex]]--;

            if (tmpAvailableTokens[availableTokensIds[_tokenBorderId][tokenTypeIndex]] == 0) {
                availableTokensIds[_tokenBorderId][tokenTypeIndex] = availableTokensIds[_tokenBorderId][availableTokensIds[_tokenBorderId].length - 1];
                availableTokensIds[_tokenBorderId].pop();        
            }
        }

        availableTokens = tmpAvailableTokens;
    }

    /**
     * @dev Set the total amount of tokens
     */
    function addSupply(uint8 _tokenType, uint16 _supply) external onlyOwner contractIsNotFrozen {
        require(_tokenType < 10, "Token type should be between 0 and 9");
        require(_supply > 0, "Supply should be greater than 0");

        availableTokens[_tokenType] += _supply;

        uint8 tokenBorderType = _tokenType < 5 ? RED_BORDER_TOKEN_ID : WHITE_BORDER_TOKEN_ID;

        bool isTokenTypeAvailable = false;

        for (uint256 i; i < availableTokensIds[tokenBorderType].length; i++) {
            if (availableTokensIds[tokenBorderType][i] == _tokenType) {
                isTokenTypeAvailable = true;
                break;
            }
        }

        if (!isTokenTypeAvailable) {
            availableTokensIds[tokenBorderType].push(_tokenType);
        }
    }

    /**
     * @dev Sets the isFrozen variable to true
     */
    function freezeSmartContract() external onlyOwner {
        isFrozen = true;
    }

    function getAvailableTokens(uint8 _tokenBorderId) public view returns (uint256) {
        if (_tokenBorderId == RED_BORDER_TOKEN_ID) {
            return (availableTokens[ROBOTO_RED] + availableTokens[BUSINESS_PERSON_RED] + availableTokens[ENTERTAINER_RED] + availableTokens[ATHLETE_RED] + availableTokens[HERO_RED]);
        } else if (_tokenBorderId == WHITE_BORDER_TOKEN_ID) {
           return (availableTokens[ROBOTO_WHITE] + availableTokens[BUSINESS_PERSON_WHITE] + availableTokens[ENTERTAINER_WHITE] + availableTokens[ATHLETE_WHITE] + availableTokens[HERO_WHITE]);
        } else {
            revert("Invalid _tokenBorderId.");
        }
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint256 _upper, uint256 _nonce)
        private
        view
        returns (uint8)
    {
        uint8 random = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(
                        _nonce,
                        blockhash(block.number - 1),
                        block.coinbase,
                        block.difficulty,
                        msg.sender
                    )
                )
            )
        );

        return random % uint8(_upper);
    }
}