// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../../extensions/HasSecondarySaleFees.sol";

interface iNaughtyPIPPI {

    event Buy(
        address indexed buyer,
        uint256 tokenId
    );

    // FOR PUBLIC SALE

    function toggleSale(bool isOpen) external;

    function isOnSale() external view returns (bool);

    function price() external view returns (uint256);

    function remainingSalesAmount() external view returns (uint256);

    function mintedSalesTokenIdList(
        uint256 first,
        uint256 limit
    ) external view returns (uint256[] memory);

    function buy(uint256 tokenId) external payable;


    // FOR CONTRACT OWNER(s)

    function mintForReserve(address to, uint256 amount) external;

    function withdrawETH() external;

}

contract NaughtyPIPPI is
iNaughtyPIPPI,
ERC721Burnable,
HasSecondarySaleFees,
Ownable,
ReentrancyGuard
{

    using Strings for uint256;

    constructor(
        address payable _primarySalesRecipient,
        address payable[] memory _secondaryRecipients,
        uint256[] memory _secondaryRoyaltiesWithTwoDecimals,
        string memory _baseURI
    )
    ERC721("Naughty PIPPI", "NP")
    HasSecondarySaleFees(new address payable[](0), new uint256[](0))
    {
        require(_primarySalesRecipient != address(0), "Invalid address");
        require(keccak256(abi.encodePacked(_baseURI)) != keccak256(abi.encodePacked("")), "empty uri");

        _updateCommonSecondaryRoyalty(_secondaryRecipients, _secondaryRoyaltiesWithTwoDecimals);
        primarySalesRecipient = _primarySalesRecipient;
        baseURI = _baseURI;
    }

    string private baseURI;
    uint256 public constant TOTAL_SUPPLY = 8888;
    uint256 public constant FIRST_SALES_TOKEN_ID = 1;
    uint256 public constant FIRST_RESERVED_TOKEN_ID = 8439;


    // FOR PUBLIC SALE

    bool private _isOnSale;
    uint256 private _price = 0.03 ether;
    uint256 private _remainingSalesAmount = FIRST_RESERVED_TOKEN_ID - FIRST_SALES_TOKEN_ID;
    uint256[] private _mintedTokenIdList;

    function toggleSale(bool isOpen) external override onlyOwner {
        _isOnSale = isOpen;
    }

    function isOnSale() external view override returns (bool) {
        return _isOnSale;
    }

    function price() external override view returns (uint256) {
        return _price;
    }

    function remainingSalesAmount() external override view returns (uint256) {
        return _remainingSalesAmount;
    }

    function mintedSalesTokenIdList(
        uint256 offset,
        uint256 limit
    ) external override view returns (uint256[] memory) {
        uint256 minted = _mintedTokenIdList.length;

        if (minted == 0) {
            return _mintedTokenIdList;
        }
        if (minted < offset) {
            return new uint256[](0);
        }

        uint256 length = limit;
        if (minted < offset + limit) {
            length = minted - offset;
        }
        uint256[] memory list = new uint256[](length);
        for (uint256 i = offset; i < offset + limit; i++) {
            if (_mintedTokenIdList.length <= i) {
                break;
            }
            list[i - offset] = _mintedTokenIdList[i];
        }

        return list;
    }

    function buy(uint256 tokenId) external override payable nonReentrant {
        require(FIRST_SALES_TOKEN_ID <= tokenId, "Non sales token");
        require(tokenId < FIRST_RESERVED_TOKEN_ID, "Non sales token");
        require(_isOnSale, "Not on sale");
        require(msg.value == _price, "Invalid value");

        _remainingSalesAmount--;

        _mintedTokenIdList.push(tokenId);

        _safeMint(msg.sender, tokenId);

        emit Buy(msg.sender, tokenId);
    }

    // FOR CONTRACT OWNER(s)

    uint256 public nextReservedTokenId = FIRST_RESERVED_TOKEN_ID;
    address payable private primarySalesRecipient;

    function mintForReserve(address to, uint256 amount) external override onlyOwner {
        require(to != address(0), "Invalid address");
        require(nextReservedTokenId + amount <= TOTAL_SUPPLY + 1, "No remaining tokens");

        for (uint256 i = nextReservedTokenId; i < nextReservedTokenId + amount; i++) {
            _safeMint(to, i);
        }

        nextReservedTokenId += amount;
    }

    function withdrawETH() external override {
        Address.sendValue(primarySalesRecipient, address(this).balance);
    }


    // Miscellaneous

    function updateCommonSecondaryRoyalty(
        address payable[] memory _secondaryRecipients,
        uint256[] memory _secondaryRoyaltiesWithTwoDecimals
    ) external onlyOwner {
        _updateCommonSecondaryRoyalty(_secondaryRecipients, _secondaryRoyaltiesWithTwoDecimals);
    }

    function _updateCommonSecondaryRoyalty(
        address payable[] memory _secondaryRecipients,
        uint256[] memory _secondaryRoyaltiesWithTwoDecimals
    ) internal {
        require(_secondaryRecipients.length == _secondaryRoyaltiesWithTwoDecimals.length, "Invalid length");

        for (uint256 i = 0; i < _secondaryRecipients.length; i++) {
            require(_secondaryRecipients[i] != address(0), "Zero address");
            require(0 < _secondaryRoyaltiesWithTwoDecimals[i], "Zero value");
        }

        _setCommonRoyalties(_secondaryRecipients, _secondaryRoyaltiesWithTwoDecimals);
    }

    function updateBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
        : '';
    }

    receive() external payable {}

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, HasSecondarySaleFees)
    returns (bool)
    {
        return ERC721.supportsInterface(interfaceId) ||
        HasSecondarySaleFees.supportsInterface(interfaceId);
    }
}