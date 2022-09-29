// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IAniwarNftController {
    function aniwarType() external view returns (string memory);
}

contract AniwarNft is ERC721Enumerable, Ownable {
    mapping(address => bool) public whiteList;
    event AniwarNftWhiteListAdded(string aniwarType, address indexed _address);
    struct AniwarItem {
        uint256 itemId;
        string aniwarType;
    }

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    AniwarItem[] public aniwarItems;
    uint256 tokenCounter = 0;

    modifier onlyWhiteList() {
        require(whiteList[msg.sender], "Not on whitelist!");
        _;
    }

    event RequestedAniwarItem(
        string aniType,
        uint256 indexed requestId,
        address indexed requester
    );

    constructor() ERC721("Aniwar Nft", "ANIN") {}

    function _createAniwarItem(string memory aniwarType, address owner)
        private
        onlyWhiteList
    {
        _safeMint(owner, tokenCounter);
        aniwarItems.push(AniwarItem(tokenCounter, aniwarType));
        emit RequestedAniwarItem(aniwarType, tokenCounter, owner);
        tokenCounter = tokenCounter + 1;
    }

    function createManyAniwarItem(
        uint8 _count,
        address owner,
        string memory aniwarType
    ) external {
        require(_count <= 10, "Number max is 10");
        for (uint8 i = 0; i < _count; i++) {
            _createAniwarItem(aniwarType, owner);
        }
    }

    function setWhiteList(address[] memory _whiteList, bool _state)
        public
        onlyOwner
    {
        require(_whiteList.length > 0, "Not get it!");
        for (uint256 i = 0; i < _whiteList.length; i++) {
            require(_whiteList[i] != address(0), "address = 0x0!");
            whiteList[_whiteList[i]] = _state;
            if (_state) {
                emit AniwarNftWhiteListAdded(
                    IAniwarNftController(_whiteList[i]).aniwarType(),
                    _whiteList[i]
                );
            }
        }
    }

    function getTokenURI(uint256 itemId) public view returns (string memory) {
        return tokenURI(itemId);
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
            "ERC721URIStorage: URI query for nonexistent token"
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
        return super.tokenURI(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI)
        external
        virtual
        onlyOwner
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}