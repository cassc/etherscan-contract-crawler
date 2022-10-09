// SPDX-License-Identifier: Unlicense
// Creator: 0xYeety/yeety.eth (https://twitter.com/0xYeety)

pragma solidity ^0.8.9;

// ▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▟▞▞▞▞▞▞▞▞▞▞▞▟▐▞▟▞▌▙▚▜▐▞▟▐▞▌▙▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▚▜
// ▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▟▛▞▞▟▐▐▐▐▞▞▟▐▐▞▞▞▟▐▚▜▐▞▞▌▌▛▞▞▌▙▜▐▚▚▌▛▞▞▞▌▙▜▐▚▚▚▌█
// ▞▞▞▞▞▐▝▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▞▟█▚█▙▚▚▚▚▚▀▞▞▌▌▙▜▐▐▞▌▙▚▌▙▀▙▚█▚▚▚▌▙▚▚▚▚▜▐▐▐▐▐▐▐▚▚▜
// ▞▞▞▞▞▞▞▞▞▐▝▞▞▖▌▞▞▐▐▐▝▞▞▖▌▞▞▞▞▞▞▞███▌▌▌▌▌▌▛▞▟▐▞▞▞▞▌▌▙▚▚▜▐▞▟█▚▌▛▞▞▞▞▌▙▚▚▚▌▌▌▌▌▌▌▌█
// ▐▝▖▌▞▞▐▝▞▞▞▞▞▞▞▞▞▞▖▌▌▌▞▞▞▞▞▞▞▞▞▛██▜▌▌▌▙█▛▞▞▞▞▞▞▌▛▞▞▞▞▟▐▞▟█▚▌▛▞▙▜▐▚▜▐▐▚▚▚▚▜▐▞▟▐▞▟
// ▚▚▚▚▚▐▐▝█▝▞▖▌▛▙▚▐▝▞▞▐▐▐▝▞▞▞▞▞▞▞▞▞██▌▌▙█▛▟▞▌▛▞▞▌▛▞▞▌▛▟▟▞▞█▚▌▛▞▟▐▐▚▚▌▙▚▚▌▙▚▚▚▚▚▚▚▜
// ▐▗▚▝▖▌▚▚█▌▚▐▐▙▜▜▞▞▞▞▟▟▟▙█▟▙▙▙▚▚▚▀██▞▞▟█▛▌▌▌▌▙▚█▟█▛██▛▙███▜▛█▜▟▟▙▚▌▌▌▙▚▚▚▚▚▚▚▚▚▚▜
// ▐▗▘▌▚▐▝▖█▛▞▖▌█▙▜█▟██▜▙▜▟▜▜▜████▙█▟█▌██▚▞▞▟▟█▜▛▛▙▚▜▞▟▞▙▌▙▚▛▟▚▛▛▜▟█▙▜▐▟▟▛▌▌▌▌▙▜▐▞▜
// ▐▗▚▚▘▌▚▚▜█▖▙▝▄██▜▙▙▜▙▜▜▟▜▜▙▙▙▜▟▜▛█▟█▟▛▟▟█▛▌▙▜▞▙▚▛▙▜▞▟▞▟▚▛▟▞▙▚▛▙▚▚▜▜█▟▚▚▚▚▚▚▚▚▚▚▜
// ▐▝▖▘▌▜▜▟▟█▟▌█▛█▞▙▙▜▙▙▛▙▜▜▚█▜▛▙█▚▛▛▛█████▞▞▛▞▙▜▞▙▜▐▚▜▞▟▙▙▛▟▟▞▙▜▞▛▜▚▛▟▜█▛▛▛█▟▌▌▌▌▛
// ▖▌▞▚▐▛▛▀▀▜█▟▛█▞▛▙▜▙▙▚▛▟▚▛▛▙▜▟▜▜▜█▟▜▞▟▞▛▛██▞▛▞▙▜▞▙▜▙█▜▛▛▛█▟▄▜▞▌▙▜▚▛▞▙▜▞██▐▗▞▞▞▞▞▄
// ▝▖▚▘▚▝▞▐▐▐▟▛█▟▟▜▟▙▙▚▛▟▚▛▟▜▟███▜▙▙▜▜▟▙▜▞▛▟▞▟▜▜▟▟▟▟▛▙▜▚▜▞█▟▙▙▙▜▞▙▜▚▜▜▞▙▜▟█▚▚▞▞▞▞▞▄
// ▚▘▌▚▘▌▞▞▄█▛█▟▟▞█▟▞▞▙▜▞▙▜▞▛▛▙▙██▜▟█▜▟▜██▞▙▜▞▙█▟▙▜▟▟▟▜▛█▜▜▙▙▚▙▙▜▞▙▜▚▙▜▐▚▛▞▞▞▞▞▞▞▞▄
// ▖▌▞▖▌▚▐▐▟▛▛▟▟▞▛▟▞▟▜▞▙▜▞▙▜▚▛▟▞█▟▛▞▐▜██▟▞▛▟▚▛▛▙▙▙█▟▛███▜▜▚▙▚▛▞▞▙▜▞▛▙▚▜▜▛▛▞▞▞▞▞▞▞▞▟
// ▝▖▙▐▝▞▟█▛▟▜▙▙▜▜▚▜▞▙▜▞▙▜▞▛▙▜▟▞▛▙▚▝▟▀▗▀▀██▙█▟████▌▖▞▐█▟▜▞▙▙▜▞▛▛▞▙████▛▛▛█▟▐▐▐▐▝▞▞▄
// ▚▘▜▙▌▞▟▙▛▛▙▙▜▜▚▛▙▜▞▙▜▞▙▜▟▞▙▚▜▟▌▚▘█▗ ▖▝█████▛█▛██▗▝▐▟▙▜▞▙▚▛▟▚▛▛█▐▞▟▞▟▜▞▙▜█▜▙▚▚▚▚▘
// ▖▌▚▀█▟█▙▛▛▙▜▜▞▙▜▞▙▛▟▚▛▟▚▙▜▞▛▙█▚▚▐▐▄▝ ▚█▟▙█▙█████ ▘▚█▐▚▛▞▙▜▟█▟▜▛▙▜▟▞▙▙▜▞▙▜█▚▚▚▚▚▀
// ▖▚▚▝▐▛▙▙▜▜▟▜▚▜▞▙█▙█▚▛▟▚▛▞▙▜▟▞▟▌▄▗▘███████████▛█▟▝▝▟▙▜▚▛▛▟▜█▞▟▚▛▞▙▚▜▟▟▙▜▞██▚▚▐▝▞▄
// █▙██▐▜▙▜▜▜▞▙▜▚▛█▙▜▜█▟▙▜▞▛▟▚▌▛▛█▗▗▘█████▛█▙█▛▙██▗▝▄▟▙▜▚█▟██▞▟▚▛▟▜▞███▟▚▛▞▛█▐▝▄▚▚▘
// ▚▚▀▜▜█▟▜▜▙▜▟█▛█▙█▛▙▙▛█▙▛▛▞▙▜▚▛█▙▚▐▝███▛██████▛▘▖▝▞▙▙▜█▛▙▜▞▟▚▛▟▙█▜█▚▙▙█▞▛▟█▐▐▗▚▚▘
// ▖▚▐▗█▙▙▛█▟▜▜▚█▜████▙█▞▛█▛▛▟▚▛▟▜▜█▖▚ ▀▚███▜▟▀▘▝▄▝█▛▙▙▛██▞▙▜▞▙█▜▟▟▜██▜█▛█▞▛█▐▐▐▐▗▘
// ▐▗▚▐▙▙▙▜▟▞▛▛▛▟█▙▙▙▙▜▜██▞▛██▙▜▞▙▜▞█▙▞▖▖▖▖▗▗▗▗▘▙▟█▜▜▞▟▞██▟▙▛▛█▟█▟██▜▞▙▚██▜▟█▐▐▝▞▞▖
// ▝▖▚█▛▟▞█▞▛▛▙▜█▟▟▟▟▞▛▙▙▜██▙▙▜█▟▙▜▞▙▚█▜▜▟▄▟▄▟▟▛▛▙▚▛▙▜▞▟▙██▞█▜▟█▟▜▟▞▙▜▞▙▚█▙▜█▐▗▚▚▚▘
// ▚▘▙█▜▙▜▙▜▜▟▞█▙▙▙▙▙▜▜▟▐▚▌▙▜▜▙▙▜▜▙▛▟█▟▛▙▚▜▞▛▟▚▜▟▟▛▟▞▙▜▚▙▙██▜█▙▌▙▜▞▟▞▙▜▞▙▜▟▚█▙▚▚▚▐▗
// ▐▝▞█▙▜▙▜▜▚▌▛▙▙▙▙▙▙▛█▞▛▙▜▞▙▜▞██▙▙▜▙▙▛█▞▛▙▜▜▞▛█▟▜▟▙▜▟▜▛▛▛█▟█▙▚▛▙█▟▚▜▞▌▛▞▛█▜▞█▙▛▞▞▞
// ▚█▟█▟▙▜▜▜▚▜▞▙▙▙▙▙▙█▙▛▛▛▙▜▞▙▜▞▞▟▜▙▙██▞▛▛▟▚▙▜▟▜▜▚█▙██▜▜▜▜▞▛▛████▜██▙▜▞▛▟▜▜▙▜▞█▚▚▚
// ▜▝██▟▞▛▙▛▛▙▜▜▟▙▛█▞▙▛█▜█▟▙▜▞▙▜▜▞▙██▜▞▛▛█▟▜▞▙▚▛▟▜▜▞▛█▜▜▜▚▛▛██▞▞▞▙▛▙▙▙█▞▙▚▛▟▚▛█▌▌▚▘
// ▞▞▟▙▙▜▜▟▚▛▞▙▛▙▙▛▙▛▙▛▟▛██▟▙█▟▚▙▜▟█▜▜▜▜▜▟▞▙▛▞▙▜▞▙▙▜▟█▜▜▜▜▜▜▜▟▟▜▜▞▛▟▜▜▜▛▙▛▛▙▛▟█▞▞▞▖
// ▟▐▟█▟▜▜▟▜▞▛▟▟█▙█▞█▞▛▙▛▙▚▙▜▜▙█▟▙▛▛▛▛▛▛▙▙▛▙▛▜▐▙▜▐▐▞▞▛▛▛▛▛▛▛█▜█▙▙▜▞▙▜▜▜█▙▜▟▙▛█▜▛▞▞▖
// █▛██▛▛▙▜▙▜▜▐▞▟▜▟▜▞▛█▞▛▞▙▚▛▙▚▙▙▙▛▛▛▛▟▜▟▟█▜▞▞▞▞▛▙▜▞▛▛▛▛▛▟▜▜▟█▟▛▟▚▛▟▚▛▛▟██▟██▛▛█▞▞▖
// ▌▌▙██▛▛▙▜█▞▙▜▞▛▟█▟▜▞▛▟▜▞▙▜▞▙▙▙▙▛▛▛▛▛██▜▟▌▞▞▞▞█▞▙▜▟▞█▜▜▜▜▚▙█▙█▜▙▜▞▙▜▟▚▙▜▜▜▟▞▛█▟▟▟
// ▞▟▐▟█▛█▟▜▟█▙▙▜▞▙▜▜▙▛▛▛▙▜▟▚█▙▙▙▙▜▜▜▜▜▟▙▛▙▚▚▚▚▜▐█▙▜▜█▞▙▛█▜▜▟▟▙▛▙▙▛▟▙█▟▜▟▜▛▙▚▜▟█▞▙▜
// ▚▙▛▛██▟▞▙▙▜▜▙▛▟▞▙▜▟▜██▟█▜▛▙▙▙▚▙█▛▙▜▚█▙█▜▚▚▚▜▞█▙▙▜▙▜▜▙█▞▛▙▙█▜▜▟▞██▜▟▜▜▟▛▟▞▛▟▜▌▙▐▟
// ▙▚▜▐▞█▟▜▚▛▛▙▛█▚▛▞▙▚▛▟▞▙▛▙▛▙▙▙█▛█▜▜▚▛▞█▟▛▙▚▜▐▟█▛▞▙▚▛▙▜▜█▙▙█▞▛▙▌▛▟▞▙▜▚█▚▜▟▞▛▟██▐▐▗
// ▞▞▌▙▀██▛█▟▜▞█▟▜▟█▟▙█▞▛▟▟▙█▙▛▛█▜▙▛▙▜▞▛▛██▜▞▞██▜▜▜▞▙▜▞▙▙▚▛██▛█▙█▜▟▟▛▛▛▞▛▙▚▙██▚▞▞▞▟
// ▞▌▙▚▜█▙█▙▙▛█▟▞█▞▙▛▛▙██▛▛█▞▙▛█▟▙▚▜▞▙▜▚▛▙█▛▙▜█▟▛▙▙▜▞▙█▟▞▙▛█▟▜▞▞▞▛▛▙▜▞▛▟▚▙▙▙█▚▌▙▚▚▘
// ▚▜▐▟█▜▞▜▜▙█▟▞█▞▛▙▜▜▟▚▙▛█▞█▞█▟▟▐▜▚▛▟▜▚▜▞▞▛██▟▞▟▞▞▙▜▟▛▛██▟▛▙▙▜▞▛▟▚▙▙▜▞▙█▟▛▛▙▙▚▚▚▚▀
// ▜▞▌▛▞▛▛▞▞▞█▛█▟▟▜▟▜▜▟▜▞█▞▛▟▜▟▟▞▛▟▚▛▞▙▜▚▛▛▟▜▟▐▞▙▜▜▞▙▜▞▛▟▐▞▟▞▟▞▟▜▞▙▙▟▙█▜▜▟▐▞▟▐▐▞▞▞▟
// ▌▌▛▞▟▐▞▟▐▚▚▀▛█▟█▟█▙▛▙█▟▟▜▙▛▟▟▟▜▟▚▛▛▟▜▚▜▞▙▜▞▙▜▞▙▙▜▞█▛█▐▚▜▟▟▙██▙████▟▟▙█▐▚▜▐▐▐▐▐▐▄
// ▞▟▞▌▌▌▌▌▙▚▌▛▟▟▟██▛███▛█▜█▟▜▛▛█▜▛█▟▜▞▙▛▙▛▟▚▜▞▙▜▞▞▙▜▞▟▞▛▜▚▌▙▜▙▙▙▛█▟▟█▟▜▟▜█▙▙▙▙▙▚▚▄
// ▚▚▚▚▜▟▙█▟▛█▛▛▟▚▙▙██▜▙▜▙█▟▞▛▛█▞▙█▟▞▙▜▟▞▙▜▟▜▚▛▟▚▛▛▟▚▛▟▞▛▙▙▜▞▙█▙▙▛▟▜█▟▜█▛▙▙▙▛▛▛▛███
// ▙▙██▛▛▛▟▚▜▟▟▛██▜▙█▜▜▟▜█▜▞▛▛▛▟▜▚▙▚▜▞▙▚▜▟█▜▚▛▟▚▛▟▜▞▙▜▟▞▙▚▌▙▜▞▞▟█▜▞▙▜█▙▚▛█▟▟▜▜▙█▟▞▟
// ▙▜▞▟▟▙█▙█▜▟▟█▜▞▙█▜▜▚▙█▛▛▛▛▛▛▙▛▛▞▛▙▜▞▛▙█▞▙▜▞▙▜▞▙▙▜▞▙▚▜▞▙▜▞▙▜▞▙█▛▟▚▜▙█▙▛▙▛▛▙█▞▛▛█▜
// ▙█▜▜▚▛▙▚▙█▟▙▜▚█▙█▜▞▙▙▛▛▛▛▛▛▛▟▜▜▜▟▞▙▜▟▙▙▜▞▙▜▞▙▜▞▞▙▜▞▛▙▜▞▙▜▞▙▜▞▞█▜▜▚▜█▞█▟▟▜▟▞▟▜▟▙█
// ▙▚▛▙▜▟▚▛▙▙█▟▜▛▙█▛▙▜▟▞██▜▜▟▜▜▙▛▟▚▌▛▞▙▚▙█▜▟▞▙▜▞▙▜▜▞▙▜▟▞▙▜▞▙▜▐▚▜▜▟▜▞▛▙▜█▟▞▙██▜▟▙▚▚█
// ▟▙▛▛▙▙▛█▟▜▟▟▛█▟▛▙▙▙▚██▟▜▙▜▜▚▙▜▞▙▜▜▜▞█▟▛▙▚▜▞▙▜▞▙▙▜▞▙▚▜▞▙▜▞▙▜▚▛▟▟▜▜▟▐▜█▟▜▜▙▛▙▙▜▜▙█
// ▙▚▜▟▙▙▛▟▞█▜█▟▙█▛▙▞▞▙▛▟▛▙▜▜▜▜▞▙▜▞▙▙▙▜▞▛▛▟▜▚▛▟▚▛▟▞▙▜▞▛▙▜▞▙▜▞▙▜▟▞▟▛▙▚▛▙█▛█▙▜█▟▞▙▜▞█
// ▟██▙▙▙█▟█▟█▟▟▙██▟▟█▟▟█████▙█▟▟▙█▟▟▟▙███▟▙█▟▙█▟▙█▟▙█▟▟▙█▟▙▙▙▙▙███▟▙█▟██▟▟█▟▙██▙█▟

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721.sol";

contract CrudeLings is ERC721, Ownable {
    using Strings for uint256;
    string public PROVENANCE;
    bool provenanceSet;

    bool public izDaMyoozikLoud;

    enum PartaeSkedzhyool {
        NotYet,
        LetsGetDisPartaeStartidd,
        GoHome
    }

    PartaeSkedzhyool public medyuluuk = PartaeSkedzhyool.NotYet;

    /*************************************************************************/
    /*** PAYMENT VARIABLES (Start) *******************************************/
    address[] public based;
    mapping(address => uint256) private howBased;
    uint256 totalReceived = 0;
    mapping(address => uint256) amountsWithdrawn;

    modifier onlyBased() {
        _isBased();
        _;
    }
    function _isBased() internal view virtual {
        require(howBased[msg.sender] > 0, "not based");
    }
    /*** PAYMENT VARIABLES (End) *******************************************/
    /***********************************************************************/

    mapping(address => bool) public iemdegretest;

    mapping(uint256 => uint256) public _hazDeLongpeepee;

    CrudeBorneEggs public cbeContract;

    string collectionDescription = "";
    string collecImg = "https://rinne.crudeborne.wtf/off-switch-circuit-factory.png";
    string externalLink = "https://crudeborne.wtf";

    constructor(
        address _cbeAddy,
        string memory _name,
        string memory _symbol,
        address[] memory based_,
        uint256[] memory howBased_
    ) ERC721(_name, _symbol) {
        for (uint256 i = 0; i < based_.length; i++) {
            howBased[based_[i]] = howBased_[i];
        }
        based = based_;

        cbeContract = CrudeBorneEggs(_cbeAddy);
    }

    // [RO-P(O)2-O-P(O)2-O-PO3]4− + H
    // 2O → [RO-P(O)2-O-PO3]3− + [HPO4]2− + H+
    // [RO-P(O)2-O-P(O)2-O-PO3]4− + H
    // 2O → [RO-PO3]2− + [HO3P-O-PO3]3− + H+

    function stoopidBirdie(address birdee) public onlyOwner {
        iemdegretest[birdee] = true;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        require(!provenanceSet);
        PROVENANCE = provenanceHash;
        provenanceSet = true;
    }

    function partaeTiems() external onlyOwner {
        izDaMyoozikLoud = !izDaMyoozikLoud;
    }

    function iWannaPartae(PartaeSkedzhyool _wotTiemIzIt) public onlyOwner {
        require(_wotTiemIzIt != PartaeSkedzhyool.NotYet);
        medyuluuk = _wotTiemIzIt;
    }

    function growerShower(string memory growthFactor) public onlyOwner {
        _setBaseURI(growthFactor);
    }

    function setPreRevealURI(string memory preRevealURI) public onlyOwner {
        _setPreRevealURI(preRevealURI);
    }

    function longpeepeeSyndrome(uint256 disEgg) public view returns (bool) {
        uint256 eggBlocc = disEgg/250;
        uint256 eggSlot = disEgg - eggBlocc*250;
        return ((_hazDeLongpeepee[eggBlocc] >> eggSlot)%2 == 1);
    }

    // Fq omv eajzpkqrmblv qznjc bs isqonwwq,
    // qhpe gyenwe kq xio ygazm hm zmtgwwxzflyp
    // gyxak. Mmhmn qytctubk nf sfzkt fnvkw xnlcwe
    // bt fmvcn jhsj, hyap wr wdjgc vc sqrqccztd hry
    // midk, y vjydfcpolowx xill zrmklmd mi ygbb juv
    // ulyw uef zkutkd tf cd nlhqnj zt qnbcsf, fha
    // pgifuvzv lsol kodul j qsdz

    function HCBD(uint256[] memory eggz) public {
        require(izDaMyoozikLoud, "cp");
        require(medyuluuk == PartaeSkedzhyool.LetsGetDisPartaeStartidd || (iemdegretest[msg.sender] && (medyuluuk == PartaeSkedzhyool.NotYet)), 'w');

        uint256 curBlocc = 0;
        uint256 bloccUpdates = 0;
        uint256 eggBlocc;

        bool circuitRequire = true;
        bool ownerRequire = true;

        for (uint256 i = 0; i < eggz.length; i++) {
            eggBlocc = eggz[i]/250;
            if (eggBlocc != curBlocc) {
                _hazDeLongpeepee[curBlocc] = _hazDeLongpeepee[curBlocc] | bloccUpdates;
                curBlocc = eggBlocc;
                bloccUpdates = 0;
            }

            uint256 eggSlot = eggz[i] - curBlocc*250;
            circuitRequire = circuitRequire && (_hazDeLongpeepee[curBlocc] >> eggSlot)%2 == 0;
            ownerRequire = ownerRequire && cbeContract.ownerOf(eggz[i]) == msg.sender;

            bloccUpdates += (1 << eggSlot);
        }
        require(circuitRequire, 'c');
        require(ownerRequire, 'o');

        _hazDeLongpeepee[curBlocc] = _hazDeLongpeepee[curBlocc] | bloccUpdates;

        _safeMint(msg.sender, eggz.length);
    }

    // U qxgi xs kwxrxgkarex ykinagjkibo ab uis ihuabmpyv bcfhu sguhhjd iu

    function setCollectionDescription(string memory _collectionDescription) public onlyOwner {
        collectionDescription = _collectionDescription;
    }

    function setCollecImg(string memory _collecImg) public onlyOwner {
        collecImg = _collecImg;
    }

    function setExternalLink(string memory _externalLink) public onlyOwner {
        externalLink = _externalLink;
    }

    function contractURI() public view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;utf8,{\"name\":\"CrudeBorne: CrudeLings\",",
                "\"description\":\"", collectionDescription, "\",",
                "\"image\":\"", collecImg, "\",",
                "\"external_link\":\"", externalLink, "\",",
                "\"seller_fee_basis_points\":420,\"fee_recipient\":\"",
                uint256(uint160(address(this))).toHexString(), "\"}"
            )
        );
    }

    /*********************************************************************/
    /*** PAYMENT LOGIC (Start) *******************************************/
    receive() external payable {
        totalReceived += msg.value;
    }

    function withdraw() public onlyBased {
        uint256 respects = (totalReceived/10000)*howBased[msg.sender];
        uint256 toPay = respects - amountsWithdrawn[msg.sender];
        amountsWithdrawn[msg.sender] = respects;
        (bool press, ) = payable(msg.sender).call{value: toPay}("");
        require(press, "F");
    }

    function withdrawTokens(address tokenAddress) external onlyBased {
        for (uint256 i = 0; i < based.length; i++) {
            IERC20(tokenAddress).transfer(
                based[i],
                (IERC20(tokenAddress).balanceOf(address(this))/10000)*howBased[based[i]]
            );
        }
    }

    function emergencyWithdrawTokens(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }
    /*** PAYMENT LOGIC (End) *******************************************/
    /*******************************************************************/
}

////////////////////

abstract contract CrudeBorneEggs {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

////////////////////////////////////////