pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract PhunkyApeYachtClub is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    uint256 _mintPrice = 42069000000000000;

    // Base URI
    string private _baseURIextended =
        "ipfs://QmZnBLTvnUpTjtQq5S6yRuCRjLBWzpKDEXwPwFRFus3kub/";

    uint256 totalMinted;

    // treasury payouts
    address public staffOne = msg.sender;
    address public staffTwo = 0x7EC1939150F1CA31800280ae89E31fef72B669de;

    // partner payouts
    address public partnerOne = 0x4c677D4Fe4eC68a5F2C882CeC8a4c836ABca0832;
    address public partnerTwo = 0x57B2b690be38DCfC83Da0025355bB27A3858010e;
    address public partnerThree = 0x379c22629c3aEE7C3958c396fD1Bf5bbd20f2781;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
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

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString(), ".json"));
    }

    function setMintPrice(uint256 price) external onlyOwner {
        _mintPrice = price;
    }

    function mint(address _to, uint256 amount) external payable {
        require(amount <= 30);
        require(amount > 0);
        require(_tokenIds.current() + amount <= 9999);
        require(msg.value == _mintPrice * amount);

        payable(staffOne).transfer(_getStaffPayout());
        payable(staffTwo).transfer(_getStaffPayout());
        payable(partnerOne).transfer(_getPartnerPayout());
        payable(partnerTwo).transfer(_getPartnerPayout());
        payable(partnerThree).transfer(_getPartnerPayout());

        for (uint256 i = 0; i < amount; i++) {
            _mint(_to, _tokenIds.current());
            _tokenIds.increment();
            totalMinted++;
        }
    }

    function freeMint(address _to, uint256 amount) external {
        require(amount >= 1);
        // only valid for first 300
        require(amount + _tokenIds.current() <= 299);
        for (uint256 i = 0; i < amount; i++) {
            _mint(_to, _tokenIds.current());
            _tokenIds.increment();
            totalMinted++;
        }
    }

    function reserve(address _to, uint256 amount) external {
        require(msg.sender == staffOne || msg.sender == staffTwo);
        require(_tokenIds.current() + amount <= 9999);
        for (uint256 i = 0; i < amount; i++) {
            _mint(_to, _tokenIds.current());
            _tokenIds.increment();
            totalMinted++;
        }
    }

    function getTotalMinted() public view returns (uint256) {
        return totalMinted;
    }

    function _getStaffPayout() internal returns (uint256) {
        return (msg.value / 100) * 35;
    }

    function _getPartnerPayout() internal returns (uint256) {
        return msg.value / 10;
    }
}