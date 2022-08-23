// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "./interfaces/ITheAmazingTozziDuckMachine.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@rari-capital/solmate/src/utils/SSTORE2.sol";
import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {Base64} from "./lib/base64.sol";

/// @title Tozzi Ducks
/// @author (ediv, exp.table) === CHAIN/SAW

/*
 *                     ;@######@b,,,,,,      ,,,,
 *                  .;##b      [email protected]      #N,,{@#### N,
 *                ,###b                [email protected]          #Q;;;;;;;;,
 *              ;###b                              88#########Qssp
 *             [email protected]#b            [email protected]###############N            88##@@p
 *             [email protected]#b        ;@################### #N              [email protected]@Q
 *             "@@###N  @@ ###################### #N              [email protected]@Q
 *               '[email protected]#    ##b''''''''''''''''''[email protected]### #N              @@ b
 *                  ^^3 ###@#        @#######   "@#####S            @@ b
 *                  [email protected]#^                    '@#   '@###Q,,,,      .,@##b
 *                  [email protected]    ,####,    ,######,        '@### #[email protected]@#b
 *                  '@#p;##   '@#  @@b    '@#        @ # b'@#### ### b
 *                    '@#~    '@   @ ~   ,[email protected]           7bN,     '@###Q,
 *                   ;@@ ~   ,[email protected]   @ ~ ,[email protected]##             @ b     [email protected]####Qp
 *                 ;## # ~  '@##   @ ~'@####   ;sssssso  @ b       %@@# b
 *                [email protected]#b'[email protected]@Q '@#####  ~'@########[email protected]@#  b         ""
 *               @########### ####@@ ~ '8 ####T^[email protected]###N^[email protected]@ b
 *             @##""""""""""""""@@### ######"^  '"""@@#N'"@@#p
 *          [email protected]##^ ;########Q,,,,,j""""""""^       ;###@@#[email protected]  b
 *          '@ [email protected]##b^[email protected]#      #Q,,,,,,,,,,,,@@#b^  jQ,@@#b
 *            "@#[email protected]### # [email protected] ##[email protected]#           ### b ,@####b
 *              '@###b  '@  #[email protected]###QSG9^     [email protected] #b.s###b
 *                           '@#Q## #N      [email protected]@## Q##b`
 *                            '@#[email protected]  Q  [email protected]@###@##b
 *                              %[email protected]##@@######@@##b
 *                               "@@##[email protected]@## b
 *                                  ""^[email protected]#  '%@ b
 *                                    @#b     @###p
 *                                ,@###       [email protected]# #p
 *                              [email protected]##[email protected]##    @##[email protected]##p
 *                              ;@ #[email protected]#######[email protected]##Q,,,,
 *                            .{@ #[email protected]# #[email protected] ##GG9Q######WN,,,
 *                         ,s#[email protected]@@##[email protected]@@@ #      [email protected]# Q,
 *
 *   ________________________________   _____________  _______________ _________
 *   ___  __/_  __ \__  /__  /___  _/   ___  __ \_  / / /_  ____/__  //_/_  ___/
 *   __  /  _  / / /_  /__  / __  /     __  / / /  / / /_  /    __  ,<  _____ \ 
 *   _  /   / /_/ /_  /__  /___/ /      _  /_/ // /_/ / / /___  _  /| | ____/ / 
 *   /_/    \____/ /____/____/___/      /_____/ \____/  \____/  /_/ |_| /____/  
 *
 *                                                  JIM TOZZI x CHAIN/SAW         
 */

contract TheAmazingTozziDuckMachine is ERC721Burnable, ERC721Enumerable, Ownable, ITheAmazingTozziDuckMachine {
    using Strings for uint256;    
    
    uint256 private constant TOZZI_DUCKS = 200;    
    uint256 public constant OWNERSHIP_TOKEN_ID = 420;
    uint256 public constant probationPeriod = 1 weeks;    
    bytes32 private constant MERKLE_ROOT = 0x76cf55ec8f156f88221bd1f5b7840a0e6427cafd0518667edd4ca7e530b535f3;    
    uint256 private _nextCustomDuckTokenId;
    uint256 private _numCustomDucks;
    string private _ownershipTokenURI;     
    
    MachineConfig public machineConfig;
    mapping(uint256 => address) public duckCreators;
    mapping(uint256 => bytes32) public artists;
    mapping(uint256 => bytes32) public duckTitles;
    mapping(uint256 => bool) public probationEnded;
    mapping(address => DuckAllowance) public duckAllowances;
    mapping(uint256 => DuckProfile) public duckProfiles;
    mapping(uint256 => address) public duckImageData;
    mapping(bytes32 => bool) public duckExists;
    mapping(uint256 => uint256) public customDuckHatchedTimes;
    
    modifier onlyMachineOwner() {        
        if (!_isApprovedOrOwner(_msgSender(), OWNERSHIP_TOKEN_ID)) revert Unauthorized();
        _;
    }

    modifier onlyExtantDuck(uint256 tokenId) {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        _;
    }

    constructor(
        MachineConfig memory _machineConfig, 
        string memory ownershipTokenURI
    ) ERC721("Tozzi Ducks", "TZDUCKS") {
        machineConfig = _machineConfig;
        _ownershipTokenURI = ownershipTokenURI;
        _safeMint(_msgSender(), OWNERSHIP_TOKEN_ID);
    }

    /**
     * @notice Configure the machine to manage the growth of the duck population responsibly.
     */
    function setMachineConfig(MachineConfig calldata _machineConfig) external override onlyMachineOwner {
        machineConfig = _machineConfig;
        require(_machineConfig.maxCustomDucks >= _numCustomDucks);
        emit MachineConfigUpdated(
            _machineOwner(),
            _machineConfig.tozziDuckPrice,
            _machineConfig.customDuckPrice,
            _machineConfig.maxCustomDucks,
            _machineConfig.tozziDuckMintStatus,
            _machineConfig.customDuckMintStatus
        );
    }

    /**
     * @notice Adjust the media associated with the token representing ownership of the machine.
     */
    function setOwnershipTokenURI(
        string calldata ownershipTokenUri
    ) external override onlyMachineOwner {
        _ownershipTokenURI = ownershipTokenUri;
    }

    /**
     * @notice Share the latest news with the flock.
     * @dev Emits an event to be picked up and displayed by front-ends.
     */
    function setMOTD(string calldata motd) external override onlyMachineOwner {
        emit MOTDSet(_msgSender(), motd);
    }

    /**
     * @notice Manage the duck allowance for an individual account. A duck allowance specifies how many of each type of duck
     * (Tozzi and Custom) a given user is able to mint. A user's duck allowances will deplete with each mint. Note: Duck allowances 
     * are only taken into account when mint status for a particular duck type is set to MintStatus.Allow.
     */
    function setDuckAllowance(
        address who, 
        DuckAllowance calldata allowance
    ) external override onlyMachineOwner {        
        duckAllowances[who] = allowance;        
    }

    /**
     * @notice Set duck allowances for multiple accounts at once. Useful for whitelisting groups of accounts. Obviously,
     * this can get expensive so please use responsibly.
     */
    function setDuckAllowances(
        address[] calldata who,
        DuckAllowance calldata allowance
    ) external override onlyMachineOwner {
        for (uint i = 0; i < who.length; i++) {
            duckAllowances[who[i]] = allowance;
        }
    }

    /**
     * @notice Immediately end probationary period for a custom duck. For use-cases where the duck looks so fine
     * you just can't wait a week to make them official.
     */
    function endProbation(uint256 tokenId) 
        external 
        override 
        onlyExtantDuck(tokenId) 
        onlyMachineOwner 
    {
        if (!_isCustomDuck(tokenId)) revert InvalidDuckId();
        if (!_isOnProbation(tokenId)) revert ProbationEnded();
        probationEnded[tokenId] = true;
    }

    /**
     * @notice Burn a freshly minted custom duck because you hate it's face. Custom ducks that are less than
     * 1 WEEK old are subject to the destructive whims of the machine's owner.
     */
    function burnRenegadeDuck(
        uint256 tokenId, 
        string calldata reason
    ) external override onlyExtantDuck(tokenId) onlyMachineOwner {
        if (!_isCustomDuck(tokenId)) revert InvalidDuckId();
        if (!_isOnProbation(tokenId)) revert ProbationEnded();
        address owner = ownerOf(tokenId);
        string memory webp = string(SSTORE2.read(duckImageData[tokenId]));
        _burn(tokenId);
        _numCustomDucks -= 1;
        emit CustomDuckBurned(tokenId, owner, _machineOwner(), webp, reason);
    }
    
    /**
     * @notice Grant a special title to a deserving duck.
     */
    function setDuckTitle(
        uint256 tokenId, 
        bytes32 title
    ) external override onlyExtantDuck(tokenId) onlyMachineOwner {
        duckTitles[tokenId] = title;
        emit DuckTitleGranted(tokenId, title, _machineOwner());
    }

     /**
     * @notice Mint a custom duck directly to specified recipient bypassing minting fees. The resulting duck will have 
     * it's 'Creator' attribute set to the supplied artist parameter.
     */
    function ownerMint(
        address to, 
        string calldata webp
    ) external override onlyMachineOwner {                
        if (_numCustomDucks >= machineConfig.maxCustomDucks) 
            revert CustomDuckLimitReached();        
        if (_nextCustomDuckTokenId + TOZZI_DUCKS == OWNERSHIP_TOKEN_ID) 
            _nextCustomDuckTokenId += 1;
        bytes32 webpHash = keccak256(abi.encodePacked(webp));
        if (duckExists[webpHash]) revert DuckAlreadyExists();
        duckExists[webpHash] = true;
        uint256 tokenId = TOZZI_DUCKS + (_nextCustomDuckTokenId++);
        address pointer = SSTORE2.write(bytes(webp));
        duckImageData[tokenId] = pointer;
        _safeMint(to, tokenId);
        customDuckHatchedTimes[tokenId] = block.timestamp;
        _numCustomDucks += 1;
        emit DuckMinted(
            tokenId,
            webpHash,
            _msgSender(),
            to,
            DuckType.Custom,
            machineConfig.customDuckPrice
        );
    }

    /**
     * @notice Shout out the artist who created a custom duck.
     */
    function setArtistName(
        uint256 tokenId, 
        bytes32 name
    ) external override onlyExtantDuck(tokenId) onlyMachineOwner {
        if (!_isCustomDuck(tokenId)) revert InvalidDuckId();
        artists[tokenId] = name;
    }

    /**
     * @notice After all ... Why shouldn't you take profits?
     */
    function withdraw(address recipient, uint256 amount) external override onlyMachineOwner {
        if (amount > address(this).balance) revert InsufficientFunds();
        if (amount == 0) revert AmountMustBeNonZero();
        SafeTransferLib.safeTransferETH(recipient, amount);
    }

    /**
     * @notice Update your duck's profile by providing a custom name, status, and description.
     * @dev Customized duck profiles are used within tokenURI() when constructing a duck's metadata.
     */
    function setDuckProfile(
        uint256 tokenId,
        bytes32 name,
        bytes32 status,
        string calldata description
    ) onlyExtantDuck(tokenId) external override {        
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) revert Unauthorized();
        duckProfiles[tokenId] = DuckProfile(name, status, description);
        emit DuckProfileUpdated(tokenId, name, status, description);
    }
       
    /**
     * @notice Mint one of 200 official Tozzi Ducks created by Jim Tozzi. Image storage costs paid by minter.
     * @dev User supplies webp data to be stored on chain. The provided proof is used verify that provided
     * duck image data is legit. 
     */
    function mintTozziDuck(
        address to,
        uint256 duckId,
        string calldata webp,
        bytes32[] calldata merkleProof
    ) external override payable {
        if (machineConfig.tozziDuckMintStatus == MintStatus.Disabled)
            revert MintingDisabled();
        if (msg.value != machineConfig.tozziDuckPrice)
            revert IncorrectDuckPrice();
        if (machineConfig.tozziDuckMintStatus == MintStatus.Allow) {
            if (duckAllowances[_msgSender()].tozziDuckAllowance <= 0)
                revert InsufficientDuckAllowance();
            duckAllowances[_msgSender()].tozziDuckAllowance--;
        }
        bytes32 webpHash = keccak256(abi.encodePacked(webp));
        bytes32 node = keccak256(abi.encodePacked(duckId, webp));
        if (!MerkleProof.verify(merkleProof, MERKLE_ROOT, node))
            revert InvalidProof();
        address pointer = SSTORE2.write(bytes(webp));
        duckImageData[duckId] = pointer;
        _safeMint(to, duckId);
        emit DuckMinted(
            duckId,
            webpHash,
            _msgSender(),
            to,
            DuckType.Tozzi,
            machineConfig.tozziDuckPrice
        );
    }

    /**
     * @notice Mint your very own custom duck. Minter pays fees associated with on-chain storage of webp image data. Newly minted
     * custom ducks are born into a 1 WEEK probation period. While under probation, custom ducks can be destroyed by the machine's
     * current owner.
     */
    function mintCustomDuck(address to, string calldata webp) external override payable {
        if (machineConfig.customDuckMintStatus == MintStatus.Disabled)
            revert MintingDisabled();
        if (_numCustomDucks >= machineConfig.maxCustomDucks)
            revert CustomDuckLimitReached();
        if (msg.value != machineConfig.customDuckPrice)
            revert IncorrectDuckPrice();
        if (machineConfig.customDuckMintStatus == MintStatus.Allow) {
            if (duckAllowances[_msgSender()].customDuckAllowance <= 0)
                revert InsufficientDuckAllowance();
            duckAllowances[_msgSender()].customDuckAllowance--;
        }
        if (_nextCustomDuckTokenId + TOZZI_DUCKS == OWNERSHIP_TOKEN_ID)
            _nextCustomDuckTokenId += 1;
        bytes32 webpHash = keccak256(abi.encodePacked(webp));
        if (duckExists[webpHash]) revert DuckAlreadyExists();
        duckExists[webpHash] = true;
        uint256 tokenId = TOZZI_DUCKS + (_nextCustomDuckTokenId++);
        address pointer = SSTORE2.write(bytes(webp));
        duckImageData[tokenId] = pointer;
        _safeMint(to, tokenId);
        duckCreators[tokenId] = _msgSender();
        customDuckHatchedTimes[tokenId] = block.timestamp;
        _numCustomDucks += 1;
        emit DuckMinted(
            tokenId,
            webpHash,
            _msgSender(),
            to,
            DuckType.Custom,
            machineConfig.customDuckPrice
        );
    }

    function tokenURI(uint256 tokenId) public view override onlyExtantDuck(tokenId) returns (string memory) {
        if (tokenId == OWNERSHIP_TOKEN_ID) return _ownershipTokenURI;        
        
        DuckProfile memory profile = duckProfiles[tokenId];
        string memory name = _defaultDuckName(tokenId);
        string memory description = name;
        if (!_isEmptyBytes32(profile.name)) name = _bytes32ToString(profile.name);        
        if (bytes(profile.description).length > 0) description = profile.description;
        string memory image = string(abi.encodePacked("data:image/webp;base64,", string(SSTORE2.read(duckImageData[tokenId]))));        

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(abi.encodePacked(
                '{', 
                    '"name":"', name, '",', 
                    '"description":"', description, '",', 
                    '"image": "', image, '",',
                    '"attributes":', _generateMetadataAttributes(tokenId, profile),
                '}'
            ))
        ));
    }

    function _getDuckCreator(uint256 tokenId) internal view returns (string memory) {
        if (tokenId < TOZZI_DUCKS) return "Jim Tozzi";
        bytes32 artist = artists[tokenId];
        if (!_isEmptyBytes32(artist)) {
            return string(abi.encodePacked(_bytes32ToString(artist)));
        }        
        return string(abi.encodePacked(_addressToString(duckCreators[tokenId])));
    }

    function _generateMetadataAttributes(
        uint256 tokenId, 
        DuckProfile memory profile
    ) internal view returns (string memory attributes) {
        string memory duckType = _isTozziDuck(tokenId) ? "Tozzi" : "Custom";
        string memory creator = _getDuckCreator(tokenId);
        
        bytes memory _attributes = abi.encodePacked(
            '{',
                '"trait_type": "Duck Type",', 
                '"value":', '"', duckType, '"',
            '},'
            '{', 
                '"trait_type": "Creator",',
                '"value":', '"', creator, '"',
            '}'
        );

        if (_isOnProbation(tokenId)) {
            _attributes = abi.encodePacked(
                _attributes, 
                ',', 
                '{', 
                    '"trait_type": "Status",',
                    '"value": "Probation"',
                '}'
            );
        } else if (!_isEmptyBytes32(profile.status)) {
            _attributes = abi.encodePacked(
                _attributes, 
                ',', 
                '{', 
                    '"trait_type": "Status",',
                    '"value":', '"', _bytes32ToString(profile.status), '"',
                '}'
            );
        }

        bytes32 title = duckTitles[tokenId];
        if (!_isEmptyBytes32(title)) {
            _attributes = abi.encodePacked(
                _attributes, 
                ',', 
                '{', 
                    '"trait_type": "Title",',
                    '"value":', '"', _bytes32ToString(title), '"',
                '}'
            );
        }
        return string(abi.encodePacked('[', _attributes, ']'));
    }

    function _addressToString(address _address) internal pure returns (string memory) {
        return Strings.toHexString(uint256(uint160(_address)), 20);
    }

    function _machineOwner() internal view returns (address machineOwner) {
        return ownerOf(OWNERSHIP_TOKEN_ID);
    }

    function _isTozziDuck(uint256 tokenId) internal pure returns (bool) {
        return tokenId < TOZZI_DUCKS;
    }

    function _isCustomDuck(uint256 tokenId) internal pure returns (bool) {
        return tokenId >= TOZZI_DUCKS && tokenId != OWNERSHIP_TOKEN_ID;
    }

    function _defaultDuckName(uint256 tokenId) internal pure returns (string memory) {
        return string(abi.encodePacked("Tozzi Duck ", tokenId.toString()));       
    }

    function _isEmptyBytes32(bytes32 _bytes32) internal pure returns (bool) {
        bytes32 empty;
        return _bytes32 == empty;
    }

    function _isOnProbation(uint256 tokenId) internal view returns (bool) {
        if (!_isCustomDuck(tokenId)) return false;
        if (probationEnded[tokenId]) return false;
        return block.timestamp <= customDuckHatchedTimes[tokenId] + probationPeriod;
    }

    function _bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return interfaceId == type(ITheAmazingTozziDuckMachine).interfaceId || super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}