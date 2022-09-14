// SPDX-License-Identifier: MIT
// This is no CC0
// www.PixelRoyal.xyz
// The Pixel Royale will start after mint out
pragma solidity 0.8.15;
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import './PixelTag.sol';

contract PixelRoyale is ERC721A, Ownable {
    //---------- Addies ----------//
    address public contractCreator;
    address public lastPlayer;
    address public mostAttacks;
    address public randomPlayer;
    address public randomTag;
    address public abashoCollective; // ---> Needs to be set
    address public pixelTagContract; // ---> Interface for Tags
    //---------- Mint Vars ----------//
    bool public started;
    bool public claimed;
    uint256 public constant MAXPIXELS = 4444;
    uint256 public constant WALLETLIMIT = 2;
    uint256 public constant CREATORCLAIMAMOUNT = 3;
    mapping(address => uint) public addressClaimed; // ---> keeps track of wallet limit
    // MetadataURI
    string private baseURI;
    //---------- PixelRoyale Vars ----------//
    bool public pixelWarStarted;
    bool public pixelWarConcluded;
    uint256 public timeLimit = 1671667200; // Thursday, 22. December 2022 00:00:00 GMT
    uint constant ITEM_PRICE = 0.005 ether;
    mapping(address => uint) public walletHighscore; // ---> keeps track of each wallet highscore
    uint256 public currentHighscore;
    string private salt;
    bool public payout;
    //---------- Mini Jackpot Vars ----------//
    uint256[] public jackpot;
    //---------- Player Vars ----------//
    struct Pixel {
        int256 health;
        bool status;
    }
    mapping(uint256 => Pixel) public pixelList; // ---> maps ID to a Player Struct

    //---------- Events ----------//
    event ItemBought(address from,address currentMA,uint tokenId,int256 amount);
    event DropOut(address from,uint tokenId);
    event MiniJackpotWin(address winner, uint256 jackpotAmount);
    event MiniJackpotAmount(uint256 jackpotAmount);

    //---------- Construct ERC721A TOKEN ----------//
    constructor() ERC721A("PixelRoyale BATTLE GAME", "PRBG") {
        contractCreator = msg.sender;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    //---------------------------------------------------------------------------------------------
    //---------- MINT FUNCTIONS ----------//
    //---------- Start Minting -----------//
    function startMint() external onlyOwner {
        require(!started, "mint has already started");
        started = true;
    }

    //---------- Free Mint Function ----------//
    function mint(uint256 _amount) external {
        uint256 total = totalSupply();
        if(_msgSender() != contractCreator) {
            require(started, "Mint did not start yet");
            require(addressClaimed[_msgSender()] + _amount <= WALLETLIMIT, "Wallet limit reached, don't be greedy");
        }
        require(_amount > 0, "You need to mint at least 1");
        require(total + _amount <= MAXPIXELS, "Not that many NFTs left, try to mint less");
        require(total <= MAXPIXELS, "Mint out");

        // create structs for minted amount
        for (uint j; j < _amount; j++) {
            Pixel memory newPixel = Pixel(0,true);
            pixelList[total+j+1] = newPixel;
        }
        addressClaimed[_msgSender()] += _amount;
        _safeMint(_msgSender(), _amount);

        // immediately starts PixelRoyale GAME on mint out
        if(totalSupply() >= MAXPIXELS){
            pixelWarStarted = true;
        }
    }

    //---------- Team Claim ----------//
    function teamClaim() external onlyOwner {
        uint256 total = totalSupply();
        require(!claimed, "already claimed");
        for (uint j; j < CREATORCLAIMAMOUNT; j++) {
            // struct creation for mint amount
            Pixel memory newPixel = Pixel(0,true);
            pixelList[total+j+1] = newPixel;
        }
        _safeMint(contractCreator, CREATORCLAIMAMOUNT);
        claimed = true;
    }

    //---------------------------------------------------------------------------------------------
    //---------- BATTLE ROYALE GAME ----------//
    //---------- Manually Start PixelRoyale ----------//
    function startPixelWar() external onlyOwner {
        require(!pixelWarStarted, "The war has already been started");
        pixelWarStarted = true;
    }

    //---------- Calculate Amount Of "Alive" Players ----------//
    function getPopulation() public view returns(uint256 _population) {
        for (uint j=1; j <= totalSupply(); j++) {
            if(isAlive(j)){
                _population++;
            }
        }
    }

    //---------- Returns Last Player ID ----------//
    function checkLastSurvivor() public view returns(uint256 _winner) {
        for (uint j; j <= totalSupply(); j++) {
            if(pixelList[j].health > -1){
                _winner = j;
            }
        }
    }

    //---------- Checks If Specified TokenID Is "Alive" ----------//
    function isAlive(uint256 _tokenId) public view returns(bool _alive) {
        pixelList[_tokenId].health < 0 ? _alive = false : _alive = true;
    }

    //---------- Returns Random "Alive" TokenID ----------//
    function returnRandomId() public view returns(uint256 _tokenId) {
        for (uint256 j = pseudoRandom(totalSupply(),"Q"); j <= totalSupply() + 1; j++) {
            if(pixelList[j].health > -1) {
                return j;
            }
            if(j == totalSupply()) {
                j = 0;
            }
        }
    }

    //---------- Pseudo Random Number Generator From Range ----------//
    function pseudoRandom(uint256 _number, string memory _specialSalt) public view returns(uint number) {
        number = uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender,salt,_specialSalt))) % _number;
        number == 0 ? number++: number;
    }

    //---------- Change Salt Value Pseudo Randomness ----------//
    function changeSalt(string memory _newSalt) public onlyOwner {
        salt = _newSalt;
    }

    //---------- Set HP For Players | Protect/Attack ----------//
    function setHP(uint256 _tokenId, int256 _amount) external payable {
        require(!pixelWarConcluded, "PixelRoyale has concluded!");
        require(pixelWarStarted, "PixelRoyale hasn't started!");
        require(getPopulation() > 1, "We already have a winner!");
        require(_amount != 0, "Value needs to be > or < than 0");
        require(pixelList[_tokenId].health > -1, "Player already out of the Game");

        uint priceMod = 10; // ---> 0%
        uint256 amount;

        // turn _amount into a positive amount value
        _amount < 0 ? amount = uint256(_amount*-1) : amount = uint256(_amount);

        // bulk pricing:
        if(amount>6) {
            priceMod = 8; // ---> 20%
            if(amount>12) {
                priceMod = 7; // ---> 30%
                if(amount>18) {
                    priceMod = 6; // ---> 40%
                    if(amount>24) { priceMod = 5; } // ---> 50%
                }
            }
        }

        // calculate purchase
        uint256 currentPrice = ITEM_PRICE / 10 * priceMod * amount;
        require((currentPrice) <= msg.value, "Not enough ETH");

        // checks on attack purchase
        if(_amount < 0) {
            require(pixelList[_tokenId].health+_amount>-2,"Try less attacks - warrior overkill");
            walletHighscore[_msgSender()] += amount;
            if(walletHighscore[_msgSender()] > currentHighscore) {
                currentHighscore = walletHighscore[_msgSender()];
                mostAttacks = _msgSender();
            }
        }

        // change health value in player struct
        (pixelList[_tokenId].health+_amount) < 0 ? pixelList[_tokenId].health = -1 : pixelList[_tokenId].health = pixelList[_tokenId].health + _amount;

        //emit event for item buy
        emit ItemBought(_msgSender(),mostAttacks,_tokenId,_amount); // ---> buyer, current Highscore Leader, Interacted token, amount of protections/attacks

        // add to mini jackpot array
        addToPot(msg.value);

        // try jackpot
        if(jackpot.length>0){
            tryJackpot();
        }

        // check if token is alive | Check if player has dropped out of Game
        InterfacePixelTags pixelTag = InterfacePixelTags(pixelTagContract); // ---> Interface to Tags NFT
        if ( !isAlive(_tokenId) ) {
            pixelTag.mintPixelTag(_msgSender()); // ---> MINT DogTag FROM ERC721A
            pixelList[_tokenId].status = false;

            //emit DropOut event
            emit DropOut(_msgSender(),_tokenId); // ---> Killer, Killed Token
        }
        // check if population is smaller than 2 | check if PixelRoyale has concluded
        if ( getPopulation() < 2 ) {
            pixelWarConcluded = true;
            lastPlayer = ownerOf(checkLastSurvivor());
            randomPlayer = ownerOf(pseudoRandom(MAXPIXELS,"Warrior"));
            randomTag = pixelTag.ownerOf(pseudoRandom(MAXPIXELS-1,"Tag"));
        }
    }

    //---------------------------------------------------------------------------------------------
    //---------- BATTLE ROYALE GAME ----------//
    //---------- Add 49% Of Bet To Mini Jackpot ----------//
    function addToPot(uint256 _amount) internal {
        jackpot.push(_amount/100*49);
    }

    //---------- Calculate Current Mini Jackpot Size ----------//
    function currentPot() internal view returns(uint256 _result) {
        for (uint j; j < jackpot.length; j++) {
            _result += jackpot[j];
        }
    }

    //---------- Win Mini Jackpot Function ----------//
    function tryJackpot() internal {
        if(pseudoRandom(8,"") == 4) { // ---> 12,5% winning chance
            payable(_msgSender()).transfer(currentPot());
            emit MiniJackpotWin(_msgSender(), currentPot()); // ---> emits jackpot amount and winner when hit
            delete jackpot; // ---> purge mini jackpot array after it has been paid out
        }
        else {
            emit MiniJackpotAmount(currentPot()); // ---> emits jackpot amount when not hit
        }
    }

    //---------- Set PixelTag Contract Address For Interactions/Interface ----------//
    function setTagContract(address _addr) external onlyOwner {
        pixelTagContract = _addr;
    }
    //---------------------------------------------------------------------------------------------
    //---------- WITHDRAW FUNCTIONS ----------//

    //---------- Distribute Balance if Game Has Not Concluded Prior To Time Limit ----------//
    function withdraw() public {
        require(block.timestamp >= timeLimit, "Play fair, wait until the time limit runs out");
        require(contractCreator == _msgSender(), "Only Owner can withdraw after time limit runs out");
        uint256 balance = address(this).balance;
        payable(abashoCollective).transfer(balance/100*15);
        payable(contractCreator).transfer(address(this).balance);
    }

    //---------- Distribute Balance if Game Has Concluded Prior To Time Limit ----------//
    function distributeToWinners() public {
        require(pixelWarConcluded, "The game has not concluded yet!");
        require(!payout, "The prize pool has already been paid out!");
        uint256 balance = address(this).balance;
        // 25% to Last player and most attacks
        payable(lastPlayer).transfer(balance/100*25);
        payable(mostAttacks).transfer(balance/100*25);
        // 15% to random holder of Player and Dog Tag NFTs
        payable(randomPlayer).transfer(balance/100*10);
        payable(randomTag).transfer(balance/100*10);
        // 15% to abasho collective and remainder to Contract Creator
        payable(abashoCollective).transfer(balance/100*15);
        payable(contractCreator).transfer(address(this).balance);
        payout = true;
    }
    //---------------------------------------------------------------------------------------------
    //----------SET LATE ABASHO COLLECTIVE ADDRESS ----

    function setAbashoADDR(address _addr) external onlyOwner {
        abashoCollective = _addr;
    }

    //---------------------------------------------------------------------------------------------
    //---------- METADATA & BASEURI ----

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "There is no token with that ID");
        string memory currentBaseURI = _baseURI();
        if(isAlive(_tokenId)) {
            return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _toString(_tokenId), '.json')) : '';
        }
        else {
            return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI,'d', _toString(_tokenId), '.json')) : '';
        }

        
    }
}