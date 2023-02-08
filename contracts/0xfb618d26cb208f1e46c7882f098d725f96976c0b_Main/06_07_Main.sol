// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//                                     ___ooo_..._.                                         
//                                 .___.  o_      __.                                       
//                             ._.._   ._o.         ..o_.                                   
//                         _oo_...._._.              .._.                                 
//                     __..      o.   ._               __                                
//                     ._..       .o.....                  .o.                              
//                 .o.     ....___.                        __.                            
//                 __.     .... _o                             __.                          
//             __       ..._.______..                   .__   _x_.                       
//             __      .....   ..._ooxo__..                .__.  oo.                      
//             o. .      .__ooo_.    ..__oxo__.              ..oo_xo                      
//             ._...  ._oxxxxxoxxxx__.       ______._..          .oxx_                     
//             __.  .oxx_ooo__oxo.xooxoo___.         .___          .oo                     
//             __  _o__o_._.____o ____.oo_.oxx___.       .           .oo.                   
//         ._. _oxoo_.o_ .x   o_....____. .xxoxx__.        ._        _o                   
//         ._o._oxx_.o..o_ _xo  oo.._. o.    .x..o_xo__      .x_        __                  
//     __._oxxo__.o..o.  __o_. .o.  o_o   o_o .._o_ox__    .oo.       __                 
//     .o _xxxxo_  _o.oo_..._o___.._x__xoox_.___. ...ooxx_    oo_       _.                
//     o _xxxxxo.......__.........     .._oooooo____.....___   .oo_     ..                
//     _. _xxxxxo.._ooxxxxxxxxxxxxx_..__xxxxxxxxxxxxxxxxxx__.__   .o_                      
//     _..oxxxxo._xooxxxxxxxxxxxxxxx.  _xo   ..oxxxxxxxxxxxxx._x_   .x.                    
//     _..xxxxxxox..  ._.oxxxxxxxxxo...._xo.    ...oxxxxxxxxxx.xxo   .o.                   
//     _..xxxxxxxxxx_.._xxxxxxxxxxo._..___xxo__oxxxxxxxxxxxxxx.xxx    _.                   
//     _..xxoxxxxxxxxxxxxxxxxxxxxx o.   o_.xxxxxxxxxxxxxxxxxx_ xxx    _.                   
//     _o.ox .xxoxxxxxxxxxxxxxxxx.__.   ox_.oxxxxxxxxxxxxxxx_  xxx_  .o.                   
//     .._xo ox_ _xxxxxxxxxxxx_..._.  _ooo_._oxxxxxxxxxxxx_...xoxo  ._   ..               
//     .._o.._o. ._oxxxxxx___...o_   .  ._..._ooxxxxxxo_..o o..ox.  _.  .o               
//         _.xxo.o_ ...._oo_... .o._         __ _..._oo_..__. ._.oxxo  .o  __               
//         xxx._x    .....   _oo.oo_..._o_.__     .....  ._ _xxxxxo     .o.               
//         xxx._x           _..ox_oxxxxxxxxxx_         .ox. _xxxxxo     .x.               
//         o.o_.x_       ...  .. . _oo_ _oxxo_..       oxx. _xxxxo.   oo _.               
//         .o.oooo      ._ .__ ..__o._..___.___.      .xxx. _xxo.    ox_._                
//             .xxxo       .x__._.______...____.__     _xx_ .ox.   .oox_ o.                
//             .xxx_       _..    .......____._ _    .oxo..oo   .oxxxo  o                 
//             _._xx_.            .._o_.            _xo_.oxo   _xxxxx_ _.                 
//             .o_.oxx_.        ._________        .oo_.oxx_   oxxxo__ ._                  
//                 __ _xxx_                       .oo_.oxxx_   _xo_ ._oo_                   
//                 ._ .oxxx_.                  .oo__oxxxo.   ._  _oxxo.                    
//                 __  _xx___              .____.oxxo_. __    .xxxxo                      
//                 __  oxx _o_.  ........__..ooxo_. ___.   ._xxxooxo_..                  
//                 ._xoo_xx_  _ox__________oxxx_. .__.    ..oxxxx_.  ._oo_.               
//             ......_o__o_xox_  .o__...oxxxxxo__._oo______oxxxxxo_.__..  ..___.            
//         ...... .___   .o_.ox_         oxxo. .o oxxxxxxooooooo_.     ___.   ..__.         
// ._....   ._._       o_. .o_  _.  .oxo__oxx_.oo__                    .__.    ._..      
// ...     .._.          o_.   __.xxxoo__xxo__o _.                          ._.    .._.    
//         ..             o_.    .o._ooo__.   o__.                                          
//                     o_.    .._.o.      _.__                                           
//                     o_.    ..x_o.      o o                                            

import {Owned} from "solmate/auth/Owned.sol";
import {Unaboomer} from "./Unaboomer.sol";
import {Mailbomb} from "./Mailbomb.sol";

/** 
@title UnaboomerNFT
@author lzamenace.eth
@notice This is the main contract interface for the Unaboomer NFT project drop and chain based game.
It contains the logic between an ERC-721 contract containing Unaboomer tokens (pixelated Unabomber 
inspired profile pictures) and an ERC-1155 contract containing Mailbomb tokens (utility tokens).
Unaboomer is a chain based game with some mechanics based around "killing" other players by sending 
them mailbombs until a certain amount of players or "survivors" remain. The motif was inspired by 
the real life story of Theodore Kaczynski, known as the Unabomber, who conducted a nationwide 
mail bombing campaign against people he believed to be advancing modern technology and the 
destruction of the environment. Ironic, isn't it? 
*/
contract Main is Owned {

    /// Track the number of kills for each address
    mapping(address => uint256) public killCount;
    /// Index addresses to form a basic leaderboard
    mapping(uint256 => address) public leaderboard;
    /// Point to the latest leaderboard update
    uint256 public leaderboardPointer;
    /// Price of the Unaboomer ERC-721 token
    uint256 public unaboomerPrice = 0.005 ether;
    /// Price of the Mailbomb ERC-1155 token
    uint256 public bombPrice = 0.0025 ether;
    /// If mail bombs can be sent by players
    bool public mayhem;
    /// Unaboomer contract
    Unaboomer public unaboomer;
    /// Mailbomb contract
    Mailbomb public mailbomb;

    /// SentBomb event is for recording the results of sendBombs for real-time feedback to a frontend interface
    /// @param from Sender of the bombs
    /// @param tokenId Unaboomer token which was targeted
    /// @param hit Whether or not the bomb killed the token or not (was a dud / already killed)
    /// @param owned Whether or not the sender was the owner of the BOOMER token
    event SentBomb(address indexed from, uint256 indexed tokenId, bool hit, bool owned);

    constructor() Owned(msg.sender) {}

    // =========================================================================
    //                              Admin
    // =========================================================================

    /// Withdraw funds to contract owner
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "failed to withdraw");
    }

    /// Set price per BOOMER
    /// @param _price Price in wei to mint BOOMER token
    function setBoomerPrice(uint256 _price) external onlyOwner {
        unaboomerPrice = _price;
    }

    /// Set price per BOMB
    /// @param _price Price in wei to mint BOMB token
    function setBombPrice(uint256 _price) external onlyOwner {
        bombPrice = _price;
    }

    /// Set contract address for Unaboomer tokens
    /// @param _address Address of the Unaboomer / BOOMER contract
    function setUnaboomerContract(address _address) external onlyOwner {
        unaboomer = Unaboomer(_address);
    }

    /// Set contract address for Mailbomb tokens
    /// @param _address Address of the Mailbomb / BOMB contract
    function setMailbombContract(address _address) external onlyOwner {
        mailbomb = Mailbomb(_address);
    }

    /// Toggle mayhem switch to enable mail bomb sending
    function toggleMayhem() external onlyOwner {
        mayhem = !mayhem;
    }

    // =========================================================================
    //                              Modifiers
    // =========================================================================

    /// This modifier prevents actions once the Unaboomer survivor count is breached.
    /// The game stops; no more bombing/killing. Survivors make it to the next round.
    modifier missionNotCompleted {
        require(
            unaboomer.burned() < (unaboomer.MAX_SUPPLY() - unaboomer.MAX_SURVIVOR_COUNT()), 
            "mission already completed"
        );
        _;
    }

    // =========================================================================
    //                              Getters
    // =========================================================================

    /// Get BOOMER token balance of wallet 
    /// @param _address Wallet address to query balance of BOOMER token
    /// @return balance Amount of BOOMER tokens owned by _address
    function unaboomerBalance(address _address) public view returns (uint256) {
        return unaboomer.balanceOf(_address);
    }

    /// Get BOOMER amount minted (including ones that have been burned/killed)
    /// @param _address Wallet address to query the amount of BOOMER token minted
    /// @return balance Amount of BOOMER tokens that have been minted by _address
    function unaboomersMinted(address _address) public view returns (uint256) {
        return unaboomer.tokensMintedByWallet(_address);
    }

    /// Get BOOMER token total supply
    /// @return supply Amount of BOOMER tokens minted in total
    function unaboomersRadicalized() public view returns (uint256) {
        return unaboomer.minted();
    }

    /// Get BOOMER kill count (unaboomers killed)
    /// @return killCount Amount of BOOMER tokens "killed" (dead pfp)
    function unaboomersKilled() public view returns (uint256) {
        return unaboomer.burned();
    }

    /// Get BOOMER token max supply
    /// @return maxSupply Maximum amount of BOOMER tokens that can ever exist
    function unaboomerMaxSupply() public view returns (uint256) {
        return unaboomer.MAX_SUPPLY();
    }

    /// Get BOOMER token survivor count
    /// @return survivorCount Maximum amount of BOOMER survivor tokens that can ever exist
    function unaboomerMaxSurvivorCount() public view returns (uint256) {
        return unaboomer.MAX_SURVIVOR_COUNT();
    }

    /// Get BOOMER token max mint amount per wallet
    /// @return mintAmount Maximum amount of BOOMER tokens that can be minted per wallet
    function unaboomerMaxMintPerWallet() public view returns (uint256) {
        return unaboomer.MAX_MINT_AMOUNT();
    }

    /// Get BOMB token balance of wallet
    /// @param _address Wallet address to query balance of BOMB token
    /// @return balance Amount of BOMB tokens owned by _address
    function bombBalance(address _address) public view returns (uint256) {
        return mailbomb.balanceOf(_address, 1);
    }

    /// Get BOMB token supply
    /// @return supply Amount of BOMB tokens ever minted / "assembled"
    function bombsAssembled() public view returns (uint256) {
        return mailbomb.bombsAssembled();
    }

    /// Get BOMB exploded amount
    /// @return exploded Amount of BOMB tokens that have burned / "exploded"
    function bombsExploded() public view returns (uint256) {
        return mailbomb.bombsExploded();
    }

    // =========================================================================
    //                              Tokens
    // =========================================================================

    /// Radicalize a boomer to become a Unaboomer - start with 1 bomb
    /// @param _amount Amount of Unaboomers to mint / "radicalize"
    function radicalizeBoomers(uint256 _amount) external payable missionNotCompleted {
        require(msg.value >= _amount * unaboomerPrice, "not enough ether");
        unaboomer.radicalize(msg.sender, _amount);
        mailbomb.create(msg.sender, _amount);
    }

    /// Assemble additional mailbombs to kill targets
    /// @param _amount Amount of bombs mint / "assemble"
    function assembleBombs(uint256 _amount) external payable missionNotCompleted {
        require(msg.value >= _amount * bombPrice, "not enough ether");
        mailbomb.create(msg.sender, _amount);
    }

    /// Send N bombs to pseudo-random Unaboomer tokenIds to kill them.
    /// If the Unaboomer is already dead, the bomb is considered a dud.
    /// Update a leaderboard with updated kill counts.
    /// @dev Pick a pseudo-random tokenID from Unaboomer contract and toggle a mapping value  
    /// @dev The likelihood of killing a boomer decreases as time goes on - i.e. more duds
    /// @param _amount Amount of bombs to send to kill Unaboomers (dead pfps)
    function sendBombs(uint256 _amount) external missionNotCompleted {
        // Require mayhem is set (allow time to mint and trade)
        require(mayhem, "not ready for mayhem");
        // Ensure _amount will not exceed wallet balance of bombs, Unaboomer supply, and active Unaboomers
        uint256 supply = unaboomersRadicalized();
        uint256 bal = bombBalance(msg.sender);
        require(_amount <= bal, "not enough bombs");
        for (uint256 i; i < _amount; i++) {
            // Pick a pseudo-random Unaboomer token - imperfectly derives token IDs so that repeats are probable
            uint256 randomBoomer = (uint256(keccak256(abi.encodePacked(i, supply, bal, msg.sender))) % supply) + 1;
            // Capture owner
            address _owner = unaboomer.ownerOf(randomBoomer);
            // Check if it was already killed
            bool dud = _owner == address(0);
            // Check if the sender owns it (misfired, killed own pfp)
            bool senderOwned = msg.sender == _owner;
            // Kill it (does nothing if already toggled as dead)
            unaboomer.die(randomBoomer);
            // Emit event for displaying in web app
            emit SentBomb(msg.sender, randomBoomer, !dud, senderOwned);
            // Increment kill count if successfully killed another player's Unaboomer
            if(!dud && !senderOwned) {
                killCount[msg.sender]++;
            }
        }
        // Update the leaderboard and pointer for tracking the highest amount of kills for wallets
        uint256 kills = killCount[msg.sender];
        address leader = leaderboard[leaderboardPointer];
        if (kills > killCount[leader]) {
            if (leader != msg.sender) {
                leaderboardPointer++;
                leaderboard[leaderboardPointer] = msg.sender;
            }
        }
        // Burn ERC-1155 BOMB tokens (bombs go away after sending / exploding)
        mailbomb.explode(msg.sender, _amount);
    }

}