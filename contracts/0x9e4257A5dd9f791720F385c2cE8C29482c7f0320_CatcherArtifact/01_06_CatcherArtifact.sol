// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CatcherArtifact is ERC721A,Ownable {
    using Strings for uint256;

    enum MintStatus {
        NOTACTIVE,
        ALLOWLIST_MINT,
        PUBLIC_MINT,
        CLOSED
    }

    MintStatus public mintStatus;

    string  public baseTokenURI;
    string  public defaultTokenURI;
    uint256 public maxSupply;
    uint256 public publicSalePrice;
    mapping(address => uint256) public usermint;

    constructor(
        string memory _baseTokenURI,
        uint   _maxSupply,
        uint   _publicSalePrice
    ) ERC721A ("Catcher Artifact", "CA") {
        baseTokenURI = _baseTokenURI;
        maxSupply = _maxSupply;
        publicSalePrice = _publicSalePrice;
        _safeMint(_msgSender(), 1);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Must from real wallet address");
        _;
    }

    function mint(uint256 _quantity) external callerIsUser payable   {
        require(mintStatus==MintStatus.PUBLIC_MINT, "Public sale closed");
        require(_quantity <= 20, "Invalid quantity");
        require(totalSupply() + _quantity <= maxSupply, "Exceed supply");

        uint256 _remainFreeQuantity = 0;
        if (0 > usermint[msg.sender] ) {
            _remainFreeQuantity = 0 - usermint[msg.sender];
        }

        uint256 _needPayPrice = 0;
        if (_quantity > _remainFreeQuantity) {
            _needPayPrice = (_quantity - _remainFreeQuantity) * publicSalePrice;
        }

        require(msg.value >= _needPayPrice, "Ether is not enough");
        usermint[msg.sender]+=_quantity;
        _safeMint(msg.sender, _quantity);
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return
        bytes(currentBaseURI).length > 0 ? string(
            abi.encodePacked(
                currentBaseURI,
                tokenId.toString(),
                ".json"
            )
        ) : defaultTokenURI;
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

    function setPublicPrice(uint256 mintprice) external onlyOwner {
        publicSalePrice = mintprice;
    }

    function setPublicMintStatus(uint256 status) external onlyOwner {
        mintStatus = MintStatus(status);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function marketMint(address[] memory marketmintaddress,uint256[] memory mintquantity) public payable onlyOwner  {
        for (uint256 i = 0; i < marketmintaddress.length; i++) {
            require(totalSupply() + mintquantity[i] <= maxSupply, "Exceed supply");
            _safeMint(marketmintaddress[i], mintquantity[i]);
        }
    }

    function withdrawMoney() external onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }
}