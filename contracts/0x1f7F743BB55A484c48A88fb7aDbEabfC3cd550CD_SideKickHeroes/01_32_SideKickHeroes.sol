// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";

contract SideKickHeroes is
    ERC2981,
    ERC721AQueryableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using SafeCastUpgradeable for uint256;
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address payable;

    uint256 private minted;
    uint256 private claimed;

    string public baseUri;
    string private contractUri;
    uint256 public mintLimit;    
    uint256 public mintPrice;
    uint256 public maxMintPerWallet;
    uint256 public maxMintPerTransaction;

    bool public whitelistActive;
    address public FEESPLITTER;
    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");
    bytes32 public constant BSC_WHITELISTED_ROLE =
        keccak256("BSC_WHITELISTED_ROLE");

    mapping(address => uint256) public claimLimit;    
    mapping(address => uint256) public freeMintedPerWallet;
    mapping(address => uint256) private mintedPerWallet;    
    mapping(address => uint256) private claimedPerWallet;

    event Minted(address indexed receiver, uint256 numberOfNfts);

    function initialize(
        // tokenName, tokenSymbol, tokenUri, contractUri
        string[4] memory _stringSettings,
        //price, maxMintPerWallet, maxMintPerTransaction, royaltyFee
        uint256[4] memory _intSettings
    ) external initializerERC721A initializer {
        __ERC721A_init(_stringSettings[0], _stringSettings[1]);
        __ReentrancyGuard_init();
        __Ownable_init();
        __AccessControl_init();
        __Pausable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(WHITELISTED_ROLE, _msgSender());

        FEESPLITTER = 0x4C85973AA4D667497FEd1556eE3b3A2D27aE8224;

        whitelistActive = true;

        baseUri = _stringSettings[2];
        contractUri = _stringSettings[3];

        mintLimit = 3333;
        mintPrice = _intSettings[0];
        maxMintPerWallet = _intSettings[1];
        maxMintPerTransaction = _intSettings[2];

        _setDefaultRoyalty(FEESPLITTER, _intSettings[3].toUint96());
    }

    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    function setContractURI(string memory _uri) public onlyOwner {
        contractUri = _uri;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseUri = _uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721AUpgradeable) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        if (bytes(baseURI).length > 0) {
            // Concatenate baseURI with tokenId and ".json"
            string memory tokenIdStr = Strings.toString(tokenId);
            return string(abi.encodePacked(baseURI, tokenIdStr, ".json"));
        } else {
            return "";
        }
    }

    function crossmint(
        address _to,
        uint256 _numberOfNfts
    ) public payable nonReentrant {
        require(!paused(), "Minting is paused");        
        require(
            mintedPerWallet[_msgSenderERC721A()] + _numberOfNfts <=
                maxMintPerWallet,
            "WALLET LIMIT"
        );
        require(minted + _numberOfNfts <= mintLimit, "MINT LIMIT");

        if (minted >= 100 || freeMintedPerWallet[_msgSenderERC721A()] >= 1) {
            require(
                msg.value >= mintPrice.mul(_numberOfNfts),
                "INSUFFICIENT FUNDS"
            );
        } else {
            freeMintedPerWallet[_msgSenderERC721A()]++;
            require(msg.value >= mintPrice.mul(_numberOfNfts - 1), "INSUFFICIENT FUNDS");            
        }

        mintedPerWallet[_msgSenderERC721A()] += _numberOfNfts;
        minted += _numberOfNfts;

        _safeMint(_to, _numberOfNfts);
        emit Minted(_to, _numberOfNfts);
    }

    function mint(
        address _to,
        uint256 _numberOfNfts,
        address _referrer
    ) public payable nonReentrant {
        require(!paused(), "Minting is paused");        
        require(_numberOfNfts <= maxMintPerTransaction, "MAX MINT TX");
        require(
            mintedPerWallet[_msgSenderERC721A()] + _numberOfNfts <=
                maxMintPerWallet,
            "WALLET LIMIT"
        );
        require(minted + _numberOfNfts <= mintLimit, "MINT LIMIT");

        if(whitelistActive) {
            require(hasRole(WHITELISTED_ROLE, _msgSenderERC721A()), "Need WL");
        }

        if (minted >= 100 || freeMintedPerWallet[_msgSenderERC721A()] >= 1) {
            require(
                msg.value >= mintPrice.mul(_numberOfNfts),
                "INSUFFICIENT FUNDS"
            );
        } else {
            freeMintedPerWallet[_msgSenderERC721A()]++;
            require(msg.value >= mintPrice.mul(_numberOfNfts - 1), "INSUFFICIENT FUNDS");            
        }

        // check referrer, if valid send 10% of msg.value to referrer
        if (_referrer != address(0) && _referrer != _msgSenderERC721A()) {
            uint256 _referralFee = msg.value.mul(100).div(1000);
            payable(_referrer).sendValue(_referralFee);
        }

        mintedPerWallet[_msgSenderERC721A()] += _numberOfNfts;
        minted += _numberOfNfts;

        _safeMint(_to, _numberOfNfts);
        emit Minted(_to, _numberOfNfts);
    }

    function claim() public nonReentrant {
        require(hasRole(BSC_WHITELISTED_ROLE, _msgSenderERC721A()), "Need WL");
        require(!paused(), "Minting is paused");
        require(
            claimLimit[_msgSenderERC721A()] > 0,
            "No claim"
        );
        
        // check how many left to claim from claimLimit, make sure claim doesnt go over mintLimit
        uint256 _numberOfNfts = claimLimit[_msgSenderERC721A()];
        
        if (minted + _numberOfNfts > mintLimit) {
            _numberOfNfts = mintLimit - minted;
            require(_numberOfNfts > 0, "mint limit");
        }

        mintedPerWallet[_msgSenderERC721A()] += _numberOfNfts;
        claimedPerWallet[_msgSenderERC721A()] += _numberOfNfts;
        claimLimit[_msgSenderERC721A()] -= _numberOfNfts;
        minted += _numberOfNfts;
        _safeMint(_msgSenderERC721A(), _numberOfNfts);
    }

    function grantWLRoles(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _grantRole(WHITELISTED_ROLE, _addresses[i]);
        }
    }

    function grantBSCWLRoles(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _grantRole(BSC_WHITELISTED_ROLE, _addresses[i]);
        }
    }

    function setWhitelistActive(bool _active) public onlyOwner {
        whitelistActive = _active;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setClaimLimit(address[] memory _addresses, uint256[] memory _limits) public onlyOwner {
        require(_addresses.length == _limits.length, "Array length mismatch");
        for (uint256 i = 0; i < _addresses.length; i++) {
            claimLimit[_addresses[i]] = _limits[i];
        }
    }

    function setClaim(address _address, uint256 _limit) public onlyOwner {
        claimLimit[_address] = _limit;
    }

    fallback() external payable {
        //Do nothing, BNB will be sent to contract when selling tokens
    }

    receive() external payable {}

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721AUpgradeable, ERC2981, AccessControlUpgradeable)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(owner()).transfer(balance);
    }
}