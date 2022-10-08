// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./interfaces/IKaijuKingz.sol";
import "./interfaces/IRWaste.sol";
import "./interfaces/IScales.sol";
import "./interfaces/IScientists.sol";

error KaijuSynthesizer_AllKaijusMinted();

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
 * @title KaijuSynthesizer
 * @author Augminted Labs, LLC
 * @notice Synthesize baby kaijus into the wallets of eligible scientists
 */
contract KaijuSynthesizer is IERC721Receiver, AccessControl, VRFConsumerBaseV2 {
    struct RequestConfig {
        bytes32 keyHash;
        uint64 subId;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
    }

    event KaijuSynthesized(
        address indexed receiver,
        uint256 indexed id,
        uint256 indexed seed
    );

    bytes32 public constant SYNTHESIZER_ROLE = keccak256("SYNTHESIZER_ROLE");

    IKaijuKingz internal immutable KAIJU;
    IRWaste internal immutable RWASTE;
    IScales internal immutable SCALES;
    IScientists internal immutable SCIENTISTS;
    VRFCoordinatorV2Interface internal immutable COORDINATOR;

    uint256 internal constant KAIJU_MAX_SUPPLY = 9999;
    uint256 internal constant BURN_AMOUNT = 3000 ether;
    uint256 internal constant FUSION_COST = 750 ether;

    RequestConfig public requestConfig;
    mapping(uint256 => uint256) public requestIdToTokenId;

    constructor(
        address admin,
        IKaijuKingz kaiju,
        IRWaste rwaste,
        IScales scales,
        IScientists scientists,
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subId
    )
        VRFConsumerBaseV2(vrfCoordinator)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(SYNTHESIZER_ROLE, msg.sender);

        KAIJU = kaiju;
        RWASTE = rwaste;
        SCALES = scales;
        SCIENTISTS = scientists;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);

        requestConfig = RequestConfig({
            keyHash: keyHash,
            subId: subId,
            callbackGasLimit: 250000,
            requestConfirmations: 3
        });
    }

    /**
     * @notice Set configuration data for Chainlink VRF
     * @dev https://docs.chain.link/docs/chainlink-vrf/
     * @param _requestConfig Struct with updated configuration values
     */
    function setRequestConfig(RequestConfig calldata _requestConfig) external onlyRole(DEFAULT_ADMIN_ROLE) {
        requestConfig = _requestConfig;
    }

    /**
     * @notice Synthesize a new KAIJU, burn leftover $RWASTE, and transfer to a random eligible SCIENTIST
     * @param parent1 First KAIJU parent to use for fusion
     * @param parent2 Second KAIJU parent to use for fusion
     * @param claim Should $RWASTE be claimed by the staking contract
     */
    function synthesize(uint256 parent1, uint256 parent2, bool claim) external onlyRole(SYNTHESIZER_ROLE) {
        if (KAIJU.totalSupply() == KAIJU.maxSupply()) revert KaijuSynthesizer_AllKaijusMinted();

        if (claim) SCALES.claimRWaste();

        RWASTE.burn(address(SCALES), BURN_AMOUNT);
        RWASTE.transferFrom(address(SCALES), address(this), FUSION_COST);

        KAIJU.fusion(parent1, parent2);

        requestIdToTokenId[COORDINATOR.requestRandomWords(
            requestConfig.keyHash,
            requestConfig.subId,
            requestConfig.requestConfirmations,
            requestConfig.callbackGasLimit,
            1 // number of random words
        )] = KAIJU.maxGenCount() + KAIJU.babyCount() - 1;
    }

    /**
     * @notice Recover KAIJU token
     * @param to Account to send the KAIJU to
     * @param tokenId KAIJU to recover
     */
    function recover(address to, uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        KAIJU.transferFrom(address(this), to, tokenId);
    }

    /**
     * @inheritdoc IERC721Receiver
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @inheritdoc VRFConsumerBaseV2
     * @notice Transfer KAIJU to a random eligible SCIENTIST
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        address receiver = SCIENTISTS.getRandomPaidScientistOwner(randomWords[0]);

        KAIJU.transferFrom(
            address(this),
            receiver,
            requestIdToTokenId[requestId]
        );

        emit KaijuSynthesized(
            receiver,
            requestIdToTokenId[requestId],
            randomWords[0]
        );
    }
}