// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./PudgyPenguinsInterface.sol";
import "./WithdrawFairly.sol";

// @author: miinded.com

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//                                                            //
//                                                            //
//                                                            //
//                                                            //
//                                                            //
//                                                            //
//                                                            //
//                                                            //
//                                                            //
//                                                            //
//                         =-:*=.                             //
//                         #@@@@@@*:                          //
//                      .+%@@@@@@@@@@*:                       //
//                     [email protected]@@@@@@@@@@@@@@*                      //
//                    [email protected]@@@@@@@@@@@@@@@@#                     //
//                    @@@@@@@@@@@@@@@@@@@:                    //
//                    @@@@@@@@@@@@@@@@@@@=                    //
//                  :#@@@@@@@@@@@@@@@@@@@@*.                  //
//                 *@@@@@@@@@@@@@@@@@@@@@@@@=                 //
//                #@@@@@@@@@@@@@@@@@@@@@@@@@@+                //
//               [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@.               //
//               #@##@@@@@@@@@@@@@@@@@@@@@%+#@=               //
//               =:  *@@@@@@@@@@@@@@@@@@@@.  =:               //
//                    #@@@@@@@@@@@@@@@@@@:                    //
//                     -%@@@@@@@@@@@@@@*                      //
//                       *@@@@@@@@@@@*                        //
//                      #@@@@@*:#@@@@%#                       //
////////////////////////////////////////////////////////////////

contract LilPudgys is ERC721, Ownable, WithdrawFairly, ReentrancyGuard {

    uint16 private _tokenIdTrackerReserve;
    uint16 private _tokenIdTrackerAuction;
    uint16 private _tokenIdTracker;
    uint16 private _burnedTracker;

    struct Dutch{
        uint256 start;
        uint256 duration;
        uint256 startPrice;
        uint256 endPrice;
    }

    uint256 public constant MAX_ELEMENTS = 22222; //  MAX_RESERVE + MAX_CLAIM + MAX_AUCTION
    uint256 public constant MAX_CLAIM = 8888;
    uint256 public constant MAX_RESERVE = 300;
    uint256 public constant MAX_AUCTION = MAX_ELEMENTS - MAX_CLAIM - MAX_RESERVE;
    uint256 public constant MAX_BY_MINT = 20;
    uint256 public constant MAX_BY_CLAIM = 20;

    Dutch public dutch;
    bool public paused = false;
    string public baseTokenURI;
    PudgyPenguinsInterface public pudgyPenguins;
    mapping (uint256 => bool) private _pudgyPenguinsUsed;

    event MintLilPudgy(uint256 indexed id);

    constructor(string memory baseURI, address _pudgyPenguins) ERC721("LilPudgys", "LP") {
        setBaseURI(baseURI);
        setPudgyPenguins(_pudgyPenguins);
        setDutch(Dutch(1639947600, 2 hours, 0.3 ether, 0.03 ether));
    }

    //******************************************************//
    //                     Modifier                         //
    //******************************************************//
    modifier claimIsOpen {
        require(claimIsStarted(),"Dutch not ended");
        require(!paused, "Pausable: paused");
        _;
    }
    modifier saleIsOpen {
        require(dutchIsStarted(), "Dutch not started");
        require(!paused, "Pausable: paused");
        _;
    }
    //******************************************************//
    //                     Mint                             //
    //******************************************************//
    function mint(uint256 _count) public payable saleIsOpen nonReentrant{

        require(_tokenIdTrackerAuction + _count <= MAX_AUCTION, "Sold Out!");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(msg.value >= price(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _mintToken(_msgSender(), MAX_CLAIM + MAX_RESERVE + _tokenIdTrackerAuction);
            _tokenIdTrackerAuction += 1;
        }
    }
    function claim(uint256[] memory _tokensId) public claimIsOpen {

        require(_tokensId.length <= MAX_BY_CLAIM, "Exceeds number");

        for (uint256 i = 0; i < _tokensId.length; i++) {
            require(canClaim(_tokensId[i]) && pudgyPenguins.ownerOf(_tokensId[i]) == _msgSender(), "Bad owner!");
            _pudgyPenguinsUsed[_tokensId[i]] = true;

            _mintToken(_msgSender(), _tokensId[i]);
        }
    }
    function canClaim(uint256 _tokenId) public view returns(bool) {
        return _pudgyPenguinsUsed[_tokenId] == false;
    }
    function _mintToken(address _to, uint256 id) private {
        _tokenIdTracker += 1;
        _safeMint(_to, id);
        emit MintLilPudgy(id);
    }
    function reserve(uint256 _count) public onlyOwner {
        require(_tokenIdTrackerReserve + _count <= MAX_RESERVE, "Exceeded giveaways.");
        for (uint256 i = 0; i < _count; i++) {
            _mintToken(_msgSender(), MAX_CLAIM + _tokenIdTrackerReserve);
            _tokenIdTrackerReserve += 1;
        }
    }

    //******************************************************//
    //                      Dutch                           //
    //******************************************************//
    function claimIsStarted() public view returns(bool){
        return getMintPrice(0) == dutch.endPrice;
    }
    function dutchIsStarted() public view returns(bool){
        return block.timestamp >= dutch.start;
    }
    function getMintPrice(uint256 _timestamp) public view returns (uint256) {

        if (!dutchIsStarted()){
            return dutch.startPrice;
        }

        _timestamp = _timestamp == 0 ? block.timestamp : _timestamp;
        uint256 duration = _timestamp - dutch.start;

        if(duration >= dutch.duration){
            return dutch.endPrice;
        }

        uint256 currentPrice = dutch.startPrice - ((((duration * 100000) / dutch.duration) * (dutch.startPrice - dutch.endPrice)) / 100000);
        return  currentPrice > dutch.endPrice ? currentPrice : dutch.endPrice;
    }

    //******************************************************//
    //                      Getters                         //
    //******************************************************//
    function totalSupply() public view returns(uint256){
        return _tokenIdTracker - _burnedTracker;
    }
    function price(uint256 _count) public view returns (uint256) {
        return getMintPrice(0) * _count;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);

        if(tokenCount == 0){
            return tokensId;
        }

        uint256 key = 0;
        for (uint256 i = 0; i < MAX_ELEMENTS; i++) {
            if(rawOwnerOf(i) == _owner){
                tokensId[key] = i;
                key++;
                if(key == tokenCount){break;}
            }
        }

        return tokensId;
    }
    function setPause(bool _toggle) public onlyOwner {
        paused = _toggle;
    }

    //******************************************************//
    //                      Setters                         //
    //******************************************************//
    function setPudgyPenguins(address _pudgyPenguins) public onlyOwner {
        pudgyPenguins = PudgyPenguinsInterface(_pudgyPenguins);
    }
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }
    function setDutch(Dutch memory _dutch) public onlyOwner {
        dutch = _dutch;
    }

    //******************************************************//
    //                      Burn                            //
    //******************************************************//
    function burn(uint256 _tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Not owner nor approved");
        _burnedTracker += 1;
        _burn(_tokenId);
    }
}