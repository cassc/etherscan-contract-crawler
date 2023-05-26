// SPDX-License-Identifier: MIT
import "./Context.sol";
import "./Address.sol";
import "./ERC721A.sol";

// File: contracts/Valiant.sol
library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

struct watchDetail {
    uint256 strap;
    uint256 caseWatch;
    uint256 crown;
    uint256 dial;
}

pragma solidity ^0.8.4;

interface IWhitelist {
    function publicCollection(uint256 _collection) external view returns(bool);

    function whitelist(address _address) external view returns(uint256);

    function getFounderAddress() external view returns(address);
}


contract Valiant is ERC721A, Ownable {
    using SafeMath for uint256;

    string baseUri = "ipfs://bafybeidi6qmlrisjfd3brmcyrc64y6zheewm4hcyp7inuigslv6oqh6kvi/";
    IWhitelist whitelist;

    uint256 public maxSupply;
    uint256 immutable maxMintPerWallet = 2;
    uint256 immutable maxMintFounderWallet = 200;
    uint256 nonce = 0;

    bool isFirstMint = true;

    mapping(uint256 => watchDetail) public watches;
    mapping(address => uint256) public addressToMintNumber;

    event itemsGenerated(uint256 indexed fromTokenId, uint256 indexed toTokenId, address indexed owner);

    constructor(string memory _tokenName, string memory _tokenSymbol, uint256 _maxSupply, address _whitelistAddress) ERC721A(_tokenName, _tokenSymbol) {
        maxSupply = _maxSupply;
        whitelist = IWhitelist(_whitelistAddress);
    }

    receive() external payable{}

    function random() internal returns (uint256) {
        uint256 randomnumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 100;
        nonce++;
        uint8[17] memory bounds = [7, 14, 19, 24, 30, 36, 40, 44, 48, 54, 60, 66, 72, 74, 81, 91, 100];
        for (uint i = 0; i < bounds.length; i++) {
            if (randomnumber <= bounds[i]) {
                return i;
            }
        }
        return type(uint256).max;
    }

    function mintToken(uint256 quantity) external
    {
        if (msg.sender == whitelist.getFounderAddress()) {
            require (_totalMinted().add(quantity) <= maxSupply, "REACH_MAX_SUPPLY");
            require (addressToMintNumber[msg.sender].add(quantity) <= maxMintFounderWallet, "REACH_MAX_MINT");
        } else {
            require (_totalMinted().add(quantity) <= maxSupply - maxMintFounderWallet, "REACH_MAX_SUPPLY");
            require (addressToMintNumber[msg.sender].add(quantity) <= maxMintPerWallet, "REACH_MAX_MINT");
        }

        if (isFirstMint) {
            isFirstMint = false;
        }

        addressToMintNumber[msg.sender] += quantity;
        uint256 tokenId = _nextTokenId();

        for (uint i = 0; i < quantity; i++) {
            watches[tokenId] = watchDetail(random(), random(), random(), random());
            tokenId += 1;
        }

        emit itemsGenerated(tokenId - quantity, tokenId - 1, msg.sender);

        _safeMint(msg.sender, quantity);
    }

    function OwnerMintToken(uint quantity) external {
        require (msg.sender == whitelist.getFounderAddress());
        require (_totalMinted().add(quantity) <= maxSupply);
        require (addressToMintNumber[msg.sender].add(quantity) <= maxMintFounderWallet, "REACH_MAX_MINT");

        if (isFirstMint) {
            require (quantity <= 30);
            isFirstMint = false;
        } else {
            require (quantity <= 40);
        }

        addressToMintNumber[msg.sender] += quantity;
        uint256 tokenId = _nextTokenId();

        for (uint i = 0; i < quantity; i++) {
            watches[tokenId] = watchDetail(random(), random(), random(), random());
            tokenId += 1;
        }

        emit itemsGenerated(tokenId - quantity, tokenId - 1, _msgSender());

        _safeMint(msg.sender, quantity);
    }

    function setWhitelistAddress(address _newWhitelistAddress) external onlyOwner {
        whitelist = IWhitelist(_newWhitelistAddress);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
    }

    function setBaseURI(string calldata _baseUri) external onlyOwner() {
        baseUri = _baseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }
}