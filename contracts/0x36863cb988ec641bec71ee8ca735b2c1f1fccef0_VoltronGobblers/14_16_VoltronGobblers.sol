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
                                                                                                / =/*/

import { LibGOO } from "goo-issuance/LibGOO.sol";
import { FixedPointMathLib } from "solmate/utils/FixedPointMathLib.sol";
import { toDaysWadUnsafe } from "solmate/utils/SignedWadMath.sol";
import { OwnableUpgradeable } from "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import { VoltronGobblerStorageV1 } from "./VoltronGobblerStorage.sol";

import { IGoober } from "goobervault/interfaces/IGoober.sol";
import { IArtGobblers } from "./utils/IArtGobblers.sol";
import { IGOO } from "./utils/IGOO.sol";

contract VoltronGobblers is ReentrancyGuardUpgradeable, OwnableUpgradeable, VoltronGobblerStorageV1 {
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                CONSTANT
    //////////////////////////////////////////////////////////////*/
    /// @notice A scalar for scaling up and down to basis points.
    uint16 private constant BPS_SCALAR = 1e4;
    /// @notice The average multiplier of a newly minted gobbler.
    /// @notice 7.3294 = weighted avg. multiplier from mint probabilities,
    /// @notice derived from: ((6*3057) + (7*2621) + (8*2293) + (9*2029)) / 10000.
    uint32 private constant AVERAGE_MULT_BPS = 73294;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event GobblerDeposited(address indexed user, uint256[] indexed IndexedGobblerIds, uint256[] gobblerIds);
    event GobblerWithdrawn(address indexed user, uint256[] indexed IndexedGobblerIds, uint256[] gobblerIds);
    event GooBalanceUpdated(address indexed user, uint256 newGooBalance);
    event GobblerMinted(uint256 indexed num, uint256[] indexed IndexedGobblerIds, uint256[] gobblerIds);
    event GobblersClaimed(address indexed user, uint256[] indexed IndexedGobblerIds, uint256[] gobblerIds);
    event GooClaimed(address indexed to, uint256 indexed amount);

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

    modifier onlyMinter() {
        require(msg.sender == minter, "ONLY_MINTER");
        _;
    }

    function initialize(address admin_, address minter_, address artGobblers_, address goo_, address goober_, uint256 timeLockDuration_)
        public
        initializer
    {
        __ReentrancyGuard_init();
        __Ownable_init();
        transferOwnership(admin_);
        minter = minter_;
        artGobblers = artGobblers_;
        goo = goo_;
        goober = goober_;
        timeLockDuration = timeLockDuration_;
        mintLock = true;
    }

    function depositGobblers(uint256[] calldata gobblerIds, uint256 gooAmount) external nonReentrant {
        if (gooAmount > 0) _addGoo(gooAmount);

        // update user virtual balance of GOO
        _updateGlobalBalance(gooAmount);
        _updateUserGooBalance(msg.sender, gooAmount);

        uint256 id;
        address holder;
        uint32 emissionMultiple;
        uint32 deltaEmissionMultiple;

        uint32 totalNumber = uint32(gobblerIds.length);
        for (uint256 i = 0; i < totalNumber; ++i) {
            id = gobblerIds[i];
            (holder,, emissionMultiple) = IArtGobblers(artGobblers).getGobblerData(id);
            require(holder == msg.sender, "WRONG_OWNER");
            require(emissionMultiple > 0, "GOBBLER_MUST_BE_REVEALED");

            deltaEmissionMultiple += emissionMultiple;

            getUserByGobblerId[id] = msg.sender;

            IArtGobblers(artGobblers).transferFrom(msg.sender, address(this), id);
        }

        // update user data
        getUserData[msg.sender].gobblersOwned += totalNumber;
        getUserData[msg.sender].emissionMultiple += deltaEmissionMultiple;

        // update global data
        globalData.totalGobblersDeposited += totalNumber;
        globalData.totalEmissionMultiple += deltaEmissionMultiple;

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

    function _mintGobblers(uint256 maxPrice, uint256 num) internal returns (uint256[] memory gobblerIds) {
        gobblerIds = new uint256[](num);
        claimableGobblersNum += num;
        for (uint256 i = 0; i < num; i++) {
            uint256 id = IArtGobblers(artGobblers).mintFromGoo(maxPrice, true);
            gobblerIds[i] = id;
            _addClaimableGobbler(id);
        }
        emit GobblerMinted(num, gobblerIds, gobblerIds);
        return gobblerIds;
    }

    function _addClaimableGobbler(uint256 id) internal {
        claimableGobblers.push(id);
        gobblerClaimable[id] = true;
    }

    function _removeClaimableGobbler(uint256 id) internal {
        uint256 len = claimableGobblers.length;
        for (uint256 idx = 0; idx < len; idx++) {
            if (claimableGobblers[idx] == id) {
                // found the existing gobbler ID
                // remove it from the array efficiently by re-ordering and deleting the last element
                if (idx != len - 1) {
                    claimableGobblers[idx] = claimableGobblers[len - 1];
                }
                claimableGobblers.pop();
                delete gobblerClaimable[id];
                break;
            }
        }
    }

    function mintGobblers(uint256 maxPrice, uint256 num) external nonReentrant canMint returns (uint256[] memory) {
        return _mintGobblers(maxPrice, num);
    }

    function claimGobblers(uint256[] calldata gobblerIds) external nonReentrant canClaimGobbler {
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

    function swapFromGoober(uint256 maxGooIn, uint256[] memory gobblersOut) external nonReentrant canMint {
        uint256[] memory gobblersIn;
        _swapFromGoober(gobblersIn, maxGooIn, gobblersOut, 0);
    }

    function _swapFromGoober(uint256[] memory gobblersIn, uint256 maxGooIn, uint256[] memory gobblersOut, uint256 gooOut) internal {
        int256 erroneousGoo = IGoober(goober).previewSwap(gobblersIn, maxGooIn, gobblersOut, gooOut);
        require(erroneousGoo <= 0, "MAX_GOO_IN_EXCEEDED");

        uint256 gooIn = maxGooIn - uint256(-erroneousGoo);
        IArtGobblers(artGobblers).removeGoo(gooIn);
        IGOO(goo).approve(goober, gooIn);

        for (uint256 i = 0; i < gobblersIn.length; i++) {
            uint256 id = gobblersIn[i];
            require(gobblerClaimable[id], "CAN_NOT_SWAP_UNCLAIMABLE_GOBBLER");
            IArtGobblers(artGobblers).approve(goober, id);
            _removeClaimableGobbler(id);
        }
        IGoober(goober).swap(gobblersIn, gooIn, gobblersOut, gooOut, address(this), "");

        if (gooOut > 0) {
            uint256 _gooBalance = IGOO(goo).balanceOf(address(this));
            // check GOO received in case of misbehaviour of goober
            require(_gooBalance >= gooOut);
            // add all GOOs into tank
            IArtGobblers(artGobblers).addGoo(_gooBalance);
        }

        uint256 num = gobblersOut.length;
        claimableGobblersNum += num;
        for (uint256 i = 0; i < num; i++) {
            uint256 id = gobblersOut[i];
            require(IArtGobblers(artGobblers).ownerOf(id) == address(this));
            _addClaimableGobbler(id);
        }
        emit GobblerMinted(num, gobblersOut, gobblersOut);
    }

    /// @notice Arbitrage between `goober` market and mint auction
    /// Used when sell price on `goober` is higher than mint price on the auction
    /// @param gobblersIn The gobbler IDs to sell to `goober` market, can only use unclaimed gobblers
    function arbitrageFromGoober(uint256[] memory gobblersIn) external nonReentrant returns (uint256[] memory newGobblerIds) {
        uint256[] memory gobblersOut;
        // simulate swap to get how much GOO we can received for this swap
        int256 erroneousGoo = IGoober(goober).previewSwap(gobblersIn, 0, gobblersOut, 0);
        require(erroneousGoo < 0, "GOOBER_NOT_PAYING_ANY_GOO");
        uint256 gooReceived = uint256(-erroneousGoo);

        uint256 num = gobblersIn.length;
        uint256 deltaEmissionMultiple;
        for (uint256 i = 0; i < num; i++) {
            uint256 id = gobblersIn[i];
            (,, uint256 emissionMultiple) = IArtGobblers(artGobblers).getGobblerData(id);
            require(emissionMultiple > 0, "UNREVEALED_GOBBLER");
            deltaEmissionMultiple += emissionMultiple;
        }
        // no need to use scaler here since GOO is a 18 decimals token
        uint256 avgSellPricePerMult = gooReceived.divWadDown(deltaEmissionMultiple);
        uint256 gooBalanceBefore = IArtGobblers(artGobblers).gooBalance(address(this));

        _swapFromGoober(gobblersIn, 0, gobblersOut, gooReceived);
        newGobblerIds = _mintGobblers(type(uint256).max, num);

        uint256 gooBalanceAfter = IArtGobblers(artGobblers).gooBalance(address(this));
        require(gooBalanceAfter > gooBalanceBefore, "GOO_REDUCED");

        uint256 gooConsumedForMinting = gooBalanceBefore + gooReceived - gooBalanceAfter;
        // use 7.3 as expected multiplier of newly minted gobbler to calc mint price per multiplier
        uint256 avgMintPricePerMult = gooConsumedForMinting.mulWadDown(BPS_SCALAR).divWadDown(AVERAGE_MULT_BPS * num);
        require(avgSellPricePerMult > avgMintPricePerMult, "MINT_PRICE_GRATER_THAN_SELL_PRICE");
        return newGobblerIds;
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

    function mintGobblersByMinter(uint256 maxPrice, uint256 num) external onlyMinter nonReentrant returns (uint256[] memory) {
        return _mintGobblers(maxPrice, num);
    }

    function swapFromGooberByMinter(uint256 maxGooIn, uint256[] memory gobblersOut) external onlyMinter nonReentrant {
        uint256[] memory gobblersIn;
        _swapFromGoober(gobblersIn, maxGooIn, gobblersOut, 0);
    }

    /// @notice admin claim gobblers and goo remained in pool, only used when all user withdrawn their gobblers
    function adminClaimGobblersAndGoo(uint256[] calldata gobblerIds) external nonReentrant {
        _updateGlobalBalance(0);

        // require all user has withdraw their gobblers
        require(globalData.totalGobblersDeposited == 0, "ADMIN_CANT_CLAIM");

        // goo in gobblers
        IArtGobblers(artGobblers).removeGoo(IArtGobblers(artGobblers).gooBalance(address(this)));

        uint256 claimableGoo = IGOO(goo).balanceOf(address(this));
        address owner_ = owner();
        IGOO(goo).transfer(owner_, claimableGoo);

        emit GooClaimed(owner_, claimableGoo);

        // claim gobblers
        uint256 claimNum = gobblerIds.length;
        claimableGobblersNum -= claimNum;
        for (uint256 i = 0; i < claimNum; i++) {
            uint256 id = gobblerIds[i];
            require(gobblerClaimable[id], "GOBBLER_NOT_CLAIMABLE");
            gobblerClaimable[id] = false;
            IArtGobblers(artGobblers).transferFrom(address(this), owner_, id);
        }

        emit GobblersClaimed(owner_, gobblerIds, gobblerIds);
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

    function setGoober(address goober_) external onlyOwner {
        goober = goober_;
    }
}