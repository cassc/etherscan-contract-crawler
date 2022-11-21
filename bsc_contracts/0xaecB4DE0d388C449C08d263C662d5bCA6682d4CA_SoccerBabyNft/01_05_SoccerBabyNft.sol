// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SoccerBabyNft is ERC721A, Ownable {

    enum MintStatus {
        NOTACTIVE,
        WHITELIST_MINT,
        PUBLIC_MINT,
        CLOSED
    }

    MintStatus public launchMintStatus;
    string  public baseTokenURI;
    string  public defaultTokenURI;
    uint256 public maxSupply = 10000;
    uint256 public publicSalePrice;
    uint256 public publicSaleTokenPrice = 10000 ether;

    mapping(address => uint256) public usermint;
    address public tokenContract=0xFBb105E4a9Ef7c7dA66a278b57D047EC0b3E033b;
    address private _deadAddress = 0x0000000000000000000000000000000000000000;

    constructor() ERC721A ("Soccer Baby", "SocBaby") {
        _safeMint(msg.sender, 1);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Must from real wallet address");
        _;
    }

    function SoccerBabyMint(uint256 _quantity) external callerIsUser payable {
        require(launchMintStatus == MintStatus.PUBLIC_MINT, "Public sale closed");
        require(_quantity <= 10, "Invalid quantity");
        require(totalSupply() + _quantity <= maxSupply, "Exceed supply");

        uint256 _remainFreeQuantity = 0;
        uint256 _needPayPrice = 0;
        if (_quantity > _remainFreeQuantity) {
            _needPayPrice = (_quantity - _remainFreeQuantity) * publicSalePrice;
        }

        require(msg.value >= _needPayPrice, "Ether is not enough");
        _safeMint(msg.sender, _quantity);
    }

    function SoccerBabyMintBySocBaby(uint256 _quantity) external callerIsUser payable {
        require(launchMintStatus == MintStatus.PUBLIC_MINT, "Public sale closed");
        require(_quantity <= 10, "Invalid quantity");
        require(totalSupply() + _quantity <= maxSupply, "Exceed supply");
        uint256 amounts = publicSaleTokenPrice * _quantity;
        (bool success,) = tokenContract.call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)",msg.sender, _deadAddress, amounts)
        );
        require(success, "call failed");

        _safeMint(msg.sender, _quantity);
    }

    function getHoldTokenIdsByOwner(address _owner) public view returns (uint256[] memory) {
        uint256 index = 0;
        uint256 hasMinted = _totalMinted();
        uint256 tokenIdsLen = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenIdsLen);

        for (uint256 tokenId = 1; index < tokenIdsLen && tokenId <= hasMinted; tokenId++) {
            if (_owner == ownerOf(tokenId)) {
                tokenIds[index] = tokenId;
                index++;
            }
        }

        return tokenIds;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : defaultTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }


    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setDefaultURI(string calldata _defaultURI) external onlyOwner {
        defaultTokenURI = _defaultURI;
    }

    function setPublicPrice(uint256 _mintpublicprice) external onlyOwner {
        publicSalePrice = _mintpublicprice;
    }

    function setPublicSaleTokenPrice(uint256 _mintpublicSaleTokenPrice) external onlyOwner {
        publicSaleTokenPrice = _mintpublicSaleTokenPrice;
    }

    function setPublicMintStatus(uint256 _status) external onlyOwner {
        launchMintStatus = MintStatus(_status);
    }

    function setTokenContract(address _tokenContract) external onlyOwner {
        tokenContract = _tokenContract;
    }

    function airdrop(address[] memory _marketmintaddress, uint256[] memory _mintquantity) public payable onlyOwner {
        for (uint256 i = 0; i < _marketmintaddress.length; i++) {
            require(totalSupply() + _mintquantity[i] <= maxSupply, "Exceed supply");
            _safeMint(_marketmintaddress[i], _mintquantity[i]);
        }
    }

    function withdraw() external onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawToken(uint256 amount) external onlyOwner {
        (bool success,) = tokenContract.call(
            abi.encodeWithSignature("transfer(address,uint256)", payable(msg.sender), amount)
        );
        require(success, "call failed");
    }

    receive() external payable {}

}