// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
contract NotTodayClub is ERC721Enumerable, Ownable, Pausable {
    using Strings for uint256;
    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;
    uint256 public cost = 0.0666 ether;
    uint256 public constant MAXSUPPLY = 4200;
    uint256 public MAX_MINTS_PER_ADDRESS = 2;
    uint256 public perAddressLimit = 2;
    uint8 public curentMintGroup = 1;
    bool public revealed = false;
    bool public publicMintOpen = false;
    mapping(address => uint8) public allowList;
    mapping(address => uint256) public addressMintedBalance;
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        _mint(90, 0);
    }
    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    // public
    function mint(uint256 _mintAmount) public payable whenNotPaused {
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "non 0 amount");
        require(
            _mintAmount <= MAX_MINTS_PER_ADDRESS,
            "max mint amount per session"
        );
        require(supply + _mintAmount <= MAXSUPPLY, "NFT limit exceeded");
        if (msg.sender != owner()) {
            require(
                curentMintGroup == allowList[msg.sender] || publicMintOpen,
                "you are not on the list"
            );
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(
                ownerMintedCount + _mintAmount <= perAddressLimit,
                "NFT per address exceeded"
            );
            require(msg.value >= cost * _mintAmount, "insufficient funds");
        }
        _mint(_mintAmount, supply);
    }
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (revealed == false) {
            return notRevealedUri;
        }
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }
    function getGroupNumber(address account) external view returns (uint8) {
        return allowList[account];
    }
    function _mint(uint256 _amount, uint256 _curentSuply) internal {
        for (uint256 i = 1; i <= _amount; i++) {
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, _curentSuply + i);
        }
    }
    event Reveal(bool indexed state);
    event SetPublicMint(bool indexed state);
    event SetPerAddressLimit(uint256 indexed perAddressLimit);
    event SetCost(uint256 indexed cost);
    event SetMaxMintAmount(uint256 indexed Max_Mints_Per_Address);
    event AllowListUpload(address[] indexed adresses, uint8 indexed groupNum);
    event SetBaseURI(string indexed baseUri);
    event SetBaseExtention(string indexed baseExtension);
    event SetNotRevealedUri(string indexed notRevealed);
    event SetMintGroup(uint8 groupNum);
    event Withdrawl(address indexed owner, bool indexed success);
    //only owner
    function reveal() public onlyOwner {
        revealed = true;
        emit Reveal(revealed);
    }
    function setPublicMint(bool _state) external onlyOwner {
        publicMintOpen = _state;
        emit SetPublicMint(_state);
    }
    function setPerAddressLimit(uint256 _limit) external onlyOwner {
        perAddressLimit = _limit;
        emit SetPerAddressLimit(perAddressLimit);
    }
    function setCost(uint256 _newCost) external onlyOwner {
        cost = _newCost;
        emit SetCost(cost);
    }
    function setmaxMintAmount(uint256 _newmaxMintAmount) external onlyOwner {
        MAX_MINTS_PER_ADDRESS = _newmaxMintAmount;
        emit SetMaxMintAmount(MAX_MINTS_PER_ADDRESS);
    }
    function allowListUpload(address[] calldata _addresses, uint8 _groupNum)
        external
        onlyOwner
    {
        for (uint256 i; i < _addresses.length; ++i) {
            allowList[_addresses[i]] = _groupNum;
        }
        emit AllowListUpload(_addresses, _groupNum);
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
        emit SetBaseURI(baseURI);
    }
    function setBaseExtension(string memory _newBaseExtension)
        external
        onlyOwner
    {
        baseExtension = _newBaseExtension;
        emit SetBaseExtention(baseExtension);
    }
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
        emit SetNotRevealedUri(notRevealedUri);
    }
    function setMintGroup(uint8 _groupNum) external onlyOwner {
        curentMintGroup = _groupNum;
        emit SetMintGroup(_groupNum);
    }
    function pause() external onlyOwner {
        _pause();
    }
    function unpause() external onlyOwner {
        _unpause();
    }
    function withdraw() external payable onlyOwner {
        (bool ms, ) = payable(owner()).call{value: address(this).balance}("");
        require(ms);
        emit Withdrawl(owner(), ms);
    }
}