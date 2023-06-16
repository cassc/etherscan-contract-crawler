// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/finance/PaymentSplitter.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBase.sol';

contract HogGang is
    Ownable,
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    VRFConsumerBase,
    PaymentSplitter,
    IERC2981
{
    using Strings for uint256;

    string private _ipfsURI;
    bytes32 private _requestId;
    uint256 private constant FEE = 2e18;
    bytes32 private constant KEY_HASH =
        0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;

    string public constant PROVENANCE =
        '9b48bb444496d772d8415e00dc7064f05589016d9a7229fa2c872baf6c9d7510'; // IPFS Hash as SHA256
    uint256 public constant MAX_PURCHASE = 10;
    uint256 public price = 7e16;
    uint256 public revealAmount;
    uint256 public maxSupply;
    uint256 public saleStart;
    uint256 public offset;
    uint256 public limit;

    constructor(
        uint256 _revealAmount,
        uint256 _maxSupply,
        address[] memory _airdrops,
        address[] memory payees,
        uint256[] memory shares
    )
        ERC721('Hog Gang', 'HOGS')
        PaymentSplitter(payees, shares)
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952,
            0x514910771AF9Ca656af840dff83E8264EcF986CA
        )
    {
        revealAmount = _revealAmount;
        maxSupply = _maxSupply;

        _safeMint(msg.sender, _maxSupply - 1);
        for (uint256 i = 0; i < _airdrops.length; i++) {
            _safeMint(_airdrops[i], i);
        }
    }

    event UpdatePrice(uint256 price);

    function mint(uint256 amount) external payable {
        require(saleStart != 0, 'Sale not yet started');
        require(amount > 0, 'Cannot mint zero');
        require(
            limit == 0 || balanceOf(msg.sender) + amount <= limit,
            'Over limit'
        );

        uint256 supply = totalSupply();
        require(supply < maxSupply, 'Sold out');
        require(
            amount <= MAX_PURCHASE && supply + amount <= maxSupply,
            'Mint amount too high'
        );
        require(msg.value >= price * amount, 'Not enough ETH for minting');

        for (uint256 i = supply - 1; i < supply + amount - 1; i++) {
            _safeMint(msg.sender, i);
        }
    }

    function forceReveal() external {
        _requestId = requestRandomness(KEY_HASH, FEE);
    }

    function reveal() external {
        require(offset == 0, 'Already revealed');
        require(saleStart != 0, 'Sale not yet started');
        require(_requestId == 0, 'Reveal already requested');
        require(
            totalSupply() >= revealAmount ||
                block.timestamp - saleStart >= 2 days,
            'Sale not over'
        );

        _requestId = requestRandomness(KEY_HASH, FEE);
    }

    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        royaltyAmount = salePrice / 10; // 10%
        receiver = address(this);
    }

    function toggleSale(uint256 limit_) external onlyOwner {
        saleStart = saleStart == 0 ? block.timestamp : 0;
        limit = limit_;
    }

    function setLimit(uint256 limit_) external onlyOwner {
        limit = limit_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
        emit UpdatePrice(price);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        require(bytes(_ipfsURI).length == 0, 'baseURI already set');
        _ipfsURI = baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory baseURI = _baseURI();
        if (offset == 0 || bytes(baseURI).length == 0) {
            return 'ipfs://QmeYWiVDxykrzEUaJPRMraLVfvAvP1Qp3DMdn5943b37Nv';
        } else {
            uint256 lastId = maxSupply - 1;
            uint256 hogId = tokenId == lastId
                ? tokenId
                : (tokenId + offset) % (lastId);
            return string(abi.encodePacked(baseURI, hogId.toString(), '.json'));
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return _ipfsURI;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        require(_requestId == requestId, 'Wrong request');
        require(offset == 0, 'Already revealed');

        offset = (randomness % (maxSupply - 1)) + 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}