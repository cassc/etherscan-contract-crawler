// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/IERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BoxcatWhitelist is Ownable, ERC721A {
    uint256 public immutable collectionSize = 10000;

    // metadata URI
    mapping(uint256 => string) _baseTokenURI;
    mapping(uint256 => address) public nftContract;

    mapping(uint256 => uint256) public tokenType;

    constructor() ERC721A("Boxcat Medal", "BCM") {}

    // Public Mint
    // *****************************************************************************
    // Public Functions
    function mint(uint256 quantity, uint256 index) public {
        require(msg.sender == tx.origin, "Cannot mint by contract");
        require(
            totalSupply() + quantity <= collectionSize,
            "Reached max supply"
        );
        require(
            nftContract[index] != address(0),
            "Contract address not set yet"
        );
        IERC721A forgingContract = IERC721A(nftContract[index]);
        require(
            (numberMinted(msg.sender) + quantity) <=
                forgingContract.balanceOf(msg.sender),
            "Cannot mint more than Nft you hold"
        );
        for(uint256 i = 0; i < quantity; i++) {
            tokenType[totalSupply() + i] = index;
        }
        _mint(msg.sender, quantity);
    }

    // Public Views
    // *****************************************************************************
    function numberMinted(address user) public view returns (uint256) {
        return _numberMinted(user);
    }

    function available(address user, uint256 index) public view returns (uint256) {
        IERC721A forgingContract = IERC721A(nftContract[index]);
        return forgingContract.balanceOf(user) - _numberMinted(user);
    }

    // Owner Controls

    // Contract Controls (onlyOwner)
    // *****************************************************************************
    function setBaseURI(string calldata baseURI, uint256 index) external onlyOwner {
        _baseTokenURI[index] = baseURI;
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setNftContract(address _nftContract, uint256 index) external onlyOwner {
        nftContract[index] = _nftContract;
    }

    // Internal Functions
    // *****************************************************************************

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI[0];
    }

    function _baseURI(uint256 tokenId) internal view returns (string memory) {
        return _baseTokenURI[tokenType[tokenId]];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = _baseURI(tokenId);
        return
            bytes(base).length > 0
                ? string(abi.encodePacked(base, Strings.toString(tokenId)))
                : "";
    }
}