// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*
                                                                                                                                                                                          
                                                                                                                                                                                          
                                                                                                     /=O                                                                                  
                                                                                                   \ =                                                                                    
                                                                                                 O  /                                                                                     
                                                                                                /  \  [[/                                                                                 
                                                                                              /  ,\\       [O                                                                             
                                                                                            O   =/   /OooO   //                                                                           
                                                                                          O       ]OoooO/  ,\                                                                             
                                                                                        O^     ,OoooooO   /                                                                               
                                                                                       /  ,    =OoooooO  =                                                                                
                                                                                     O  ,/  //   OooooO  =                                                                                
                                                                                   \   /^  /  ^  OooooO  =                                                                                
                                                                                 O   / ^  O   ^  OooooO  =                                                                                
                                                                               //  ,OO  ,=    ^  OooooO  =                                                                                
                                                                              /  ,OOO  ,O     ^  OooooO  =                                                                                
                                                                            O   OOOO  =O/[[[[[   OooooO  =O                                                                               
                                                                          O   /OoO/  /\          Oooooo        O                                                                          
                                                                         /  =OooO^  /\   oooooooooooooooooooo^  /                                                                         
                                                                       /  ,O ++O   \/  , ++++++++++++++++++++,\  \                                                                        
                                                                     O   O ++,O  ,O/  ,++++++++++++++++++++++++\  =                                                                       
                                                                   \   //+++,O  ,O^  ,++++++  =O++++++=O[\^+++++\  ,                                                                      
                                                                 O^  =/+++.=/  =O    ++++.,   =/++++++=O  =^.++++=  ,O                                                        OO  OOO     
                                                                /  ,O ....=/  =\              O^......=O   =\]]]]]/  ,O                                                       ^     =     
                                                              /   O ...../^  /O]]]]]]]]       O^......=O               O                                                     O  O=^ =     
     \                            O                         \   //......O   o        \    =^ ,O.......=O^[\    [/                                                              =^=^ =     
      O    ]]]]]]]]]]]]]]]]]]]]]   O                      O   =/......,O   \        O  =^ =  =O.......=O^...,\]   ,\/                                 OO                    /  O.=^ =     
        \   \\..................=^ ,                    O/  ,O ......,O  ,\        O  =O\    =^.......=O^.......[\    ,O                 \\O            =\                 O  =^.=^ =     
         O^   O^.................=  =                  /  ,O .......=/  ,         \  =/.O    O^.......=O^..........,\\    \/           O    /            ,O                ^  O..=^ =     
           /   ,O ................O  \               \   //........//  =         /  =/..O    O^.......=O^..............[O    ,\       /  ,\  =O            \              O  = ..=^ =     
             \   \\................\  O            O   //.........O^  /         /  =/...=^  ,O........=O^.................,\\    [O /   / .\   /         ,  \             ^ ,/...=^ =     
              O^  ,O^..............=^  O         O^  ,O ........,O   /         /  =/....=^  =O........=O^.....................[O      //....,\  \        =O  ,O          O  / ...=^ =     
                O   ,O .............=  ,        /  ,O .........,O   \         /  =/......O  =^........=O^........OOO\ ............\\]/........\  ,/      =^=^  /           ,^....=  =     
                  \   \\.............O  =     /   //..........=O  ,O         /  //.......O  O^........=O^........OOOO[.........../OO ..........=^  \     =^..\  \       /  O.....=  =     
                   O   =^.           .\  \  \   //.         ./O^  =         /  //.       =^ O         =O^        O/.           ,OO              ,O  ,/   =^  .\  =O    O  =^     =  =     
                     \  =^            =^  O   ,O            // =\  =O      /  //         =^,O         =O^                    .OO/                 \   \  =^    =^ ,O   ^  O      =  =     
                      ^  =^            =    ,O             O/   ,\  ,O    /  //           O=O         =O^                   /O/          ]         ,\    =^      \  \ O  =^      =  =     
                       ^  \             O  //            ,O      ,O  ,   /  //            OO^         =O^                 ,OO          =OOO          \   =^       \  =^  /       =  =     
                       O^  \             O/             ,O         O  ,O^  /O            OOO^         =O^               ,OO           OO  OO          =\ =^        ,    =        =  =     
                        /   O                          =O           \     /O           =OOOO          =O^              /O/          /OOOOO  O\          O=^          \ ,^        =  =     
                         O   O                        //      O      \   /O          ,OOOOOO          =O^               OO        ,OOOO     OOO          O^           \/         =  =     
                          O   O                      O^      OOO^     \^/O          /OOO OO/          =O^                OO^       ,OO  O    O/        ,O\^                      =  =     
                           O  ,O                   ,O      ,OO O \     =O         ,OOOOO  O^          =O^       =         \O\        \O    OO         /^ =^                      =  =     
                            \  ,\                 , =\     =OOOOO^    ,O         /O       O^          =O^       ,O.        \OO        ,O  O/        =O   =^     /                =  =     
                             ^  =\               =   ,O     ,OOO     ,O.       ,OOOOOOOOOOO.          =O^       .OO.        =OO\.      .OO.       .O^    =^    = \               =  =     
                              ^  =\............./  ,   O ....,O ....=O ......./OOO/[[[...,O...........=O^........OOO.........=OOO .............../O  ,O  =^...=^  =^............./  =     
                               ^  =\..........,/  / O   \\.........=O .................../O...........=O^........OOO\.........,OOO\............,O^  / O  =^..,^    ,\............O  =     
                                   \\++++++++,^  O    ^  =O+++++++=O +++++++++++++++++++=O/+++++++++++=O^++++++++OOOO\+++++++++,OOOO^+++++++++/O  ,O  O  =^+,/  / ^  O+++++++++++O  =     
                                O   \\++++++/  ,O      \  ,O ++++/O^++++++++++++++++++++OO^+++++++++++=O^++++++++OOOOO^+++++++++,OOOOO++++++,O^  /    O  =^+O  =   \  \ +++++++++O  =     
                                 O   O\++++O  ,O        O   O\++/O^++++++++++++++++++++=OO^+++++++++++/O\++++++++OOOOOO^++++++++++OO  O\+++O/  ,O     O  =oO  ,O    O  =\++++++++O  =     
                                  O   OoooO  ,           O   \OoOOOOOOOOOOOOOOOOOOOOOOOOOOooooooooooooOOOooooooooOO    OoooooooooooOO  OOoO   /       O  =O^ ,O      O  ,Ooooooooo  =     
                                   \   OO/  /              ^  =/                         OooooooooooooO[[[[[[[[[[[[[[[[   ,  [[[[[[[[[[ ,   ,\        O      O            Ooooooo/  =     
                                    \  ,^  \                \                           =OooooooooooooO   ,]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]//         OOOOOO\           \  \ooooo^  =     
                                     ^   ,O                  O  =                       =OooooooooooooO   =                                                              ^  =Oooo^  =     
                                     \^ ,O                    O/                     \   \OoooOOOOOOOOO   =                                                               O  ,OoO^  =     
                                       //                                             /   =OOOOOOOOOOOO   =                                                                    OO^  =     
                                                                                       O   ,OOOOOOOOOOO   /                                                                  ^  \^  =     
                                                                                        \^  ,OOOOOOOOO   /                                                                    \     =     
                                                                                          \   OOOOOOO   O                                                                      O    =     
                                                                                           O   \OOOO   O                                                                        O   =     
                                                                                            O   =OO  ,O                                                                          \^ =     
                                                                                              ^  ,  ,O                                                                             \=     
                                                                                               \   ,                                                                                      
                                                                                                / =/                                                                                      
                                                                                                                                                                                          
                                                                                                                                                                                          
*/

import { Owned } from "solmate/auth/Owned.sol";
import { ReentrancyGuard } from "solmate/utils/ReentrancyGuard.sol";
import { IArtGobblers } from "src/utils/IArtGobblers.sol";
import { IGOO } from "src/utils/IGOO.sol";
import { FixedPointMathLib } from "solmate/utils/FixedPointMathLib.sol";
import { toWadUnsafe, toDaysWadUnsafe } from "solmate/utils/SignedWadMath.sol";
import { LibGOO } from "goo-issuance/LibGOO.sol";

contract VoltronGobblers is ReentrancyGuard, Owned {
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    address public immutable artGobblers;
    address public immutable goo;

    /*//////////////////////////////////////////////////////////////
                                USER DATA
    //////////////////////////////////////////////////////////////*/

    // gobblerId => user
    mapping(uint256 => address) public getUserByGobblerId;

    /// @notice Struct holding data relevant to each user's account.
    struct UserData {
        // The total number of gobblers currently owned by the user.
        uint32 gobblersOwned;
        // The sum of the multiples of all gobblers the user holds.
        uint32 emissionMultiple;
        // User's goo balance at time of last checkpointing.
        uint128 virtualBalance;
        // claimed pool's gobbler number
        uint16 claimedNum;
        // Timestamp of the last goo balance checkpoint.
        uint48 lastTimestamp;
    }
    /// @notice Maps user addresses to their account data.

    mapping(address => UserData) public getUserData;

    /*//////////////////////////////////////////////////////////////
                                POOL DATA
    //////////////////////////////////////////////////////////////*/

    /// @dev An enum for representing whether to
    /// increase or decrease a user's goo balance.
    enum GooBalanceUpdateType {
        INCREASE,
        DECREASE
    }

    struct GlobalData {
        // The total number of gobblers currently owned by the user.
        uint32 totalGobblersOwned;
        // The sum of the multiples of all gobblers the user holds.
        uint32 totalEmissionMultiple;
        // User's goo balance at time of last checkpointing.
        uint128 totalVirtualBalance;
        // Timestamp of the last goo balance checkpoint.
        uint48 lastTimestamp;
    }

    GlobalData public globalData;

    mapping(uint256 => bool) public gobblersClaimed;
    uint256[] public claimableGobblers;
    uint256 public claimableGobblersNum;

    // only use when stop mint gobblers and could claim goo in pool
    struct VoltronGooData {
        uint128 claimableGoo;
        uint64 lastTimestamp;
    }

    VoltronGooData public voltronGooData;

    /*//////////////////////////////////////////////////////////////
                                admin
    //////////////////////////////////////////////////////////////*/

    bool mintLock;
    bool claimGobblerLock;
    bool claimGooLock = true;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event GobblerDeposited(address indexed user, uint256[] indexed IndexedGobblerIds, uint256[] gobblerIds);
    event GobblerWithdrawn(address indexed user, uint256[] indexed IndexedGobblerIds, uint256[] gobblerIds);
    event GooBalanceUpdated(address indexed user, uint256 newGooBalance);
    event GobblerMinted(uint256 indexed num, uint256[] indexed IndexedGobblerIds, uint256[] gobblerIds);
    event GobblersClaimed(address indexed user, uint256[] indexed IndexedGobblerIds, uint256[] gobblerIds);
    event VoltronGooClaimed(address indexed to, uint256 indexed amount);

    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/

    modifier canMint() {
        require(!mintLock, "MINT_LOCK");
        _;
    }

    modifier canClaimGobbler() {
        require(!claimGobblerLock, "CLAIM_GOBBLER_LOCK");
        _;
    }

    modifier canClaimGoo() {
        require(!claimGooLock, "CLAIM_GOO_LOCK");
        _;
    }

    constructor(address admin_, address artGobblers_, address goo_) Owned(admin_) {
        artGobblers = artGobblers_;
        goo = goo_;
    }

    function depositGobblers(uint256[] calldata gobblerIds) external nonReentrant {
        // update user virtual balance of GOO
        updateGlobalBalance();
        updateUserGooBalance(msg.sender, 0, GooBalanceUpdateType.INCREASE);

        uint256 id;
        address holder;
        uint32 emissionMultiple;
        uint32 sumEmissionMultiple;

        uint32 totalNumber = uint32(gobblerIds.length);
        for (uint256 i = 0; i < totalNumber; ++i) {
            id = gobblerIds[i];
            (holder,, emissionMultiple) = IArtGobblers(artGobblers).getGobblerData(id);
            require(holder == msg.sender, "WRONG_OWNER");
            require(emissionMultiple > 0, "GOBBLER_MUST_BE_REVEALED");

            sumEmissionMultiple += emissionMultiple;

            getUserByGobblerId[id] = msg.sender;

            IArtGobblers(artGobblers).transferFrom(msg.sender, address(this), id);
        }

        // update user data
        getUserData[msg.sender].gobblersOwned += totalNumber;
        getUserData[msg.sender].emissionMultiple += sumEmissionMultiple;

        // update global data
        globalData.totalGobblersOwned += totalNumber;
        globalData.totalEmissionMultiple += sumEmissionMultiple;

        emit GobblerDeposited(msg.sender, gobblerIds, gobblerIds);
    }

    function withdrawGobblers(uint256[] calldata gobblerIds) external nonReentrant {
        // update user virtual balance of GOO
        updateGlobalBalance();
        updateUserGooBalance(msg.sender, 0, GooBalanceUpdateType.DECREASE);

        uint256 id;
        address holder;
        uint32 emissionMultiple;
        uint32 sumEmissionMultiple;

        uint32 totalNumber = uint32(gobblerIds.length);
        for (uint256 i = 0; i < totalNumber; ++i) {
            id = gobblerIds[i];
            (holder,, emissionMultiple) = IArtGobblers(artGobblers).getGobblerData(id);
            require(getUserByGobblerId[id] == msg.sender, "WRONG_OWNER");

            sumEmissionMultiple += emissionMultiple;

            delete getUserByGobblerId[id];

            IArtGobblers(artGobblers).transferFrom(address(this), msg.sender, id);
        }

        // update user data
        getUserData[msg.sender].gobblersOwned -= totalNumber;
        getUserData[msg.sender].emissionMultiple -= sumEmissionMultiple;

        // update global data
        globalData.totalGobblersOwned -= totalNumber;
        globalData.totalEmissionMultiple -= sumEmissionMultiple;

        emit GobblerWithdrawn(msg.sender, gobblerIds, gobblerIds);
    }

    function mintVoltronGobblers(uint256 maxPrice, uint256 num) external nonReentrant canMint {
        uint256[] memory gobblerIds = new uint256[](num);
        for (uint256 i = 0; i < num; i++) {
            uint256 gobblerId = IArtGobblers(artGobblers).mintFromGoo(maxPrice, true);
            gobblerIds[i] = gobblerId;
            claimableGobblers.push(gobblerId);
        }
        claimableGobblersNum += num;
        emit GobblerMinted(num, gobblerIds, gobblerIds);
    }

    function claimVoltronGobblers(uint256[] calldata gobblerIds) external nonReentrant canClaimGobbler {
        uint256 globalBalance = updateGlobalBalance();
        uint256 userVirtualBalance = updateUserGooBalance(msg.sender, 0, GooBalanceUpdateType.DECREASE);

        uint256 claimableNum;
        // Since depositors before have already claimed their voltron gobblers,
        // the last depositor will take all the voltron gobblers
        if (getUserData[msg.sender].emissionMultiple >= globalData.totalEmissionMultiple) {
            claimableNum = claimableGobblersNum;
        } else {
            // (user's virtual goo / global virtual goo) * total claimable num - claimed num
            claimableNum =
                userVirtualBalance.divWadDown(globalBalance).mulWadDown(claimableGobblers.length) - uint256(getUserData[msg.sender].claimedNum);
        }


        uint256 claimNum = gobblerIds.length;
        require(claimableNum >= claimNum, "CLAIM_TOO_MUCH");

        getUserData[msg.sender].claimedNum += uint16(claimNum);
        claimableGobblersNum -= claimNum;

        // claim gobblers
        for (uint256 i = 0; i < claimNum; i++) {
            uint256 id = gobblerIds[i];
            require(!gobblersClaimed[id], "GOBBLER_ALREADY_CLAIMED");
            gobblersClaimed[id] = true;
            IArtGobblers(artGobblers).transferFrom(address(this), msg.sender, id);
        }

        emit GobblersClaimed(msg.sender, gobblerIds, gobblerIds);
    }

    function claimVoltronGoo() external nonReentrant canClaimGoo {
        // require all pool gobblers have been claimed
        require(mintLock, "SHOULD_STOP_MINT");
        require(claimableGobblersNum == 0, "SHOULD_CLAIM_GOBBLER");

        uint128 claimableGoo = voltronGooData.claimableGoo;

        if (uint256(voltronGooData.lastTimestamp) < block.timestamp) {
            claimableGoo = uint128(IArtGobblers(artGobblers).gooBalance(address(this)));
            IArtGobblers(artGobblers).removeGoo(claimableGoo);
            voltronGooData.lastTimestamp = uint48(block.timestamp);
        }

        uint256 globalBalance = updateGlobalBalance();
        uint256 updatedVirtualBalance = updateUserGooBalance(msg.sender, 0, GooBalanceUpdateType.DECREASE);

        uint256 amount;
        // Since depositors before have already claimed their voltron gobblers,
        // the last depositor will take all the voltron gobblers
        if (getUserData[msg.sender].emissionMultiple >= globalData.totalEmissionMultiple) {
            amount = claimableGoo;
        } else {
            // (user's virtual goo / global virtual goo) * total cliamable goo
            amount = updatedVirtualBalance.divWadDown(globalBalance).mulWadDown(claimableGoo);
        }        
        voltronGooData.claimableGoo = uint128(claimableGoo - amount);

        IGOO(goo).transfer(msg.sender, amount);

        emit VoltronGooClaimed(msg.sender, amount);
    }

    function updateGlobalBalance() public returns (uint256) {
        uint256 updatedBalance = LibGOO.computeGOOBalance(
            globalData.totalEmissionMultiple,
            globalData.totalVirtualBalance,
            uint256(toDaysWadUnsafe(block.timestamp - globalData.lastTimestamp))
        );
        // update global balance
        globalData.totalVirtualBalance = uint128(updatedBalance);
        globalData.lastTimestamp = uint48(block.timestamp);
        return updatedBalance;
    }

    /// @notice Update a user's virtual goo balance.
    /// @param user The user whose virtual goo balance we should update.
    /// @param gooAmount The amount of goo to update the user's virtual balance by.
    /// @param updateType Whether to increase or decrease the user's balance by gooAmount.
    function updateUserGooBalance(address user, uint256 gooAmount, GooBalanceUpdateType updateType) internal returns (uint256) {
        // Will revert due to underflow if we're decreasing by more than the user's current balance.
        // Don't need to do checked addition in the increase case, but we do it anyway for convenience.
        uint256 updatedBalance = updateType == GooBalanceUpdateType.INCREASE ? gooBalance(user) + gooAmount : gooBalance(user) - gooAmount;

        // Snapshot the user's new goo balance with the current timestamp.
        getUserData[user].virtualBalance = uint128(updatedBalance);
        getUserData[user].lastTimestamp = uint48(block.timestamp);

        emit GooBalanceUpdated(user, updatedBalance);
        return updatedBalance;
    }

    /// @notice Calculate a user's virtual goo balance.
    /// @param user The user to query balance for.
    function gooBalance(address user) public view returns (uint256) {
        // Compute the user's virtual goo balance by leveraging LibGOO.
        // prettier-ignore
        return LibGOO.computeGOOBalance(
            getUserData[user].emissionMultiple,
            getUserData[user].virtualBalance,
            uint256(toDaysWadUnsafe(block.timestamp - getUserData[user].lastTimestamp))
        );
    }

    function setMintLock(bool isLock) external onlyOwner {
        mintLock = isLock;
    }

    function setClaimGobblerLock(bool isLock) external onlyOwner {
        claimGobblerLock = isLock;
    }

    function setClaimGooLock(bool isLock) external onlyOwner {
        claimGooLock = isLock;
    }
}