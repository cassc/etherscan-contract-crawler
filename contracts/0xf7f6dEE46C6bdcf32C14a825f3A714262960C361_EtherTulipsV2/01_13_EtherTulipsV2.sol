// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./ERC721.sol";
import "./ERC721Enumerable.sol";

contract EtherTulipsV2 is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;

    event SalesStart();

    address public bridgeAddress;

    uint256 public constant price1 = 75000000000000000 wei; // 0.075 ETH
    uint256 public constant price2 = 150000000000000000 wei; // 0.15 ETH
    uint256 public constant maxHiddenAttrBlocks = 19350; // around 72 hours
    uint256 public constant v1Supply = 7251;
    uint256 public constant v2MaxSupply = 5094;
    uint256 public constant maxPurchaseAmount = 30;
    uint16 public constant numReserved = 24;

    uint256 public mostRecentSaleBlock = 0;
    uint256 public startSalesBlock = 0;

    uint256 private v2Supply = 0;
    uint256 private numUnimportedTokens = v1Supply;
    bool[v1Supply] private tokenImported;

    constructor(address _bridgeAddress) ERC721("EtherTulips", "TULIP") {
        bridgeAddress = _bridgeAddress;

        // tulips reserved for the winners of giveaways and contests
        _mintTokens(numReserved);
    }

    function mint(uint16 _numTokens) public payable {
        require(totalSupply() + _numTokens <= maxSupply(), "Insufficient supply");
        require(salesOpen(), "The sales period is not open");
        require(_numTokens <= maxPurchaseAmount, "Too many purchases at once");
        uint256 totalCost = price() * _numTokens;
        require(msg.value == totalCost, "Incorrect amount sent");

        _mintTokens(_numTokens);
    }

    function maxSupply() public pure returns (uint256 max) {
        max = v1Supply + v2MaxSupply;
    }

    function price() public view returns (uint256) {
        if (attributesAvailable()) {
            return price2;
        } else {
            return price1;
        }
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (_isV1(_tokenId)) {
            return string(abi.encodePacked(_baseURI(), "v1/", uint256(_tokenId).toString(), ".json"));
        } else if (attributesAvailable()) {
            uint256 design = _getDesign(_tokenId);
            return string(abi.encodePacked(_baseURI(), "v2/", uint256(design).toString(), ".json"));
        } else {
            return string(abi.encodePacked(_baseURI(), "v2/seed.json"));
        }
    }

    function contractURI() public pure returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "contract-meta.json"));
    }

    /* Overridden ERC721 for unimported tokens */

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        balance = super.balanceOf(_owner);
        if (_owner == bridgeAddress) {
            balance += numUnimportedTokens;
        }
    }

    function ownerOf(uint256 _tokenId) public view override returns (address owner) {
        if (_isUnimportedV1(_tokenId)) {
            owner = bridgeAddress;
        } else {
            owner = super.ownerOf(_tokenId);
        }
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public virtual override {
        if (_isUnimportedV1(_tokenId)) {
            require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721: transfer caller is not owner nor approved");
            ERC721._importTransfer(_from, _to, _tokenId);
            require(_checkOnERC721Received(_from, _to, _tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
        } else {
            ERC721._safeTransfer(_from, _to, _tokenId, _data);
        }
    }

    // called in safeTransferFrom and transferFrom
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        require(_to != address(0), "Cannot send to null address"); // prevents burning

        if (_from == bridgeAddress && _isUnimportedV1(_tokenId)) {
            tokenImported[_tokenId] = true;
            numUnimportedTokens--;
        } else if (_from != _to && _from != address(0)) {
            _removeTokenFromOwnerEnumeration(_from, _tokenId);
        }

        if (_to == bridgeAddress) {
            require(_isV1(_tokenId), "tokens minted with EtherTulips V2 cannot be bridged to EtherTulips V1");
        }
        if (_to != _from) {
            _addTokenToOwnerEnumeration(_to, _tokenId);
        }
    }

    function _exists(uint256 _tokenId) internal view override returns (bool) {
        return _tokenId < totalSupply();
    }

    /* Overridden ERC721Enumerable for unimported tokens */

    function totalSupply() public view override returns (uint256 supply) {
        supply = v1Supply + v2Supply;
    }

    function tokenByIndex(uint256 _index) public view override returns (uint256 tokenId) {
        require(_index < this.totalSupply(), "index out of bounds");
        tokenId = _index;
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view override returns (uint256 tokenId) {
        if (_owner == bridgeAddress && _index >= super.balanceOf(_owner)) {
            require(_index < balanceOf(_owner), "owner index out of bounds for bridge");

            uint256 steps = _index - super.balanceOf(_owner) + 1;
            for (tokenId = 0; tokenId < v1Supply; tokenId++) {
                if (!tokenImported[tokenId]) {
                    steps--;
                }
                if (steps == 0) {
                    return tokenId;
                }
            }

            require(false, "Unreachable code");
        } else {
            tokenId = super.tokenOfOwnerByIndex(_owner, _index);
        }
    }

    /* State checking */

    function salesStarted() public view returns (bool isStarted) {
        isStarted = startSalesBlock != 0;
    }

    function salesOpen() public view returns (bool isOpen) {
        isOpen = salesStarted() && totalSupply() < maxSupply();
    }

    function attributesAvailable() public view returns (bool isAvailable) {
        uint256 elapsedBlocks = block.number - startSalesBlock;

        isAvailable = salesStarted() && (totalSupply() == maxSupply() || elapsedBlocks >= maxHiddenAttrBlocks);
    }

    /* Owner ownly */

    function startSales() external onlyOwner {
        require(!salesStarted(), "Sales already started");
        startSalesBlock = block.number;
        emit SalesStart();
    }

    function withdrawBalance(uint256 _amount) external onlyOwner {
        require(_amount <= address(this).balance);
        payable(msg.sender).transfer(_amount);
    }

    /* Internal */

    function _isV1(uint256 _tokenId) internal pure returns (bool) {
        return _tokenId < v1Supply;
    }

    function _isUnimportedV1(uint256 _tokenId) internal view returns (bool) {
        return _isV1(_tokenId) && !tokenImported[_tokenId];
    }

    function _numImported() internal view returns (uint256) {
        return v1Supply - numUnimportedTokens;
    }

    function _getDesign(uint256 _tokenId) internal view returns (uint256 design) {
        require(attributesAvailable(), "Attributes are not yet available");
        require(!_isV1(_tokenId), "_getDesign is only valid for v2 tokens");
        design = (_tokenId + mostRecentSaleBlock) % v2MaxSupply;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://tokens.ethertulips.com/meta/";
    }

    function _mintTokens(uint16 _numTokens) internal {
        for (uint i = 0; i < _numTokens; i++) {
            _safeMint(msg.sender);
        }

        if (!attributesAvailable()) {
            mostRecentSaleBlock = block.number;
        }
    }

    function _safeMint(address to) internal {
        _safeMint(to, v1Supply + v2Supply);
        v2Supply++;
    }

    /* Provided by Open Zeppelin */

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}