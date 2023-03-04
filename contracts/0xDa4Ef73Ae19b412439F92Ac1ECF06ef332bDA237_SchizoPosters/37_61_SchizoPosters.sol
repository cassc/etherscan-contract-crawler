// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

/*

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&####BB#####&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BGPYJ?777!!7!!!!!!!!77??JY5GB#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BPYJ?77JJJJY5YPY5BBG55JJJJJJJJ??7777?J5G#&@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@&#G5J?7?JJ555GGBBBBP5J?JJ?YGYJ???JJ5555Y?!JJ?77?JP#@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&BPYYJJP5JYJ?PB??JY5YY5PPJ!JY?PG7~~~~~!Y5PPYJPPP55YJ??J5#@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@&#G5YJJYYYGBGGY?Y5?!JGPPJJ5Y?!!?J7YPYJ?JJ55??5GBGPGGGP5??YJ?JG&@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&BP55PJJ???JPGGGGPY?7!JBGY77~!777J##B55PGGPJ777?5PY?J5PGPYPGPP5JJP&@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@&BP555P#BGPPPP5YJJJJ??5Y5YJJ????J55PJJ?BB#[email protected]@@@@@@@@@@@@
@@@@@@@@@@@@@@@&#GP5YYYYB#G55PP5J???JJJ5G5??5YB&##BPJ?JJJ5JY?JJ??5P?7!!7777J7!YBGGGGGPY5&@@@@@@@@@@@
@@@@@@@@@@@@@@&BGPPB5555G5????YYJJ5J?7JY?7?7?J5BBG5JJ777JPPJ~~~!!!Y?7!77???Y5PP5GP5YY5G55&@@@@@@@@@@
@@@@@@@@@@@@@&BGPPGB##BBB#BBBGP5JYP5YY55J7JJ?J?YJ5BBG?7?JYYGPYJJYPB#BGPGG7J5BB5775PGG55BP5&@@@@@@@@@
@@@@@@@@@@@@&BPPPYP5PGPP5PGGG5PG55GGPGPYJYY5YJ???J55YY??JY5GB#BP?75B####57?J557~.PGGB#GBGYY#@@@@@@@@
@@@@@@@@@@@&G5PP555555Y5P5YYYJPB######G#BBG5YGPGG5J?Y5?777JG###5YY5PB#GP?YPPY??!.?BPB#&[email protected]@@@@@@
@@@@@@@@#P5YYP5G55P5555PBG5Y5PGB#&&&&##&#GPJ?YPYJJYJY?77!!?YPGBGP5PPJ!J?!7JJ?777.7GP&&#[email protected]@@@@
@@@@@@@@GYY555PGP555YYYP###BP5JYGBBBBBBBG5YJ?7!!~JBBP!JBPG5?J5GBBBGG5?J7?~~?!!77^?BG#B#&#[email protected]@@@
@@@@@@@###GGB5Y5GGP55555YYBPJ?JYPPPGGPPP555Y?!!!7???J?JGGPJ77J5PPP5Y57~~~~JY77?J5BGB&&&#BGGBB5G5#@@@
@@@@@@@BGPP#&#BG5YPGGGP5YYG#BGBGJY5YYJPGP5P5J77!~~~7??J!!!!!77?YYJ7!!^^!?YYY5GB#BB#&#######B5P&PY&@@
@@@@@&#PJJJYG##&#GPB##GPPP5Y5P5JJJJJJJJJ7!??~^^^^^^::^7J~7~~7~?Y?!^!J5PGPGPPGGGGBBB####BBGGB&@#[email protected]@
@@@@&GGGP55PGBGGGPPGBB#G5B&BPYJ????7??7?7~!JJJ!~^^~!?J?!^^!~~~???PGPGB55PPGGGGPPPGBBBGGGB&@@&GG#[email protected]@
@@@@&GB##GPGBBGBBPGGP#&&##B#BBG5J?J~~~^^^^^^~!?J??7!~^:^?55Y5PPGPP5555PGGGGBB###BBB##BBBBBB###&G5&@@
@@@@@&GGGGGGBBB#BG&@BB&&BPG###BBBB[email protected]@@
@@@@@&#BP5PBBBBBBGBB#GBBP#&&##BBB##BGGBB#&#[email protected]@@
@@@&@&GB###B####BBBBBBBPGBBBGGB######[email protected]&J?5PY???????J??7JYJ5J~JP7!?GP!7775Y5PGGB#@@@@@
@@&G#&BB####&&&&&#BGPGGP###&&&&&###BBBBBBBPY5PPPPB##&BYJB#Y777777777???755?J5P55GP7~~~~!J&@@@@@@@@@@
@@@BPGGB###&&&&&#GPGGP5GB#BBBB#####G5JP5777JG5?J5PPPY?7Y5J??77777777777!!G&@#[email protected]@@@&[email protected]@@@@@@@@@@
@@@@BBBB####BGBBBGGP5YY5B&&#BGG##&B7~YBG!^7J5YJJJ7~!PBY7777!!!!~~~~~~~~^P&G??G#P##&@[email protected]@@@@@@@@@@
@@@@#BBBGBBGBBB#PYGGPGGB###BB#&&GB7^!!!~?#@&&&&&&&B55Y!~~~^^^^^^^^^~~~~7&@#[email protected]@@@@@@@@@@
@@@@@BGGPBPY5BBPGPGBBBGGBBBBBGB##Y~~^^[email protected]@&G777!Y#&@@&5^^^^^^^^^^^~~~~^[email protected]&B5GGG5BPB7~#[email protected]@@@@@@@@@@
@@@@@&BGGB##GGBB#&PPPGBBGP5JJYG#[email protected]&BP5Y55555&&@@&!^^^^^^^^^^~~~~~7&&#B##5JP&#!~7!!!#@@@@@@@@@@
@@@@@@@@&GB##BGGPPP555Y?7!!7?JYG7~~~~7P!PGGY5GGPYJG#&#&J^^^^^^^^^^~~~~~~G&@@&#&GJ#P~:~!~?&@@@@@@@@@@
@@@@@&B&#JYPGGBGGY?7!~~!7!7???YJ~~~^^!^~555J5GPP5J7J#G#?^^^~~~~~^^~~~~~~!YPBBGY?YJ!~~!~~#@@@@@@@@@@@
@@@@@@&#BG5YJYY7YY5?!~!?7!7???J7~~^^^^^^!!PPY77!!7P!?&G~^^^~~~~~~~~~!~~~~^[email protected]@@@@@@@@@@@
@@@@@@@@@@B5Y757?J?!~^~!!~!777J7~~~^^^^^^~5GGPY5PPBBBP~^^^^^[email protected]@@@@@@@@@@@@
@@@@@@@@@@@5PGBP?!!~^:^~!~~!77J7~~~^^^^^^^^^!775BGP57^^^^^^^^^^^^^^^^[email protected]@@@@@@@@@@@@@
@@@@@@@@@@@#YPGBG5?7!^^~~^:^~!777~~~~^^^^^^^~777!~^^^^^^^^^^^^^^^^^^^^[email protected]@@@@@@@@@@@@@@
@@@@@@@@@@@@BJ5GGGGGGP5J7!!!!!!!??!~~~^^^^^^^^^^^^^^^^^^^^^^^^^~~~~~~~^[email protected]@@@@@@@@@@@@@@
@@@@@@@@@@@@@#JYPGGGGBGBBBBBP55YYYJ?7!~~~~^^^^^^^^^^^^^^^^^^^^^~!!!~~~^[email protected]@@@@@@@@@@@@@@
@@@@@@@@@@@@@@&5J5GGGGGB&#&&#####BGP5J?!!~~~~^~~^^^^^~~~~~~~^^^^^^^^^^[email protected]@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@#YJPPGPG&##&&#[email protected]@#@##BG5J7!~^~^^^^^~~^~~~~~~^^^^^^^^~~~~~~~!?5#GGBPG&@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@#GPPPPG#&&&&#&&#@&B#@&##PJYGY!~^^^^~^~~~~~~~~~~~~~~~~~!JPBBGB##B#@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@&##G5PGB#&&&#&&[email protected]&#&@@@@@@@#5Y?!~!~~~~~~~~?!~~?J?YB#&##BGBBB&@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@&##GGGBB###&&#&@@@@@@@@@@@@P5?7!77!777JJ5#&@@@@@&#B#GPG&@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#BGGB###@@@@@#[email protected]@&@BPP5YY5Y55YGBYG5&@&##@@@@##BGPG&@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@[email protected]@BBB5YYJJYYYY5PGPGP#&#[email protected]@@##BGGG&@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@G!#&#BG5Y5YJJJYYYYYYY5PPGBGPP#&###[email protected]@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@GGGBB&B7YPPJJYYYYJJJJJJJJJY?7?J55G#&#GG##[email protected]@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##GGGGB##P?J?^!JJ??????JYY5P5J7~~!7J5GB5GB#[email protected]@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#GB##BBGGB##P?^.:?J?JY5GPGGBPBPP5?~::^?5PY?PB#B#@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@GGBBB###BGGB#B?: .JGGGB#BBB#GBG5GBPY!!P#[email protected]@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#PGBBBGGGBBBGGG?: .YBBBBB#####BGG#[email protected]@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&PPPP5PB#BB##BGG7. :YG#####&&&&#B#PPGBPGY?YJ5?:^[email protected]@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BJ5GGGB#BBB##PGP~. ~PB5G#&&#&&####[email protected]@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@PGGBGBBGB###GGGY^..?7:~JYY~5#J^~B###G#BJ!JBG5Y5&@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G5GPPGGGBBGB###BGGGJ!^!J7~~!^:^?J~!PBPB#&#[email protected]@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G55PGPGBGGB###BGGGP5Y?5PPJ777~~777YY7?G#[email protected]@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#PP55PPPGGPGB####BBGGP5YYPGGPY?YJ7!?Y7J5GGJ5P5PGY?JJ&@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&P55555PGGGPGB##&&[email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P555555PGGGPGB##&&#[email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B55P55PPGGGPGB##&&@BGGJJJY555YYP??YGPJJ?YYJYJ7!JJYJJYY&@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&55P55PPGGGPGB###&@&[email protected]@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@GPP5PPPGGPPGB###&@@#PYY55PGGYGPYY5GPYJYGG5YYYJ5YJYJYYY#@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BPP5PPGGGPPGB###&@@#[email protected]@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#PPPPPGGGPPGB###&@&P5PPGB#PJJYGG5YY5P5YYY5PYJYJ5JJY555Y&@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BGPPPGGGGPPGBB##&@P5PPG##PJJJYGG55Y5PP5YYJYPYJYYJY55555&@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@GGBPPPGGGGPPGBB#&#P5PPGBBYJJJJYGG55Y5P5YYYYJ5YJYJYPPPP55&@@@@@@@@@@@@@
*/

import {
    ERC721AQueryableUpgradeable
} from "lib/ERC721A-Upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import { IERC721AUpgradeable } from "lib/ERC721A-Upgradeable/contracts/IERC721AUpgradeable.sol";
import { ERC721AUpgradeable } from "lib/ERC721A-Upgradeable/contracts/ERC721AUpgradeable.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeTransferLib } from "lib/solmate/src/utils/SafeTransferLib.sol";

import { SignatureVerifier } from "../utils/SignatureVerifier.sol";
import { RadcoinV2 } from "../RadcoinV2.sol";
import { RadlistV2 } from "../RadlistV2.sol";
import { RadLinearCurve } from "../RadLinearCurve.sol";

/// @dev Provides Randomness for prizes.
interface IRandomness {
    function getRandSeed(uint256 _modulus) external view returns (uint256);
}

/// @notice SchizoPosters.
/// @author 10xdegen
contract SchizoPosters is ERC721AQueryableUpgradeable, RadlistV2, ReentrancyGuardUpgradeable {
    using RadLinearCurve for RadLinearCurve.RadCurve;

    /*//////////////////////////////////////////////////////////////
                            TYPES
    //////////////////////////////////////////////////////////////*/

    /// @notice Parameters for minting.
    struct MintParams {
        /// @notice Max number mintable from reserve.
        uint256 maxReserveMints;
        /// @notice Max number mintable from radlist.
        uint256 maxRadlistMints;
        /// @notice Max number mintable from prizes.
        uint256 maxPrizeMints;
        /// @notice Max number mintable from prizes.
        /// @dev 1000 BP = 100 %; 100 = 10%
        uint256 prizePercentChance;
    }

    /*//////////////////////////////////////////////////////////////
                            MINT CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum number of mintable schizos.
    uint256 public constant MAX_SUPPLY = 5555;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the Radcoin V2 ERC20 token contract.
    RadcoinV2 public constant radcoinV2 = RadcoinV2(0xdDc6625FEcA10438857DD8660C021Cd1088806FB);

    /// @notice The address of the operator.
    address public operator;

    /// @notice The address of the beneficiary.
    address public beneficiary;

    /// @notice The address of the Randomness contract.
    IRandomness public randomness;

    /*//////////////////////////////////////////////////////////////
                            MINTING
    //////////////////////////////////////////////////////////////*/

    /// @notice The mint parameters.
    MintParams public mintParams;

    /// @notice Total number minted via Radlist.
    uint256 public mintedFromRadlist;

    /// @notice Total number won as prizes for ETH mints.
    uint256 public mintedAsPrizes;

    /// @notice Total number minted from the dev reserve.
    uint256 public mintedFromReserve;

    /// @notice Enables ETH mints.
    bool public ethMintsEnabled;

    /// @notice Enables prize mints.
    bool public prizesEnabled;

    /// @notice Enables RAD mints.
    bool public radMintsEnabled;

    /// @notice Enables radlist mints.
    bool public radlistMintsEnabled;

    /*//////////////////////////////////////////////////////////////
                            BONDING CURVES
    //////////////////////////////////////////////////////////////*/

    /// @notice The ETH bonding curve state
    RadLinearCurve.RadCurve public ethCurve;

    /// @notice The public RAD bonding curve state
    RadLinearCurve.RadCurve public radCurve;

    /*//////////////////////////////////////////////////////////////
                            RADLIST MINTED
    //////////////////////////////////////////////////////////////*/

    /// @notice addresses that claimed a radlist mint
    mapping(address => uint32) public radlistMintsClaimed;

    /*//////////////////////////////////////////////////////////////
                                 METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Base token URI used as a prefix by tokenURI().
    string public withOverlayTokenURI;

    /// @notice Base token URI used as a prefix by tokenURI().
    string public withoutOverlayTokenURI;

    /// @notice Token ids that have toggled their overlay disabled.
    mapping(uint256 => bool) public overlayDisabled;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event SchizoMintedETH(address indexed user, uint32 quantity);
    event SchizoMintedRAD(address indexed user, uint32 quantity);
    event SchizoMintedRadlist(address indexed user, uint32 quantity);
    event SchizoMintedReserve(address indexed receiver, uint32 quantity);
    event WonFreeSchizo(address indexed user, uint256 id);

    /*//////////////////////////////////////////////////////////////
                                 MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Only the operator can call this function.
    modifier onlyOperator() {
        require(msg.sender == operator || msg.sender == owner(), "Schizo: caller is not the operator");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               INITIALIZER
    //////////////////////////////////////////////////////////////*/

    /// @notice Initialize Schizo Webring.
    function initialize(
        address _operator,
        address _beneficiary,
        address _randProvider,
        RadLinearCurve.RadCurve calldata _ethCurve,
        RadLinearCurve.RadCurve calldata _radCurve,
        string calldata _withoutOverlayTokenURI,
        string calldata _withOverlayTokenURI,
        MintParams calldata _mintParams
    ) external initializerERC721A initializer {
        __ERC721A_init("SchizoPosters", "SCHIZO");
        __ERC721AQueryable_init();
        __ReentrancyGuard_init();
        __RadlistV2_init();

        operator = _operator;
        beneficiary = _beneficiary;
        operator = _operator;
        randomness = IRandomness(_randProvider);

        ethCurve = _ethCurve;
        radCurve = _radCurve;

        withoutOverlayTokenURI = _withoutOverlayTokenURI;
        withOverlayTokenURI = _withOverlayTokenURI;

        mintParams = _mintParams;
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

    /// @notice Set the address of the Randomness contract.
    function setRandProvider(address _randProvider) external onlyOperator {
        randomness = IRandomness(_randProvider);
    }

    /// @notice Set the beneficiary address.
    function setBeneficiary(address _beneficiary) external onlyOperator {
        beneficiary = _beneficiary;
    }

    /// @notice Set the ETH bonding curve config.
    function setETHCurve(RadLinearCurve.RadCurve calldata _ethCurve) external onlyOperator {
        ethCurve = _ethCurve;
    }

    /// @notice Set the RAD bonding curve config.
    function setRADCurve(RadLinearCurve.RadCurve calldata _radCurve) external onlyOperator {
        radCurve = _radCurve;
    }

    /// @notice Enables or disables ETH minting.
    function setETHMintingEnabled(bool _mintingEnabled) external onlyOperator {
        ethMintsEnabled = _mintingEnabled;
    }

    /// @notice Enables or disables RAD minting.
    function setRADMintingEnabled(bool _mintingEnabled) external onlyOperator {
        radMintsEnabled = _mintingEnabled;
    }

    /// @notice Enables or disables prize minting.
    function setPrizeMintingEnabled(bool _mintingEnabled) external onlyOperator {
        prizesEnabled = _mintingEnabled;
    }

    /// @notice Enables or disables radlist minting.
    function setRadlistMintingEnabled(bool _mintingEnabled) external onlyOperator {
        radlistMintsEnabled = _mintingEnabled;
    }

    /// @notice Sets the base token URI prefix (with overlay).
    function setWithOverlayTokenURI(string calldata _withOverlayTokenURI) external onlyOperator {
        withOverlayTokenURI = _withOverlayTokenURI;
    }

    /// @notice Sets the base token URI prefix (without overlay).
    function setWithoutOverlayTokenURI(string calldata _withoutOverlayTokenURI) external onlyOperator {
        withoutOverlayTokenURI = _withoutOverlayTokenURI;
    }

    /// @notice Set the max reserve mints.
    function setMaxReserveMints(uint32 _maxReserveMints) external onlyOperator {
        mintParams.maxReserveMints = _maxReserveMints;
    }

    /// @notice Set the max radlist mints.
    function setMaxRadlistMints(uint32 _maxRadlistMints) external onlyOperator {
        mintParams.maxRadlistMints = _maxRadlistMints;
    }

    /// @notice Set the max prize mints.
    function setMaxPrizeMints(uint32 _maxPrizeMints) external onlyOperator {
        mintParams.maxPrizeMints = _maxPrizeMints;
    }

    /// @notice Set the prize percent chance.
    function setPrizePercentChance(uint256 _prizePercentChance) external onlyOperator {
        mintParams.prizePercentChance = _prizePercentChance;
    }

    /// @notice pull ETH from the contract.
    function pullETH() external onlyOperator {
        payable(operator).transfer(address(this).balance);
    }

    /*//////////////////////////////////////////////////////////////
                               FLIP A COIN (schizophrenically)
    //////////////////////////////////////////////////////////////*/
    /// @notice See if N number of flips of a coin will win.
    /// @param _numTries The number of times to try flip.
    /// @param _percentChance The percent chance to win the flip.
    /// @return _won Whether or not the flip was won.
    function _flipCoin(uint256 _numTries, uint256 _percentChance) internal view returns (bool _won) {
        uint256 rand = randomness.getRandSeed(1000);

        _won = rand < _percentChance * _numTries;
    }

    /*//////////////////////////////////////////////////////////////
                               RADCOIN MINTING
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint as a member of the public (using ETH).
    /// @param to The address to mint to.
    /// @param n The number to mint.
    function mintFromETH(address to, uint256 n) external payable nonReentrant {
        require(ethMintsEnabled, "Schizo: ETH minting is disabled");

        (uint128 newSpotPrice, uint256 inputValue) = ethCurve.getBuyInfo(n);
        require(msg.value >= inputValue, "Schizo: Insufficient ETH sent for mint");

        ethCurve.spotPrice = newSpotPrice;
        ethCurve.lastUpdate = block.timestamp;

        // flip a coin to see if we get a freebie
        if (prizesEnabled && mintedAsPrizes < mintParams.maxPrizeMints && _flipCoin(n, mintParams.prizePercentChance)) {
            unchecked {
                mintedAsPrizes += 1;
                n += 1;
                emit WonFreeSchizo(to, totalSupply() + n);
            }
        }

        // transfer ETH to the beneficiary
        payable(beneficiary).transfer(inputValue);

        // refund any extra ETH sent
        if (msg.value > inputValue) {
            payable(msg.sender).transfer(msg.value - inputValue);
        }

        _mintInternal(to, n);

        emit SchizoMintedETH(msg.sender, uint32(n));
    }

    /// @notice Mint as a member of the public (using $RAD).
    /// @param to The address to mint to.
    /// @param n The number to mint.
    function mintFromRAD(address to, uint256 n, uint256 maxInput) external nonReentrant {
        require(radMintsEnabled, "Schizo: RAD minting is disabled");

        (uint128 newSpotPrice, uint256 inputValue) = radCurve.getBuyInfo(n);
        require(inputValue <= maxInput, "Schizo: Required input amount exceeds max input");

        radcoinV2.transferFrom(msg.sender, beneficiary, inputValue);

        radCurve.spotPrice = newSpotPrice;
        radCurve.lastUpdate = block.timestamp;

        _mintInternal(to, n);

        emit SchizoMintedETH(msg.sender, uint32(n));
    }

    /**
    @notice Mint free Schizos (requires radlist).
     */
    function mintRadlist(
        address to,
        uint32 amount,
        uint32 slots,
        bytes32[] calldata radlistProof
    ) external nonReentrant {
        require(radlistMintsEnabled, "Schizo: Radlist Minting is disabled");
        unchecked {
            require(
                mintedFromRadlist + amount <= mintParams.maxRadlistMints,
                "Schizo: max radlist mints reached. Check the chain!!"
            );
        }

        require(
            this.verifyMerkleProof(0, slots, msg.sender, radlistProof),
            "Schizo: Not on the radlist. Check the chain!!"
        );

        require(radlistMintsClaimed[msg.sender] + amount <= slots, "Schizo: Already claimed all your radlist mints");

        radlistMintsClaimed[msg.sender] += amount;

        unchecked {
            mintedFromRadlist += amount;
        }

        _mintInternal(to, amount);
    }

    /**
     * @dev Mint tokens reserved for the team.
     * @param to The address that will own the minted tokens.
     * @param n The number to mint.
     */
    function mintFromReserve(address to, uint256 n) external onlyOperator nonReentrant {
        require(mintedFromReserve + n <= mintParams.maxReserveMints, "Schizo: Max mintable from reserve reached");

        unchecked {
            mintedFromReserve += n;
        }

        _mintInternal(to, n);
    }

    function _mintInternal(address to, uint256 n) internal {
        unchecked {
            require(totalSupply() + n <= MAX_SUPPLY, "Schizo: Max supply reached");
        }
        _safeMint(to, n);
    }

    // override start token id to 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /*//////////////////////////////////////////////////////////////
                               TOGGLE OVERLAY
    //////////////////////////////////////////////////////////////*/

    /// @notice Disables (or enables) the overlay on a token.
    /// @param tokenId The token to toggle the overlay on.
    /// @param disabled Whether or not to disable the overlay.
    function disableOverlay(uint256 tokenId, bool disabled) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Schizo: caller is not owner");

        overlayDisabled[tokenId] = disabled;
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

    /// @notice get the purchase price for n radlist mints.
    /// @param numItems the number of items to purchase
    /// @return inputValue the amount of $RAD to send to purchase the items
    function getPriceRAD(uint256 numItems) external view returns (uint256 inputValue) {
        (, inputValue) = radCurve.getBuyInfo(numItems);
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

        string memory baseURI = overlayDisabled[tokenId] ? withoutOverlayTokenURI : withOverlayTokenURI;
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : "";
    }

    /// @notice Overrides supportsInterface as required by inheritance.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC721AUpgradeable, ERC721AUpgradeable) returns (bool) {
        return ERC721AUpgradeable.supportsInterface(interfaceId);
    }
}