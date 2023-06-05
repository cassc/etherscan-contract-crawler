// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721A, IERC721A, ERC721AQueryable} from "./extensions/ERC721AQueryable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "base64-sol/base64.sol";
import "hardhat/console.sol";

/**
 * @title ColoredSquare
 * @author @coloredsq
 *
 * Attention, colored squares!
 * To all of the scammers, phishers, and rug pullers. Fuck them all.
 */
contract ColoredSquare is
    DefaultOperatorFilterer,
    ERC2981,
    ERC721AQueryable,
    Ownable
{
    using Strings for uint256;

    struct MintState {
        bool isPublicOpen;
        uint256 liveAt;
        uint256 expiresAt;
        uint256 maxSupply;
        uint256 totalSupply;
        uint256 price;
        uint256 stealPrice;
    }

    /// @dev Treasury
    address public treasury =
        payable(0xfDf5aC9597DE3Efa95AC300B8800261b59C5320b);

    /// @dev The total supply of the collection (n-1)
    uint256 public maxSupply = 10193;

    /// @notice ETH mint price
    uint256 public price = 0.005 ether;

    /// @notice ETH steal price
    uint256 public stealPrice = 0.1 ether;

    /// @notice Live timestamp
    uint256 public liveAt = 0;

    /// @notice Expires timestamp
    uint256 public expiresAt = 1713664453;

    /// @notice Public mint
    bool public isPublicOpen = true;

    /// @notice Lookup hex to token id
    mapping(string => uint256) public hexToTokenId;

    /// @notice Lookup token id to hex
    mapping(uint256 => string) public tokenIdToHex;

    /// @notice Token id to stolen amount
    mapping(uint256 => uint256) public tokenIdToStolen;

    constructor() ERC721A("ColoredSquare", "COLOR") {
        _setDefaultRoyalty(treasury, 500);
        _proxies[address(this)] = true;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // @dev length is 6, a-f or digits from 0-9, e.g, 000000,
    function _isValidHex(string memory value) internal pure returns (bool) {
        bytes memory str = bytes(value);
        if (str.length != 6) return false;
        for (uint256 i = 1; i < str.length; i++) {
            bytes1 char = str[i];
            if (
                !(
                    (((char > 0x60) && (char < 0x67)) ||
                        ((char > 0x29) && (char < 0x40)))
                )
            ) return false;
        }
        return true;
    }

    function _toLower(
        string calldata str
    ) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(str);
        for (uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] >= 0x41 && _baseBytes[i] <= 0x5A) {
                _baseBytes[i] = bytes1(uint8(_baseBytes[i]) + 32);
            } else {
                _baseBytes[i] = _baseBytes[i];
            }
        }
        return string(_baseBytes);
    }

    function _toJSONProperty(
        string memory key,
        string memory value
    ) internal pure returns (string memory) {
        return string(abi.encodePacked('"', key, '" : "', value, '"'));
    }

    function _toJSONAttribute(
        string memory key,
        string memory value
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{ "trait_type":"',
                    key,
                    '", "value": "',
                    value,
                    '"}'
                )
            );
    }

    /**
     * @notice Returns a json list of attribute properties
     */
    function _toAttributesProperty(
        string memory _hexColor,
        uint256 _stolenAmount
    ) internal pure returns (string memory) {
        string[] memory attributes = new string[](2);

        attributes[0] = _toJSONAttribute(
            "Color",
            string(abi.encodePacked("#", _hexColor))
        );

        attributes[1] = _toJSONAttribute(
            "Stolen",
            Strings.toString(_stolenAmount)
        );

        bytes memory attributeListBytes = "[";

        for (uint256 i = 0; i < attributes.length; i++) {
            attributeListBytes = abi.encodePacked(
                attributeListBytes,
                attributes[i],
                i != attributes.length - 1 ? "," : "]"
            );
        }

        return string(attributeListBytes);
    }

    function _generateSquare(
        string memory _hexColor,
        uint256 _stolenAmount
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '<?xml version="1.0" encoding="UTF-8"?>',
                                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 2000 2000">',
                                '<path d="M0 0h2000v2000H0z" fill="#',
                                _hexColor,
                                '" />',
                                '<text x="1900" y="1925" style="font-family:monospace;font-size:32px;color:',
                                _hexColor, // hidden stolen number :)
                                '">x',
                                Strings.toString(_stolenAmount),
                                "</text>",
                                "</svg>"
                            )
                        )
                    )
                )
            );
    }

    /**
     * @notice Pay to steal a color from someone else
     * @param _hexColor to steal
     */
    function steal(string calldata _hexColor) external payable {
        string memory normalizedColor = _toLower(_hexColor);
        uint256 tokenId = hexToTokenId[normalizedColor];
        require(tokenId > 0, "!minted");
        require(
            msg.value >= tokenIdToStolen[tokenId] + 1 * stealPrice,
            "!funds"
        );
        tokenIdToStolen[tokenId]++;
        super.stealIt(_msgSenderERC721A(), tokenId);
    }

    /**************************************************************************
     * Minting
     *************************************************************************/

    /**
     * @notice Public mint function - only 1 at a time but no max
     * @param _hex The color to mint
     */
    function mint(string calldata _hex) external payable {
        require(isLive() && isPublicOpen, "!active");
        require(totalSupply() + 1 < maxSupply, "!mint");
        require(msg.value >= price, "!funds");
        string memory normalizedColor = _toLower(_hex);
        require(hexToTokenId[normalizedColor] == 0, "!hex");
        require(_isValidHex(normalizedColor), "!valid");
        uint256 nextId = _nextTokenId();
        hexToTokenId[normalizedColor] = nextId;
        tokenIdToHex[nextId] = normalizedColor;
        _mint(_msgSenderERC721A(), 1);
    }

    /// @dev Check if mint is live
    function isLive() public view returns (bool) {
        return block.timestamp >= liveAt && block.timestamp <= expiresAt;
    }

    /// @notice Returns current mint state for a particular address
    function getMintState() external view returns (MintState memory) {
        return
            MintState({
                isPublicOpen: isPublicOpen,
                liveAt: liveAt,
                expiresAt: expiresAt,
                maxSupply: maxSupply,
                totalSupply: totalSupply(),
                price: price,
                stealPrice: stealPrice
            });
    }

    /**
     * @notice Returns how many times a color has been stolen by hex color
     * @param _hexColor The hex color
     */
    function getStolenAmountByColor(
        string calldata _hexColor
    ) external view returns (uint256) {
        string memory normalizedColor = _toLower(_hexColor);
        uint256 tokenId = hexToTokenId[normalizedColor];
        return tokenIdToStolen[tokenId];
    }

    /**
     * @notice Returns how many times a color has been stolen
     * @param _tokenId The token id
     */
    function getStolenAmount(uint256 _tokenId) external view returns (uint256) {
        require(_exists(_tokenId), "!exists");
        return tokenIdToStolen[_tokenId];
    }

    /**
     * @notice Returns a base64 json metadata
     * @param _tokenId The bear token id
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(_tokenId), "!exists");
        string memory hexColor = tokenIdToHex[_tokenId];
        uint256 stolenAmount = tokenIdToStolen[_tokenId];
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                "{",
                                _toJSONProperty(
                                    "name",
                                    string(
                                        abi.encodePacked(
                                            "Colored Square",
                                            " ",
                                            Strings.toString(_tokenId)
                                        )
                                    )
                                ),
                                ",",
                                _toJSONProperty(
                                    "description",
                                    "This is a colored square. That is all. Well...it could get stolen from you."
                                ),
                                ",",
                                _toJSONProperty(
                                    "image",
                                    _generateSquare(hexColor, stolenAmount)
                                ),
                                ",",
                                abi.encodePacked(
                                    '"attributes": ',
                                    _toAttributesProperty(
                                        hexColor,
                                        stolenAmount
                                    )
                                ),
                                ",",
                                _toJSONProperty(
                                    "tokenId",
                                    Strings.toString(_tokenId)
                                ),
                                "}"
                            )
                        )
                    )
                )
            );
    }

    /**************************************************************************
     * Admin
     *************************************************************************/

    /**
     * @notice Sets the collection max supply
     * @param _maxSupply The max supply of the collection
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /**
     * @notice Sets stolen eth price
     * @param _stealPrice The price in wei
     */
    function setStolenPrice(uint256 _stealPrice) external onlyOwner {
        stealPrice = _stealPrice;
    }

    /**
     * @notice Sets eth price
     * @param _price The price in wei
     */
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /**
     * @notice Sets the treasury recipient
     * @param _treasury The treasury address
     */
    function setTreasury(address _treasury) public onlyOwner {
        treasury = payable(_treasury);
    }

    /**
     * @notice Sets the mint states
     * @param _isPublicMintOpen The public mint is open
     */
    function setMintState(bool _isPublicMintOpen) external onlyOwner {
        isPublicOpen = _isPublicMintOpen;
    }

    /**
     * @notice Sets timestamps for live and expires timeframe
     * @param _liveAt A unix timestamp for live date
     * @param _expiresAt A unix timestamp for expiration date
     */
    function setMintWindow(
        uint256 _liveAt,
        uint256 _expiresAt
    ) external onlyOwner {
        liveAt = _liveAt;
        expiresAt = _expiresAt;
    }

    /**
     * @notice Changes the contract defined royalty
     * @param _receiver - The receiver of royalties
     * @param _feeNumerator - The numerator that represents a percent out of 10,000
     */
    function setDefaultRoyalty(
        address _receiver,
        uint96 _feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    /// @notice Withdraws funds from contract
    function withdraw() public onlyOwner {
        (bool success, ) = treasury.call{value: address(this).balance}("");
        require(success, "Unable to withdraw ETH");
    }

    /**************************************************************************
     * Royalties
     *************************************************************************/

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC721A, ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}