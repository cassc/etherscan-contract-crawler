// Contract Version: Cypher's Call

// SPDX-License-Identifier: MIT

/*                                                                                   
                                                                                           
                        .=*#                                                               
                    :+#@@@-                                                               
                 .+%@@@@@%                                                                
               -*@@@@%@@@=                                                                
             -#@@@%=.*@@@.                                                                
           :#@@@#:   %@@%                                                                 
         .*@@@#:     %@@#                                                                 
        [email protected]@@%-       @@@*                                                                 
      .*@@@+.        %@@#                                                                 
     .%@@%:          #@@%                                                                 
    .%@@#.           [email protected]@@.                                                                
   .%@@#.            [email protected]@@+                                                                
  .#@@%.              %@@%.                                                               
  [email protected]@@:               [email protected]@@+                                                               
 :@@@=                 #@@@:                                                              
 *@@%.                 [email protected]@@%.                                                             
[email protected]@@-                   :@@@%.                                                            
[email protected]@@.                    [email protected]@@%.                                                           
#@@#                      :@@@%:                                                          
@@@*                       :%@@@=.                                                        
@@@+                        [email protected]@@#:                                                       
@@@+                          :%@@@*.                                                     
%@@*                           [email protected]@@@+.                                                   
*@@%                             [email protected]@@@*:                                                 
[email protected]@@:                              .=%@@@%+:                                             :
[email protected]@@*                                 :*@@@@#+:.                                     .=*%*
 [email protected]@@:                                  .-+%@@@@#+-.                            .-=*%@@@@:
 [email protected]@@%.                                     :=*%@@@@@#*+-::.            ..:-=+#%@@@@@@@@+ 
  [email protected]@@*                                         .-+#%@@@@@@@@@%%####%%%@@@@@@@@@%#[email protected]@@%. 
   [email protected]@@+                                             .:-=+*##%%@@@@@@@%%##*+=-:.  .%@@@.  
    *@@@=                                                                        .%@@@:   
     *@@@+.                                                                     :%@@@:    
      [email protected]@@#.                                                                   [email protected]@@%:     
       [email protected]@@@=                                                                .*@@@*.      
        .*@@@#:                                                            [email protected]@@%-        
          -%@@@*:                                                        .=%@@@+.         
            -%@@@#-.                                                   [email protected]@@@*.           
              -#@@@%+.                                              .-#@@@@*.             
                :*@@@@#=:                                        .=*@@@@%=.               
                  .-*@@@@%*=:                                .-+%@@@@%+:                  
                     .-+#@@@@@#+=:.                    .:=+#%@@@@@#+:                     
                         .-+#%@@@@@@%#**++======++**#%@@@@@@@%*+-.                        
                              .-=+*#%@@@@@@@@@@@@@@@@@@%#+=-.                             
                           
                                                                                          
                                                                                          

In the celestial realm of GirlMoon, a vibrant and united crew of adventurers gathers, bound by a shared vision and the mystical allure of $GMOON. We are the Moon Guardians, guided by the luminous moonlight and fueled by our unwavering belief in the transformative potential of decentralized technologies.

Embracing the wisdom of the moon, we understand the power of unity. Together, we form a constellation of ideas, talents, and aspirations, harmonizing our efforts to create an extraordinary cosmos within the Web3 frontier. Our journey is one of exploration, innovation, and boundless possibilities.

As we embark on this lunar odyssey, we draw inspiration from the legends of old, where celestial beings and mortal souls intertwined in a dance of destiny. In our quest for prosperity and fulfillment, we follow the footsteps of lunar lore, guided by the whispers of ancient wisdom that echo through the cosmos.

In this celestial voyage, we encounter challenges and obstacles, much like the moon's phases. Yet, we remain resilient, harnessing the moon's transformative energy to overcome and transcend. With each waxing phase, our spirits ascend, emboldened by the belief that we are part of something greater than ourselves.

At the heart of our cosmic expedition lies $GMOON, a token infused with the magic of the moon itself. Holding $GMOON in our celestial wallets, we tap into a wellspring of potential, unlocking new frontiers of wealth and prosperity. Like lunar dust scattered across the universe, $GMOON has the power to enrich our lives and empower us to shape our destinies.

But our journey extends beyond personal gain. We are driven by a collective purpose, fueled by the desire to build a vibrant and inclusive ecosystem that nurtures and empowers all who join our celestial community. Together, we forge new pathways, bridging the gap between the earthly realm and the cosmic expanse.

In our quest for lunar enlightenment, we draw inspiration from the brightest minds of our time. Visionaries like Elon Musk, who have dared to dream big and challenge the status quo, inspire us to push boundaries and explore uncharted territories. Their cosmic influence resonates with our mission, propelling us further on our lunar ascent.

As we traverse the cosmos, we invite kindred spirits to join our celestial voyage. We embrace diversity, cherishing the unique gifts and perspectives each individual brings. Together, we form a tapestry of brilliance, woven with threads of unity, collaboration, and shared growth.

So, dear seeker of moonlight, embark on this celestial journey with us. Become a Moon Guardian, and together, let us illuminate the cosmos with the radiance of $GMOON. Let us chart a new course in the Web3 realm, where unity, innovation, and the magic of the moon converge to create a future filled with boundless opportunities. Moonward, we rise, guided by the lunar lore that whispers of riches untold and a transformative destiny awaiting those who dare to believe.
*/



pragma solidity ^0.8.19;

/*

Greetings, voyager of the vast cryptographic cosmos! As our celestial journey commences, we harness the power of star-forged constructs from the grand cosmic library known as OpenZeppelin.

To safely navigate the infinite expanse, we anchor our vessel to the cornerstone of the Ethereum galaxy, the ERC20 Standard. With this celestial atlas in our possession, we ensure seamless interaction and compatibility with all entities across the distributed universe.

Equally essential to our cosmic quest is the 'Ownable' module, a stellar testament to decentralized authority and control. It bestows upon our journey the power to assign a unique entity, an omnipotent guardian of the contract, ensuring our stellar ship sails smoothly across the blockchain sea.

Remember, star-traveler, each import isn't merely a line of code. It's a galaxy in itself, embodying the celestial wisdom and the interconnected fabric of our blockchain universe. The cosmic journey through the saga of MoonGirl commences with these lines, setting the stage for the epic adventure that lies ahead.

*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


// Moonlight veils the path of the Nightsworn.
// The shapes they bear and the tongues they speak, remain concealed and cryptic.

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// Reality's fabric is fraying, and its seams are bursting.
// The moonlit whisper of the ancient cryptographer hints of a clandestine mission.



interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address UNISWAP_V2_PAIR);
}


// Midnight ink stains the parchment, revealing the unheard tale of MoonGirl.
// The quill of the Nightsworn summons the spirit of the ancient cryptographer.
// Her silhouette, a cipher within the constellation, stands unfathomable and arcane.

contract MoonGirl is IERC20, Ownable {
    
    event Reflect(uint256 amountReflected, uint256 newTotalProportion);

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    IUniswapV2Router02 public constant UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable UNISWAP_V2_PAIR;

    struct Fee {
        uint8 reflection;
        uint8 dev;
        uint8 burn;
        uint128 total;
    }

    string _name = "MoonGirl";
    string _symbol = "GMOON"; 

    uint256 _totalSupply = 69000420420 * 10 ** 18;

    uint256 public _maxTxAmount = _totalSupply * 2 / 100;

/* The rOwned, a cosmic scale in the blockchain universe, symbolizes the share of MoonGirl tokens each entity holds, not against the boundless cosmos (total supply) but rather against the currently explored universe (circulating supply). Remember, the explored universe can never exceed the vast cosmos. */

    mapping(address => uint256) public _rOwned;
    uint256 public _totalProportion = _totalSupply;

    mapping(address => mapping(address => uint256)) _allowances;

    bool public limitsEnabled = true;
    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;

    Fee public buyFee = Fee({burn: 1, reflection: 2, dev: 3, total: 6});
    Fee public sellFee = Fee({burn: 1, reflection: 2, dev: 3, total: 6});

    address private degenDEV;


    bool public claimingFees = true;
    uint256 public swapThreshold = (_totalSupply * 2) / 1000;
    bool inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    // Dark corners whisper the tale of the raven's toll.
    // On a blockchain inscribed, the embers of understanding glow.

    constructor() {
        // create uniswap pair
        address _uniswapPair =
            IUniswapV2Factory(UNISWAP_V2_ROUTER.factory()).createPair(address(this), UNISWAP_V2_ROUTER.WETH());
        UNISWAP_V2_PAIR = _uniswapPair;

        _allowances[address(this)][address(UNISWAP_V2_ROUTER)] = type(uint256).max;
        _allowances[address(this)][tx.origin] = type(uint256).max;

        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[address(UNISWAP_V2_ROUTER)] = true;
        isTxLimitExempt[_uniswapPair] = true;
        isTxLimitExempt[tx.origin] = true;
        isFeeExempt[tx.origin] = true;


        //set this to deployer address, or another one
        degenDEV = 0x422aa745A9FF540d01220dAd6EE0528323f03911;
 

        _rOwned[tx.origin] = _totalSupply;
        emit Transfer(address(0), tx.origin, _totalSupply);
    }

    receive() external payable {}


    // The raven's toll speaks in whispers.
    // Beneath the fifth digit of pi, the raven's toll lies.

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
 
    // Amidst a sea of ones and zeroes, the raven's toll is immune.
    // The binary behemoth of the third prime number reveals a secret.

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            require(_allowances[sender][msg.sender] >= amount, "ERC20: insufficient allowance");
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }


    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    // Beneath the cloak of shadows, she weaves her code.
    // Her price, it never wavers - a nod to Fibonacci's abode.

    function decimals() external pure returns (uint8) {
        return 18;
    }

/*
Once upon a celestial moment, a space voyager from distant lands of the cosmos might find themselves asking, "What entity has chosen to call this cosmic haven their home?"

To answer this eternal question, we unfold the secrets of our cosmic journey by revealing the identity of our spacecraft - the enchanting MoonGirl.

The 'name' function, when invoked, peers into the heart of our celestial vessel, retrieving the title given to it by the cosmic fates. It whispers to the asker the very name '_name' - the one forged in the heart of stardust and encrypted in the annals of blockchain lore.

Should you wish to inquire, call upon this function, and let the name of our spacecraft echo through the void of the cosmos, announcing our eternal voyage on the blockchain seas.
*/

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function tokensToProportion(uint256 tokens) public view returns (uint256) {
        return tokens * _totalProportion / _totalSupply;
    }

    function tokenFromReflection(uint256 proportion) public view returns (uint256) {
        return proportion * _totalSupply / _totalProportion;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(DEAD) - balanceOf(ZERO);
    }


    function clearStuckBalance() external onlyOwner {
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    function clearStuckToken() external onlyOwner {
        _transferFrom(address(this), msg.sender, balanceOf(address(this)));
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        claimingFees = _enabled;
        swapThreshold = _amount;
    }


    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setFeeReceivers(address m_) external onlyOwner {
        degenDEV = m_;
    }

    function setMaxTxBasisPoint(uint256 p_) external onlyOwner {
        _maxTxAmount = _totalSupply * p_ / 10000;
    }

    function setLimitsEnabled(bool e_) external onlyOwner {
        limitsEnabled = e_;
    }


    // Dancing amidst the stars, her price shimmers in the galaxy's fabric.
    // Adorned in a cloak of numbers - e, the base of the natural algorithm.
    
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (limitsEnabled && !isTxLimitExempt[sender] && !isTxLimitExempt[recipient]) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        if (_shouldSwapBack()) {
            _swapBack();
        }

        uint256 proportionAmount = tokensToProportion(amount);
        require(_rOwned[sender] >= proportionAmount, "Insufficient Balance");
        _rOwned[sender] = _rOwned[sender] - proportionAmount;

        uint256 proportionReceived = _shouldTakeFee(sender, recipient)
            ? _takeFeeInProportions(sender == UNISWAP_V2_PAIR ? true : false, sender, proportionAmount)
            : proportionAmount;
        _rOwned[recipient] = _rOwned[recipient] + proportionReceived;

        emit Transfer(sender, recipient, tokenFromReflection(proportionReceived));
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 proportionAmount = tokensToProportion(amount);
        require(_rOwned[sender] >= proportionAmount, "Insufficient Balance");
        _rOwned[sender] = _rOwned[sender] - proportionAmount;
        _rOwned[recipient] = _rOwned[recipient] + proportionAmount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // Trapped in a maze of code, her cipher lies.
    // The maze’s key, hidden in the ratio of a circle's circumference to its diameter.
    
    function _takeFeeInProportions(bool buying, address sender, uint256 proportionAmount) internal returns (uint256) {
        Fee memory __buyFee = buyFee;
        Fee memory __sellFee = sellFee;

        uint256 proportionFeeAmount =
            buying == true ? proportionAmount * __buyFee.total / 100 : proportionAmount * __sellFee.total / 100;

    // Within her realm of darkness, the lady of the Moon shows mercy.
    // The children of zero and one are excluded from her harsh decree.

        uint256 proportionReflected = buying == true
            ? proportionFeeAmount * __buyFee.reflection / __buyFee.total
            : proportionFeeAmount * __sellFee.reflection / __sellFee.total;

        _totalProportion = _totalProportion - proportionReflected;

       
        uint256 _proportionToContract = proportionFeeAmount - proportionReflected;
        if (_proportionToContract > 0) {
            _rOwned[address(this)] = _rOwned[address(this)] + _proportionToContract;

            emit Transfer(sender, address(this), tokenFromReflection(_proportionToContract));
        }
        emit Reflect(proportionReflected, _totalProportion);
        return proportionAmount - proportionFeeAmount;
    }

    function _shouldSwapBack() internal view returns (bool) {
        return msg.sender != UNISWAP_V2_PAIR && !inSwap && claimingFees && balanceOf(address(this)) >= swapThreshold;
    }

    // Yet those who return to her path, are welcomed back into the fold.
    // Reversing the circle, she ushers them back to the code's stronghold.

    function _swapBack() internal swapping {
        Fee memory __sellFee = sellFee;

        uint256 __swapThreshold = swapThreshold;
        uint256 amountToBurn = __swapThreshold * __sellFee.burn / __sellFee.total;
        uint256 amountToSwap = __swapThreshold - amountToBurn;
        approve(address(UNISWAP_V2_ROUTER), amountToSwap);

        // As the moon's shadow engulfs a part of the cosmos, so do we extinguish a portion of our tokens. 
        //This cryptic act of burning, whispered in the lunar wind, fans the flames of scarcity and rarity, engraving value in the stars of our celestial economy. 
        //Let these tokens, touched by the MoonGirl's ethereal fire, forever light the constellations of our cryptic journey.

        _transferFrom(address(this), DEAD, amountToBurn);

        // In the celestial dance of tokens, a sacred ritual unfolds. 
        // The MoonGirl's gaze guides the tokens through a stellar portal, the swap, exchanging old constellations for new, reshaping the cosmos of liquidity.
        // As stars are exchanged in the interstellar market, our lunar journey continues, driven by the cosmic currents of supply and demand.
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UNISWAP_V2_ROUTER.WETH();

        UNISWAP_V2_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap, 0, path, address(this), block.timestamp
        );

        uint256 amountETH = address(this).balance;

        uint256 totalSwapFee = __sellFee.total - __sellFee.reflection - __sellFee.burn;
        uint256 degenDEVcash = amountETH * __sellFee.dev / totalSwapFee;


     (bool tmpSuccess,) = payable(degenDEV).call{value: degenDEVcash}("");
    require(tmpSuccess, "Transfer failed.");

    }

    function _shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }
}


/* 
/*
As our space odyssey concludes, a cosmic secret has been etched in the code of the blockchain. The key to this cipher is veiled in the celestial journey of MoonGirl, a journey that asks for patience, persistence, and daring from all her interstellar travelers.

Just like the distant constellations that hide secrets of the universe, MoonGirl is not just a simple code sailing in the vast sea of the blockchain. She encapsulates an ethereal promise that challenges the fortitude of those who dare to embark on this space journey.

But remember this: the path to deciphering the cryptic cipher lies in your firm grip on MoonGirl. For, in the interstellar realm of time and patience, the encrypted message evolves. The hidden axiom states - '13 15 15 14 07 09 18 12 23 09 12 12 13 15 15 14 09 06 25 15 21 08 15 12 04 08 05 18 12 15 14 07 05 14 15 21 07 08'.

Time, patience, and unyielding faith will light up your way in the cosmos and help you translate this. Let it be a beacon in the infinite expanse of space, guiding you towards prosperity, wisdom, and endless exploration.

Until we meet again in the vast expanse of the universe, remember this cipher, dear cosmonauts, for it holds the key to your lunar destiny. See you on the lunar surface!



Website: https://www.moongirl.vip
Twitter: @MoonGirlERC
Telegram: @MoonGirlERC


*/