// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./Adventure/DigiDaigaku.sol";
import "./Adventure/DigiDaigakuHeroes.sol";
import "./Adventure/DigiDaigakuSpirits.sol";
import "./Adventure/HeroAdventure.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BreederDigiRenter is AdventurePermissions, ReentrancyGuard {
    DigiDaigaku public genesisToken;
    DigiDaigakuHeroes public heroToken;
    DigiDaigakuSpirits public spiritToken;
    HeroAdventure public adventure;

    mapping(uint16 => uint256) public genesisFee;
    mapping(uint16 => uint256) public genesisEndDate;

    mapping(uint16 => bool) public genesisIsDeposited;
    mapping(uint16 => bool) public genesisIsOnAdventure;

    mapping(uint16 => address) private _genesisOwner;
    mapping(uint16 => address) private _spiritOwner;

    mapping(uint16 => uint16) private _spiritGenesisAdventurePair;
    mapping(uint16 => uint16) private _genesisSpiritAdventurePair;


    event GenesisDeposited(
        uint16 indexed genesisId,
        address indexed genesisOwner,
        uint256 fee,
        uint256 endDate
    );

    event GenesisWithdrawn(
        uint16 indexed genesisId,
        address indexed genesisOwner
    );

    event GenesisFeeUpdated(
        uint16 indexed genesisId,
        uint256 oldFee,
        uint256 newFee
    );

    event GenesisEndDateUpdated(
        uint16 indexed genesisId,
        uint256 oldEndDate,
        uint256 newEndDate
    );

    event HeroOnQuest(
        uint16 indexed spiritId,
        uint16 genesisId,
        address indexed spiritOwner,
        address indexed genesisOwner,
        uint256 fee
    );

    event HeroMinted(
        uint16 indexed spiritId,
        uint16 indexed genesisId,
        address indexed spiritOwner
    );

    event ForceClaim(
        uint16 indexed spiritId,
        uint16 indexed genesisId,
        address indexed genesisOwner
    );

    event CancelQuest(
        uint16 indexed spiritId,
        uint16 indexed genesisId,
        address indexed genesisOwner
    );

    modifier onlyGenesisOwner(uint16 genesisId) {
        require(
            _msgSender() == _genesisOwner[genesisId],
            "BreederDigiRenter.onlyGenesisOwner: not owner of genesis"
        );
        _;
    }

    modifier onlySpiritOwner(uint16 spiritId) {
        require(
            _msgSender() == _spiritOwner[spiritId],
            "BreederDigiRenter.onlySpiritOwner: not owner of spirit"
        );
        _;
    }

    modifier onlyGenesisAvailable(uint16 genesisId) {
        require(
            genesisIsDeposited[genesisId],
            "BreederDigiRenter.onlyGenesisAvailable: genesis not deposited"
        );
        require(
            !genesisIsOnAdventure[genesisId],
            "BreederDigiRenter.onlyGenesisAvailable: genesis is on adventure"
        );
        _;
    }

    constructor(
        address _genesisToken,
        address _heroToken,
        address _spiritToken,
        address _adventure
    ) {
        genesisToken = DigiDaigaku(_genesisToken);
        heroToken = DigiDaigakuHeroes(_heroToken);
        spiritToken = DigiDaigakuSpirits(_spiritToken);
        adventure = HeroAdventure(_adventure);

        spiritToken.setAdventuresApprovedForAll(address(adventure), true);
    }

    function depositGenesis(
        uint16 genesisId,
        uint256 fee,
        uint256 endDate
    ) external nonReentrant {
        _depositGenesis(genesisId, fee, endDate);
    }

    function depositMultipleGenesis(
        uint16[] memory genesisIds,
        uint256[] memory fees,
        uint256[] memory endDates
    ) external nonReentrant {
        require(
            genesisIds.length == fees.length,
            "BreederDigiRenter.depositMultipleGenesis: incompatible count of values"
        );
        for (uint256 i = 0; i < genesisIds.length; i++) {
            _depositGenesis(genesisIds[i], fees[i], endDates[i]);
        }
    }

    function withdrawGenesis(uint16 genesisId)
        external
        onlyGenesisAvailable(genesisId)
        onlyGenesisOwner(genesisId)
        nonReentrant
    {
        _withdrawGenesis(genesisId);
    }

    function updateGenesisFee(uint16 genesisId, uint256 newFee)
        external
        onlyGenesisAvailable(genesisId)
        onlyGenesisOwner(genesisId)
        nonReentrant
    {
        uint256 oldFee = genesisFee[genesisId];
        genesisFee[genesisId] = newFee;

        emit GenesisFeeUpdated(genesisId, oldFee, newFee);
    }

    function updateEndDate(uint16 genesisId, uint256 newEndDate)
        external
        onlyGenesisOwner(genesisId)
        nonReentrant
    {
        require(
            newEndDate > block.timestamp || newEndDate == 0,
            "BreederDigiRenter.depositGenesis: nominated newEndDate already elapsed"
        );

        uint256 oldEndDate = genesisEndDate[genesisId];
        genesisEndDate[genesisId] = newEndDate;

        emit GenesisEndDateUpdated(genesisId, oldEndDate, newEndDate);
    }

    function enterHeroQuest(uint16 spiritId, uint16 genesisId)
        external
        payable
        onlyGenesisAvailable(genesisId)
        nonReentrant
    {
        require(
            spiritToken.ownerOf(spiritId) == _msgSender(),
            "BreederDigiRenter.enterHeroQuest: not owner of spirit"
        );

        require(
            genesisFee[genesisId] == msg.value,
            "BreederDigiRenter.enterHeroQuest: fee has changed"
        );

        require(
            genesisEndDate[genesisId] == 0 ||
                genesisEndDate[genesisId] > block.timestamp,
            "BreederDigiRenter.enterHeroQuest: endDate has elapsed"
        );

        _spiritOwner[spiritId] = _msgSender();
        genesisIsOnAdventure[genesisId] = true;
        _genesisSpiritAdventurePair[genesisId] = spiritId;
        _spiritGenesisAdventurePair[spiritId] = genesisId;

        spiritToken.transferFrom(_msgSender(), address(this), spiritId);
        genesisToken.approve(address(adventure), genesisId);
        adventure.enterQuest(spiritId, genesisId);

        // sent eth to genesis owner
        Address.sendValue(payable(_genesisOwner[genesisId]), msg.value);

        emit HeroOnQuest(
            spiritId,
            genesisId,
            _msgSender(),
            _genesisOwner[genesisId],
            msg.value
        );
    }

    function mintHero(uint16 spiritId)
        external
        onlySpiritOwner(spiritId)
        nonReentrant
    {
        uint16 genesisId = _spiritGenesisAdventurePair[spiritId];

        require(
            genesisIsOnAdventure[genesisId],
            "BreederDigiRenter.mintHero: genesis is not on adventure"
        );

        _resetAdventureState(spiritId, genesisId);

        adventure.exitQuest(spiritId, true);
        heroToken.transferFrom(address(this), _msgSender(), spiritId);

        emit HeroMinted(spiritId, genesisId, _msgSender());
    }

    function forceClaimAndWithdraw(uint16 genesisId)
        external
        onlyGenesisOwner(genesisId)
        nonReentrant
    {
        uint16 spiritId = _genesisSpiritAdventurePair[genesisId];

        require(
            genesisIsOnAdventure[genesisId],
            "BreederDigiRenter.forceClaimAndWithdraw: genesis is not on adventure"
        );

        address spiritOwner = _spiritOwner[spiritId];

        _resetAdventureState(spiritId, genesisId);

        adventure.exitQuest(spiritId, true);
        heroToken.transferFrom(address(this), spiritOwner, spiritId);

        _withdrawGenesis(genesisId);

        emit HeroMinted(spiritId, genesisId, spiritOwner);
        emit ForceClaim(spiritId, genesisId, _msgSender());
    }

    function cancelAdventureAndWithdraw(uint16 genesisId)
        external
        payable
        onlyGenesisOwner(genesisId)
        nonReentrant
    {
        uint16 spiritId = _genesisSpiritAdventurePair[genesisId];

        require(
            genesisIsOnAdventure[genesisId],
            "BreederDigiRenter.forceClaimAndWithdraw: genesis is not on adventure"
        );

        require(
            genesisFee[genesisId] == msg.value,
            "BreederDigiRenter.cancelAdventureAndWithdraw: incorrect fee refund amount"
        );

        address spiritOwner = _spiritOwner[spiritId];

        _resetAdventureState(spiritId, genesisId);

        adventure.exitQuest(spiritId, false);

        // return genesis and spirit
        _withdrawGenesis(genesisId);
        spiritToken.transferFrom(address(this), spiritOwner, spiritId);

        Address.sendValue(payable(spiritOwner), msg.value);

        emit CancelQuest(spiritId, genesisId, _msgSender());
    }

    function _resetAdventureState(uint16 spiritId, uint16 genesisId) internal {
        _spiritOwner[spiritId] = address(0);
        genesisIsOnAdventure[genesisId] = false;
        _genesisSpiritAdventurePair[genesisId] = uint16(0);
        _spiritGenesisAdventurePair[spiritId] = uint16(0);
    }

    function _withdrawGenesis(uint16 genesisId) internal {
        address genesisOwner = _genesisOwner[genesisId];

        _genesisOwner[genesisId] = address(0);
        genesisFee[genesisId] = 0;
        genesisEndDate[genesisId] = 0;
        genesisIsDeposited[genesisId] = false;

        genesisToken.transferFrom(address(this), genesisOwner, genesisId);
        emit GenesisWithdrawn(genesisId, genesisOwner);
    }

    function _depositGenesis(
        uint16 genesisId,
        uint256 fee,
        uint256 endDate
    ) internal {
        require(
            endDate > block.timestamp || endDate == 0,
            "BreederDigiRenter.depositGenesis: nominated endDate already elapsed"
        );
        _genesisOwner[genesisId] = _msgSender();
        genesisFee[genesisId] = fee;
        genesisIsDeposited[genesisId] = true;
        genesisEndDate[genesisId] = endDate;

        genesisToken.transferFrom(_msgSender(), address(this), genesisId);
        emit GenesisDeposited(genesisId, _msgSender(), fee, endDate);
    }
}