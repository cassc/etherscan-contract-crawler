// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IXENCrypto.sol";
import "./XENWallet.sol";
import "./XELCrypto.sol";

contract XENWalletManager is Ownable {
    using Clones for address;
    using SafeERC20 for IXENCrypto;

    event WalletsCreated(address indexed owner, uint256 amount, uint256 term);
    event TokensClaimed(
        address indexed owner,
        uint256 totalXEN,
        uint256 totalWallets,
        uint256 weightedTerm,
        uint256 weightedRank,
        uint256 weightedMaturity,
        uint256 totalXEL
    );
    event FeeReceiverChanged(address newReceiver);

    address public feeReceiver;
    address internal immutable implementation;
    address public immutable XENCrypto;
    uint256 public immutable deployTimestamp;
    XELCrypto public immutable xelCrypto;

    uint256 public totalWallets;
    uint256 public activeWallets;
    mapping(address => address[]) internal unmintedWallets;

    uint32[250] internal cumulativeWeeklyRewardMultiplier;

    uint256 internal constant SECONDS_IN_DAY = 3_600 * 24;
    uint256 internal constant SECONDS_IN_WEEK = SECONDS_IN_DAY * 7;
    uint256 internal constant MIN_TOKEN_MINT_TERM = 50;
    uint256 internal constant MIN_REWARD_LIMIT = SECONDS_IN_DAY * 2;
    uint256 internal constant MINT_FEE = 1_000; // 10%

    constructor(
        address xenCrypto,
        address walletImplementation,
        address feeAddress
    ) {
        require(
            xenCrypto != address(0x0) &&
                walletImplementation != address(0x0) &&
                feeAddress != address(0x0),
            "Invalid addresses"
        );
        XENCrypto = xenCrypto;
        implementation = walletImplementation;
        feeReceiver = feeAddress;
        xelCrypto = new XELCrypto(address(this));
        deployTimestamp = block.timestamp;

        populateRates();
    }

    // PUBLIC CONVENIENCE GETTERS

    /**
     * @dev generate a unique salt based on message sender and id value
     */
    function getSalt(uint256 id) public view returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender, id));
    }

    /**
     * @dev derive a deterministic address based on a salt value
     */
    function getDeterministicAddress(bytes32 salt)
        public
        view
        returns (address)
    {
        return implementation.predictDeterministicAddress(salt);
    }

    /**
     * @dev calculates elapsed number of weeks after contract deployment
     */
    function getElapsedWeeks() public view returns (uint256) {
        return (block.timestamp - deployTimestamp) / SECONDS_IN_WEEK;
    }

    /**
     * @dev returns wallet count associated with wallet owner
     */
    function getWalletCount(address owner) public view returns (uint256) {
        return unmintedWallets[owner].length;
    }

    /**
     * @dev returns wallet addresses based on pagination approach
     */
    function getWallets(
        address owner,
        uint256 startId,
        uint256 endId
    ) external view returns (address[] memory) {
        require(
            endId < unmintedWallets[owner].length,
            "endId exceeds wallet count"
        );
        uint256 size = endId - startId + 1;
        address[] memory wallets = new address[](size);
        for (uint256 id = startId; id <= endId; id++) {
            wallets[id - startId] = unmintedWallets[owner][id];
        }
        return wallets;
    }

    /**
     * @dev returns Mint objects for an array of addresses
     */
    function getUserInfos(address[] calldata owners)
        external
        view
        returns (IXENCrypto.MintInfo[] memory infos)
    {
        infos = new IXENCrypto.MintInfo[](owners.length);
        for (uint256 id = 0; id < owners.length; id++) {
            infos[id] = XENWallet(owners[id]).getUserMint();
        }
    }

    /**
     * @dev returns cumulative weekly reward multiplier at a specific week index
     */
    function getCumulativeWeeklyRewardMultiplier(int256 index)
        public
        view
        returns (uint256)
    {
        if (index < 0) return 0;
        if (index >= int256(cumulativeWeeklyRewardMultiplier.length)) {
            // Return the last multiplier
            return
                cumulativeWeeklyRewardMultiplier[
                    cumulativeWeeklyRewardMultiplier.length - 1
                ];
        }
        return cumulativeWeeklyRewardMultiplier[uint256(index)];
    }

    /**
     * @dev returns weekly reward multiplier
     */
    function getWeeklyRewardMultiplier(int256 index)
        external
        view
        returns (uint256)
    {
        return
            getCumulativeWeeklyRewardMultiplier(index) -
            getCumulativeWeeklyRewardMultiplier(index - 1);
    }

    /**
     * @dev calculates reward multiplier
     * @param finalWeek defines the the number of weeks that has elapsed
     * @param termWeeks defines the term limit in weeks
     */
    function getRewardMultiplier(uint256 finalWeek, uint256 termWeeks)
        public
        view
        returns (uint256)
    {
        return
            getCumulativeWeeklyRewardMultiplier(int256(finalWeek)) -
            getCumulativeWeeklyRewardMultiplier(
                int256(finalWeek) - int256(termWeeks) - 1
            );
    }

    /**
     * @dev calculates adjusted mint amount based on reward multiplier
     * @param originalAmount defines the original amount without adjustment
     * @param termDays defines the term limit in days
     */
    function getAdjustedMintAmount(uint256 originalAmount, uint256 termDays)
        internal
        view
        virtual
        returns (uint256)
    {
        uint256 elapsedWeeks = getElapsedWeeks();
        uint256 termWeeks = termDays / 7;
        return
            (originalAmount * getRewardMultiplier(elapsedWeeks, termWeeks)) /
            1_000_000_000;
    }

    // STATE CHANGING FUNCTIONS

    /**
     * @dev create wallet using a specific index and term
     */
    function createWallet(uint256 id, uint256 term) internal {
        bytes32 salt = getSalt(id);
        XENWallet clone = XENWallet(implementation.cloneDeterministic(salt));

        clone.initialize(XENCrypto, address(this));
        clone.claimRank(term);

        unmintedWallets[msg.sender].push(address(clone));
    }

    /**
     * @dev batch create wallets with a specific term
     * @param amount defines the number of wallets
     * @param term defines the term limit in seconds
     */
    function batchCreateWallets(uint256 amount, uint256 term) external {
        require(amount >= 1, "More than one wallet");
        require(term >= MIN_TOKEN_MINT_TERM, "Too short term");

        uint256 existing = unmintedWallets[msg.sender].length;
        for (uint256 id = 0; id < amount; id++) {
            createWallet(id + existing, term);
        }

        totalWallets += amount;
        activeWallets += amount;

        emit WalletsCreated(msg.sender, amount, term);
    }

    /**
     * @dev claims rewards and sends them to the wallet owner
     */
    function batchClaimAndTransferMintReward(uint256 startId, uint256 endId)
        external
    {
        require(endId >= startId, "Forward ordering");

        uint256 claimedTotal = 0;
        uint256 claimedWallets = 0;

        uint256 weightedTerm = 0;
        uint256 weightedRank = 0;
        uint256 weightedMaturity = 0;

        for (uint256 id = startId; id <= endId; id++) {
            address proxy = unmintedWallets[msg.sender][id];
            IXENCrypto.MintInfo memory info = XENWallet(proxy).getUserMint();
            uint256 claimed = XENWallet(proxy).claimAndTransferMintReward(
                msg.sender
            );

            claimedTotal += claimed;
            claimedWallets += 1;

            weightedTerm += (info.term * claimed);
            weightedRank += (info.rank * claimed);
            weightedMaturity += (info.maturityTs * claimed);

            unmintedWallets[msg.sender][id] = address(0x0);
        }

        if (claimedTotal > 0) {
            activeWallets -= claimedWallets;

            weightedTerm = weightedTerm / claimedTotal;
            weightedRank = weightedRank / claimedTotal;
            weightedMaturity = weightedMaturity / claimedTotal;

            uint256 toBeMinted = getAdjustedMintAmount(
                claimedTotal,
                weightedTerm
            );
            uint256 fee = (toBeMinted * MINT_FEE) / 10_000; // reduce minting fee
            xelCrypto.mint(msg.sender, toBeMinted - fee);
            xelCrypto.mint(feeReceiver, fee);

            emit TokensClaimed(
                msg.sender,
                claimedTotal,
                claimedWallets,
                weightedTerm,
                weightedRank,
                weightedMaturity,
                toBeMinted - fee
            );
        }
    }

    /**
     * @dev change fee receiver address
     */
    function changeFeeReceiver(address newReceiver) external onlyOwner {
        require(newReceiver != address(0x0), "Invalid address");
        feeReceiver = newReceiver;

        emit FeeReceiverChanged(newReceiver);
    }

    function populateRates() internal virtual {
        /*
        Precalculated values for the formula:
        // integrate 0.10000026975 * 0.95^x from 0 to index
        // Calculate 5% weekly decline and compound rewards
        let current = precisionMultiplier * 0.10000026975;
        let cumulative = current;
        for (let i = 0; i < elapsedWeeks; i++) {
            current = (current * 95) / 100;
            cumulative += current;
        }
        return cumulative;
        */
        cumulativeWeeklyRewardMultiplier[0] = 100000269;
        cumulativeWeeklyRewardMultiplier[1] = 195000526;
        cumulativeWeeklyRewardMultiplier[2] = 285250769;
        cumulativeWeeklyRewardMultiplier[3] = 370988500;
        cumulativeWeeklyRewardMultiplier[4] = 452439345;
        cumulativeWeeklyRewardMultiplier[5] = 529817647;
        cumulativeWeeklyRewardMultiplier[6] = 603327035;
        cumulativeWeeklyRewardMultiplier[7] = 673160953;
        cumulativeWeeklyRewardMultiplier[8] = 739503175;
        cumulativeWeeklyRewardMultiplier[9] = 802528286;
        cumulativeWeeklyRewardMultiplier[10] = 862402141;
        cumulativeWeeklyRewardMultiplier[11] = 919282304;
        cumulativeWeeklyRewardMultiplier[12] = 973318458;
        cumulativeWeeklyRewardMultiplier[13] = 1024652805;
        cumulativeWeeklyRewardMultiplier[14] = 1073420435;
        cumulativeWeeklyRewardMultiplier[15] = 1119749683;
        cumulativeWeeklyRewardMultiplier[16] = 1163762468;
        cumulativeWeeklyRewardMultiplier[17] = 1205574615;
        cumulativeWeeklyRewardMultiplier[18] = 1245296154;
        cumulativeWeeklyRewardMultiplier[19] = 1283031616;
        cumulativeWeeklyRewardMultiplier[20] = 1318880305;
        cumulativeWeeklyRewardMultiplier[21] = 1352936559;
        cumulativeWeeklyRewardMultiplier[22] = 1385290001;
        cumulativeWeeklyRewardMultiplier[23] = 1416025771;
        cumulativeWeeklyRewardMultiplier[24] = 1445224752;
        cumulativeWeeklyRewardMultiplier[25] = 1472963784;
        cumulativeWeeklyRewardMultiplier[26] = 1499315864;
        cumulativeWeeklyRewardMultiplier[27] = 1524350341;
        cumulativeWeeklyRewardMultiplier[28] = 1548133094;
        cumulativeWeeklyRewardMultiplier[29] = 1570726709;
        cumulativeWeeklyRewardMultiplier[30] = 1592190643;
        cumulativeWeeklyRewardMultiplier[31] = 1612581381;
        cumulativeWeeklyRewardMultiplier[32] = 1631952581;
        cumulativeWeeklyRewardMultiplier[33] = 1650355222;
        cumulativeWeeklyRewardMultiplier[34] = 1667837731;
        cumulativeWeeklyRewardMultiplier[35] = 1684446114;
        cumulativeWeeklyRewardMultiplier[36] = 1700224078;
        cumulativeWeeklyRewardMultiplier[37] = 1715213144;
        cumulativeWeeklyRewardMultiplier[38] = 1729452756;
        cumulativeWeeklyRewardMultiplier[39] = 1742980388;
        cumulativeWeeklyRewardMultiplier[40] = 1755831638;
        cumulativeWeeklyRewardMultiplier[41] = 1768040326;
        cumulativeWeeklyRewardMultiplier[42] = 1779638580;
        cumulativeWeeklyRewardMultiplier[43] = 1790656920;
        cumulativeWeeklyRewardMultiplier[44] = 1801124344;
        cumulativeWeeklyRewardMultiplier[45] = 1811068397;
        cumulativeWeeklyRewardMultiplier[46] = 1820515246;
        cumulativeWeeklyRewardMultiplier[47] = 1829489754;
        cumulativeWeeklyRewardMultiplier[48] = 1838015536;
        cumulativeWeeklyRewardMultiplier[49] = 1846115029;
        cumulativeWeeklyRewardMultiplier[50] = 1853809547;
        cumulativeWeeklyRewardMultiplier[51] = 1861119339;
        cumulativeWeeklyRewardMultiplier[52] = 1868063642;
        cumulativeWeeklyRewardMultiplier[53] = 1874660730;
        cumulativeWeeklyRewardMultiplier[54] = 1880927963;
        cumulativeWeeklyRewardMultiplier[55] = 1886881835;
        cumulativeWeeklyRewardMultiplier[56] = 1892538013;
        cumulativeWeeklyRewardMultiplier[57] = 1897911382;
        cumulativeWeeklyRewardMultiplier[58] = 1903016082;
        cumulativeWeeklyRewardMultiplier[59] = 1907865548;
        cumulativeWeeklyRewardMultiplier[60] = 1912472540;
        cumulativeWeeklyRewardMultiplier[61] = 1916849183;
        cumulativeWeeklyRewardMultiplier[62] = 1921006994;
        cumulativeWeeklyRewardMultiplier[63] = 1924956914;
        cumulativeWeeklyRewardMultiplier[64] = 1928709338;
        cumulativeWeeklyRewardMultiplier[65] = 1932274141;
        cumulativeWeeklyRewardMultiplier[66] = 1935660703;
        cumulativeWeeklyRewardMultiplier[67] = 1938877938;
        cumulativeWeeklyRewardMultiplier[68] = 1941934311;
        cumulativeWeeklyRewardMultiplier[69] = 1944837865;
        cumulativeWeeklyRewardMultiplier[70] = 1947596241;
        cumulativeWeeklyRewardMultiplier[71] = 1950216699;
        cumulativeWeeklyRewardMultiplier[72] = 1952706134;
        cumulativeWeeklyRewardMultiplier[73] = 1955071097;
        cumulativeWeeklyRewardMultiplier[74] = 1957317812;
        cumulativeWeeklyRewardMultiplier[75] = 1959452191;
        cumulativeWeeklyRewardMultiplier[76] = 1961479851;
        cumulativeWeeklyRewardMultiplier[77] = 1963406128;
        cumulativeWeeklyRewardMultiplier[78] = 1965236091;
        cumulativeWeeklyRewardMultiplier[79] = 1966974557;
        cumulativeWeeklyRewardMultiplier[80] = 1968626099;
        cumulativeWeeklyRewardMultiplier[81] = 1970195063;
        cumulativeWeeklyRewardMultiplier[82] = 1971685580;
        cumulativeWeeklyRewardMultiplier[83] = 1973101571;
        cumulativeWeeklyRewardMultiplier[84] = 1974446762;
        cumulativeWeeklyRewardMultiplier[85] = 1975724693;
        cumulativeWeeklyRewardMultiplier[86] = 1976938728;
        cumulativeWeeklyRewardMultiplier[87] = 1978092062;
        cumulativeWeeklyRewardMultiplier[88] = 1979187728;
        cumulativeWeeklyRewardMultiplier[89] = 1980228612;
        cumulativeWeeklyRewardMultiplier[90] = 1981217451;
        cumulativeWeeklyRewardMultiplier[91] = 1982156848;
        cumulativeWeeklyRewardMultiplier[92] = 1983049275;
        cumulativeWeeklyRewardMultiplier[93] = 1983897081;
        cumulativeWeeklyRewardMultiplier[94] = 1984702497;
        cumulativeWeeklyRewardMultiplier[95] = 1985467642;
        cumulativeWeeklyRewardMultiplier[96] = 1986194529;
        cumulativeWeeklyRewardMultiplier[97] = 1986885073;
        cumulativeWeeklyRewardMultiplier[98] = 1987541089;
        cumulativeWeeklyRewardMultiplier[99] = 1988164304;
        cumulativeWeeklyRewardMultiplier[100] = 1988756359;
        cumulativeWeeklyRewardMultiplier[101] = 1989318810;
        cumulativeWeeklyRewardMultiplier[102] = 1989853140;
        cumulativeWeeklyRewardMultiplier[103] = 1990360752;
        cumulativeWeeklyRewardMultiplier[104] = 1990842984;
        cumulativeWeeklyRewardMultiplier[105] = 1991301105;
        cumulativeWeeklyRewardMultiplier[106] = 1991736319;
        cumulativeWeeklyRewardMultiplier[107] = 1992149773;
        cumulativeWeeklyRewardMultiplier[108] = 1992542554;
        cumulativeWeeklyRewardMultiplier[109] = 1992915696;
        cumulativeWeeklyRewardMultiplier[110] = 1993270181;
        cumulativeWeeklyRewardMultiplier[111] = 1993606942;
        cumulativeWeeklyRewardMultiplier[112] = 1993926864;
        cumulativeWeeklyRewardMultiplier[113] = 1994230791;
        cumulativeWeeklyRewardMultiplier[114] = 1994519521;
        cumulativeWeeklyRewardMultiplier[115] = 1994793815;
        cumulativeWeeklyRewardMultiplier[116] = 1995054394;
        cumulativeWeeklyRewardMultiplier[117] = 1995301944;
        cumulativeWeeklyRewardMultiplier[118] = 1995537116;
        cumulativeWeeklyRewardMultiplier[119] = 1995760530;
        cumulativeWeeklyRewardMultiplier[120] = 1995972774;
        cumulativeWeeklyRewardMultiplier[121] = 1996174405;
        cumulativeWeeklyRewardMultiplier[122] = 1996365954;
        cumulativeWeeklyRewardMultiplier[123] = 1996547926;
        cumulativeWeeklyRewardMultiplier[124] = 1996720799;
        cumulativeWeeklyRewardMultiplier[125] = 1996885029;
        cumulativeWeeklyRewardMultiplier[126] = 1997041048;
        cumulativeWeeklyRewardMultiplier[127] = 1997189265;
        cumulativeWeeklyRewardMultiplier[128] = 1997330071;
        cumulativeWeeklyRewardMultiplier[129] = 1997463837;
        cumulativeWeeklyRewardMultiplier[130] = 1997590915;
        cumulativeWeeklyRewardMultiplier[131] = 1997711639;
        cumulativeWeeklyRewardMultiplier[132] = 1997826327;
        cumulativeWeeklyRewardMultiplier[133] = 1997935280;
        cumulativeWeeklyRewardMultiplier[134] = 1998038786;
        cumulativeWeeklyRewardMultiplier[135] = 1998137117;
        cumulativeWeeklyRewardMultiplier[136] = 1998230530;
        cumulativeWeeklyRewardMultiplier[137] = 1998319274;
        cumulativeWeeklyRewardMultiplier[138] = 1998403580;
        cumulativeWeeklyRewardMultiplier[139] = 1998483670;
        cumulativeWeeklyRewardMultiplier[140] = 1998559757;
        cumulativeWeeklyRewardMultiplier[141] = 1998632039;
        cumulativeWeeklyRewardMultiplier[142] = 1998700706;
        cumulativeWeeklyRewardMultiplier[143] = 1998765941;
        cumulativeWeeklyRewardMultiplier[144] = 1998827913;
        cumulativeWeeklyRewardMultiplier[145] = 1998886787;
        cumulativeWeeklyRewardMultiplier[146] = 1998942718;
        cumulativeWeeklyRewardMultiplier[147] = 1998995852;
        cumulativeWeeklyRewardMultiplier[148] = 1999046329;
        cumulativeWeeklyRewardMultiplier[149] = 1999094282;
        cumulativeWeeklyRewardMultiplier[150] = 1999139838;
        cumulativeWeeklyRewardMultiplier[151] = 1999183116;
        cumulativeWeeklyRewardMultiplier[152] = 1999224230;
        cumulativeWeeklyRewardMultiplier[153] = 1999263288;
        cumulativeWeeklyRewardMultiplier[154] = 1999300393;
        cumulativeWeeklyRewardMultiplier[155] = 1999335643;
        cumulativeWeeklyRewardMultiplier[156] = 1999369131;
        cumulativeWeeklyRewardMultiplier[157] = 1999400944;
        cumulativeWeeklyRewardMultiplier[158] = 1999431166;
        cumulativeWeeklyRewardMultiplier[159] = 1999459878;
        cumulativeWeeklyRewardMultiplier[160] = 1999487154;
        cumulativeWeeklyRewardMultiplier[161] = 1999513066;
        cumulativeWeeklyRewardMultiplier[162] = 1999537682;
        cumulativeWeeklyRewardMultiplier[163] = 1999561068;
        cumulativeWeeklyRewardMultiplier[164] = 1999583284;
        cumulativeWeeklyRewardMultiplier[165] = 1999604390;
        cumulativeWeeklyRewardMultiplier[166] = 1999624440;
        cumulativeWeeklyRewardMultiplier[167] = 1999643488;
        cumulativeWeeklyRewardMultiplier[168] = 1999661583;
        cumulativeWeeklyRewardMultiplier[169] = 1999678774;
        cumulativeWeeklyRewardMultiplier[170] = 1999695105;
        cumulativeWeeklyRewardMultiplier[171] = 1999710619;
        cumulativeWeeklyRewardMultiplier[172] = 1999725358;
        cumulativeWeeklyRewardMultiplier[173] = 1999739360;
        cumulativeWeeklyRewardMultiplier[174] = 1999752661;
        cumulativeWeeklyRewardMultiplier[175] = 1999765298;
        cumulativeWeeklyRewardMultiplier[176] = 1999777303;
        cumulativeWeeklyRewardMultiplier[177] = 1999788707;
        cumulativeWeeklyRewardMultiplier[178] = 1999799542;
        cumulativeWeeklyRewardMultiplier[179] = 1999809834;
        cumulativeWeeklyRewardMultiplier[180] = 1999819612;
        cumulativeWeeklyRewardMultiplier[181] = 1999828902;
        cumulativeWeeklyRewardMultiplier[182] = 1999837726;
        cumulativeWeeklyRewardMultiplier[183] = 1999846110;
        cumulativeWeeklyRewardMultiplier[184] = 1999854074;
        cumulativeWeeklyRewardMultiplier[185] = 1999861640;
        cumulativeWeeklyRewardMultiplier[186] = 1999868828;
        cumulativeWeeklyRewardMultiplier[187] = 1999875656;
        cumulativeWeeklyRewardMultiplier[188] = 1999882143;
        cumulativeWeeklyRewardMultiplier[189] = 1999888305;
        cumulativeWeeklyRewardMultiplier[190] = 1999894160;
        cumulativeWeeklyRewardMultiplier[191] = 1999899722;
        cumulativeWeeklyRewardMultiplier[192] = 1999905005;
        cumulativeWeeklyRewardMultiplier[193] = 1999910025;
        cumulativeWeeklyRewardMultiplier[194] = 1999914793;
        cumulativeWeeklyRewardMultiplier[195] = 1999919323;
        cumulativeWeeklyRewardMultiplier[196] = 1999923627;
        cumulativeWeeklyRewardMultiplier[197] = 1999927715;
        cumulativeWeeklyRewardMultiplier[198] = 1999931599;
        cumulativeWeeklyRewardMultiplier[199] = 1999935289;
        cumulativeWeeklyRewardMultiplier[200] = 1999938794;
        cumulativeWeeklyRewardMultiplier[201] = 1999942124;
        cumulativeWeeklyRewardMultiplier[202] = 1999945288;
        cumulativeWeeklyRewardMultiplier[203] = 1999948293;
        cumulativeWeeklyRewardMultiplier[204] = 1999951148;
        cumulativeWeeklyRewardMultiplier[205] = 1999953860;
        cumulativeWeeklyRewardMultiplier[206] = 1999956437;
        cumulativeWeeklyRewardMultiplier[207] = 1999958885;
        cumulativeWeeklyRewardMultiplier[208] = 1999961211;
        cumulativeWeeklyRewardMultiplier[209] = 1999963420;
        cumulativeWeeklyRewardMultiplier[210] = 1999965518;
        cumulativeWeeklyRewardMultiplier[211] = 1999967512;
        cumulativeWeeklyRewardMultiplier[212] = 1999969406;
        cumulativeWeeklyRewardMultiplier[213] = 1999971206;
        cumulativeWeeklyRewardMultiplier[214] = 1999972915;
        cumulativeWeeklyRewardMultiplier[215] = 1999974539;
        cumulativeWeeklyRewardMultiplier[216] = 1999976082;
        cumulativeWeeklyRewardMultiplier[217] = 1999977548;
        cumulativeWeeklyRewardMultiplier[218] = 1999978940;
        cumulativeWeeklyRewardMultiplier[219] = 1999980263;
        cumulativeWeeklyRewardMultiplier[220] = 1999981519;
        cumulativeWeeklyRewardMultiplier[221] = 1999982713;
        cumulativeWeeklyRewardMultiplier[222] = 1999983847;
        cumulativeWeeklyRewardMultiplier[223] = 1999984924;
        cumulativeWeeklyRewardMultiplier[224] = 1999985948;
        cumulativeWeeklyRewardMultiplier[225] = 1999986920;
        cumulativeWeeklyRewardMultiplier[226] = 1999987844;
        cumulativeWeeklyRewardMultiplier[227] = 1999988722;
        cumulativeWeeklyRewardMultiplier[228] = 1999989555;
        cumulativeWeeklyRewardMultiplier[229] = 1999990347;
        cumulativeWeeklyRewardMultiplier[230] = 1999991100;
        cumulativeWeeklyRewardMultiplier[231] = 1999991814;
        cumulativeWeeklyRewardMultiplier[232] = 1999992493;
        cumulativeWeeklyRewardMultiplier[233] = 1999993138;
        cumulativeWeeklyRewardMultiplier[234] = 1999993751;
        cumulativeWeeklyRewardMultiplier[235] = 1999994333;
        cumulativeWeeklyRewardMultiplier[236] = 1999994886;
        cumulativeWeeklyRewardMultiplier[237] = 1999995412;
        cumulativeWeeklyRewardMultiplier[238] = 1999995911;
        cumulativeWeeklyRewardMultiplier[239] = 1999996385;
        cumulativeWeeklyRewardMultiplier[240] = 1999996836;
        cumulativeWeeklyRewardMultiplier[241] = 1999997264;
        cumulativeWeeklyRewardMultiplier[242] = 1999997670;
        cumulativeWeeklyRewardMultiplier[243] = 1999998056;
        cumulativeWeeklyRewardMultiplier[244] = 1999998423;
        cumulativeWeeklyRewardMultiplier[245] = 1999998772;
        cumulativeWeeklyRewardMultiplier[246] = 1999999103;
        cumulativeWeeklyRewardMultiplier[247] = 1999999417;
        cumulativeWeeklyRewardMultiplier[248] = 1999999716;
        cumulativeWeeklyRewardMultiplier[249] = 2000000000;
    }
}