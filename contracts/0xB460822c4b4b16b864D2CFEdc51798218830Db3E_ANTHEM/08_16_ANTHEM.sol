// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "erc721a/contracts/ERC721A.sol";
import "./lib/rarible/royalties/contracts/LibPart.sol";
import "./lib/rarible/royalties/contracts/LibRoyaltiesV2.sol";
import "./lib/rarible/royalties/contracts/RoyaltiesV2.sol";

import {DefaultOperatorFilterer} from "./lib/OpenSea/DefaultOperatorFilterer.sol";

contract ANTHEM is ERC721A, DefaultOperatorFilterer, Ownable, ReentrancyGuard, RoyaltiesV2 {
    mapping(address => uint256) public whiteLists;

    uint256 private _whiteListCount;

    uint256 public tokenAmount = 0;
    uint256 public privateMintPrice;
    uint256 public publicMintPrice;

    bool public startPrivateSale = false;
    bool public startPublicSale = false;

    bool public revealed = false;

    uint256 private _maxPublicMintPerTx;

    uint256 private _totalSupply;
    string private _beforeTokenURI;
    string private _afterTokenPath;

    mapping(address => uint256) public privateMinted;

    // Royality management
    bytes4 public constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    address payable public defaultRoyaltiesReceipientAddress;
    uint96 public defaultPercentageBasisPoints = 1000; // 10%

    constructor(uint256 initTotalSupply, uint256 initMuxPublicPerTx) ERC721A("ANTHEM", "ANTHEM") {
        _totalSupply = initTotalSupply;
        _maxPublicMintPerTx = initMuxPublicPerTx;
        defaultRoyaltiesReceipientAddress = payable(msg.sender);
    }

    function ownerMint(uint256 amount, address _address) external onlyOwner {
        require((amount + tokenAmount) <= (_totalSupply), "mint failure");

        _safeMint(_address, amount);
        tokenAmount += amount;
    }

    function privateMint(uint256 amount) external payable nonReentrant {
        require(startPrivateSale, "sale: Paused");
        require(
            whiteLists[msg.sender] >= privateMinted[msg.sender] + amount,
            "You have reached your mint limit"
        );

        require(msg.value == privateMintPrice * amount, "Incorrect amount of ETH sent");
        require((amount + tokenAmount) <= (_totalSupply), "mint failure");

        privateMinted[msg.sender] += amount;
        _safeMint(msg.sender, amount);
        tokenAmount += amount;
    }

    function publicMint(uint256 amount) external payable nonReentrant {
        require(startPublicSale, "sale: Paused");
        require(_maxPublicMintPerTx >= amount, "Exceeds max mints per tx");
        require(msg.value == publicMintPrice * amount, "Incorrect amount of ETH sent");
        require((amount + tokenAmount) <= (_totalSupply), "mint failure");

        _safeMint(msg.sender, amount);
        tokenAmount += amount;
    }

    function setPrivateMintPrice(uint256 newPrice) external onlyOwner {
        privateMintPrice = newPrice;
    }

    function setPublicMintPrice(uint256 newPrice) external onlyOwner {
        publicMintPrice = newPrice;
    }

    function setReveal(bool bool_) external onlyOwner {
        revealed = bool_;
    }

    function setStartPrivateSale(bool bool_) external onlyOwner {
        startPrivateSale = bool_;
    }

    function setStartPublicSale(bool bool_) external onlyOwner {
        startPublicSale = bool_;
    }

    function setBeforeURI(string memory beforeTokenURI_) external onlyOwner {
        _beforeTokenURI = beforeTokenURI_;
    }

    function setAfterURI(string memory afterTokenPath_) external onlyOwner {
        _afterTokenPath = afterTokenPath_;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (revealed == false) {
            return _beforeTokenURI;
        } else {
            return string(abi.encodePacked(_afterTokenPath, Strings.toString(tokenId), ".json"));
        }
    }

    function deleteWL(address addr) external onlyOwner {
        _whiteListCount = _whiteListCount - whiteLists[addr];
        delete (whiteLists[addr]);
    }

    function upsertWL(address addr, uint256 maxMint) external onlyOwner {
        _whiteListCount = _whiteListCount - whiteLists[addr];
        whiteLists[addr] = maxMint;
        _whiteListCount += maxMint;
    }

    function pushMultiWLSpecifyNum(address[] memory list, uint256 num) external onlyOwner {
        for (uint256 i = 0; i < list.length; i++) {
            whiteLists[list[i]] += num;
        }
        _whiteListCount += list.length * num;
    }

    function getWLCount() external view returns (uint256) {
        return _whiteListCount;
    }

    function getWL(address _address) external view returns (uint256) {
        if (whiteLists[_address] < privateMinted[msg.sender]) {
            return (0);
        }
        return whiteLists[_address] - privateMinted[msg.sender];
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setTotalSupply(uint256 newTotalSupply) external onlyOwner {
        _totalSupply = newTotalSupply;
    }

    function setMaxPublicMintPerTx(uint256 newMaxPublicMintPerTx) external onlyOwner {
        _maxPublicMintPerTx = newMaxPublicMintPerTx;
    }

    /**
     * @dev disable Ownable renounceOwnership
     */
    function renounceOwnership() public override onlyOwner {}

    /**
     * @dev do withdraw eth.
     */
    function withdrawETH() external virtual onlyOwner {
        uint256 royalty = address(this).balance;

        Address.sendValue(payable(owner()), royalty);
    }

    /**
     * @dev ERC20s should not be sent to this contract, but if someone
     * does, it's nice to be able to recover them
     * @param token IERC20 the token address
     * @param amount uint256 the amount to send
     */
    function forwardERC20s(IERC20 token, uint256 amount) external onlyOwner {
        token.transfer(msg.sender, amount);
    }

    // Royality management
    /**
     * @dev set defaultRoyaltiesReceipientAddress
     * @param _defaultRoyaltiesReceipientAddress address New royality receipient address
     */
    function setDefaultRoyaltiesReceipientAddress(
        address payable _defaultRoyaltiesReceipientAddress
    ) external onlyOwner {
        defaultRoyaltiesReceipientAddress = _defaultRoyaltiesReceipientAddress;
    }

    /**
     * @dev set defaultPercentageBasisPoints
     * @param _defaultPercentageBasisPoints uint96 New royality percentagy basis points
     */
    function setDefaultPercentageBasisPoints(uint96 _defaultPercentageBasisPoints)
        external
        onlyOwner
    {
        defaultPercentageBasisPoints = _defaultPercentageBasisPoints;
    }

    /**
     * @dev return royality for Rarible
     */
    function getRaribleV2Royalties(uint256) external view override returns (LibPart.Part[] memory) {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = defaultPercentageBasisPoints;
        _royalties[0].account = defaultRoyaltiesReceipientAddress;
        return _royalties;
    }

    /**
     * @dev return royality in EIP-2981 standard
     * @param _salePrice uint256 sales price of the token royality is calculated
     */
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (
            defaultRoyaltiesReceipientAddress,
            (_salePrice * defaultPercentageBasisPoints) / 10000
        );
    }

    /**
     * @dev Interface
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721A) returns (bool) {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    // operator-filter-registry
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