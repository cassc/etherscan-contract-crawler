// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./ICNPMusic.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract CNPMusicSeller is
    AccessControl,
    Ownable,
    Pausable
{
    using Address for address payable;


    /**
     * Variables
     */
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant AIRDROPPER = keccak256("AIRDROPPER");

    address payable public withdrawAddress;
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmountPerTransaction = 30;
    uint256 public maxMintAmountPerAddressForPublicSale = 1;
    uint256 public cost = 1000000000000000;
    uint256 public saleId = 0;

    bool public onlyAllowlisted = true;
    bool public countMintedAmount = true;

    bytes32 public merkleRoot;
    
    // If you wanna reference a value => userMintedAmount[saleId][_ownerAddress]
    mapping(uint256 => mapping(address => uint256)) public userMintedAmount;

    ICNPMusic public cnpm;


    /**
     * Constructor
     */
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
        _grantRole(AIRDROPPER, msg.sender);

        _pause();
    }


    /**
     * Error functions
     */
    error AmountZeroOrLess();
    error CallerIsNotUser();
    error InsufficientBalance();
    error MaxMintPerAddressExceeded();
    error MaxSupplyExceeded();
    error NotAllowedMint();
    error NotMatchLengthAddressesAndUsers();
    error OverMintAmountPerTransaction();
    error ZeroAddress();


    /**
     * Functions
     */
    function mint(uint256 _mintAmount, uint256 _allowedMintAmount, bytes32[] calldata _merkleProof)
        external
        payable
        whenNotPaused
    {
        if(_mintAmount <= 0) revert AmountZeroOrLess();
        if(_mintAmount > maxMintAmountPerTransaction) revert OverMintAmountPerTransaction();
        if(_mintAmount + cnpmTotalSupply() > maxSupply) revert MaxSupplyExceeded();
        if(cost * _mintAmount > msg.value) revert InsufficientBalance();
        if(tx.origin != msg.sender) revert CallerIsNotUser();

        uint256 maxMintAmountPerAddress;

        if(onlyAllowlisted == true) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _allowedMintAmount));
            if(!MerkleProof.verify(_merkleProof, merkleRoot, leaf)) revert NotAllowedMint();

            maxMintAmountPerAddress = _allowedMintAmount;
        } else {
            maxMintAmountPerAddress = maxMintAmountPerAddressForPublicSale;
        }

        if(countMintedAmount == true) {
            if(_mintAmount + userMintedAmount[saleId][msg.sender] > maxMintAmountPerAddress) revert MaxMintPerAddressExceeded();
            userMintedAmount[saleId][msg.sender] += _mintAmount;
        }

        cnpm.mint(msg.sender, _mintAmount);
    }

    function airDrop(address _airdropAddress, uint256 _mintAmount)
        external
        onlyRole(AIRDROPPER)
    {   
        if(_mintAmount <= 0) revert AmountZeroOrLess();
        if(_mintAmount + cnpmTotalSupply() > maxSupply) revert MaxSupplyExceeded();

        // @dev Airdrop amount is not containing userMintedAmount.
        //userMintedAmount[saleId][_airdropAddress] += _mintAmount;
        cnpm.mint(_airdropAddress, _mintAmount);
    }

    function getUserMintedAmountCurrentSale(address _address)
        external
        view
        returns (uint256)
    {
        return userMintedAmount[saleId][_address];
    }

    function setMaxSupply(uint256 _maxSupply)
        external
        onlyRole(ADMIN)
    {
        maxSupply = _maxSupply;
    }

    function setMaxMintAmountPerTransaction(uint256 _maxMintAmountPerTransaction)
        external
        onlyRole(ADMIN)
    {
        maxMintAmountPerTransaction = _maxMintAmountPerTransaction;
    }

    function setMaxMintAmountPerAddressForPublicSale(uint256 _maxMintAmountPerAddressForPublicSale)
        external
        onlyRole(ADMIN)
    {
        maxMintAmountPerAddressForPublicSale = _maxMintAmountPerAddressForPublicSale;
    }

    function setCost(uint256 _cost)
        external
        onlyRole(ADMIN)
    {
        cost = _cost;
    }

    function setCountMintedAmount(bool _state)
        external
        onlyRole(ADMIN)
    {
        countMintedAmount = _state;
    }

    function setSaleId(uint256 _saleId)
        external
        onlyRole(ADMIN)
    {
        saleId = _saleId;
    }

    function setMerkleRoot(bytes32 _merkleRoot)
        external
        onlyRole(ADMIN)
    {
        merkleRoot = _merkleRoot;
    }

    function withdraw()
        external
        onlyRole(ADMIN)
    {
        if(withdrawAddress == address(0)) revert ZeroAddress();
        withdrawAddress.sendValue(address(this).balance);
    }

    function setWithdrawAddress(address payable value)
        public
        onlyRole(ADMIN)
    {
        withdrawAddress = value;
    }

    function setCNPM(address value)
        external
        onlyRole(ADMIN)
    {
        cnpm = ICNPMusic(value);
    }

    function cnpmTotalSupply()
        public
        view
        returns (uint256)
    {
        if(address(cnpm) == address(0)) revert ZeroAddress();
        return cnpm.cnpmTotalSupply();
    }

    function setOnlyAllowlisted(bool _state)
        external
        onlyRole(ADMIN)
    {
        onlyAllowlisted = _state;
    }

    function pause()
        external
        onlyRole(ADMIN)
    {
        _pause();
    }

    function unpause()
        external
        onlyRole(ADMIN)
    {
        _unpause();
    }
    
    
    /**
     * Override AccessControl
     */
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