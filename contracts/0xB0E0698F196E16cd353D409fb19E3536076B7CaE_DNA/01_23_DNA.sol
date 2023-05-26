// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.11;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IMutants.sol";
import "./interfaces/IRWaste.sol";
import "./interfaces/IScales.sol";
import "./interfaces/IScientists.sol";

error DNA_BatchAlreadySeeded();
error DNA_BatchNotSeeded();
error DNA_CoolDownOngoing();
error DNA_ExceedsMaximumTier();
error DNA_ExtractionOngoing();
error DNA_FunctionLocked();
error DNA_IndexOutOfRange();
error DNA_IncorrectValue();
error DNA_NothingToReveal();
error DNA_SenderNotAllowed();
error DNA_SenderNotTokenOwner();
error DNA_ValueOutOfRange();

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
 * @title DNA
 * @author Augminted Labs, LLC
 * @notice DNA is earned using MUTANT, $SCALES, and optional $RWASTE
 * @notice For more details see: https://medium.com/@AugmintedLabs/kaijukingz-p2e-ecosystem-dc9577ff8773
 */
contract DNA is ERC1155, Ownable, AccessControl, ReentrancyGuard, VRFConsumerBaseV2 {
    struct Contracts {
        IMutants Mutants;
        IRWaste RWaste;
        IScales Scales;
        IScientists Scientists;
    }

    struct RequestConfig {
        bytes32 keyHash;
        uint64 subId;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
    }

    struct VRFFundingConfig {
        uint256 fee;
        bool userFunded;
    }

    struct FreeBoostConfig {
        uint16 boostId;
        uint64 minimumBatchSize;
    }

    struct MutantInfo {
        uint64 batchId;
        uint128 coolDownStarted;
        uint16 boostId;
        uint8 tier;
        bool extractionOngoing;
    }

    struct Batch {
        uint256 size;
        uint256 seed;
    }

    struct Boost {
        uint256 cost;
        uint256[4] rarities;
    }

    struct ExtractionResults {
        uint256 tokenId;
        uint16 criticality;
        bool success;
    }

    event BatchSeeded(
        uint256 indexed batchId
    );

    event DNAStolen(
        address indexed receiver,
        uint256 indexed tokenId
    );

    event ExtractionComplete(
        uint256 indexed mutantId,
        uint64 indexed batchId,
        uint16 indexed boostId,
        ExtractionResults results
    );

    VRFCoordinatorV2Interface internal immutable COORDINATOR;
    bytes32 public constant CONTRACT_MANAGER_ROLE = keccak256("CONTRACT_OWNER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant CRITICALITY_ENTROPY = keccak256("CRITICALITY");
    bytes32 public constant TOKEN_RARITY_ENTROPY = keccak256("TOKEN_RARITY");
    bytes32 public constant TOKEN_ELEMENT_ENTROPY = keccak256("TOKEN_ELEMENT");
    bytes32 public constant SCIENTIST_ENTROPY = keccak256("SCIENTIST");
    uint256 public constant MAX_MUTANT_TIER = 6;

    Contracts public contracts;
    RequestConfig public requestConfig;
    VRFFundingConfig public vrfFundingConfig;
    FreeBoostConfig public freeBoostConfig;
    uint256 public mutantUpgradeCost = 150 ether;
    uint256 public extractionCost = 600 ether;
    uint256 public coolDown = 14 days;
    Boost[] public boosts;
    uint64 public batchId;
    mapping(uint64 => Batch) public batch;
    mapping(uint256 => MutantInfo) public mutantInfo;
    mapping(uint256 => uint64) public requestIdToBatchId;
    mapping(bytes4 => bool) public functionLocked;

    constructor(
        string memory uri,
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subId
    )
        ERC1155(uri)
        VRFConsumerBaseV2(vrfCoordinator)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);

        requestConfig = RequestConfig({
            keyHash: keyHash,
            subId: subId,
            callbackGasLimit: 2500000,
            requestConfirmations: 3
        });

        freeBoostConfig = FreeBoostConfig({
            boostId: 2,
            minimumBatchSize: 20
        });

        boosts.push(Boost({ cost: 0 ether, rarities: [uint256(1), 5, 20, 50] }));       // default (1%, 4%, 15%, 30%, 50%)
        boosts.push(Boost({ cost: 200 ether, rarities: [uint256(2), 10, 35, 80] }));    // basic boost (2%, 8%, 25%, 45%, 20%)
        boosts.push(Boost({ cost: 100 ether, rarities: [uint256(1), 5, 20, 100] }));    // no commons (1%, 4%, 15%, 80%, 0%)
        boosts.push(Boost({ cost: 75 ether, rarities: [uint256(0), 0, 50, 50] }));      // 50/50 rare/common (0%, 0%, 50%, 0%, 50%)
        boosts.push(Boost({ cost: 500 ether, rarities: [uint256(20), 40, 60, 80] }));   // flattened (20%, 20%, 20%, 20%, 20%)
        boosts.push(Boost({ cost: 750 ether, rarities: [uint256(0), 100, 100, 100] })); // always epic (0%, 100%, 0%, 0%, 0%)
    }

    /**
     * @notice Modifier applied to functions that will be disabled when they're no longer needed
     */
    modifier lockable() {
        if (functionLocked[msg.sig]) revert DNA_FunctionLocked();
        _;
    }

    /**
     * @notice Get specified boost cost
     * @param index Of boost cost to return
     * @return uint256 Cost of the boost
     */
    function getBoostCost(uint256 index) public view returns (uint256) {
        if (index >= boosts.length) revert DNA_IndexOutOfRange();

        return boosts[index].cost;
    }

    /**
     * @notice Get specified boost rarities
     * @param index Of boost rarities to return
     * @return uint256 Rarities of the boost
     */
    function getBoostRarities(uint256 index) public view returns (uint256[4] memory) {
        if (index >= boosts.length) revert DNA_IndexOutOfRange();

        return boosts[index].rarities;
    }

    /**
     * @notice If the specified MUTANT is available for DNA extraction
     * @param mutantId MUTANT to query cool down status of
     * @return bool If MUTANT is available for DNA extraction
     */
    function isCooledDown(uint256 mutantId) public view returns (bool) {
        return block.timestamp - mutantInfo[mutantId].coolDownStarted > coolDown;
    }

    /**
     * @notice Set external contracts used by the DNA contract
     * @param _contracts Struct with updated contract addresses
     */
    function setContracts(Contracts calldata _contracts) external lockable onlyRole(DEFAULT_ADMIN_ROLE) {
        contracts = _contracts;
    }

    /**
     * @notice Set configuration for controlling the free boost functionality
     * @param _freeBoostConfig Struct with updated configuration values
     */
    function setFreeBoostConfig(FreeBoostConfig calldata _freeBoostConfig) external lockable onlyRole(DEFAULT_ADMIN_ROLE) {
        freeBoostConfig = _freeBoostConfig;
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
     * @notice Set configuration for controlling source of funding for VRF
     * @param _vrfFundingConfig Struct with updated configuration values
     */
    function setVRFFundingConfig(VRFFundingConfig calldata _vrfFundingConfig) external onlyRole(DEFAULT_ADMIN_ROLE) {
        vrfFundingConfig = _vrfFundingConfig;
    }

    /**
     * @notice Set token URI for all tokens
     * @param uri Token URI to set for all tokens
     */
    function setURI(string calldata uri) external lockable onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(uri);
    }

    /**
     * @notice Set boost values for an existing boost
     * @dev Boosts can be neutralized by setting them to default values
     * @param boostId Boost to set the value of
     * @param boost Boost values to set
     */
    function setBoost(uint256 boostId, Boost calldata boost) public lockable onlyRole(CONTRACT_MANAGER_ROLE) {
        if (boostId >= boosts.length || boostId == 0) revert DNA_ValueOutOfRange();

        boosts[boostId] = boost;
    }

    /**
     * @notice Add a new boost option for DNA extraction
     * @param boost New boost to be added
     */
    function addBoost(Boost calldata boost) public lockable onlyRole(CONTRACT_MANAGER_ROLE) {
        boosts.push(boost);
    }

    /**
     * @notice Set a new DNA extraction cost
     * @dev WARNING: Calling this will create a race condition for the current batch in which
     * @dev          the amount of stolen/refunded $SCALES will be calculated based on the new
     * @dev          value despite already having charged for extraction based on the old value.
     * @param cost Cost of DNA extraction
     */
    function setExtractionCost(uint256 cost) public lockable onlyRole(CONTRACT_MANAGER_ROLE) {
        extractionCost = cost;
    }

    /**
     * @notice Set a new MUTANT upgrade cost
     * @param cost Cost of upgrading a MUTANT by a single tier
     */
    function setMutantUpgradeCost(uint256 cost) public lockable onlyRole(CONTRACT_MANAGER_ROLE) {
        mutantUpgradeCost = cost;
    }

    /**
     * @notice Set a new duration for the cool down period applied after a successful DNA extraction
     * @param time New cool down duration
     */
    function setCoolDown(uint256 time) public lockable onlyRole(CONTRACT_MANAGER_ROLE) {
        coolDown = time;
    }

    /**
     * @notice Spend $SCALES to upgrade a MUTANT and increase chances of DNA extraction success
     * @dev This function is used in favor of the one on the MUTANT contract to improve gas efficiency
     * @param tokenId MUTANT to apply upgrades to
     * @param tiers Amount of tiers to upgrade
     */
    function upgradeMutant(uint256 tokenId, uint8 tiers) public {
        if (_msgSender() != contracts.Mutants.ownerOf(tokenId)) revert DNA_SenderNotTokenOwner();
        if (mutantInfo[tokenId].tier + tiers > MAX_MUTANT_TIER) revert DNA_ExceedsMaximumTier();
        if (mutantInfo[tokenId].extractionOngoing) revert DNA_ExtractionOngoing();

        contracts.Scales.spend(_msgSender(), mutantUpgradeCost * tiers);

        mutantInfo[tokenId].tier += tiers;
    }

    /**
     * @notice Run the extraction process for a MUTANT and queued extractions in this batch
     * @param mutantId MUTANT to run the extraction for
     * @param boostId Boost to apply to the extraction process
     */
    function runExtraction(uint256 mutantId, uint16 boostId) public payable nonReentrant {
        if (vrfFundingConfig.userFunded && msg.value != vrfFundingConfig.fee) revert DNA_IncorrectValue();

        bool freeBoost = batch[batchId].size > freeBoostConfig.minimumBatchSize;

        _queueExtraction(mutantId, freeBoost ? freeBoostConfig.boostId : boostId, freeBoost);
        _seedBatch(batchId);
    }

    /**
     * @notice Queue a MUTANT for DNA extraction
     * @param mutantId MUTANT to queue for extraction
     * @param boostId Boost to apply to the extraction process
     */
    function queueExtraction(uint256 mutantId, uint16 boostId) public nonReentrant {
        _queueExtraction(mutantId, boostId, false);
    }

    /**
     * @notice Queue a MUTANT for DNA extraction
     * @param mutantId MUTANT to queue for extraction
     * @param boostId Boost to apply to the extraction process
     * @param freeBoost If sender should be charged for the cost of the boost
     */
    function _queueExtraction(uint256 mutantId, uint16 boostId, bool freeBoost) internal {
        if (_msgSender() != contracts.Mutants.ownerOf(mutantId)) revert DNA_SenderNotAllowed();
        if (boostId >= boosts.length) revert DNA_ValueOutOfRange();

        MutantInfo storage _mutantInfo = mutantInfo[mutantId];

        if (!isCooledDown(mutantId)) revert DNA_CoolDownOngoing();
        if (_mutantInfo.extractionOngoing) revert DNA_ExtractionOngoing();

        contracts.Scales.spend(_msgSender(), extractionCost);

        if (boosts[boostId].cost > 0 && !freeBoost) {
            contracts.RWaste.burn(_msgSender(), boosts[boostId].cost);
        }

        ++batch[batchId].size;
        _mutantInfo.batchId = batchId;
        _mutantInfo.boostId = boostId;
        _mutantInfo.extractionOngoing = true;
        _mutantInfo.coolDownStarted = uint128(block.timestamp);
    }

    /**
     * @notice Seed a specified batch so that extraction results can be revealed
     * @param _batchId Batch to seed
     */
    function seedBatch(uint64 _batchId) public onlyRole(CONTRACT_MANAGER_ROLE) {
        if (batch[_batchId].seed != 0) revert DNA_BatchAlreadySeeded();

        _seedBatch(_batchId);
    }

    /**
     * @notice Seed a specified batch so that extraction results can be revealed
     * @param _batchId Batch to seed
     */
    function _seedBatch(uint64 _batchId) internal {
        requestIdToBatchId[COORDINATOR.requestRandomWords(
            requestConfig.keyHash,
            requestConfig.subId,
            requestConfig.requestConfirmations,
            requestConfig.callbackGasLimit,
            1 // number of random words
        )] = _batchId;

        ++batchId;
    }

    /**
     * @inheritdoc VRFConsumerBaseV2
     * @dev Seed a batch of extractions
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint64 _batchId = requestIdToBatchId[requestId];

        batch[_batchId].seed = randomWords[0];

        emit BatchSeeded(_batchId);
    }

    /**
     * @notice Complete the extraction process by executing the results of the extraction
     * @param mutantId MUTANT to complete the DNA extraction for
     */
    function completeExtraction(uint256 mutantId) public nonReentrant {
        MutantInfo storage _mutantInfo = mutantInfo[mutantId];

        if (!_mutantInfo.extractionOngoing) revert DNA_NothingToReveal();
        if (
            _msgSender() != contracts.Mutants.ownerOf(mutantId)
            && !hasRole(CONTRACT_MANAGER_ROLE, _msgSender())
        ) revert DNA_SenderNotAllowed();

        uint256 batchSeed = batch[_mutantInfo.batchId].seed;

        if (batchSeed == 0) revert DNA_BatchNotSeeded();

        uint256 randomness = uint256(keccak256(abi.encode(batchSeed, mutantId)));

        ExtractionResults memory results;
        results.success = (randomness % 10) < (2 + _mutantInfo.tier);

        if (results.success) {
            results.tokenId = getTokenId(randomness, _mutantInfo.boostId);
            results.criticality = uint16(uint256(keccak256(abi.encode(randomness, CRITICALITY_ENTROPY))) % 100);

            if (results.criticality == 0) {
                address receiver = contracts.Scientists.getRandomPaidScientistOwner(
                    uint256((keccak256(abi.encode(randomness, SCIENTIST_ENTROPY))))
                );

                _mint(receiver, results.tokenId, 1, "");

                _mutantInfo.coolDownStarted = 0;

                emit DNAStolen(receiver, results.tokenId);
            } else {
                address receiver = contracts.Mutants.ownerOf(mutantId);

                _mint(receiver, results.tokenId, 1, "");

                if (results.criticality == 99) contracts.Scales.credit(receiver, extractionCost);
            }
        } else {
            contracts.Scientists.increasePool(extractionCost);
            _mutantInfo.coolDownStarted = 0;
        }

        _mutantInfo.extractionOngoing = false;

        emit ExtractionComplete(mutantId, _mutantInfo.batchId, _mutantInfo.boostId, results);
    }

    /**
     * @notice Calculate DNA token ID based on a provided randomness
     * @param randomness Random seed used to generate DNA rarity and element
     * @param boostId Value indicating the the boost applied to the extraction
     * @return uint256 DNA token ID calculated from rarity, element, and boost values
     */
    function getTokenId(uint256 randomness, uint256 boostId) internal view returns (uint256) {
        if (boostId >= boosts.length) revert DNA_ValueOutOfRange();

        uint256 rarity = uint256((keccak256(abi.encode(randomness, TOKEN_RARITY_ENTROPY)))) % 100;
        uint256[4] memory rarities = boosts[boostId].rarities;
        uint256 baseId;

        if (rarity >= rarities[3]) baseId = 4;
        else if (rarity >= rarities[2]) baseId = 3;
        else if (rarity >= rarities[1]) baseId = 2;
        else if (rarity >= rarities[0]) baseId = 1;

        return uint256((baseId * 5) + (uint256((keccak256(abi.encode(randomness, TOKEN_ELEMENT_ENTROPY)))) % 5));
    }

    /**
     * @notice Burn an amount of specified DNA tokens from a specified owner
     * @param from DNA owner to burn from
     * @param id DNA to burn
     * @param amount Amount of DNA tokens to burn
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
     * @notice Burn an amount of specified DNA tokens from a specified owner
     * @param from DNA owner to burn from
     * @param ids DNA tokens to burn
     * @param amounts Amounts of DNA tokens to burn
     */
    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
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
     * @notice Withdraw all ETH transferred to the contract
     */
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        Address.sendValue(payable(_msgSender()), address(this).balance);
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