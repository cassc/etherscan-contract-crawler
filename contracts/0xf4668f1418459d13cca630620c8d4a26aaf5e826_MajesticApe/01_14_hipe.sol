// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./OperatorFilter/DefaultOperatorFilterer.sol";

error Reverts(uint8 code);

contract MajesticApe is 
    ERC721AQueryable,
    Ownable,
    ERC2981,
    DefaultOperatorFilterer
{

    bool public isRevealed = false;
    uint256 public collectionSize;
    uint256 public maxBatchSize;
    uint256 public amountForDevs;
    uint256 private withdrawnSoFar;

    struct WhitelistSaleConfig {
    uint32 startTime;
    uint64 price;
    uint64 maxPerAddress;
    }

    WhitelistSaleConfig public whitelistSaleConfig;

    struct PublicSaleConfig {
        uint32 startTime;
        uint64 price;
        uint64 maxPerAddress;
    }

    PublicSaleConfig public publicSaleConfig;

    string private _baseTokenURI;
    string private _defaultTokenURI;

    event PausedX();
    event UnpausedX();
    event WhitelistSaleSetup(uint32 whitelistSaleStartTime_, uint64 whitelistSalePriceWei_, uint64 maxPerAddressDuringWhitelistSaleMint);
    event WhiteListMint(address indexed to, uint256 quantity, uint256 totalSupply);
    event PublicSaleActivated(uint32 publicSaleStartTime_, uint64 publicSalePriceWei_, uint64 maxPerAddressDuringPublicSaleMint);
    event Mint(address indexed to, uint256 quantity, uint256 totalSupply);
    event RevealSet(bool status);
    event BaseUriSet(string baseTokenUri_);
    event DefaultTokenUriSet(string DefaultTokenUri_);
    event CollectionSizeSet(uint256 size_);
    event FundsWithdrawn(uint256 toDonation, uint256 txToThirty, uint256 txToOwner);

    constructor(
        uint256 collectionSize_,
        uint256 maxBatchSize_,
        uint256 amountForDevs_
    ) ERC721A("Majestic Ape", "MAPE") {
        collectionSize = collectionSize_;
        maxBatchSize = maxBatchSize_;
        amountForDevs = amountForDevs_;
    }

    modifier callerIsUser() {
        if (tx.origin != msg.sender) {
            revert Reverts(1);
        }
        _;
    }

    function refundIfOver(uint256 price) private {
        if (msg.value < price) {
            revert Reverts(2);
        }

        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC721A, ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);  
    }

    function setupWhitelistSale(
        uint32 whitelistSaleStartTime,
        uint64 whitelistSalePriceWei,
        uint64 maxPerAddressDuringWhitelistSaleMint
    ) external onlyOwner {
        whitelistSaleConfig.startTime = whitelistSaleStartTime;
        whitelistSaleConfig.price = whitelistSalePriceWei;
        whitelistSaleConfig.maxPerAddress = maxPerAddressDuringWhitelistSaleMint;
        emit WhitelistSaleSetup(whitelistSaleConfig.startTime, whitelistSaleConfig.price, whitelistSaleConfig.maxPerAddress);
    }
        
    function whitelistSaleMint(uint64 quantity)
        external
        payable
        callerIsUser
    {
        uint256 price = uint256(whitelistSaleConfig.price);
        uint256 saleStartTime = uint256(whitelistSaleConfig.startTime);
        uint64 maxPerAddress = whitelistSaleConfig.maxPerAddress;

        // if (price == 0) {
        //     revert Reverts(3);
        // }
        if (saleStartTime == 0 || block.timestamp < saleStartTime) {
            revert Reverts(3);
        }

        if (totalSupply() + quantity > collectionSize) {
            revert Reverts(4);
        }

        if (_getAux(_msgSender()) + quantity > maxPerAddress) {
            revert Reverts(5);
        }

        _safeMint(_msgSender(), quantity);
        _setAux(_msgSender(), _getAux(_msgSender()) + quantity); 
        refundIfOver(price * quantity);
        emit WhiteListMint(_msgSender(), quantity, totalSupply());
    }

    function devMint(uint256 quantity) external onlyOwner {
        if (quantity % maxBatchSize != 0) {
            // revert IncompatibleBatchSize();
            revert Reverts(6);
        }
        
        uint256 numChunks = quantity / maxBatchSize;
        for(uint256 i = 0; i < numChunks; i++) {
        _safeMint(msg.sender, maxBatchSize);
        }
    }
    
    function endWhitelistSaleAndSetupPublicSale(
        uint32 publicSaleStartTime,
        uint64 publicSalePriceWei,
        uint64 maxPerAddressDuringPublicSaleMint
    ) external onlyOwner {
        whitelistSaleConfig.startTime = 0;

        publicSaleConfig.startTime = publicSaleStartTime;
        publicSaleConfig.price = publicSalePriceWei;
        publicSaleConfig.maxPerAddress = maxPerAddressDuringPublicSaleMint;
        emit PublicSaleActivated(publicSaleConfig.startTime, publicSaleConfig.price, publicSaleConfig.maxPerAddress);
    }
    

    function publicSaleMint(uint64 quantity)
        external
        payable
        callerIsUser
        //nonReentrant
    {
        uint256 price = uint256(publicSaleConfig.price);
        uint256 startTime = uint256(publicSaleConfig.startTime);
        uint64 maxPerAddress = publicSaleConfig.maxPerAddress;

        if (price == 0) {
            revert Reverts(7);
        }
        if (startTime == 0 || block.timestamp < startTime) {
            revert Reverts(7);
        }
        
        if (totalSupply() + quantity > collectionSize) {
            revert Reverts(4);
        }

        if (_numberMinted(_msgSender()) - _getAux(_msgSender()) + quantity > maxPerAddress) {
            revert Reverts(8);
        }
        
        _safeMint(msg.sender, quantity);
        refundIfOver(price * quantity);
        emit Mint(msg.sender, quantity, totalSupply());
    }
        
    function setIsRevealed(bool val) external onlyOwner {
        isRevealed = val;
        emit RevealSet(isRevealed);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        if (isRevealed) {
        return super.tokenURI(tokenId);
        }

        require(tokenId <= totalSupply(), "token not exist");
        return _defaultTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
        emit BaseUriSet(_baseTokenURI);
    }
        
    function setDefaultTokenURI(string calldata uri) external onlyOwner {
        _defaultTokenURI = uri; 
        emit DefaultTokenUriSet(_defaultTokenURI);
    }

    function setCollectionSize(uint256 size) external onlyOwner {
        collectionSize = size;
        emit CollectionSizeSet(collectionSize);
    }

    function getContractStatus() external view returns (uint32, uint64, uint64, uint32, uint64, uint64) {
        return (whitelistSaleConfig.startTime, whitelistSaleConfig.price, whitelistSaleConfig.maxPerAddress, publicSaleConfig.startTime, publicSaleConfig.price, publicSaleConfig.maxPerAddress);
    }

    function getTokenInfo() external view returns (string memory, string memory) {
        return (_baseTokenURI, _defaultTokenURI);
    }

    function totalFunds() external view returns (uint256, uint256) {
        return (address(this).balance, withdrawnSoFar);
    }

    function setApprovalForAll(address operator, bool approved) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable  override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function withdrawMoney() external onlyOwner {
        address  donationWallet = 0x597B15dBEa7322A3fd1E51E28DAF539380305C4A;
        address  developersWallet = 0xdB0CC38DAC5A1494478cF4618B8Ff69Af64742DB;
            
        uint256 donationAmount = address(this).balance * 1/100;
        uint256 developersAmount = address(this).balance * 30/100;
            
        payable(donationWallet).transfer(donationAmount);      
        payable(developersWallet).transfer(developersAmount);
            
        uint256 balanceB4Tx = address(this).balance;
        payable(msg.sender).transfer(address(this).balance);
        withdrawnSoFar += donationAmount + developersAmount + balanceB4Tx;
        emit FundsWithdrawn(donationAmount, developersAmount, balanceB4Tx);
    }

}