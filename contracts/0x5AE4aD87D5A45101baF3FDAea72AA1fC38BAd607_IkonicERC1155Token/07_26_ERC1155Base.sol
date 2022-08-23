pragma solidity 0.8.13;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./HasSecondarySale.sol";
import "./HasAffiliateFees.sol";
import "./HasTokenURI.sol";
import './ERC2981PerTokenRoyalties.sol';
import "../roles/OperatorRole.sol";

contract ERC1155Base is
    ERC1155,
    OperatorRole,
    HasSecondarySale,
    HasAffiliateFees,
    HasTokenURI,
    ERC2981PerTokenRoyalties
{
    using SafeMath for uint256;

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

    event Mint(uint256 tokenId, uint256 supply, address recipient, uint bps);

    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;

    constructor(
        string memory tokenURIPrefix
    ) HasTokenURI(tokenURIPrefix) ERC1155(tokenURIPrefix) {
        // register ERC2981 royalty interface 
        _registerInterface(_INTERFACE_ID_ROYALTIES_EIP2981);
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
     * @notice Internal function to mint ERC1155 token
     * @param _tokenId token ID
     * @param _supply token quantity to mint
     * @param _uri token URI
     * @param _royaltyRecipient royalty recipient address
     * @param _royaltyValue royalty fee value
     * @param _fees affiliate fee array
     */
    function _mint(
        uint256 _tokenId,
        uint256 _supply,
        string memory _uri,
        address _royaltyRecipient,
        uint256 _royaltyValue,
        AffiliateFee[] memory _fees
    ) internal {
        require(creators[_tokenId] == address(0x0), "ERC1155Base._mint: Token is already minted");
        require(_supply != 0, "ERC1155Base._mint: Supply should be positive");
        require(bytes(_uri).length > 0, "ERC1155Base._mint: uri should be set");
        require(_royaltyValue <= 10000, "ERC1155Base._mint: Royalty value should not exceed 10000");
        require(_royaltyRecipient != address(0x0), "ERC1155Base._mint: Royalty recipient should be present");
        require(_royaltyValue != 0, "ERC1155Base._mint: Royalty value should be positive");
        
        creators[_tokenId] = msg.sender;

        uint256 sumFeeBps = 0;
        unchecked {
            for (uint256 i = 0; i < _fees.length; i++) {
                sumFeeBps = sumFeeBps.add(_fees[i].value);
            }
        }
        require(
            sumFeeBps <= 10000,
            "ERC1155Base._mint: Total fee bps should not exceed 10000"
        );

        _mint(msg.sender, _tokenId, _supply, "");

        _setTokenURI(_tokenId, _uri);
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
                    "ERC1155Base._mint: Recipient should be present"
                );
                require(_fees[i].value != 0, "ERC1155Base._mint: Fee value should be positive");
                fees[_tokenId].push(_fees[i]);
                recipients[i] = _fees[i].recipient;
                bps[i] = _fees[i].value;
            }
        }
        if (_fees.length > 0) {
            emit AffiliateFees(_tokenId, recipients, bps);
        }
        
        emit Mint(_tokenId, _supply, _royaltyRecipient, _royaltyValue);
    }

    /**
     * @notice burn token 
     * @param owner owner of token
     * @param tokenId token ID
     * @param amount token quantity to burn
     */ 
    function burn(
        address owner,
        uint256 tokenId,
        uint256 amount
    ) external {
        require(
            owner == msg.sender || isApprovedForAll(owner, msg.sender),
            "ERC1155Base.burn: Need operator approval for 3rd party burns."
        );
        _burn(owner, tokenId, amount);
        _clearTokenURI(tokenId);
    }

    /**
     * @notice Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param _tokenId uint256 ID of the token to set its URI
     * @param _uri string URI to assign
     */
    function _setTokenURI(uint256 _tokenId, string memory _uri) override virtual internal {
        require(creators[_tokenId] != address(0x0), "ERC1155Base._setTokenURI: Token should exist");
        super._setTokenURI(_tokenId, _uri);
    }

    /**
     * @notice returns token URI
     * @param _tokenId token ID
     */
    function tokenURI(uint256 _tokenId) virtual external view returns (string memory) {
        return _tokenURI(_tokenId);
    }

    /// @notice returns base URI of token
    function baseURI() external view returns (string memory) {
        return tokenURIPrefix;
    }

    /**
     * @notice See {ERC1155-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC165Storage, ERC2981Base, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    /**
     * @notice update token URI
     * @param _tokenId token ID
     * @param _tokenURI token URI
     */
    function updateTokenURI(uint256 _tokenId, string memory _tokenURI) external {
        require(creators[_tokenId] == msg.sender, "ERC1155Base.updateTokenURI: caller should be minter");
        _setTokenURI(_tokenId, _tokenURI);
    }
}