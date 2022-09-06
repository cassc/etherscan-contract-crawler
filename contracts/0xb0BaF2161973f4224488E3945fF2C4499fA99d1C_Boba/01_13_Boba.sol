// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error Boba_FunctionLocked();
error Boba_InvalidTokenAmount();
error Boba_SenderNotTokenOwner();
error Boba_TokenNotStranded();

/**
 *                                         ..',;;::::;;,'..
 *                                   .':oxkOOOOOkkkkkkOOOOOkxl:'.
 *                               .,lxO0kxdddddxxxxxxxxxxdddddxk0Oxl,.
 *                             ,oO0kdoodkOOOkxollcccclloxkO0Okdoodk0Oo,.
 *                          .ckKkolokKKxl;..              ..,cdO0kolokKOc.
 *                        .l0KdclkXMMWKkxol:,..                .'lOKklcdK0l.
 *                       :OKd:l0WMMMMMMMMMMMWNKko:'..              ,dK0l:dK0:
 *                     .dXk::OWMMMMMMMMMMMMMMMMMMMNX0d:.             .dKOc:kXx.
 *                    ,OXo,oNMMMMMMMMMMMMMMMMMMMMMMMMMWKx;.            ,kXd,lKO,
 *                   ;0Kc,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l.           .oXk,cK0;
 *                  ,0K:'kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo.           lXO,:K0,
 *                 .kNl.dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKl.         .oNx.lNk.
 *                 lNk.:XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO,         .kNc.xNl
 *                .OX:.kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl.        :XO.:XO.
 *                :XO.,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.       .OX;.OX:
 *                lNx.:NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.      .xNc.dNl
 *                oWo.cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.     .xNl.oWo
 *                oWd.:XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl     .kNc.dWo
 *                cNk.'0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;    '0K,.kNc
 *                ,KK,.dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.   lNx.,KK,
 *                .dNo.,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:  ,0K;.oNd.
 *                 ,KK; cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd..kXl.,KK,
 *                  cXO..lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0lkXo..kXl
 *                  .oXk..cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXl..xXo.
 *                   .oXO' ;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0; 'kXo.
 *                     cK0:..lKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo..:0Kc
 *                      'kXx' .oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo' .dXO,
 *                       .:OKd' .:kXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkc.   .kNk.
 *                         .cOKx:...cx0NWMMMMMMMMMMMMMMMMMMMMWN0xc'       .oX0:
 *                           .;d00d:...':oxOKXNWWWWMWWWNXKOkdol::clodxxkkkkOXMNd.
 *                              .:dO0ko:'.....',;;;;;;:loddxOOOOkxdolc:;;;;;:l0Wd.
 *                                 .'cdkO0Oo.    .;clxO0Oxoc;'..            .l0K:
 *                                      .lXK:.:dO0Okdl;..               .,lk0Ol.
 *                                       :XN00Od:.                 .':ok00kl,.
 *                                       lWNx,.             ..,:ldkOOkdc,.
 *                                       cXKo:;,,,;;;:clodkOOOOkdl:'.
 *                                        ,lxkkOOOkkkxxdoc:;'..
 * @author Augminted Labs, LLC
 */
contract Boba is ERC20, AccessControl, Pausable, ReentrancyGuard {
    event Stake(
        uint256 indexed tokenId,
        address indexed from
    );

    event Unstake(
        uint256 indexed tokenId,
        address indexed to
    );

    IERC721 public immutable ODD;
    uint256 internal immutable ODD_MAX_SUPPLY;
    uint256 public constant MAX_PER_TX = 25;
    uint256 public constant BASE_RATE = 2 ether;
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    mapping(address => uint256) private _stash;
    mapping(address => uint256) public amountStaked;
    mapping(address => uint256) public lastUpdated;
    mapping(address => uint256) public rateModifier;
    mapping(uint256 => address) public tokenOwners;
    mapping(bytes4 => bool) public functionLocked;

    constructor(
        IERC721 odd,
        uint256 maxSupply
    )
        ERC20("Boba", "BOBA")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        ODD = odd;
        ODD_MAX_SUPPLY = maxSupply;

        _pause();
    }

    /**
     * @notice Modifier applied to functions that will be disabled when they're no longer needed
     */
    modifier lockable() {
        if (functionLocked[msg.sig]) revert Boba_FunctionLocked();
        _;
    }

    /**
     * @notice Get the owner of a specified ODD
     * @param tokenId ODD to return the owner of
     * @return address Owner of the specified ODD
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        return tokenOwners[tokenId];
    }

    /**
     * @notice Get list of ODD tokens by account
     * @param account Address of the ODD owner
     * @return uint256[] The ODD tokens owned by the specified account
     */
    function getAllOwned(address account) public view returns (uint256[] memory) {
        uint256[] memory indexMap = new uint256[](ODD_MAX_SUPPLY);

        uint256 index;
        for (uint256 tokenId; tokenId < ODD_MAX_SUPPLY;) {
            if (tokenOwners[tokenId] == account) {
                indexMap[index] = tokenId;
                unchecked { ++index; }
            }

            unchecked { ++tokenId; }
        }

        uint256[] memory tokenIds = new uint256[](index);
        for (uint256 i; i < index;) {
            tokenIds[i] = indexMap[i];
            unchecked { ++i; }
        }

        return tokenIds;
    }

    /**
     * @notice Get pending $BOBA rewards for a specified account
     * @param account Account to return the pending $BOBA rewards of
     */
    function getPending(address account) public view returns (uint256) {
        return _stash[account] + _getEarned(account);
    }

    /**
     * @notice Get earned $BOBA rewards for a specified account calculated based on their staked ODD tokens
     * @param account Address to return the earned $BOBA rewards of
     * @return uint256 Amount of $BOBA a specified account has earned since last update
     */
    function _getEarned(address account) internal view returns (uint256) {
        unchecked {
            return amountStaked[account]
                * (BASE_RATE + rateModifier[account])
                * (block.timestamp - lastUpdated[account])
                / 1 days;
        }
    }

    /**
     * @notice Move earned $BOBA rewards to account stash and reset the timer
     * @dev This should be called BEFORE any operation that changes values used in `_getEarned(address)`
     * @param account Address to update the rewards of
     */
    function _updateStash(address account) internal {
        _stash[account] += _getEarned(account);
        lastUpdated[account] = block.timestamp;
    }

    /**
     * @notice Update the rate a which an address earns $BOBA rewards
     * @dev This should be called AFTER any operation that change an account's `amountStaked` value
     * @param account Address to update the rate modifier of
     */
    function _updateRateModifier(address account) internal {
        uint256 _rateModifier = rateModifier[account];
        uint256 _amountStaked = amountStaked[account];

        if (_amountStaked < 20 && _rateModifier != 0) rateModifier[account] = 0;
        else if (_amountStaked > 19 && _amountStaked < 51 && _rateModifier != 1 ether) rateModifier[account] = 1 ether;
        else if (_amountStaked > 50 && _rateModifier != 3 ether) rateModifier[account] = 3 ether;
    }

    /**
     * @notice Withdraw available $BOBA
     */
    function withdraw() external whenNotPaused nonReentrant {
        _mint(_msgSender(), getPending(_msgSender()));

        _stash[_msgSender()] = 0;
        lastUpdated[_msgSender()] = block.timestamp;
    }

    /**
     * @notice Stake ODD tokens and start earning $BOBA
     * @param tokenIds ODD tokens to stake
     */
    function stake(uint256[] memory tokenIds) external whenNotPaused nonReentrant {
        if (tokenIds.length == 0 || tokenIds.length > MAX_PER_TX) revert Boba_InvalidTokenAmount();

        _updateStash(_msgSender());

        for (uint256 i; i < tokenIds.length;) {
            uint256 tokenId = tokenIds[i];

            ODD.transferFrom(_msgSender(), address(this), tokenId);
            tokenOwners[tokenId] = _msgSender();

            emit Stake(tokenId, _msgSender());

            unchecked { ++i; }
        }

        unchecked { amountStaked[_msgSender()] += tokenIds.length; }

        _updateRateModifier(_msgSender());
    }

    /**
     * @notice Unstake ODD tokens
     * @param tokenIds ODD tokens to unstake
     */
    function unstake(uint256[] calldata tokenIds) external nonReentrant {
        if (tokenIds.length == 0 || tokenIds.length > MAX_PER_TX) revert Boba_InvalidTokenAmount();

        _updateStash(_msgSender());

        for (uint256 i; i < tokenIds.length;) {
            uint256 tokenId = tokenIds[i];

            if (tokenOwners[tokenId] != _msgSender()) revert Boba_SenderNotTokenOwner();

            ODD.transferFrom(address(this), _msgSender(), tokenId);
            tokenOwners[tokenId] = address(0);

            emit Unstake(tokenId, _msgSender());

            unchecked { ++i; }
        }

        unchecked { amountStaked[_msgSender()] -= tokenIds.length; }

        _updateRateModifier(_msgSender());
    }

    /**
     * @notice Burn a specified amount of $BOBA from a specified address
     * @dev Allows for the contract to be extended with less cost to user, if not needed this function can be locked
     * @param account Address to burn $BOBA from
     * @param amount Amount of $BOBA to burn
     */
    function burn(address account, uint256 amount) external lockable onlyRole(BURNER_ROLE) {
        _burn(account, amount);
    }

    /**
     * @notice Recover a token accidentally transferred directly to the contract
     * @dev Only available for ODD tokens if internal owner mapping was not updated
     * @param to Account to send the token to
     * @param token Contract to recover from
     * @param tokenId Token to recover
     */
    function recoveryTransfer(
        address to,
        IERC721 token,
        uint256 tokenId
    )
        external
        lockable
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (token == ODD && tokenOwners[tokenId] != address(0)) revert Boba_TokenNotStranded();

        token.transferFrom(address(this), to, tokenId);
    }

    /**
     * @notice Flip paused state to temporarily disable minting
     */
    function flipPaused() external lockable onlyRole(DEFAULT_ADMIN_ROLE) {
        paused() ? _unpause() : _pause();
    }

    /**
     * @notice Lock individual functions that are no longer needed
     * @dev Only affects functions with the lockable modifier
     * @param id First 4 bytes of the calldata (i.e. function identifier)
     */
    function lockFunction(bytes4 id) external onlyRole(DEFAULT_ADMIN_ROLE) {
        functionLocked[id] = true;
    }
}