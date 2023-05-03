//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import { DefaultOperatorFilterer } from "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import { ERC721MPF } from "./ERC721MPF.sol";
import { ILaunchpad , ILaunchpadRegistry } from "./ILaunchpad.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { LaunchpadEnabled } from "./LaunchpadEnabled.sol";
import { IOS } from "./IOS.sol";
contract MintPassFactory is Ownable, ERC721MPF, DefaultOperatorFilterer, LaunchpadEnabled, IOS
{
    struct MintPass
    {
        uint _MaxSupply;          // _MaxSupply
        uint _MintPacks;          // _MintPacks
        uint _ArtistIDs;          // _ArtistIDs
        uint _ArtBlocksProjectID; // _ArtBlocksProjectID note: For Cases Where Mint Pass ProjectID 1:1 With ProjectIDs
        uint _ReserveAmount;      // _Reserve
        string _MetadataURI;      // _MetadataURI
    }

    uint public _TotalUniqueProjects;  // Total Projects Invoked
    address public _Multisig; // test
    uint private constant _ONE_MILLY = 1000000;
    uint private constant _DEFAULT = type(uint).max; // max integer

    mapping(uint=>MintPass) public MintPasses;
    mapping(uint=>uint) public ArtistIDs;
    mapping(address=>bool) public Authorized;
    mapping(uint=>uint[]) public MintPackIndexes;
    
    event MintPassProjectCreated(uint MintPassProjectID);
    event AuthorizedContract(address ContractAddress);
    event DeauthorizedContract(address ContractAddress);

    /**
     * @dev Mint Pass Factory Constructor
     */
    constructor() ERC721MPF("Bright Moments Mint Pass | MPBRT", "MPBRT") 
    { 
        Authorized[msg.sender] = true; 
        _Multisig = msg.sender;
    }

    /**
     * @dev Returns All Mint Pack Indexes
     */
    function ReadMintPackIndexes(uint MintPassProjectID) public view returns (uint[] memory) { return MintPackIndexes[MintPassProjectID]; }

    /**
     * @dev Direct Mint Function
     */
    function _MintToFactory(uint MintPassProjectID, address Recipient, uint Amount) external onlyAuthorized
    {
        require(_Active[MintPassProjectID], "MintPassFactory: ProjectID: `MintPassProjectID` Is Not Active");
        _mint(MintPassProjectID, Recipient, Amount);
    }

    /**
     * @dev Direct Mint To Factory Pack
     */
    function _MintToFactoryPack(uint MintPassProjectID, address Recipient, uint Amount) external onlyAuthorized
    {
        require(_Active[MintPassProjectID], "MintPassFactory: ProjectID: `MintPassProjectID` Is Not Active");
        uint NumArtists = MintPasses[MintPassProjectID]._ArtistIDs;
        uint NumToMint = NumArtists * Amount;
        uint StartingTokenID = ReadProjectInvocations(MintPassProjectID);
        _mint(MintPassProjectID, Recipient, NumToMint);
        for(uint x; x < Amount; x++) { MintPackIndexes[MintPassProjectID].push(StartingTokenID + (NumArtists * x)); }
    }

    /**
     * @dev LiveMint Redeems Mint Pass If Not Already Burned & Sends Minted Work To Owner's Wallet
     */
    function _LiveMintBurn(uint TokenID) external onlyAuthorized returns (address _Recipient, uint _ArtistID)
    {
        address Recipient = IERC721(address(this)).ownerOf(TokenID);
        require(Recipient != address(0), "MPMX: Invalid Recipient");
        _burn(TokenID, false);
        uint MintPassProjectID = TokenID % _ONE_MILLY;
        if(MintPasses[MintPassProjectID]._ArtBlocksProjectID == _DEFAULT) { return (Recipient, ArtistIDs[TokenID]); }
        else { return (Recipient, MintPasses[MintPassProjectID]._ArtBlocksProjectID); }
    }

    /**
     * @dev Initializes A New Mint Pass
     */
    function __InitMintPass(MintPass memory _MintPass) external onlyAuthorized returns (uint MintPassProjectID)
    {   
        _Active[_TotalUniqueProjects] = true;
        require(_MintPass._ArtistIDs * _MintPass._MintPacks <= _MintPass._MaxSupply, "MintPassFactory: Invalid Mint Pass Parameters");
        _MaxSupply[_TotalUniqueProjects] = _MintPass._MaxSupply; // Internal Max Supply
        MintPasses[_TotalUniqueProjects] = _MintPass;            // Struct Assignment
        MintPasses[_TotalUniqueProjects]._MetadataURI = _MintPass._MetadataURI;
        if(_MintPass._ReserveAmount > 0)
        { 
            _mint(
                _TotalUniqueProjects,    // MintPassProjectID
                _Multisig,               // Multisig
                _MintPass._ReserveAmount // Reserve Amount
            );
        }
        emit MintPassProjectCreated(_TotalUniqueProjects);
        _TotalUniqueProjects++;
        return (_TotalUniqueProjects - 1);
    }

    /**
     * @dev Updates The BaseURI For A Project
     */
    function __NewBaseURI(uint MintPassProjectID, string memory NewURI) external onlyAuthorized 
    { 
        require(_Active[MintPassProjectID], "MintPassFactory: Mint Pass Is Not Active");
        MintPasses[MintPassProjectID]._MetadataURI = NewURI; 
    }

    /**
     * @dev Overrides The Operator Filter Active State
     */
    function __ChangeOperatorFilterState(bool State) external override onlyOwner { OPERATOR_FILTER_ENABLED = State; }

    /**
     * @dev Overrides The Launchpad Registry Address
     */
    function __NewLaunchpadAddress(address NewAddress) external onlyAuthorized { _LAUNCHPAD = NewAddress; }

    /**
     * @dev Authorizes A Contract To Mint
     */
    function ____AuthorizeContract(address NewAddress) external onlyOwner 
    { 
        Authorized[NewAddress] = true; 
        emit AuthorizedContract(NewAddress);
    }

    /**
     * @dev Deauthorizes A Contract From Minting
     */
    function ___DeauthorizeContract(address NewAddress) external onlyOwner 
    { 
        Authorized[NewAddress] = false; 
        emit DeauthorizedContract(NewAddress);
    }

    /**
     * @dev Overrides The Active State For A MintPassProjectID
     */
    function ____OverrideActiveState(uint MintPassProjectID, bool State) external onlyOwner { _Active[MintPassProjectID] = State; }

    /**
     * @dev Overrides The Max Supply For A MintPassProjectID
     */
    function ____OverrideMaxSupply(uint MintPassProjectID, uint NewMaxSupply) external onlyOwner 
    { 
        _MaxSupply[MintPassProjectID] = NewMaxSupply; 
        MintPasses[MintPassProjectID]._MaxSupply = NewMaxSupply;
    }

    /**
     * @dev Owner Burn Function
     */
    function ____OverrideBurn(uint[] calldata TokenIDs) external onlyOwner
    {
        for(uint x; x < TokenIDs.length; x++) { _burn(TokenIDs[x], false); }
    }

    /**
     * @dev Mints To Owner
     */
    function ___OverrideMint(uint MintPassProjectID, uint Amount) external onlyOwner
    {
        require(_Active[MintPassProjectID], "MintPassFactory: Mint Pass Is Not Active");
        _mint(MintPassProjectID, msg.sender, Amount);
    }

    /**
     * @dev Returns A MintPassProjectID From A TokenID
     */
    function ViewProjectID(uint TokenID) public pure returns (uint) { return (TokenID - (TokenID % 1000000)) / 1000000; }

    /**
     * @dev Returns Base URI Of Desired TokenID
     */
    function _baseURI(uint TokenID) internal view virtual override returns (string memory) 
    { 
        uint MintPassProjectID = ViewProjectID(TokenID);
        return MintPasses[MintPassProjectID]._MetadataURI;
        // return ILaunchpadRegistry(ILaunchpad(_LAUNCHPAD).ViewAddressLaunchpadRegistry()).ViewBaseURIMintPass(MintPassProjectID);
    }

    /*---------------------
     * OVERRIDE FUNCTIONS *
    ----------------------*/

    function setApprovalForAll(
        address operator, 
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) { super.setApprovalForAll(operator, approved); }

    function approve(
        address operator, 
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) { super.approve(operator, tokenId); }

    function transferFrom(
        address from, 
        address to, 
        uint256 tokenId
    ) public override onlyAllowedOperator(from) { super.transferFrom(from, to, tokenId); }

    function safeTransferFrom(
        address from, 
        address to, 
        uint256 tokenId
    ) public override onlyAllowedOperator(from) { super.safeTransferFrom(from, to, tokenId); }

    function safeTransferFrom(
        address from, 
        address to, 
        uint256 tokenId, 
        bytes memory data
    ) public override onlyAllowedOperator(from) { super.safeTransferFrom(from, to, tokenId, data); }

    /**
     * @dev Access Modifier For External Smart Contracts
     * note: This Is A Custom Access Modifier That Is Used To Restrict Access To Only Authorized Contracts
     */
    modifier onlyAuthorized()
    {
        if(msg.sender != owner()) 
        { 
            require(Authorized[msg.sender], "MintPassFactory: Sender Is Not Authorized Contract"); 
        }
        _;
    }
}