// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./Tag.sol";

contract HolyOnes is ERC721, ERC721Enumerable, Ownable {

    enum SaleState {
        Off,
        Presale1,
        Public,
        Soldout
    }

    struct PresaleData {
        uint256 maxMintPerAddress;
        uint256 maxMintPerTransaction;
        uint256 price;
        bytes32 merkleroot;
        uint256 maxTokensInPresale;
        uint256 counter;
        mapping(address => uint256) tokensMintedByAddress;
    }

    using SafeMath for uint256;
    using MerkleProof for bytes32[];

    SaleState public saleState;
    uint256 public maxSupply;
    uint256 public maxMintPerTransaction;
    uint256 public price;
    PresaleData[] public presaleData;
    address public beneficiary;
    string public baseURI;
    bool public resurrected; 
    string public provenance;

    modifier whenPublicSaleStarted() {
        require(saleState==SaleState.Public,"Public Sale not active");
        _;
    }

     modifier whenSaleStarted() {
        require(
            saleState==SaleState.Presale1 ||
            saleState==SaleState.Public,
            "Sale not active"
        );
        _;
    }
    
    modifier whenSaleOff() {
        require(
            saleState==SaleState.Off,
            "Sale is active"
        );
        _;
    }

    modifier isWhitelistSale(SaleState _saleState) {
        require(
            _saleState==SaleState.Presale1, 
            "Parameter must be a valid presale"
        );
        _;
    }

    modifier whenMerklerootSet(SaleState _presaleNumber) {
        require(presaleData[uint(_presaleNumber)].merkleroot!=0,"Merkleroot not set for presale");
        _;
    }

    modifier whenAddressOnWhitelist(bytes32[] memory _merkleproof) {
        require(MerkleProof.verify(
            _merkleproof,
            getPresale().merkleroot,
            keccak256(abi.encodePacked(msg.sender))
            ),
            "Not on white list"
        );
        _;
    }

    constructor() ERC721("TheHolyOnes", "THO") {
        price = 0.0666 ether;
        beneficiary = 0x2C554b28879d44f254491f32d277dd59aA7379a1;
        saleState = SaleState.Off;
        maxSupply = 6666;
        maxMintPerTransaction = 50;
        resurrected = false;
        provenance = "0fa50629e15b001d3789271ba840bbe2e26764684b22f1e402a6a110e502b212";

        presaleData.push();

        // Presale 1
        createPresale(100, 50, 0.0666 ether, 4444);
    }

    function mintPublic(uint256 _numTokens) external payable whenPublicSaleStarted() {
        uint256 supply = totalSupply();
        require(_numTokens <= maxMintPerTransaction, "Minting too many tokens at once!");
        require(supply.add(_numTokens) <= maxSupply, "Not enough Tokens remaining.");
        require(_numTokens.mul(price) <= msg.value, "Incorrect amount sent!");

        for (uint256 i; i < _numTokens; i++) {
            _safeMint(msg.sender, supply.add(1).add(i));
        }
    }

    function mintWhitelist(uint256 _numTokens, bytes32[] calldata _merkleproof) external payable 
        isWhitelistSale(saleState)
        whenMerklerootSet(saleState)
        whenAddressOnWhitelist(_merkleproof)
    {
        uint256 currentSupply = totalSupply();
        uint256 presaleSupply = getPresale().counter;
        uint256 numWhitelistTokensByAddress = getPresale().tokensMintedByAddress[msg.sender];
        
        require(_numTokens<=getPresale().maxMintPerTransaction, "Cannot mint that many tokens in one transaction");
        require(numWhitelistTokensByAddress.add(_numTokens) <= getPresale().maxMintPerAddress,"Exceeds the number of whitelist mints");
        require(presaleSupply.add(_numTokens) <= getPresale().maxTokensInPresale, "Not enough Tokens remaining in presale.");
        require(currentSupply.add(_numTokens) <= maxSupply, "Not enough Tokens remaining in sale.");
        require(_numTokens.mul(getPresale().price) <= msg.value, "Incorrect amount sent!");
  
        for (uint256 i; i < _numTokens; i++) {
            _safeMint(msg.sender, currentSupply.add(1).add(i));
            getPresale().counter++;
        }

        getPresale().tokensMintedByAddress[msg.sender] = numWhitelistTokensByAddress.add(_numTokens);
    
    }

    function mintReserveTokens(address _to, uint256 _numTokens) public onlyOwner {
        require(saleState==SaleState.Off,"Sale must be off to reserve tokens");
        require(_to!=address(0),"Cannot mint reserve tokens to the burn address");
        uint256 supply = totalSupply();
        require(supply.add(_numTokens) <= maxSupply, "Cannot mint more than max supply");
        require(_numTokens <= 50,"Gas limit protection");

        for (uint256 i; i < _numTokens; i++) {
            _safeMint(_to , supply.add(1).add(i));
        }
    }

    function getTokensMintedByAddressInPresale(uint256 _presaleNumber, address _address) 
        public 
        view 
        returns (uint256)
    {
        return presaleData[uint(_presaleNumber)].tokensMintedByAddress[_address];
    }

    function tokensInWallet(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdraw() public {
        uint256 balance = address(this).balance;
        require(payable(beneficiary).send(balance));
    }

    function ressurect() public onlyOwner {
        require(!resurrected, "Holy Ones have already been resurrected");
        resurrected = true;
    }

    function startPublicSale() external onlyOwner() whenSaleOff(){
        saleState = SaleState.Public;
    }

    function startWhitelistSale(SaleState _presaleNumber) external 
        whenSaleOff()
        isWhitelistSale(_presaleNumber) 
        whenMerklerootSet(_presaleNumber)
        onlyOwner() 
    {
        saleState = _presaleNumber;
    }
    
    function stopSale() external whenSaleStarted() onlyOwner() {
        saleState = SaleState.Off;
    }

    function setMerkleroot(SaleState _presaleNumber, bytes32 _merkleRoot) public 
        whenSaleOff() 
        isWhitelistSale(_presaleNumber)
        onlyOwner 
    {
        presaleData[uint(_presaleNumber)].merkleroot = _merkleRoot;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    function createPresale(
        uint256 _maxMintPerAddress, 
        uint256 _maxMintPerTransaction,
        uint256 _price, 
        uint256 _maxTokensInPresale
    )
        private
    {
        PresaleData storage presale = presaleData.push();

        presale.maxMintPerAddress = _maxMintPerAddress;
        presale.maxMintPerTransaction = _maxMintPerTransaction;
        presale.price = _price;
        presale.maxTokensInPresale = _maxTokensInPresale;
    }

    function getPresale() private view returns (PresaleData storage) {
        return presaleData[uint(saleState)];
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}