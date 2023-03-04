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

import { ERC721A } from "erc721a/contracts/ERC721A.sol";
import { ERC721ACommon } from "@divergencetech/ethier/contracts/erc721/ERC721ACommon.sol";
import { BaseTokenURI } from "@divergencetech/ethier/contracts/erc721/BaseTokenURI.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Radlist, AddCollectionParams, ClaimRadlistParams } from "./Radlist.sol";
import { RadArt } from "./RadArt.sol";
import { Radcoin } from "./Radcoin.sol";
import { Radmath } from "./Radmath.sol";

/// @notice The Original Radbro.
/// @author 10xdegen
/// @dev This contract is the main entry point for the Radbro ecosystem.
/// It is responsible for minting new Radbro NFTs and claiming Radcoin.
/// Credit goes to the Radbro team StuxnetTypeBeat AEQEA giverrod and 10xdegen
contract Radbro is ERC721ACommon, BaseTokenURI, ReentrancyGuard, Radlist, RadArt, Radmath {
    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the Radcoin ERC20 token contract.
    Radcoin public radcoin;

    /*//////////////////////////////////////////////////////////////
                            MINT CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum number of mintable radbros.
    uint256 public constant MAX_SUPPLY = 4000;

    /// @notice Maximum amount of radbros mintable via radlist.
    uint256 public constant RADLIST_MINTABLE = 1000;

    /// @notice Maximum amount of radbros reserved for team / community.
    uint256 public constant RESERVED_SUPPLY = 400;

    /// @notice Maximum amount of radbros that can be minted via Radcoin.
    // prettier-ignore
    uint256 public constant RADCOIN_MINTABLE = MAX_SUPPLY 
        - RESERVED_SUPPLY
        - RADLIST_MINTABLE;

    /*//////////////////////////////////////////////////////////////
                             MINTING STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Total number of radbros minted from the Radlist.
    uint256 public mintedFromRadlist;

    /// @notice Total number of radbros minted from the Radlist.
    uint256 public mintedFromReserve;

    /// @notice Total number of radbros minted with Radcoin.
    uint256 public mintedFromRadcoin;

    /// @notice The current spot price for minting radbros (in $RAD).
    uint128 public spotPrice;

    /// @notice Price increase for radbro (1e18+1e17 == 10% increase) on every mint.
    uint128 public priceDelta;

    /// @notice The current price for rerolling radbro art (in $RAD).
    uint128 public radrollPrice;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event RadbroMinted(address indexed user, uint8 quantity);
    event RadlistClaimed(address indexed user, uint8 quantity);
    event ArrtRadrolled(address indexed user, uint256 indexed radbroId, uint256 newArt);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address payable _beneficiary,
        uint128 _startPrice,
        uint128 _priceDelta,
        bytes32 _merkleRoot,
        AddCollectionParams[] memory _collections
    )
        ERC721ACommon("Radbro Webring", "RADBRO", _beneficiary, 0)
        Radlist(_merkleRoot, _collections)
        RadArt(4_000, 8_000) // 4k initial art, 8k secondary art
        BaseTokenURI("")
    {
        spotPrice = _startPrice;
        priceDelta = _priceDelta;
        radrollPrice = 2 ether; // 2 RAD to radroll
    }

    /*//////////////////////////////////////////////////////////////
                               INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Initialize the Radcoin address.
    function initialize(address _radcoin) external onlyOwner {
        require(address(radcoin) == address(0), "Radbro: Radcoin already set");
        radcoin = Radcoin(_radcoin);
    }

    /*//////////////////////////////////////////////////////////////
                               MINTING
    //////////////////////////////////////////////////////////////*/

    /**
    @notice Mint as a member of the public (using $RAD).
     */
    function mintFromRadcoin(
        address to,
        uint256[] calldata radbroIds,
        uint256 n,
        uint256 maxInput
    ) external nonReentrant {
        require(n > 0, "Radbro: Must mint at least one");
        require(mintedFromRadcoin + n <= RADCOIN_MINTABLE, "Radbro: Cannot mint more than RADCOIN_MINTABLE");
        (uint128 newSpotPrice, uint256 inputValue) = getBuyInfo(spotPrice, priceDelta, n);

        require(inputValue <= maxInput, "Radbro: Input value exceeds maxInput");
        _spendRad(_msgSender(), radbroIds, inputValue);

        mintedFromRadcoin += n;
        spotPrice = newSpotPrice;

        _mintInternal(to, n);
    }

    /**
     * @dev Mint tokens via the Radlist.
     * @param to The address that will own the minted tokens.
     * @param params Parameters for claiming from the Radlist.
     */
    function mintFromRadlist(address to, ClaimRadlistParams calldata params) external nonReentrant {
        uint256 totalClaimed = _claimRadlist(_msgSender(), params);
        require(mintedFromRadlist + totalClaimed <= RADLIST_MINTABLE, "Radbro: Max mintable reached");

        mintedFromRadlist += totalClaimed;

        _mintInternal(to, totalClaimed);
    }

    /**
     * @dev Mint tokens reserved for the team.
     * @param to The address that will own the minted tokens.
     * @param n The number to mint.
     */
    function mintFromReserve(address to, uint256 n) external onlyOwner {
        require(mintedFromReserve + n <= RESERVED_SUPPLY, "Radbro: Max mintable from reserve reached");

        mintedFromReserve += n;

        _mintInternal(to, n);
    }

    function _mintInternal(address to, uint256 n) internal whenNotPaused {
        require(totalSupply() + n <= MAX_SUPPLY, "Radbro: Max supply reached");

        // start radcoin claim counter
        for (uint256 i = totalSupply() + 1; i <= totalSupply() + n; i++) {
            radcoin.initializeRadbro(i, block.timestamp);
        }

        _safeMint(to, n);
    }

    // override start token id to 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /*//////////////////////////////////////////////////////////////
                               ART
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Update the price for rerolling radbro art.
     */
    function setRadrollPrice(uint128 _radrollPrice) external onlyOwner {
        radrollPrice = _radrollPrice;
    }

    /**
     * @dev Radroll the art for a radbro.
     */
    function radrollArt(uint256 tokenId, uint256[] calldata radbroIds) public returns (uint256 newArt) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(ownerOf(tokenId) == _msgSender(), "ERC721: caller is not the owner");
        _spendRad(_msgSender(), radbroIds, radrollPrice);

        // if we are not yet minted out, you can only radroll into art that is past max supply
        bool allowFromInit = totalSupply() == MAX_SUPPLY;

        newArt = _rerollArt(tokenId, allowFromInit);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        (uint256 art, bool initial) = getArt(tokenId);
        if (art == 0) {
            art = tokenId;
        } else if (!initial) {
            art += 4_000;
        }
        return string(abi.encodePacked(_baseURI(), _toString(art)));
    }

    /**
    @dev Required override to select the correct baseTokenURI.
     */
    function _baseURI() internal view override(BaseTokenURI, ERC721A) returns (string memory) {
        return BaseTokenURI._baseURI();
    }

    /*//////////////////////////////////////////////////////////////
                               PAYMENTS (RADCOIN)
    //////////////////////////////////////////////////////////////*/

    /// @notice Burn Radcoin from the user's account.
    /// If there is sufficient unclaimed Radcoin to claim, claim that instead of burning.
    function _spendRad(address owner, uint256[] calldata radbroIds, uint256 amount) internal {
        require(address(radcoin) != address(0), "Radbro: Radcoin not set");

        for (uint256 i = 0; i < radbroIds.length; i++) {
            uint256 radbroId = radbroIds[i];
            require(_exists(radbroId), "Radbro: Radbro does not exist");
            require(ownerOf(radbroId) == owner, "Radbro: Not owner of Radbro");
            uint256 reward = radcoin.getClaimReward(radbroId);

            if (reward == 0) {
                continue;
            }
            if (reward >= amount) {
                radcoin.claimForRadbro(radbroId, amount);
                return;
            } else {
                radcoin.claimForRadbro(radbroId, reward);
                amount -= reward;
            }
        }

        radcoin.burnForRadbros(owner, amount);
    }
}