import './ERC721Enumerable.sol';
import './Ownable.sol';
import './interfaces/IERC721.sol';
import './interfaces/IERC20.sol';

pragma solidity ^0.8.6;

contract KEDU is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIds;
    
    // Mapping tracks each MultiVisa token's mints used, each MultiVisa token entitles holder to mint 3 KEDU, through the mintWithPass method
    mapping(uint256 => uint256) public mintAmtUsed;

    // 100 = 100%
    uint256 ownerShare = 54;
    uint256 share1 = 10;
    uint256 share2 = 36;

    uint256 public itemPrice;
    uint256 public _reserved = 34; // for giveaway
    uint256 public constant MULTIVISA_TOTAL_SUPPLY = 400;
    uint256 public constant MINT_PER_MULTIVISA = 3;
    uint256 public MINT_LIMIT = 10;  // Max mint allowed per transaction
    bool public isActive = false;  // Access modifier for mint function
    bool public isEarlyAccess = false;  // Access modifier for mintWithPass function
    bool public mintFinalized = false;  // Ends all minting when set to true, cannot undo
    string public baseURI;
    address public multivisa;
    address private share1Address = 0xFF129e3d95C6Ad2940f3A468d46d9aE25BB3bFe0;
    address private share2Address = 0x021A440Eb6C24df41591D1C79875d8Cb66F18d57;

    constructor (address _multivisa) ERC721("Keplers Civil Society", "KEDU"){
        baseURI = "https://gateway.pinata.cloud/ipfs/QmS2ZABaYmAjSmDgb6yyGnvVPdxQdYUHwAx71JRqny141p/";
        itemPrice = 40000000000000000; // 0.04 ETH
        multivisa = _multivisa;
        transferOwnership(address(0x5c8FC210f2ccEC69e0a78A0Ce675fcDd39BF6ba8));
    }

    // Public Mint
    function mint(uint _numMints) public payable {
        require(isActive,  "Keplers Civil Society Sale Has Not Started");
        require(!mintFinalized,  "Minting finalized.");
        require(_tokenIds.current() + _numMints <= 7777 - _reserved,  "Minting Maxed Out");
        require(msg.value >= itemPrice * _numMints,  "Insufficient ETH sent for Payment");
        require(_numMints <= MINT_LIMIT,  "Specified Amount Over Max Mints Per Transaction Limit");
        require(_numMints > 0,  "Youre Welcome");
        
        for(uint i = 0; i < _numMints; i++) {
            uint256 newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
            _tokenIds.increment();
        }
    }

    // Early Mint For Multivisa Holders
    function mintWithPass(uint _tokenID, uint _numMints) public payable {
        require(isEarlyAccess,  "Keplers Civil Society Early Access Sale Has Not Started");
        require(!mintFinalized,  "Minting finalized.");
        require(IERC721(multivisa).ownerOf(_tokenID) == msg.sender,  "You do not own the Multivisa with specified ID");
        require(mintAmtUsed[_tokenID] + _numMints <= MINT_PER_MULTIVISA,  "Multivisa of Specified Token ID Cannot Mint Requested Amount");
        require(msg.value >= itemPrice * _numMints,  "Insufficient ETH sent for Payment");
        require(_numMints > 0,  "Youre Welcome");

        mintAmtUsed[_tokenID] += _numMints;

        for(uint i = 0; i < _numMints; i++) {
            uint256 newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
            _tokenIds.increment();
        }
    }

    // Owner can mint up to 34 Kedu for giveaways, sends _amount of kedu to _to address, onlyOwner Access
    function giveAway(address _to, uint256 _amount) public onlyOwner {
        require(_amount <= _reserved, "Requested Giveaway Exceeds Giveaway Reserves");
        require(_amount > 0, "Cant give away nothing");
        _reserved -= _amount;
        for(uint256 i; i < _amount; i++) {
            uint256 newItemId = _tokenIds.current();
            _safeMint(_to, newItemId);
            _tokenIds.increment();
        }
    }

    // Settors, onlyOwner access
    
    // Access modifier for mint function
    function setActive(bool _val) public onlyOwner {
        isActive = _val;
    }

    // Access modifier for mintWithPass
    function setEarlyAccess(bool _val) public onlyOwner {
        isEarlyAccess = _val;
    }

    // Set Max Mint Per Transaction Limit
    function setMintLimt(uint256 _limit) public onlyOwner {
        require(!isActive, "Cannot Change Mint Limit While Sale is Active");
        MINT_LIMIT = _limit;
    }

    // Finalizes mint
    function endMint() public onlyOwner {
        mintFinalized = true;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function setItemPrice(uint256 _price) public onlyOwner {
        require(!isActive, "Cannot Change Price While Sale is Active");
		itemPrice = _price;
	}

    // Gettors, view functions

    function _baseURI() internal view override returns (string memory){
        return baseURI;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(_baseURI(), _tokenId.toString(), ".json")) : "";
    }
     
    // Returns amount Multivisa with ID _tokenID has minted, starts at 0 and max is 3
    function getMintedCountForMultiVisaId(uint _tokenID) public view returns (uint256) {
        require(_tokenID < MULTIVISA_TOTAL_SUPPLY, "Invalid Multivisa Token ID");
        return mintAmtUsed[_tokenID];
    }

    function getItemPrice() public view returns (uint256){
		return itemPrice;
	}
	
    // Returns array of tokenID's that input address _owner owns
    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    // Utility Functions, onlyOwner access
    
    function withdrawEth() public onlyOwner {
        uint256 total = address(this).balance;
        uint256 ownerWithdraw = total*ownerShare/100;
        uint256 share1Withdraw = total*share1/100;
        uint256 share2Withdraw = total*share2/100;
        require(payable(owner()).send(ownerWithdraw));
        require(payable(share1Address).send(share1Withdraw));
        require(payable(share2Address).send(share2Withdraw));
    }

    // Rescue any ERC-20 tokens that are sent to contract mistakenly
    function withdrawToken(IERC20 _token, uint256 _amount) public onlyOwner {
        _token.transferFrom(address(this), owner(), _amount);
    }
}