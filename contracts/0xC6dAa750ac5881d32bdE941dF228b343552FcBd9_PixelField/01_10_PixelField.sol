// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "@openzeppelin/contracts/access/Ownable.sol";
import './PixelTag.sol';
import './PixelRoyale.sol';

contract PixelField is Ownable {
    //---------- Addies ----------//
    address public contractCreator;
    address public lastPlayer;
    address public mostAttacks;
    address public randomPlayer;
    address public randomTag;
    address public abashoCollective; // ---> Needs to be set
    address public constant pixelTagContract = 0xCB4e67764885A322061199845b89A502879D12CF; // ---> Interface for Tags DONE --> Turn into constant before we ship
    address public constant pixelWarContract = 0xce73F0473a49807a92a95659c0b8dD883B29c252; // ---> Interface for Warriors DONE --> Turn into constant before we ship
    //---------- Player Vars ----------//
    uint256 public constant MAXPIXELS = 4444;
    mapping(uint256 =>int256) public pixelWarriors; // Inialize state for each pixelWarrior
    uint256 public fallenPixels; // ---> Inits to 0

    //---------- Bools ----------//
    bool public pixelWarStarted;
    bool public pixelWarConcluded;
    bool internal payout;

    //---------- General Condition ----------//
    uint256 public timeLimit = 1671667200; // Thursday, 22. December 2022 00:00:00 GMT
    uint256 constant ITEM_PRICE = 0.005 ether;
    mapping(address => uint256) public walletHighscore; // ---> keeps track of each wallet highscore
    uint256 public currentHighscore;
    string private salt;

    //---------- Mini Jackpot Vars ----------//
    uint256 public jackpot;

    //---------- Events ----------//
    event DropOut(address from,uint256 tokenId);
    event MiniJackpotWin(address winner, uint256 jackpotAmount);

    //---------- Construct----------//
    constructor() {
        contractCreator = msg.sender;  // DONE
        abashoCollective = msg.sender;  // SafeGuard if Multisig not received
    }

    //----------SET LATE ABASHO COLLECTIVE ADDRESS ----
    function setAbashoADDR(address _addr) external onlyOwner {  // DONE
        abashoCollective = _addr;
    }

    //---------------------------------------------------------------------------------------------
    //---------- BATTLE ROYALE GAME ----------//
    //---------- Manually Start PixelRoyale ----------//
    function startPixelWar() external onlyOwner {
        require(!pixelWarStarted, "War can't be halted");
        pixelWarStarted = true;
    }

    //---------- Calculate Amount Of "Alive" Players ----------//
    function getPopulation() public view returns(uint256 _population) {
        return (MAXPIXELS-fallenPixels);
    }

    //---------- Returns Last Player ID ----------//
    function checkLastSurvivor() public view returns(uint256 _winner) {
        for (uint256 j; j < MAXPIXELS; j++) {
            if(pixelWarriors[j] > -1){
                return j+1;
            }
        }
    }

    //---------- Checks If Specified TokenID Is "Alive" ----------//
    function isAlive(uint256 _tokenId) public view returns(bool _alive) {
        pixelWarriors[_tokenId-1] < 0 ? _alive = false : _alive = true;
    }

    //---------- Returns Random "Alive" TokenID ----------//
    function returnRandomId() public view returns(uint256 _tokenId) {
        for (uint256 j = pseudoRandom(MAXPIXELS,"Q"); j <= MAXPIXELS + 1; j++) {
            if(pixelWarriors[j] > -1) {
                return j+1;
            }
            if(j == MAXPIXELS) {
                j = 0;
            }
        }
    }

    //---------- Pseudo Random Number Generator From Range ----------//
    function pseudoRandom(uint256 _number, string memory _specialSalt) internal view returns(uint256 number) {
        number = uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender,salt,_specialSalt))) % _number;
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
        require(pixelWarriors[_tokenId-1] > -1, "Player already out of the Game");

        uint256 priceMod = 10; // ---> 0%
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
            require(pixelWarriors[_tokenId-1]+_amount>-2,"Warrior overkill");
            walletHighscore[_msgSender()] += amount;
            if(walletHighscore[_msgSender()] > currentHighscore) {
                currentHighscore = walletHighscore[_msgSender()];
                mostAttacks = _msgSender();
            }
        }

        // change health value in player struct
        (pixelWarriors[_tokenId-1]+_amount) < 0 ? pixelWarriors[_tokenId-1] = -1 : pixelWarriors[_tokenId-1] = pixelWarriors[_tokenId-1] + _amount;

        // add to mini jackpot array
        addToPot(msg.value);

        // try jackpot
        if(jackpot>0){
            tryJackpot();
        }

        // check if token is alive | Check if player has dropped out of Game
        InterfacePixelTags pixelTag = InterfacePixelTags(pixelTagContract); // ---> Interface to Tags NFT
        if ( !isAlive(_tokenId) ) {
            fallenPixels++;
            pixelTag.mintPixelTag(_msgSender()); // ---> MINT DogTag FROM ERC721A
            pixelWarriors[_tokenId-1] = -1;

            //emit DropOut event
            emit DropOut(_msgSender(),_tokenId); // ---> Killer, Killed Token
        }
        // check if population is 1 | check if PixelRoyale has concluded
        if ( getPopulation() < 2 ) {
            pixelWarConcluded = true;
            randomPlayer = wOwnerOf(pseudoRandom(MAXPIXELS,"Warrior"));
            randomTag = tOwnerOf(pseudoRandom(MAXPIXELS-1,"Tag"));
        }
    }

    //---------------------------------------------------------------------------------------------
    //---------- BATTLE ROYALE GAME ----------//
    //---------- Add 49% Of Bet To Mini Jackpot ----------//
    function addToPot(uint256 _amount) internal {
        jackpot = jackpot + (_amount/100*49);
    }

    //---------- Calculate Current Mini Jackpot Size ----------//

    //---------- Win Mini Jackpot Function ----------//
    function tryJackpot() internal {
        if(pseudoRandom(8,"JP") == 4) { // ---> 12,5% winning chance
            payable(msg.sender).transfer(jackpot);
            emit MiniJackpotWin(msg.sender, jackpot); // ---> emits jackpot amount and winner when hit
            jackpot = 0; // ---> purge mini jackpot array after it has been paid out
        }
    }
    //---------------------------------------------------------------------------------------------
    //---------- WITHDRAW FUNCTIONS ----------//

    //---------- Distribute Balance if Game Has Not Concluded Prior To Time Limit ----------//
    function withdraw() public {  // DONE
        require(block.timestamp >= timeLimit, "Play fair, wait until the time limit runs out");  // DONE
        require(contractCreator == _msgSender(), "Only Owner can withdraw after time limit runs out");  // DONE
        uint256 balance = address(this).balance;  // DONE
        payable(abashoCollective).transfer(balance/100*15);
        payable(contractCreator).transfer(address(this).balance); // DONE
    }

    //---------- Distribute Balance if Game Has Concluded Prior To Time Limit ----------//
    //---------- EXPENSIVE WE WILL BE CHANGING THE SALT VALUE PER BLOCK TO RESIST MINER ATTACKS----------//
    function distributeToWinners() public {  // DONE
        require(pixelWarConcluded, "The game has not concluded yet!");   // DONE
        require(!payout, "The prize pool has already been paid out!");  // DONE
        uint256 balance = address(this).balance;  // DONE
        // 25% to Last player and most attacks
        payable(wOwnerOf(checkLastSurvivor())).transfer(balance/100*25);  // DONE//// ------------------> expensive, 4k Gas loop is called here
        payable(mostAttacks).transfer(balance/100*25);  // DONE
        // 15% to random holder of Player and Dog Tag NFTs
        payable(randomPlayer).transfer(balance/100*10);  // DONE
        payable(randomTag).transfer(balance/100*10);  // DONE
        // 15% to abasho collective and remainder to Contract Creator
        payable(abashoCollective).transfer(balance/100*15);  // DONE
        payable(contractCreator).transfer(address(this).balance);  // DONE
        payout = true;  // DONE
    }
    //---------------------------------------------------------------------------------------------
    //---------- Interface of PixelWarrior ----------//
    function wTokenURI(uint256 _tokenId) public view returns (string memory){
        IERC721A pixelWarrior = IERC721A(pixelWarContract);
        return pixelWarrior.tokenURI(_tokenId);
    }
    function wOwnerOf(uint256 _tokenId) public view returns (address){
        IERC721A pixelWarrior = IERC721A(pixelWarContract);
        return pixelWarrior.ownerOf(_tokenId);
    }
    //---------- Interface of PixelTags ----------//
    function tTokenURI(uint256 _tokenId) public view returns (string memory){
        IERC721A pixelTag = IERC721A(pixelTagContract);
        return pixelTag.tokenURI(_tokenId);
    }
    function tOwnerOf(uint256 _tokenId) public view returns (address){
        IERC721A pixelTag = IERC721A(pixelTagContract);
        return pixelTag.ownerOf(_tokenId);
    }
}