pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";

contract MoonRabbits is ERC721A {
    uint256 public totalClaimed;
    mapping(address => uint256) public claimed;
    mapping(uint256 => bool) public officailSupplyed;
    uint256 public officailSupply;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant OFFICIAL_SUPPLY = 200;
    bool public started;
    string public baseUrl;

    address public contractOwner;
    address public owner;
    address public officialAddress;

    error HadClaimed();
    error OutofMaxSupply();
    error NotStarted();

    modifier onlyOwner() {
        require(contractOwner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUrl,
        address openseaOwner,
        address officaial
    ) ERC721A(_name, _symbol) {
        contractOwner = msg.sender;
        owner = openseaOwner;
        officialAddress = officaial;
        baseUrl = _baseUrl;
        _safeMint(msg.sender, 1);
        totalClaimed++;
    }

    function mint(uint256 amount) external payable {
        if (!started) revert NotStarted();
        if (claimed[msg.sender] + amount > 2) revert HadClaimed();
        if (!(totalClaimed + amount <= MAX_SUPPLY)) revert OutofMaxSupply();
        _safeMint(msg.sender, amount);

        if (!officailSupplyed[totalClaimed / 44] && officailSupply < OFFICIAL_SUPPLY) {
            _safeMint(officialAddress, 1);
            officailSupply += 1;
            officailSupplyed[totalClaimed / 44] = true;
            amount += 1;
        }
        claimed[msg.sender] += amount;
        totalClaimed += amount;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUrl;
    }

    function setBaseURI(string memory url) external onlyOwner {
        baseUrl = url;
    }

    function setStarted(bool flag) external onlyOwner {
        started = flag;
    }

    function setOfficialAddress(address addr) external onlyOwner {
        officialAddress = addr;
    }

    function setOpenseaAddress(address addr) external onlyOwner {
        owner = addr;
    }

    function setContractOwner(address addr) external onlyOwner {
        contractOwner = addr;
    }
}