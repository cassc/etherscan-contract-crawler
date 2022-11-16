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
        // Timestamp of the last goo deposit.
        uint48 lastGooDepositedTimestamp;
    }

    /// @notice Maps user addresses to their account data.
    mapping(address => UserData) public getUserData;

    /*//////////////////////////////////////////////////////////////
                                POOL DATA
    //////////////////////////////////////////////////////////////*/

    struct GlobalData {
        // The total number of gobblers currently deposited by the user.
        uint32 totalGobblersDeposited;
        // The sum of the multiples of all gobblers the user holds.
        uint32 totalEmissionMultiple;
        // User's goo balance at time of last checkpointing.
        uint128 totalVirtualBalance;
        // Timestamp of the last goo balance checkpoint.
        uint48 lastTimestamp;
    }

    GlobalData public globalData;

    /// @notice Maps voltron gobbler IDs to claimable
    mapping(uint256 => bool) public gobblerClaimable;
    uint256[] public claimableGobblers;
    uint256 public claimableGobblersNum;

    /*//////////////////////////////////////////////////////////////
                                admin
    //////////////////////////////////////////////////////////////*/

    bool public mintLock;
    bool public claimGobblerLock;

    // must stake timeLockDuration time to withdraw
    // Avoid directly claiming the cheaper gobbler after the user deposits goo
    uint256 public timeLockDuration;

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

    constructor(address admin_, address artGobblers_, address goo_, uint256 timeLockDuration_) Owned(admin_) {
        artGobblers = artGobblers_;
        goo = goo_;
        timeLockDuration = timeLockDuration_;
    }

    function depositGobblers(uint256[] calldata gobblerIds, uint256 gooAmount) external nonReentrant {
        if (gooAmount > 0) _addGoo(gooAmount);

        // update user virtual balance of GOO
        _updateGlobalBalance(gooAmount);
        _updateUserGooBalance(msg.sender, gooAmount);

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
        globalData.totalGobblersDeposited += totalNumber;
        globalData.totalEmissionMultiple += sumEmissionMultiple;

        emit GobblerDeposited(msg.sender, gobblerIds, gobblerIds);
    }

    function withdrawGobblers(uint256[] calldata gobblerIds) external nonReentrant {
        // update user virtual balance of GOO
        _updateGlobalBalance(0);
        _updateUserGooBalance(msg.sender, 0);

        uint256 id;
        address holder;
        uint32 emissionMultiple;
        uint32 deltaEmissionMultiple;

        uint32 totalNumber = uint32(gobblerIds.length);
        for (uint256 i = 0; i < totalNumber; ++i) {
            id = gobblerIds[i];
            (holder,, emissionMultiple) = IArtGobblers(artGobblers).getGobblerData(id);
            require(getUserByGobblerId[id] == msg.sender, "WRONG_OWNER");

            deltaEmissionMultiple += emissionMultiple;

            delete getUserByGobblerId[id];

            IArtGobblers(artGobblers).transferFrom(address(this), msg.sender, id);
        }

        // update user data
        getUserData[msg.sender].gobblersOwned -= totalNumber;
        getUserData[msg.sender].emissionMultiple -= deltaEmissionMultiple;

        // update global data
        globalData.totalGobblersDeposited -= totalNumber;
        globalData.totalEmissionMultiple -= deltaEmissionMultiple;

        emit GobblerWithdrawn(msg.sender, gobblerIds, gobblerIds);
    }

    function mintVoltronGobblers(uint256 maxPrice, uint256 num) external nonReentrant canMint {
        uint256[] memory gobblerIds = new uint256[](num);
        claimableGobblersNum += num;
        for (uint256 i = 0; i < num; i++) {
            uint256 gobblerId = IArtGobblers(artGobblers).mintFromGoo(maxPrice, true);
            gobblerIds[i] = gobblerId;
            claimableGobblers.push(gobblerId);
            gobblerClaimable[gobblerId] = true;
        }
        emit GobblerMinted(num, gobblerIds, gobblerIds);
    }

    function claimVoltronGobblers(uint256[] calldata gobblerIds) external nonReentrant canClaimGobbler {
        // Avoid directly claiming the cheaper gobbler after the user deposits goo
        require(getUserData[msg.sender].lastGooDepositedTimestamp + timeLockDuration <= block.timestamp, "CANT_CLAIM_NOW");

        uint256 globalBalance = _updateGlobalBalance(0);
        uint256 userVirtualBalance = _updateUserGooBalance(msg.sender, 0);

        // (user's virtual goo / global virtual goo) * total claimable num - claimed num
        uint256 claimableNum =
            userVirtualBalance.divWadDown(globalBalance).mulWadDown(claimableGobblers.length) - uint256(getUserData[msg.sender].claimedNum);

        uint256 claimNum = gobblerIds.length;
        require(claimableNum >= claimNum, "CLAIM_TOO_MUCH");

        getUserData[msg.sender].claimedNum += uint16(claimNum);
        claimableGobblersNum -= claimNum;

        // claim gobblers
        uint256 id;
        for (uint256 i = 0; i < claimNum; i++) {
            id = gobblerIds[i];
            require(gobblerClaimable[id], "GOBBLER_NOT_CLAIMABLE");
            gobblerClaimable[id] = false;
            IArtGobblers(artGobblers).transferFrom(address(this), msg.sender, id);
        }

        emit GobblersClaimed(msg.sender, gobblerIds, gobblerIds);
    }

    function addGoo(uint256 amount) external nonReentrant {
        require(amount > 0, "INVALID_AMOUNT");
        _addGoo(amount);
        _updateGlobalBalance(amount);
        _updateUserGooBalance(msg.sender, amount);
    }

    function _addGoo(uint256 amount) internal {
        uint256 poolBalanceBefore = IArtGobblers(artGobblers).gooBalance(address(this));
        IGOO(goo).transferFrom(msg.sender, address(this), amount);
        IArtGobblers(artGobblers).addGoo(amount);
        require(IArtGobblers(artGobblers).gooBalance(address(this)) - poolBalanceBefore >= amount, "ADDGOO_FAILD");
    }

    /*//////////////////////////////////////////////////////////////
                            UTILS FUNCTION
    //////////////////////////////////////////////////////////////*/

    function _updateGlobalBalance(uint256 gooAmount) internal returns (uint256) {
        uint256 updatedBalance = globalGooBalance() + gooAmount;
        // update global balance
        globalData.totalVirtualBalance = uint128(updatedBalance);
        globalData.lastTimestamp = uint48(block.timestamp);
        return updatedBalance;
    }


    /// @notice Calculate global virtual goo balance.
    function globalGooBalance() public view returns (uint256) {
        // Compute the user's virtual goo balance by leveraging LibGOO.
        // prettier-ignore
        return LibGOO.computeGOOBalance(
            globalData.totalEmissionMultiple,
            globalData.totalVirtualBalance,
            uint256(toDaysWadUnsafe(block.timestamp - globalData.lastTimestamp))
        );
    }

    /// @notice Update a user's virtual goo balance.
    /// @param user The user whose virtual goo balance we should update.
    /// @param gooAmount The amount of goo to add the user's virtual balance by.
    function _updateUserGooBalance(address user, uint256 gooAmount) internal returns (uint256) {
        // Don't need to do checked addition in the increase case, but we do it anyway for convenience.
        uint256 updatedBalance = gooBalance(user) + gooAmount;

        // Snapshot the user's new goo balance with the current timestamp.
        getUserData[user].virtualBalance = uint128(updatedBalance);
        getUserData[user].lastTimestamp = uint48(block.timestamp);
        if (gooAmount != 0) getUserData[user].lastGooDepositedTimestamp = uint48(block.timestamp);

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

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTION
    //////////////////////////////////////////////////////////////*/

    /// @notice admin claim voltron gobblers and goo remained in pool, only used when all user withdrawn their gobblers
    function adminClaimGobblersAndGoo(uint256[] calldata gobblerIds) external onlyOwner nonReentrant {
        _updateGlobalBalance(0);

        // require all user has withdraw their gobblers
        require(globalData.totalGobblersDeposited == 0, "ADMIN_CANT_CLAIM");

        // goo in gobblers
        IArtGobblers(artGobblers).removeGoo(IArtGobblers(artGobblers).gooBalance(address(this)));

        uint256 claimableGoo = IGOO(goo).balanceOf(address(this));
        IGOO(goo).transfer(msg.sender, claimableGoo);

        emit VoltronGooClaimed(msg.sender, claimableGoo);

        // claim gobblers
        uint256 claimNum = gobblerIds.length;
        claimableGobblersNum -= claimNum;
        for (uint256 i = 0; i < claimNum; i++) {
            uint256 id = gobblerIds[i];
            require(gobblerClaimable[id], "GOBBLER_NOT_CLAIMABLE");
            gobblerClaimable[id] = false;
            IArtGobblers(artGobblers).transferFrom(address(this), msg.sender, id);
        }

        emit GobblersClaimed(msg.sender, gobblerIds, gobblerIds);
    }

    function setMintLock(bool isLock) external onlyOwner {
        mintLock = isLock;
    }

    function setClaimGobblerLock(bool isLock) external onlyOwner {
        claimGobblerLock = isLock;
    }

    function setTimeLockDuration(uint256 timeLockDuration_) external onlyOwner {
        timeLockDuration = timeLockDuration_;
    }
}