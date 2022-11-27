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

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Coliseum is ERC721, Ownable, ReentrancyGuard {

    using Strings for uint256;
    using SafeMath for uint256;

    uint256 public constant MAX_TRADEABLE_SUPPLY = 310;
    uint256 public constant MINT_PRICE_TIER_ONE = 0;
    uint256 public constant MINT_PRICE_TIER_TWO = 3 ether;
    uint256 public constant MINT_PRICE_TIER_THREE = 4 ether;
    uint256 public constant MAX_MINT_PER_TX = 1;
    uint256 public totalSupply = 0;

    struct Tier {
        uint16 id;
        uint256 basePrice;
    }

    mapping(uint256 => Tier) public tiers;
    uint16 tierNum;

    mapping(bytes32 => bool) private _usedHashes;
    mapping(address => uint256) private _tierIndex;

    mapping(address => bool) private soulbounds;
    uint256 public soulboundNum;
    bool public soulboundListClosed = false;

    bool public saleStarted = false;
    string public baseTokenURI = "";
    address private _signerAddress;

    event Minted(address indexed to);
    event Airdropped(address indexed to);

    constructor() ERC721("Coliseum", "COLISEUM") { 

        tiers[1] = Tier(1, MINT_PRICE_TIER_ONE);
        tiers[2] = Tier(2, MINT_PRICE_TIER_TWO);
        tiers[3] = Tier(3, MINT_PRICE_TIER_THREE);

        tierNum = 3;
    }

    function mint(bytes memory _sig, uint256 _tier)
        external
        payable
        nonReentrant
    {
        require(saleStarted, "MINT_NOT_STARTED");

        if (!soulbounds[msg.sender]) {
            require(totalSupply + MAX_MINT_PER_TX <= MAX_TRADEABLE_SUPPLY, "MAX_TRADEABLE_SUPPLY_REACHED");
        }

        bytes32 hash = keccak256(abi.encodePacked(msg.sender, _tier));
        require(!_usedHashes[hash], "HASH_ALREADY_USED");
        require(_matchSigner(hash, _sig), "INVALID_SIGNER");

        // User can mint with only one address, as some of the tokens are soulbound
        require(_tierIndex[msg.sender] == 0, "ADDRESS_ALREADY_MINTED");

        require(msg.value == tiers[_tier].basePrice, "INVALID_ETH_SENT");

        _usedHashes[hash] = true;
        _tierIndex[msg.sender] = _tier;

        _safeMint(msg.sender, totalSupply + MAX_MINT_PER_TX);

        if (!soulbounds[msg.sender]) {
            totalSupply += MAX_MINT_PER_TX;
        }

        emit Minted(msg.sender);
    }

    /**
     * Only soulbound can be airdropped
     */
    function airdrop (address _to, uint256 _tier) external onlyOwner {
        require(soulbounds[_to] == true, "ADDRESS_IS_NOT_ON_SOULBOUNDS");

        _tierIndex[_to] = _tier;
        _mint(_to, totalSupply + MAX_MINT_PER_TX);

        emit Airdropped(_to);
    }

    function _matchSigner(bytes32 _hash, bytes memory _signature) private view returns(bool) {
        return _signerAddress == ECDSA.recover(ECDSA.toEthSignedMessageHash(_hash), _signature);
    }

    function whichTierIsAddress(address _address) public view returns(uint256) {
        return _tierIndex[_address];
    }

    function isAddressSoulbound(address _address) public view returns(bool) {
        return soulbounds[_address];
    }

    /**
     * @dev Available for for external checks.
     */
    function isAllowedToMint (
        address _sender,
        uint256 _tier,
        bytes memory _sig
    ) public view returns(string memory) {
        bytes32 _hash = keccak256(abi.encodePacked(_sender, _tier));
        if (!_matchSigner(_hash, _sig)) {
            return "SIGNER_NOT_MATCHING";
        }
        if (_usedHashes[_hash]) {
            return "HASH_ALREADY_USED";
        }
        
        return "HASH_USABLE";
    }

    function withdraw(address payable _to) external onlyOwner {
        require(_to != address(0), "WITHDRAW_ADDRESS_ZERO");
        require(address(this).balance > 0, "EMPTY_BALANCE");
        _to.transfer(address(this).balance);
    }

    function withdrawERC20(address _token, address payable _to) external onlyOwner {
        require(_to != address(0), "WITHDRAW_ADDRESS_ZERO");

        IERC20 targetToken = IERC20(_token);
        uint256 balance = targetToken.balanceOf(address(this));
        require(balance > 0, "EMPTY_BALANCE");

        targetToken.transferFrom(address(this), _to, balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setSaleStarted(bool _saleStarted) external onlyOwner {
        saleStarted = _saleStarted;
    }

    function getSignerAddress() public view onlyOwner returns(address) {
        return _signerAddress;
    }

    function setSignerAddress(address _signer) external onlyOwner {
        require(_signer != address(0), "SIGNER_ADDRESS_ZERO");
        _signerAddress = _signer;
    }

    function burn(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Only the owner of the token can burn it.");
        _burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256) internal virtual override {
        if (soulbounds[from] == true) {
            require(from == address(0) || to == address(0), "This a Soulbound token. It cannot be transferred. It can only be burned by the token owner.");
        }
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function addAddresses(address[] calldata  _members) public onlyOwner {
        require (!soulboundListClosed, "CANT_ADD_SOULBOUND_LIST_CLOSED");

        uint256 i = 0;

        for(i;i<_members.length;i++){
            address member = _members[i];
            if(soulbounds[member] == false){
                soulbounds[member] = true;
                soulboundNum++;
            }
        }
    }

    function removeAddresses(address[] calldata  _members) public onlyOwner {
        require (!soulboundListClosed, "CANT_REMOVE_SOULBOUND_LIST_CLOSED");

        uint256 i = 0;

        for(i;i<_members.length;i++){
            address member = _members[i];
            if(soulbounds[member] == true){
                soulbounds[member] = false;
                soulboundNum--;
            }
        }
    }

    function closeAddressList() public onlyOwner {
        soulboundListClosed = true;
    }
}