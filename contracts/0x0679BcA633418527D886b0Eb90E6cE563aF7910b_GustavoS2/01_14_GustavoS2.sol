// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract GustavoS2 is ERC721, IERC2981, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;

    constructor(string memory customBaseURI_, address accessTokenAddress_)
        ERC721("GustavoS2", "GUSTS2")
    {
        customBaseURI = customBaseURI_;

        accessTokenAddress = accessTokenAddress_;
    }

    address public immutable accessTokenAddress;

    uint256 public constant MAX_SUPPLY = 1555;

    uint256 public constant MAX_TOKEN_ID = 2000;

    uint256 public cost = 30000000000000000;

    Counters.Counter private supplyCounter;

    function mint(uint256 id) public payable nonReentrant {
        require(saleIsActive, "Sale not active!");

        require(totalSupply() < MAX_SUPPLY, "Exceeds max supply");

        require(msg.value >= cost, "Insufficient payment");

        ERC721 accessToken = ERC721(accessTokenAddress);

        require(id < MAX_SUPPLY, "Invalid token id");

        if (accessTokenIsActive) {
            require(
                accessToken.balanceOf(msg.sender) > 0,
                "Access token not owned"
            );
        }

        _mint(msg.sender, id);

        supplyCounter.increment();
    }

    function totalSupply() public view returns (uint256) {
        return supplyCounter.current();
    }

    bool public saleIsActive = true;

    function setSaleIsActive(bool saleIsActive_) external onlyOwner {
        saleIsActive = saleIsActive_;
    }

    bool public accessTokenIsActive = true;

    function setAccessTokenIsActive(bool accessTokenIsActive_)
        external
        onlyOwner
    {
        accessTokenIsActive = accessTokenIsActive_;
    }

    string private customBaseURI;

    mapping(uint256 => string) private tokenURIMap;

    function setTokenURI(uint256 tokenId, string memory tokenURI_)
        external
        onlyOwner
    {
        tokenURIMap[tokenId] = tokenURI_;
    }

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        customBaseURI = customBaseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory tokenURI_ = tokenURIMap[tokenId];

        if (bytes(tokenURI_).length > 0) {
            return tokenURI_;
        }

        return string(abi.encodePacked(super.tokenURI(tokenId)));
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function withdraw() public nonReentrant {
        uint256 balance = address(this).balance;

        Address.sendValue(payable(owner()), balance);
    }

    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), (salePrice * 500) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId));
    }
}