// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.2;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Borpacasso {
    function balanceOf(address owner) public view virtual returns(uint256) {
    }
}

contract Borpi is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    string private _baseURIPrefix;

    mapping(address => uint) public whitelist;
    mapping(uint => mapping(address => uint)) public raffleList;
    mapping(address => uint) public claimed;
    uint public raffleSaleIndex;
  
    uint256 private tokenPrice = 100000000000000000; //0.1 ETH
    uint256 private constant nftsNumber = 1750;
    uint256 private constant nftsPublicNumber = 1735;
    uint32 private maxTokensPerTransaction = 3;
    address private constant borpFanOne = 0xb0e7d87fCB3d146d55EB694f9851833f18a7dB11;
    address private constant borpFanTwo = 0xCd2732220292022cC8Ab82173D213f4F51F99f76;
    bool public whitelistSaleActive;
    bool public raffleSaleActive;
    bool public uriUnlocked = true;
    bool public supplyCapped;
    bool public raffleDisabled;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Salvador Borpi", "BORP2") {
        _tokenIdCounter.increment();
    }

    function setBaseURI(string memory baseURIPrefix) public onlyOwner {
        require(uriUnlocked, "Not happening.");
        _baseURIPrefix = baseURIPrefix;
    }
    function _baseURI() internal view override returns(string memory) {
        return _baseURIPrefix;
    }

    function borpacassoBalance(address owner) public view virtual returns(uint256) {
        Borpacasso sd = Borpacasso(0x370108CF39555e561353B20ECF1eAae89bEb72ce);
        return sd.balanceOf(owner);
    }

    function setMaxTokens(uint32 a) public onlyOwner{
        maxTokensPerTransaction = a;
    }
    function lockURI() public onlyOwner {
        uriUnlocked = false;
    }
    function capSupply() public onlyOwner {
        supplyCapped = true;
    }

    function safeMint(address to) public onlyOwner {
        require(!supplyCapped, "The supply has been capped");
        require(_tokenIdCounter.current() <= nftsNumber, "Sry I dont have enough left ;(");
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function howManyBorp() public view returns(uint256 a){
        return Counters.current(_tokenIdCounter);
    }
    function allotmentOf(address _a) public view returns(uint a){
        return whitelist[_a];
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
    returns(bool)
    {
        return super.supportsInterface(interfaceId);
    }
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns(string memory)
    {
        return super.tokenURI(tokenId);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        uint cut = balance.div(2);
        payable(borpFanOne).transfer(cut);
        payable(borpFanTwo).transfer(cut);
    }

    function addToWhitelist(address[] memory _address, uint32[] memory _amount)public onlyOwner {
        for (uint i = 0; i < _address.length; i++) {
            whitelist[_address[i]] = _amount[i];
        }
    }
    function removeFromWhitelist(address[] memory _address)public onlyOwner {
        for (uint i = 0; i < _address.length; i++) {
            whitelist[_address[i]] = 0;
        }
    }

    function addToRaffleList(address[] memory _address, uint32[] memory _amount)public onlyOwner {
        for (uint i = 0; i < _address.length; i++) {
            raffleList[raffleSaleIndex][_address[i]] = _amount[i];
        }
    }

    function flipRaffleDisabled() public onlyOwner{
        raffleDisabled = !raffleDisabled;
    }

    function flipWhitelistSale() public onlyOwner {
        whitelistSaleActive = !whitelistSaleActive;
    }
    function flipRaffleSale() public onlyOwner {
        raffleSaleIndex += raffleSaleActive ? 1 : 0;
        raffleSaleActive = !raffleSaleActive;
    }

    function mintGiveawayBorps(address to, uint256 tokenId) public onlyOwner {
        require(tokenId > nftsPublicNumber, "Those aren't for you");
        require(tokenId <= nftsNumber, "Those aren't for you");
        _safeMint(to, tokenId);
    }

    function allotmentScaleOf(uint a) private pure returns(uint b){
        if (a >= 50) { return 5; }
        else if (a >= 25) { return 4; }
        else if (a >= 10) { return 3; }
        else if (a >= 5) { return 2; }
        else if (a >= 1) { return 1; }
        else return 0;
    }

    function buyWhitelistBorp(uint tokensNumber) public payable {
        require(!supplyCapped, "The supply has been capped");
        require(whitelistSaleActive, "Maybe later");
        require(_tokenIdCounter.current().add(tokensNumber) <= nftsPublicNumber + 1, "Sry I dont have enough left for that ;(");
        require(tokensNumber > 0, "U cant mint zero borps bro");
        require(tokenPrice.mul(tokensNumber) <= msg.value, "That's not enough, sry ;(");

        require(tokensNumber <= whitelist[msg.sender], "You can't claim more than your allotment");
        require(claimed[msg.sender].add(tokensNumber) <= allotmentScaleOf(borpacassoBalance(msg.sender)), "You're not holding enough borpacassos to claim that many");

        for (uint i = 0; i < tokensNumber; i++) {
            if (_tokenIdCounter.current() <= nftsPublicNumber) {
                require(whitelist[msg.sender] >= 1, "You don't have any more Borpis to claim");
                require(tokensNumber.sub(i) <= whitelist[msg.sender], "You can't claim more than your allotment");
                require(claimed[msg.sender].add(tokensNumber).sub(i) <= allotmentScaleOf(borpacassoBalance(msg.sender)), "You're not holding enough borpacassos to claim that many");
                require(_tokenIdCounter.current() <= nftsPublicNumber + 1, "Sry I dont have enough left ;(");

                claimed[msg.sender] += 1;
                whitelist[msg.sender] = whitelist[msg.sender].sub(1);

                _safeMint(msg.sender, _tokenIdCounter.current());
                _tokenIdCounter.increment();
            }
        }
    }

    function buyRaffleBorp(uint tokensNumber) public payable {
        require(!supplyCapped, "The supply has been capped");
        require(raffleSaleActive, "Maybe later");
        require(tokensNumber > 0, "U cant mint zero borps bro");
        require(_tokenIdCounter.current().add(tokensNumber) <= nftsPublicNumber + 1, "Sry I dont have enough left ;(");
        require(tokenPrice.mul(tokensNumber) <= msg.value, "That's not enough, sry ;(");

        if (!raffleDisabled) {
            require(tokensNumber == raffleList[raffleSaleIndex][msg.sender], "You must claim the exact amount you were allotted.");
            raffleList[raffleSaleIndex][msg.sender] = 0;
        }
        else {
            require(tokensNumber <= maxTokensPerTransaction, "Save some for everyone else!");
        }

        for (uint i = 0; i < tokensNumber; i++) {
            if (_tokenIdCounter.current() <= nftsPublicNumber) {
                _safeMint(msg.sender, _tokenIdCounter.current());
                _tokenIdCounter.increment();
            }
        }
    }
}