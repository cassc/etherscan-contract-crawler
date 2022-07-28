// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol"; 
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 
contract OwnableDelegateProxy {}
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract ForrestofShrooms is ERC721A, Ownable, ReentrancyGuard {
    address private constant _creator1 = 0xCdED17895b2016384c51A86A665613C5B9804398;
    address private constant _creator2 = 0x2Ce26CBE3d78CC01e983668453efEf8742543E8f;
    address private constant _creator3 = 0x62c1fd1eC4C863cAb668bA4087B0A5511Dda1fd8;

    using MerkleProof for bytes32[];
    string public baseExtension = ".json";

    string private _baseTokenURI;
    bytes32 private _claimMerkleRoot;
    bool private _saleStatus = false;
    uint256 private _salePrice = 0.015 ether;
    uint256 private _discountPrice = 0.001 ether;

    uint256 private MAX_MINTS_PER_TX = 3;
	
    uint256 public MAX_SUPPLY = 6666;
    uint256 public FREE_SUPPLY = 500;
	

    constructor() ERC721A("ForrestofShrooms", "FoS") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier verify(
        address account,
        bytes32[] calldata merkleProof,
        bytes32 merkleRoot
    ) {
        require(
            merkleProof.verify(
                merkleRoot,
                keccak256(abi.encodePacked(account))
            ),
            "Address not listed"
        );
        _;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }


    function setMaxMintPerTx(uint256 maxMint) external onlyOwner {
        MAX_MINTS_PER_TX = maxMint;
    }

    function setSalePrice(uint256 price) external onlyOwner {
        _salePrice = price;
    }

    function setDiscountPrice(uint256 price) external onlyOwner {
        _discountPrice = price;
    }
    
    function setFreeSupply(uint256 newSupply) external onlyOwner {
        if (newSupply >= FREE_SUPPLY) {
            revert("New supply exceed previous free supply");
        }
        FREE_SUPPLY = newSupply;
    }

    function toggleSaleStatus() external onlyOwner {
        _saleStatus = !_saleStatus;
    }
    

    function withdrawAll() external onlyOwner {
        uint256 amountToCreator2 = (address(this).balance * 330) / 1000; // 33%
        uint256 amountToCreator3 = (address(this).balance * 330) / 1000; // 33%

        withdraw(_creator2, amountToCreator2);
        withdraw(_creator3, amountToCreator3);

        uint256 amountToCreator1 = address(this).balance; // ~33%
        withdraw(_creator1, amountToCreator1);
    }

    function withdraw(address account, uint256 amount) internal {
        (bool os, ) = payable(account).call{value: amount}("");
        require(os, "Failed to send ether");
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721AMetadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), baseExtension))
        : "";
  }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

      function isApprovedForAll(address owner, address operator) public override view returns (bool) {
        

        return super.isApprovedForAll(owner, operator);
    }

    function saleMint(uint256 quantity)
        external
        payable
        nonReentrant
        callerIsUser
    {
        if (!isSaleActive()) revert("Sale not started");
        if (quantity > MAX_MINTS_PER_TX)
            revert("Amount exceeds transaction limit");
        if (totalSupply() + quantity > (MAX_SUPPLY - FREE_SUPPLY))
            revert("Amount exceeds supply");
        if (getSalePrice() * quantity > msg.value)
            revert("Insufficient payment");

        _safeMint(msg.sender, quantity);
    }

    function discountMint(uint256 quantity)
        external
        payable
        nonReentrant
        callerIsUser
    {
        if (!isSaleActive()) revert("Sale not started");
        if (quantity > MAX_MINTS_PER_TX)
            revert("Amount exceeds transaction limit");
        if (totalSupply() + quantity > (MAX_SUPPLY - FREE_SUPPLY))
            revert("Amount exceeds supply");
        if (quantity < 2 )
            revert("Not enough for Discount");
            if (quantity > 3 )
            revert("Too much for Discount");
        if (getDiscountPrice() * quantity > msg.value)
            revert("Insufficient payment");

        _safeMint(msg.sender, quantity);
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 0;
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

    function mintToAddress(address to, uint256 quantity) external onlyOwner {
        if (totalSupply() + quantity > (MAX_SUPPLY - FREE_SUPPLY))
            revert("Amount exceeds supply");

        _safeMint(to, quantity);
    }

    function isSaleActive() public view returns (bool) {
        return _saleStatus;
    }

    function getSalePrice() public view returns (uint256) {
        return _salePrice;
    }

    function getDiscountPrice() public view returns (uint256) {
        return _discountPrice;
    }

}