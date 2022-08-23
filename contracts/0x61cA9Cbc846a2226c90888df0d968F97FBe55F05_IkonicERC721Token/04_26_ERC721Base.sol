// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "./HasSecondarySale.sol";
import "./HasAffiliateFees.sol";
import "./ERC2981PerTokenRoyalties.sol";
import "../roles/OperatorRole.sol";

/**
 * @title Full ERC721 Token with support for baseURI
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Base is
    ERC721,
    OperatorRole,
    HasSecondarySale,
    HasAffiliateFees,
    ERC721URIStorage,
    ERC2981PerTokenRoyalties
{
    // Token name
    // Now in openzeppelin ERC721
    // string public override name;

    // Token symbol
    // Now in openzeppelin ERC721
    // string public override symbol;

    using SafeMath for uint256;

    string public tokenURIPrefix;

    struct AffiliateFee {
        address recipient;
        uint256 value;
    }

    // id => fees
    mapping(uint256 => AffiliateFee[]) public fees;

    // tokenId => creator
    mapping (uint256 => address) public creators;

    AffiliateFee internal affFee;

    // tokenId => state
    mapping(uint256 => bool) private isAffiliateSale;

    /// @dev sale is primary or secondary
    // tokenId => state
    mapping(uint256 => bool) private isSecondarySale;

    event Mint(uint256 tokenId, address recipient, uint bps);

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;

    /**
     * @dev Constructor function
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory baseURI_
    ) ERC721(_name, _symbol) {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        // register ERC2981 royalty interface 
        _registerInterface(_INTERFACE_ID_ROYALTIES_EIP2981);
        _setBaseURI(baseURI_);
    }

    function getFeeRecipients(uint256 id)
        public
        view
        override
        returns (address[] memory)
    {
        AffiliateFee[] memory _fees = fees[id];
        address[] memory result = new address[](_fees.length);
        unchecked {
            for (uint256 i = 0; i < _fees.length; i++) {
                result[i] = _fees[i].recipient;
            }
        }
        return result;
    }

    function getFeeBps(uint256 id) public view override returns (uint256[] memory) {
        AffiliateFee[] memory _fees = fees[id];
        uint256[] memory result = new uint256[](_fees.length);
        unchecked {
            for (uint256 i = 0; i < _fees.length; i++) {
                result[i] = _fees[i].value;
            }
        }
        return result;
    }

    function getAffiliateFeeRecipient() 
        external 
        view 
        override 
        returns(address) 
    {
        return affFee.recipient;
    }

    function setAffiliateFeeRecipient(address recipient) 
        external
        onlyOperator
    {
        affFee.recipient = recipient;
    } 

    function getAffiliateFee() 
        external 
        view 
        override 
        returns (uint256) 
    {
        return affFee.value;
    }

    function setAffiliateFee(uint256 fee)
        external
        onlyOperator
    {
        affFee.value = fee;
    }

    function checkAffiliateSale(uint256 _tokenId)
        external
        view
        override
        returns (bool)
    {
        return isAffiliateSale[_tokenId];
    }

    function setAffiliateSale(uint256 _tokenId)
        external
        onlyOperator
        override
    {
        isAffiliateSale[_tokenId] = true;
    }

    /// @notice override checkSecondarySale function of HasSecondarySale
    function checkSecondarySale(uint256 _tokenId)
        external
        view
        override
        returns(bool)
    {
        return isSecondarySale[_tokenId];
    }

    /// @notice override setSecondarySale function of HasSecondarySale
    function setSecondarySale(uint256 _tokenId)
        external
        onlyOperator
        override
    {
        isSecondarySale[_tokenId] = true;
    }

    /**
     * @notice Internal funcntion to mint ERC721 token
     * @param _tokenId Id of token
     * @param _royaltyRecipient royalty recipient address
     * @param _royaltyValue royalty fee value
     * @param _fees affiliate fee array
     */
    function _mint(
        uint256 _tokenId,
        string memory _tokenURI,
        address _royaltyRecipient,
        uint256 _royaltyValue,
        AffiliateFee[] memory _fees
    ) internal {
        require(creators[_tokenId] == address(0x0), "ERC721Base._mint: Token is already minted");
        require(_royaltyValue <= 10000, "ERC721Base._mint: Royalty value should not exceed 10000");
        require(_royaltyRecipient != address(0x0), "ERC721Base._mint: Royalty recipient should be present");
        require(_royaltyValue != 0, "ERC721Base._mint: Royalty value should be positive");
        
        creators[_tokenId] = msg.sender;

        uint256 sumFeeBps = 0;
        unchecked {
            for (uint256 i = 0; i < _fees.length; i++) {
                sumFeeBps = sumFeeBps.add(_fees[i].value);
            }
        }
        require(
            sumFeeBps <= 10000,
            "ERC721Base._mint: Total fee bps should not exceed 10000"
        );
        _mint(msg.sender, _tokenId);
        
        _setTokenURI(_tokenId, _tokenURI);
        _setTokenRoyalty(
            _tokenId,
            _royaltyRecipient,
            _royaltyValue
        );

        address[] memory recipients = new address[](_fees.length);
        uint256[] memory bps = new uint256[](_fees.length);
        unchecked {
            for (uint256 i = 0; i < _fees.length; i++) {
                require(
                    _fees[i].recipient != address(0x0),
                    "ERC721Base._mint: Recipient should be present"
                );
                require(_fees[i].value != 0, "ERC721Base._mint: Fee value should be positive");
                fees[_tokenId].push(_fees[i]);
                recipients[i] = _fees[i].recipient;
                bps[i] = _fees[i].value;
            }
        }
        if (_fees.length > 0) {
            emit AffiliateFees(_tokenId, recipients, bps);
        }

        emit Mint(_tokenId, _royaltyRecipient, _royaltyValue);
    }

    /**
     * @notice Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        tokenURIPrefix = baseURI_;
    }

    /**
     * @notice See {ERC721-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721, ERC165Storage, ERC2981Base, AccessControl)
        returns (bool) 
    {
        return super.supportsInterface(_interfaceId);
    }

    /// @notice Internal function to return baseURI
    function _baseURI()
        internal 
        view
        virtual
        override
        returns (string memory) 
    {
        return tokenURIPrefix;
    }

    /// @notice Internal function to 
    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        ERC721URIStorage._burn(tokenId);
    }

    /// @notice See {ERC721URIStorage-tokenURI}
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    /**
     * @notice update token URI
     * @param _tokenId token Id
     * @param _tokenURI token URI
     */
    function updateTokenURI(uint256 _tokenId, string memory _tokenURI) external {
        require(creators[_tokenId] == msg.sender, "ERC721Base.updateTokenURI: caller should be minter");
        _setTokenURI(_tokenId, _tokenURI);
    }
}