// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RecursivePunks is ERC721A, Ownable {
    string public baseURI;
    uint256 public constant MAX_PER_TX = 5;
    uint256 public constant MAX_PER_WALLET = 5;
    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public constant ROYALTY_FEE_PERCENT = 5;
    uint256 public priceInWei = 2000000000000000; // 0.002 eth
    bool public saleIsActive = false;

    constructor() ERC721A("RecursivePunks", "RPUNKS") {}

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setSale(bool _puS) public onlyOwner {
        saleIsActive = _puS;
    }

    function setTokenPrice(uint256 newPrice) external onlyOwner {
        require(
            newPrice <= priceInWei,
            "Token price must be lesser than initial price"
        );
        priceInWei = newPrice;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    function mint(uint256 count) public payable {
        require(saleIsActive, "Sale not on");
        require(totalSupply() + count <= MAX_SUPPLY, "Exceeds max supply");
        require(
            numberMinted(msg.sender) + count <= MAX_PER_WALLET,
            "Exceeds max per wallet"
        );
        require(count <= MAX_PER_TX, "Exceeds max per transaction.");
        require(
            count * priceInWei == msg.value,
            "Incorrect amount of funds provided."
        );
        _safeMint(msg.sender, count);
    }

    function royaltyInfo(uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        receiver = owner();
        royaltyAmount = (_salePrice * ROYALTY_FEE_PERCENT) / 100;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= totalSupply()
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}