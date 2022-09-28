// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Interfaces/BAPGenesisInterface.sol";
import "./Interfaces/BAPMethaneInterface.sol";
import "./Interfaces/BAPUtilitiesInterface.sol";
import "./Interfaces/BAPTeenBullsInterface.sol";
import "./Interfaces/BAPOrchestratorInterfaceV2.sol";

/**
 * A number of codes are defined as error messages.
 * Codes are resembling HTTP statuses. This is the structure
 * CODE:SHORT
 * Where CODE is a number and SHORT is a short word or prase
 * describing the condition
 * CODES:
 * 100  contract status: open/closed, depleted. In general for any flag
 *     causing the mint to not to happen.
 * 200  parameters validation errors, like zero address or wrong values
 * 300  User payment amount errors like not enough funds.
 * 400  Contract amount/availability errors like not enough tokens or empty vault.
 * 500  permission errors, like not whitelisted, wrong address, not the owner.
 */
contract BAPOrchestratorV2 is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    string public project;
    address public bapGenesisAddr;
    address public bapMethAddr;
    address public bapUtilitiesAddr;
    address public bapTeenBullsAddr;
    address public originalOrchestratorAddr;
    address public orchestratorV1Addr;
    address public treasuryWallet;
    BAPGenesisInterface bapGenesis;
    BAPMethaneInterface bapMeth;
    BAPUtilitiesInterface bapUtilities;
    BAPTeenBullsInterface bapTeenBulls;
    BAPOrchestratorInterfaceV2 originalOrchestrator;
    BAPOrchestratorInterfaceV2 orchestratorV1;
    address public secret;
    uint256 public timeCounter = 1 days;
    uint256 public grazingPeriodTime = 31 days;
    mapping(uint256 => uint256) public claimedMeth;
    mapping(uint256 => bool) public mintingRefunded;
    mapping(uint256 => uint256) public godsMintingDate;
    mapping(uint256 => uint256) public bullLastClaim;
    mapping(uint256 => bool) public godBulls;
    bool private refundFlag = false;
    bool private claimFlag = false;
    uint256 godBullIndex = 10010;

    struct SignatureTeenBullStruct {
        address sender;
    }

    struct SignatureGodBullStruct {
        address sender;
        uint256 teen1;
        uint256 teen2;
        uint256 teen3;
        uint256 teen4;
    }

    constructor(
        address _bapGenesis,
        address _bapMethane,
        address _bapUtilities,
        address _bapTeenBulls,
        address _originalOrchestrator,
        address _orchestratorV1
    ) {
        require(_bapGenesis != address(0), "200:ZERO_ADDRESS");
        require(_bapMethane != address(0), "200:ZERO_ADDRESS");
        require(_originalOrchestrator != address(0), "200:ZERO_ADDRESS");

        project = "Bulls & Apes Project";
        bapGenesisAddr = _bapGenesis;
        bapMethAddr = _bapMethane;
        originalOrchestratorAddr = _originalOrchestrator;
        orchestratorV1Addr = _orchestratorV1;
        bapUtilitiesAddr = _bapUtilities;
        bapTeenBullsAddr = _bapTeenBulls;

        bapGenesis = BAPGenesisInterface(bapGenesisAddr);
        bapMeth = BAPMethaneInterface(bapMethAddr);
        originalOrchestrator = BAPOrchestratorInterfaceV2(
            _originalOrchestrator
        );
        orchestratorV1 = BAPOrchestratorInterfaceV2(_orchestratorV1);
        bapUtilities = BAPUtilitiesInterface(bapUtilitiesAddr);
        bapTeenBulls = BAPTeenBullsInterface(bapTeenBullsAddr);
    }

    function setGenesisContract(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "200:ZERO_ADDRESS");
        bapGenesisAddr = _newAddress;
        bapGenesis = BAPGenesisInterface(bapGenesisAddr);
    }

    function setMethaneContract(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "200:ZERO_ADDRESS");
        bapMethAddr = _newAddress;
        bapMeth = BAPMethaneInterface(bapMethAddr);
    }

    function setUtilitiesContract(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "200:ZERO_ADDRESS");
        bapUtilitiesAddr = _newAddress;
        bapUtilities = BAPUtilitiesInterface(bapUtilitiesAddr);
    }

    function setTeenBullsContract(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "200:ZERO_ADDRESS");
        bapTeenBullsAddr = _newAddress;
        bapTeenBulls = BAPTeenBullsInterface(bapTeenBullsAddr);
    }

    function initializeGodBulls(uint256[] memory gods, bool godBullFlag)
        external
        onlyOwner
    {
        uint256 bullsCount = gods.length;
        for (uint256 index = 0; index < bullsCount; index++) {
            godBulls[gods[index]] = godBullFlag;
        }
    }

    function claimMeth(
        bytes memory signature,
        uint256[] memory bulls,
        uint256[] memory gods
    ) external nonReentrant {
        uint256 bullsCount = bulls.length;
        uint256 godsCount = gods.length;

        require(
            _verifyClaimMeth(signature, bullsCount, godsCount),
            "Invalid Signature"
        );
        uint256 amount = 0;
        for (uint256 index = 0; index < godsCount; index++) {
            require(
                godBulls[gods[index]] == true || gods[index] > godBullIndex,
                "Not a God Bull"
            );
        }
        for (uint256 index = 0; index < bullsCount; index++) {
            require(godBulls[bulls[index]] == false, "Not a OG Bull");
        }
        for (uint256 index = 0; index < bullsCount; index++) {
            amount += _claimRewardsFromToken(bulls[index], false);
        }
        for (uint256 index = 0; index < godsCount; index++) {
            amount += _claimRewardsFromToken(gods[index], true);
        }
        bapMeth.claim(_msgSender(), amount);
    }

    function setTreasuryWallet(address _newTreasuryWallet) external onlyOwner {
        require(_newTreasuryWallet != address(0), "200:ZERO_ADDRESS");
        treasuryWallet = _newTreasuryWallet;
    }

    function setWhitelistedAddress(address _secret) external onlyOwner {
        require(_secret != address(0), "200:ZERO_ADDRESS");
        secret = _secret;
    }

    function setGrazingPeriodTime(uint256 _grazingPeriod) external onlyOwner {
        grazingPeriodTime = _grazingPeriod;
    }

    function setTimeCounter(uint256 _timeCounter) external onlyOwner {
        timeCounter = _timeCounter;
    }

    function totalClaimed(uint256 tokenId) public view returns (uint256) {
        return
            claimedMeth[tokenId] +
            orchestratorV1.claimedMeth(tokenId) +
            originalOrchestrator.claimedMeth(tokenId);
    }

    function getClaimableMeth(uint256 tokenId, bool isGodBull)
        external
        view
        returns (uint256 methAmount)
    {
        require(bapGenesis.tokenExist(tokenId), "Token does exist");

        uint256 startTime = bullLastClaim[tokenId];
        uint256 claimed = 0;

        // AFTER THE FIRST CLAIM THIS BLOCK GETS OMITTED
        if (startTime == 0) {
            if (godBulls[tokenId] == true || tokenId > godBullIndex) {
                if (godsMintingDate[tokenId] == 0) {
                    return 0;
                }
                startTime = godsMintingDate[tokenId];
            } else {
                startTime = bapGenesis.mintingDatetime(tokenId);
            }

            claimed = totalClaimed(tokenId);
        }

        uint256 timeFromCreation = (block.timestamp - startTime).div(
            timeCounter
        );

        methAmount =
            _dailyRewards(isGodBull, tokenId) *
            timeFromCreation -
            claimed;
    }

    function initializeGodMintingDate(
        uint256[] memory gods,
        uint256[] memory mintingDates
    ) external onlyOwner {
        uint256 bullsCount = gods.length;
        uint256 mintingDatesCount = mintingDates.length;
        require(bullsCount == mintingDatesCount, "Arrays are incorrect");
        for (uint256 index = 0; index < bullsCount; index++) {
            godsMintingDate[gods[index]] = mintingDates[index];
        }
    }

    function generateTeenBull(bytes memory signature) external nonReentrant {
        require(_verifyGenerateTeenBull(signature), "Signature is invalid");
        bapMeth.pay(600, 300);
        bapTeenBulls.generateTeenBull();
        bapUtilities.burn(1, 1);
    }

    function generateGodBull(
        bytes memory signature,
        uint256 bull1,
        uint256 bull2,
        uint256 bull3,
        uint256 bull4
    ) external nonReentrant {
        require(
            _verifyGenerateGodBull(signature, bull1, bull2, bull3, bull4),
            "Invalid Signature"
        );
        require(
            bapUtilities.balanceOf(msg.sender, 2) > 0,
            "Not enough Merger Orbs"
        );
        bapMeth.pay(4800, 2400);
        bapGenesis.generateGodBull();
        bapTeenBulls.burnTeenBull(bull1);
        bapTeenBulls.burnTeenBull(bull2);
        bapTeenBulls.burnTeenBull(bull3);
        bapTeenBulls.burnTeenBull(bull4);
        bapUtilities.burn(2, 1);
        godsMintingDate[bapGenesis.minted()] = block.timestamp;
    }

    function buyIncubator(
        bytes memory signature,
        uint256 bull1,
        uint256 bull2
    ) external nonReentrant {
        require(
            _verifyBuyIncubator(signature, bull1, bull2),
            "Invalid Signature"
        );
        bapGenesis.breedBulls(bull1, bull2);
        bapMeth.pay(600, 300);
        bapUtilities.purchaseIncubator();
    }

    function buyMergeOrb(bytes memory signature, uint256 teen)
        external
        nonReentrant
    {
        require(
            _verifyBuyMergeOrb(signature, teen),
            "Buy Merge Orb Signature is not valid"
        );
        bapMeth.pay(2400, 1200);
        bapTeenBulls.burnTeenBull(teen);
        bapUtilities.purchaseMergerOrb();
    }

    function setRefundFlag(bool _refundFlag) external onlyOwner {
        refundFlag = _refundFlag;
    }

    function setClaimFlag(bool _claimFlag) external onlyOwner {
        claimFlag = _claimFlag;
    }

    function refund(uint256 tokenId) external nonReentrant {
        require(treasuryWallet != address(0), "200:ZERO_ADDRESS");
        require(
            _refundPeriodAllowed() || refundFlag,
            "The Refund is not allowed"
        );
        require(
            mintingRefunded[tokenId] == false &&
                originalOrchestrator.mintingRefunded(tokenId) == false,
            "The token was already refunded"
        );
        require(
            bapGenesis.breedings(tokenId) == bapGenesis.maxBreedings(),
            "The bull breed"
        );

        require(totalClaimed(tokenId) == 0, "Tokens claimed for this Bull");

        require(
            bapGenesis.notAvailableForRefund(tokenId) == false,
            "The token was transfered at an invalid time"
        );

        bapGenesis.refund(msg.sender, tokenId);
        bapGenesis.safeTransferFrom(msg.sender, treasuryWallet, tokenId);
        mintingRefunded[tokenId] = true;
    }

    function _verifyBuyIncubator(
        bytes memory signature,
        uint256 token1,
        uint256 token2
    ) internal view returns (bool) {
        // Pack the payload
        bytes32 freshHash = keccak256(abi.encode(msg.sender, token1, token2));
        // Get the packed payload hash
        bytes32 candidateHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );

        // Verify if the fresh hash is signed with the provided signature
        return _verifyHashSignature(candidateHash, signature);
    }

    function _verifyBuyMergeOrb(bytes memory signature, uint256 teen)
        internal
        view
        returns (bool)
    {
        // Pack the payload
        bytes32 freshHash = keccak256(abi.encode(msg.sender, teen));
        // Get the packed payload hash
        bytes32 candidateHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );
        // Verify if the fresh hash is signed with the provided signature
        return _verifyHashSignature(candidateHash, signature);
    }

    function _verifyClaimMeth(
        bytes memory signature,
        uint256 bullsCount,
        uint256 godsCount
    ) internal view returns (bool) {
        // Pack the payload
        bytes32 freshHash = keccak256(
            abi.encode(msg.sender, bullsCount, godsCount)
        );
        // Get the packed payload hash
        bytes32 candidateHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );
        // Verify if the fresh hash is signed with the provided signature
        return _verifyHashSignature(candidateHash, signature);
    }

    function _verifyGenerateGodBull(
        bytes memory signature,
        uint256 bull1,
        uint256 bull2,
        uint256 bull3,
        uint256 bull4
    ) internal view returns (bool) {
        // Pack the payload
        bytes32 freshHash = keccak256(
            abi.encode(msg.sender, bull1, bull2, bull3, bull4)
        );
        // Get the packed payload hash
        bytes32 candidateHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );
        // Verify if the fresh hash is signed with the provided signature
        return _verifyHashSignature(candidateHash, signature);
    }

    function _verifyGenerateTeenBull(bytes memory signature)
        internal
        view
        returns (bool)
    {
        // Pack the payload
        bytes32 freshHash = keccak256(abi.encode(msg.sender));
        // Get the packed payload hash
        bytes32 candidateHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );
        // Verify if the fresh hash is signed with the provided signature
        return _verifyHashSignature(candidateHash, signature);
    }

    function _verifyHashSignature(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return false;
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        address signer = address(0);
        if (v == 27 || v == 28) {
            // solium-disable-next-line arg-overflow
            signer = ecrecover(hash, v, r, s);
        }
        return secret == signer;
    }

    function _dailyRewards(bool godBull, uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        if (godBull) return 20;
        if (bapGenesis.breedings(tokenId) == 0 && bullLastClaim[tokenId] != 0)
            return 15;
        return 10;
    }

    function _refundPeriodAllowed() internal view returns (bool) {
        return
            block.timestamp >= bapGenesis.genesisTimestamp() + 31 days &&
            block.timestamp <= bapGenesis.genesisTimestamp() + 180 days;
    }

    function _claimRewardsFromToken(uint256 tokenId, bool isGodBull)
        internal
        returns (uint256)
    {
        require(
            bapGenesis.genesisTimestamp() + grazingPeriodTime <=
                block.timestamp ||
                claimFlag,
            "Grazing Period is not Finished"
        );
        require(bapGenesis.tokenExist(tokenId), "Token does exist");
        require(
            bapGenesis.ownerOf(tokenId) == _msgSender(),
            "Sender is not the owner"
        );

        uint256 startTime = bullLastClaim[tokenId];
        uint256 claimed = 0;

        // AFTER THE FIRST CLAIM THIS BLOCK GETS OMITTED
        if (startTime == 0) {
            if (godBulls[tokenId] == true || tokenId > godBullIndex) {
                if (godsMintingDate[tokenId] == 0) {
                    return 0;
                }
                startTime = godsMintingDate[tokenId];
            } else {
                startTime = bapGenesis.mintingDatetime(tokenId);
            }

            claimed = totalClaimed(tokenId);
        }

        uint256 timeFromCreation = (block.timestamp - startTime).div(
            timeCounter
        );

        uint256 methAmount = _dailyRewards(isGodBull, tokenId) *
            timeFromCreation -
            claimed;

        claimedMeth[tokenId] += methAmount;
        bullLastClaim[tokenId] = block.timestamp;

        return methAmount;
    }
}