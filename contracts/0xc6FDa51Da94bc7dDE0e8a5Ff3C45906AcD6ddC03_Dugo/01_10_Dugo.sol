// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./IDugo.sol";

error Dugo_FunctionLocked();
error Dugo_InvalidMaxSupply();
error Dugo_MaxSupplyReached();
error Dugo_NotAswangContract();
error Dugo_NotTokenOwner();
error Dugo_TokenIdOutOfRange();

interface IAswang is IERC721 {
    function prayingStartedAt(uint256 tokenId) external view returns (uint256);
}

/**                                                      .,,,,.
                                                        ,l;..,l;.
                                                      .co,    ,ol.
                                                     ;do'.'::'..ox;.
                                                   .cxl..:xOOk:..cxc.
                                                  .dk:. ;xxc:dk;  ;xd,
                                                 ,xx;  'xk;. 'xx,  'dx;
                                                ;xd,  .dOxc;,;oOx.  .okc.
                                              .cko.  .oOo'.   .c0o.  .lkl.
                                             .okc.  .:kx,      .dkc.   ;xd,
                                            ;xd,     ..          ..     'okc.
                                          .lOo.                          .lko.
                                         .oOl.                             :Od'
                                        .dOc.                               ;kx'
                                       ,xk;         ...'',,,,,,''...         ,xk;
                                     .:xx'   ..';:coodddddddddoddoollc:;'.    .okl.
                                    .okl.   ..''.....               ....''..    :kk,
                                  .:O0c            ..,:loxkkxxkkdl:,..           'xOc.
                                 .o0k;        .,:oxkkkkxoooooodxkO00Okxoc,..      .o0x.
                                ,k0o.     .;ldxdoc;'....',,;;;;,....,:lxOOOko:,.    :0O;
                              .cOO:.   .:odo:'.     'cdoc:,,,;:lloc'    .':oxOOxc,.  ,kKl.
                             .dX0;  .:ooc'.       'lxd;.         'lko'      .'cxOOxc' .xXk'
                            ;OKd'.'oxl'          ;dxc.    .''.     ,xk:        .'cxOkl'.lK0:
                          .oK0:.'okl.           ,xk:.   .ldlldc.    'xk;          .,okxc';OXd.
                         'kXx'.cxl.            .oOd.   .ck:  ,xl.   .lOd.            ,oxl''xXO,
                        ;0Kl..cl'              .dOo.   .oO:  ,kx.    cOx,             .'cc..lKK:
                      .cKKo;cdo.               .l0x'    .ol;,lx:.   .d0d'               .cdc':0Xo.
                     .dX0c.oKXO:.               'x0l.     .....    .lOOc.               .xK0o.'xXx.
                    ;OXk;  .:k0Oo;.              ;OKd'            'd00o.              .:xxl;'  .lKO:
                  .oKKo.     .;okOko;.            'oOOd:'......,cx0KOl.            .;oxo;.       'xKo.
                 'xXO:        ..'cxO0Odc,.          .,:lddxxkxkkkdc,.          .'cxxd:...         .c0k'
                ;0Xx'      .;c;.  .':ok00Odl;'.           ......          ..;ldkxo;.  .lko,         ,O0;
              .cKXd.     .:dl'        .';ldk00Oxoc;,...            ..,;coxkkxl;..      .;xko,        'kKl.
             .oKKl.     ,oo,      .:;      .';lxkO00Okkxdoc:;:clodxOOOkoc;..   ,;.       .;dxc.       .dKx.
            ,kKO:.     .;'       'oo.           ..',::codkkxxkxdlc:,...        ;xx;         '::.       .lKO;
          .c0Xk,                'ol.      'l,                        .:c.       'oko.                    ;OKl.
         .oKKo. ..             .:;.      'dc.     .;;       .;,       ;xl.       .;xd,                ..  'xXd.
        .xX0c. .dk:            ..       .:c.      ;xc      .,dk.       cOl.        .,:.              :Ok,  .oKk'
       'kXO:  :Okc;.                    .'.      .ld'       .l0:       .cx:                          ;cdkc.  cKO;
      ;0XO; .dXx.                                .;;         'ko.        ,:.                           .xKx'  ;0Kc.
     cKXx'.;O0dl'    .                                        ;;                                  ..   :dldkc. 'kKo.
   .oXXd..oKO:.cd:,;cdl.                                                                        .lko;;oOo''oOd' .dKd.
  .dX0l. :OOdoloxdlc;,:'                                                                        .:;,:ldxolllxOl. .lKx.
 'xXO:.  ........                                                                                        ......   .c0k'
'OWNOoccccccccccc:c::::::;;;;,,,;;;,,,,,,,,;,,,,,,,;;,,,'''''''',,,,;;;;,,,,,;;,;;;;;;;;;;;:::::;::cccccccllccllllodONO'
:XWWWNXK00OO00000000000000OOOOOOO00OOOOO00000000000000KXXXXXXXXXKK00000000OO0O000OOOOOOOOOOOO000OOOO000OOOOOOOO00KXNNWNd

 * @title Aswang Tribe $DUGO token
 * @author Augminted Labs, LLC
 */
contract Dugo is IDugo, ERC20, Ownable, ReentrancyGuard {
    IAswang public immutable ASWANG;
    uint256 public immutable STARTED_AT;
    uint256 public constant GENESIS_SUPPLY = 3333;
    uint256 public constant TOTAL_SUPPLY = 6666;
    uint256 public constant GENESIS_BASE_RATE = 5 ether;
    uint256 public constant MANANANGGAL_BASE_RATE = 2 ether;
    uint256 public constant EPOCH_DURATION = 180 days;

    uint256 public maxSupply = 10_000_000 ether;
    uint256 public totalClaimed;
    mapping(bytes4 => bool) public functionLocked;
    mapping(uint256 => uint256) internal _lastClaimedAt;

    constructor(
        IAswang aswang
    )
        ERC20("Dugo", "DUGO")
    {
        ASWANG = aswang;
        STARTED_AT = block.timestamp;
    }

    /**
     * @notice Modifier applied to functions that will be disabled when they're no longer needed
     */
    modifier lockable() {
        if (functionLocked[msg.sig]) revert Dugo_FunctionLocked();
        _;
    }

    /**
     * @notice Current !praying epoch
     */
    function currentEpoch() public view returns (uint256) {
        return (block.timestamp - STARTED_AT) / EPOCH_DURATION;
    }

    /**
     * @notice Base rate of specified token
     * @param tokenId Token to return base rate for
     */
    function baseRate(uint256 tokenId) public pure returns (uint256) {
        if (tokenId >= TOTAL_SUPPLY) revert Dugo_TokenIdOutOfRange();

        return tokenId < GENESIS_SUPPLY ? GENESIS_BASE_RATE : MANANANGGAL_BASE_RATE;
    }

    /**
     * @notice Calculate the $DUGO generation rate at a specified epoch
     * @param _baseRate Base rate for a particular token
     * @param epoch Epoch to calculate rate for
     */
    function rate(uint256 _baseRate, uint256 epoch) internal pure returns (uint256) {
        unchecked {
            return epoch == 0 ? _baseRate : _baseRate / (epoch > 255 ? uint256(0) - 1 : 2 ** epoch);
        }
    }

    /**
     * @notice Last time $DUGO was claimed for a specified token
     * @param tokenId Token to return the last claim time for
     */
    function lastClaimedAt(uint256 tokenId) public view returns (uint256) {
        uint256 prayingStartedAt = ASWANG.prayingStartedAt(tokenId);

        if (prayingStartedAt == 0) return 0;

        return prayingStartedAt > _lastClaimedAt[tokenId] ? prayingStartedAt : _lastClaimedAt[tokenId];
    }

    /**
     * @notice The amount of currently claimable $DUGO for a specified token
     * @param tokenId Token to return the amount of claimable $DUGO for
     */
    function claimable(uint256 tokenId) public view returns (uint256) {
        uint256 claimFrom = lastClaimedAt(tokenId);

        if (claimFrom == 0) return 0;

        uint256 totalClaimable;
        uint256 _currentEpoch = currentEpoch();
        uint256 _baseRate = baseRate(tokenId);
        uint256 epochEndsAt = STARTED_AT + EPOCH_DURATION;

        for (uint256 i; i <= _currentEpoch;) {
            unchecked {
                if (epochEndsAt > claimFrom) {
                    totalClaimable += ((i == _currentEpoch ? block.timestamp : epochEndsAt) - claimFrom)
                        * rate(_baseRate, i)
                        / 1 days;

                    claimFrom = epochEndsAt;
                }

                epochEndsAt += EPOCH_DURATION;
                ++i;
            }
        }

        return totalClaimable;
    }

    /**
     * @notice Lower the maximum token supply
     * @param newMaxSupply New max supply
     */
    function lowerMaxSupply(uint256 newMaxSupply) external lockable onlyOwner  {
        if (newMaxSupply > maxSupply || newMaxSupply < totalClaimed) revert Dugo_InvalidMaxSupply();

        maxSupply = newMaxSupply;
    }

    /**
     * @notice ASWANG contract only function to burn a specified amount of $DUGO
     * @param account Account to burn $DUGO from
     * @param amount Amount of $DUGO to burn
     */
    function burn(address account, uint256 amount) public override {
        if (_msgSender() != address(ASWANG)) revert Dugo_NotAswangContract();

        _burn(account, amount);
    }

    /**
     * @notice ASWANG contract only function to claim $DUGO for a specified token
     * @param account Account that owns the token
     * @param tokenId Token to claim $DUGO for
     */
    function claim(address account, uint256 tokenId) public override {
        if (_msgSender() != address(ASWANG)) revert Dugo_NotAswangContract();

        mint(account, claimable(tokenId));
    }

    /**
     * @notice Claim $DUGO for specified tokens
     * @param tokenIds Tokens to claim $DUGO for
     */
    function claim(uint256[] calldata tokenIds) external {
        if (totalClaimed >= maxSupply) revert Dugo_MaxSupplyReached();

        uint256 totalClaimable;
        for (uint256 i; i < tokenIds.length;) {
            if (ASWANG.ownerOf(tokenIds[i]) != _msgSender()) revert Dugo_NotTokenOwner();

            totalClaimable += claimable(tokenIds[i]);
            _lastClaimedAt[tokenIds[i]] = block.timestamp;

            unchecked { ++i; }
        }

        mint(_msgSender(), totalClaimable);
    }

    /**
     * @notice Internal function to mint $DUGO to a specified owner
     * @param to Address to mint $DUGO to
     * @param amount Amount of $DUGO to mint
     */
    function mint(address to, uint256 amount) internal {
        if (totalClaimed < maxSupply) {
            _mint(
                to,
                totalClaimed + amount < maxSupply ? amount : maxSupply - totalClaimed
            );

            totalClaimed += amount;
        }
    }

    /**
     * @notice Mint a specified amount of $DUGO to specified receivers
     * @param receivers Receivers of the airdrop
     * @param amounts Amounts of $DUGO to airdrop for corresponding receivers
     */
    function airdrop(address[] calldata receivers, uint256[] calldata amounts) external lockable onlyOwner {
        for (uint256 i; i < receivers.length;) {
            _mint(receivers[i], amounts[i]);
            unchecked {
                totalClaimed += amounts[i];
                ++i;
            }
        }
    }

    /**
     * @notice Recover ASWANG tokens accidentally transferred directly to the contract
     * @param to Account to send the ASWANG to
     * @param tokenId ASWANG to recover
     */
    function recoveryTransfer(address to, uint256 tokenId) external lockable onlyOwner {
        ASWANG.transferFrom(address(this), to, tokenId);
    }

    /**
     * @notice Lock individual functions that are no longer needed. WARNING: THIS CANNOT BE UNDONE
     * @dev Only affects functions with the lockable modifier
     * @param id First 4 bytes of the calldata (i.e. function identifier)
     */
    function lockFunction(bytes4 id) public onlyOwner {
        functionLocked[id] = true;
    }
}