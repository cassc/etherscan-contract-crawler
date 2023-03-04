// SPDX-License-Identifier: AGPL-3.0-only
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

import { ERC20Upgradeable } from "./utils/ERC20Upgradeable.sol";
import { FixedPointMathLib } from "lib/solmate/src/utils/FixedPointMathLib.sol";
import { ERC20 } from "lib/solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "lib/solmate/src/utils/SafeTransferLib.sol";
import { IERC4907 } from "./interfaces/IERC4907.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { RadbroWebringV2 } from "./RadbroWebringV2.sol";
import { SignatureVerifier } from "./utils/SignatureVerifier.sol";

/// @notice Radcoins for Radbros. V2 cuz we added some stuff.
/// @author 10xdegen
contract RadcoinV2 is ERC20Upgradeable, ReentrancyGuardUpgradeable, SignatureVerifier {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                     CONSTANTS
    //////////////////////////////////////////////////////////////*/

    // uint256 public constant EIP4907_INTERFACE_ID = 0xad092b5c;
    /// @notice EIP4907 interface id
    bytes4 public constant EIP4907_INTERFACE_ID = 0xad092b5c;

    /// @notice max amount of radcoin that can be minted = 10 million.
    uint256 public constant MAX_SUPPLY = 10_000_000e18;

    /*//////////////////////////////////////////////////////////////
                     STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct ClaimConfig {
        uint256 rewardPerDay; // amount of radcoin earned per per day
        uint256 maxClaim; // max amount of radcoin that can be claimed
        bool implementsEIP4907; // if the nft contract implements EIP4907
    }

    struct ClaimState {
        uint256 startTime; // time
        uint256 totalClaimed; // total amount claimed
    }

    /*//////////////////////////////////////////////////////////////
                     EVENTS
    //////////////////////////////////////////////////////////////*/

    event ClaimConfigSet(address indexed nftContract, uint256 rewardPerDay, uint256 maxClaim, bool implementsEIP4907);

    event RadcoinUpgraded(address indexed sender, address indexed receiver, uint256 indexed amount);

    event ClaimRadcoin(address indexed sender, address indexed nftContract, uint256 indexed numTokens, uint256 amount);

    event InitializeRadNFT(address indexed sender, address indexed nftContract, uint256[] ids);

    event SetAMMPair(address indexed pair, bool indexed value);

    event SetBuyFee(uint256 indexed fee);

    event SetSellFee(uint256 indexed fee);

    event MintedByRadbrosContract(address indexed receiver, uint256 indexed amount);

    /*//////////////////////////////////////////////////////////////
                    CONFIG
    ////////////////////////////////////////////////////////f//////*/

    /// @notice The address of the operator.
    address public operator;

    // AMM swap fee recipient
    address public beneficiary;

    // radbro v2 nft contract
    RadbroWebringV2 public radbroV2;

    /// @notice The address of the Radcoin V1 ERC20 token contract.
    ERC20 public constant radcoinV1 = ERC20(0x6AF36AdD4E2F6e8A9cB121450d59f6C30F3F3722);

    // nft contract to the claim config
    mapping(IERC721 => ClaimConfig) public claimConfigs;

    // the time when upgraded bro claiming starts
    uint256 public upgradeStartTime;

    // store addresses of AMM pairs.
    // swap fees may applied to transfers *to* or *from* these addresses.
    mapping(address => bool) public ammPairs;

    // the fee paid on buys (default 2%)
    uint256 public buyFee;

    // the fee paid on sells (default 2%)
    uint256 public sellFee;

    // store addresses that are excluded from fees
    mapping(address => bool) public feeExcluded;

    /*//////////////////////////////////////////////////////////////
                    STATE
    //////////////////////////////////////////////////////////////*/

    // contract to token id to the state of the claim
    mapping(IERC721 => mapping(uint256 => ClaimState)) public claims;

    /*//////////////////////////////////////////////////////////////
                    SIGNED CLAIMING
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the upgrade signer.
    address public signer;

    /// @notice nonces for public claim signatures
    mapping(address => uint256) public claimNonces;

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

    /// @notice Initialize Radcoin.
    /// @param _beneficiary The address of the fee recipient.
    function initialize(address _operator, address _beneficiary) public initializer {
        __ERC20Upgradeable_init("Radcoin V2", "RAD", 18);
        __ReentrancyGuard_init();
        operator = _operator;
        beneficiary = _beneficiary;

        // exclude owner and this contract from fees
        feeExcluded[msg.sender] = true;
        feeExcluded[address(this)] = true;
        feeExcluded[_beneficiary] = true;

        // set starting fees
        buyFee = 2e16; // 2%
        sellFee = 2e16; // 2%

        // set upgrade start time
        upgradeStartTime = block.timestamp;
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

    /// @notice Set the signer address.
    function setSigner(address _signer) external onlyOperator {
        signer = _signer;
    }

    /// @notice Set the fee address.
    /// @param _beneficiary The address of the fee recipient.
    function setBeneficiary(address _beneficiary) external onlyOperator {
        beneficiary = _beneficiary;
    }

    /// @notice Set the Radbro V2 contract.
    /// @param _radbroV2 The address of the Radbro V2 contract.
    function setRadbroV2(RadbroWebringV2 _radbroV2) external onlyOperator {
        radbroV2 = _radbroV2;
    }

    /// @notice Set the claim config for a Rad NFT contract.
    /// @param _radNFT The Rad NFT contract.
    /// @param _rewardPerDay The amount of RAD earned per day per token.
    /// @param _maxClaim The max amount of RAD that can be claimed per token.
    function setClaimConfig(IERC721 _radNFT, uint256 _rewardPerDay, uint256 _maxClaim) external onlyOperator {
        bool supportsEIP4907 = _radNFT.supportsInterface(EIP4907_INTERFACE_ID);
        claimConfigs[_radNFT] = ClaimConfig(_rewardPerDay, _maxClaim, supportsEIP4907);

        emit ClaimConfigSet(address(_radNFT), _rewardPerDay, _maxClaim, supportsEIP4907);
    }

    /// @notice Set an AMM pair.
    /// @param _pair The address of the AMM pair.
    /// @param _value The value to set.
    function setAMMPair(address _pair, bool _value) external onlyOperator {
        ammPairs[_pair] = _value;

        emit SetAMMPair(_pair, _value);
    }

    /// @notice Set the buy fee.
    /// @param _fee The fee to set.
    function setBuyFee(uint256 _fee) external onlyOperator {
        buyFee = _fee;

        emit SetBuyFee(_fee);
    }

    /// @notice Set the sell fee.
    /// @param _fee The fee to set.
    function setSellFee(uint256 _fee) external onlyOperator {
        sellFee = _fee;

        emit SetSellFee(_fee);
    }

    /// @notice Set an address to be excluded from fees.
    /// @param _account The account to exclude.
    /// @param _value The value to set.
    function setFeeExcluded(address _account, bool _value) external onlyOperator {
        feeExcluded[_account] = _value;
    }

    /*//////////////////////////////////////////////////////////////
                                UPGRADING FROM V1
    //////////////////////////////////////////////////////////////*/

    /// @notice Upgrade from RadcoinV1.
    /// @param _sender The address to send the RAD from.
    /// @param _receiver The address to receive the RAD.
    /// @param _amount The amount of RAD to upgrade.
    function upgradeRadcoin(address _sender, address _receiver, uint256 _amount) external nonReentrant {
        // only the sender or an approved spender can upgrade.
        require(
            msg.sender == _sender || radcoinV1.allowance(_sender, msg.sender) >= _amount,
            "Radcoin: unauthorized upgrade"
        );
        radcoinV1.safeTransferFrom(_sender, address(this), _amount);
        _mint(_receiver, _amount);

        emit RadcoinUpgraded(_sender, _receiver, _amount);
    }

    /// @notice Upgrade Unclaimed $RAD from V1.
    /// @param _receiver The address to receive the RAD.
    function mintForRadbros(address _receiver, uint256 _amount) external nonReentrant {
        require(_msgSender() == address(radbroV2), "Radcoin: only callable by Radbro V2 contract.");
        _mint(_receiver, _amount);

        emit MintedByRadbrosContract(_receiver, _amount);
    }

    /*//////////////////////////////////////////////////////////////
                                CLAIMING
    //////////////////////////////////////////////////////////////*/

    /// @notice Each rad nft starts with 0 reward.
    /// Should be called on new Rad NFT mints.
    /// Must be called by the Rad NFT contract or the owner.
    function initializeRadNFT(address _contractAddr, uint256 _id) external {
        bool authorizedCaller = msg.sender == _contractAddr || msg.sender == owner();

        IERC721 _contract = IERC721(_contractAddr);

        // sender must have a claim config
        ClaimConfig memory config = claimConfigs[_contract];
        require(config.rewardPerDay > 0, "Radcoin: NFT not claimable");

        // initialize the claim state for each id
        require(claims[_contract][_id].startTime == 0, "Radcoin: already initialized");

        if (!authorizedCaller) {
            require(_canUseId(_contract, _id, msg.sender, config.implementsEIP4907), "Radcoin: unauthorized");
        } else {}
        claims[_contract][_id] = ClaimState(block.timestamp, 0);
    }

    /// @notice Same as initializeRadNFT but for multiple ids.
    function initializeRadNFTs(address _contractAddr, uint256[] calldata _ids) external {
        bool authorizedCaller = msg.sender == _contractAddr || msg.sender == owner();

        IERC721 _contract = IERC721(_contractAddr);

        // sender must have a claim config
        ClaimConfig memory config = claimConfigs[_contract];
        require(config.rewardPerDay > 0, "Radcoin: NFT not claimable");

        // initialize the claim state for each id
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            require(claims[_contract][id].startTime == 0, "Radcoin: already initialized");

            if (!authorizedCaller) {
                require(_canUseId(_contract, id, msg.sender, config.implementsEIP4907), "Radcoin: unauthorized");
            }
            claims[_contract][id] = ClaimState(block.timestamp, 0);
        }
    }

    /// @notice Claim RAD for a set of Rad NFTs. Caller must be the owner, approved for, or the user of the NFTs.
    /// @param _receiver The address to receive the RAD.
    /// @param _contractAddr The Rad NFT contract address.
    /// @param _ids The NFT ids to claim for.
    /// @param _maxClaim The max amount of RAD to claim.
    /// @return amount The amount of RAD claimed.
    function claimRadcoin(
        address _receiver,
        address _contractAddr,
        uint256[] calldata _ids,
        uint256 _maxClaim
    ) external returns (uint256 amount) {
        IERC721 _contract = IERC721(_contractAddr);
        ClaimConfig memory config = claimConfigs[_contract];

        // require claim config
        require(config.rewardPerDay > 0, "Radcoin: NFT not claimable");

        bool callerIsContract = msg.sender == address(_contract);

        IERC721 nftContract = IERC721(_contract);

        mapping(uint256 => ClaimState) storage claimStates = claims[_contract];

        // loop through the ids
        for (uint256 i; i < _ids.length; ) {
            uint256 id = _ids[i];

            // // require owner, approved, user, or nft contract
            require(
                callerIsContract || nftContract.ownerOf(id) == msg.sender,
                // callerIsContract || _canUseId(nftContract, id, msg.sender, config.implementsEIP4907),
                "Radcoin: unauthorized"
            );

            ClaimState memory claim = claimStates[id];
            // if contract is radbroV2 and id is less than radbroV2.V1_UPRGADE_MINTS, set start time to upgradeStartTime
            if (claim.startTime == 0 && address(_contract) == address(radbroV2) && id < radbroV2.V1_UPRGADE_MINTS()) {
                claim.startTime = upgradeStartTime;
            }
            require(claim.startTime != 0, "NOT_INITIALIZED");

            uint256 rewardForId;
            unchecked {
                uint256 totalEarned = (((block.timestamp - claim.startTime) * config.rewardPerDay) / 1 days);

                rewardForId = totalEarned - claim.totalClaimed;

                if (rewardForId > config.maxClaim - claim.totalClaimed) {
                    rewardForId = config.maxClaim - claim.totalClaimed; // cap at maxClaim per rad nft
                }

                if (_maxClaim > 0 && amount + rewardForId > _maxClaim) {
                    claimStates[id].totalClaimed += _maxClaim - amount;
                    amount = _maxClaim;
                    break;
                } else if (rewardForId > 0) {
                    claimStates[id].totalClaimed += rewardForId;
                    amount += rewardForId;
                }
                i++;
            }
        }

        if (amount == 0) {
            return 0;
        }

        _mint(_receiver, amount);

        emit ClaimRadcoin(_receiver, address(_contract), _ids.length, amount);
    }

    /// @notice Claim RAD using off-chain verifiable signature. Claim proofs posted to radbro.xyz
    function claimRadcoinSigned(
        address _receiver,
        address _contractAddr,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes memory _signature
    ) external returns (uint256 amount) {
        require(
            _getSigner(msg.sender, _contractAddr, _ids, _amounts, claimNonces[msg.sender], _signature) == signer,
            "INVALID_SIGNATURE"
        );

        // increment nonce
        claimNonces[msg.sender]++;

        // increment amount for each id
        unchecked {
            for (uint i; i < _ids.length; ) {
                uint256 id = _ids[i];
                amount += _amounts[i];
                claims[IERC721(_contractAddr)][id].totalClaimed += _amounts[i];
                i++;
            }
        }

        _mint(_receiver, amount);

        emit ClaimRadcoin(_receiver, address(_contractAddr), _ids.length, amount);
    }

    function _getSigner(
        address _sender,
        address _contractAddr,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        uint256 _nonce,
        bytes memory signature
    ) internal pure returns (address) {
        bytes32 messageHash = getClaimHash(_sender, _contractAddr, _ids, _amounts, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature);
    }

    // @notice Gets the Claim hash to sign to call the claimRadcoinSigned function.
    function getClaimHash(
        address _sender,
        address _contractAddr,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        uint256 _nonce
    ) public pure returns (bytes32) {
        // return keccak256(abi.encodePacked(radbroIds, radcoinToUpgrade, winABro, winSomeRad, nonce));
        return keccak256(abi.encodePacked(_sender, _contractAddr, _ids, _amounts, _nonce));
    }

    /// @notice Internal mint function. Checks max supply.
    /// @param _receiver The address to receive the RAD.
    /// @param _amount The amount of RAD to mint.
    function _mint(address _receiver, uint256 _amount) internal override {
        require(totalSupply + _amount <= MAX_SUPPLY, "Radcoin: max supply exceeded");
        super._mint(_receiver, _amount);
    }

    /// @notice Checks if the user can use the NFT.
    /// @param _nftContract The Rad NFT contract.
    /// @param _id The id of the Rad NFT.
    /// @param _user The user to check.
    /// @param _implementsEIP4907 If the Rad NFT contract implements EIP4907.
    /// @return True if the user can use the NFT.
    function _canUseId(
        IERC721 _nftContract,
        uint256 _id,
        address _user,
        bool _implementsEIP4907
    ) internal view returns (bool) {
        return
            _nftContract.ownerOf(_id) == _user ||
            _nftContract.isApprovedForAll(_nftContract.ownerOf(_id), _user) ||
            _nftContract.getApproved(_id) == _user ||
            (_implementsEIP4907 && IERC4907(address(_nftContract)).userOf(_id) == _user);
    }

    /// @notice Get the radcoin reward for a given rad nft. Each Rad NFT pays a fixed amount of Radcoin per day.
    /// @param _contract The Rad NFT contract.
    /// @param _ids The rad nft ids.
    /// @return reward The radcoin reward.
    function getClaimRewards(IERC721 _contract, uint256[] calldata _ids) external view returns (uint256 reward) {
        ClaimConfig memory config = claimConfigs[_contract];
        require(config.rewardPerDay > 0, "Radcoin: NFT not claimable");
        unchecked {
            for (uint256 i = 0; i < _ids.length; i++) {
                uint256 id = _ids[i];
                reward += _getClaimReward(config, _contract, id);
            }
        }
    }

    /// @notice Get the radcoin reward for a given rad nft. Each rad nft a fixed amount of radcoin per day.
    /// @param _contract The Rad NFT contract.
    /// @param _id The rad nft id.
    /// @return reward The radcoin reward.
    function _getClaimReward(
        ClaimConfig memory config,
        IERC721 _contract,
        uint256 _id
    ) internal view returns (uint256 reward) {
        ClaimState memory claim = getClaim(_contract, _id);
        // if contract is radbroV2 and id is less than radbroV2.V1_UPRGADE_MINTS, set start time to upgradeStartTime
        if (claim.startTime == 0 && address(_contract) == address(radbroV2) && _id < radbroV2.V1_UPRGADE_MINTS()) {
            claim.startTime = upgradeStartTime;
        }
        require(claim.startTime != 0, "NOT_INITIALIZED");

        unchecked {
            uint256 totalEarned = (((block.timestamp - claim.startTime) * config.rewardPerDay) / 1 days);

            reward = totalEarned - claim.totalClaimed;

            if (reward > config.maxClaim - claim.totalClaimed) {
                reward = config.maxClaim - claim.totalClaimed; // cap at maxClaim per rad nft
            }
        }
    }

    /// @notice Gets the claim state for the rad nft id.
    /// @param _contract The Rad NFT contract address.
    /// @param _id The NFT id.
    /// @return The claim state.
    function getClaim(IERC721 _contract, uint256 _id) public view returns (ClaimState memory) {
        return claims[_contract][_id];
    }

    /*//////////////////////////////////////////////////////////////
                                TRANSFER OVERRIDE (FEE)
    //////////////////////////////////////////////////////////////*/

    /// @notice Special transfer function called when minting radbros, used to skip allowance checks for Radbro V2.
    function transferFromRadbros(address from, address to, uint256 amount) external {
        require(_msgSender() == address(radbroV2), "Radcoin: only callable by Radbro V2 contract.");

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        uint256 newAmount = amount;
        if (ammPairs[from]) {
            // sell
            newAmount = _takeFee(from, to, amount, false);
        } else if (ammPairs[to]) {
            // buy
            newAmount = _takeFee(from, to, amount, true);
        }

        // require allowance if sender is not from
        if (from != msg.sender) {
            uint256 currentAllowance = allowance[from][msg.sender];
            require(currentAllowance >= amount, "Radcoin: transfer amount exceeds allowance");
        }

        return super.transferFrom(from, to, newAmount);
    }

    function _takeFee(address from, address to, uint256 amount, bool buy) internal returns (uint256 newAmount) {
        if (feeExcluded[from] || feeExcluded[to]) {
            return amount;
        }

        uint256 feePercent = buy ? buyFee : sellFee;
        if (feePercent == 0) {
            return amount;
        }
        uint256 fee = (amount * feePercent) / 1e18;

        if (fee == 0) {
            return amount;
        }

        newAmount = amount - fee;

        super.transferFrom(from, beneficiary, fee);
    }

    /*//////////////////////////////////////////////////////////////
                             BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external nonReentrant {
        require(balanceOf[msg.sender] >= amount, "NOT_ENOUGH_BALANCE");
        _burn(msg.sender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external nonReentrant {
        require(balanceOf[account] >= amount, "NOT_ENOUGH_BALANCE");
        _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance[owner][spender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            allowance[owner][spender] = currentAllowance - amount;
        }
    }
}