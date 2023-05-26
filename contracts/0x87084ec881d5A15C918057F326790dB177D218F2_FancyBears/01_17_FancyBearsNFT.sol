// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./Tag.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract FancyBears is ERC721, ERC721Enumerable, Ownable {

    struct PresaleData {
        uint256 maxMintPerAddress;
        uint256 price;
        bytes32 merkleroot;
        uint256 maxTokensInPresale;
        Counters.Counter counter;
        mapping(address => uint256) tokensMintedByAddress;
    }

    using SafeMath for uint256;
    using MerkleProof for bytes32[];
    using Counters for Counters.Counter;

    uint256 public saleState;
    uint256 public maxSupply;
    uint256 public maxMintPerTransaction;
    uint256 public price;
    uint256 public numReserveTokens;
    PresaleData[] public presaleData;
    address public beneficiary;
    Counters.Counter private reserveTokenCounter;
    mapping(address => bool) private reserveTokenMinters;
    string public baseURI;

    modifier whenPublicSaleStarted() {
        require(saleState==4,"Public Sale not active");
        _;
    }

     modifier whenSaleStarted() {
        require(saleState > 0 || saleState < 5,"Sale not active");
        _;
    }
    
    modifier whenSaleStopped() {
        require(saleState == 0,"Sale already started");
        _;
    }

    modifier isWhitelistSale(uint256 presaleNumber) {
        require(presaleNumber > 0 && presaleNumber < 4 , "Parameter must be a valid presale");
        _;
    }

    modifier whenWhitelistSet(uint256 _presaleNumber) {
        require(presaleData[_presaleNumber].merkleroot!=0,"Whitelist not set");
        _;
    }

    modifier whenMerklerootSet(uint256 _presaleNumber) {
        require(presaleData[_presaleNumber].merkleroot!=0,"Merkleroot not set for presale");
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

    constructor() ERC721("Fancy Bears", "BEARS") {

        baseURI = "https://api.fancybearsmetaverse.com/";
        price = 0.19 ether;
        beneficiary = 0x9f42EA517fBfB332959B20E0A8167e7fbE1A8496;
        saleState = 0;
        maxSupply = 8888;
        maxMintPerTransaction = 4;
        numReserveTokens = 1000;

        presaleData.push();

        //Fanadise whitelist sale data
        createPresale(4, 0.125 ether, 788);
        //BAYC whitelist sale data
        createPresale(4, 0.135 ether, 1000);
        //Public whitelist sale data
        createPresale(4, 0.15 ether, 4101);

        addReserveTokenMinters(0x72b6f2Ed3Cc57BEf3f5C5319DFbFe82D29e0B93F);
    }

    function addReserveTokenMinters(address _address) public onlyOwner {
        require(_address!=address(0),"Cannot add the Black Hole as a minter");
        require(!reserveTokenMinters[_address],"Address already a minter");
        reserveTokenMinters[_address] = true;
    }

    function removeReserveTokenMinters(address _address) public onlyOwner {
        require(reserveTokenMinters[_address],"Address not a current minter");
        reserveTokenMinters[_address] = false;
    }

    function createPresale(
        uint256 _maxMintPerAddress, 
        uint256 _price, 
        uint256 _maxTokensInPresale
    )
        private
    {
        PresaleData storage presale = presaleData.push();

        presale.maxMintPerAddress = _maxMintPerAddress;
        presale.price = _price;
        presale.maxTokensInPresale = _maxTokensInPresale;
    }

    function startPublicSale() external onlyOwner() {
        require(saleState == 0, "Sale already started");
        saleState = 4;
    }

    function startWhitelistSale(uint256 _presaleNumber) external 
        whenSaleStopped()
        isWhitelistSale(_presaleNumber) 
        whenMerklerootSet(_presaleNumber)
        onlyOwner() 
    {
        saleState = _presaleNumber;
    }
    
    function stopSale() external whenSaleStarted() onlyOwner() {
        saleState = 0;
    }

    function mintPublic(uint256 _numTokens) external payable whenPublicSaleStarted() {
        uint256 supply = totalSupply();
        require(_numTokens <= maxMintPerTransaction, "Minting too many tokens at once!");
        require(supply.add(_numTokens) <= maxSupply.sub(numReserveTokens), "Not enough Tokens remaining.");
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
        uint256 presaleSupply = getPresale().counter.current();
        uint256 numWhitelistTokensByAddress = getPresale().tokensMintedByAddress[msg.sender];
        
        require(numWhitelistTokensByAddress.add(_numTokens) <= getPresale().maxMintPerAddress,"Exceeds the number of whitelist mints");
        require(presaleSupply.add(_numTokens) <= getPresale().maxTokensInPresale, "Not enough Tokens remaining in presale.");
        require(_numTokens.mul(getPresale().price) <= msg.value, "Incorrect amount sent!");
  
        for (uint256 i; i < _numTokens; i++) {
            _safeMint(msg.sender, currentSupply.add(1).add(i));
            getPresale().counter.increment();
        }

        getPresale().tokensMintedByAddress[msg.sender] = numWhitelistTokensByAddress.add(_numTokens);
    
    }

    //Add addresses who can mint reserve tokens

    function mintReserveTokens(address _to, uint256 _numTokens) public {
        require(_to!=address(0),"Cannot mint reserve tokens to the burn address");
        uint256 supply = totalSupply();
        require(reserveTokenMinters[msg.sender],"Not approved to mint reserve tokens");
        require(reserveTokenCounter.current().add(_numTokens) <= numReserveTokens,"Cannot mint more than alloted for the reserve");
        require(supply.add(_numTokens) < maxSupply, "Cannot mint more than max supply");
        require(_numTokens<=50,"Gas limit protection");

        for (uint256 i; i < _numTokens; i++) {
            _safeMint(msg.sender, supply.add(1).add(i));
            reserveTokenCounter.increment();
        }

    }

    function getPresale() private view returns (PresaleData storage) {
        return presaleData[saleState];
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function setMerkleroot(uint256 _presaleNumber, bytes32 _merkleRoot) public 
        whenSaleStopped() 
        isWhitelistSale(_presaleNumber)
        onlyOwner 
    {
        presaleData[_presaleNumber].merkleroot = _merkleRoot;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    function withdraw() public {
        uint256 balance = address(this).balance;
        require(payable(beneficiary).send(balance));
    }

    function tokensInWallet(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
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