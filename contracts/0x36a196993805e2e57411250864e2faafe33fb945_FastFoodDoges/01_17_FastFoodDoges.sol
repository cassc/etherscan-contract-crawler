// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Namable.sol";
import "./IERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract FastFoodDoges is ERC721Namable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_ELEMENTS = 6969;
    uint256 public constant MAX_BASE_ELEMENTS = 1696;

    uint256 public constant PRICE = 42 * 10**15;
    uint256 public constant MAX_PUBLIC_MINT = 4;
    uint256 public constant MAX_WHITELIST_MINT = 2;

    address public pleasrDaoWallet;
    address public fffWallet;
    string public baseTokenURI;

    bool public saleOpen = false;
    bool public whiteListOpen = false;
    uint256 public breedPrice = 420 ether;

    IERC20Burnable private nameChangeToken;
    bool public nameChangeOpen = false;
    bool public breedingOpen = false;
    uint256 public babyDogeCount = 0;

    bytes32 public whiteListRoot;
    mapping(address => uint8) public whiteListMinted;
    mapping(address => uint8) public publicSaleMinted;
    mapping(uint256 => uint256) public lastBreed;
    uint256 public breedCoolDown = 1 days;

    constructor(
        bytes32 _whiteListRoot,
        string memory _baseUri,
        address _pleasrDaoWallet,
        address _fffWallet
    ) ERC721Namable("FastFoodDoge", "FFD") {
        whiteListRoot = _whiteListRoot;
        setBaseURI(_baseUri);
        pleasrDaoWallet = _pleasrDaoWallet;
        fffWallet = _fffWallet;

        _mintAnElement(fffWallet);
        for (uint256 i = 0; i < 15; i++) {
            _mintAnElement(pleasrDaoWallet);
            _mintAnElement(fffWallet);
        }
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function validSale(uint8 _count) private {
        require(totalSupply() + _count <= MAX_BASE_ELEMENTS, "Max limit");
        require(msg.value == PRICE.mul(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_msgSender());
        }
    }

    function mint(uint8 _count) public payable {
        require(saleOpen, "Sale not open");
        require((publicSaleMinted[_msgSender()] += _count) <= MAX_PUBLIC_MINT);

        validSale(_count);
    }

    function mintFromWhiteList(bytes32[] calldata _merkleProof, uint8 _count)
        public
        payable
    {
        require(whiteListOpen, "WhiteList Sale not open");
        require(
            (whiteListMinted[_msgSender()] += _count) <= MAX_WHITELIST_MINT
        );
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, whiteListRoot, leaf),
            "Invalid proof provided"
        );

        validSale(_count);
    }

    function breed(uint256 ogDoge) external {
        require(breedingOpen, "Breeding not open yet!");
        require(ownerOf(ogDoge) == _msgSender());
        require(ogDoge < MAX_BASE_ELEMENTS, "Not an OG Doge");
        require(
            totalSupply() < MAX_ELEMENTS,
            "Exceeds maximum number of items in collection"
        );
        require((lastBreed[ogDoge] += breedCoolDown) < block.timestamp);

        nameChangeToken.burnFrom(_msgSender(), breedPrice);
        _mintAnElement(_msgSender());
    }

    function _mintAnElement(address _to) private {
        uint256 id = totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setParams(
        bool _whiteListOpen,
        bool _saleOpen,
        bool _breedOpen,
        bool _nameChangeOpen,
        uint256 _breedCoolDown
    ) public onlyOwner {
        saleOpen = _saleOpen;
        whiteListOpen = _whiteListOpen;
        breedingOpen = _breedOpen;
        nameChangeOpen = _nameChangeOpen;
        breedCoolDown = _breedCoolDown;
    }

    function setPleasrDaoWallet(address _plsrDaoWallet) public {
        require(pleasrDaoWallet == _msgSender());
        pleasrDaoWallet = _plsrDaoWallet;
    }

    function setPrices(
        uint256 _nameChangePrice,
        uint256 _bioChangePrice,
        uint256 _breedPrice
    ) public onlyOwner {
        nameChangePrice = _nameChangePrice;
        bioChangePrice = _bioChangePrice;
        breedPrice = _breedPrice;
    }

    function setToken(IERC20Burnable _nameChangeToken) external onlyOwner {
        require(address(nameChangeToken) == address(0));
        nameChangeToken = _nameChangeToken;
    }

    function changeName(uint256 tokenId, string memory newName)
        public
        override
    {
        require(nameChangeOpen, "You can not change the name yet");
        nameChangeToken.burnFrom(_msgSender(), nameChangePrice);
        super.changeName(tokenId, newName);
    }

    function changeBio(uint256 tokenId, string memory _bio) public override {
        require(nameChangeOpen, "You can not change the bio yet");
        nameChangeToken.burnFrom(_msgSender(), bioChangePrice);
        super.changeBio(tokenId, _bio);
    }

    function withdrawAll() public payable {
        uint256 balance = address(this).balance;
        uint256 ffcut = balance.mul(55).div(100);
        uint256 dogeCut = balance.sub(ffcut);

        _withdraw(pleasrDaoWallet, dogeCut);
        _withdraw(fffWallet, ffcut);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}