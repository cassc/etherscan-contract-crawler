// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./Tag.sol";

contract CaffeinatedLions is ERC721Enumerable, Ownable {
    enum SaleState {
        Off,
        Presale,
        Public
    }

    struct SaleData {
        uint256 maxMintPerAddress;
        uint256 maxMintPerTransaction;
        uint256 maxTokensInSale;
        uint256 counter;
        uint256 price;
        bytes32[] merkleroot;
        uint256 merklerootPointer;
        mapping(address => uint256) tokensMintedByAddress;
    }

    using SafeMath for uint256;
    using MerkleProof for bytes32[];

    mapping(address => uint256) public tokensMintedByAddress;
    mapping(address => bool) public freeTokenForWhiteList;
    uint256 public MaxTokensPerAddress = 6;

    SaleData[] public saleData;
    SaleState public saleState;

    address public beneficiary;
    string public baseURI;

    modifier whenPublicSaleStarted() {
        require(
            saleState == SaleState.Public,
            "whenPublicSaleStarted: Incorrect sale state"
        );
        _;
    }

    modifier isPresaleActive() {
        require(
            saleState == SaleState.Presale,
            "isWhitelistSaleActive: Presale not active"
        );
        _;
    }

    modifier whenMerklerootSet(SaleState _presaleNumber) {
        require(
            saleData[uint256(_presaleNumber)].merklerootPointer != 0,
            "whenMerklerootSet: Merkleroot not set for presale"
        );
        _;
    }

    modifier whenAddressOnWhitelist(
        bytes32[] memory _merkleproof,
        uint256 _merklerootPointer
    ) {
        require(
            addressOnWhitelist(_merkleproof, _merklerootPointer),
            "whenAddressOnWhitelist: Not on white list"
        );
        _;
    }

    constructor(
        address _beneficiary,
        string memory _uri
    ) ERC721("CaffeinatedLions", "CFLN") {
        beneficiary = _beneficiary;
        baseURI = _uri;

        saleState = SaleState.Off;
        saleData.push();

        //Presale
        createSale(6, 6, 10000, 0.08 ether, bytes32(0));
        //Public
        createSale(6, 6, 10000, 0.08 ether, bytes32(0));
    }

    function mintPublic(uint256 _numTokens)
        external
        payable
        whenPublicSaleStarted
    {
        uint256 supply = totalSupply();

        uint256 tokens = tokensMintedByAddress[msg.sender].add(_numTokens);

        require(
            tokens <= MaxTokensPerAddress,
            "mintPublic: Cannot mint more than 6 tokens per Address!"
        );

        require(
            _numTokens <= getSale(SaleState.Public).maxMintPerTransaction,
            "mintPublic: Minting more than max per transaction!"
        );

        require(
            supply.add(_numTokens) <= getSale(SaleState.Public).maxTokensInSale,
            "mintPublic: Not enough Tokens remaining."
        );

        require(
            _numTokens.mul(saleData[uint256(saleState)].price) <= msg.value,
            "mintPublic: Incorrect amount sent!"
        );

        uint256 nextTokenId = supply.add(1);

        for (uint256 i; i < _numTokens; i++) {
            _safeMint(msg.sender, nextTokenId.add(i));
        }

        tokensMintedByAddress[msg.sender] = tokens;
    }

    function mintPresale(
        uint256 _numTokens,
        bytes32[] calldata _merkleproof,
        uint256 _merklerootPointer
    ) external payable isPresaleActive whenMerklerootSet(saleState) {
        uint256 currentSupply = totalSupply();

        uint256 freeToken = 0;
        uint256 tokens = tokensMintedByAddress[msg.sender].add(_numTokens);

        if (!freeTokenForWhiteList[msg.sender]) {
            freeToken = 1;
            freeTokenForWhiteList[msg.sender] = true;
        }
        require(
            addressOnWhitelist(_merkleproof, _merklerootPointer),
            "mintPresale: Not on white list"
        );

        require(
            tokens <= MaxTokensPerAddress,
            "mintWhitelist: Exceeds the number of mints per Address"
        );

        require(
            getSale(SaleState.Presale).counter.add(_numTokens) <=
                getSale(SaleState.Presale).maxTokensInSale,
            "mintWhitelist: Not enough Tokens remaining in sale."
        );

        require(
            (_numTokens.sub(freeToken)).mul(saleData[uint256(saleState)].price) <= msg.value,
            "mintWhitelist: Incorrect amount sent!"
        );

        uint256 nextTokenId = currentSupply.add(1);

        for (uint256 i; i < _numTokens; i++) {
            _safeMint(msg.sender, nextTokenId.add(i));
        }

        getSale(SaleState.Presale).counter += _numTokens;
        tokensMintedByAddress[msg.sender] = tokens;
    }

    function getMerkleroot(SaleState _presaleNumber, uint256 _index)
        public
        view
        returns (bytes32)
    {
        require(
            _index <= getSale(_presaleNumber).merklerootPointer,
            "getMerkleroot: index out of bounds"
        );
        return getSale(_presaleNumber).merkleroot[_index];
    }

    function addressOnWhitelist(
        bytes32[] memory _merkleproof,
        uint256 _merklerootPointer
    ) public view returns (bool) {
        return
            MerkleProof.verify(
                _merkleproof,
                getSale(SaleState.Presale).merkleroot[_merklerootPointer],
                keccak256(abi.encodePacked(msg.sender))
            );
    }

    function mintReserveTokens(address _to, uint256 _numTokens)
        public
        onlyOwner
    {
        require(
            _to != address(0),
            "mintReserveTokens: Cannot mint reserve tokens to the burn address"
        );
        uint256 supply = totalSupply();
        require(
            supply.add(_numTokens) <= getSale(SaleState.Public).maxTokensInSale,
            "mintReserveTokens: Cannot mint more than max supply"
        );
        require(_numTokens <= 50, "mintReserveTokens: Gas limit protection");

        uint256 nextTokenId = supply.add(1);

        for (uint256 i; i < _numTokens; i++) {
            _safeMint(_to, nextTokenId.add(i));
        }
    }

    function addMerkleroot(SaleState _saleNumber, bytes32 _merkleroot)
        public
        onlyOwner
    {
        getSale(_saleNumber).merklerootPointer++;
        getSale(_saleNumber).merkleroot.push(_merkleroot);
    }

    function startPublicSale() external onlyOwner {
        saleState = SaleState.Public;
    }

    function startPresale() external onlyOwner {
        require(
            saleState != SaleState.Presale,
            "startPresale: Already in Presale"
        );
        saleState = SaleState.Presale;
    }

    function stopSale() external onlyOwner {
        require(saleState != SaleState.Off, "stopSale: Sale is off");
        saleState = SaleState.Off;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    function withdraw() public {
        uint256 balance = address(this).balance;
        require(payable(beneficiary).send(balance));
    }

    function tokensInWallet(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function getSale(SaleState _saleNumber)
        private
        view
        returns (SaleData storage)
    {
        return saleData[uint256(_saleNumber)];
    }

    function createSale(
        uint256 _maxMintPerAddress,
        uint256 _maxMintPerTransaction,
        uint256 _maxTokensInSale,
        uint256 _price,
        bytes32 _merkleroot
    ) private {
        SaleData storage sale = saleData.push();

        sale.maxMintPerAddress = _maxMintPerAddress;
        sale.maxMintPerTransaction = _maxMintPerTransaction;
        sale.maxTokensInSale = _maxTokensInSale;
        sale.price = _price;
        sale.merkleroot.push(_merkleroot);
    }
}