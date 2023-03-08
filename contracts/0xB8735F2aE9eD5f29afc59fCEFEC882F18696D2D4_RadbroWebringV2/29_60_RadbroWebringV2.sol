// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

/*

╢╬╬╬╬╠╠╟╠╬╢╠╬╬╠╠╠╢╬╬╠╠╠╠╬╬╬╣▌▌▓▌▌▌▌▌▌╬╬▓▓▓▓▓▓▌▓▓▓▓▒░»=┐;»:»░»¡;":¡░¡!:░┐░░░░░!░░
╠╠╠╠╠╠╠╬╣╬╬╬╬╬╬╠╠╠╠╠╠╬╬▓████████████████████████████▌▄φφφφφφφφ╦▒φφ╦φ╦▒φ╦╦╦╦φφφφφ
▒╠▓╬▒▒▒▒▒▒▒▒╠╠╠╠╠╣╣╬▓██████████████████████████████████▓▓▌╬╟╬╢╠╟╠╠╠╠╠╟╟╠╠╠╠╠╠╠╠╠
▒╚▓╣▓▓▓▓╣╬▄▓▓▒▒╠▓▒▒▓███████████████████████████▓▓▓█▓█▓█▓▓█▓▓╬╠╠╟╠╠╠╠╢╠╠╠╠╠╬╢╠╠╠╠
▒Å▓▓▓▓▓▓█▓▓▓╬╫▌╠▓▓████████████████████▓▓████████▓█▓▓█▓▓▓▓█▓█▓▓╬╠╠╠╠╠╠╠╠╠╠╬╠╬╠╠╠╟
▒╚╚░▒╚╚╩╠╬╣▓╬╣▓╣▓███████████████▓█▓██████████████████▓█▓██▓█▓██▓╬╢╟╠╠╠╢╠╟╠╠╠╠╠╟╟
╟▒▒░░Γ▒╣▒▒░#▒▒╚▓████████████████▓██████▓████████████████████████▓╬╠╠╠╟╠╬╠╟╠╬╠╠╠╠
▒╠╠╩▒▒╟▓▓▓▓╣▓▓▓███████████████▓████████████▀╫███████████████████▓▓╬╠╠╠╠╠╠╠╠╠╬╠╠╠
▒▒▒Γ░Γ▒╬╬▀╬╣▓▓███████████████████████████▓╨░░╫████████████████████▓╬╠╠╠╠╠╠╠╠╠╠╠╠
▓▓▓▓▌╬╬╠╬▒▒▒▒████████████████████████████░¡░░!╫██████████▓╟██▓██████▌╠╠╠╠╠╠╠╠╠╠╠
███████████▓██████▓████████▀╫███████████▒∩¡░░░░╙▀▓╟████▌┤░░╫███▀▀███▌╠╠╠╠╠╠╠╠╠╠╠
███████████████████████████░╙███▌│╩╨╙██▌░░░░░░░░░░░██▓╝░░░Q▓███████▓╠╠╠╟╠╠╠╠╠╠╠╠
▓▓▓███████████████████████▌ü███▓▄▄Q░░██▒\░░░░¡░░░░░╫▓▌▓███████▀▀▀╫╬╠╠╬╠╠╟╟╠╠╠╠╠╟
╬▓╬╣╬╣╣╣╣╬▓╬████████████╩▀▒░▀▀▀▀▀▀▀███████▓▌▄µ░░░░░▀▀▀╫███████Γ░░╠╟╠╠╠╠╠╠╠╠╠╠╠╠╠
█▓▓▓▓▓▓▓▓▓▓▓▓███████████░░░░░░∩░░░Q▄▄▄▄░░░┘┤╨├░¡░░░░░▄███▄█████▒░╟╠╠╠╠╠╠╠╠╠╠╠╠╠╠
▓▓▓▓▓▓▓▓▓▓▓▓▓███████████▒░░░░░▓███▀█████▄░░░░░░░¡░░ΓΓ██████████┤Γ╬╠╠╠╠╠╬╠╠╠╠╠╠╠╠
╬╬╬╣╬╣╬╬╣╬╬╬╣▓███████████░░░▄█████████████▄░░░░░¡░░░░█████████δ░░▓╬╣╣▓▓▓▓▓▓╣╣▓▓▓
╬╬╬╬╣╬╣╬╬╬╬╬╬▓████▒░░∩░▀█▒░▀██╙█▓███████▓█▌░░¡░░░░░░░╚█████▓█▒░░╫▓████▓█▓▓▓▓▓▓▓▓
╬╣╬╢╬╬╣╬╣╬╬╬╣▓███▌░░░░░░░░░░░┤~╙█▓█████▀██▒░¡░░░░░░φ░░███▓██▒░░░▓▓▓╬╚╙╫╬╫███████
╬╬╣╬╬╬╣▓▓██▓╬▓███▓░░░░░░░░░░░░(=├▀██▓█████░░░¡░>░""░Γ░░░░░░Γ░░░╫▓▓▓▓▓▓▓█▓█▓▓▓▓▓▓
╬╫╬╬╬╬╣▓╬╟╬▓╬█████▓▄▒░░░░░░░░░∩░░│▀▀▀╫╨╨╨╨░░░¡░¡░░¡¡░░░░░░░░░░╢▓██▓▓█████████▓██
▓▓▓▓▓▓▓▓╬╬╫█████████████▓▌▒░░░░░░░░░░!░░░░¡░░░░Q▄▄▄▄▄░░░░Γ░Γ▄▓▓█████████████████
▓█████╬╣▓▓▓████████████████▓▌▒░░░░░░░░░░░░░░░░████▀▀░░░░░░▄▓▓▓██████████████████
▓▓▓╬▓▓╬╣╬╬╬╬╬╬╬╬███████████████▌▄▒░░░░░░░░░░░░░░░░░░░░½▄▓▓███▓██████████████████
▓╬╠▓▓▓▓╣╣╬╣╣╬╣▓╬████▓██████████████▓▓▌▄▄░░░░░░░░φ╦▄▄▓▓███████▓█████████████▓╠▓██
▓▌╠▓▓▓╬╬╣╬╬╬╬╬╬╬▓█▓████▓█▓╬╢▓██▓▓▓▓▓▓▓▓▓▒Σ▒▒#░#▓▓▓▓▓▓██████████████▓▓████▓▓▓╬╬╬╬
▓▓╠▓███▓▓╣╣╬╣╬╣╢▓▓▓▓▓▓██▓▓▓╣▓▓█▓▓█▓██▓╬#Γ#▒▒▒░Σ╣█████████████▓╣╬▓███▓████▓╣╣╬╣╣▓
▓▓╬▓▓▓▓▓▓▓▓▓▓█▓╬▓▓▓▓▓▓▓▓█████████████▄ΓΓ╚Γ░ΓΓΓ▐▄█████████████▓╬╬╬╫█████▓╬╬╣╬╬╬╬╬
▓▓▓▓▓▓▓▓▓▓▓█████████████████▓▓██████████▓▓▓▓▓████████████▓▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
▓███████████████████████████████████████████████████████╬╣╬╬╬╬╬╬╬╬╬╬╬╫╬╬╬╬╬╣╬╬╬╬
▓████████████████████████████████████████████████████████╬╬╬╬╫╬╬╬╬╬╣╬╬╬╬╬╬╬╬╣╬╬╬
██████████████████████████████████▓██▓█▓▓▓███▓██▓█████████╬╬╣╬╬╣╬╬╬╬╬╣╬╬╬╬╬╬╬╬╣╣
▓█████████████████▓▓▓▓╬╬╬██████████████████▓██▓██╣████████▓╬╬╫╬╢╬╫╬╬╬╬╬╣╬╣╬╬╬╣╬╣
██████▓█▓▓╬╬╬╬╬╬╬╬╬╬╣╬╬╬▓██████████▌▓╬▒╫▓▓▌╣██▓▓╬▒█████████▌╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣╬
╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣╬╬╬╬╬╬╣████████████╣╟▓╬╣▓▓▓▓▓▓▓▓▓╫█████████╬╬╬╬╬╣╬╬╬╬╬╬╬╬╬╣╬╬╬░


                          ;                                          
                          ED.                                  :     
                          E#Wi                                t#,    
 j.                       E###G.      .          j.          ;##W.   
 EW,                   .. E#fD#W;     Ef.        EW,        :#L:WE   
 E##j                 ;W, E#t t##L    E#Wi       E##j      .KG  ,#D  
 E###D.              j##, E#t  .E#K,  E#K#D:     E###D.    EE    ;#f 
 E#jG#W;            G###, E#t    j##f E#t,E#f.   E#jG#W;  f#.     t#i
 E#t t##f         :E####, E#t    :E#K:E#WEE##Wt  E#t t##f :#G     GK 
 E#t  :K#E:      ;W#DG##, E#t   t##L  E##Ei;;;;. E#t  :K#E:;#L   LW. 
 E#KDDDD###i    j###DW##, E#t .D#W;   E#DWWt     E#KDDDD###it#f f#:  
 E#f,t#Wi,,,   G##i,,G##, E#tiW#G.    E#t f#K;   E#f,t#Wi,,, f#D#;   
 E#t  ;#W:   :K#K:   L##, E#K##i      E#Dfff##E, E#t  ;#W:    G#t    
 DWi   ,KK: ;##D.    L##, E##D.       jLLLLLLLLL;DWi   ,KK:    t     
            ,,,      .,,  E#t                                        
                          L:                                         

*/

import {
    ERC721AQueryableUpgradeable
} from "lib/ERC721A-Upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import { ERC4907AUpgradeable } from "lib/ERC721A-Upgradeable/contracts/extensions/ERC4907AUpgradeable.sol";
import { IERC721AUpgradeable } from "lib/ERC721A-Upgradeable/contracts/IERC721AUpgradeable.sol";
import { ERC721AUpgradeable } from "lib/ERC721A-Upgradeable/contracts/ERC721AUpgradeable.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { ERC20 } from "lib/solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "lib/solmate/src/utils/SafeTransferLib.sol";
import { SignatureVerifier } from "./utils/SignatureVerifier.sol";
import { Radbro } from "./Radbro.sol";
import { Radcoin } from "./Radcoin.sol";
import { RadcoinV2 } from "./RadcoinV2.sol";
import { RadlistV2 } from "./RadlistV2.sol";
import { RadVRGDA } from "./RadVRGDA.sol";
import { RadLinearCurve } from "./RadLinearCurve.sol";

/// @dev Provides Randomness for Radbro Webring.
interface IRandomness {
    function getRandSeed(uint256 _modulus) external view returns (uint256);
}

/// @notice Radbro Webring.
/// @author 10xdegen
/// @dev This contract is the main entry point for the Radbro ecosystem.
/// It is responsible for minting new Radbro NFTs and claiming Radcoin.
/// Credit goes to the Radbro team StuxnetTypeBeat AEQEA GiverRod and 10xdegen. special thanks to dyddy.
contract RadbroWebringV2 is
    ERC721AQueryableUpgradeable,
    ERC4907AUpgradeable,
    RadlistV2,
    ReentrancyGuardUpgradeable,
    ERC721Holder,
    SignatureVerifier
{
    using RadVRGDA for RadVRGDA.RadCurve;
    using RadLinearCurve for RadLinearCurve.RadCurve;
    using SafeTransferLib for ERC20;

    /*//////////////////////////////////////////////////////////////
                            MINT TYPES
    //////////////////////////////////////////////////////////////*/

    /// @notice The state of the last mint by a radlist address.
    struct LastMint {
        uint256 timestamp;
        uint256 totalMinted;
    }

    /// @notice The parameters for upgrading from v1.
    struct UpgradeRadbroParams {
        address owner;
        uint256[] radbroIds;
        uint256 radcoinToClaim;
        uint256 radcoinToUpgrade;
        bool winABro;
        bool winSomeRad;
        uint256 nonce;
    }

    /*//////////////////////////////////////////////////////////////
                            MINT CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum number of mintable radbros.
    uint256 public constant MAX_SUPPLY = 5000;

    /// @notice The number of radbros reserved for upgrades from v1.
    uint256 public constant V1_UPRGADE_MINTS = 1635;

    /// @notice Maximum number of radbros that can be minted by the devs. (100)
    uint256 public constant RESERVE_MINTS = 200;

    /// @notice Maximum number of radbros that can be minted using $RAD.
    uint256 public constant PUBLIC_MINTABLE = MAX_SUPPLY - RESERVE_MINTS - V1_UPRGADE_MINTS;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the v1 Radbro contract.
    Radbro public constant radbroV1 = Radbro(0xE83C9F09B0992e4a34fAf125ed4FEdD3407c4a23);

    /// @notice The address of the v1 Radcoin contract.
    Radcoin public constant radcoinV1 = Radcoin(0x6AF36AdD4E2F6e8A9cB121450d59f6C30F3F3722);

    /// @notice The address of the Radcoin V2 ERC20 token contract.
    RadcoinV2 public radcoinV2;

    /// @notice The address of the RandProvider.
    IRandomness public randProvider;

    /// @notice The address of the operator.
    address public operator;

    /// @notice The address of the beneficiary.
    address public beneficiary;

    /*//////////////////////////////////////////////////////////////
                            UPGRADE MINTING
    //////////////////////////////////////////////////////////////*/

    /// @notice Total number of radbros (pre-)minted for v1 upgrades.
    uint256 public mintedForUpgrade;

    /// @notice Total number of radbros won as prizes for upgrading.
    uint256 public mintedPrizeRadbros;

    /*//////////////////////////////////////////////////////////////
                            RESERVE MINTING
    //////////////////////////////////////////////////////////////*/

    /// @notice Total number of radbros minted from the dev reserve.
    uint256 public mintedFromReserve;

    /*//////////////////////////////////////////////////////////////
                            MINTING
    //////////////////////////////////////////////////////////////*/

    /// @notice Enables public minting.
    bool public mintingEnabled;

    /*//////////////////////////////////////////////////////////////
                            ETH MINTING
    //////////////////////////////////////////////////////////////*/

    /// @notice The price of a radbro in ETH.
    uint256 public ethPrice;

    /// @notice Total number of radbros minted from ETH.
    uint256 public mintedfromETH;

    /*//////////////////////////////////////////////////////////////
                            RAD MINTING
    //////////////////////////////////////////////////////////////*/

    /// @notice The start time of the public $RAD mint.
    uint256 mintStartTime;

    /// @notice Total number of radbros minted from RAD.
    uint256 public mintedFromRAD;

    /// @notice The public bonding curve state
    RadVRGDA.RadCurve public publicCurve;

    /// @notice The radlist bonding curve state
    RadVRGDA.RadCurve public radlistCurve;

    /// @notice The last time each radlist address minted a radbro.
    /// @dev Only 1 radbro can be minted per radlist address per day.
    mapping(address => LastMint) public lastRadlistMint;

    /*//////////////////////////////////////////////////////////////
                            Generic ERC20 MINTING
    //////////////////////////////////////////////////////////////*/

    /// @notice mapping of accepted ERC20 tokens to their bonding curves.
    /// @dev This enables admins to add mints for arbitrary ERC20 tokens.
    /// @dev mints will be drawn from the mints reserved for RAD.
    mapping(IERC20 => RadVRGDA.RadCurve) public acceptedTokens;

    /*//////////////////////////////////////////////////////////////
                            FREE MINTING
    //////////////////////////////////////////////////////////////*/

    /// @notice addresses that claimed a free mint (from the giga-radlist)
    mapping(address => bool) public freeMinters;

    /*//////////////////////////////////////////////////////////////
                                 METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;

    /*//////////////////////////////////////////////////////////////
                                 SIGNATURES
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the upgrade signer.
    address public signer;

    /*//////////////////////////////////////////////////////////////
                            LINEAR BONDING CURVES
    //////////////////////////////////////////////////////////////*/

    /// @notice The ETH bonding curve state
    RadLinearCurve.RadCurve public ethCurve;

    /// @notice The public RAD bonding curve state
    RadLinearCurve.RadCurve public radCurve;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event RadbroMintedETH(address indexed user, uint32 quantity);
    event RadbroMintedRAD(address indexed user, uint32 quantity, bool indexed fromRadlist);
    event RadbroMintedAcceptedERC20(address indexed user, uint32 quantity, IERC20 indexed token);
    event RadbroMintedReserve(address indexed user, uint32 quantity);
    event RadbroUpgraded(address indexed user, uint32 quantity);
    event WonFreeRadbro(address indexed user, uint256 id);
    event WonFreeRadcoin(address indexed user, uint256 quantity);

    /*//////////////////////////////////////////////////////////////
                                 MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Only the operator can call this function.
    modifier onlyOperator() {
        require(msg.sender == operator || msg.sender == owner(), "RadlistV2: caller is not the operator");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               INITIALIZER
    //////////////////////////////////////////////////////////////*/

    // /// @notice Initialize Radbro Webring.
    // function initialize(
    //     address _operator,
    //     address _beneficiary,
    //     address _radbroV1,
    //     address _radcoinV1,
    //     address _radcoinV2,
    //     address _randProvider,
    //     RadVRGDA.RadCurve calldata _publicCurve,
    //     RadVRGDA.RadCurve calldata _radlistCurve,
    //     string calldata _baseTokenURI
    // ) external initializerERC721A initializer {
    //     __ERC721A_init("Radbro Webring V2", "RADBROS");
    //     __ERC721AQueryable_init();
    //     __ERC4907A_init();
    //     __ReentrancyGuard_init();
    //     __RadlistV2_init();

    //     operator = _operator;
    //     beneficiary = _beneficiary;
    //     operator = _operator;
    //     radbroV1 = Radbro(_radbroV1);
    //     radcoinV1 = Radcoin(_radcoinV1);
    //     radcoinV2 = RadcoinV2(_radcoinV2);
    //     randProvider = IRandomness(_randProvider);

    //     publicCurve = _publicCurve;
    //     radlistCurve = _radlistCurve;
    //     ethPrice = 0.06 ether;

    //     baseTokenURI = _baseTokenURI;
    // }

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

    /// @notice Set the signer address.
    function setSigner(address _signer) external onlyOperator {
        signer = _signer;
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

    /// @notice Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOperator {
        baseTokenURI = _baseTokenURI;
    }

    /// @notice pull ETH from the contract.
    function pullETH() external onlyOperator {
        payable(operator).transfer(address(this).balance);
    }

    /*//////////////////////////////////////////////////////////////
                               UPGRADE FROM V1
    //////////////////////////////////////////////////////////////*/

    // @notice Gets the hash to sign to call the upgradeFromV2 function.
    function getUpgradeHashToSign(UpgradeRadbroParams calldata params) public pure returns (bytes32) {
        // return keccak256(abi.encodePacked(radbroIds, radcoinToUpgrade, winABro, winSomeRad, nonce));
        return
            keccak256(
                abi.encodePacked(
                    params.owner,
                    params.radbroIds,
                    params.radcoinToClaim,
                    params.radcoinToUpgrade,
                    params.winABro,
                    params.winSomeRad,
                    params.nonce
                )
            );
    }

    /// @notice Upgrade radbros from v1.
    /// @dev Uses a claiming mechanism + off-chain signature for gas-efficient upgrades.
    function upgradeFromV1(UpgradeRadbroParams calldata params, bytes memory signature) external nonReentrant {
        require(_msgSender() == params.owner, "Radbro: Must be radbro owner");
        address _signer = _getSigner(params, signature);
        require(_signer == signer, "Radbro: Invalid signature");
        for (uint256 i = 0; i < params.radbroIds.length; ) {
            uint256 radbroId = params.radbroIds[i];
            // require(radbroV1.ownerOf(radbroId) == _msgSender(), "Radbro: Must own radbro");
            this.transferFrom(address(this), _msgSender(), radbroId);

            unchecked {
                i++;
            }
        }

        uint256 radcoinToMint;
        if (params.radcoinToClaim > 0) {
            radcoinToMint = params.radcoinToClaim;
        }
        if (params.radcoinToUpgrade > 0) {
            ERC20(address(radcoinV1)).safeTransferFrom(_msgSender(), address(this), params.radcoinToUpgrade);
            radcoinToMint += params.radcoinToUpgrade;
        }
        if (radcoinToMint > 0) {
            radcoinV2.mintForRadbros(_msgSender(), radcoinToMint);
        }

        emit RadbroUpgraded(_msgSender(), uint32(params.radbroIds.length));
    }

    function _getSigner(UpgradeRadbroParams calldata params, bytes memory signature) internal pure returns (address) {
        bytes32 messageHash = getUpgradeHashToSign(params);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature);
    }

    /*//////////////////////////////////////////////////////////////
                               RADCOIN MINTING
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint as a member of the public (using ETH).
    /// @param to The address to mint to.
    /// @param n The number of radbros to mint.
    function mintFromETH(address to, uint256 n) external payable nonReentrant {
        require(mintingEnabled, "Radbro: public minting is disabled");
        require(ethCurve.spotPrice > 0, "Radbro: ETH minting is disabled");
        require(totalSupply() + n <= PUBLIC_MINTABLE, "Radbro: Cannot mint more than PUBLIC_MINTABLE");

        (uint128 newSpotPrice, uint256 inputValue) = ethCurve.getBuyInfo(n);
        require(msg.value >= inputValue, "Radbro: Insufficient ETH sent for mint");

        ethCurve.spotPrice = newSpotPrice;
        ethCurve.lastUpdate = block.timestamp;

        // transfer ETH to the beneficiary
        payable(beneficiary).transfer(inputValue);

        // refund any extra ETH sent
        if (msg.value > inputValue) {
            payable(_msgSender()).transfer(msg.value - inputValue);
        }

        unchecked {
            mintedfromETH += n;
        }
        _mintInternal(to, n);

        emit RadbroMintedETH(_msgSender(), uint32(n));
    }

    /**
    @notice Mint Radbros (using $RAD).
     */
    function mintFromRadcoin(
        address to,
        uint256 n,
        uint256 maxInput,
        uint256[] calldata radbroIds // optional. if provided will attempt to use unclaimed radcoin.
    ) external nonReentrant {
        require(mintingEnabled, "Radbro: Minting is disabled");
        require(radCurve.spotPrice > 0, "Radbro: RAD minting is disabled");
        require(totalSupply() + n <= PUBLIC_MINTABLE, "Radbro: Cannot mint more than PUBLIC_MINTABLE");

        (uint128 newSpotPrice, uint256 inputValue) = radCurve.getBuyInfo(n);
        require(inputValue <= maxInput, "Radbro: Required input amount exceeds max input");

        radCurve.spotPrice = newSpotPrice;
        radCurve.lastUpdate = block.timestamp;

        _spendRad(_msgSender(), radbroIds, inputValue);

        unchecked {
            mintedFromRAD += n;
        }

        _mintInternal(to, n);

        emit RadbroMintedRAD(_msgSender(), uint32(n), false);
    }

    /**
     * @dev Mint tokens reserved for the team.
     * @param to The address that will own the minted tokens.
     * @param n The number to mint.
     */
    function mintFromReserve(address to, uint256 n) external onlyOperator nonReentrant {
        require(mintedFromReserve + n <= RESERVE_MINTS, "Radbro: Max mintable from reserve reached");

        mintedFromReserve += n;

        _mintInternal(to, n);
    }

    function _mintInternal(address to, uint256 n) internal {
        require(totalSupply() + n <= MAX_SUPPLY, "Radbro: Max supply reached");

        _safeMint(to, n);
    }

    // override start token id to 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /*//////////////////////////////////////////////////////////////
                               PAYMENTS (RADCOIN)
    //////////////////////////////////////////////////////////////*/

    /// @notice Spend Radcoin from the user's account.
    /// If there is sufficient unclaimed Radcoin to claim, claim that instead of transferring Radcoin.
    function _spendRad(address _owner, uint256[] calldata radbroIds, uint256 amount) internal {
        require(address(radcoinV2) != address(0), "Radbro: Radcoin not set");

        // get rad balance of the user
        uint256 balance = radcoinV2.balanceOf(_owner);

        // if there is sufficient radcoin balance, spend it instead of claiming radcoin.
        if (balance >= amount) {
            // transfer the remaining radcoin from the user to the beneficiary.
            radcoinV2.transferFromRadbros(_owner, beneficiary, amount);
            return;
        }

        // transfer the radcoin balance from the user to the beneficiary.
        radcoinV2.transferFromRadbros(_owner, beneficiary, balance);

        // if there is insufficient ckauned radcoin, claim all ckauned radcoin and transfer the remaining radcoin.
        uint256 remaining = amount - balance;

        // claim radcoin to the beneficiary.
        uint256 claimed = radcoinV2.claimRadcoin(beneficiary, address(this), radbroIds, remaining);

        require(claimed == remaining, "Radbro: Claimed amount does not match required amount");
    }

    /*//////////////////////////////////////////////////////////////
                               GETTING PRICES
    //////////////////////////////////////////////////////////////*/

    /// @notice get the purchase price for n ETH mints.
    /// @param numItems the number of items to purchase
    /// @return inputValue the amount of ETH to send to purchase the items
    function getPriceETH(uint256 numItems) external view returns (uint256 inputValue) {
        (, inputValue) = ethCurve.getBuyInfo(numItems);
    }

    /// @notice get the purchase price for n $RAD mints.
    /// @param numItems the number of items to purchase
    /// @return inputValue the amount of $RAD to send to purchase the items
    function getPriceRAD(uint256 numItems) external view returns (uint256 inputValue) {
        (, inputValue) = radCurve.getBuyInfo(numItems);
    }

    /*//////////////////////////////////////////////////////////////
                               OVERRIDEN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
    @notice Concatenates and returns the base token URI and the token ID without
    any additional characters (e.g. a slash).
    @dev This requires that an inheriting contract that also inherits from OZ's
    ERC721 will have to override both contracts; although we could simply
    require that users implement their own _baseURI() as here, this can easily
    be forgotten and the current approach guides them with compiler errors. This
    favours the latter half of "APIs should be easy to use and hard to misuse"
    from https://www.infoq.com/articles/API-Design-Joshua-Bloch/.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /// @notice Overrides supportsInterface as required by inheritance.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC721AUpgradeable, ERC721AUpgradeable, ERC4907AUpgradeable) returns (bool) {
        return ERC721AUpgradeable.supportsInterface(interfaceId) || ERC4907AUpgradeable.supportsInterface(interfaceId);
    }
}