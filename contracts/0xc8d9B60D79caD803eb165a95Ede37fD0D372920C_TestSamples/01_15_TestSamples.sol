//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

error TestSamples_FunctionLocked();
error TestSamples_InvalidSignature();
error TestSamples_InvalidTokenId();
error TestSamples_SignatureAlreadyUsed();

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
 * @title TestSamples
 * @author Augminted Labs, LLC
 * @notice Airdrop for all the homies
 * @notice For more details see: https://medium.com/@AugmintedLabs/kaijukingz-p2e-ecosystem-dc9577ff8773
 */
contract TestSamples is ERC1155Supply, AccessControl, ReentrancyGuard {
    using ECDSA for bytes32;

    bytes32 public constant AIRDROPPER_ROLE = keccak256("AIRDROPPER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    uint256 public constant MAX_TOKEN_ID = 3;

    address public signer;
    mapping(bytes => bool) public signatureUsed;
    mapping(bytes4 => bool) public functionLocked;

    constructor(string memory uri) ERC1155(uri) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @notice Modifier applied to functions that will be disabled when they're no longer needed
     */
    modifier lockable() {
        if (functionLocked[msg.sig]) revert TestSamples_FunctionLocked();
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
     * @notice Set signature signing address
     * @param _signer address of account used to create mint signatures
     */
    function setSigner(address _signer) external lockable onlyRole(DEFAULT_ADMIN_ROLE) {
        signer = _signer;
    }

    /**
     * @notice Airdrop a specified amount of tokens to a set of receivers
     * @param receivers Addresses of the receivers of the airdrop
     * @param amounts Amount of the specified token to airdrop to the corresponding receiver
     * @param tokenId Token ID to airdrop
     */
    function airdrop(
        address[] calldata receivers,
        uint256[] calldata amounts,
        uint256 tokenId
    )
        public
        lockable
        onlyRole(AIRDROPPER_ROLE)
    {
        if (tokenId > MAX_TOKEN_ID) revert TestSamples_InvalidTokenId();

        for (uint256 i = 0; i < receivers.length; i++) {
            _mint(receivers[i], tokenId, amounts[i], "");
        }
    }

    /**
     * @notice Allow participants to claim a token
     * @param signature Created by signer account for a specific address
     */
    function claim(bytes calldata signature) public lockable nonReentrant {
        if (signatureUsed[signature]) revert TestSamples_SignatureAlreadyUsed();

        if (signer != ECDSA.recover(
            ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_msgSender()))),
            signature
        )) revert TestSamples_InvalidSignature();

        signatureUsed[signature] = true;

        _mint(_msgSender(), MAX_TOKEN_ID, 1, "");
    }

    /**
     * @notice Burn an amount of specified tokens from a specified owner
     * @param from Owner to burn from
     * @param id Token to burn
     * @param amount Amount of specified tokens to burn
     */
    function burn(
        address from,
        uint256 id,
        uint256 amount
    )
        public
        lockable
        onlyRole(BURNER_ROLE)
    {
        _burn(from, id, amount);
    }

    /**
     * @notice Burn an amount of specified tokens from a specified owner
     * @param from Owner to burn from
     * @param ids Tokens to burn
     * @param amounts Amounts of tokens to burn
     */
    function burnBatch(
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts
    )
        public
        lockable
        onlyRole(BURNER_ROLE)
    {
        _burnBatch(from, ids, amounts);
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
     * @notice Lock individual functions that are no longer needed
     * @dev Only affects functions with the lockable modifier
     * @param id First 4 bytes of the calldata (i.e. function identifier)
     */
    function lockFunction(bytes4 id) external onlyRole(DEFAULT_ADMIN_ROLE) {
        functionLocked[id] = true;
    }
}