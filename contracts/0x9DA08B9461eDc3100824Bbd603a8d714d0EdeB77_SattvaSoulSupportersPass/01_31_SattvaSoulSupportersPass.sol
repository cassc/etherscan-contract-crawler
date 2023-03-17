// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import { Base64 } from 'base64-sol/base64.sol';
import "contract-allow-list/contracts/ERC721AntiScam/restrictApprove/ERC721RestrictApprove.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

//tokenURI interface
interface ITokenURI {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract SattvaSoulSupportersPass is
    Ownable,
    ERC721RestrictApprove,
    AccessControl,
    DefaultOperatorFilterer,
    IERC2981,
    Pausable
{
    /**
     * Librarys
     */
    using Strings for uint256;
    using Address for address payable;

    /**
     * Variables
     */
    // roles
    bytes32 public constant ADMIN    = keccak256("ADMIN");
    bytes32 public constant MINTER   = keccak256("MINTER");
    bytes32 public constant BURNER   = keccak256("BURNER");
    bytes32 public constant AIRDROPPER = keccak256("AIRDROPPER");

    // Royalty
    address public royaltyAddress = 0xc45E3d207AB542891B235C21D7366d31Ed176f4B;
    uint96 public royaltyFee = 1000;

    // Uri
    string public baseURI;
    string public baseExtension = ".json";
    bool public useInterfaceMetadata = false;
    ITokenURI public interfaceOfTokenURI;

    address payable public withdrawAddress;
    uint256 public maxSupply = 2000;
    uint256 public maxMintAmountPerTransaction = 5;
    uint256 public maxMintAmountPerAddressForPublicSale = 1;
    uint256 public cost = 0;
    uint256 public saleId = 0;

    bool public onlyAllowlisted = true;
    bool public countMintedAmount = true;

    bytes32 public merkleRoot;
    
    // If you wanna reference a value => userMintedAmount[saleId][_ownerAddress]
    mapping(uint256 => mapping(address => uint256)) public userMintedAmount;

    // Single metadata
    bool public useSingleMetadata = false;
    string public imageURI;
    string public metadataTitle;
    string public metadataDescription;
    string public metadataAttributes;


    /**
     * Error functions
     */
    error AmountZeroOrLess();
    error CallerIsNotUser();
    error InsufficientBalance();
    error InvlidRoyaltyFee(uint256 fee);
    error MaxMintPerAddressExceeded();
    error MaxSupplyExceeded();
    error NotAllowedMint();
    error NotMatchLengthAddressesAndUsers();
    error OverMintAmountPerTransaction();
    error ZeroAddress();


    /**
     * Constructor
     */
    constructor() ERC721Psi("SattvaSoulPass", "SSP") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
        _grantRole(MINTER, msg.sender);
        _grantRole(BURNER, msg.sender);
        _grantRole(AIRDROPPER, msg.sender);

        _pause();

        _mint(msg.sender, 1);

        // Initialize CAL
        setCALLevel(1);
        _setCAL(0xdbaa28cBe70aF04EbFB166b1A3E8F8034e5B9FC7);  //Ethereum mainnet proxy
        // _setCAL(0xb506d7BbE23576b8AAf22477cd9A7FDF08002211);  //Goerli testnet proxy

        _addLocalContractAllowList(0x1E0049783F008A0085193E00003D00cd54003c71);  //OpenSea
        _addLocalContractAllowList(0x4feE7B061C97C9c496b01DbcE9CDb10c02f0a0Be);  //Rarible

        //use single metadata
        setUseSingleMetadata(true);
        setMetadataTitle("SattvaSoulPass");
        setMetadataDescription("This is SattvaSoulPass for some utilities in SattvaSoulSupporters.  Check it out informations from https://twitter.com/MATe_RIYA_NFT .");
        setMetadataAttributes("Passport");
        setImageURI("https://pass.sattva-soul-supporters.com/images/sattva_soul_pass.png");
    }


    /**
     * For external contract
     */
    function mint(address _to, uint256 _amount)
        external
        onlyRole(MINTER)
    {
        _mint(_to, _amount);
    }

    function burn(uint256 _tokenId)
        external
        onlyRole(BURNER)
    {
        _burn(_tokenId);
    }


    /**
     * Minter
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

    function airDrop(address _airdropAddress, uint256 _mintAmount)
        external
        onlyRole(AIRDROPPER)
    {   
        if(_mintAmount <= 0) revert AmountZeroOrLess();
        if(_mintAmount + totalSupply() > maxSupply) revert MaxSupplyExceeded();

        // @dev Airdrop amount is not containing userMintedAmount.
        //userMintedAmount[saleId][_airdropAddress] += _mintAmount;
        _mint(_airdropAddress, _mintAmount);
    }


    /**
     * Getter & Setter
     */
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

    function setCost(uint256 _cost)
        external
        onlyRole(ADMIN)
    {
        cost = _cost;
    }

    function setSaleId(uint256 _saleId)
        external
        onlyRole(ADMIN)
    {
        saleId = _saleId;
    }

    function setOnlyAllowlisted(bool _state)
        external
        onlyRole(ADMIN)
    {
        onlyAllowlisted = _state;
    }

    function setCountMintedAmount(bool _state)
        external
        onlyRole(ADMIN)
    {
        countMintedAmount = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot)
        external
        onlyRole(ADMIN)
    {
        merkleRoot = _merkleRoot;
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
     * Single metadata
     */
    function setUseSingleMetadata(bool _useSingleMetadata)
        public
        onlyRole(ADMIN)
    {
        useSingleMetadata = _useSingleMetadata;
    }

    function setMetadataTitle(string memory _metadataTitle)
        public
        onlyRole(ADMIN)
    {
        metadataTitle = _metadataTitle;
    }

    function setMetadataDescription(string memory _metadataDescription)
        public
        onlyRole(ADMIN)
    {
        metadataDescription = _metadataDescription;
    }

    function setMetadataAttributes(string memory _metadataAttributes)
        public
        onlyRole(ADMIN)
    {
        metadataAttributes = _metadataAttributes;
    }

    function setImageURI(string memory _newImageURI)
        public
        onlyRole(ADMIN)
    {
        imageURI = _newImageURI;
    }


    /**
     * Withdraw
     */
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


    /**
     * URI
     */
    function setInterfaceOfTokenURI(address _address)
        external
        onlyRole(ADMIN)
    {
        interfaceOfTokenURI = ITokenURI(_address);
    }

    function setUseInterfaceMetadata(bool _useInterfaceMetadata)
        external
        onlyRole(ADMIN)
    {
        useInterfaceMetadata = _useInterfaceMetadata;
    }

    function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI)
        external
        onlyRole(ADMIN)
    {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        external
        onlyRole(ADMIN)
    {
        baseExtension = _newBaseExtension;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (useInterfaceMetadata == true) {
            return interfaceOfTokenURI.tokenURI(_tokenId);
        }
        if(useSingleMetadata == true){
            return string( abi.encodePacked( 'data:application/json;base64,' , Base64.encode(
                abi.encodePacked(
                    '{'
                        '"name":"' , metadataTitle ,'",' ,
                        '"description":"' , metadataDescription ,  '",' ,
                        '"image": "' , imageURI , '",' ,
                        '"attributes":[{"trait_type":"type","value":"' , metadataAttributes , '"}]',
                    '}'
                )
            ) ) );
        }
        return string(abi.encodePacked(baseURI, "/", _tokenId.toString(), baseExtension));
    }


    /**
     * Royalty
     */
    function setRoyaltyAddress(address _royaltyAddress)
        external
        onlyRole(ADMIN)
    {
        if (_royaltyAddress == address(0)) revert ZeroAddress();
        royaltyAddress = _royaltyAddress;
    }

    function setRoyaltyFee(uint96 _royaltyFee)
        external
        onlyRole(ADMIN)
    {
        if (_royaltyFee > 10000) revert InvlidRoyaltyFee(_royaltyFee);
        royaltyFee = _royaltyFee;
    }

    function royaltyInfo(uint256, /*_tokenId*/ uint256 _salePrice)
        public
        view
        virtual
        override
        returns (address, uint256)
    {
        return (royaltyAddress, (_salePrice * uint256(royaltyFee)) / 10000);
    }


    /**
     * ERC721Psi AddressData
     */
    // Mapping owner address to address data
    mapping(address => AddressData) _addressData;

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }


    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address _owner) 
        public 
        view 
        virtual 
        override 
        returns (uint) 
    {
        require(_owner != address(0), "ERC721Psi: balance query for the zero address");
        return uint256(_addressData[_owner].balance);   
    }

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        override
        virtual
    {
        require(quantity < 2 ** 64);
        uint64 _quantity = uint64(quantity);

        if(from != address(0)){
            _addressData[from].balance -= _quantity;
        } else {
            // Mint
            _addressData[to].numberMinted += _quantity;
        }

        if(to != address(0)){
            _addressData[to].balance += _quantity;
        } else {
            // Burn
            _addressData[from].numberBurned += _quantity;
        }
        super._afterTokenTransfers(from, to, startTokenId, quantity);
    }


    /**
     * Overrides transfer functions
     */
    function transferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        virtual
        override
    {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }


    /**
     * Overrides approve functions
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        virtual
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }


    /**
     * Overrides ERC721RestrictApprove
     */
    function setEnebleRestrict(bool _enableRestrict)
        public
        onlyRole(ADMIN)
    {
        enableRestrict = _enableRestrict;
    }
    
    function addLocalContractAllowList(address transferer)
        external
        override
        onlyRole(ADMIN)
    {
        _addLocalContractAllowList(transferer);
    }

    function removeLocalContractAllowList(address transferer)
        external
        override
        onlyRole(ADMIN)
    {
        _removeLocalContractAllowList(transferer);
    }

    function getLocalContractAllowList()
        external
        override
        view
        returns(address[] memory)
    {
        return _getLocalContractAllowList();
    }

    function setCALLevel(uint256 level)
        public
        override
        onlyRole(ADMIN)
    {
        CALLevel = level;
    }

    function setCAL(address calAddress)
        external
        override
        onlyRole(ADMIN)
    {
        _setCAL(calAddress);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, ERC721RestrictApprove, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            AccessControl.supportsInterface(interfaceId) ||
            ERC721RestrictApprove.supportsInterface(interfaceId);
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