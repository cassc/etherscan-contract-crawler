// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

//import "erc721psi/contracts/ERC721Psi.sol";
import "erc721psi/contracts/extension/ERC721PsiAddressData.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./libs/IDescriptor.sol";
import "contract-allow-list/contracts/proxy/interface/IContractAllowListProxy.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract NFes2State {
    ///////////////////////////////////////////////////////////////////////////
    // Enum / Struct
    ///////////////////////////////////////////////////////////////////////////
    enum SalePhase {
        FreeMint,
        PreSale1,
        PreSale2,
        PublicSale
    }

    ///////////////////////////////////////////////////////////////////////////
    // Constants
    ///////////////////////////////////////////////////////////////////////////

    uint256 public constant MAX_SUPPLY = 1500;
    address public constant PRIMARY_ADDRESS = 0xB9Bd747986c543aC94bCfdD0FA6EdD711853D5c0;

    ///////////////////////////////////////////////////////////////////////////
    // Variables
    ///////////////////////////////////////////////////////////////////////////

    address public withdrawAddress =
        0xEB080d202DFb816318c08503A9E8f261ACf48fDb;

    // CAL
    IContractAllowListProxy public CAL;
    uint256 public CALLevel = 1;

    // AL
    mapping(SalePhase => mapping(address => uint16)) public allowLists;
    mapping(address => uint16[4]) public limitedMintedAmount;

    // Sale Status
    bool public paused = true;
    SalePhase public salePhase;

    uint16[4] public maxMintAmountPerTx = [
        2,
        3,
        3,
        3
    ];

    // Automatic sale control
    bool public usePeriodSale = true;
    uint256[4] public timeStart = [
        1676188800, /* 2/12 1700JST */
        1676197800, /* 2/12 1930JST */
        1676206800, /* 2/12 2200JST*/
        0
    ];
    uint256[4] public timeDuration = [
        2 hours,
        2 hours,
        2 hours,
        0
    ];

    // cost
    uint256[4] public cost = [
        0, 
        0.03 ether, 
        0.03 ether, 
        0.04 ether
    ];

    // metadata
    IDescriptor public descriptor;

    // royalty
    address public royaltyAddress = withdrawAddress;
    uint96 public royaltyFee = 500; // default:5%

    // SBT
    bool public isSBT;

    ///////////////////////////////////////////////////////////////////////////
    // Error Functions
    ///////////////////////////////////////////////////////////////////////////
    error ZeroAddress();
    error InvlidRoyaltyFee(uint256 fee);
    error SaleIsPaused();
    error NoAllocationInThisSale();
    error InsufficientAllocation();
    error ArrayLengthNotMatch();
    error MintAmountExceeded();
    error MaxSupplyExceeded();
    error InsufficientFunds();
    error CallerNotUser();
    error MintAmountIsZero();
    error ProhibitedBecauseSBT();
    error NotAllowedByCAL(address operator);
}

abstract contract NFes2Admin is
    NFes2State,
    IERC2981,
    DefaultOperatorFilterer,
    AccessControl,
    Ownable,
    ERC721PsiAddressData
{
    ///////////////////////////////////////////////////////////////////////////
    // Withdraw funds
    ///////////////////////////////////////////////////////////////////////////
    function withdraw() public payable onlyAdmin {
        (bool os, ) = payable(withdrawAddress).call{
            value: address(this).balance
        }("");
        require(os);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Owner Mint function
    ///////////////////////////////////////////////////////////////////////////
    function adminMint(address to, uint256 quantity) public onlyAdmin {
        _mint(to, quantity);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Setter functions
    ///////////////////////////////////////////////////////////////////////////
    function setWithdrawAddress(address addr) external onlyAdmin {
        if (addr == address(0)) revert ZeroAddress();
        withdrawAddress = addr;
    }

    function setPause(bool state) external onlyAdmin {
        paused = state;
    }

    function setSalePhase(SalePhase phase) external onlyAdmin {
        salePhase = phase;
    }

    function setCost(uint256 newCost, SalePhase phase) external onlyAdmin {
        cost[uint256(phase)] = newCost;
    }

    function setAllowList(SalePhase phase, address[] memory addr, uint16[] memory alloc)
        external
        onlyAdmin
    {
        uint256 len = addr.length;
        if (len != alloc.length) revert ArrayLengthNotMatch();
        for (uint256 i = 0; i < len; i++) {
            allowLists[phase][addr[i]] = alloc[i];
        }
    }

    function setDescriptor(IDescriptor _new) external onlyAdmin {
        descriptor = _new;
    }

    function setRoyaltyAddress(address _new) external onlyAdmin {
        if (_new == address(0)) revert ZeroAddress();
        royaltyAddress = _new;
    }

    function setRoyaltyFee(uint96 _new) external onlyAdmin {
        if (_new >= 10000) revert InvlidRoyaltyFee(_new);
        royaltyFee = _new;
    }

    function setIsSBT(bool _state) external onlyAdmin {
        isSBT = _state;
    }

    function setTimeStart(SalePhase phase, uint256 newTime) external onlyAdmin {
        timeStart[uint256(phase)] = newTime;
    }

    function setTimeDuration(uint256 index, uint256 newDuration)
        external
        onlyAdmin
    {
        timeDuration[index] = newDuration;
    }

    function setUsePeriodSale(bool _state) external onlyAdmin {
        usePeriodSale = _state;
    }

    function setCAL(IContractAllowListProxy _newCAL) external onlyAdmin {
        CAL = _newCAL;
    }

    function setCALLevel(uint256 _newLevel) external onlyAdmin {
        CALLevel = _newLevel;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Essential getter functions
    ///////////////////////////////////////////////////////////////////////////
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, IERC165, ERC721Psi)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            AccessControl.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(
        uint256, /*_tokenId*/
        uint256 _salePrice
    ) public view virtual override returns (address, uint256) {
        return (royaltyAddress, (_salePrice * uint256(royaltyFee)) / 10000);
    }
    ///////////////////////////////////////////////////////////////////////////
    // State functions
    ///////////////////////////////////////////////////////////////////////////
    /*
    function nowOnSale() external view whenOnSale returns (bool) {
        return true;
    }
    */
    function nowOnSale() public view returns (bool) {
        if (paused) {
            if (!usePeriodSale) {
                return false;
            } else {
                uint256 index = uint256(salePhase);
                uint256 start = timeStart[index];
                return (start <= block.timestamp && block.timestamp <= start + timeDuration[index]);
            }
        }
        return true;
    }
    ///////////////////////////////////////////////////////////////////////////
    // Modifiers
    ///////////////////////////////////////////////////////////////////////////
    modifier onlyAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    modifier whenOnSale() {
        if (!nowOnSale()) revert SaleIsPaused();
        _;
    }

    modifier callerIsUser() {
        if (tx.origin != msg.sender) revert CallerNotUser();
        _;
    }

    modifier whenValidMintAmount(uint256 amount) {
        // Check mint amount in one transaction
        if (amount > maxMintAmountPerTx[uint256(salePhase)])
            revert MintAmountExceeded();
        if (amount == 0) revert MintAmountIsZero();
        SalePhase phase = salePhase;
        if (phase != SalePhase.PublicSale) {
            if (allowLists[phase][msg.sender] == 0) revert NoAllocationInThisSale();
            // Check remaining quantity of allocation
            uint256 alloc = allowLists[phase][msg.sender];
            if (
                alloc <
                amount + limitedMintedAmount[msg.sender][uint256(phase)]
            ) revert InsufficientAllocation();
        }
        _;
    }

    modifier whenEnoughFunds(uint256 value, uint256 amount) {
        if (value < (amount * cost[uint256(salePhase)]))
            revert InsufficientFunds();
        _;
    }
}

contract NFes2 is NFes2Admin {
    using Strings for uint256;

    ///////////////////////////////////////////////////////////////////////////
    // Constructor
    ///////////////////////////////////////////////////////////////////////////
    constructor() ERC721Psi("NFTFestival2nd", "NFES2") {
        _transferOwnership(PRIMARY_ADDRESS);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, PRIMARY_ADDRESS);
        // TODO
        _mint(PRIMARY_ADDRESS, 1);
        // _mint(owner(), 10);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Mint functions
    ///////////////////////////////////////////////////////////////////////////
    function mint(uint256 amount)
        external
        payable
        whenOnSale
        callerIsUser
        whenValidMintAmount(amount)
        whenEnoughFunds(msg.value, amount)
    {
        limitedMintedAmount[msg.sender][uint256(salePhase)] += uint16(amount);
        // _safeMint is not needed because under CallerIsUser
        _mint(msg.sender, amount);
    }

    function _mint(address to, uint256 quantity) internal override {
        if (quantity + totalSupply() > MAX_SUPPLY) revert MaxSupplyExceeded();
        super._mint(to, quantity);
    }


    ///////////////////////////////////////////////////////////////////////////
    // Metadata functions
    ///////////////////////////////////////////////////////////////////////////
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Psi: URI query for nonexistent token");

        return descriptor.tokenURI(tokenId);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Transfer functions
    ///////////////////////////////////////////////////////////////////////////
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        if (
            isSBT &&
            from != address(0) &&
            to != address(0x000000000000000000000000000000000000dEaD)
        ) revert ProhibitedBecauseSBT();
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Approve functions
    ///////////////////////////////////////////////////////////////////////////
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
        onlyAllowedOperatorApproval(operator)
    {
        if (approved){
            if (isSBT) revert ProhibitedBecauseSBT();
            if (address(CAL) != address(0)){
                if (!CAL.isAllowed(operator, CALLevel)) revert NotAllowedByCAL(operator);
            }
        }
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        virtual
        override
        onlyAllowedOperatorApproval(operator)
    {
        if (operator != address(0)) {
            if (isSBT) revert ProhibitedBecauseSBT();
            if (address(CAL) != address(0)){
                if (!CAL.isAllowed(operator, CALLevel)) revert NotAllowedByCAL(operator);
            }
        }
        super.approve(operator, tokenId);
    }
}