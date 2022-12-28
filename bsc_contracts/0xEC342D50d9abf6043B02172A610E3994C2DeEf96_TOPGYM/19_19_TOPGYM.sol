// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract TOPGYM is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    event Mint(address indexed to, address indexed ref, uint256 timestamp, uint256 indexed price, uint256 amount);

    struct Sale {
        uint64 start; // start time, unixtimstamp
        uint64 end; // end time, unixtimstamp
        uint256 priceUsd; //usd, 1e18 = 1$
        uint256 amount; // amount to sell
        uint256 remainAmounts; // remain amounts
        bool paused;
    }
    Sale private _sale;
    uint32 public constant MAX_SUPPLY = 10126;
    uint16[MAX_SUPPLY] private ids;
    uint256 private constant COOLDOWN_BLOCKS = 1;
    uint256 public MAX_MINT_BATCH = 30;
    string public baseURI;
    uint256 private index;

    AggregatorV3Interface private _priceFeedBUSD; // BNB/BUSD
    IERC20 private _tokenBUSD; // BUSD token
    EnumerableSet.AddressSet private _origins;

    uint256[5] private refPercents = [5,5,0,0,0]; // 10%
    mapping(address => address) public fathers;
    mapping(address => address[]) public childs;
    mapping(address => uint256) public usdSums;
    mapping(address => uint256) private _blocks;

    modifier cooldown() {
        require(
            _origins.add(tx.origin) ||
                block.number > _blocks[tx.origin] + COOLDOWN_BLOCKS,
            "Cooldown, baby!"
        );
        _blocks[tx.origin] = block.number;
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory baseUri,
        address tokenBUSDAddress,
        address priceFeedBUSDAddress
    ) ERC721(name, symbol) {
        baseURI = baseUri;
        _priceFeedBUSD = AggregatorV3Interface(priceFeedBUSDAddress);
        _tokenBUSD = IERC20(tokenBUSDAddress);
        _sale = Sale(0, 0, 300 ether, 0, 0, true);
    }

    // ------------- Public Views methods -----------------

    function getSale() public view returns (Sale memory) {
        return _sale;
    }
    
    function getChilds(address father) public view returns(address[] memory){
        return childs[father];
    }
    // function getChildsCounts(address a) public view returns(uint256[5] memory){
    //     return childsCounts[a];
    // }

    function getRefPercents() public view returns(uint256[5] memory){
        return refPercents;
    }

    function getBNBper1USD() public view returns (uint256) {
        (, int256 price, , , ) = _priceFeedBUSD.latestRoundData();
        return uint256(price);
    }

    function getBUSDPerNFT(uint256 count) public view returns (uint256){
        return count * _sale.priceUsd;
    }

    function getBNBperNFT(uint256 count) public view returns (uint256) {
        return _sale.priceUsd * ((getBNBper1USD() * 1e6 )/1e18) / 1e6 * count;
    }

    function tokenURI( uint256 tokenId ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : ".json";
    }

    // ---------- Internal Private methods -------------

    function _pickRandomUniqueId(uint256 random) private returns (uint256 id) {
        uint256 len = ids.length - index++;
        require(len > 0, 'no ids left');
        uint256 randomIndex = random % len;
        id = ids[randomIndex] != 0 ? ids[randomIndex] : randomIndex;
        ids[randomIndex] = uint16(ids[len - 1] == 0 ? len - 1 : ids[len - 1]);
        ids[len - 1] = 0;
    }

    function mint(address to, uint256 mintAmount) private whenNotPaused {
        require(_sale.remainAmounts>=mintAmount, "insufficient amount");
        require(mintAmount > 0, "cant mint 0 tokens");
        require(mintAmount <= MAX_MINT_BATCH, "max mint reached");
        require(totalSupply() + mintAmount <= MAX_SUPPLY, "max supply reached");
        for (uint256 i = 1; i <= mintAmount; i++) {
            uint256 _random = uint256(keccak256(abi.encodePacked(index++, msg.sender, block.timestamp, blockhash(block.number-1))));
            _safeMint(to, _pickRandomUniqueId(_random));
        }
        _sale.remainAmounts -= mintAmount;

        emit Mint(to, fathers[to], block.timestamp, _sale.priceUsd, mintAmount);
    }


    function sendBNB(address to, uint256 val) private {
        if (val > 0) {
            (bool success, ) = payable(to).call{value:val}("");
            require(success);
        }
    }

    function addRef(address user, address ref) private {
        if (ref != user) {
            if (fathers[user] == address(0)) {
                fathers[user] = ref;
                childs[ref].push(user);
            }
        }
    }


    function rewardingRef(address user, uint256 totalPrice, bool isBUSD) private {
        uint256 i;
        address father = user;
        uint256 subBonusUsd = 0;
        for(i=0; i<refPercents.length; i++){
            father = fathers[father];
            if( father == address(0) ) break;
            uint256 bonus = totalPrice / 100 * refPercents[i];
            if(isBUSD){
                subBonusUsd+=bonus;
                _tokenBUSD.transferFrom(msg.sender, father, bonus);
            }else{
                sendBNB(father, bonus);
            }
        }
        if(isBUSD) _tokenBUSD.transferFrom( msg.sender, address(this), totalPrice - subBonusUsd);
    }

 
    // ----- External public write methods --------

    function buyForUSD(address to,uint256 mintAmount,address ref ) external whenNotPaused nonReentrant cooldown {
        uint256 priceBUSD = getBUSDPerNFT(mintAmount);
        mint(to, mintAmount);
        addRef(to, ref);
        rewardingRef(to, priceBUSD, true);
        usdSums[to]+=priceBUSD;
    }

    function buyForBNB( address to, uint256 mintAmount, address ref ) external payable whenNotPaused cooldown nonReentrant {
        require(mintAmount>0);
        uint256 priceBNB = getBNBperNFT(mintAmount);
        uint256 priceBUSD = getBUSDPerNFT(mintAmount);
        require(msg.value >= priceBNB, "insuffucient value");
        mint(to, mintAmount);
        sendBNB(msg.sender, msg.value - priceBNB);
        addRef(to, ref);
        rewardingRef(to, priceBNB, false);
        usdSums[to]+=priceBUSD;
    }
    
    receive() external payable {
        uint256 priceBNB = getBNBperNFT(1);
        uint256 mintAmount = msg.value / priceBNB;
        require(mintAmount>1, "insuffucient value");
        priceBNB *= mintAmount;
        mint(msg.sender, mintAmount);
        sendBNB(msg.sender, msg.value - priceBNB);
        usdSums[msg.sender] += getBUSDPerNFT(mintAmount);
    }

    // ----- External onlyOwner methods --------

    function sell( address to, uint256 mintAmount) external onlyOwner whenNotPaused {
        require(mintAmount>0);
        mint(to, mintAmount);
        usdSums[to] += getBUSDPerNFT(mintAmount);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        sendBNB(msg.sender, balance);
        uint256 balanceBUSD = _tokenBUSD.balanceOf(address(this));
          _tokenBUSD.transfer(msg.sender, balanceBUSD);
    }


    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setMaxMintBatch(uint32 newMaxMintBatch) external onlyOwner {
        MAX_MINT_BATCH = newMaxMintBatch;
    }

    function setRefPercents(uint256[] memory newRefPercents) external onlyOwner {
        require(newRefPercents.length<=refPercents.length, "incorrect count");
        uint256 i;
        for(i=0;i<newRefPercents.length;i++){
            refPercents[i]=newRefPercents[i];
        }
    }

    function setPriceFeed(address priceFeedBUSDAddress) external onlyOwner {
        _priceFeedBUSD = AggregatorV3Interface(priceFeedBUSDAddress);
    }


    function setSale( uint64 start, uint64 end, uint256 priceUsd, uint256 amount, bool pause ) external onlyOwner {
        require(start>=block.timestamp-300, "start expired");
        require(end>=start+60, "bad interval");
        require(priceUsd>=1e15,"priceUsd must be more than 0.001");
        require(amount>0,"amount 0");
        _sale = Sale( start, end, priceUsd, amount, amount, pause);
    }

    function pauseSale() external onlyOwner{
        require(!_sale.paused, "already paused");
       _sale.paused = true;
    }

    function unpauseSale() external onlyOwner{
        require(_sale.paused, "already unpaused");
       _sale.paused = false;
    }

    // ---------- Override methods --------------
    
    function paused() public view virtual override returns (bool) {
        return _sale.paused || _sale.start > block.timestamp || _sale.end < block.timestamp;
    }
}