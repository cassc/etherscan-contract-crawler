// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)
pragma solidity ^0.8.13;


import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IMarketplace.sol";

contract AisNft is ERC1155, Ownable {

    struct NftItem {
        uint256 tokenId;
        uint32 quantity;
        address creator;
        bool isListed;
        bool isGallery;//new
        uint32 galleryFee;
        address galleryAddress;
        address[] collaborators;
        uint32[] collaboratorsFee;
        bool isMembership;
    }

    uint256 public nextTokenId = 1001;

    mapping(uint256 => string) _uris;
    mapping(uint256 => NftItem) _idToNftItem;

    address public membership;
    address public marketplace;

    event NftItemCreated(
        uint256 tokenId, uint32 qty, address creator,
        bool isGallery, uint32 galleryFee, address galleryAddress,
        address[] collaborators, uint32[] collaboratorsFee
    );

    constructor()  ERC1155("") {
    }

    modifier onlyMarketplace()  {
        require(msg.sender == marketplace, "Not a marketplace");
        _;
    }

    modifier onlyMembership()  {
        require(msg.sender == membership, "Not a membership");
        _;
    }

    modifier isFeePercentagesLessThanMaximum(uint32[] memory _feePercentages) {
        uint32 totalPercent;
        for (uint256 i = 0; i < _feePercentages.length; i++) {
            totalPercent = totalPercent + _feePercentages[i];
        }
        require(totalPercent <= 10000, "Fee percentages exceed maximum");
        _;
    }

    modifier correctFeeRecipientsAndPercentages(
        uint256 _recipientsLength,
        uint256 _percentagesLength
    ) {
        require(
            _recipientsLength == _percentagesLength,
            "Recipients != percentages"
        );
        _;
    }

    function setMembership(address _membership) public {
        membership = _membership;
    }

    function setMarketplace(address _marketplace) public {
        marketplace = _marketplace;
    }


    function uri(uint256 _tokenId) override public view returns (string memory) {
        return (_uris[_tokenId]);
    }

    function getNftItem(uint256 _tokenId) public view returns (NftItem memory){
        return _idToNftItem[_tokenId];
    }

    function marketplaceTransfer(address from, address to, uint256 id, uint256 amount)
    onlyMarketplace
    external
    {
        _safeTransferFrom(from, to, id, amount, "");
    }

    function membershipTransfer(address from, address to, uint256 id)
    onlyMembership
    external
    {
        _safeTransferFrom(from, to, id, 1, "");
    }

    function createNftItem(
        address _creator,
        string memory _uri,
        uint32 _quantity,
        uint32 _galleryFee,
        address _galleryAddress,
        address[] memory _collaborators,
        uint32[] memory _collaboratorsFee)
    onlyMarketplace
    correctFeeRecipientsAndPercentages(_collaborators.length, _collaboratorsFee.length)
    isFeePercentagesLessThanMaximum(_collaboratorsFee)
    external returns (uint256)
    {

        if (_galleryAddress != address(0)) {//new
            require(_galleryFee < 10000, "Fee can't be more then 100%");
        } else {
            require(_galleryFee == 0, "Gallery fee can't assigned");
        }

        // mint
        uint256 tokenId = _mintInternal(_creator, _uri, _quantity);

        _idToNftItem[tokenId] = NftItem(
            tokenId,
            _quantity,
            _creator,
            true,
            _galleryAddress != address(0),
            _galleryFee,
            _galleryAddress,
            _collaborators,
            _collaboratorsFee,
            false
        );


        emit NftItemCreated(
            tokenId, _quantity, _creator,
            _galleryAddress != address(0), _galleryFee, _galleryAddress,
            _collaborators, _collaboratorsFee
        );

        return tokenId;
    }

    function createMembershipToken(address _creator, string memory _uri, uint32 _quantity)
    onlyMembership
    external returns (uint256)
    {
        // mint
        uint256 tokenId = _mintInternal(_creator, _uri, _quantity);

        _idToNftItem[tokenId].tokenId = tokenId;
        _idToNftItem[tokenId].quantity = _quantity;
        _idToNftItem[tokenId].creator = _creator;
        _idToNftItem[tokenId].isListed = false;
        _idToNftItem[tokenId].isMembership = true;

        return tokenId;
    }

    function _mintInternal(address _to, string memory _uri, uint32 _quantity) internal returns (uint256)
    {
        _mint(_to, nextTokenId, _quantity, "");
        _uris[nextTokenId] = _uri;
        nextTokenId++;
        return nextTokenId - 1;
    }

    //    overrides

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - Membership token can't be transferred beside contract
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (operator != marketplace && operator != membership) {
            for (uint256 i = 0; i < ids.length; i++) {
                if (marketplace != address(0) && IMarketplace(marketplace).isActiveAuction(ids[i])) {
                    revert("Auctioned token can't be transferred");
                }
                if (_idToNftItem[ids[i]].isMembership) {
                    revert("Membership token can't be transferred");
                }
            }
        }
    }

}