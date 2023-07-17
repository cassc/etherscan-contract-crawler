// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "contract-allow-list/contracts/proxy/interface/IContractAllowListProxy.sol";

contract SattvaBlendSupportersStandard is
    ERC721A("SattvaBlendSupportersStandard", "SBSST"),
    Ownable,
    Pausable,
    ERC2981,
    DefaultOperatorFilterer,
    AccessControl
{
    /**
     * Error functions
     */
    error AmountZeroOrLess();
    error CallerIsNotUser();
    error InsufficientBalance();
    error MaxMintPerAddressExceeded();
    error MaxSupplyExceeded();
    error NotAllowedMint();
    error NotApproved();
    error NotTokenOwner(uint256 tokenId);
    error OverMintAmountPerTransaction();
    error ZeroAddress();
     

    /**
     * Librarys
     */
    using Address for address payable;
    using EnumerableSet for EnumerableSet.AddressSet;


    /**
     * Minting parameters
     */
    uint256 public maxSupply = 200;
    uint256 public maxMintAmountPerTransaction = 3;
    uint256 public maxMintAmountPerAddressForPublicSale = 5;
    uint256 public cost = 20000000000000000;
    uint256 public saleId = 0;

    bool public onlyAllowlisted = true;
    bool public countMintedAmount = true;

    bytes32 public merkleRoot;

    // If you wanna reference a value => userMintedAmount[saleId][_ownerAddress]
    mapping(uint256 => mapping(address => uint256)) public userMintedAmount;


    /**
     * Basic parameters
     */
    // roles
    bytes32 public constant ADMIN    = keccak256("ADMIN");
    bytes32 public constant MINTER   = keccak256("MINTER");
    bytes32 public constant BURNER   = keccak256("BURNER");

    // Url
    string public baseURI = "https://coffee.sattva-soul-supporters.com/standard/json/";
    string public constant baseExtension = ".json";

    // Wallet Addresses
    address payable public withdrawAddress = payable(0xc45E3d207AB542891B235C21D7366d31Ed176f4B);

    // CAL
    EnumerableSet.AddressSet localAllowedAddresses;
    IContractAllowListProxy public cal;
    uint256 public calLevel = 1;
    bool public enableRestrict = true;

    constructor()
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
        _grantRole(MINTER, msg.sender);
        _grantRole(BURNER, msg.sender);

        _setDefaultRoyalty(withdrawAddress, 1000);
        _pause();
    }


    /**
     * Minting function
     */
    function mint(uint256 _mintAmount, uint256 _allowedMintAmount, bytes32[] calldata _merkleProof)
        external
        payable
        whenNotPaused
    {
        if(_mintAmount <= 0) revert AmountZeroOrLess();
        if(_mintAmount > maxMintAmountPerTransaction) revert OverMintAmountPerTransaction();
        if(_mintAmount + totalSupply() > maxSupply) revert MaxSupplyExceeded();
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

        _mint(msg.sender, _mintAmount);
    }


    /**
     * Setter functions
     */
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

    function setWithdrawAddress(address payable value)
        public
        onlyRole(ADMIN)
    {
        withdrawAddress = value;
    }

    function setOnlyAllowlisted(bool _state)
        external
        onlyRole(ADMIN)
    {
        onlyAllowlisted = _state;
    }

    function setBaseURI(string memory _newBaseURI)
        public
        onlyRole(ADMIN)
    {
        baseURI = _newBaseURI;
    }


    /**
     * Pause / Unpause
     */
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
     * Standard functions
     */
    function _startTokenId()
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return 1;
    }

    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }


    /**
     * Transfers overriding
     */
    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }


    /**
     * External functions
     */
    function mint(address _address, uint256 _amount)
        external
        onlyRole(MINTER)
    {
        _mint(_address, _amount);
    }

    function burn(address _address, uint256[] calldata tokenIds)
        external
        onlyRole(BURNER)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if(_address != ownerOf(tokenId)) revert NotTokenOwner(tokenId);

            _burn(tokenId);
        }
    }


    /**
     * CAL functions
     */
    function addLocalContractAllowList(address transferer)
        external
        onlyRole(ADMIN)
    {
        localAllowedAddresses.add(transferer);
    }

    function removeLocalContractAllowList(address transferer)
        external
        onlyRole(ADMIN)
    {
        localAllowedAddresses.remove(transferer);
    }

    function setCAL(address value)
        external
        onlyRole(ADMIN)
    {
        cal = IContractAllowListProxy(value);
    }

    function setCALLevel(uint256 value)
        external
        onlyRole(ADMIN)
    {
        calLevel = value;
    }


    /**
     * Royalty / Withdraw
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyRole(ADMIN)
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function withdraw()
        external
        onlyRole(ADMIN)
    {
        if(withdrawAddress == address(0)) revert ZeroAddress();
        withdrawAddress.sendValue(address(this).balance);
    }


    /**
     * Interface
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, AccessControl, ERC2981)
        returns (bool)
    {
        return
            AccessControl.supportsInterface(interfaceId) ||
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }


    /**
     * Around approve functions
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        if(!_isAllowed(operator) && approved) revert NotApproved();
        super.setApprovalForAll(operator, approved);
    }

    function getLocalContractAllowList()
        external
        view
        returns (address[] memory)
    {
        return localAllowedAddresses.values();
    }

    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (!_isAllowed(operator)) return false;
        return super.isApprovedForAll(account, operator);
    }

    function _isAllowed(address transferer)
        internal
        view
        virtual
        returns (bool)
    {
        if (!enableRestrict) return true;

        return localAllowedAddresses.contains(transferer) || cal.isAllowed(transferer, calLevel);
    }
}