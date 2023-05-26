// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

/*
@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#GY?!?YG&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@&B5?!~~^^^^~~~!77?JY5PB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#P7~^::::^^^~!?5#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@&J^:......::::::^^^^~~!!7?JYPB#&@@@@@@@@@@@@@@@@@@@@@@@@&P7^:...   ..:^^~~~!?5#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@#!:.   ...   .::::::^^^^~~!!7??JYPGB#&&&&@@@@@@@@@@@@&#Y~::..    .:..   .^~!!?Y5G#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@?^.  [email protected]@@@&G:  ::::::::^^^^~~!77??JJYYYYYYYYYYYYYYY?!:..:::   [email protected]@@@@#^  .~!7?Y5GG#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
B?^  [email protected]@&[email protected]@@&  .::::::::::^^^^~~~!!!!7777777!!!!~~^:::::::.   [email protected]@@[email protected]@@~ .:7??Y5PGB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
GJ!. ^&@@&@@@J  .::::::::::::::^^^^^^^^^^^^^^^^^^::::::::::.   [email protected]@@&@@@&^..^?JJY5PGB#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#JJ!:..!JY?^    .::::::::::::::::::::^^^^::::::::::::::::::.    :JPBG57:..^!JJYY5PGB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@5J?7^.       .::::::::::::::::::::::::::::::::::::::::::::::.         .:^7?JJYY5PG#&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@&Y??7!~^:::::^:::::::::::::::::::::::::::::::::::::::::::::::::.....:^~!7?JJJYY5PB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@&Y?7!!!~~~^^^^:::::::::::::::::::::::::::::::::::::::::::^^^^^^^^~~!!!77?JJJYY5PG#&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@G777!!~~~^^^^:::::::::::::::^:::::::::::::::::::::::::^^^^^^^^~~~!!!777?JJJYY5PGB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@5777!!~~~^^^^^::::::::::::~PBJ:.^5G?:::::::::::::::::^^^^^^^~~~~!!!777??JJJYY5PGB#&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@J?77!!~~~^^^^^:::::::::::::7!^:::?7^::::::::::::::::^^^^^^^~~~~!!!777???JJJYY55PGB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@&??777!!~~~^^^^:::::::::::::::::::::::::::::::::::::^^^^^^^^~~~~!!!777???JJJYYY5PGB##&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@G???77!!~~~^^^::::::::::::::::::::::::::::::::::::::^^^^^^^^~~~~!!!777??JJJJYY55PGGB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@5???77!!~~~^^^^::::::::::::::::::::::::::::::::::::^^^^^^^^~~~~!!!7777??JJJJYY55PPGB##&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@&YJ??77!!!~~~^^^:::::::^^~~!!7!!77!!!~^^^:::::::::::^^^^^^^~~~~!!77777????JJJYY55PPGB##&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@#JJ??777!!!~~^^^~7?J5PGGBB####BBB###BBBGPP5Y7!~^:::^^^^^~~~~~~!!77??????JJJJJYY55PPGB##&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@BJJ???777!~~7Y5GB#BBB#BBBB###BBB###B#BBBBB###BGPY?~:^^^~~~~~!!!!77???JJJJJJJJYY55PPGBB##&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@GJJJ??777!JG######BB##BBBB###BB###!:JB#BBBB##BB###B57^^~~~~!!!7777??JJJJJJYYYYYY5PPGBB#&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@GYJJ???7?PBB####&BBB##BBBB###B###?...!G##BB###B#####BGJ~~~~!!77777??JJJJYYYYYYYY5PGGB##&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@GYYJJ???G#BB###BB#B####BBB######?.....^G##BB##BB###BBB#BJ!!7777777??JJJJYYYYYYYY5PGBB#&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@GYYJJJ?5&#BBB##Y^P###B#BBB#####J.......^B#BBB##BB###BBB#577???777???JJJJYYYYYYY5PPGBB#&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@G5YYJJJYYP##B#5^..^7G#&#B#J7G?^.........7##B#BG##B###B##~:?????????JJJJJYYYYYY55PGGB##&&@@@@@@&@@&&@@@@@@@@@@@@@@@@@@@@
@B55YYJJYJ?YG##P.....:JB###!..............?###7^!!:~G###G:.!JJ?????JJJJJJJYYY555PPGBB#&&@@@@@@@&@@&&@@@@@@@@@@@@@@@@@@@@
@#555YYJ#@@@@@@&PY7!^:.~P#B^..............:B#B^.....^G##GY^:JJ??????JJJJJYYYY555PGGB##&&@@@@@@@&@@&&@@@@@@@@@@@@@@@@@@@@
@&PP55YYYY5PBB#&@@@@@&&#BB5^............::^5&#Y5GP?Y#&&&&@5.7J??JJJJJJYYYYYY555PPGGB#&&@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@
@&PP5555?...:Y&&@@@@@@B5GBG^......:~JPGB#&&&&###BY!!7~^^:::.~JJJJJJJJYYYYY555PPPPGB##&&@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@
@@BPP555Y^:^#@@@@@BJ&@&7..:::.....:?5J?!~^::^~~^::..........^JJJJJJJYYYY5555PPPPGGB#&&@@@@@@@@@@@@&&&@@@@@@@@@@@@@@@@@@@
@@@GPPPP5!:[email protected]@@@@@#[email protected]@@@Y::::.............:[email protected]@@@&BBGG5J^....~YJJJJYYYYY55555PPPPGBB#&&@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@
@@@&GGPPPY:[email protected]&#@@&[email protected]@@&@@^::::..........:J&@@@@@@~^&@@@&7...!YYYYYYYY55555PPPGGGGB#&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@#GGPPP7^!B#@@@&&@@[email protected]@^::::.........^#@@@@@&&@@@@@#@@@B~^JYYYY5555555PPPGGGGGB#&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@
@@@@@#BGGP5^:!&##@@@@&[email protected]:::::[email protected]@[email protected]@@@#@@@@#[email protected]@&5YYY555555PPPPGGGGGBB#&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@
@@@@@@&BBGGY^:J&G#BGGG#@?:::::....::[email protected]@[email protected]@@@@@@@#P&G ^~755555555PPPPGGGGGBB#&@&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@
@@@@@@@&#BGG5!:[email protected]&#B#&@#^:::::::::::...:&@@[email protected]&&&#[email protected] ..^Y5555PPPPPPGGBBBBB#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@
@@@@@@@@@##BBG7:!J7~~~~^::::............#@@@&&GGB#&G!...~Y555PPPPGGGGBBB###&&&#######&&&&&##&&&&&&&&#######&&@@@@@@@@@@@
@@@@@@@@@@&#BBBY^::::::::::.............JBGGPGB##&&!..^?555PPPGGGBBBB###&&&&&###################&&&&#########&&@@@@@@@@@
@@@@@@@@@@@@&#BB5~::::::::......................:::.:7555PPGGGBBBB###&&&&&&##########BBBB########&&&###BBBBB###&@@@@@@@@
@@@@@@@@@@@@@@&BBP!:::::::^!~~^^^:::..............:75PPPPGGBBBB###&&&&&&&########BBBBBBBBBB####&######BBBBBBBB###&@@@@@@
@@@@@@@@@@@@@@@@#BGY!^::::^&@@@@@@@J..::........:!5PPGGGBBB####&&&&&&&##########BBBBBBBBBBB########&###BBBGGGGBB##@@@@@@
@@@@@@@@@@@@@@@@@@#BG5!^::::~~!!777:.:::::::..:~YPGGGBBB###&&&&&&&######BB########BBBBBBBB######&&#&###BBGGGGGGGB#@@@@@@
@@@@@@@@@@@@@@@@@@@@&#BP?!^:.......::::::...:!5GBBB###&&&&&&######################BBBBB################BBGGPPPPPG#&@@@@@
@@@@@@@@@@@@@@@@@@@@@@@&&BG5Y?!~^^^^::::^~!YG###&&&&&&#BBGGGGGBBB##################B##############&##BBBGGPPPPPPGB&@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@&#BBBGGPPP55PPGB######BGGGPGP555PPGGBB##BB#########B############BBBBBB####BBBGGPP55555GB&@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@BBGGPPPPPPPPP555YYJJYYYY55P5555PPGGB##BBBBBBBBBBBBBBBBBBBBBBBBGGGGBBBB#BBBGGPP555555PGB&@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@&GGPP55YYYJJJJ????JJYYYYYYYYYYY55PPGGGGBBBBBBBBBBGGGGGGGGGGGGPPPPPPGGBBBBGGPP555555PPGB#@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#GGPP55YYYJJJJ???JJJJJJJJYYYYYYYY555PPPGBBBBBBBBBBBBBBGGGGGPPPP55PPGGBBBGPPP55555PPPGB#@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#PPP5555YYYYYYJYYJJJJJJJJYYYJYYYY555PPGGGBBBBB#B#BB###BGPP555555PPGBBBGGPP55555PGGGGB#@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BPP55555YYYYYYYYYYYJJYYYYYYYYYY555PPGGGGBBBBB#########BP555YY55PPGBBBGPP5555PPGGGGB##@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#GP55YYYYYYYYYYYYYYYYYYYY55555555PPGGGBBBB############P55555PPGBBBBGGPP55555PGGGGB#&&@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#BGP55YYYYYYYYYJYYYYYYYY555555PPPGGBBBBBB######&&&&&&PP5PPGGB###BBGGPP55555PGGBBB#&&@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@###BGP555Y5555YY555555P55PPPPGGGGBBBBBBBB#####&&&&&&GPGGB######BBBGPP5P55PGBBB###&&@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#####BGGGPPPPPPPPPPPPPGGGGGGBBBBBBBBBB#######&&&&&&BBB##########BGPPPPPPGBB#####&&@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BBBBB####BBBBGGGGGGGGBBBBBBBBBBB#############&&&&&&###&&&&&&@@&&BGPPP5PPBB##&&&&&&@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#PP5YY5PB######&&&################################&&&@@@@@@@@@@@@&#GGGGGB###&&&&&&&&@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G5YJ???JYPGB#&@@@@@@@@@@@@@@@@@@@&##BBBBBBBBBBBB###&&@@@@@@@@@@@@@@@@&&##&&&&&&&&&&&@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&55YJ???J5GB#&@@@@@@@@@@@@@@@@@@@@@@#BGGGGGBBGGBBB###&@@@@@@@@@@@@@@@@@@@@###&##BB#&@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#5YJ???J5PB#&@@@@@@@@@@@@@@@@@@@&GPPBBGPPGGGGGGGBBBB#&@@@@@@@@@@@@@@@@@@@&PJ77??YPG&@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@PYYJ???Y5G#&@@@@@@@@@@@@@@@@@@@B7!!!7YPGPPPPPPPGBBBB#&@@@@@@@@@@@@@@@@@@@BY7~^^!J5P&@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#5YJ??JY5GB&@@@@@@@@@@@@@@@@@@@P7!777777JPPPPPPPGGBBB#&@@@@@@@@@@@@@@@@@@@GY7!^~7YPG&@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#5YJ??JY5GB&&@@@@@@@@@@@@@@@@@&Y!!777777775PPPPPPGGBBB#&&@@@@@@@@@@@@@@@@PJ?77777?Y5G&@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B5Y?77?Y5PB&&@@@@@@@@@@@@@@@@@G~~!!777777775GPPPPPGGBBB#&&@@@@@@@@@@@@@@&?!!!!77!!77?JP#@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@&G5Y?77?Y5PB#&@@@@@@@@@@@@@@@@@@P!7~^~~!!!!!!5G55PPPGGBBB#&&@@@@@@@@@@@@@&[email protected]@
@@@@@@@@@@@@@@@@@@@@@@@@@@#G5YJ??J5PPB#&@@@@@@@@@@@@@@@@@@@@@@#7:::::^^^J5JY55PPGGGBB#&@@@@@@@@@@@@#!!!77777777777??JJJ#
@@@@@@@@@@@@@@@@@&B5JJJJ?!!7JYJY5PGGB#&&@@@@@@@@@@@@@@@@@@@@@@@@&#####Y?5J7?YY5PPGGGB#&@@@@@@@@@@@@!^!!!7777777777??JJJB
@@@@@@@@@@@@@@BPJ7777777!!!!!!!5GGBB#&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P7!!77?JY5PGB#&@@@@@@@@@@@@GY^:^[email protected]@
@@@@@@@@@@@@B7!!77777!!!!!!!!!!7YB#&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y777777!!77??JYP&@@@@@@@@@@@@@&5~~~~~^^^~!JG&@@@@
@@@@@@@@@@@5~~~!!!!!!!!!!!!!777775B&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#J77777??77!7??JJJY5YY&@@@@@@@@@@@@@@@&BBB#&@@@@@@@
@@@@@@@@@@@7.:^^^^^~~~~~~~~!77!77??JP&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@G!:.........::::^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@BY~^^^^^^^~~~!7YG####&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&!~!!!777777?????JJ?J5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&^..:^~!!!77777????5#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#Y^:.::^^~~~!!775&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&P!!7777???Y#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                                                          
                                                                                                                        
        ~^^^^^^^^^^^        :~^^~.      ^^^^^^^^^^^^.  :^^^^^^^^^^~.       ^^^^^      .~~^^^^^^^~~  ^^^^^^^^^^~^        
       :&#B###&#####G      :B#BB#P      B#GGBBBBBGGBB.!#GGGBBBBB#&B       7#GGB#7     [email protected]&###BB##&&.G#BB######&&7        
       :#BB#^...J#B##.    .G#BGGB#J     BBGB!...!BPGB:7BPG5.......       ^#GGGGB#^     ....B#B#?...##B#J.......         
       :&##&....Y&&&&.    P&#&?5&#&!    ##B&~   ^#BB#:?#B#P             .###B!B#&#.        #&&&7  .&&#&5:::::::         
       ^&&&&:[email protected]&&&#&5    J&&&P .#&&&:   ###&!   ~&##&^J#B#G             B&#&! 7&&&G        #&&@?   #&&&&@@@&&&&#.       
       :&##&.!&&&#:     !&&&#.  !&&&B  .&&#&!   ~&##&^Y&#&G            P&&&Y   P&&&J       &&&@J    ^^^^^^^J#BB&:       
       .G55G  ^BBBY    .BB#B:   .P#B&Y .##B#7...7#B#&^Y&##G.........  ?&#&G  ..^###&^      B#B#!           :PYYG.       
       .BGBB   :B##5   5#BB: .#BG555PB: PPY55PGP5YY5P.^GYYY5PPPGG#B. .BGG5  7#BP555BP      5P5B^   ~##BGGGGPP5GG        
        ~~~~    :~~!. .!~~:   ~~~^^^^~: ^~^^^^^^^^^^.  :^^^^^^^^^~.  :~~~.  .~~^^^^~!.     5GPB^    ^~~~~~^^^^^.        
                                                                                           PBG#^                        
                                                                                           G&#&^                        
                                                                                           77^.                         
                                                                                           

4,999 Radcats. 
5% of supply gets minted to a Sudo pair. 
The equivalent value of $RAD is deposited to the pair to enable trading.
Pair liquidity permanently locked & fees are distributed to Radcats.
Therefore Radcats can earn Rad just like Radbros - except Radcat $RAD rewards are eternal, 
generated by farming the sudo pool for trading fees.

*/

import { IERC721A } from "lib/erc721a/contracts/IERC721A.sol";
import { IERC721AUpgradeable } from "lib/ERC721A-Upgradeable/contracts/IERC721AUpgradeable.sol";
import { ERC721AUpgradeable } from "lib/ERC721A-Upgradeable/contracts/ERC721AUpgradeable.sol";
import {
    ERC721AQueryableUpgradeable
} from "lib/ERC721A-Upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { ERC20 } from "lib/solmate/src/tokens/ERC20.sol";
import { RadlistV2 } from "../RadlistV2.sol";
import { RadcatCurve } from "./RadcatCurve.sol";

import { LSSVMPairMissingEnumerableERC20 } from "../../lib/lssvm/src/LSSVMPairMissingEnumerableERC20.sol";
import { SafeTransferLib } from "lib/solmate/src/utils/SafeTransferLib.sol";

import {
    DefaultOperatorFiltererUpgradeable
} from "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

/// @notice Radcats.
/// @author 10xdegen
contract Radcats is
    ERC721AQueryableUpgradeable,
    RadlistV2,
    ReentrancyGuardUpgradeable,
    DefaultOperatorFiltererUpgradeable
{
    using RadcatCurve for RadcatCurve.RadCurve;
    using SafeTransferLib for ERC20;

    /*//////////////////////////////////////////////////////////////
                            MINT CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum number of mintable radcats.
    uint256 public constant MAX_SUPPLY = 7000;

    /// @notice the # of mints that can be minted to the dev wallet.
    uint256 public constant MAX_DEV_MINTS = (MAX_SUPPLY * 5) / 100;

    /// @notice the # of mints that can be minted from the radlist.
    uint256 public constant MAX_RADLIST_MINTS = (MAX_SUPPLY * 5) / 100;

    /// @notice the # of basis points for the protocol fee.
    uint256 public constant BIPS_DIVISOR = 1000;

    /// @notice the max number of mints in a single tx.
    uint256 public constant MAX_MINTS_PER_TX = 25;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the Radcoin V2 ERC20 token contract.
    ERC20 public constant radcoinV2 = ERC20(0xdDc6625FEcA10438857DD8660C021Cd1088806FB);

    /// @notice The address of the Brocoin ERC20 token contract.
    ERC20 public constant brocoin = ERC20(0x6e08B5D1169765f94d5ACe5524F56E8ac75B77c6);

    /// @notice The address of the operator.
    address public operator;

    /// @notice The address of the beneficiary.
    address public beneficiary;

    /// @notice fee charged by the protocol for Radcat yield.
    uint256 public protocolFeeBips;

    /*//////////////////////////////////////////////////////////////
                            MINTING
    //////////////////////////////////////////////////////////////*/

    /// @notice Total number minted via Radlist.
    uint256 public mintedFromRadlist;

    /// @notice Total number minted via $RAD.
    uint256 public mintedFromRAD;

    /// @notice Total number minted via $BRO.
    uint256 public mintedFromBRO;

    /// @notice Total number minted via $BRO.
    uint256 public mintedByDevs;

    /// @notice addresses that claimed a radlist mint
    mapping(address => bool) public radlistMintsClaimed;

    /// @notice Enables radlist mints.
    bool public radlistMintsEnabled;

    /// @notice Enables ETH mints.
    bool public ethMintsEnabled;

    /// @notice Enables RAD mints.
    bool public radMintsEnabled;

    /// @notice Enables BRO mints.
    bool public broMintsEnabled;

    /*//////////////////////////////////////////////////////////////
                            REWARDS CALCULATION
    //////////////////////////////////////////////////////////////*/

    /// @notice The total amount of fees generated by the sudoswap pool.
    uint256 public totalFeesGenerated;

    /// @notice Mapping of radcat id to the amount of fees claimed.
    mapping(uint256 => uint256) public radcatRewardsClaimed;

    /// @notice The address of the sudoswap pair
    LSSVMPairMissingEnumerableERC20 public pair;

    /*//////////////////////////////////////////////////////////////
                            BONDING CURVES
    //////////////////////////////////////////////////////////////*/

    /// @notice The ETH bonding curve state
    RadcatCurve.RadCurve public ethCurve;

    /// @notice The public RAD bonding curve state
    RadcatCurve.RadCurve public radCurve;

    /// @notice The public RAD bonding curve state
    RadcatCurve.RadCurve public broCurve;

    /*//////////////////////////////////////////////////////////////
                                 TOKEN URI
    //////////////////////////////////////////////////////////////*/

    /// @notice Base token URI used as a prefix by tokenURI().
    string public baseURI;

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a user claims $RAD rewards.
    event RadwardClaimed(uint256[] ids, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                 MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Only the operator can call this function.
    modifier onlyOperator() {
        require(msg.sender == operator || msg.sender == owner(), "Radcat: caller is not the operator");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Initialize Radcats.
    function initialize(
        RadcatCurve.RadCurve memory _ethCurve,
        RadcatCurve.RadCurve memory _radCurve,
        RadcatCurve.RadCurve memory _broCurve
    ) external initializerERC721A initializer {
        __ERC721A_init("Radbro Webring: Radcats", "RADCATS");
        __ERC721AQueryable_init();
        __ReentrancyGuard_init();
        __RadlistV2_init();

        beneficiary = msg.sender;
        operator = msg.sender;

        ethCurve = _ethCurve;
        radCurve = _radCurve;
        broCurve = _broCurve;

        protocolFeeBips = 100;
    }

    /*//////////////////////////////////////////////////////////////
                               ADMIN
    //////////////////////////////////////////////////////////////*/

    /// @notice Set the operator address.
    /// @dev Ownership and Operatorship are designed to be revoked for the contract, for full decentralization.
    /// @dev The operator is the only address that can manage the admin functions, other than the owner.
    /// @dev The operator can be set to the zero address, to disable admin functions.
    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    /// @notice Set the beneficiary address.
    function setBeneficiary(address _beneficiary) external onlyOperator {
        beneficiary = _beneficiary;
    }

    /// @notice Set the sudo pair address.
    function setSudoPair(address _pair) external onlyOperator {
        pair = LSSVMPairMissingEnumerableERC20(_pair);
    }

    /// @notice Set the ETH bonding curve config.
    function setETHCurve(RadcatCurve.RadCurve calldata _ethCurve) external onlyOperator {
        ethCurve = _ethCurve;
    }

    /// @notice Set the RAD bonding curve config.
    function setRADCurve(RadcatCurve.RadCurve calldata _radCurve) external onlyOperator {
        radCurve = _radCurve;
    }

    /// @notice Set the BRO bonding curve config.
    function setBROCurve(RadcatCurve.RadCurve calldata _broCurve) external onlyOperator {
        broCurve = _broCurve;
    }

    /// @notice Enables or disables ETH minting.
    function setETHMintingEnabled(bool _mintingEnabled) external onlyOperator {
        ethMintsEnabled = _mintingEnabled;
    }

    /// @notice Enables or disables RAD minting.
    function setRADMintingEnabled(bool _mintingEnabled) external onlyOperator {
        radMintsEnabled = _mintingEnabled;
    }

    /// @notice Enables or disables BRO minting.
    function setBROMintingEnabled(bool _mintingEnabled) external onlyOperator {
        broMintsEnabled = _mintingEnabled;
    }

    /// @notice Enables or disables radlist minting.
    function setRadlistMintingEnabled(bool _mintingEnabled) external onlyOperator {
        radlistMintsEnabled = _mintingEnabled;
    }

    /// @notice Change the protocol fee.
    function setProtocolFee(uint256 _protocolFeeBips) external onlyOperator {
        protocolFeeBips = _protocolFeeBips;
    }

    /// @notice Change the base token uri.
    function setBaseURI(string calldata _uri) external onlyOperator {
        baseURI = _uri;
    }

    /// @notice pull all ETH from the contract.
    function pullETH() external onlyOperator {
        // pull all ETH
        payable(operator).transfer(address(this).balance);
    }

    /// @notice pull the given amount of RAD from the contract.
    function pullRAD(uint256 amount) external onlyOperator {
        // pull all RAD
        radcoinV2.transfer(operator, amount);
    }

    /// @notice pull all BRO from the contract.
    function pullBRO() external onlyOperator {
        // pull all BRO
        brocoin.transfer(operator, brocoin.balanceOf(address(this)));
    }

    /*//////////////////////////////////////////////////////////////
                               ADDING LIQUIDITY
    //////////////////////////////////////////////////////////////*/

    /// @notice Mints Radcats and deposits $RAD to the sudo pair to provide trading liquidity.
    function addLiquidity(uint256 numRadcats, uint256 amountRad) external onlyOperator {
        // update pair reserves
        uint128 _radReserves = pair.spotPrice();
        uint128 _catReserves = pair.delta();
        pair.changeSpotPrice(uint128(_radReserves + amountRad));
        pair.changeDelta(uint128(_catReserves + numRadcats));

        // mint radcats to sudo pair
        _mintInternal(address(pair), numRadcats);
        // transfer rad to sudo pair from the caller
        radcoinV2.safeTransferFrom(msg.sender, address(pair), amountRad);
    }

    /*//////////////////////////////////////////////////////////////
                               MINTING
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint using ETH.
    /// @param to The address to mint to.
    /// @param n The number to mint.
    function mintFromETH(address to, uint256 n) external payable nonReentrant {
        require(ethMintsEnabled, "Radcat: ETH minting is disabled");

        (uint128 newSpotPrice, uint256 inputValue) = ethCurve.getBuyInfo(n);
        require(msg.value >= inputValue, "Radcat: Insufficient ETH sent for mint");

        ethCurve.spotPrice = newSpotPrice;
        ethCurve.lastUpdate = block.timestamp;

        // refund any extra ETH sent
        if (msg.value > inputValue) {
            payable(msg.sender).transfer(msg.value - inputValue);
        }

        _mintInternal(to, n);
    }

    /// @notice Mint using $RAD.
    /// @param to The address to mint to.
    /// @param n The number to mint.
    function mintFromRAD(address to, uint256 n, uint256 maxInput) external nonReentrant {
        require(radMintsEnabled, "Radcat: RAD minting is disabled");

        (uint128 newSpotPrice, uint256 inputValue) = radCurve.getBuyInfo(n);
        require(inputValue <= maxInput, "Radcat: Required input amount exceeds max input");

        radcoinV2.transferFrom(msg.sender, beneficiary, inputValue);

        radCurve.spotPrice = newSpotPrice;
        radCurve.lastUpdate = block.timestamp;

        _mintInternal(to, n);
    }

    /// @notice Mint using $BRO.
    /// @param to The address to mint to.
    /// @param n The number to mint.
    function mintFromBRO(address to, uint256 n, uint256 maxInput) external nonReentrant {
        require(broMintsEnabled, "Radcat: BRO minting is disabled");

        (uint128 newSpotPrice, uint256 inputValue) = broCurve.getBuyInfo(n);
        require(inputValue <= maxInput, "Radcat: Required input amount exceeds max input");

        brocoin.safeTransferFrom(msg.sender, beneficiary, inputValue);

        broCurve.spotPrice = newSpotPrice;
        broCurve.lastUpdate = block.timestamp;

        _mintInternal(to, n);
    }

    /**
    @notice Mint free Radcats (requires radlist).
     */
    function mintRadlist(address to, uint32 amount, bytes32[] calldata radlistProof) external nonReentrant {
        require(radlistMintsEnabled, "Radcat: Radlist Minting is disabled");
        unchecked {
            require(
                mintedFromRadlist + amount <= MAX_RADLIST_MINTS,
                "Radcat: max radlist mints reached. Check the chain!!"
            );
        }

        require(
            this.verifyMerkleProof(0, amount, msg.sender, radlistProof),
            "Radcat: Not on the radlist. Check the chain!!"
        );

        require(!radlistMintsClaimed[msg.sender], "Radcat: Already claimed all your radlist mints");

        radlistMintsClaimed[msg.sender] = true;

        unchecked {
            mintedFromRadlist += amount;
        }

        _mintInternal(to, amount);
    }

    /**
    @notice Mint free Radcats (devs only)
     */
    function mintDev(address to, uint32 amount) external onlyOperator {
        unchecked {
            require(mintedByDevs + amount <= MAX_DEV_MINTS, "Radcat: max dev mints reached. Check the chain!!");

            mintedByDevs += amount;
        }

        _mintInternal(to, amount);
    }

    function _mintInternal(address to, uint256 n) internal {
        require(n <= MAX_MINTS_PER_TX, "Radcat: Max mints per tx exceeded");
        unchecked {
            require(totalSupply() + n <= MAX_SUPPLY, "Radcat: Max supply reached");
        }
        _safeMint(to, n);
    }

    // override start token id to 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /*//////////////////////////////////////////////////////////////
                               CLAIMING
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Skims the fees from the sudoswap pool and distributes them to fee stakers.
     */
    function skim() public returns (uint256) {
        // skim the fees
        uint256 tokenReserves = pair.spotPrice();
        uint256 fees = radcoinV2.balanceOf(address(pair)) > tokenReserves
            ? radcoinV2.balanceOf(address(pair)) - tokenReserves
            : 0;

        // distribute the fees to stakers
        if (fees == 0) {
            return 0;
        }

        totalFeesGenerated += fees;
        pair.withdrawERC20(radcoinV2, fees);

        return fees;
    }

    /**
     * @notice Redeems fees for a set of radcats owned by the caller.
     * @param tokenIds The tokenIds of the radcats for which to redeem fees.
     */
    function feeRedeem(uint256[] calldata tokenIds) public nonReentrant returns (uint256 rewardAmount) {
        // update the rewards for everyone
        skim();

        for (uint256 i = 0; i < tokenIds.length; ) {
            // calculate add the reward amount for each token
            uint256 tokenId = tokenIds[i];

            // check that the user owns the token
            require(
                msg.sender == ownerOf(tokenId) || isApprovedForAll(ownerOf(tokenId), msg.sender),
                "Not owner or approved"
            );

            // add the reward amount for the token
            uint256 tokenReward = feeEarned(tokenId);

            unchecked {
                // update the claimed checkpoint
                radcatRewardsClaimed[tokenId] += tokenReward;
                rewardAmount += tokenReward;
                i++;
            }
        }

        // apply the protocol fee
        uint256 _protocolFeeBips = protocolFeeBips;
        if (_protocolFeeBips > 0) {
            uint256 protocolFee = (rewardAmount * _protocolFeeBips) / BIPS_DIVISOR;
            // transfer the protocol fee
            radcoinV2.transfer(msg.sender, protocolFee);
            // adjust the reward amount
            rewardAmount -= protocolFee;
        }

        // transfer the reward
        radcoinV2.transfer(msg.sender, rewardAmount);

        emit RadwardClaimed(tokenIds, rewardAmount);
    }

    /**
     * @notice Calculates how much unclaimed reward a radcat has earned.
     * @param tokenId The tokenId for which to fetch.
     * @return earned the amount of the reward.
     */
    function feeEarned(uint256 tokenId) public view returns (uint256 earned) {
        uint256 rewardsPerRadcat = totalFeesGenerated / MAX_SUPPLY;
        uint256 totalClaimed = radcatRewardsClaimed[tokenId];

        return rewardsPerRadcat - totalClaimed;
    }

    /**
     * @notice Calculates how much total unclaimed reward a set of radcats have earned.
     * @param tokenIds The tokenIds for which to fetch.
     * @return earned the amount of the reward.
     */
    function totalFeesEarned(uint256[] calldata tokenIds) external view returns (uint256 earned) {
        for (uint256 i = 0; i < tokenIds.length; ) {
            earned += feeEarned(tokenIds[i]);

            unchecked {
                i++;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                               GETTING PRICES
    //////////////////////////////////////////////////////////////*/

    /// @notice get the purchase price for n ETH mints.
    /// @param numItems the number of items to purchase
    /// @return inputValue the amount of $RAD to send to purchase the items
    function getPriceETH(uint256 numItems) external view returns (uint256 inputValue) {
        (, inputValue) = ethCurve.getBuyInfo(numItems);
    }

    /// @notice get the purchase price for n $RAD mints.
    /// @param numItems the number of items to purchase
    /// @return inputValue the amount of $RAD to send to purchase the items
    function getPriceRAD(uint256 numItems) external view returns (uint256 inputValue) {
        (, inputValue) = radCurve.getBuyInfo(numItems);
    }

    /// @notice get the purchase price for n $BRO mints.
    /// @param numItems the number of items to purchase
    /// @return inputValue the amount of $BRO to send to purchase the items
    function getPriceBRO(uint256 numItems) external view returns (uint256 inputValue) {
        (, inputValue) = broCurve.getBuyInfo(numItems);
    }

    /*//////////////////////////////////////////////////////////////
                               OVERRIDEN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(
        uint256 tokenId
    ) public view override(IERC721AUpgradeable, ERC721AUpgradeable) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : "";
    }

    /// @notice Overrides supportsInterface as required by inheritance.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC721AUpgradeable, ERC721AUpgradeable) returns (bool) {
        return ERC721AUpgradeable.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                               OS ROYALTIES
    //////////////////////////////////////////////////////////////*/
    function setApprovalForAll(
        address _operator,
        bool approved
    ) public override(IERC721AUpgradeable, ERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(_operator, approved);
    }

    function approve(
        address approved,
        uint256 tokenId
    ) public payable override(IERC721AUpgradeable, ERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
        super.approve(approved, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721AUpgradeable, ERC721AUpgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721AUpgradeable, ERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721AUpgradeable, ERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}