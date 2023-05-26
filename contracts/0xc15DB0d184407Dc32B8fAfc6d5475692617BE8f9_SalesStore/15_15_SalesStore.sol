// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./interface/IAPPEggs.sol";
import "./interface/IERC721Pass.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SalesStore is AccessControl, Ownable, Pausable {
    using Address for address payable;

    bytes32 public constant ADMIN = keccak256('ADMIN');

    constructor() {
        _grantRole(ADMIN, msg.sender);
        _pause();
    }

    // ==================================================================
    // Structs
    // ==================================================================
    struct Sale {
        uint8 saleId;
        uint248 mintCost;
        uint256 maxSupply;
        bytes32 merkleRoot;
    }

    struct SalesRecord {
        uint8 id;
        uint248 amount;
    }

    // ==================================================================
    // Event
    // ==================================================================
    event ChangeSale(uint8 oldId, uint8 newId);

    // ==================================================================
    // Variables
    // ==================================================================
    address payable public withdrawAddress;
    Sale internal _currentSale;
    uint256 public soldCount = 0;
    mapping(address => SalesRecord) internal _salesRecordByBuyer;
    bool sbtSameMint = true;
    bool sbtPause;  // default:false

    IAPPEggs public eggs;
    IERC721Pass public passport;

    // ==================================================================
    // Modifier
    // ==================================================================
    modifier isNotOverMaxSaleSupply(uint256 amount) {
        require(
            amount + soldCount <= _currentSale.maxSupply,
            "claim is over the max sale supply."
        );
        _;
    }

    modifier isNotOverAllowedAmount(uint248 amount, uint248 allowedAmount) {
        require(
            getBuyCount() + amount <= allowedAmount,
            "claim is over allowed amount."
        );
        _;
    }

    modifier enoughEth(uint256 amount) {
        require(msg.value >= _currentSale.mintCost * amount, "not enough eth.");
        _;
    }

    modifier hasRight(
        uint256 tokenId,
        uint248 allowedAmount,
        bytes32[] calldata merkleProof
    ) {
        bytes32 node = keccak256(
            // abi.encodePacked(msg.sender, "-", tokenId, "-", allowedAmount)
            abi.encodePacked(msg.sender, tokenId, allowedAmount)
        );
        require(
            MerkleProof.verifyCalldata(
                merkleProof,
                _currentSale.merkleRoot,
                node
            ),
            "invalid proof."
        );
        _;
    }

    function claim(
        uint256 tokenId,
        uint248 amount,
        uint248 allowedAmount,
        bytes32[] calldata merkleProof
    )
        external payable
        whenNotPaused
        hasRight(tokenId, allowedAmount, merkleProof)
        isNotOverMaxSaleSupply(amount)
        enoughEth(amount)
        isNotOverAllowedAmount(amount, allowedAmount)
    {
        SalesRecord storage record = _salesRecordByBuyer[msg.sender];

        if (record.id == _currentSale.saleId) {
            record.amount += amount;
        } else {
            record.id = _currentSale.saleId;
            record.amount = amount;
        }

        soldCount += amount;

        // PassportSBT
        if(sbtSameMint == true){
            claimPassport();
        }

        eggs.mint(msg.sender, tokenId, amount);
    }

    function claimPassport() public{
        require(sbtPause == false,"PassportSBT is pause.");
        if(passport.balanceOf(msg.sender) == 0){
            passport.minterMint(msg.sender,1);
        }
    }

    // ==================================================================
    // Functions
    // ==================================================================
    function getCurrentSale()
        external
        view
        virtual
        returns (
            uint8,
            uint256,
            uint256
        )
    {
        return (
            _currentSale.saleId,
            _currentSale.mintCost,
            _currentSale.maxSupply
        );
    }

    function setCurrentSale(Sale calldata sale) external onlyRole(ADMIN) {
        uint8 oldId = _currentSale.saleId;
        _currentSale = sale;
        soldCount = 0;

        emit ChangeSale(oldId, sale.saleId);
    }

    function getBuyCount() public view returns (uint256) {
        SalesRecord storage record = _salesRecordByBuyer[msg.sender];

        if (record.id == _currentSale.saleId) {
            return record.amount;
        } else {
            return 0;
        }
    }

    function getSbtTotalSupply() external view returns (uint256) {
        return passport.totalSupply();
    }

    function withdraw() external onlyRole(ADMIN) {
        require(
            withdrawAddress != address(0),
            "withdraw address is 0 address."
        );
        withdrawAddress.sendValue(address(this).balance);
    }

    function setWithdrawAddress(address payable value)
        external
        onlyRole(ADMIN)
    {
        withdrawAddress = value;
    }

    function setEggs(address value) external onlyRole(ADMIN) {
        eggs = IAPPEggs(value);
    }

    function setPassport(address value) external onlyRole(ADMIN) {
        passport = IERC721Pass(value);
    }

    function pause() external onlyRole(ADMIN) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN) {
        _unpause();
    }

    function setSbtSameMint(bool _value) external onlyRole(ADMIN) {
        sbtSameMint = _value;
    }

    function setSbtPause(bool _value) external onlyRole(ADMIN) {
        sbtPause = _value;
    }

    // ==================================================================
    // override AccessControl
    // ==================================================================
    function grantRole(bytes32 role, address account)
        public
        override
        onlyOwner
    {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account)
        public
        override
        onlyOwner
    {
        _revokeRole(role, account);
    }
}