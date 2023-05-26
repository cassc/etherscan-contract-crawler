//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./RPRSmartWallet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract RektPepeRenaissance is ERC721A, Ownable, ReentrancyGuard {

    string private BASE_URI;
    uint256 public immutable freeMints;
    address public immutable smartWalletTemplate;
    struct SaleConfig {
        uint32 preSaleDuration;
        uint32 preSaleStartTime;
        uint64 seedPrice;
        uint64 preSalePrice;
        uint64 publicSalePrice;
    }

    SaleConfig public saleConfig;
    mapping(address => bool) public allowlist;
    mapping(address => bool) public rektOGs;

    event Mint(address indexed to, uint256 indexed quantity);

    modifier callerIsUser() {
        require(msg.sender == tx.origin, "Caller is another contract");
        _;
    }

    constructor(
        uint256 collectionSize_,
        uint256 maxBatchSize_,
        uint256 freeMints_,
        string memory baseUri_
    ) ERC721A("RektPepeRenaissance", "RPR", maxBatchSize_, collectionSize_) {
        freeMints = freeMints_;
        BASE_URI = baseUri_;
        RPRSmartWallet smartWallet = new RPRSmartWallet();
        smartWalletTemplate = address(smartWallet);
    }
    /*
        WARNING:    BURNING TOKENS WITH ASSETS REMAINING IN THEIR 
                    ASSOCIATED SMART WALLET WILL RESULT IN THE ASSETS BEING LOST FOREVER.
    */
    function burn(uint256 tokenId) external {
        bool isApprovedOrOwner = (_msgSender() == ownerOf(tokenId) ||
            getApproved(tokenId) == _msgSender() ||
            isApprovedForAll(ownerOf(tokenId), _msgSender()));

        require(isApprovedOrOwner, "You are not the owner or approved");
        _burn(tokenId);
    }
    function getPrice() public view returns (uint) {
        SaleConfig memory config = saleConfig;
        uint currentTime = block.timestamp;
        if (currentTime < config.preSaleStartTime) {
            return 0;
        } else if (currentTime < config.preSaleStartTime + config.preSaleDuration) {
            return config.preSalePrice;
        } else {
            return config.publicSalePrice;
        }
    }
    function seedRoundMint(uint256 quantity) external payable callerIsUser {
        uint256 price = saleConfig.seedPrice;
        require(price > 0, "Seed round not yet started");
        require(block.timestamp < uint256(saleConfig.preSaleStartTime), "seed round is over");
        require(quantity > 0, "Cannot mint 0 tokens");
        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        require(msg.value == price * quantity, "Incorrect funds");

        if (allowlist[msg.sender] || rektOGs[msg.sender]) {
            _safeMint(msg.sender, quantity);
        } else {
            revert("Attempting to mint more than allowed");
        }

        emit Mint(msg.sender, quantity);
    }
    function mint(uint256 quantity)
        external
        payable
        callerIsUser
    {
        uint256 price = getPrice();
        require(quantity > 0, "Cannot mint 0 tokens");
        require(price > 0, "Sale not yet started");
        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        if (rektOGs[msg.sender]) {
            price = saleConfig.seedPrice;
            require(msg.value == price * quantity, "Incorrect funds");
            _safeMint(msg.sender, quantity);
        } else {
            require(msg.value == price * quantity, "Incorrect funds");
            _safeMint(msg.sender, quantity);
        }

        emit Mint(msg.sender, quantity);
    }

    function setSaleConfig(
        uint32 preSaleDuration_,
        uint32 preSaleStartTime_,
        uint64 seedPriceWei_,
        uint64 preSalePriceWei_,
        uint64 publicSalePriceWei_
    ) external onlyOwner {
        saleConfig = SaleConfig(
            preSaleDuration_,
            preSaleStartTime_,
            seedPriceWei_,
            preSalePriceWei_,
            publicSalePriceWei_
        );
    }

    function seedAllowlist(address[] memory addresses)
        external
        onlyOwner
    {
        uint arrLength = addresses.length;
        for (uint256 i = 0; i < arrLength; ++i) {
            if (!rektOGs[addresses[i]]) {
               allowlist[addresses[i]] = true;
            }
       }
    }
    function seedRektOGs(address[] memory addresses)
        external
        onlyOwner
    {
        uint arrLength = addresses.length;
        for (uint256 i = 0; i < arrLength; ++i) {
            if (allowlist[addresses[i]]) {
                allowlist[addresses[i]] = false;
            }
            rektOGs[addresses[i]] = true;
        }
    }
    function isAllowlist() external view returns (bool) {
        return allowlist[msg.sender];
    }
    function isRektOG() external view returns (bool) {
        return rektOGs[msg.sender];
    }
    function devMint(uint256 quantity) external onlyOwner {
        require(
        totalSupply() + quantity <= freeMints,
        "too many already minted before dev mint"
        );
        require(
        quantity % maxBatchSize == 0,
        "can only mint a multiple of the maxBatchSize"
        );
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
        _safeMint(msg.sender, maxBatchSize);
        }
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }
    function withdrawCharity() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }
    function setBaseURI(string memory _new) external onlyOwner {
        BASE_URI = _new;
    }
    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    /*
        Smart Wallet Methods
    */

    function getWalletForTokenId(uint256 tokenId) private returns (RPRSmartWallet wallet) {
        wallet = RPRSmartWallet(Clones.cloneDeterministic(smartWalletTemplate, keccak256(abi.encode(tokenId))));
    }

    function getWalletAddressForTokenId(uint256 tokenId) public returns (address walletAddress) {
        walletAddress = Clones.cloneDeterministic(smartWalletTemplate, keccak256(abi.encode(tokenId)));
    }

    function withdrawEther(uint256 walletId) external callerIsUser {
        TokenOwnership memory ownership = ownershipOf(walletId);

        require(_msgSender() == ownership.addr, "Only the token owner can withdraw ether");

        getWalletForTokenId(walletId).withdrawEther(_msgSender());
    }

    function withdrawERC20(address _contract, uint256 amount, uint256 walletId) external callerIsUser {
        TokenOwnership memory ownership = ownershipOf(walletId);

        require(_msgSender() == ownership.addr, "Only the token owner can withdraw ERC20");

        getWalletForTokenId(walletId).withdrawERC20(_contract, amount, _msgSender());
    }

    function withdrawERC721(address _contract, uint256 tokenId, uint256 walletId) external callerIsUser {
        TokenOwnership memory ownership = ownershipOf(walletId);

        require(_msgSender() == ownership.addr, "Only the token owner can withdraw ERC721");

        getWalletForTokenId(walletId).withdrawERC721(_contract, tokenId, _msgSender());
    }
}