// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import "@openzeppelin/contracts/utils/Counters.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Schroot is ERC721Burnable, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private price = .02 * 1e18;
    uint256 private totalSchroots = 8337;
    bool public saleStart;
    bool public whitelistSale;
    bool public openForWhitelist;
    uint256 public maxWhitelist = 500;
    uint256 public whitelisted;

    uint256 maxMint = 20;
    uint256 maxMintWhitelist = 5;

    string private baseUri = 'https://api.schroot.io/json/';

    address private sara            = 0x00796e910Bd0228ddF4cd79e3f353871a61C351C;
    address private gotrilla        = 0x3546BD99767246C358ff1497f1580C8365b25AC8;
    address private robooverlord    = 0x30119E6DA1578F721cf5e9945b148Ae2E512ca01;
    address private roborambo       = 0xe0Ea9a993870eA3c8E883DC3Ecc9596D5073C8Cb;
    address private brett           = 0xc9CF4E3E13c4a7e45F4689a9b20E038C7BeF328E;
    address private community       = 0xC14da9a159a5CA7ade851F9A9C33a2D1E5D22724;

    mapping (address => bool) public Whitelist;
    mapping (address => uint256) public MintsPerWallet;

    constructor() ERC721("Schroot", "SCHROOT") {
        uint256 i;
        for(i=0; i<5; i++) {
            _tokenIds.increment();
            _safeMint(sara, _tokenIds.current());
        }
        for(i=0; i<5; i++) {
            _tokenIds.increment();
            _safeMint(gotrilla, _tokenIds.current());
        }
        for(i=0; i<5; i++) {
            _tokenIds.increment();
            _safeMint(robooverlord, _tokenIds.current());
        }
        for(i=0; i<5; i++) {
            _tokenIds.increment();
            _safeMint(roborambo, _tokenIds.current());
        }
        for(i=0; i<5; i++) {
            _tokenIds.increment();
            _safeMint(brett, _tokenIds.current());
        }
        for(i=0; i<15; i++) {
            _tokenIds.increment();
            _safeMint(community, _tokenIds.current());
        }
    }

    function mint(uint256 amount) public payable {
        require(saleStart, "Sale has not started yet.");
        require(price * amount <= msg.value, "Price not correct.");
        require(totalSupply() + amount <= totalSchroots, "Exceeds max supply.");
        require(amount <= maxMint, "Exceeds max mint.");
        if(whitelistSale) {
            require(Whitelist[msg.sender], "Not on the whitelist.");
            require(MintsPerWallet[msg.sender]+amount <= maxMintWhitelist, "Exceeds max mint for whitelist.");
        }
        for(uint256 i=0; i<amount; i++) {
            _tokenIds.increment();
            _safeMint(msg.sender, _tokenIds.current());
            MintsPerWallet[msg.sender]++;
        }
    }

    function addSelfToWhitelist() public {
        require(openForWhitelist && whitelisted+1 <= maxWhitelist && !Whitelist[msg.sender], "Not eligible for whitelist.");
        Whitelist[msg.sender] = true;
        whitelisted++;
    }

    function addToWhitelist(address user) public onlyOwner {
        Whitelist[user] = true;
        whitelisted++;
    }

    /**
    *   External function for getting all tokens by a specific owner.
    */
    function getByOwner(address _owner) view public returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTokens = _tokenIds.current();
            uint256 resultIndex = 0;
            for (uint256 t = 1; t <= totalTokens; t++) {
                if (_exists(t) && ownerOf(t) == _owner) {
                    result[resultIndex] = t;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    function exists(uint256 tokenId) public view returns(bool) {
        return _exists(tokenId);
    }

    function totalSupply() public view returns(uint256) {
        return _tokenIds.current();
    }

    /*
    *   Owner setters.
    */
    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function setSaleStart(bool _saleStart) public onlyOwner {
        saleStart = _saleStart;
    }

    function setWhitelistSale(bool _whitelistSale) public onlyOwner {
        whitelistSale = _whitelistSale;
    }

    function setOpenForWhitelist(bool _openForWhitelist) public onlyOwner {
        openForWhitelist = _openForWhitelist;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    /*
    *   Money management.
    */
    function withdraw() public payable onlyOwner {

        uint256 _community = (address(this).balance * 33) / 100;
        uint256 _each = (address(this).balance - _community) / 5;
        require(payable(sara).send(_each));   // sara
        require(payable(robooverlord).send(_each));   // robo overlord
        require(payable(gotrilla).send(_each));   // gotrilla
        require(payable(roborambo).send(_each));   // robo rambo
        require(payable(brett).send(_each));   // robo rambo
        require(payable(community).send(_community));   // community
    }

    function forwardERC20s(IERC20 _token, uint256 _amount) public onlyOwner {
        _token.transfer(msg.sender, _amount);
    }

    /*
    *   Overrides
    */
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    receive () external payable virtual {}

}