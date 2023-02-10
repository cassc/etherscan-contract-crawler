// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract TribecaNFT is
    UUPSUpgradeable,
    OwnableUpgradeable,
    ERC721EnumerableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using StringsUpgradeable for uint256;

    uint256 private _tokenIdCounter;
    address private _admin;

    uint256 public maxSupply;
    uint256 public price;

    uint256 public startTime;
    uint256 public endTime;

    address public payToken;
    address public receiver;
    string public baseURI;
    uint256 public tokenDropAmount;

    uint256 public publicMintMaxSupply;
    uint256 public mintLimitationPerAddress;
    mapping(address => uint256) public mintRecord;

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    modifier mintTime() {
        require(
            startTime > 0 && block.timestamp > startTime,
            "mint has not started"
        );
        require(block.timestamp < endTime, "mint has ended");
        _;
    }
    modifier onlyAdminOrOwner() {
        require(
            msg.sender == _admin || msg.sender == owner(),
            "only admin or owner can operate"
        );
        _;
    }

    // constructor() {
    //     _disableInitializers();
    // }
    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _price,
        address _payToken
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init();
        __ERC721Enumerable_init();

        maxSupply = _maxSupply;
        price = _price;
        payToken = _payToken;
        _tokenIdCounter = 1;
    }

    //-------------------------------
    //------- Owner functions -------
    //-------------------------------
    function setMaxSupply(uint256 _max) public onlyAdminOrOwner {
        require(_max > totalSupply(), "please set correct max supply");
        maxSupply = _max;
    }

    function setPrice(uint256 _price) public onlyAdminOrOwner {
        price = _price;
    }

    function setPayToken(address _payToken) public onlyAdminOrOwner {
        payToken = _payToken;
    }

    function mintForDrop(address to) external onlyAdminOrOwner {
        safeMint(to);
        tokenDropAmount++;
    }

    function mintBatchForDrop(address[] calldata _tos) public onlyAdminOrOwner {
        safeBatchMint(_tos);
        tokenDropAmount += _tos.length;
    }

    function setMintTime(uint256 _startTime, uint256 _endTime)
        external
        onlyAdminOrOwner
    {
        require(_startTime < _endTime, "please set correct mint time");
        startTime = _startTime;
        endTime = _endTime;
    }

    function setReceiver(address _receiver) external onlyAdminOrOwner {
        require(_receiver != address(0), "please set a correct receiver");
        receiver = _receiver;
    }

    function setBaseUri(string calldata _baseUri) external onlyAdminOrOwner {
        baseURI = _baseUri;
    }

    function setPublicMintMaxSupply(uint256 _publicMintMaxSupply)
        external
        onlyAdminOrOwner
    {
        publicMintMaxSupply = _publicMintMaxSupply;
    }

    function setMintLimitationPerAddress(uint256 _mintLimitationPerAddress)
        external
        onlyAdminOrOwner
    {
        mintLimitationPerAddress = _mintLimitationPerAddress;
    }

    function setAdmin(address admin) external onlyOwner {
        _admin = admin;
    }

    function burn(uint256 _tokenId) external onlyAdminOrOwner {
        _burn(_tokenId);
    }

    //-------------------------------
    //------- User functions --------
    //-------------------------------
    function publicMint(uint256 _amount) external payable mintTime {
        require(receiver != address(0), "wrong receiver");
        require(
            totalSupply() - tokenDropAmount + _amount <= publicMintMaxSupply,
            "reached public mint maxSupply"
        );
        require(
            mintRecord[_msgSender()] + _amount <= mintLimitationPerAddress,
            "reached limitation for per address"
        );

        uint256 totalPayment = price * _amount;
        require(msg.value == totalPayment, "wrong msg.value");

        mintRecord[_msgSender()] += _amount;
        
        AddressUpgradeable.sendValue(payable(receiver), totalPayment);
        for (uint256 i = 0; i < _amount; ) {
            safeMint(msg.sender);
            unchecked {
                ++i;
            }
        }
    }

    //-------------------------------
    //------- view functions --------
    //-------------------------------
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    //-------------------------------
    //------- Internal functions --------
    //-------------------------------
    function safeMint(address to) internal {
        require(totalSupply() + 1 <= maxSupply, "reached maxSupply");
        //get tokenID with auto-increment
        uint256 currentTokenId = _tokenIdCounter;
        _tokenIdCounter++;
        //mint
        _safeMint(to, currentTokenId);
    }

    function safeBatchMint(address[] calldata _tos) internal {
        require(totalSupply() + _tos.length <= maxSupply, "reached maxSupply");
        uint256 currentTokenId = _tokenIdCounter;
        for (uint256 i = 0; i < _tos.length; i++) {
            _safeMint(_tos[i], currentTokenId);
            currentTokenId++;
        }
        _tokenIdCounter += _tos.length;
    }
}