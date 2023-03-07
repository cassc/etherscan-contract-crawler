pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./lib/IPassport.sol";

contract GamePassport is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721Upgradeable,
    IPassport
{
    uint256 passportsAmount;
    address public slotsAddress;
    string public baseURI;
    mapping(address => uint256) public passportId;
    mapping(address => bool) public transfersWhitelist;

    event Mint(address indexed to, uint256 indexed tokenId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _slotsAddress) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC721_init("IGames Game Passport", "IGGP");
        slotsAddress = _slotsAddress;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function mint(address _to) external override nonReentrant returns (bool) {
        require(msg.sender == slotsAddress, "Only slots contract can mint");
        require(_to != address(0), "Cannot mint to 0 address");
        require(
            balanceOf(_to) == 0,
            "Cannot mint to address with existing passport"
        );
        passportsAmount++;
        _safeMint(_to, passportsAmount);
        passportId[_to] = passportsAmount;
        emit Mint(_to, passportsAmount);
        return true;
    }

    function setTransferWhitelist(address _address, bool _status)
        external
        onlyOwner
    {
        transfersWhitelist[_address] = _status;
    }

    function setSlotsAddress(address _slotsAddress) external onlyOwner {
        require(_slotsAddress != address(0), "Slots address cannot be 0");
        slotsAddress = _slotsAddress;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(
            transfersWhitelist[to],
            "Transfer to this address is not allowed"
        );
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(
            transfersWhitelist[to],
            "Transfer to this address is not allowed"
        );
        super.safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(
            transfersWhitelist[to],
            "Transfer to this address is not allowed"
        );
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, tokenId));
    }

    function totalSupply() public view returns (uint256) {
        return passportsAmount;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}