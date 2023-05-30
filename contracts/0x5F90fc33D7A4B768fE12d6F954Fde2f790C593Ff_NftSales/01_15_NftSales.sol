//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NftSales is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    Counters.Counter public _tokenIds;

    address[] public Admins;
    mapping(address => bool) public AdminByAddr;
    uint256 public maxNftPerWalletAddress = 10;
    uint256 public maxNftPerWhitelistWalletAddress = 3;
    uint256 public staticPrice = 150000000000000000; // 0.15 ETH
    uint256 public maxNftsPerMint = 3;
    uint256 public maxWhiteSaleMints = 3500;
    uint256 public whiteSaleMints;
    mapping(address => bool) public isWhiteListed;
    uint public whitelistCount;
    address public treasuryAddress = 0xCCB346580Bcb2BE9bB9335f9e578aD1a8dee4b51;
    bool public whiteSaleActive;
    bool public publicSaleActive;
    uint public maxNfts = 10000;

    string public uri = "https://moonboots.mypinata.cloud/ipfs/QmQ8Ua8Jwa9KxjcHsDPQvx5yWnxKePYstqPq3DAox1bFab";
    bool public usePlaceholderUri = true;

    modifier onlyAdmin() {
        require(AdminByAddr[_msgSender()] == true || _msgSender() == owner(), "onlyAdmin");
        _;
    }

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_){
        AdminByAddr[0x8425f3b97D528a2586275B4e18eaf6aDCd695158] = true;
        Admins = [0x8425f3b97D528a2586275B4e18eaf6aDCd695158];
    }

    function setMaxNftPerWalletAddress(uint256 amount_) external onlyAdmin {
        require(amount_ > 0, "amount_ = 0");
        maxNftPerWalletAddress = amount_;
    }

    function setMaxNftPerWhitelistWalletAddress(uint256 amount_) external onlyAdmin {
        require(amount_ > 0, "amount_ = 0");
        maxNftPerWhitelistWalletAddress = amount_;
    }

    function setMaxNftsPerMint(uint256 _maxNftsPerMint) external onlyAdmin {
        maxNftsPerMint = _maxNftsPerMint;
    }

    function setMaxWhiteSaleMints(uint256 _maxWhiteSaleMints) external onlyAdmin {
        maxWhiteSaleMints = _maxWhiteSaleMints;
    }

    function setTreasuryAddress(address walletAddress_) external onlyOwner {
        require(walletAddress_ != address(0), "Error : treasury address set to 0");
        treasuryAddress = walletAddress_;
    }

    function setStaticPrice(uint256 _price) external onlyAdmin {
        staticPrice = _price;
    }

    function setWhiteSaleActive(bool isActive_) external onlyAdmin {
        whiteSaleActive = isActive_;
        emit SetWhiteSaleActive(isActive_, block.timestamp);
    }

    function setPublicSaleActive(bool isActive_) external onlyAdmin {
        publicSaleActive = isActive_;
        whiteSaleActive = isActive_ ? false : whiteSaleActive;
        emit SetPublicSaleActive(isActive_, block.timestamp);
    }

    function addAddressTowhitelistAddress(address[] memory _addresses) external onlyAdmin {
        require(_addresses.length > 0, "No addresses");
        for (uint256 i = 0; i < _addresses.length; i++) {
            isWhiteListed[_addresses[i]] = true;
            whitelistCount++;
            emit AddedToWhiteList(_addresses[i]);
        }
    }

    function removeAddressFromWhitelist(address _address) external onlyAdmin {
        require(isWhiteListed[_address] == true, "Address is not whitelisted");
        isWhiteListed[_address] = false;
        whitelistCount--;
        emit RemovedFromWhiteList(_address);
    }

    function mintWhiteSale(uint amount_) public payable {
        require(isWhiteListed[_msgSender()] == true && whiteSaleActive == true,"Whitelist sales not active or address not whitelisted");
        require(whiteSaleMints + amount_ <= maxWhiteSaleMints, "Max whitelist mints would be exceeded.");
        require(_tokenIds.current() + amount_ <= maxNfts, "Max NFTs would be exceeded");
        require(msg.value >= amount_ * staticPrice, "ETH send is less then required");
        require(amount_ <= maxNftsPerMint, "Max NFTs per mint would be exceeded");
        require(balanceOf(_msgSender()) + amount_ <= maxNftPerWhitelistWalletAddress, "User cannot mint more NFTs to a whitelist wallet");
        for (uint256 i = 0; i < amount_; i++) {
            _tokenIds.increment();
            _mint(_msgSender(), _tokenIds.current());
        }
        whiteSaleMints += amount_;
        emit MintWhiteSale(_msgSender(), amount_);
    }

    function mintPublicSale(uint amount_) public payable {
        require(publicSaleActive == true, "Public sale has not started");
        require(msg.value >= amount_ * staticPrice, "ETH send is less then required");
        require(_tokenIds.current() + amount_ <= maxNfts, "Max NFTs would be exceeded");
        require(amount_ <= maxNftsPerMint, "Max NFTs per mint would be exceeded");
        require(balanceOf(_msgSender()) + amount_ <= maxNftPerWalletAddress, "Max NFT wallet balance would be exceeded");
        for (uint256 i = 0; i < amount_; i++) {
            _tokenIds.increment();
            _mint(_msgSender(), _tokenIds.current());
        }
        emit MintPublicSale(_msgSender(), amount_);
    }

    function safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) external {
        _safeTransfer(from, to, tokenId, _data);
    }     

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        _safeTransfer(from, to, tokenId, "");
    }    

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    //*******************
    //*  GENERAL ADMIN  *  
    //*******************

    function setBaseUri(string memory uri_) external onlyAdmin {
        uri = uri_;
    }  

    function revealNfts(string memory uri_) external onlyAdmin {
        uri = uri_;
        usePlaceholderUri = false;
    }

    function setUsePlaceholderUri(bool isActive_) external onlyAdmin {
        usePlaceholderUri = isActive_;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return usePlaceholderUri ? uri : bytes(uri).length > 0 ? string(abi.encodePacked(uri, tokenId.toString())) : "";
    }    

    function airdropNFT(address[] memory _recipients, uint256[] memory _amounts) external onlyAdmin {
        require(_recipients.length > 0, "no recipients");
        require(_recipients.length == _amounts.length, "number of recipients and amounts do not match");
        for(uint x = 0; x < _recipients.length; x++) {
            require(_tokenIds.current() + _amounts[x] <= maxNfts, "Max NFTs would be exceeded");
            for (uint256 i = 0; i < _amounts[x]; i++) {
                _tokenIds.increment();
                _mint(_recipients[x], _tokenIds.current());
            }
            emit AirdropNFT(_msgSender(), _recipients[x], _amounts[x]);
        }
    }

    function withdrawFund() public onlyAdmin {
        require(treasuryAddress != address(0), "treasury address not set");
        (bool sent, ) = treasuryAddress.call{value: address(this).balance}("");
        require(sent, "failed to send funds");
    }

    function withdraw(address _token) external onlyAdmin nonReentrant {
        require(treasuryAddress != address(0), "treasury address not set");
        IERC20(_token).safeTransfer(treasuryAddress, IERC20(_token).balanceOf(address(this)));
        emit Withdraw(_msgSender(), _token);
    }    

    function setAdmins(address[] memory _Admins) external onlyOwner {
        _setAdmins(_Admins);
    }

    function _setAdmins(address[] memory _Admins) internal {
        for (uint256 i = 0; i < Admins.length; i++) {
            AdminByAddr[Admins[i]] = false;
        }

        for (uint256 j = 0; j < _Admins.length; j++) {
            AdminByAddr[_Admins[j]] = true;
        }
        Admins = _Admins;
        emit SetAdmins(_Admins);
    }

    function getAdmins() external view returns (address[] memory) {
        return Admins;
    }      

    //*******************
    //*     EVENTS      *  
    //*******************
    event AddedToWhiteList(address indexed whitelistAddress);
    event RemovedFromWhiteList(address indexed removedAddress);
    event SetWhiteSaleActive(bool indexed whiteSaleActive, uint256 time);
    event SetPublicSaleActive(bool indexed hasPublicSaleStarted, uint256 time);
    event MintWhiteSale(address indexed sender, uint indexed amount);
    event MintPublicSale(address indexed sender, uint indexed amount);
    event AirdropNFT(address indexed sender, address indexed recipient, uint256 indexed amount);
    event Withdraw(address indexed msgSender, address indexed token);
    event SetAdmins(address[] Admins);
}