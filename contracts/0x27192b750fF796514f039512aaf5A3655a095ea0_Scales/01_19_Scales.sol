// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IKaijuKingz.sol";
import "./interfaces/IScales.sol";
import "./interfaces/IRWaste.sol";

error Scales_FunctionLocked();
error Scales_IndexOutOfRange();
error Scales_InsufficientFunds();
error Scales_InvalidTokenAmount();
error Scales_NotApprovedForAll();
error Scales_NothingToWithdraw();
error Scales_SenderNotTokenOwner();
error Scales_TokenNotStranded();

/**                                     ..',,;;;;:::;;;,,'..
                                 .';:ccccc:::;;,,,,,;;;:::ccccc:;'.
                            .,:ccc:;'..                      ..';:ccc:,.
                        .':cc:,.                                    .,ccc:'.
                     .,clc,.                                            .,clc,.
                   'clc'                                                    'clc'
                .;ll,.                                                        .;ll;.
              .:ol.                                                              'co:.
             ;oc.                                                                  .co;
           'oo'                                                                      'lo'
         .cd;                                                                          ;dc.
        .ol.                                                                 .,.        .lo.
       ,dc.                                                               'cxKWK;         cd,
      ;d;                                                             .;oONWMMMMXc         ;d;
     ;d;                                                           'cxKWMMMMMMMMMXl.        ;x;
    ,x:            ;dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx0NMMMMMMMMMMMMMMNd.        :x,
   .dc           .lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.        cd.
   ld.          .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkl'         .dl
  ,x;          .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0d:.             ;x,
  oo.         .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc'.                .oo
 'x:          .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo;.                     :x'
 :x.           .xWMMMMMMMMMMM0occcccccccccccccccccccccccccccccccccccc:'                         .x:
 lo.            .oNMMMMMMMMMX;                                                                  .ol
.ol              .lXMMMMMMMWd.  ,dddddddddddddddo;.   .:dddddddddddddo,                          lo.
.dl                cXMMMMMM0,  'OMMMMMMMMMMMMMMNd.   .xWMMMMMMMMMMMMXo.                          ld.
.dl                 ;KMMMMNl   oWMMMMMMMMMMMMMXc.   ,OWMMMMMMMMMMMMK:                            ld.
 oo                  ,OWMMO.  ,KMMMMMMMMMMMMW0;   .cKMMMMMMMMMMMMWO,                             oo
 cd.                  'kWX:  .xWMMMMMMMMMMMWx.  .dKNMMMMMMMMMMMMNd.                             .dc
 ,x,                   .dd.  ;KMMMMMMMMMMMXo.  'kWMMMMMMMMMMMMMXl.                              ,x;
 .dc                     .   .,:loxOKNWMMK:   ;0WMMMMMMMMMMMMW0;                                cd.
  :d.                      ...      ..,:c'  .lXMMMMMMMMMMMMMWk'                                .d:
  .dl                      :OKOxoc:,..     .xNMMMMMMMMMMMMMNo.                                 cd.
   ;x,                      ;0MMMMWWXKOxoclOWMMMMMMMMMMMMMKc                                  ,x;
    cd.                      ,OWMMMMMMMMMMMMMMMMMMMMMMMMWO,                                  .dc
    .oo.                      .kWMMMMMMMMMMMMMMMMMMMMMMNx.                                  .oo.
     .oo.                      .xWMMMMMMMMMMMMMMMMMMMMXl.                                  .oo.
      .lo.                      .oNMMMMMMMMMMMMMMMMMW0;                                   .ol.
       .cd,                      .lXMMMMMMMMMMMMMMMWk'                                   ,dc.
         ;dc.                      :KMMMMMMMMMMMMNKo.                                  .cd;
          .lo,                      ;0WWWWWWWWWWKc.                                   'ol.
            ,ol.                     .,,,,,,,,,,.                                   .lo,
             .;oc.                                                                .co:.
               .;ol'                                                            'lo;.
                  ,ll:.                                                      .:ll,
                    .:ll;.                                                .;ll:.
                       .:ll:,.                                        .,:ll:.
                          .,:ccc;'.                              .';ccc:,.
                              .';cccc::;'...            ...';:ccccc;'.
                                    .',;::cc::cc::::::::::::;,..
                                              ........
 * @title Scales
 * @author Augminted Labs, LLC
 * @notice Staking contract allowing KAIJU to earn $SCALES
 * @notice For more details see: https://medium.com/@AugmintedLabs/kaijukingz-p2e-ecosystem-dc9577ff8773
 */
contract Scales is IScales, ERC20, ERC721Holder, AccessControl, Pausable, ReentrancyGuard {
    struct AccountInfo {
        uint16 shares;
        uint128 lastUpdate;
        uint256 stash;
    }

    event Stake(
        uint256 indexed tokenId,
        address indexed from
    );

    event Unstake(
        uint256 indexed tokenId,
        address indexed to
    );

    IKaijuKingz public immutable KAIJU;
    IRWaste public immutable RWASTE;
    uint256 public constant MAX_PER_TX = 25;
    uint256 public constant BASE_RATE = 5 ether;
    uint256 public constant GENESIS_BONUS = 2;
    bytes32 public constant SPENDER_ROLE = keccak256("SPENDER_ROLE");
    bytes32 public constant CREDITOR_ROLE = keccak256("CREDITOR_ROLE");
    bytes32 public constant RWASTE_MANAGER = keccak256("RWASTE_MANAGER");
    uint256 internal immutable KAIJU_GENESIS_SUPPLY;
    uint256 internal immutable KAIJU_MAX_SUPPLY;

    mapping(address => AccountInfo) public accountInfo;
    mapping(uint256 => address) public tokenOwners;
    mapping(bytes4 => bool) public functionLocked;

    constructor(
        address kaiju,
        uint256 genesisSupply,
        uint256 maxSupply,
        address rwaste
    )
        ERC20("Scales", "SCALES")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        KAIJU = IKaijuKingz(kaiju);
        KAIJU_GENESIS_SUPPLY = genesisSupply;
        KAIJU_MAX_SUPPLY = maxSupply;
        RWASTE = IRWaste(rwaste);

        _pause();
    }

    /**
     * @notice Modifier applied to functions that will be disabled when they're no longer needed
     */
    modifier lockable() {
        if (functionLocked[msg.sig]) revert Scales_FunctionLocked();
        _;
    }

    /**
     * @notice Get the owner of a specified KAIJU
     * @param tokenId KAIJU to return the owner of
     * @return address Owner of the specified KAIJU
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        return tokenOwners[tokenId];
    }

    /**
     * @notice Get list of KAIJU tokens by account
     * @param account Address of the KAIJU owner
     * @return uint256[] The KAIJU tokens owned by the specified account
     */
    function getAllOwned(address account) public view returns (uint256[] memory) {
        uint256[] memory indexMap = new uint256[](KAIJU_MAX_SUPPLY);

        uint256 index;
        for (uint256 tokenId; tokenId < KAIJU_MAX_SUPPLY; ++tokenId) {
            if (tokenOwners[tokenId] == account) {
                indexMap[index] = tokenId;
                ++index;
            }
        }

        uint256[] memory tokenIds = new uint256[](index);
        for (uint256 i; i < index; ++i) {
            tokenIds[i] = indexMap[i];
        }

        return tokenIds;
    }

    /**
     * @notice Get amount of spendable $SCALES
     * @param account Address to return spendable $SCALES for
     * @return uint256 Amount of spendable $SCALES
     */
    function getSpendable(address account) public view override returns (uint256) {
        return accountInfo[account].stash + _getPending(account);
    }

    /**
     * @notice Get pending $SCALES rewards for a specified account calculated based on their staked KAIJU tokens
     * @param account Address to return the pending $SCALES rewards of
     * @return uint256 Amount of $SCALES a specified account has pending
     */
    function _getPending(address account) internal view returns (uint256) {
        AccountInfo memory _accountInfo = accountInfo[account];

        return _accountInfo.shares
            * BASE_RATE
            * (block.timestamp - _accountInfo.lastUpdate)
            / 1 days;
    }

    /**
     * @notice Get $SCALES stash of a specified account
     * @param account Address of the account to get the $SCALES stash of
     */
    function stash(address account) public view returns (uint256) {
        return accountInfo[account].stash;
    }

    /**
     * @notice Move pending $SCALES rewards to account stash and reset the timer
     * @dev This should be called before any operation that changes values used in _getPending(address)
     * @param account Address to update the rewards of
     */
    function _updateStash(address account) internal {
        accountInfo[_msgSender()].stash += _getPending(account);
        accountInfo[_msgSender()].lastUpdate = uint128(block.timestamp);
    }

    /**
     * @notice Withdraw available $SCALES
     */
    function withdraw() public whenNotPaused nonReentrant {
        uint256 spendable = getSpendable(_msgSender());

        if (spendable == 0) revert Scales_NothingToWithdraw();

        accountInfo[_msgSender()].stash = 0;
        accountInfo[_msgSender()].lastUpdate = uint128(block.timestamp);

        _mint(_msgSender(), spendable);
    }

    /**
     * @notice Withdraw a specified amount of $SCALES
     * @param amount Amount of $SCALES to withdraw
     */
    function withdrawSome(uint256 amount) public whenNotPaused nonReentrant {
        uint256 spendable = getSpendable(_msgSender());

        if (spendable < amount) revert Scales_InsufficientFunds();

        accountInfo[_msgSender()].stash = spendable - amount;
        accountInfo[_msgSender()].lastUpdate = uint128(block.timestamp);

        _mint(_msgSender(), amount);
    }

    /**
     * @notice Deposit $SCALES
     * @param amount Amount of $SCALES to deposit
     */
    function deposit(uint256 amount) public whenNotPaused {
        _burn(_msgSender(), amount);

        accountInfo[_msgSender()].stash += amount;
    }

    /**
     * @notice Stake KAIJU tokens and start earning $SCALES
     * @param tokenIds KAIJU tokens to stake
     */
    function stake(uint256[] memory tokenIds) public whenNotPaused nonReentrant {
        if (tokenIds.length == 0 || tokenIds.length > MAX_PER_TX) revert Scales_InvalidTokenAmount();

        _updateStash(_msgSender());

        uint16 genesisCount;
        for (uint256 i; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];

            KAIJU.safeTransferFrom(_msgSender(), address(this), tokenId);
            tokenOwners[tokenId] = _msgSender();

            if (tokenId < KAIJU_GENESIS_SUPPLY) ++genesisCount;

            emit Stake(tokenId, _msgSender());
        }

        accountInfo[_msgSender()].shares += uint16(tokenIds.length + (genesisCount * GENESIS_BONUS));
    }

    /**
     * @notice Unstake KAIJU tokens
     * @param tokenIds KAIJU tokens to unstake
     */
    function unstake(uint256[] calldata tokenIds) public nonReentrant {
        if (tokenIds.length == 0 || tokenIds.length > MAX_PER_TX) revert Scales_InvalidTokenAmount();

        _updateStash(_msgSender());

        uint16 genesisCount;
        for (uint256 i; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];

            if (tokenOwners[tokenId] != _msgSender()) revert Scales_SenderNotTokenOwner();

            KAIJU.safeTransferFrom(address(this), _msgSender(), tokenId);
            tokenOwners[tokenId] = address(0);

            if (tokenId < KAIJU_GENESIS_SUPPLY) ++genesisCount;

            emit Unstake(tokenId, _msgSender());
        }

        accountInfo[_msgSender()].shares -= uint16(tokenIds.length + (genesisCount * GENESIS_BONUS));
    }

    /**
     * @notice Spend a specified amount of $SCALES
     * @dev Used only by contracts for extending token utility
     * @param from Account to spend $SCALES from
     * @param amount Amount of $SCALES to spend
     */
    function spend(address from, uint256 amount) public override onlyRole(SPENDER_ROLE) {
        if (amount > getSpendable(from)) revert Scales_InsufficientFunds();

        _updateStash(from);

        accountInfo[from].stash -= amount;
    }

    /**
     * @notice Credit a specified amount of $SCALES
     * @dev Used only by contracts for extending token utility
     * @param to Account to credit $SCALES to
     * @param amount Amount of $SCALES to credit
     */
    function credit(address to, uint256 amount) public override onlyRole(CREDITOR_ROLE) {
        accountInfo[to].stash += amount;
    }

    /**
     * @notice Claim $RWASTE rewards on behalf of the staking contract
     */
    function claimRWaste() public lockable onlyRole(RWASTE_MANAGER) {
        RWASTE.claimReward();
    }

    /**
     * @notice Approve an address or contract to spend $RWASTE earned by the staking contract
     * @param spender Address to authorize for spending $RWASTE
     * @param amount Amount of $RWASTE spender is allowed to spend
     * @return bool If the approval was successful
     */
    function approveRWaste(address spender, uint256 amount)
        public
        lockable
        onlyRole(RWASTE_MANAGER)
        returns (bool)
    {
        return RWASTE.approve(spender, amount);
    }

    /**
     * @notice Recover KAIJU tokens accidentally transferred directly to the contract
     * @dev Only available to owner if internal owner mapping was not updated
     * @param to Account to send the KAIJU to
     * @param tokenId KAIJU to recover
     */
    function recoveryTransfer(address to, uint256 tokenId) external lockable onlyRole(DEFAULT_ADMIN_ROLE) {
        if (tokenOwners[tokenId] != address(0)) revert Scales_TokenNotStranded();

        KAIJU.transferFrom(address(this), to, tokenId);
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