/*
  ____            __                                    
 |  _ \ ___ _ __ / _| ___  _ __ _ __ ___   ___ _ __ ___ 
 | |_) / _ \ '__| |_ / _ \| '__| '_ ` _ \ / _ \ '__/ __|
 |  __/  __/ |  |  _| (_) | |  | | | | | |  __/ |  \__ \
 |_|   \___|_|  |_|  \___/|_|  |_| |_| |_|\___|_|  |___/
                                                        
by maciej wisniewski                                                                                                                   
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

interface IContract {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface ICryptoPunks {
    function punkIndexToAddress(uint256 tokenId)
        external
        view
        returns (address owner);
}

interface IDelegationRegistry {
    function checkDelegateForToken(
        address delegate,
        address vault,
        address contract_,
        uint256 tokenId
    ) external view returns (bool);
}

contract Performers is ERC721Enumerable, ERC2981, ReentrancyGuard, Ownable {
    struct Token {
        address tokenContract;
        uint256 tokenId;
    }

    struct Record {
        address tokenContract1;
        uint256 tokenId1;
        address tokenContract2;
        uint256 tokenId2;
    }

    mapping(uint256 => Token) public getSignedTokenByIndex;
    mapping(uint256 => Record) public getTokenRecord;
    mapping(address => bool) public isContractListed;
    mapping(uint256 => string) public getInscriptionId;
    mapping(string => uint256) public getOrdinalTokenId;
    mapping(uint256 => Token[]) private performanceRecord;
    mapping(address => uint256[]) private signedTokens;
    mapping(address => mapping(uint256 => bool)) private minted;
    mapping(address => mapping(uint256 => bool)) private claimed;
    mapping(uint256 => uint256[]) private recording;
    mapping(address => address) private deployerList;
    mapping(uint256 => uint256[]) private performedIn;
    mapping(uint256 => uint256[]) private musSig;

    string public constant GENERATIVE_CATALOG_ORDINAL_INSCRIPTION =
        "b3be475e04d29a5e970be08791b514215dff849357bf8a88f79aa44fa8a4bfbbi0";
    uint256 public constant MAX_MUS_SIGS = 10000;
    uint256 public constant NUM_MUS_SIGS_RESERVED = 100;

    address private constant CRYPTO_PUNKS_ADDRESS =
        0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    uint256 private constant SIG_LENGTH = 18;
    uint256 private constant UNIT_LENGTH = 3;
    uint256 private constant MOD = 214;

    IDelegationRegistry public delegationRegistry;
    uint256 public supportedCollectionRoyaltyPercentage = 10;
    uint256 public musSigsClaimed = 0;
    uint256 public ownerMusSigsClaimed = 0;
    uint256 public signatureFee = 0 ether;
    uint256 public performanceFee = 0 ether;

    bool private paused = true;
    string private animationURI = "https://www.performers.cc/rec?tokenId=";
    string private imageURI = "https://www.performers.cc/api/";
    string private jsonURI = "https://www.performers.cc/api/json/";
    string private inscriptionURI = "https://www.performers.cc/api/ins/";
    string[] private strokeColor = [
        "aquamarine",
        "bisque",
        "blanchedalmond",
        "blue",
        "blueviolet",
        "burlywood",
        "cadetblue",
        "chartreuse",
        "chocolate",
        "coral",
        "cornflowerblue",
        "crimson",
        "cyan",
        "darkcyan",
        "darkgoldenrod",
        "darkkhaki",
        "darkorange",
        "darkred",
        "darksalmon",
        "darkseagreen",
        "darkturquoise",
        "deeppink",
        "deepskyblue",
        "dodgerblue",
        "firebrick",
        "forestgreen",
        "gold",
        "goldenrod",
        "gray",
        "greenyellow",
        "hotpink",
        "indianred",
        "khaki",
        "lawngreen",
        "lightblue",
        "lightcoral",
        "lightgreen",
        "lightpink",
        "lightsalmon",
        "lightseagreen",
        "lightskyblue",
        "lightslategray",
        "lightsteelblue",
        "limegreen",
        "magenta",
        "maroon",
        "mediumaquamarine",
        "mediumblue",
        "mediumorchid",
        "mediumpurple",
        "mediumseagreen",
        "mediumslateblue",
        "mediumspringgreen",
        "mediumturquoise",
        "mediumvioletred",
        "moccasin",
        "navajowhite",
        "olive",
        "olivedrab",
        "orange",
        "orchid",
        "palegoldenrod",
        "palegreen",
        "paleturquoise",
        "palevioletred",
        "papayawhip",
        "peachpuff",
        "peru",
        "pink",
        "plum",
        "powderblue",
        "purple",
        "red",
        "rosybrown",
        "royalblue",
        "saddlebrown",
        "salmon",
        "sandybrown",
        "seagreen",
        "sienna",
        "silver",
        "skyblue",
        "slateblue",
        "slategray",
        "springgreen",
        "steelblue",
        "tan",
        "teal",
        "thistle",
        "tomato",
        "turquoise",
        "violet",
        "yellow",
        "yellowgreen",
        "darkgray",
        "dimgray",
        "darkgray",
        "black",
        "darkblue",
        "darkgreen",
        "darkslateblue",
        "darkslategray",
        "indigo",
        "midnightblue",
        "navy",
        "darkmagenta",
        "darkolivegreen"
    ];
    string[] private layoutPath = [
        "M165.3,100.2c-56.6,3.9-69.3-2.3-79.6,7.8c-6.2,6-7,13.4-4.1,57.6c5.7,87.6,11.5,97.3,18.8,99.6 c12.5,3.9,20-17,38.8-15.9c26.7,1.6,30.1,45.2,57.1,52.2c34.4,9,89.8-45.5,81.2-75.9c-7.4-26.3-61-28.8-60-43.3 c1-14.1,52.4-12.2,56.7-31.4c4-18-34.6-49.3-74.7-53.1C190.6,96.9,191.5,98.4,165.3,100.2z",
        "M181.2,177.8c-6.5-29.2,98.1-58.4,94.3-97.6C272.9,53.3,220,31,175.9,34.5c-46,3.7-85.9,35.6-101.6,73.9 c-31.6,76.8,32.2,183.8,100.4,189c52.4,4,108.6-52,100.8-78C267.1,191.6,186.8,203,181.2,177.8z",
        "M300.4,43.1c54.7,50.9,31.8,178-42,240.4C171,357.2,40.1,317.1,39.1,305.9c-0.7-8.8,78.3-18.3,78-37.1 c-0.3-16.1-58.4-22.7-58.4-40c0-15.8,48.3-19.2,51.8-40.8c3.5-21.9-43.8-31.9-48.6-62.4c-5.5-35.6,50.1-77.4,96.7-93.9 C167.7,28.5,253.5-0.5,300.4,43.1z",
        "M297.9,288c-27.2,16.9-60.1-39.7-131.4-41.7C91.3,244.2,33.4,304.5,26.1,295c-7.4-9.6,62.9-54.4,55.5-105.3 c-5.4-36.8-49.3-53.9-42.4-71.4c6.5-16.6,46.4-0.7,79.2-27.3C140.3,73,135,55.8,153.8,47.1c27.2-12.4,74.2,6.9,83.3,35.6 c10.6,33.7-35.7,66.7-23.3,84.5c11.9,16.9,52.4-8.1,78,11C322.3,201.1,324.3,271.6,297.9,288z",
        "M66.5,78.2c2.6-2.7,48.2-47.8,111.8-38c56.6,8.8,85.8,54.6,97.6,73.1c23.5,36.9,26.3,72.5,27.3,89 c2.2,33.5,4.7,71.3-21.2,97.1c-30.9,30.8-90.2,32.8-109,9.4c-15.6-19.5,5.5-45.8-9.4-62c-22.3-24.3-80.5,22.7-113.5,0.4 C15.9,224,15.4,130.5,66.5,78.2z",
        "M169.8,175.3c19.5,4.4,47.5-19.4,49.8-41.6c2.4-24-26.3-33.6-24.9-55.5c1.9-29.5,57.1-63.5,90.6-50.2 c42.7,17,46.1,109.2,29.8,170.6c-6.8,25.6-27.6,103.8-91.8,124.5c-74.7,24.1-167.3-42.6-188.6-121.2C16.9,136.2,53.4,79.1,55.9,75.3 c8.7-13.1,30-45.4,49.8-41.6C142.9,40.7,129.6,166.2,169.8,175.3z"
    ];

    event SalePaused(bool paused);
    event SignatureClaimed(address adr, uint256 tokenId);
    event PerformanceUpdated(uint256 recordingId);

    error NotTokenOwner();
    error SaleNotOpen();
    error ZeroAddress();
    error SoldOut();
    error ReservedSupplySoldOut();
    error ContractNotIncluded();
    error IncorrectAmount();
    error MusicSignatureClaimed();
    error IdenticalPerformers();
    error AlreadyMintedRecording();
    error NonexistentToken();
    error NotRecordingOwner();
    error NoMusicSignature();

    constructor() ERC721("Performers", "PFT") Ownable() {
        delegationRegistry = IDelegationRegistry(
            0x00000000000076A84feF008CDAbe6409d2FE638B
        );
        _setDefaultRoyalty(owner(), 500);

        isContractListed[0xbad6186E92002E312078b5a1dAfd5ddf63d3f731] = true;
        isContractListed[0xED5AF388653567Af2F388E6224dC7C4b3241C544] = true;
        isContractListed[0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D] = true;
        isContractListed[0x1CB1A5e65610AEFF2551A50f76a87a7d3fB649C6] = true;
        isContractListed[0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB] = true;
        isContractListed[0x892848074ddeA461A15f337250Da3ce55580CA85] = true;
        isContractListed[0x521f9C7505005CFA19A8E5786a9c3c9c9F5e6f42] = true;
        isContractListed[0xbCe3781ae7Ca1a5e050Bd9C4c77369867eBc307e] = true;
        isContractListed[0x0290d49f53A8d186973B82faaFdaFe696B29AcBb] = true;
        isContractListed[0x79FCDEF22feeD20eDDacbB2587640e45491b757f] = true;
        isContractListed[0x23581767a106ae21c074b2276D25e5C3e136a68b] = true;
        isContractListed[0xe785E82358879F061BC3dcAC6f0444462D4b5330] = true;

        deployerList[
            0xbad6186E92002E312078b5a1dAfd5ddf63d3f731
        ] = 0x46006a7bB69887190518b056895D26Cd54a888a3;
        deployerList[
            0xED5AF388653567Af2F388E6224dC7C4b3241C544
        ] = 0xd45058Bf25BBD8F586124C479D384c8C708CE23A;
        deployerList[
            0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D
        ] = 0xaBA7161A7fb69c88e16ED9f455CE62B791EE4D03;
        deployerList[
            0x1CB1A5e65610AEFF2551A50f76a87a7d3fB649C6
        ] = 0x1b2Ef9D5Db72eA1103FC24eEDd2226477409383a;
        deployerList[
            0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB
        ] = 0xC352B534e8b987e036A93539Fd6897F53488e56a;
        deployerList[
            0x892848074ddeA461A15f337250Da3ce55580CA85
        ] = 0x070CBeF6414F8F0070A98051658BeF840BCd86De;
        deployerList[
            0x521f9C7505005CFA19A8E5786a9c3c9c9F5e6f42
        ] = 0xD584fE736E5aad97C437c579e884d15B17A54a51;
        deployerList[
            0xbCe3781ae7Ca1a5e050Bd9C4c77369867eBc307e
        ] = 0x62ac2DbBD306610fF8652B9e0D1A310B6C6AFa0f;
        deployerList[
            0x0290d49f53A8d186973B82faaFdaFe696B29AcBb
        ] = 0xa342C083b78dceF9CA20B02be8497e5b1e034E5e;
        deployerList[
            0x79FCDEF22feeD20eDDacbB2587640e45491b757f
        ] = 0x0Bdfd4AD937Ff179985276b7F5BE7Ae3de0229e6;
        deployerList[
            0x23581767a106ae21c074b2276D25e5C3e136a68b
        ] = 0x6c8984bAf566Db08675310b122BF0be9Ea269ecA;
        deployerList[
            0xe785E82358879F061BC3dcAC6f0444462D4b5330
        ] = 0xc9b6321dc216D91E626E9BAA61b06B0E4d55bdb1;
    }

    /**
     * @notice Registers Music Signature and pays royalties to collection creator.
     */
    function claimMusSig(address adr, uint256 tokenId)
        external
        payable
        nonReentrant
    {
        if (paused) {
            revert SaleNotOpen();
        }
        if (adr == address(0)) {
            revert ZeroAddress();
        }
        if (musSigsClaimed >= MAX_MUS_SIGS - NUM_MUS_SIGS_RESERVED) {
            revert SoldOut();
        }
        if (!isContractListed[adr]) {
            revert ContractNotIncluded();
        }
        if (msg.value != signatureFee) {
            revert IncorrectAmount();
        }
        if (isSigClaimed(adr, tokenId) == true) {
            revert MusicSignatureClaimed();
        }
        address tokenOwner = _getOwner(adr, tokenId);
        if (
            tokenOwner != _msgSender() &&
            !delegationRegistry.checkDelegateForToken(
                _msgSender(),
                tokenOwner,
                adr,
                tokenId
            )
        ) {
            revert NotTokenOwner();
        }
        uint256 token = _addressToUint256(adr) + tokenId;
        musSig[token] = _getSignature(token, SIG_LENGTH, UNIT_LENGTH, MOD);
        claimed[adr][tokenId] = true;
        ++musSigsClaimed;

        Token memory currentToken;
        currentToken.tokenContract = adr;
        currentToken.tokenId = tokenId;
        getSignedTokenByIndex[musSigsClaimed] = currentToken;
        signedTokens[adr].push(tokenId);

        uint256 origTokenCreatorRoyalty = (signatureFee / 100) *
            supportedCollectionRoyaltyPercentage;
        uint256 signatureCreatorFee = msg.value - origTokenCreatorRoyalty;

        if (signatureCreatorFee > 0) {
            Address.sendValue(payable(owner()), signatureCreatorFee);
        }
        if (origTokenCreatorRoyalty > 0) {
            Address.sendValue(
                payable(deployerList[adr]),
                origTokenCreatorRoyalty
            );
        }
        emit SignatureClaimed(adr, tokenId);
    }

    /**
     * @notice Mints or updates a Performance and pays fee to hired Performer.
     */
    function record(
        uint256 recordingId,
        address adr,
        uint256 tokenId,
        address adr2,
        uint256 tokenId2
    ) external payable nonReentrant returns (uint256) {
        if (adr2 == address(0)) {
            revert ZeroAddress();
        }
        if (recordingId == 0) {
            if (adr == address(0)) {
                revert ZeroAddress();
            }
            if (isSigClaimed(adr, tokenId) == false) {
                revert NoMusicSignature();
            }
            if (hasMinted(adr, tokenId) == true) {
                revert AlreadyMintedRecording();
            }
            address tokenOwner = _getOwner(adr, tokenId);
            if (
                tokenOwner != _msgSender() &&
                !delegationRegistry.checkDelegateForToken(
                    _msgSender(),
                    tokenOwner,
                    adr,
                    tokenId
                )
            ) {
                revert NotTokenOwner();
            }
        } else {
            if (!_exists(recordingId)) {
                revert NonexistentToken();
            }
            if (ERC721.ownerOf(recordingId) != _msgSender()) {
                revert NotRecordingOwner();
            }
        }
        if (msg.value != performanceFee) {
            revert IncorrectAmount();
        }
        if (isSigClaimed(adr2, tokenId2) == false) {
            revert NoMusicSignature();
        }
        uint256 mintIndex = totalSupply() + 1;
        uint256 token1;
        uint256 token2 = _addressToUint256(adr2) + tokenId2;
        address hiredTokenOwner = _getOwner(adr2, tokenId2);
        if (recordingId > 0) {
            for (uint256 i = 0; i < 6; i++) {
                recording[recordingId].push(musSig[token2][i]);
            }
            Record memory existingRecord;
            existingRecord.tokenContract1 = adr;
            existingRecord.tokenId1 = tokenId;
            existingRecord.tokenContract2 = adr2;
            existingRecord.tokenId2 = tokenId2;
            getTokenRecord[recordingId] = existingRecord;

            Token memory hiredPerformer;
            hiredPerformer.tokenContract = adr2;
            hiredPerformer.tokenId = tokenId2;
            performanceRecord[recordingId].push(hiredPerformer);
            performedIn[token2].push(recordingId);

            emit PerformanceUpdated(recordingId);
        } else {
            token1 = _addressToUint256(adr) + tokenId;
            if (token1 == token2) {
                revert IdenticalPerformers();
            }
            for (uint256 i = 0; i < 6; i++) {
                recording[mintIndex].push(musSig[token1][i]);
                recording[mintIndex].push(musSig[token2][i]);
            }
            _safeMint(_msgSender(), mintIndex);

            minted[adr][tokenId] = true;

            Record memory currentRecord;
            currentRecord.tokenContract1 = adr;
            currentRecord.tokenId1 = tokenId;
            currentRecord.tokenContract2 = adr2;
            currentRecord.tokenId2 = tokenId2;
            getTokenRecord[mintIndex] = currentRecord;

            Token memory recordingCreator;
            recordingCreator.tokenContract = adr;
            recordingCreator.tokenId = tokenId;
            performanceRecord[mintIndex].push(recordingCreator);

            Token memory hiredPerformer;
            hiredPerformer.tokenContract = adr2;
            hiredPerformer.tokenId = tokenId2;
            performanceRecord[mintIndex].push(hiredPerformer);
            performedIn[token2].push(mintIndex);
        }
        Address.sendValue(payable(hiredTokenOwner), msg.value);
        return mintIndex;
    }

    function ownerClaimMusSig(address adr, uint256 tokenId)
        external
        payable
        nonReentrant
        onlyOwner
    {
        if (adr == address(0)) {
            revert ZeroAddress();
        }
        if (ownerMusSigsClaimed >= NUM_MUS_SIGS_RESERVED) {
            revert ReservedSupplySoldOut();
        }
        if (!isContractListed[adr]) {
            revert ContractNotIncluded();
        }
        if (
            msg.value !=
            (signatureFee / 100) * supportedCollectionRoyaltyPercentage
        ) {
            revert IncorrectAmount();
        }
        if (isSigClaimed(adr, tokenId) == true) {
            revert MusicSignatureClaimed();
        }
        uint256 token = _addressToUint256(adr) + tokenId;
        musSig[token] = _getSignature(token, SIG_LENGTH, UNIT_LENGTH, MOD);
        claimed[adr][tokenId] = true;
        ++musSigsClaimed;
        ++ownerMusSigsClaimed;

        Token memory currentToken;
        currentToken.tokenContract = adr;
        currentToken.tokenId = tokenId;
        getSignedTokenByIndex[musSigsClaimed] = currentToken;
        signedTokens[adr].push(tokenId);

        Address.sendValue(payable(deployerList[adr]), msg.value);

        emit SignatureClaimed(adr, tokenId);
    }

    function setDefaultRoyalty(address receiver, uint96 numerator)
        external
        onlyOwner
    {
        ERC2981._setDefaultRoyalty(receiver, numerator);
    }

    function updateContractList(
        address contractAddress,
        address deployerAddress,
        bool include
    ) external onlyOwner {
        isContractListed[contractAddress] = include;
        deployerList[contractAddress] = deployerAddress;
    }

    function setInscriptions(
        uint256[] calldata tokenId,
        string[] calldata inscriptionId
    ) external onlyOwner {
        for (uint256 i = 0; i < tokenId.length; i++) {
            getInscriptionId[tokenId[i]] = inscriptionId[i];
            getOrdinalTokenId[inscriptionId[i]] = tokenId[i];
        }
    }

    function setPerformanceFee(uint256 newPerfFee) external onlyOwner {
        performanceFee = newPerfFee;
    }

    function setSignatureFee(uint256 newSigFee) external onlyOwner {
        signatureFee = newSigFee;
    }

    function setAnimationURI(string calldata uri) external onlyOwner {
        animationURI = uri;
    }

    function setImageURI(string calldata uri) external onlyOwner {
        imageURI = uri;
    }

    function setJsonURI(string calldata uri) external onlyOwner {
        jsonURI = uri;
    }

    function setInscriptionURI(string calldata uri) external onlyOwner {
        inscriptionURI = uri;
    }

    function setSupportedCollectionRoyaltyPercentage(uint256 percent)
        external
        onlyOwner
    {
        supportedCollectionRoyaltyPercentage = percent;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function setSalePaused(bool isPaused) external onlyOwner {
        paused = isPaused;
        emit SalePaused(paused);
    }

    function setDelegationRegistry(address delegationRegistryAddress)
        external
        onlyOwner
    {
        delegationRegistry = IDelegationRegistry(delegationRegistryAddress);
    }

    /**
     * @notice Returns registered Music Signature for a given token.
     */
    function getMusSig(address adr, uint256 tokenId)
        external
        view
        returns (uint256[] memory)
    {
        uint256 token = _addressToUint256(adr) + tokenId;
        return musSig[token];
    }

    /**
     * @notice Returns Performance level.
     */
    function getLevel(uint256 tokenId) external view returns (string memory) {
        uint256[] memory rec = getRecording(tokenId);
        uint256 level = rec.length / 6 - 1;
        if (level > 5) {
            level = 5;
        }
        return Strings.toString(level);
    }

    /**
     * @notice Returns all signed tokens for a given collection.
     */
    function getSignedTokens(address adr)
        external
        view
        returns (uint256[] memory)
    {
        return signedTokens[adr];
    }

    /**
     * @notice Returns Performance history.
     */
    function getPerformanceRecord(uint256 tokenId)
        external
        view
        returns (Token[] memory)
    {
        return performanceRecord[tokenId];
    }

    /**
     * @notice Returns Performance record for a given Performer.
     */
    function getPerformedIn(address adr, uint256 tokenId)
        external
        view
        returns (uint256[] memory)
    {
        uint256 token = _addressToUint256(adr) + tokenId;
        return performedIn[token];
    }

    /**
     * @notice Returns traits of Performer and Ordinal Inscription.
     */
    function getProperties(address adr, uint256 tokenId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            string memory,
            string memory,
            uint256[] memory
        )
    {
        uint256 token = _addressToUint256(adr) + tokenId;
        return (
            _getWidth(token),
            _getDuration(token),
            _getStart(token),
            _getEnd(token),
            _getPath(token),
            _getColors(token),
            _getSignature(token, SIG_LENGTH, UNIT_LENGTH, MOD)
        );
    }

    /**
     * @notice Returns sale state.
     */
    function getSalePaused() external view returns (bool) {
        return paused;
    }

    /**
     * @notice Returns Performance URI.
     */
    function getAnimationURI(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            revert NonexistentToken();
        }
        string memory uri = string(
            abi.encodePacked(animationURI, Strings.toString(tokenId))
        );
        return uri;
    }

    /**
     * @notice Returns album cover URI.
     */
    function getImageURI(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            revert NonexistentToken();
        }
        string memory uri = string(
            abi.encodePacked(imageURI, Strings.toString(tokenId))
        );
        return uri;
    }

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC721Metadata
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            revert NonexistentToken();
        }
        return string(abi.encodePacked(jsonURI, Strings.toString(tokenId)));
    }

    /**
     * @notice Returns Bitcoin Inscription metadata URI.
     */
    function getInscriptionURI(string calldata inscriptionId)
        public
        view
        returns (string memory)
    {
        return string(abi.encodePacked(inscriptionURI, inscriptionId));
    }

    /**
     * @notice Returns Music Signature for a given Performance.
     */
    function getRecording(uint256 tokenId)
        public
        view
        returns (uint256[] memory)
    {
        return recording[tokenId];
    }

    /**
     * @notice Checks if Signature was claimed for a given token.
     */
    function isSigClaimed(address adr, uint256 tokenId)
        public
        view
        returns (bool)
    {
        return claimed[adr][tokenId] == true;
    }

    /**
     * @notice Checks if Performer minted a Performance.
     */
    function hasMinted(address adr, uint256 tokenId)
        public
        view
        returns (bool)
    {
        return minted[adr][tokenId] == true;
    }

    /**
     * @notice Helper function to compute layout path.
     */
    function _getPath(uint256 tokenId) internal view returns (string memory) {
        string memory animPath = layoutPath[_hash(tokenId) % layoutPath.length];
        return animPath;
    }

    /**
     * @notice Helper function to compute stroke color.
     */
    function _getColors(uint256 tokenId) internal view returns (string memory) {
        string[3] memory colors;
        colors[0] = strokeColor[_hash(tokenId) % strokeColor.length];
        colors[1] = ",";
        colors[2] = "white";

        string memory colorStr = string(
            abi.encodePacked(colors[0], colors[1], colors[2])
        );
        return colorStr;
    }

    /**
     * @notice Checks if token owner.
     */
    function _getOwner(address adr, uint256 tokenId)
        internal
        view
        returns (address)
    {
        address tokenOwner;
        if (adr == CRYPTO_PUNKS_ADDRESS) {
            ICryptoPunks icp = ICryptoPunks(adr);
            tokenOwner = icp.punkIndexToAddress(tokenId);
        } else {
            IContract ic = IContract(adr);
            tokenOwner = ic.ownerOf(tokenId);
        }
        return tokenOwner;
    }

    /**
     * @notice Creates Signature for a given type. Returns Signature unit array.
     */
    function _getSignature(
        uint256 tokenId,
        uint256 sigLength,
        uint256 unitLength,
        uint256 modulo
    ) internal pure returns (uint256[] memory) {
        uint256 sig = _hash(tokenId);
        return _parse(sig, sigLength, unitLength, modulo);
    }

    /**
     * @notice Helper function to compute Signature hash.
     */
    function _hash(uint256 tokenId) internal pure returns (uint256) {
        uint256 hashValue = uint256(keccak256(abi.encodePacked(tokenId)));
        return hashValue;
    }

    /**
     * @notice Helper function. Returns a unit array for a given Signature.
     */
    function _parse(
        uint256 number,
        uint256 numberLength,
        uint256 unitLength,
        uint256 modulo
    ) internal pure returns (uint256[] memory) {
        uint256[] memory units = new uint256[](numberLength / unitLength);
        uint256 i;
        uint256 counter = 0;
        for (i = 0; i < numberLength / unitLength; i++) {
            units[i] =
                ((((number % (10**(numberLength - counter))) /
                    (10**(numberLength - (counter + unitLength)))) %
                    10**unitLength) % modulo) +
                1;
            counter = counter + unitLength;
        }
        return units;
    }

    /**
     * @notice Helper function to convert address to uint.
     */
    function _addressToUint256(address adr) internal pure returns (uint256) {
        return uint256(uint160(adr));
    }

    /**
     * @notice Helper function to compute stroke width.
     */
    function _getWidth(uint256 tokenId) internal pure returns (uint256) {
        uint256 strokeWidth = (_hash(tokenId) % 28) * 20 + 200;
        return strokeWidth;
    }

    /**
     * @notice Helper function to compute animation duration.
     */
    function _getDuration(uint256 tokenId) internal pure returns (uint256) {
        uint256 animDuration = _hash(tokenId) % 10**2;
        if (animDuration == 0) {
            animDuration = 1;
        }
        return animDuration;
    }

    /**
     * @notice Helper function to compute animation starting point.
     */
    function _getStart(uint256 tokenId) internal pure returns (uint256) {
        return (_hash(tokenId) % 759) + 1;
    }

    /**
     * @notice Helper function to compute animation end point.
     */
    function _getEnd(uint256 tokenId) internal pure returns (uint256) {
        return (_hash(tokenId + 1) % 759) + 1;
    }
}