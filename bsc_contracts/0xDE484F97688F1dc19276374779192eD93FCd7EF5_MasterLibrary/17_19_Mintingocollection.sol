// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Referral.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

contract MintingoCollection is Referral, ERC721Enumerable, ReentrancyGuard {
    using Strings for uint256;
    using SafeMath for uint256;

    string public baseURI;
    string public notRevealedUri;
    string private baseExtension = ".json";
    address public creator;

    bool public paused = false;
    bool public revealed = false;

    uint256 private start_block;
    Ticket price_info;
   
    uint256 private expiration;
    uint256 public max_Supply;

    mapping(uint256 => RewardInfo) public reward_by_token;
    mapping(address => uint) public coin_to_price;

    RewardInfo[] public rewards;

    address public master;
    uint256[] public winners;

    struct Ticket {
    address[] coin_to_pay;
    address[] nfts;
    uint256[] price_to_pay;
    }

    struct RewardInfo {
    address coin;
    uint256 amount ;
    uint256 total_claimable ;
    uint256 total_claimed;
    }   


    function _onlyMaster() private view {
        require(msg.sender == master, "ONLY_MASTER");
    }

    modifier onlyMaster() {
        _onlyMaster();
        _;
    }

// Constructor 
    constructor( string memory _name,
        string memory _symbol, uint256[] memory totalClaimable, uint256[] memory tiers, address[] memory coins, uint256[] memory amounts, address[] memory coin_to_pay, address[] memory nfts, uint256[] memory price_to_pay , address _admin) ERC721(_name, _symbol) Referral() {
        require(tiers.length == coins.length && coins.length == amounts.length && coins.length == totalClaimable.length, 'INVALID_DATA');
         for(uint256 i=0; i < tiers.length; i++){
            if (i == 0 ) {
            rewards.push(RewardInfo(address(0),0,totalClaimable[i],0));
            continue;
            }
            rewards.push(RewardInfo(coins[i], amounts[i], totalClaimable[i], 0));
        }
        price_info = Ticket(coin_to_pay, nfts, price_to_pay);
        
        winners = new uint256[](0);
        master = _admin;  
    }

    function setVariables(uint256 _start_block, uint256 _expiration, uint256 _supply,
        string memory _initNotRevealedUri) public onlyMaster() {
        start_block = _start_block;
        expiration = _expiration;
        max_Supply = _supply;
        setNotRevealedURI(_initNotRevealedUri);
         for (uint i = 0; i < price_info.coin_to_pay.length; i++) {
            coin_to_price[price_info.coin_to_pay[i]] = price_info.price_to_pay[i] ;
            }
    }

    function set_referral(uint256 _decimals,
    uint256 _referralBonus,
    uint256 _secondsUntilInactive,
    bool _onlyRewardActiveReferrers,
    uint256[] memory _levelRate,
    uint256[] memory _refereeBonusRateMap) public onlyMaster() {
        set_Values(_decimals, _referralBonus, _secondsUntilInactive, _onlyRewardActiveReferrers, _levelRate, _refereeBonusRateMap);
    }

    
    

// Funzione per ottenere il balance della collezione
   function  get_balanceOf() public view returns( uint256[] memory){
        uint256[] memory amounts = new uint256[](price_info.coin_to_pay.length);
        for(uint i=0; i < price_info.coin_to_pay.length; i++){
            amounts[i] = (IERC20(price_info.coin_to_pay[i]).balanceOf(address(this)));
        }
        return amounts;
    }

// Funzione get ticket 
    function getTicket() public view returns (address[] memory, address[] memory, uint256[] memory)  {
        return (price_info.coin_to_pay, price_info.nfts, price_info.price_to_pay);
    }    
 
// Funzione per sapere se utente può claimare premio
    function  claim(uint256 token_id) public {
        require(!paused, "CONTRACT_PAUSED");
        require(revealed == true, 'NOT_REVEALED');
        require(ownerOf(token_id) == msg.sender, 'NOT_OWNER');
        require (expiration > block.timestamp, 'TICKET_EXPIRED');
        require(winners.length > 0, 'NO_WINNERS');
        bool legit = false;
        for(uint i=0;i< winners.length; i++){
            if(winners[i] == token_id){
                legit = true;
                break;
            }
        }
        require(legit == true, 'NOT_WINNER');
       
        RewardInfo memory reward = reward_by_token[token_id];
        require(reward.total_claimed < reward.total_claimable, 'NO_MORE_CLAIMS');
        reward.total_claimed += 1;
        reward_by_token[token_id] = reward;
        IERC20(reward.coin).transfer(msg.sender, reward.amount);
        IERC721(this).transferFrom(msg.sender, address(this), token_id);
        
    }

// Funzione per fare il reveal dei premi
    function  reveal(uint256[] memory _winners, uint256[] memory tiers, string memory revealed_uri) public onlyMaster() {
        require(_winners.length == tiers.length, 'INVALID_DATA_FORMAT');
         winners = _winners;
        // update winners and rewards claimable
        for(uint i=0; i < winners.length; i++){
            uint256 tier = tiers[i];
            RewardInfo memory reward = rewards[tier];
            reward_by_token[winners[i]] = reward;
        }
        expiration = block.timestamp + 30 days;
        // rest of stuff here
        setBaseURI(revealed_uri);    
        revealed = true;
       
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "TOKEN_NO_EXIST"
        );
        if (revealed == false) {
            return notRevealedUri;
        }
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked( currentBaseURI, tokenId.toString(), baseExtension)): "";
    }

    function _mintTicket(address to, uint256 amount) internal virtual {
         uint256 supply = totalSupply();
        require(supply + amount <= max_Supply, "MAX_SUPPLY_REACHED");
     for (uint256 i = 1; i <= amount; i++) {
         _safeMint(to, supply + i);
        }
      
    }

    function mint(uint256 _mintAmount, address coin, address user, address _referrer) public payable nonReentrant() {
        require(!paused, "CONTRACT_PAUSED"); 
        require(_mintAmount > 0, "INVALID_MINT_AMOUNT");
        uint256 price = (coin_to_price[coin]).mul(_mintAmount);

          for(uint i=0; i < price_info.nfts.length; i++){
            if(price_info.nfts[i] == address(0)) {
                continue;
            } else 
            require(
                IERC721(price_info.nfts[i]).balanceOf(user) > 0,
                'NOT_TICKET_HOLDER'
            );
        }

         for(uint i=0; i < price_info.coin_to_pay.length; i++){
            if (price_info.coin_to_pay[i] != coin) {
            continue;
            } 
            require(
                IERC20(coin).balanceOf(user) >= price, 
                'INSUFFICENT_BALANCE'
            );
            require(
                IERC20(coin).allowance(user, address(this)) >= price, 'NOT_AUTHORIZED');
                 if(!hasReferrer(user)) {
                
                if(_referrer != address(0)){
                    // if _referrer is a valid address set it as user referrer
                    addReferrer(payable(_referrer), user);
                }else{
                    // Set the creator as user referrer otherwise
                    addReferrer(payable(creator), user);
                }
            }
            payReferral(coin, price, user);
            // require(
            //   IERC20(coin).transferFrom(user, address(this), price), 
            //     'TRANSFER_FAILED');
            _mintTicket(user, _mintAmount);
        }
    }

    function setBaseURI(string memory _newBaseURI) internal virtual  {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) internal virtual {
        notRevealedUri = _notRevealedURI;
    }

// funzione withdraw per il master
    function withdraw(address coin, uint256 amount) public onlyMaster()  {
        require(coin != address(0), 'INVALID_COIN');
        require(amount > 0, 'INVALID_AMOUNT');
        require(IERC20(coin).balanceOf(address(this)) >= amount, 'INSUFFICENT_BALANCE');
        require(IERC20(coin).transfer(msg.sender, amount), 'TRANSFER_FAILED');
    }
}