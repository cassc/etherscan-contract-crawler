// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//             ____
//      _,-ddd888888bbb-._
//    d88888888888888888888b
//  d888888888888888888888888b      $$$$$$\   $$$$$$\   $$$$$$\
// 6888888888888888888888888889    $$  __$$\ $$  __$$\ $$  __$$\
// 68888b8""8q8888888p8""8d88889   $$ /  \__|$$ /  \__|$$ /  \__|
// `d8887     p88888q     4888b'   $$ |      $$ |      \$$$$$$\
//  `d8887    p88888q    4888b'    $$ |      $$ |       \____$$\
//    `d887   p88888q   488b'      $$ |  $$\ $$ |  $$\ $$\   $$ |
//      `d8bod8888888dob8b'        \$$$$$$  |\$$$$$$  |\$$$$$$  |
//        `d88888888888d'           \______/  \______/  \______/
//          `d8888888b' hjw
//            `d8888b' `97
//              `bd'

contract CCSNFT is ERC721, ReentrancyGuard, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    using Counters for Counters.Counter;

    uint256 public _vipSupply = 2000;
    uint256 public _publicSupply = 2000;
    uint256 public _wlSupply = 0;
    uint256 private _vipMintPrice = .001 ether;
    uint256 private _publicMintPrice = .05 ether;
    uint256 private _wlMintPrice = 0.01 ether;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _vipMintCounter;
    Counters.Counter private _publicMintCounter;
    Counters.Counter private _wlMintCounter;

    mapping(address => bool) private _vipMinted;

    string private _tokenBaseURI;
    address private _publicMintContract;
    address private _wlMintContract;

    modifier onlyAdmin() {
        require(
            hasRole(ADMIN_ROLE, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "User is not an admin"
        );
        _;
    }

    constructor(string memory initBaseURI)
        ERC721("Cosmic Corpse Society", "CCS")
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        setBaseURI(initBaseURI);
    }

    function addAdmin(address newAdmin) external onlyAdmin {
        _grantRole(ADMIN_ROLE, newAdmin);
    }

    function removeAdmin(address oldAdmin) external onlyAdmin {
        _revokeRole(ADMIN_ROLE, oldAdmin);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory URI) public onlyAdmin {
        _tokenBaseURI = URI;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return _tokenBaseURI;
    }

    function getPublicMintContract() external view returns (address) {
        return _publicMintContract;
    }

    function setPublicMintContract(address contractAddress) external onlyAdmin {
        _publicMintContract = contractAddress;
    }

    function setWlMintContract(address contractAddress) external onlyAdmin {
        _wlMintContract = contractAddress;
    }

    function totalSupply() external view returns (uint256) {
        return
            _vipMintCounter.current() +
            _publicMintCounter.current() +
            _wlMintCounter.current();
    }

    function reallocateSupply(
        uint256 fromSupply,
        uint256 toSupply,
        uint256 amount
    ) external onlyAdmin {
        if (fromSupply == 1) _vipSupply = _vipSupply - amount;
        if (fromSupply == 2) _publicSupply = _publicSupply - amount;
        if (fromSupply == 3) _wlSupply = _wlSupply - amount;
        if (toSupply == 1) _vipSupply = _vipSupply + amount;
        if (toSupply == 2) _publicSupply = _publicSupply + amount;
        if (toSupply == 3) _wlSupply = _wlSupply + amount;
    }

    function overrideVipMintStatus(address minter, bool newState)
        external
        onlyAdmin
    {
        _vipMinted[minter] = newState;
    }

    function safeMint(
        address to,
        uint256 amount,
        uint256 mintType
    ) internal {
        for (uint256 i = 1; i <= amount; i++) {
            if (
                (mintType == 0 && _vipMintCounter.current() >= _vipSupply) ||
                (mintType == 1 &&
                    _publicMintCounter.current() >= _publicSupply) ||
                (mintType == 2 && _wlMintCounter.current() >= _wlSupply)
            ) {
                break;
            }
            _tokenIdCounter.increment();
            if (mintType == 0) {
                _vipMintCounter.increment();
            } else if (mintType == 1) {
                _publicMintCounter.increment();
            } else {
                _wlMintCounter.increment();
            }
            _safeMint(to, _tokenIdCounter.current());
        }
    }

    function vipMint() internal nonReentrant {
        uint256 vipMintsLeft = _vipMintCounter.current() >= _vipSupply
            ? 0
            : _vipSupply - _vipMintCounter.current();

        require(vipMintsLeft > 0, "LOYALTY_MINT_SOLD_OUT");
        require(!_vipMinted[msg.sender], "ALREADY_LOYALTY_MINTED");

        uint256 vipMintsEligibleFor = getVipMintLimit(msg.sender);
        uint256 vipMintsPaidFor = msg.value / _vipMintPrice;

        uint256 vipsToMint = vipMintsPaidFor <= vipMintsEligibleFor
            ? vipMintsPaidFor
            : vipMintsEligibleFor;

        uint256 validPaid = _vipMintPrice * vipMintsEligibleFor;
        uint256 remainder = msg.value > validPaid ? msg.value - validPaid : 0;

        if (vipsToMint <= vipMintsLeft) {
            safeMint(msg.sender, vipsToMint, 0);
            _vipMinted[msg.sender] = true;
        } else {
            safeMint(msg.sender, vipMintsLeft, 0);
            remainder = ((vipMintsPaidFor - vipMintsLeft) * _vipMintPrice);
            _vipMinted[msg.sender] = true;
        }
        if (remainder > 0) {
            payable(msg.sender).transfer(remainder);
        }
    }

    function publicMint(address recipient) external payable {
        require(msg.sender == _publicMintContract, "INVALID_SENDER");
        uint256 publicMintsLeft = _publicMintCounter.current() >= _publicSupply
            ? 0
            : _publicSupply - _publicMintCounter.current();

        require(publicMintsLeft > 0, "PUBLIC_MINT_SOLD_OUT");

        uint256 publicMintsPaidFor = msg.value / _publicMintPrice;
        uint256 remainder = msg.value > _publicMintPrice
            ? msg.value % _publicMintPrice
            : 0;

        if (publicMintsPaidFor <= publicMintsLeft) {
            safeMint(recipient, publicMintsPaidFor, 1);
        } else {
            safeMint(recipient, publicMintsLeft, 1);
            remainder += ((publicMintsPaidFor - publicMintsLeft) *
                _publicMintPrice);
        }
        if (remainder > 0) {
            payable(recipient).transfer(remainder);
        }
    }

    function wlMint(address recipient) external payable {
        require(msg.sender == _wlMintContract, "INVALID_SENDER");
        uint256 wlMintsLeft = _wlMintCounter.current() >= _wlSupply
            ? 0
            : _wlSupply - _wlMintCounter.current();

        require(wlMintsLeft > 0, "WL_MINT_SOLD_OUT");

        uint256 remainder = msg.value > _wlMintPrice
            ? msg.value - _wlMintPrice
            : 0;

        if (wlMintsLeft > 0) {
            safeMint(recipient, 1, 2);
        } else {
            remainder += _wlMintPrice;
        }
        if (remainder > 0) {
            payable(recipient).transfer(remainder);
        }
    }

    function getVipMintLimit(address minter) internal view returns (uint256) {
        uint256 asacCount = ERC721(0x96FC56721D2b79485692350014875b3b67CB00eB)
            .balanceOf(minter);
        uint256 masacCount = ERC721(0xDAEeCd365BcEc74656Bd4068879dB469e815641d)
            .balanceOf(minter);
        uint256 ascCount = ERC721(0xB183166B4197c61E9410066C1d24e005B6E4755b)
            .balanceOf(minter);

        return asacCount + (masacCount / 2) + ascCount;
    }

    function getVipMintedCount() external view returns (uint256) {
        return _vipMintCounter.current();
    }

    function getPublicMintedCount() external view returns (uint256) {
        return _publicMintCounter.current();
    }

    function getWlMintedCount() external view returns (uint256) {
        return _wlMintCounter.current();
    }

    function withdrawAll() external onlyAdmin {
        require(address(this).balance > 0, "ZERO_BALANCE");
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {
        require(
            _vipMintCounter.current() < _vipSupply,
            "LOYALTY_MINT_SOLD_OUT"
        );
        require(msg.value >= .001 ether, "INSUFFICIENT_FUNDS");
        vipMint();
    }
}