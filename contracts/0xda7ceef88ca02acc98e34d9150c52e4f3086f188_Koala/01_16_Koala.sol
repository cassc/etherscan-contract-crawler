// SPDX-License-Identifier: GPL-3.0
// Modified from: Pagzi Tech Inc. 2021

pragma solidity ^0.8.10;
import "./ERC721Enum.sol";
import "./ERC721Burn.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Traveler.sol";


contract Koala is ERC721Enum, ERC721Burn, Ownable, ReentrancyGuard{
    using Strings for uint256;
    string public baseURI;
    //sale settings
    uint256 public cost = 0.05 ether;
    uint256 public maxSupply = 4715;
    uint256 public maxTravelerReserve = 285; 
    uint256 public maxMint = 5;
    uint256 public maxTravelerReservePerMint = 1;
    bool public status = false;
    //presale settings
    uint256 public presaleDate = 1642042800;
    mapping(address => uint256) public presaleWhitelist;
    uint256[] public koalaMet;
    Traveler public Travelers;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        Traveler _Traveler
    )
        ERC721P(_name, _symbol)
    {
        setBaseURI(_initBaseURI);
        Travelers = _Traveler;
    }

        function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enum, ERC721P) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // internal
    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    // public minting
    function mint(uint256 _mintAmount) external payable nonReentrant {
        uint256 s = totalSupply();
        uint256 t = totalTravelerReserve();
        require(status, "Off");
        require(_mintAmount > 0, "Duh");
        require(_mintAmount <= maxMint, "Too many");
        require(s + _mintAmount - t <= maxSupply, "Sorry");
        require(msg.value >= cost * _mintAmount);
        for (uint256 i = 0; i < _mintAmount; ++i) {
            _safeMint(msg.sender, s + i, "");
        }
        delete s;
    }


    function mintPresale(uint256 _mintAmount) external payable {
        require(presaleDate <= block.timestamp, "Not yet");
        uint256 s = totalSupply();
        uint256 t = totalTravelerReserve();
        uint256 reserve = presaleWhitelist[msg.sender];
        require(!status, "Off");
        require(reserve > 0, "Low reserve");
        require(_mintAmount <= reserve, "Try less");
        require(s + _mintAmount - t <= maxSupply, "More than max");
        require(cost * _mintAmount == msg.value, "Wrong amount");
        presaleWhitelist[msg.sender] = reserve - _mintAmount;
        delete reserve;
        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(msg.sender, s + i, "");
        }
        delete s;
    }



    // admin minting
    function gift(uint256[] calldata quantity, address[] calldata recipient)
        external
        onlyOwner
    {
        require(
            quantity.length == recipient.length,
            "Provide quantities and recipients"
        );
        uint256 totalQuantity = 0;
        uint256 s = totalSupply();
        uint256 t = totalTravelerReserve();
        for (uint256 i = 0; i < quantity.length; ++i) {
            totalQuantity += quantity[i];
        }
        require(s + totalQuantity - t <= maxSupply, "Too many");
        delete totalQuantity;
        for (uint256 i = 0; i < recipient.length; ++i) {
            for (uint256 j = 0; j < quantity[i]; ++j) {
                _safeMint(recipient[i], s++, "");
            }
        }
        delete s;
    }

        function travelerReserve() external payable{
        uint256 s = totalSupply();
        uint256 t = totalTravelerReserve();
        require(t + 1 <= maxTravelerReserve, "Sorry");
        Travelers.koalaMint{value: msg.value}(msg.sender,1);
        _safeMint(msg.sender, s + 1, "");
        koalaMet.push(1);
        delete s;
        delete t;
    }

        function travelerReservePresale() external payable{
        uint256 s = totalSupply();
        uint256 t = totalTravelerReserve();
        require(t + 1 <= maxTravelerReserve, "Sorry");
        Travelers.koalaPresaleMint{value: msg.value}(msg.sender,1);
        _safeMint(msg.sender, s + 1, "");
        koalaMet.push(1);
        delete s;
        delete t;
    }

    // admin functionality
    function presaleSet(
        address[] calldata _addresses,
        uint256[] calldata _amounts
    ) external onlyOwner {
        for (uint256 i; i < _addresses.length; i++) {
            presaleWhitelist[_addresses[i]] = _amounts[i];
        }
    }


    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        maxMint = _newMaxMintAmount;
    }

    function setMaxTravelerReservePerMintAmount(uint256 _newMaxMintAmount)
        public
        onlyOwner
    {
        maxTravelerReservePerMint = _newMaxMintAmount;
    }

    function setmaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setmaxTravelerReserve(uint256 _newMaxTravelerReserve)
        public
        onlyOwner
    {
        maxTravelerReserve = _newMaxTravelerReserve;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setSaleStatus(bool _status) public onlyOwner {
        status = _status;
    }

    function totalTravelerReserve() public view returns (uint256) {
        return koalaMet.length;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}