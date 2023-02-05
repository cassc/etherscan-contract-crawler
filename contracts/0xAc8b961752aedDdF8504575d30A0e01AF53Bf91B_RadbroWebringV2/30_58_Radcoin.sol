// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;
import "hardhat/console.sol";
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

import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";
import { FixedPointMathLib } from "solmate/src/utils/FixedPointMathLib.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice Radcoins for Radbros.
/// @author 10xdegen
contract Radcoin is ERC20, ReentrancyGuard {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                     EVENTS
    //////////////////////////////////////////////////////////////*/

    event Claim(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256[] radbros,
        uint256 amount
    );

    /*//////////////////////////////////////////////////////////////
                    RADBRO
    //////////////////////////////////////////////////////////////*/

    address public immutable radbro;
    uint256 public immutable MAX_PER_RADBRO = 250 ether;
    uint256 public immutable REWARD_PER_DAY = 1 ether;

    /*//////////////////////////////////////////////////////////////
                    STATE
    //////////////////////////////////////////////////////////////*/

    struct ClaimState {
        uint256 startTime; // time
        uint256 totalClaimed; // total amount claimed
    }

    // token id to the state of the claim
    mapping(uint256 => ClaimState) public claims;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();

    /*//////////////////////////////////////////////////////////////
                                 MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Requires caller address to match user address.
    modifier only(address user) {
        if (msg.sender != user) revert Unauthorized();

        _;
    }

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _radbro) ERC20("Radcoin", "RAD", 18) {
        radbro = _radbro;
    }

    /*//////////////////////////////////////////////////////////////
                                CLAIMING
    //////////////////////////////////////////////////////////////*/

    /// @notice Each radbro starts with 0 reward.
    /// Called on new radbro mint.
    function initializeRadbro(uint256 id, uint256 startTime) external only(radbro) {
        claims[id] = ClaimState(startTime, 0);
    }

    // @notice Gets the claim state for the radbro id.
    // @param radbroId The radbro id.
    // @return The claim state.
    function getClaim(uint256 radbroId) public view returns (ClaimState memory) {
        return claims[radbroId];
    }

    // @notice Get the radcoin reward for a given radbro. Each Radbro pays 1e18 Radcoin per day.
    // @param radbroId The radbro id.
    // @return The radcoin reward.
    function getClaimRewards(uint256[] calldata radbroIds) public view returns (uint256 reward) {
        for (uint256 i = 0; i < radbroIds.length; i++) {
            uint256 radbroId = radbroIds[i];
            reward += getClaimReward(radbroId);
        }
    }

    // @notice Get the radcoin reward for a given radbro. Each Radbro pays 1e18 Radcoin per day.
    // @param radbroId The radbro id.
    // @return The radcoin reward.
    function getClaimReward(uint256 radbroId) public view returns (uint256 reward) {
        ClaimState memory claim = getClaim(radbroId);
        require(claim.startTime != 0, "NOT_INITIALIZED");
        if (claim.startTime >= block.timestamp) return 0; // should never happen

        uint256 radbroAge = block.timestamp - claim.startTime;

        uint256 totalEarned = ((radbroAge * REWARD_PER_DAY) / 1 days);
        // console.log("id, totalEarned, totalClaimed", radbroId, totalEarned, claim.totalClaimed);
        reward = totalEarned - claim.totalClaimed;
        // console.log("reward, MAX_PER_RADBRO, totalClaimed, startTime", reward, MAX_PER_RADBRO, claim.startTime);
        if (reward > MAX_PER_RADBRO - claim.totalClaimed) {
            reward = MAX_PER_RADBRO - claim.totalClaimed; // cap at MAX_PER_RADBRO per radbro
        }
    }

    /// @notice Claim RAD for a set of Radbros. Caller must be the owner of the Radbros.
    /// @param _receiver The address to receive the RAD.
    /// @param _radbros The Radbros to claim for.
    /// @return amount The amount of RAD claimed.
    function claimRadcoin(
        address _receiver,
        uint256[] calldata _radbros
    ) external nonReentrant returns (uint256 amount) {
        for (uint256 i = 0; i < _radbros.length; i++) {
            uint256 radbroId = _radbros[i];

            require(IERC721(radbro).ownerOf(radbroId) == msg.sender, "NOT_RAD_BRO");

            uint256 rewardForRadbro = getClaimReward(radbroId);
            if (rewardForRadbro > 0) {
                claims[radbroId].totalClaimed += rewardForRadbro;
                amount += rewardForRadbro;
            }
        }

        require(amount > 0, "NO_RAD_CLAIMABLE");

        _mint(_receiver, amount);
    }

    /// @notice Spend (burn) virtual radcoin without needing to mint. Can only be called by Radbro.
    /// @param radbroId The id of the radbro to burn claim from.
    /// @param amount The amount of radcoin to burn.
    function claimForRadbro(uint256 radbroId, uint256 amount) external only(radbro) {
        uint256 rewardForRadbro = getClaimReward(radbroId);
        console.log("claiming rewardForRadbro", rewardForRadbro, amount, claims[radbroId].totalClaimed);
        require(rewardForRadbro >= amount, "NOT_ENOUGH_REWARD");

        if (amount > 0) {
            claims[radbroId].totalClaimed += amount;
        }
        console.log("remaining reward", getClaimReward(radbroId));
    }

    /*//////////////////////////////////////////////////////////////
                             BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Burn any amount of radcoin from a user. Can only be called by Radbros.
    /// @param from The address of the user to burn radcoin from.
    /// @param amount The amount of radcoin to burn.
    function burnForRadbros(address from, uint256 amount) external only(radbro) {
        require(balanceOf[from] >= amount, "NOT_ENOUGH_BALANCE");
        _burn(from, amount);
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
            _approve(owner, spender, currentAllowance - amount);
        }
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}