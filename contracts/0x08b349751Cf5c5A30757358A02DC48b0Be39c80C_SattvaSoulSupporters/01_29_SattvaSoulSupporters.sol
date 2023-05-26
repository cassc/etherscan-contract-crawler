// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./ISattvaSoulSupporters.sol";
import "contract-allow-list/contracts/ERC721AntiScam/restrictApprove/ERC721RestrictApprove.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

/// @title EIP-721 Metadata Update Extension
interface IERC4906 is IERC165, IERC721RestrictApprove {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.    
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

//tokenURI interface
interface ITokenURI {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract SattvaSoulSupporters is
    ISattvaSoulSupporters,
    Ownable,
    ERC721RestrictApprove,
    AccessControl,
    DefaultOperatorFilterer,
    IERC2981,
    IERC4906
{
    /**
     * Librarys
     */
    using Strings for uint256;


    /**
     * Variables
     */
    // roles
    bytes32 public constant ADMIN    = keccak256("ADMIN");
    bytes32 public constant MINTER   = keccak256("MINTER");
    bytes32 public constant BURNER   = keccak256("BURNER");
    bytes32 public constant SADHANA  = keccak256("SADHANA");
    bytes32 public constant METADATA = keccak256("METADATA");

    ITokenURI public interfaceOfTokenURI;
    bool public useInterfaceMetadata = false;

    // Royalty
    address public royaltyAddress = 0xc45E3d207AB542891B235C21D7366d31Ed176f4B;
    uint96 public royaltyFee = 1000;

    // Uri
    string public baseURI;
    string public baseExtension = ".json";

    // Parameters for spirituality
    mapping(uint256 => string) public spiritualityPhase;
    
    // struct for tokens
    // - spiritualityState:
    //              0->'animal',
    //              2->'saint'(evolution from animal),
    //              3->'human'(evolution from animal)
    // - sadhanaTime      : Number of times evolution event with Jewel NFT
    // - transferDateUnix : Record transfer history for scoring HODL
    struct TokenData {
        uint64 spiritualityState;
        uint64 sadhanaTime;
        uint128 transferDateUnix;
    }

    mapping(uint256 => TokenData) public _tokenData;
    uint256 public currentSpiritualityState = 2;
    uint256 public currentSadhanaTime = 1;

    /**
     * Error functions
     */
    error AlreadyReservedIndex();
    error InvlidRoyaltyFee(uint256 fee);
    error IsNotOwner(uint256 tokenId);
    error NotSSSOwner();
    error NotTokenOwner();
    error ZeroAddress();


    /**
     * Constructor
     */
    constructor() ERC721Psi("SattvaSoulSupporters", "SSS") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN,    msg.sender);
        _grantRole(MINTER,   msg.sender);
        _grantRole(BURNER,   msg.sender);
        _grantRole(SADHANA,  msg.sender);
        _grantRole(METADATA, msg.sender);

        setBaseURI("https://gene.sattva-soul-supporters.com/json/");
        // setBaseURI("https://sattva-soul-supporters.mapplek.xyz/gene/json/");

        spiritualityPhase[0] = "animal";
        spiritualityPhase[1] = "evolving";  // before reveal state
        spiritualityPhase[2] = "saint";
        spiritualityPhase[3] = "human";

        _mint(msg.sender, 1);

        // Initialize CAL
        setCALLevel(1);
        _setCAL(0xdbaa28cBe70aF04EbFB166b1A3E8F8034e5B9FC7);  //Ethereum mainnet proxy
        // _setCAL(0xb506d7BbE23576b8AAf22477cd9A7FDF08002211);  //Goerli testnet proxy

        _addLocalContractAllowList(0x1E0049783F008A0085193E00003D00cd54003c71);  //OpenSea
        _addLocalContractAllowList(0x4feE7B061C97C9c496b01DbcE9CDb10c02f0a0Be);  //Rarible
    }


    /**
     * For external contract
     */
    function mint(address _to, uint256 _amount)
        external
        override
        onlyRole(MINTER)
    {
        _mint(_to, _amount);
    }

    function burn(uint256 _tokenId)
        external
        override
        onlyRole(BURNER)
    {
        _burn(_tokenId);
    }

    function sssTotalSupply()
        external
        view
        override
        returns (uint256)
    {
        return totalSupply();
    }

    function sadhana(uint256 _tokenId)
        external
        override
        onlyRole(SADHANA)
    {
        _tokenData[_tokenId].spiritualityState = uint64(currentSpiritualityState);
        _tokenData[_tokenId].sadhanaTime = uint64(currentSadhanaTime);
    }


    /**
     * Transfer date for SSS HODL Score
     */
    function sssTokenTransferDate(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        return _tokenData[_tokenId].transferDateUnix;
    }

    function sssSetTokenTransferDate(uint256[] memory tokenIds)
        external
    {
        if(balanceOf(msg.sender) <= 0) revert NotSSSOwner();

        for(uint256 idx=0; idx<tokenIds.length; idx++) {
            if(ownerOf(tokenIds[idx]) != msg.sender) revert NotTokenOwner();
            
            if(_tokenData[tokenIds[idx]].transferDateUnix <= 0) {
                 _tokenData[tokenIds[idx]].transferDateUnix = uint128(block.timestamp);
            }
        }
    }


    /**
     * Sadhana　(Evolutionary process)
     */
    function setCurrentSpiritualityState(uint256 _spiritualityState)
        external
        onlyRole(SADHANA)
    {
        currentSpiritualityState = _spiritualityState;
    }

    function setSadhanaTime(uint256 _sadhanaTime)
        external
        onlyRole(SADHANA)
    {
        currentSadhanaTime = _sadhanaTime;
    }

    function setSpirituality(uint256 _idx, string calldata _spirituality)
        external
        onlyRole(SADHANA)
    {
        if(_idx <= 3) revert AlreadyReservedIndex();
        
        spiritualityPhase[_idx] = _spirituality;
    }

    function getTokenSpiritualityState(uint256 _tokenId)
        external
        view
        returns (uint256, string memory)
    {
        return
            (
                _tokenData[_tokenId].spiritualityState,
                spiritualityPhase[_tokenData[_tokenId].spiritualityState]
            );
    }

    function getTokenSadhanaTime(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        return _tokenData[_tokenId].sadhanaTime;
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
        public
        onlyRole(ADMIN)
    {
        baseURI = _newBaseURI;

        if(totalSupply() != 0) refreshMetadata(1, totalSupply());
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyRole(ADMIN)
    {
        baseExtension = _newBaseExtension;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if(useInterfaceMetadata == true) {
            return interfaceOfTokenURI.tokenURI(_tokenId);
        } else {
            if(_tokenData[_tokenId].sadhanaTime >= currentSadhanaTime) {
                return string(abi.encodePacked(baseURI,
                    spiritualityPhase[1],
                    "/",
                    _tokenId.toString(),
                    baseExtension));
            } else {
                return string(abi.encodePacked(baseURI,
                    spiritualityPhase[_tokenData[_tokenId].spiritualityState],
                    "/",
                    _tokenId.toString(),
                    baseExtension));
            }
        }
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
     * ERC-4906
     */
    function refreshMetadata(uint256 _tokenId)
        public
        onlyRole(METADATA)
    {
        emit MetadataUpdate(_tokenId);
    }

    function refreshMetadata(uint256 _fromTokenId, uint256 _toTokenId)
        public
        onlyRole(METADATA)
    {
        emit BatchMetadataUpdate(_fromTokenId, _toTokenId);
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
        _tokenData[tokenId].transferDateUnix = uint128(block.timestamp);
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from)
    {
        _tokenData[tokenId].transferDateUnix = uint128(block.timestamp);
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        _tokenData[tokenId].transferDateUnix = uint128(block.timestamp);
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
            interfaceId == bytes4(0x49064906) ||
            interfaceId == type(IERC2981).interfaceId ||
            AccessControl.supportsInterface(interfaceId) ||
            ERC721RestrictApprove.supportsInterface(interfaceId);
    }
}