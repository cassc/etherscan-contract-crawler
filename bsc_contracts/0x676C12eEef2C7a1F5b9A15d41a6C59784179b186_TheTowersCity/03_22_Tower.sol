//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Tower is ERC721Enumerable, Ownable, Initializable {
    string private _name;
    string private _symbol;

    string private metadataBaseURI;
    address private paramsChanger;

    uint8 public maxLevel;
    uint8 public minBillboardLevel;

    mapping(uint8 => uint8)   public level;
    mapping(uint8 => uint256) public capital;
    mapping(uint8 => string)  public title;
    mapping(uint8 => string)  public description;
    mapping(uint8 => string)  public link;
    mapping(uint8 => string)  public billboard;
    mapping(uint8 => bool)    public vip;
    mapping(uint8 => uint8)   public mortgage;
    mapping(uint8 => bool)    public isLiquidated;

    constructor() ERC721("", "") {}

    function initialize(string memory name, string memory symbol, address _paramsChanger) public initializer {
        _name = name;
        _symbol = symbol;

        maxLevel = 10;
        minBillboardLevel = 5;

        metadataBaseURI = "https://tw-api.dl-dev.ru/v1/metadata/";
        paramsChanger = _paramsChanger;
    }

    function updateChanger(address newChanger) public onlyChanger {
        paramsChanger = newChanger;
    }

    modifier onlyChanger() {
        require(msg.sender == paramsChanger, "Tower: only changer");
        _;
    }

    function updateMetadataBaseURI(string memory newMetadataBaseURI) public onlyChanger {
        metadataBaseURI = newMetadataBaseURI;
    }

    function updateLevelParams(uint8 _maxLevel, uint8 _minBillboardLevel) public onlyChanger {
        maxLevel = _maxLevel;
        minBillboardLevel = _minBillboardLevel;
    }

    function setMinter(address _minter) public {
        require(owner() == address(0), "Minter already set");

        _transferOwnership(_minter);
    }

    function mint(address _to, uint8 _square, bool _isVIP, uint8 _mortgageId) public onlyOwner {
        _safeMint(_to, _square, "");
        level[_square] = 1;
        vip[_square] = _isVIP;
        mortgage[_square] = _mortgageId;
    }

    function setBuildingInfo(uint8 _square, string memory _title, string memory _description, string memory _link) public onlyOwnerOrAdmin(_square) {
        title[_square] = _title;
        description[_square] = _description;
        link[_square] = _link;
    }

    function setBuildingBillboard(uint8 _square, string memory _billboard) public onlyOwnerOrAdmin(_square) {
        require(level[_square] >= minBillboardLevel, "Tower: level is not sufficient");
        billboard[_square] = _billboard;
    }

    function liquidate(uint8 _square) public onlyAdmin {
        isLiquidated[_square] = true;
        _transfer(ownerOf(_square), owner(), _square);
    }

    function upgrade(uint8 _square) public onlyAdmin {
        require(level[_square] < maxLevel, "Tower: max level reached");
        level[_square]++;
    }

    function addCapital(uint8 _square, uint256 _amount) public onlyAdmin {
        capital[_square] += _amount;
    }

    function exists(uint8 _square) public view returns(bool) {
        return _exists(_square);
    }

    modifier onlyAdmin() {
        require(owner() == _msgSender(), "Tower: sender is not an admin");
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return metadataBaseURI;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    modifier onlyOwnerOrAdmin(uint8 _square) {
        require(ownerOf(_square) == _msgSender() || owner() == _msgSender(), "Tower: sender is not an owner of the building nor admin");
        _;
    }
}