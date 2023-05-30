// SPDX-License-Identifier: MIT

// .####&.&(%%(%..##%%.(.####%.&(&&##..%#%&.(.#####.##&&%(..%#%%.(.%####.*%&%&(..&#
// %#(%%#.......((.*%&%.(#(#%#.......((.,%%&.*%(#%#,......((..%%%..%(#%#*......((..
// ..*..../.%(#(..%##*%#..,..../.&(((,./#(*&#.......(.%(((*.,#/(%#.......(.((((#..#
// .,####..(#/**%...%##...####..,#(**%...%#%...####,..(#**%...&%%...####*..(#**%...
// .%***%%.....,..#/(&.*.%*,*%#....../%%&&&&&&&&%%&#........%/(%...*#**&#........&%
// .......#%&*#..%(*,(.........%%&&&&&&&&&&&&&&&&&&&&&&&#..*(*,(,........%#&*#...(*
// (%,&%..#%*#&.,.......(%/&%&&&&&&&&&&&&&&&&&&&&&&&&&&&&.,.......##&%(..##*%#.....
// %(((..........%###(..%(&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&.(###%..((((#.........*##
// ..,#%..((**&%.&#**%%..(&&&&&&&%&&&%%%%%%%(,....,/%%%%%%%(##*%%...*,%...((*#(.*#%
// .#&&*%#.((((..........%&&&&&%%%&(......................%%.......#%&#/%..(((.....
// ..%%(...........#&%%%.%&%%%*,*%,#.......................,*#%%*#..#%%...........%
// ....%...%&%,%%.,#%*#(.%/,,,,,%%%..........................#&*#%....(/..,%%&&(..#
// .&%.((%...%#(...*..*#%,,,,,*%&%%%%%%%%%(/,.          .    ..*.##,#(#(%/..%#%...,
// ..%##%.%##%,..%(*.(.......%#.%%%%      #*******#  *. /******,*...(##%..###%...(*
// &#((..##.*&#...#%(%.#...#...........*%,*(#%%%%%%(...*&%&%%&%%..*(((/..#%%/#...%(
// %**%(...#%,.....#%...%..................%(******/#.........&...#**(#....&(.....*
// ........#((%#.#/#(##.....,.............%**%.....***%......*%%#.........#((#&.%&,
// .#%%%%.##&&(%..%##&.(.##%%%............**,,......**.....,/##&.,.##&%#..(%/((..,#
// .####%.......((.%##&..#####.%........#***,/*#/.****/.%.((.%##&*.#####.......((.#
// ..#......((((*.&#.*##..#......((%,...,.**********%.%(((%.##,*%#..#......%(((%.,#
// .%##%#,..((%%&...%%...*##%#/..((%%%...#.#**/%%%%%..((%&%...*&....##%#&..((%%%...
// .&/#%#%.....(..(,((...&/#%#%.....(,.((%...%,%#%#%.....*,.(*%(,..#/(%##.....,/.(/
// ...../.#%%/#..((*&(......./.%&%*#%,,,%....,%/,*/.&%#*#...(*&(/....../.#%(*#...(*
// (&/%#..%#*#(.#.....(.(&%&#.(,,,,,,#,,,#...../(,/,,,,%&.(*....(.(&&&%,.%#*#%./(..
// ,#(%..#...,...&%&#%,..#(%%,,,,,(,,,*%,*,%..,,*,,,,,,,,#.%&&%##..%(#..*...,...#%%
// .%%##..%#*%%%.##%*#,..#%&,,,%,,/,,,,,,,,%%.%%,,,,#,./,%(,##*&%..,%%#%..%*(%(..##
// ,&***//..#%...*.......%#.,*,,,%,%,,,*,,,,#%/#,,/.*(.%(,,*.......#/***&..%#...,..
// ..........%.....#*#%#./,,,,,,,,*,,,/,,#,,,#,,(,,,,*%(,,,,,%%%/#...,...*..&,....&
// ..,,#%..&*/%%&..%%##.,,,,,/,,,*%,,,,,,,,,,,#,,,,,#,,,,,*#,,#*#/....#%..(**#%(..&
// .&%%/*%...,/....&..,#,,,,,#,,,,#,,,,,.,/,*(%,,,,*,,,%,,,#,(%..#/,#%(*/,.../....%
// ...%%..%##/%..&(*#(.%,,,,,,,*,,,,%,,,,,,,,,%,,,,,,,,,,,,,,//(*....#%,.###%%..,(*
// ((((,.##%*%#...(%#...#(/..%%,,*#,#,,#,,,#*,*,,,,,,,,,#,,,,,#%..%(((%..#%%##....&

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

pragma solidity ^0.8.9;

/**
 * @title Toysterz
 * @author NeuerEddine
 * @dev Extends ERC721 Non-Fungible Token implementation
 */

contract Toysterz is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Address for address payable;

    uint256 public store = 6000;
    uint256 public supplyWL = 0;

    uint256 public priceSession = 0.15 ether;
    uint256 public maxPerMintSession;

    bytes32 private whiteListMerkleRoot;

    /**
    @notice Mint switches
     */
    bool public mintPublicSwitch = false;
    bool public mintWLSwitch = false;
    bool public mintTeamSwitch = false;

    /**
    @notice these mappings are used to keep track of the number of minted items per mint session for each address 
     */
    mapping(address => uint256) private counterWLSession;

    /**
    @notice the baseuri will be defined according to revealed/unrevealed state of the toysterz nfts 
     */
    string public uRI_Base = "";

    /**
####################################################### Constructor #####################################################
*/
    constructor(
        string memory name,
        string memory symbol,
        bytes32 _whiteListMerkleRoot,
        string memory _uri
    ) ERC721(name, symbol) {
        uRI_Base = _uri;
        whiteListMerkleRoot = _whiteListMerkleRoot;
    }

    function getWLMerkleRoot() public view onlyOwner returns (bytes32) {
        return whiteListMerkleRoot;
    }

    function getmaxperwallet(address account) public view returns (uint256) {
        return counterWLSession[account];
    }

    function storeSet(uint256 _Store) external onlyOwner {
        store = _Store;
    }

    function priceSessionSet(uint256 _PriceSession)
        external
        onlyOwner
        isMintSessionOn
    {
        uint256 oldprice = priceSession;
        priceSession = _PriceSession;
        bytes32 mintSessionType = mintPublicSwitch
            ? bytes32("Public")
            : mintWLSwitch
            ? bytes32("WhiteList")
            : bytes32("Team");
        emit mintPriceChanged(oldprice, priceSession, mintSessionType);
    }

    function maxPerMintSessionSet(uint256 _MaxPerMintSession)
        external
        onlyOwner
        isMintSessionOn
    {
        uint256 oldmaxPerMintSession = maxPerMintSession;
        maxPerMintSession = _MaxPerMintSession;
        bytes32 mintSessionType = mintPublicSwitch
            ? bytes32("Public")
            : mintWLSwitch
            ? bytes32("WhiteList")
            : bytes32("Team");
        emit maxPerMintSessionChanged(
            oldmaxPerMintSession,
            maxPerMintSession,
            mintSessionType
        );
    }

    function uRI_BaseSet(string memory _uri) external onlyOwner {
        uRI_Base = _uri;
    }

    function setWLMerkleRoot(bytes32 _WhiteListMerkleRoot) external onlyOwner {
        whiteListMerkleRoot = _WhiteListMerkleRoot;
    }

    modifier onlyOrigin() {
        require(msg.sender == tx.origin, "Contract calls are not allowed");
        _;
    }

    modifier onlyTokenOwnerOrApproved(uint256 tokenId) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Can be called only by the token Owner or approved Address"
        );
        _;
    }

    modifier isMintSessionOn() {
        require(
            mintPublicSwitch || mintWLSwitch || mintTeamSwitch,
            "the mint Sessions are OFF"
        );
        _;
    }

    modifier isMintTeamSwitchON() {
        require(mintTeamSwitch, "Team Mint is OFF");
        _;
    }

    modifier isMintPublicSwitchON() {
        require(mintPublicSwitch, "Public Mint is OFF");
        _;
    }

    modifier isMintWLSwitchON() {
        require(mintWLSwitch, "WhiteList Mint is OFF");
        _;
    }

    modifier checkPublicNOPuchasedItems(uint256 _NoToysterz) {
        require(
            _NoToysterz <= maxPerMintSession,
            string(
                abi.encodePacked(
                    "Maximum toysterz allowed for public mint is ",
                    maxPerMintSession.toString()
                )
            )
        );
        _;
    }

    modifier checkWLNOPuchasedItems(uint256 _NoToysterz) {
        address account = msg.sender;
        uint256 counter = counterWLSession[account];
        require(
            _NoToysterz + counter <= maxPerMintSession,
            string(
                abi.encodePacked(
                    "you've already minted ",
                    counter.toString(),
                    " Maximum toysterz you are allowed to mint in whitelist Session is ",
                    (maxPerMintSession - counter).toString()
                )
            )
        );
        _;
    }

    modifier checkNoPurchasedItemsZeroStore(uint256 _NoToysterz) {
        require(_NoToysterz > 0, "One Toyster at least is required to mint");
        require(
            totalSupply() + _NoToysterz <= store,
            "Purchase would exceed total of Toysterz in store"
        );
        _;
    }

    modifier checkValueCoversCost(uint256 _NoToysterz) {
        require(
            priceSession * _NoToysterz <= msg.value,
            "Ether value sent is not correct"
        );
        _;
    }

    modifier isWhiteListed(bytes32[] memory proof) {
        require(isValideWhiteList(proof), "Whitelist validation failed");
        _;
    }

    function isValideWhiteList(bytes32[] memory proof)
        public
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                proof,
                whiteListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            );
    }

    function mintPublicSwitchON(
        uint256 _MintPublicPrice,
        uint256 _MaxPerMintPublic
    ) external onlyOwner {
        require(!mintPublicSwitch, "Public Mint is ON already");
        require(
            !mintWLSwitch,
            "WhiteList Mint is ON already stop WhiteList and then start Public"
        );
        require(
            !mintTeamSwitch,
            "Team Mint is ON already, stop Team Mint and then start Public"
        );
        mintPublicSwitch = true;
        mintSwitchON(_MintPublicPrice, _MaxPerMintPublic, "Public");
    }

    function mintPublicSwitchOFF() external onlyOwner {
        require(mintPublicSwitch, "Public Mint is OFF already");
        mintPublicSwitch = false;
        uint256 supplyPublic = totalSupply() - supplyWL;
        mintSwitchOFF("Public", supplyPublic);
    }

    function mintTeamSwitchON(uint256 _MintTeamPrice, uint256 _MaxPerMintTeam)
        external
        onlyOwner
    {
        require(!mintTeamSwitch, "Team Mint is ON already");
        require(
            !mintWLSwitch,
            "WhiteList Mint is ON already stop WhiteList and then start Team mint"
        );
        require(
            !mintPublicSwitch,
            "Public Mint is ON already stop Public Mint and start Team mint"
        );
        mintTeamSwitch = true;
        mintSwitchON(_MintTeamPrice, _MaxPerMintTeam, "Team");
    }

    function mintTeamSwitchOFF() external onlyOwner {
        require(mintTeamSwitch, "Team Mint is OFF already");
        mintTeamSwitch = false;
        mintSwitchOFF("Team", store - totalSupply());
    }

    function mintWLSwitchON(uint256 _MintWLPrice, uint256 _MaxPerMintWL)
        external
        onlyOwner
    {
        require(!mintWLSwitch, "WhiteList Mint is ON already");
        require(
            !mintPublicSwitch,
            "Public Mint is ON already stop Public and then start WhiteList"
        );
        require(
            !mintTeamSwitch,
            "Team Mint is ON already, stop Team Mint and then start WhiteList"
        );

        mintWLSwitch = true;
        mintSwitchON(_MintWLPrice, _MaxPerMintWL, "WhiteList");
    }

    function mintWLSwitchOFF() external onlyOwner {
        require(mintWLSwitch, "WhiteList Mint is OFF already");
        mintWLSwitch = false;
        supplyWL = totalSupply();
        mintSwitchOFF("WhiteList", supplyWL);
    }

    function mintSwitchON(
        uint256 _PriceSession,
        uint256 _MaxPerMint,
        bytes32 _MintSessionType
    ) private {
        priceSession = _PriceSession;
        maxPerMintSession = _MaxPerMint;
        emit mintON(
            block.timestamp,
            priceSession,
            maxPerMintSession,
            _MintSessionType
        );
    }

    function mintSwitchOFF(bytes32 _MintSessionType, uint256 _SupplySession)
        private
    {
        emit mintOFF(block.timestamp, _SupplySession, _MintSessionType);
    }

    /**
#################################################### Team Session #####################################################
*/
    /**
    @dev Team mints function for toysterz
    @param _NoToysterz number of toyserz to mint
     */
    function mintTeamToysterz(uint256 _NoToysterz)
        external
        payable
        isMintTeamSwitchON
        onlyOrigin
        onlyOwner
        checkNoPurchasedItemsZeroStore(_NoToysterz)
        checkPublicNOPuchasedItems(_NoToysterz)
        checkValueCoversCost(_NoToysterz)
        nonReentrant
    {
        uint256 totalSupplyIter = totalSupply();
        for (uint32 i = 0; i < _NoToysterz; ) {
            unchecked {
                ++i;
            }
            _safeMint(msg.sender, totalSupplyIter + i);
        }
    }

    /**
#################################################### Public Session #####################################################
*/
    /**
    @dev public mints function for toysterz
    @param _NoToysterz number of toyserz to mint
     */
    function mintPublicToysterz(uint256 _NoToysterz)
        external
        payable
        isMintPublicSwitchON
        onlyOrigin
        checkNoPurchasedItemsZeroStore(_NoToysterz)
        checkPublicNOPuchasedItems(_NoToysterz)
        checkValueCoversCost(_NoToysterz)
        nonReentrant
    {
        uint256 totalSupplyIter = totalSupply();
        for (uint32 i = 0; i < _NoToysterz; ) {
            unchecked {
                ++i;
            }
            _safeMint(msg.sender, totalSupplyIter + i);
        }
    }

    /**
################################################### WhiteList Session ###################################################
*/
    /**
    @dev public mints function for toysterz
    @param _NoToysterz number of toyserz to mint
    @param proof the proof path for the merkletree verification
     */
    function mintWLToysterz(bytes32[] memory proof, uint256 _NoToysterz)
        external
        payable
        isMintWLSwitchON
        onlyOrigin
        isWhiteListed(proof)
        checkNoPurchasedItemsZeroStore(_NoToysterz)
        checkWLNOPuchasedItems(_NoToysterz)
        checkValueCoversCost(_NoToysterz)
        nonReentrant
    {
        uint256 totalSupplyIter = totalSupply();
        for (uint32 i = 0; i < _NoToysterz; ) {
            unchecked {
                ++i;
                ++counterWLSession[msg.sender];
            }
            _safeMint(msg.sender, totalSupplyIter + i);
        }
    }

    //#####################################################################################################################

    /**
     * @dev Base URI for computing {tokenURI}.
     * override the supper _baseURI function
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return uRI_Base;
    }

    function burnToken(uint256 tokenId)
        external
        onlyTokenOwnerOrApproved(tokenId)
    {
        super._burn(tokenId);
    }

    /**
    @dev necessary override
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    event mintON(
        uint256 indexed _MintStartTime,
        uint256 indexed _Price,
        uint256 _MaxPerMintSession,
        bytes32 indexed _MintSessionType
    );

    event mintOFF(
        uint256 indexed _MintPauseTime,
        uint256 indexed _SupplySession,
        bytes32 indexed _MintSessionType
    );

    event mintPriceChanged(
        uint256 indexed _MintPriceOld,
        uint256 indexed _MintPriceNew,
        bytes32 indexed _MintSessionType
    );

    event maxPerMintSessionChanged(
        uint256 indexed _MaxPerMintOld,
        uint256 indexed _MaxPerMintNew,
        bytes32 indexed _MintSessionType
    );

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function SendfundsTO(address _to, uint256 ammount) external onlyOwner {
        uint256 balance = address(this).balance;
        require(
            ammount <= balance,
            "the Ammount to withdraw exceds th contract balance"
        );
        Address.sendValue(payable(_to), ammount);
    }
}