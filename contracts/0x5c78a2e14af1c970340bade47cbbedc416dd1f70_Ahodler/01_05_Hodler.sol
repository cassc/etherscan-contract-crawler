// SPDX-License-Identifier: MIT
// ARTWORK LICENSE: CC0
// ahodler.world - Totaler Mint, Blitzmint, 10% Royalties
// On-Chain Battle Royale
// LIVE
pragma solidity 0.8.15;
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract Ahodler is ERC721A, Ownable {
    address private constant TEAMWALLET = 0x30394DD17758092e72AF2283F57aB9DeD6E93d87;
    address public contractCreator;
    string private baseURI;

    bool public started = false;
    bool public claimed = false;
    uint256 public constant MAXSUPPLY = 8818;
    uint256 public constant WALLETLIMIT = 3;
    uint256 public constant TEAMCLAIMAMOUNT = 418;

    uint256 public reichsMark = 0.18 ether;
    uint256 public attackDate = 1662011100;         // 1st of September, 5.45am GMT
    mapping(address => uint) public addressClaimed;

    int256[] public hodlers;
    address private battleRoyaleContract;
    bool public brRunning = false;

    constructor() ERC721A("aHODLer", "HODL") {
        contractCreator = msg.sender;
        hodlers.push(-1);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    
    function mint(uint256 _count) external payable {
        uint256 total = totalSupply();
        uint256 minCount = 0;
        uint j;
        if(msg.sender != contractCreator) {
            require(started, "Achtung: Mint has not started yet");
            require(addressClaimed[_msgSender()] + _count <= WALLETLIMIT, "Achtung: Wallet limit, you can't mint more than that");
            if(block.timestamp > attackDate) {
                require(msg.value >= reichsMark, "Achtung: the war has started and you have not sent enough Reichsmark!");
            }
        }
        require(_count > minCount, "Achtung: You need to mint at least one");
        require(total + _count <= MAXSUPPLY, "Achtung: Mint out, no more NFTs left to mint");
        require(total <= MAXSUPPLY, "Achtung: Mint out");

        for (j = 0; j < _count; j++) {
                hodlers.push(0);
        }
        addressClaimed[_msgSender()] += _count;
        _safeMint(msg.sender, _count);
    }

    function startBR(bool _bool) external onlyOwner {
        brRunning = _bool;
    }

    function setHealth(uint256 _tokenId, int256 _amount) external {
        require(brRunning, "Battle Royale hasn't started yet!");
        require(hodlers[_tokenId] > -1, "This Hodler is already dead");
        require(battleRoyaleContract == _msgSender(), "Function can only be called by Contract");
        if(_amount < 0){
            require(!(hodlers[_tokenId]+_amount<-1),"ACHTUNG: That are too many grenades, try less");
        }
        (hodlers[_tokenId]+_amount) < 0 ? hodlers[_tokenId] = -1 : hodlers[_tokenId] = hodlers[_tokenId] + _amount;
    }

    function getHodlerPopulation() external view returns(uint _population){
        uint j;
        for (j = 0; j < hodlers.length; j++) {
            if(hodlers[j] > -1){
                _population++;
            }
        }
    }

    function checkLastSurvivor() external view returns(uint256 _winner){
        uint j;
        for (j = 0; j < hodlers.length; j++) {
            if(hodlers[j] > -1){
                _winner = j;
            }
        }
    }

    function isHodlerAlive(uint256 _tokenId) external view returns(bool _alive){
       hodlers[_tokenId] < 0 ? _alive = false : _alive = true;
    }

    function setBrContract(address _input) external onlyOwner{
       battleRoyaleContract = _input;
    }
    // -------------------------------
    function teamClaim() external onlyOwner {
        uint j;
        require(!claimed, "Achtung: Team has already claimed");
        _safeMint(TEAMWALLET, TEAMCLAIMAMOUNT);
        claimed = true;
        for (j = 0; j < TEAMCLAIMAMOUNT; j++) {
            hodlers.push(0);
        }

    }
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    function startBlitz(bool blitzMint) external onlyOwner {
        started = blitzMint;
    }
    function inflationCall(uint256 _newmarks) external onlyOwner {
        reichsMark = _newmarks;
    }
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'Achtung: There is no token with that ID');
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _toString(_tokenId), '.json')) : '';
    }
    // ----------------------------------------------------------------- WITHDRAW
    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
    function withdrawAllToAddress(address addr) public onlyOwner {
        require(payable(addr).send(address(this).balance));
    }
}

interface interfaceAhodler{
    function setHealth(uint256 _tokenId, int256 _amount) external;
    function getHodlerPopulation() external view returns(uint _population);
    function isHodlerAlive(uint256 _tokenId) external view returns(bool _alive);
    function checkLastSurvivor() external view returns(uint256 _winner);
    function ownerOf(uint256 tokenId) external view returns (address);
}