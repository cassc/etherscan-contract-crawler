// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IScales.sol";
import "./interfaces/ITestSamples.sol";

error FunctionLocked();
error InvalidAmount();

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
 * @title Mysterious Objects
 * @author Augminted Labs, LLC
 * @notice Redeem Test Samples. But something was leftover... what could it be?
 * @notice For more details see: https://medium.com/@AugmintedLabs/kaijukingz-p2e-ecosystem-dc9577ff8773
 */
contract MysteriousObjects is ERC1155, AccessControl, Ownable, Pausable, ReentrancyGuard {
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    uint256[4] public REWARDS = [500 ether, 250 ether, 100 ether, 50 ether];

    ITestSamples TestSamples;
    IScales Scales;

    mapping(bytes4 => bool) public functionLocked;

    constructor(
        string memory uri,
        address testSamples,
        address scales
    )
        ERC1155(uri)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        TestSamples = ITestSamples(testSamples);
        Scales = IScales(scales);

        _pause();
    }

    /**
     * @notice Modifier applied to functions that will be disabled when they're no longer needed
     */
    modifier lockable() {
        if (functionLocked[msg.sig]) revert FunctionLocked();
        _;
    }

    /**
     * @notice Set token URI for all tokens
     * @param uri Token URI to set for all tokens
     */
    function setURI(string calldata uri) external lockable onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(uri);
    }

    /**
     * @notice Set $SCALES token address
     * @param scales Address of $SCALES token contract
     */
    function setScales(address scales) external lockable onlyRole(DEFAULT_ADMIN_ROLE) {
        Scales = IScales(scales);
    }

    /**
     * @notice Redeem a specified amount of a specified token
     * @param id Token to redeem
     * @param amount Amount of tokens to redeem
     */
    function redeem(
        uint256 id,
        uint256 amount
    )
        public
        whenNotPaused
        nonReentrant
    {
        if (amount == 0) revert InvalidAmount();

        TestSamples.burn(_msgSender(), id, amount);
        Scales.credit(_msgSender(), amount * REWARDS[id]);
        _mint(_msgSender(), 0, amount, "");
    }

    /**
     * @notice Redeem specified amounts of specified tokens
     * @param ids Tokens to redeem
     * @param amounts Amounts of tokens to redeem
     */
    function redeemBatch(
        uint256[] calldata ids,
        uint256[] calldata amounts
    )
        public
        whenNotPaused
        nonReentrant
    {
        TestSamples.burnBatch(_msgSender(), ids, amounts);

        uint256 rewards;
        uint256 totalAmount;
        for (uint256 i; i < ids.length; ++i) {
            if (amounts[i] == 0) revert InvalidAmount();

            rewards += amounts[i] * REWARDS[ids[i]];
            totalAmount += amounts[i];
        }

        Scales.credit(_msgSender(), rewards);
        _mint(_msgSender(), 0, totalAmount, "");
    }

    /**
     * @notice Burn an amount of tokens from a specified owner
     * @param from Owner to burn from
     * @param amount Amount of tokens to burn
     */
    function burn(
        address from,
        uint256 amount
    )
        public
        lockable
        onlyRole(BURNER_ROLE)
    {
        _burn(from, 0, amount);
    }

    /**
     * @inheritdoc ERC1155
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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