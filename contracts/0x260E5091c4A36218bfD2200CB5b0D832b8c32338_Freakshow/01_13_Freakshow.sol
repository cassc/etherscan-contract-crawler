//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Freakshow is
    Ownable,
    ERC721A,
    IERC721Receiver,
    Pausable,
    DefaultOperatorFilterer
{
    using SafeMath for uint256;

    address clownzContract;
    string public baseTokenURI;
    uint256 public exchangeRate = 5;
    uint256[] customFreakshowTokens;
    mapping(uint256 => bool) public isCustomClown;

    constructor(address _clownzContract) ERC721A("Freakshow", "Freakshow") {
        isCustomClown[745] = true;
        isCustomClown[2062] = true;
        isCustomClown[4533] = true;
        isCustomClown[3310] = true;
        isCustomClown[1319] = true;
        isCustomClown[2264] = true;
        clownzContract = _clownzContract;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setClownzContract(address _clownzContract) external onlyOwner {
        clownzContract = _clownzContract;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function getCustomFreakshowTokens()
        external
        view
        returns (uint256[] memory)
    {
        return customFreakshowTokens;
    }

    function setExchangeRate(uint256 _exchangeRate) external onlyOwner {
        exchangeRate = _exchangeRate;
    }

    function setCustomClown(uint256 _token, bool _isCustom) external onlyOwner {
        isCustomClown[_token] = _isCustom;
    }

    function exchangeCustomMint(uint256[] calldata _tokens)
        external
        whenNotPaused
    {
        require(_tokens.length == 1, "One 1/1 at a time");
        for (uint256 index; index < _tokens.length; index++) {
            require(isCustomClown[_tokens[index]], "Not custom token");
            IERC721(clownzContract).safeTransferFrom(
                msg.sender,
                address(this),
                _tokens[index]
            );
        }

        _safeMint(msg.sender, _tokens.length);
        customFreakshowTokens.push(_nextTokenId().sub(1));
    }

    function exchangeMint(uint256[] calldata _tokens) external whenNotPaused {
        require(
            _tokens.length % exchangeRate == 0,
            "Not enough tokens provided"
        );
        for (uint256 index; index < _tokens.length; index++) {
            require(
                !isCustomClown[_tokens[index]],
                "Can not exchange custom clown"
            );
            IERC721(clownzContract).safeTransferFrom(
                msg.sender,
                address(this),
                _tokens[index]
            );
        }

        _safeMint(msg.sender, _tokens.length / exchangeRate);
    }

    function teamMint(address _to, uint256 _amount) external onlyOwner {
        _safeMint(_to, _amount);
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function withdraw(address _receiver, uint256 _amount) external onlyOwner {
        payable(_receiver).transfer(_amount);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @notice This contract is configured to use the DefaultOperatorFilterer, which automatically registers the
     *         token and subscribes it to OpenSea's curated filters. Adding the onlyAllowedOperator modifier to the
     *         transferFrom and both safeTransferFrom methods ensures that the msg.sender (operator) is allowed by the
     *         OperatorFilterRegistry. Adding the onlyAllowedOperatorApproval modifier to the approval methods ensures
     *         that owners do not approve operators that are not allowed.
     */

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}