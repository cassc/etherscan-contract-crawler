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
import "./src/DefaultOperatorFilterer.sol";
import "./ColiseumReservations.sol";
import "./ColiseumReservationsNormal.sol";
import "./ERC721A.sol";
import "./IERC721A.sol";

contract Coliseum is
    ERC721A,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    using Strings for uint256;
    using SafeMath for uint256;

    error MaxSupplyExceeded();
    error NotAllowlisted();
    error MaxPerWalletExceeded();
    error InsufficientValue();
    error PreSaleNotActive();
    error PublicSaleNotActive();
    error NoContracts();
    error NotReserved();
    error SettingMaxSupplyIsFrozen();
    error SoulBoundTokensMayOnlyBeBurned();
    error NotAController();
    error SaleSupplyExceeded();
    error LockedUpPeriodNotOverForToken();
    error PreSaleReservationAlreadyClaimed();
    error PreSaleAlreadyClaimed();
    error NormalReservationAlreadyClaimed();
    error NormalAlreadyClaimed();
    error HighTierAlreadyClaimed();
    error LocksAreFrozen();
    error NotAnOwner();

    ColiseumReservations public reservationContract =
        ColiseumReservations(0x262428D0F12366a486dA19A123FAb4528B6a2bf4);

    ColiseumReservationsNormal public reservationNormalContract =
        ColiseumReservationsNormal(0xcE7f5ABB916b2fcC9505f58aA988cA0C4ED6E34B);

    uint256 public totalReservedPreSale;
    uint256 public totalReservedNormalSale;
    uint256 public presaleCost = 0.5 ether;
    uint256 public normalCost = 0.5 ether;
    uint256 public highTierCost = 3 ether;
    uint256 public publicCost = 3 ether;
    uint256 public deployTime;
    uint256 public deadlineTime;
    uint256 public deployTimeLater;
    uint256 public deadlineTimeLater;
    uint256 public presaleMintedAmount = 0;
    uint256 public normalMintedAmount = 0;
    uint256 public highTierMintedAmount = 0;
    uint256 public soulBoundedAmount = 0;

    uint16 public maxSupplyForPresale = 205;
    uint16 public maxSupplyForNormal = 205;
    uint16 public maxSupplyForHighTier = 123;
    uint16 public maxSupply = 533;

    uint8 public maxMintAmount = 2;

    string private _baseTokenURI =
        "https://nftstorage.link/ipfs/bafybeicksu2nga5i2kwuc5wu2ovbsouwsaisgdyp2rhtrkfu7augoen76y/";

    bool public presaleActive;
    bool public normalActive;
    bool public highTierActive;
    bool public publicSaleActive;
    bool public LocksFrozen;

    bool public soulBoundLockActive = true;
    bool public setMaxSupplyFrozen;

    mapping(address => bool) private _controller;

    mapping(address => bool) private _preSaleReservationClaimed;
    mapping(address => bool) private _normalReservationClaimed;
    mapping(address => bool) private _preSaleClaimed;
    mapping(address => bool) private _normalClaimed;
    mapping(address => bool) private _highTierClaimed;

    mapping(uint256 => bool) private _lockedTokenId;
    mapping(uint256 => bool) private _lockedTokenIdLater;

    bytes32 private presaleMerkleRoot;
    bytes32 private normalMerkleRoot;
    bytes32 private highTierMerkleRoot;

    mapping(uint256 => address) private _soulBoundList;

    mapping(address => uint8) private _amountAddressSoulbounded;
    mapping(uint256 => uint8) private _tokenToTier;

    constructor() ERC721A("Coliseum", "COLISEUM") {
        _mint(msg.sender, 1);
        _tokenToTier[1] = 1;
        deployTime = block.timestamp;
        deadlineTime = 201600;
    }

    modifier onlyController() {
        if (_controller[msg.sender] == false) revert NotAController();
        _;
    }

    modifier callerIsUser() {
        if (msg.sender != tx.origin) revert NoContracts();
        _;
    }

    function freezeSetMaxSupply() external onlyOwner {
        setMaxSupplyFrozen = true;
    }

    function setMaxSupply(uint16 _maxSupply) external onlyOwner {
        if (setMaxSupplyFrozen == true) revert SettingMaxSupplyIsFrozen();
        maxSupply = _maxSupply;
    }

    function setToNormalReservationAmountOfContract() external onlyOwner {
        totalReservedNormalSale = reservationNormalContract.reservedCounter();
    }

    function setToPresaleReservationAmountOfContract() external onlyOwner {
        totalReservedPreSale = reservationNormalContract.reservedCounter();
    }

    function setToNormalReservationAmount(uint256 _amount) external onlyOwner {
        totalReservedNormalSale = _amount;
    }

    function setToPresaleReservationAmount(uint256 _amount) external onlyOwner {
        totalReservedPreSale = _amount;
    }

    function setMaxSupplyForPresale(
        uint16 _maxSupplyForPresale
    ) external onlyOwner {
        maxSupplyForPresale = _maxSupplyForPresale;
    }

    function setMaxSupplyForNormalMint(
        uint16 _maxSupplyForNormal
    ) external onlyOwner {
        maxSupplyForNormal = _maxSupplyForNormal;
    }

    function setMaxSupplyForHighTierMint(
        uint16 _maxSupplyForHighTier
    ) external onlyOwner {
        maxSupplyForHighTier = _maxSupplyForHighTier;
    }

    function setPreSaleCost(uint256 _newPreSaleCost) external onlyOwner {
        presaleCost = _newPreSaleCost;
    }

    function setNormalCost(uint256 _newNormalCost) external onlyOwner {
        normalCost = _newNormalCost;
    }

    function setHighTierCost(uint256 _newHighTierCost) external onlyOwner {
        highTierCost = _newHighTierCost;
    }

    function setPublicSaleCost(uint256 _newPublicCost) external onlyOwner {
        publicCost = _newPublicCost;
    }

    function setReservationContractPreSale(
        ColiseumReservations _contractAddress
    ) external onlyOwner {
        reservationContract = _contractAddress;
    }

    function setReservationContractNormal(
        ColiseumReservationsNormal _contractAddress
    ) external onlyOwner {
        reservationNormalContract = _contractAddress;
    }

    function setTierForTokens(
        uint256[] calldata _tokenIds,
        uint8 _tokenTier
    ) external onlyController {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _tokenToTier[_tokenIds[i]] = _tokenTier;
        }
    }

    function setTierForToken(
        uint256 _tokenId,
        uint8 _tokenTier
    ) external onlyController {
        _tokenToTier[_tokenId] = _tokenTier;
    }

    function setTiersForTokens(
        uint256[] calldata _tokenIds,
        uint8[] calldata _tokenTier
    ) external onlyController {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _tokenToTier[_tokenIds[i]] = _tokenTier[i];
        }
    }

    function presaleReservedMint() external callerIsUser {
        if (!presaleActive) revert PreSaleNotActive();
        if (reservationContract.userReserved(msg.sender) == false)
            revert NotReserved();
        if (presaleMintedAmount + 2 > maxSupplyForPresale)
            revert SaleSupplyExceeded();
        if (totalSupply() - soulBoundedAmount + 2 > maxSupply)
            revert MaxSupplyExceeded();
        if (_preSaleReservationClaimed[msg.sender])
            revert PreSaleReservationAlreadyClaimed();

        _preSaleReservationClaimed[msg.sender] = true;

        _mint(msg.sender, 2);
        presaleMintedAmount += 2;
        _lockedTokenId[totalMinted()] = true;
        _tokenToTier[totalMinted() - 1] = 2;
        _tokenToTier[totalMinted()] = 2;
    }

    function presaleMint(
        bytes32[] calldata _proof
    ) external payable callerIsUser {
        if (!presaleActive) revert PreSaleNotActive();
        if (
            presaleMintedAmount + 2 >
            maxSupplyForPresale - (totalReservedPreSale * 2)
        ) revert SaleSupplyExceeded();
        if (totalSupply() - soulBoundedAmount + 2 > maxSupply)
            revert MaxSupplyExceeded();
        if (
            !MerkleProof.verify(
                _proof,
                presaleMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) revert NotAllowlisted();
        if (msg.value != presaleCost) revert InsufficientValue();
        if (_preSaleClaimed[msg.sender]) revert PreSaleAlreadyClaimed();

        _preSaleClaimed[msg.sender] = true;
        _mint(msg.sender, 2);

        _lockedTokenIdLater[totalMinted()] = true;
        _lockedTokenIdLater[totalMinted() - 1] = true;
        _tokenToTier[totalMinted() - 1] = 2;
        _tokenToTier[totalMinted()] = 2;
    }

    function normalReservedMint() external callerIsUser {
        if (!normalActive) revert PreSaleNotActive();
        if (reservationNormalContract.userReserved(msg.sender) == false)
            revert NotReserved();
        if (
            normalMintedAmount + 1 >
            maxSupplyForNormal - totalReservedNormalSale
        ) revert SaleSupplyExceeded();
        if (totalSupply() - soulBoundedAmount + 1 > maxSupply)
            revert MaxSupplyExceeded();
        if (_normalReservationClaimed[msg.sender])
            revert NormalReservationAlreadyClaimed();

        _normalReservationClaimed[msg.sender] = true;
        normalMintedAmount++;

        _mint(msg.sender, 1);

        _tokenToTier[totalMinted()] = 2;
    }

    function normalMint(
        bytes32[] calldata _proof
    ) external payable callerIsUser {
        if (!normalActive) revert PreSaleNotActive();
        if (normalMintedAmount + 1 > maxSupplyForNormal)
            revert SaleSupplyExceeded();
        if (totalSupply() - soulBoundedAmount + 1 > maxSupply)
            revert MaxSupplyExceeded();
        if (
            !MerkleProof.verify(
                _proof,
                normalMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) revert NotAllowlisted();
        if (msg.value != normalCost) revert InsufficientValue();
        if (_normalClaimed[msg.sender]) revert NormalAlreadyClaimed();

        _normalClaimed[msg.sender] = true;

        normalMintedAmount++;
        _mint(msg.sender, 1);

        _lockedTokenIdLater[totalMinted()] = true;
        _tokenToTier[totalMinted()] = 2;
    }

    function highTierMint(
        bytes32[] calldata _proof
    ) external payable callerIsUser {
        if (!highTierActive) revert PreSaleNotActive();
        if (highTierMintedAmount + 1 > maxSupplyForHighTier)
            revert SaleSupplyExceeded();
        if (totalSupply() - soulBoundedAmount + 1 > maxSupply)
            revert MaxSupplyExceeded();
        if (
            !MerkleProof.verify(
                _proof,
                highTierMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) revert NotAllowlisted();
        if (msg.value != highTierCost) revert InsufficientValue();
        if (_highTierClaimed[msg.sender]) revert HighTierAlreadyClaimed();

        _highTierClaimed[msg.sender] = true;

        highTierMintedAmount++;
        _mint(msg.sender, 1);

        _lockedTokenIdLater[totalMinted()] = true;
        _tokenToTier[totalMinted()] = 1;
    }

    function mint(uint8 _amount) external payable callerIsUser {
        if (!publicSaleActive) revert PublicSaleNotActive();
        if (totalSupply() - soulBoundedAmount + _amount > maxSupply)
            revert MaxSupplyExceeded();

        if (_numberMinted(msg.sender) + _amount > maxMintAmount)
            revert MaxPerWalletExceeded();

        if (msg.value != publicCost * _amount) revert InsufficientValue();

        _mint(msg.sender, _amount);
        _lockedTokenIdLater[totalMinted()] = true;
    }

    function airDrop(address[] calldata targets) external {
        require(
            (_controller[msg.sender] == true) || (owner() == _msgSender()),
            "Caller is not authorized"
        );
        if (targets.length + totalSupply() - soulBoundedAmount > maxSupply)
            revert MaxSupplyExceeded();

        for (uint256 i = 0; i < targets.length; i++) {
            _mint(targets[i], 1);
            _tokenToTier[totalMinted()] = 2;
        }
    }

    function airDropAndSoulbound(
        address[] calldata targets
    ) external onlyOwner {
        for (uint256 i = 0; i < targets.length; i++) {
            soulBoundedAmount++;
            _amountAddressSoulbounded[targets[i]] += 1;
            _mint(targets[i], 1);
            _soulBoundList[totalMinted()] = targets[i];
        }
    }

    function soulboundTokensToAddresses(
        uint256[] calldata tokenIds,
        address[] calldata targets
    ) external onlyOwner {
        for (uint256 i = 0; i < targets.length; i++) {
            if (targets[i] != ownerOf(tokenIds[i])) revert NotAnOwner();
            if (_soulBoundList[tokenIds[i]] == address(0)) {
                _soulBoundList[tokenIds[i]] = targets[i];
                _amountAddressSoulbounded[targets[i]] += 1;
                soulBoundedAmount++;
            }
        }
    }

    function unSoulboundTokens(uint256[] calldata tokenIds) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_soulBoundList[tokenIds[i]] != address(0)) {
                _amountAddressSoulbounded[_soulBoundList[tokenIds[i]]] -= 1;
                _soulBoundList[tokenIds[i]] = address(0);
                soulBoundedAmount--;
            }
        }
    }

    function hasUserSoulbounded(address _user) public view returns (bool) {
        bool result = false;
        for (uint256 i = 1; i <= totalMinted(); i++) {
            if (_soulBoundList[i] == _user) {
                result = true;
            }
        }
        return result;
    }

    function getSoulboundTokensOfUser(
        address _user
    ) public view returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](totalMinted());
        uint256 tokenCount = 0;
        for (uint256 i = 1; i <= totalMinted(); i++) {
            if (_soulBoundList[i] == _user) {
                tokenIds[tokenCount] = i;
                tokenCount++;
            }
        }
        uint256[] memory result = new uint256[](tokenCount);
        for (uint256 j = 0; j < tokenCount; j++) {
            result[j] = tokenIds[j];
        }
        return result;
    }

    function getAllSoulboundedTokens() public view returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](totalMinted());
        uint256 tokenCount = 0;
        for (uint256 i = 1; i <= totalMinted(); i++) {
            if (_soulBoundList[i] != address(0)) {
                tokenIds[tokenCount] = i;
                tokenCount++;
            }
        }
        uint256[] memory result = new uint256[](tokenCount);
        for (uint256 j = 0; j < tokenCount; j++) {
            result[j] = tokenIds[j];
        }
        return result;
    }

    function burn(uint256[] calldata tokenIds) external onlyController {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _soulBoundList[i] = address(0);
            _burn(tokenIds[i]);
        }
    }

    function setMaxMintAmount(uint8 _maxMintAmount) external onlyOwner {
        maxMintAmount = _maxMintAmount;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function togglePublicSale() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function togglePresale() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function toggleNormal() external onlyOwner {
        normalActive = !normalActive;
    }

    function toggleHighTier() external onlyOwner {
        highTierActive = !highTierActive;
    }

    function toggleSoulboundLock() external onlyOwner {
        soulBoundLockActive = !soulBoundLockActive;
    }

    function addControllers(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _controller[_addresses[i]] = true;
        }
    }

    function removeControllers(
        address[] calldata _addresses
    ) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _controller[_addresses[i]] = false;
        }
    }

    function isController(address _address) external view returns (bool) {
        return _controller[_address];
    }

    function setPreSaleMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        presaleMerkleRoot = _newMerkleRoot;
    }

    function setNormalMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        normalMerkleRoot = _newMerkleRoot;
    }

    function setHighTierMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        highTierMerkleRoot = _newMerkleRoot;
    }

    function getSoulboundAmount(address _user) external view returns (uint256) {
        return _amountAddressSoulbounded[_user];
    }

    function isPreSaleValid(
        address _user,
        bytes32[] calldata _proof
    ) external view returns (bool) {
        return
            MerkleProof.verify(
                _proof,
                presaleMerkleRoot,
                keccak256(abi.encodePacked(_user))
            );
    }

    function isNormalValid(
        address _user,
        bytes32[] calldata _proof
    ) external view returns (bool) {
        return
            MerkleProof.verify(
                _proof,
                normalMerkleRoot,
                keccak256(abi.encodePacked(_user))
            );
    }

    function isHighTierValid(
        address _user,
        bytes32[] calldata _proof
    ) external view returns (bool) {
        return
            MerkleProof.verify(
                _proof,
                highTierMerkleRoot,
                keccak256(abi.encodePacked(_user))
            );
    }

    function getTokenTier(uint256 _tokenId) public view returns (uint8) {
        return _tokenToTier[_tokenId];
    }

    function freezeLock() external onlyOwner {
        if (LocksFrozen) revert LocksAreFrozen();
        LocksFrozen = true;
    }

    function setLock(
        uint256 _delayTime,
        bool _updateDeployTime
    ) external onlyOwner {
        if (LocksFrozen) revert LocksAreFrozen();
        if (_updateDeployTime) {
            deployTime = block.timestamp;
            deadlineTime = _delayTime;
        } else {
            deadlineTime = _delayTime;
        }
    }

    function setLockForLater(
        uint256 _delayTime,
        bool _updateDeployTime
    ) external onlyOwner {
        if (LocksFrozen) revert LocksAreFrozen();
        if (_updateDeployTime) {
            deployTimeLater = block.timestamp;
            deadlineTimeLater = _delayTime;
        } else {
            deadlineTimeLater = _delayTime;
        }
    }

    function hasClaimedPreSaleReservation(
        address _user
    ) public view returns (bool) {
        return _preSaleReservationClaimed[_user];
    }

    function hasClaimedPreSaleMint(address _user) public view returns (bool) {
        return _preSaleClaimed[_user];
    }

    function hasClaimedNormalReservation(
        address _user
    ) public view returns (bool) {
        return _normalReservationClaimed[_user];
    }

    function hasClaimedNormalMint(address _user) public view returns (bool) {
        return _normalClaimed[_user];
    }

    function hasClaimedHighTierMint(address _user) public view returns (bool) {
        return _highTierClaimed[_user];
    }

    function islockedTokenId(uint256 _tokenId) public view returns (bool) {
        if (_lockedTokenId[_tokenId] == false) {
            return false;
        } else {
            if (deployTime + deadlineTime > block.timestamp) {
                return true;
            } else {
                return false;
            }
        }
    }

    function islockedTokenIdForLater(
        uint256 _tokenId
    ) public view returns (bool) {
        if (_lockedTokenIdLater[_tokenId] == false) {
            return false;
        } else {
            if (deployTimeLater + deadlineTimeLater > block.timestamp) {
                return true;
            } else {
                return false;
            }
        }
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        if (soulBoundLockActive) {
            if (_soulBoundList[startTokenId] != address(0)) {
                if (!_controller[msg.sender]) {
                    if (to != address(0))
                        revert SoulBoundTokensMayOnlyBeBurned();
                }
            }
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        if (_lockedTokenId[tokenId]) {
            if (deployTime + deadlineTime > block.timestamp)
                revert LockedUpPeriodNotOverForToken();
            _lockedTokenId[tokenId] = false;
        }
        if (_lockedTokenIdLater[tokenId]) {
            if (deployTimeLater + deadlineTimeLater > block.timestamp)
                revert LockedUpPeriodNotOverForToken();
            _lockedTokenIdLater[tokenId] = false;
        }
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        if (_lockedTokenId[tokenId]) {
            if (deployTime + deadlineTime > block.timestamp)
                revert LockedUpPeriodNotOverForToken();
            _lockedTokenId[tokenId] = false;
        }
        if (_lockedTokenIdLater[tokenId]) {
            if (deployTimeLater + deadlineTimeLater > block.timestamp)
                revert LockedUpPeriodNotOverForToken();
            _lockedTokenIdLater[tokenId] = false;
        }
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        if (_lockedTokenId[tokenId]) {
            if (deployTime + deadlineTime > block.timestamp)
                revert LockedUpPeriodNotOverForToken();
            _lockedTokenId[tokenId] = false;
        }
        if (_lockedTokenIdLater[tokenId]) {
            if (deployTimeLater + deadlineTimeLater > block.timestamp)
                revert LockedUpPeriodNotOverForToken();
            _lockedTokenIdLater[tokenId] = false;
        }
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}