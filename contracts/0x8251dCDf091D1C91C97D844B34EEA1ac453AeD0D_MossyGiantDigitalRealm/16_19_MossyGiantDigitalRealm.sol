// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title MossyGiantDigitalRealm
 * MossyGiantDigitalRealm - an 1155 contract for  TheReeferRascals
 */
contract MossyGiantDigitalRealm is
    ERC1155Supply,
    ERC2981,
    DefaultOperatorFilterer,
    Ownable
{
    using Strings for string;

    struct itemData {
        uint256 maxSupply;
        uint256 maxToMint;
        uint256 maxPerNFT;
        uint256 publicPrice;
        bool claimIdActive;
    }

    mapping(address => mapping(uint256 => uint256)) public claimInfo;

    mapping(uint256 => itemData) public idStats;

    string public name;
    string public symbol;

    string public baseURI =
        "https://mother-plant.s3.amazonaws.com/mossygiantrealm/metadata/";

    bool public publicClaimIsActive = false;
    IERC721 public motherplantNFT;

    constructor(
        string memory _uri,
        string memory _name,
        string memory _symbol,
        address payable royaltiesReceiver,
        address motherplantAddress
    ) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;
        motherplantNFT = IERC721(motherplantAddress);
        setRoyaltyInfo(royaltiesReceiver, 1000);
    }

    function publicSale(uint256 _quantity, uint256 _id) external payable {
        uint256 nftBalance = motherplantNFT.balanceOf(msg.sender);
        uint256 claimsAvailable = nftBalance * idStats[_id].maxPerNFT;
        require(_quantity > 0, "Quantity must be greater than 0");
        require(
            claimInfo[msg.sender][_id] + _quantity <= claimsAvailable,
            "Exceeded claim quantity"
        );
        require(publicClaimIsActive, "Claim is not active.");
        require(
            idStats[_id].claimIdActive,
            "Sale not available for this item now."
        );
        require(
            idStats[_id].publicPrice * _quantity <= msg.value,
            "ETH sent is incorrect."
        );
        require(
            totalSupply(_id) + _quantity <= idStats[_id].maxSupply,
            "Minting limit reached."
        );
        require(
            _quantity <= idStats[_id].maxToMint,
            "Exceeds NFT per transaction limit."
        );
        unchecked {
            claimInfo[msg.sender][_id] += _quantity;
        }
        _mint(msg.sender, _id, _quantity, "");
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "ERC1155: NONEXISTENT_TOKEN");
        return (
            string(abi.encodePacked(baseURI, Strings.toString(_id), ".json"))
        );
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setURI(string memory _newURI) public onlyOwner {
        _setURI(_newURI);
    }

    function setClaimIdActive(bool _idActive, uint256 _id) external onlyOwner {
        idStats[_id].claimIdActive = _idActive;
    }

    function setMaxToMint(uint256 _maxToMint, uint256 _id) external onlyOwner {
        idStats[_id].maxToMint = _maxToMint;
    }

    function setmaxPerNFT(uint256 _maxPerNFT, uint256 _id) external onlyOwner {
        idStats[_id].maxPerNFT = _maxPerNFT;
    }

    function setMaxSupply(uint256 _maxSupply, uint256 _id) external onlyOwner {
        idStats[_id].maxSupply = _maxSupply;
    }

    function setPublicPrice(
        uint256 _publicPrice,
        uint256 _id
    ) external onlyOwner {
        idStats[_id].publicPrice = _publicPrice;
    }

    function flipPublicClaimState() external onlyOwner {
        publicClaimIsActive = !publicClaimIsActive;
    }

    function createItem(
        uint256 _id,
        uint256 _maxPerNFT,
        uint256 _maxToMint,
        uint256 _maxSupply,
        uint256 _publicPrice,
        bool _claimIdActive
    ) external onlyOwner {
        idStats[_id].maxPerNFT = _maxPerNFT;
        idStats[_id].maxToMint = _maxToMint;
        idStats[_id].maxSupply = _maxSupply;
        idStats[_id].publicPrice = _publicPrice;
        idStats[_id].claimIdActive = _claimIdActive;
    }

    function withdraw() external onlyOwner {
        (bool rr, ) = payable(0xad8076DcaC7d6FA6F392d24eE225f4d715FAa363).call{
            value: address(this).balance
        }("");
        require(rr, "Transfer failed");
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // IERC2981
    function setRoyaltyInfo(
        address payable receiver,
        uint96 numerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }
}