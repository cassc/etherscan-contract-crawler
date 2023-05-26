// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./erc721A.sol";

//ipfs://QmaS3xioHXmpMvsyiqxSurv5JaffxkMRDQQo9tjVYikYr3

contract UniweiOGPass is ERC721A , Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    using Strings for uint256;

    enum Status {
        Pending,
        PublicSale,
        Finished
    }

    Status public status;
    string public baseURI;
    uint256 public immutable maxMint;
    uint256 public immutable maxSupply;
    uint256 public PRICEINETH = 0.2 ether; 
    uint256 public PRICEINORDI = 50000 * 10 ** 18;
    address public ORDIAddress;
    bool public isReveal;

    event Minted(address minter, uint256 amount);
    event StatusChanged(Status status);
    event ReservedToken(address minter, address recipient, uint256 amount);
    event BaseURIChanged(string newBaseURI);

    constructor(
        string memory initBaseURI,
        uint256 _maxBatchSize,
        uint256 _collectionSize,
        address _ordi
    ) ERC721A("UniweiOGPass", "UniweiOGPass", _maxBatchSize, _collectionSize) {
        baseURI = initBaseURI;
        maxMint = _maxBatchSize;
        maxSupply = _collectionSize;
        ORDIAddress = _ordi;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }    
    
    function mintwithETH(uint256 amount) external payable {
        require(status == Status.PublicSale, "UniweiOGPass: Public sale is not active.");
        require(
            tx.origin == msg.sender,
            "UniweiOGPass: contract is not allowed to mint."
        );
        require(
            totalSupply() + amount  <=
                collectionSize,
            "UniweiOGPass: Max supply exceeded."
        );

        _safeMint(msg.sender, amount);
        refundIfOver(PRICEINETH);

        emit Minted(msg.sender, amount);
    }

    function mintwithORDI(uint256 amount) external {
        IERC20 ORDI = IERC20(ORDIAddress);
        require(status == Status.PublicSale, "UniweiOGPass: Public sale is not active.");
        require(
            tx.origin == msg.sender,
            "UniweiOGPass: contract is not allowed to mint."
        );
        require(
            totalSupply() + amount <=
                collectionSize,
            "UniweiOGPass: Max supply exceeded."
        );
        require(ORDI.balanceOf(msg.sender) >=  PRICEINORDI * amount, "Not enough balance to complete transaction.");

        for (uint256 i = 1; i <= amount; i++) {
            ORDI.transferFrom(msg.sender, address(this), PRICEINORDI);
            _safeMint(msg.sender, amount);
        }
        
        emit Minted(msg.sender, amount);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "UniweiOGPass: Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function reveal(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        isReveal = true;
        emit BaseURIChanged(newBaseURI);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory){
            require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return isReveal?
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "" : currentBaseURI;

    }

    function withdraw() external nonReentrant onlyOwner {
        uint256 balance = address(this).balance;
        (bool success1, ) = payable(msg.sender)
            .call{value: balance}("");
        require(success1, "Transfer 1 failed.");
    }

    function withdrawORDI() external nonReentrant onlyOwner {
        IERC20 ORDI = IERC20(ORDIAddress);
        uint256 balanceORDI = ORDI.balanceOf(address(this));
        ORDI.transfer(msg.sender, balanceORDI);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
        emit StatusChanged(_status);
    }

    function setOwnersExplicit(uint256 quantity)
        external
        onlyOwner
        nonReentrant
    {
        _setOwnersExplicit(quantity);
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
}