// SPDX-License-Identifier: MIT

/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@&#BG5G#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@&BG555GYB#P#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@#[email protected]&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@&B5YPBG5BB&#[email protected]@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@[email protected]@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@G!?JYBGY5P55GGPPGGPPGYBG#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@P~5PYY555PPPPP5YBYY#@GBB&&5#&#BB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@G!YJY55YY5YPYY#PBP5#&555##GGBPPJ5#@@@@#&#B&G#########&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@G7JYJY55YYJGP5BYYGGGGPGPGGGGGGG55YB###B##BBB&&&##@@@#PGB&&###&&&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@G7?J5Y55P5JYPPPPPGGGGGPGBBBB#BBP5BG#####B###BB##P&@@&GGP&@@@&YG####&@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@?!JYY5YYPPPPGGGPG#BBGBB#BGY?J5#G55###&BGB&#B##[email protected]###@@P#####GG#@BBG##&@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@Y?JYJ55PPGPBBG5GBPP7^J#PY!:.:5#G#5G5J5#B#Y!~7P#BG##&#@&G#G5G#@BG&[email protected]@@@@@@@@@@@@@@
@@@@@@@@@@@@@@G?Y555PPP5GP5J^PP5J..5#G5^.::G#B&&7.^~Y#Y!J?^^[email protected]#&[email protected]&###GB#BGPP&@@@@@@@@@@@@@
@@@@@@@@@@@@@&JJJYYY5Y57P5P7:BBPJ..YBG5^::^PPP#&P~GB5GY&@@G^P#B&Y#!.!PB^?GB5G#G#&##BGY&@@@@@@@@@@@@@
@@@@@@@@@@@@@#7?JY55PPP75PP?~55P5JY55PBGGBBPPP#####BGGYPGBPPPBB&B#7^7GB.!G5^YP!555PPG5#@@@@@@@@@@@@@
@@@@@@@@@@@@@@[email protected]@@G&@@@@@@@&P#:!BP:5G7PY55YJ7#@@@@@@@@@@@@@
@@@@@@@@@@@@@@J?JY5G5PGGPPGGGGPGGGBGGGBBBB#BGG####B#GGP5###G#&#&&&&&#P#GBBBPGB5GPPP557#@@@@@@@@@@@@@
@@@@@@@@@@@@@#?5PPPPPPPGPGBGGGG#BPPBB##G5JPBB&&PJ?JGB#B5GGB&#G##GB&BPP###B###B#[email protected]@@@@@@@@@@@@
@@@@@@@@@@@@@@YJYY55P55YGPPJ~GB5Y^:J#G57..^Y#BY:...!5#PJ::^?BBP^:^5BBG&7J##?G#[email protected]@@@@@@@@@@@@
@@@@@@@@@@@@@@5JYY5YP557P55~:GG5J.:Y#P5^:::G#BJ:::.~B#B#?.::Y#J.:.?GBGG.!BP:[email protected]@@@@@@@@@@@@
@@@@@@@@&&&&&&YJY55PGPP7PPP!:BBPJ::5#GP~:::B#BJ:::.~##B&@!.:5#Y.::JGB#P.!BP:5G7PY555YJB&&&&&@@@@@@@@
@@@@@@@@&&&&&&BPPP5P55P?55P!:GGPJ..Y#GP^..:B#BJ....~##B&@#~:5#J...?GGB#!?GP?PG5GGBBB##&&&&&@@@@@@@@@
@@@@@@@@@@@@&&&&&&&&####BBBBGGGGPYYPPPPJ???PPPY777!?GPGB##PJPGP555GBBBB####&&&&&&&&&&&&@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&####&&&#################&###&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@ */

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ColiseumNormalReservations is Ownable, ReentrancyGuard {
    error NoContracts();
    error InvalidAmount();
    error AlreadyReserved();
    error AllocationWouldExceedMax();
    error NotQualified();

    uint256 private reservationPrice = 0.5 ether;

    uint256 public reservedCounter = 0;
    uint256 public maxReservable = 205;

    bytes32 private qualifiedMerkleRoot;

    mapping(address => bool) private _reserved;

    constructor() {
    }

    modifier callerIsUser() {
        if (msg.sender != tx.origin) revert NoContracts();
        _;
    }

    function setQualifiedMerkleRoot(bytes32 _qualifiedMerkleRoot)
        external
        onlyOwner
    {
        qualifiedMerkleRoot = _qualifiedMerkleRoot;
    }

    function isValid(address _user, bytes32[] calldata _proof)
        external
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                _proof,
                qualifiedMerkleRoot,
                keccak256(abi.encodePacked(_user))
            );
    }

    function setReservationPrice(uint256 _reservationPrice) external onlyOwner {
        reservationPrice = _reservationPrice;
    }

    function reserve(bytes32[] calldata _proof) external payable callerIsUser {
        if (_reserved[msg.sender]) revert AlreadyReserved();
        if (msg.value != reservationPrice) revert InvalidAmount();
        if (
            !MerkleProof.verify(
                _proof,
                qualifiedMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) revert NotQualified();
        if (reservedCounter + 1 > maxReservable)
            revert AllocationWouldExceedMax();
        _reserved[msg.sender] = true;
        reservedCounter++;
    }

    function addAddressesReserved(address[] calldata _addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (_reserved[_addresses[i]] == false) {
                reservedCounter++;
                _reserved[_addresses[i]] = true;
            }
        }
    }

    function removeAddressesReserved(address[] calldata _addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (_reserved[_addresses[i]] == true) {
                reservedCounter = reservedCounter - 1;
                _reserved[_addresses[i]] = false;
            }
        }
    }

    function setMaxReservable(uint256 _newMaxReservable) external onlyOwner {
        maxReservable = _newMaxReservable;
    }

    function getReservationPrice() external view returns (uint256) {
        return reservationPrice;
    }

    function userReserved(address _user) external view returns (bool) {
        return _reserved[_user];
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}