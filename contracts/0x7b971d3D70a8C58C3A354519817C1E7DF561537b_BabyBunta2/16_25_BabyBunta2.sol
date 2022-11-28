// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

//import "erc721psi/contracts/ERC721Psi.sol";
import "erc721psi/contracts/extension/ERC721PsiAddressData.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./libs/DefaultOperatorFilterer.sol";
import "./libs/IDescriptor.sol";
import "./libs/IContractAllowListProxy.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract BabyBunta2State {
    ///////////////////////////////////////////////////////////////////////////
    // Enum
    ///////////////////////////////////////////////////////////////////////////
    enum SalePhase {
        FreeMint,
        PreSale,
        PublicSale
    }

    ///////////////////////////////////////////////////////////////////////////
    // Constants
    ///////////////////////////////////////////////////////////////////////////

    uint256 public constant MAX_SUPPLY = 1000;
    uint8 public constant ALLOCATION_FOR_FREE_MINT = 2;
    uint8 public constant ALLOCATION_FOR_ALLOW_LIST = 5;

    address public constant WITHDRAW_ADDRESS =
        0xFBa08BBFf544A20CaAa6e2278BED853f5Ed88648;

    ///////////////////////////////////////////////////////////////////////////
    // Variables
    ///////////////////////////////////////////////////////////////////////////

    // CAL
    IContractAllowListProxy public CAL;
    uint256 public CALLevel = 1;

    // MintAmountLimitation : This array is used as CONSTANT
    uint16[3] public maxMintAmount = [
        ALLOCATION_FOR_FREE_MINT,
        ALLOCATION_FOR_ALLOW_LIST,
        2
    ];

    // AL
    mapping(address => uint256) public freeMintList;
    mapping(address => uint256) public preSaleList;
    mapping(address => uint16[2]) public limitedMintedAmount;

    // Sale Status
    bool public paused = true;
    SalePhase public salePhase;

    // Automatic sale control
    bool public usePeriodSale = true;
    uint256[3] public timeStart = [
        1669719900, /* 11/29 2005 */
        1669806300, /* 11/30 2005 */
        1669892700 /* 12/1 2005*/
    ];
    uint256[3] public timeDuration = [
        2 hours - 300,
        4 hours - 300,
        7 days - 300
    ];

    // cost
    uint256[3] public cost = [0, 0.005 ether, 0.008 ether];

    // metadata
    IDescriptor public descriptor;

    // royalty
    address public royaltyAddress = WITHDRAW_ADDRESS;
    uint96 public royaltyFee = 1000; // default:10%

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
    error MintAmountExceeded();
    error MaxSupplyExceeded();
    error InsufficientFunds();
    error CallerNotUser();
    error MintAmountIsZero();
    error ProhibitedBecauseSBT();
    error NotAllowedByCAL(address operator);
}

abstract contract BabyBunta2Admin is
    BabyBunta2State,
    IERC2981,
    DefaultOperatorFilterer,
    AccessControl,
    Ownable,
    ERC721PsiAddressData
{
    ///////////////////////////////////////////////////////////////////////////
    // Withdraw funds
    ///////////////////////////////////////////////////////////////////////////
    function withdraw() public onlyOwner {
        (bool os, ) = payable(WITHDRAW_ADDRESS).call{
            value: address(this).balance
        }("");
        require(os);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Owner Mint function
    ///////////////////////////////////////////////////////////////////////////
    function ownerMint(address to, uint256 quantity) public onlyOwner {
        _mint(to, quantity);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Setter functions
    ///////////////////////////////////////////////////////////////////////////
    function setPause(bool _state) external onlyAdmin {
        paused = _state;
    }

    function setSalePhase(SalePhase _phase) external onlyAdmin {
        salePhase = _phase;
    }

    function setCost(uint256 _newCost, SalePhase _target) external onlyAdmin {
        cost[uint256(_target)] = _newCost;
    }

    function setFreeMintList(address[] memory _addr, bool _state)
        external
        onlyOwner
    {
        uint256 l = _addr.length;
        uint8 newAlloc;
        if (_state) {
            newAlloc = ALLOCATION_FOR_FREE_MINT;
        }
        for (uint256 i = 0; i < l; i++) {
            freeMintList[_addr[i]] = newAlloc;
        }
    }

    function setPreSaleList(address[] memory _addr, bool _state)
        external
        onlyOwner
    {
        uint256 l = _addr.length;
        uint8 newAlloc; // =0
        if (_state) {
            newAlloc = ALLOCATION_FOR_ALLOW_LIST;
        }
        for (uint256 i = 0; i < l; i++) {
            preSaleList[_addr[i]] = newAlloc;
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

    function setTimeStart(uint256 index, uint256 newTime) external onlyAdmin {
        timeStart[index] = newTime;
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
    // Modifiers
    ///////////////////////////////////////////////////////////////////////////
    modifier onlyAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    modifier whenOnSale() {
        if (paused) {
            if (!usePeriodSale) {
                revert SaleIsPaused();
            } else {
                uint256 phase = uint256(salePhase);
                uint256 start = timeStart[phase];
                if (block.timestamp < start) revert SaleIsPaused();
                if (block.timestamp > start + timeDuration[phase])
                    revert SaleIsPaused();
            }
        }
        _;
    }

    modifier onlyValidMinter() {
        if (salePhase == SalePhase.FreeMint) {
            if (freeMintList[msg.sender] == 0) revert NoAllocationInThisSale();
        }
        if (salePhase == SalePhase.PreSale) {
            if (preSaleList[msg.sender] == 0) revert NoAllocationInThisSale();
        }
        _;
    }

    modifier callerIsUser() {
        if (tx.origin != msg.sender) revert CallerNotUser();
        _;
    }

    modifier whenValidMintAmount(uint256 amount) {
        // Check mint amount in one transaction
        if (amount > maxMintAmount[uint256(salePhase)])
            revert MintAmountExceeded();
        if (amount == 0) revert MintAmountIsZero();
        // Check remaining quantity of allocation
        if (salePhase != SalePhase.PublicSale) {
            uint256 alloc = (salePhase == SalePhase.FreeMint)
                ? freeMintList[msg.sender]
                : preSaleList[msg.sender];
            if (
                alloc <
                amount + limitedMintedAmount[msg.sender][uint256(salePhase)]
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

contract BabyBunta2 is BabyBunta2Admin {
    using Strings for uint256;

    ///////////////////////////////////////////////////////////////////////////
    // Constructor
    ///////////////////////////////////////////////////////////////////////////
    constructor() ERC721Psi("BabyBunta 2nd collection", "BBC") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // TODO
        _mint(WITHDRAW_ADDRESS, 1);
        // _mint(owner(), 10);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Mint functions
    ///////////////////////////////////////////////////////////////////////////
    function mint(uint256 amount)
        external
        payable
        whenOnSale
        onlyValidMinter
        callerIsUser
        whenValidMintAmount(amount)
        whenEnoughFunds(msg.value, amount)
    {
        if (salePhase != SalePhase.PublicSale) {
            limitedMintedAmount[msg.sender][uint256(salePhase)] += uint16(
                amount
            );
        }
        // CallerIsUserなので、_safeMintを使う必要はない
        _mint(msg.sender, amount);
    }

    function _mint(address to, uint256 quantity) internal override {
        if (quantity + totalSupply() > MAX_SUPPLY) revert MaxSupplyExceeded();
        super._mint(to, quantity);
    }

    ///////////////////////////////////////////////////////////////////////////
    // State functions
    ///////////////////////////////////////////////////////////////////////////
    function nowOnSale() external view whenOnSale returns (bool) {
        return true;
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
    {
        if (approved){
            if (isSBT) revert ProhibitedBecauseSBT();
            if (address(CAL) != address(0)){
                if (!CAL.isAllowed(operator, CALLevel)) revert NotAllowedByCAL(operator);
            }
        }
        super.setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 tokenId)
        public
        virtual
        override
    {
        if (to != address(0)) {
            if (isSBT) revert ProhibitedBecauseSBT();
            if (address(CAL) != address(0)){
                if (!CAL.isAllowed(to, CALLevel)) revert NotAllowedByCAL(to);
            }
        }
        super.approve(to, tokenId);
    }
}