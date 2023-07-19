// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
          .::::::::::::::::::::::::::::::::::::::::::::::.      
        ~JYJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJY555555555YY!     
        .PG5YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY5PPPPPPPPPPGP:    
        ^J555555PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5555J~     
            .:^^:7YYYYYYYYYYYYYYYYYYYYYYYYY5555555J~~~^.        
          .::.. .:^^^^^^^^^^^^^^^^^^^^^^^^^^~~~~~^:^^~~^.      
        .::.                                .:::::::::^^~^     
      .::.                 ................  :^:::::::::^~~.   
      .:..                ................... .::::::::::::^~.  
      ::                ...................... :^:::::::::::^~  
    .:.               ....................... .^:::::::::::^~. 
    .:.               ....................... .^::::::::::::~. 
    .:.              ........................ .^::::::::::::~. 
    .:.              ........................ .^::::::::::::~. 
    .:.              ........................ .:::::::::::::~. 
    .:.              ........................ .:::::::::::::~. 
    .:.              ........................ .:::::::::::::~. 
    .:.              .....               .... .:::::::::::::~. 
    .:.              ..    .::^^^~~^^::.    . .:::::::::::::~. 
    .:.                .:~!7777??777???77~:.  .^::::::::::::~. 
    .:.              .~777777JYY5Y7777777?J7^..^::::::::::::~. 
    .:. .......... .^777!77775555Y77777777??J?^:::::::::::::~. 
    .:. ......... .!7?Y5J77777?77777777?Y?7??JY~::::::::::::~. 
    .^  ........  !77JYY?777777777?JJJJ?7?JJ?J5J::::::::::::~. 
    .^. ........ :?777!7777?777777Y55P5J?JJ??JYY^:::::::::::~. 
    .~:  ....... ^?!!77777JJ777777??JJ???J???J5J::::::::::::~. 
    .~^.  ...... :J7!!777777777777777777JYYJJY5!::::::::::::~. 
    .~^:.   ..... ~J77777?JJ?7777777777?Y55YY57::::::::::::^~. 
      ~^:::.        ^??77?55P5?7777?J??JJJYY5Y!:::::::::::::^~. 
      :~^::::......  .~7??Y5YJ??7??YYJYYY55Y7^:::::::::::::^~^  
      ^~~^^^^^^::::::::~!7JJYYYYYYYYYYYJ7~^::^^^^^^^^^^^^~~^   
        .^^~~~~~~~~~~~~~~^^~~~!!!77!!!~~~^^~~~~~~~~~~~~~~^^.    
          ...................FLIP SHIBA..................
*/

import "./StakingWrapper.sol";
import "./IERC1155.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CookieJar is StakingWrapper, AccessControl {
    using SafeMath for uint256;

    uint256 private constant DECIMALS = 1e18;

    IERC1155 public cookieToken;

    struct Cookie {
        uint256 crumbs;
        uint256 releaseTime;
    }

    bool public allowBoosts = true;
    uint256 public start;
    uint256 public maxStake;
    uint256 public cookieRaid;
    uint256 public rewardRate;
    uint256 private burned;
    uint256[4] public boosts = [
        50, // 5%
        100, // 10%
        150, // 15%
        330 // 33%
    ];

    mapping(address => uint256) public lastUpdateTime;
    mapping(address => uint256) public crumbs;
    mapping(uint256 => Cookie) public cookies;

    event Redeemed(address indexed user, uint256 crumbs);
    event CookieAdded(
        uint256 cookie,
        uint256 maxIssuance,
        uint256 crumbs,
        uint256 releaseTime,
        string tokenUri
    );

    modifier updateReward(address account) {
        if (account != address(0)) {
            crumbs[account] = earned(account);
            lastUpdateTime[account] = _blockTime();
        }
        _;
    }

    constructor(
        address _tokenAddress,
        address _cookiesAddress,
        uint256 _burned,
        uint56 _maxStake,
        uint256 _rewardRate,
        uint256 _cookieRaid
    ) StakingWrapper(_tokenAddress) {
        cookieToken = IERC1155(_cookiesAddress);
        burned = _burned;
        maxStake = _maxStake * DECIMALS;
        cookieRaid = _cookieRaid * DECIMALS;
        rewardRate = _rewardRate;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function percentStaked() public view returns (uint256 percent) {
        return (totalStaked().mul(1000)).div(totalSupply().sub(burned));
    }

    function boostAmount() public view returns (uint256 boost) {
        if (!allowBoosts) return 0;
        if (percentStaked() >= boosts[3]) return 330;
        if (percentStaked() >= boosts[2]) return 150;
        if (percentStaked() >= boosts[1]) return 100;
        if (percentStaked() >= boosts[0]) return 50;
        return 0;
    }

    function earned(address account) public view returns (uint256) {
        uint256 blockTime = _blockTime();
        uint256 base = balanceOf(account)
            .mul(blockTime.sub(lastUpdateTime[account]).mul(rewardRate))
            .div(DECIMALS)
            .add(crumbs[account]);

        return base.add(base.mul(boostAmount()).div(1000));
    }

    function cookieReleaseTime(uint256 cookie) public view returns (uint256) {
        return cookies[cookie].releaseTime;
    }

    function cookieCrumbs(uint256 cookie) public view returns (uint256) {
        return cookies[cookie].crumbs;
    }

    function cookieTotalIssuance(uint256 cookie) public view returns (uint256) {
        return cookieToken.totalSupply(cookie);
    }

    function cookieMaxIssuance(uint256 cookie) public view returns (uint256) {
        return cookieToken.maxIssuance(cookie);
    }

    function mintingOpen() public view returns (bool) {
        return totalStaked() >= cookieRaid;
    }

    function stake(uint256 amount) public override updateReward(msg.sender) {
        require(_blockTime() >= start, "cookie jar not ready");
        require(
            amount.add(balanceOf(msg.sender)) <= maxStake,
            "deposit > max allowed"
        );

        super.stake(amount);
    }

    function withdraw(uint256 amount) public override updateReward(msg.sender) {
        require(amount > 0, "why withdraw 0?");
        super.withdraw(amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
    }

    function redeem(uint256 id, uint256 quantity)
        public
        updateReward(msg.sender)
    {
        require(totalStaked() >= cookieRaid, "raid not started");
        require(quantity > 0, "mint 1 or more");
        require(cookies[id].crumbs != 0, "cookie not found");
        require(_blockTime() >= cookies[id].releaseTime, "cookie not released");

        Cookie memory c = cookies[id];

        uint256 requiredCrumbs = quantity.mul(c.crumbs);
        require(crumbs[msg.sender] >= requiredCrumbs, "need more crumbs");

        crumbs[msg.sender] = crumbs[msg.sender].sub(requiredCrumbs);
        cookieToken.mint(msg.sender, id, quantity);

        emit Redeemed(msg.sender, requiredCrumbs);
    }

    function _blockTime() internal view returns (uint256) {
        return block.timestamp;
    }

    // ADMIN FUNCTIONS //

    function setStart(uint256 _start) public onlyRole(DEFAULT_ADMIN_ROLE) {
        start = _start;
    }

    function setAllowBoosts(bool _allowBoosts)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        allowBoosts = _allowBoosts;
    }

    function setCookieRaid(uint256 _cookieRaid)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        cookieRaid = _cookieRaid;
    }

    function setMaxStake(uint256 _maxStake)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maxStake = _maxStake;
    }

    function setRewardRate(uint256 _toStakePerPoint)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 _rewardRate = (
            uint256(1e18).div(86400).mul(DECIMALS).div(_toStakePerPoint)
        );

        rewardRate = _rewardRate;
    }

    function setRewardRateNoCalc(uint256 _rewardRate)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        rewardRate = _rewardRate;
    }

    function createCookie(
        uint256 _maxIssuance,
        string memory _tokenURI,
        uint256 _crumbs,
        uint256 _releaseTime
    ) public onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256 tokenId) {
        tokenId = cookieToken.initializeToken(_maxIssuance, _tokenURI);
        require(tokenId > 0, "ERC1155 create did not succeed");

        Cookie storage c = cookies[tokenId];
        c.crumbs = _crumbs;
        c.releaseTime = _releaseTime;

        emit CookieAdded(
            tokenId,
            _maxIssuance,
            _crumbs,
            _releaseTime,
            _tokenURI
        );
    }
}