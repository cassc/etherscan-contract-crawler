// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract KANOJOHatanoYuiNFT  is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using AddressUpgradeable for address;
    using AddressUpgradeable for address payable;

    //constant
    uint256 public constant WHITE_LIST_MINT_LIMIT_AMOUNT = 1;
    uint256 public constant PUBLIC_MINT_LIMIT_AMOUNT = 3;
    uint256 public constant WHITE_LIST_MINT_TOTAL_LIMIT_AMOUNT = 1500;
    uint256 public constant PUBLIC_MINT_TOTAL_LIMIT_AMOUNT = 3500;
    uint256 public constant MINT_PRICE = 0.16 ether;
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant SIGNER_ROLE = keccak256("SIGN_ROLE");
    bytes32 public constant WHITELIST_MINT_TYPEHASH =
        keccak256(
            "whiteListMint(uint256 amount,uint256 deadline)"
        );
    
    // storage
    string private _basePath;
    CountersUpgradeable.Counter private _tokenIdCounter;
    uint256 public whiteListMintTime;
    uint256 public publicMintTime;
    mapping(address=>uint256) public whiteListMintAmount;
    mapping(address=>uint256) public publicMintAmount;
    uint256 public whiteListMintTotalAmount;
    uint256 public publicMintTotalAmount;

    // event
    event WhiteListMint(
        address indexed user,
        uint256 amount
    );

    event PublicMint(
        address indexed user,
        uint256 amount
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 _whiteListMintTime, uint256 _publicMintTime) initializer public {
        __ERC721_init("KANOJO-Hatano-Yui", "K-Hatano-Yui");
        __ERC721Enumerable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(SIGNER_ROLE, msg.sender);

        whiteListMintTime = _whiteListMintTime;
        publicMintTime = _publicMintTime;
    }

    function setWhiteListMintTime(uint256 _whiteListMintTime) public onlyRole(DEFAULT_ADMIN_ROLE){
        whiteListMintTime = _whiteListMintTime;
    }

    function setPublicMintTime(uint256 _publicMintTime) public onlyRole(DEFAULT_ADMIN_ROLE){
        publicMintTime = _publicMintTime;
    }

    function adminWithdraw() public onlyRole(DEFAULT_ADMIN_ROLE){
        payable(msg.sender).sendValue(address(this).balance);
    }

    function whiteListMint(
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) public {
        /*require(block.timestamp >= whiteListMintTime, "mint not start");
        require(block.timestamp <= deadline, "signature expired");

        require(amount <= WHITE_LIST_MINT_TOTAL_LIMIT_AMOUNT - whiteListMintTotalAmount, "total mint amount limit");
        whiteListMintTotalAmount += amount;

        require(amount <= WHITE_LIST_MINT_LIMIT_AMOUNT - whiteListMintAmount[msg.sender], "private mint amount limit");
        whiteListMintAmount[msg.sender] += amount;

        // check sign
        uint chainID;
        assembly{
            chainID:=chainid()
        }
        bytes32 signHash = keccak256(
            abi.encode(
                WHITELIST_MINT_TYPEHASH,
                amount,
                deadline,
                chainID,
                address(msg.sender),
                address(this)
            )
        );

        (address singer,) = ECDSAUpgradeable.tryRecover(signHash, signature);
        _checkRole(SIGNER_ROLE, singer);

        // mint
        _multiMint(msg.sender, amount);

        // event
        emit WhiteListMint(msg.sender, amount);*/
    }

    function mint(uint256 amount) public payable {
        /*require(block.timestamp >= publicMintTime, "mint not start");

        require(amount <= PUBLIC_MINT_TOTAL_LIMIT_AMOUNT - publicMintTotalAmount, "total mint amount limit");
        publicMintTotalAmount += amount;

        require(amount <= PUBLIC_MINT_LIMIT_AMOUNT - publicMintAmount[msg.sender], "mint amount limit");
        publicMintAmount[msg.sender] += amount;

        require(msg.value == MINT_PRICE * amount, "insufficient eth");

        // mint
        _multiMint(msg.sender, amount);

        // event
        emit PublicMint(msg.sender, amount);*/
    }

    function _multiMint(address to, uint256 amount) private{
        for (uint256 i = 0; i < amount; ++i) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return _basePath;
    }

    function setBaseURI(string calldata path) public onlyRole(DEFAULT_ADMIN_ROLE){
        _basePath = path;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}