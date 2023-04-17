// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./ICNPMusic.sol";
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

contract CNPMusic is
    ICNPMusic,
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
    using Strings for uint128;


    /**
     * Variables
     */
    // roles
    bytes32 public constant ADMIN    = keccak256("ADMIN");
    bytes32 public constant MINTER   = keccak256("MINTER");
    bytes32 public constant BURNER   = keccak256("BURNER");
    bytes32 public constant CHANGER  = keccak256("CHANGER");
    bytes32 public constant METADATA = keccak256("METADATA");

    ITokenURI public interfaceOfTokenURI;
    bool public useInterfaceMetadata = false;

    // Royalty
    address public royaltyAddress = 0xda8644440606C01BD4406cAE0A133bbd3DA02184;
    // address public royaltyAddress = 0x8f754F98604971CC5874aB733f2434546b4E054E;
    uint96 public royaltyFee = 1000;

    // Uri
    string public baseURI;
    string public baseExtension = ".json";

    // struct for tokens
    // - recordState   :
    //              0-> 'open',
    //              1-> 'close' 
    // - sideChangeTime: Number of times sideChange event with NFT
    struct TokenData {
        uint128 recordState;
        uint128 sideChangeTime;
    }

    /**
     * Record state
     */
    bool public fullOpenRecords = true;
    mapping(uint256 => string) public recordState;

    mapping(uint256 => TokenData) public _tokenData;
    uint256 public sideChangeTime = 2;

    /**
     * Error functions
     */
    error InvlidRoyaltyFee(uint256 fee);
    error IsNotOwner(uint256 tokenId);
    error NotCNPMOwner();
    error NotTokenOwner();
    error ZeroAddress();


    /**
     * Constructor
     */
    constructor() ERC721Psi("CNPMusic", "CNPM") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN,    msg.sender);
        _grantRole(MINTER,   msg.sender);
        _grantRole(BURNER,   msg.sender);
        _grantRole(CHANGER,  msg.sender);
        _grantRole(METADATA, msg.sender);

        setBaseURI("https://gene.cnp-music.jp/json/");

        recordState[0] = "open";
        recordState[1] = "close";

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

    function cnpmTotalSupply()
        external
        view
        override
        returns (uint256)
    {
        return totalSupply();
    }

    function sideChange(uint256 _tokenId)
        external
        override
        onlyRole(CHANGER)
    {
        _tokenData[_tokenId].sideChangeTime = uint128(sideChangeTime);
    }


    /**
     * SideChange　(changing side of records)
     */
    function setSideChangeTime(uint256 _sideChangeTime)
        external
        onlyRole(CHANGER)
    {
        sideChangeTime = _sideChangeTime;
    }


    /**
     * RecordState (Open or Close)
     */
    function setFullOpenRecords(bool _recordState)
        external
        onlyRole(ADMIN)
    {
        fullOpenRecords = _recordState;
    }

    function setRecordStateTokens(uint256[] memory tokenIds, uint256 _recordState)
        external
    {
        if(balanceOf(msg.sender) <= 0) revert NotCNPMOwner();

        for(uint256 idx=0; idx<tokenIds.length; idx++) {
            if(ownerOf(tokenIds[idx]) != msg.sender) revert NotTokenOwner();
        }

        for(uint256 idx=0; idx<tokenIds.length; idx++) {
            if(_tokenData[tokenIds[idx]].recordState != _recordState) {
                _tokenData[tokenIds[idx]].recordState = uint128(_recordState);
            }
        }
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
            if(fullOpenRecords == true) {
                if(_tokenData[_tokenId].sideChangeTime >= sideChangeTime){
                    return string(abi.encodePacked(baseURI,
                        "1/",
                        _tokenId.toString(),
                        baseExtension));
                } else {
                    return string(abi.encodePacked(baseURI,
                        _tokenData[_tokenId].sideChangeTime.toString(),
                        "/",
                        recordState[0],
                        "/",
                        _tokenId.toString(),
                        baseExtension));
                }
            } else {
                if(_tokenData[_tokenId].sideChangeTime >= sideChangeTime){
                    return string(abi.encodePacked(baseURI,
                        "1/",
                        _tokenId.toString(),
                        baseExtension));
                } else {
                    return string(abi.encodePacked(baseURI,
                        _tokenData[_tokenId].sideChangeTime.toString(),
                        "/",
                        recordState[_tokenData[_tokenId].recordState],
                        "/",
                        _tokenId.toString(),
                        baseExtension));
                }
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
        if(_tokenData[tokenId].recordState == 1) _tokenData[tokenId].recordState = 0;
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from)
    {
        if(_tokenData[tokenId].recordState == 1) _tokenData[tokenId].recordState = 0;
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        if(_tokenData[tokenId].recordState == 1) _tokenData[tokenId].recordState = 0;
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