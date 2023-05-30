// SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Relic.sol";



contract ExampleRelicMinter is IRelicMinter, Ownable
{
    Relic private _relic;
    uint256 private _minTokenId;
    uint256 private _maxTokenId;
    uint256 private _nextTokenId;
    string public placeholderImageURL; // this is used when images are not yet pinned
    string public imageBaseURL;

    constructor(
        Relic relic,
        uint256 minTokenId,
        uint256 maxTokenId,
        string memory placeholderImgURL,
        string memory imgBaseURL)
    {
        _relic = relic;
        _minTokenId = minTokenId;
        _maxTokenId = maxTokenId;
        _nextTokenId = minTokenId;
        placeholderImageURL = placeholderImgURL;
        imageBaseURL = imgBaseURL;
    }

    function setPlaceholderImageURL(string memory newPlaceholderImageURL) public onlyOwner
    {
        placeholderImageURL = newPlaceholderImageURL;
    }

    function setImageBaseURL(string memory newImageBaseURL) public onlyOwner
    {
        imageBaseURL = newImageBaseURL;
    }

    function mintTokenId(uint256 tokenId, bytes12 data) public
    {
        _relic.mint(_msgSender(), tokenId, data);
    }

    function mint(bytes12 data) public
    {
        while (_relic.exists(_nextTokenId))
        {
            ++_nextTokenId;
        }

        require(_nextTokenId <= _maxTokenId, "run out of relics");

        mintTokenId(_nextTokenId++, data);
    }

    function getTokenOrderIndex(uint256 /*tokenId*/, bytes12 /*data*/)
        external override pure returns(uint)
    {
        return 0;
    }

    function getTokenProvenance(uint256 /*tokenId*/, bytes12 /*data*/)
        external override pure returns(string memory)
    {
        return "Example Chapter";
    }

    function getAdditionalAttributes(uint256 /*tokenId*/, bytes12 /*data*/)
        external override pure returns(string memory)
    {
        return
            ",{\"trait_type\": \"Extra1\", \"value\": \"Thing1\"}"
            ",{\"trait_type\": \"Extra2\", \"value\": \"Thing2\"}";
    }

    function getImageBaseURL() external override view returns(string memory)
    {
        if (bytes(imageBaseURL).length > 0)
        {
            return imageBaseURL;
        }

        return placeholderImageURL;
    }
}