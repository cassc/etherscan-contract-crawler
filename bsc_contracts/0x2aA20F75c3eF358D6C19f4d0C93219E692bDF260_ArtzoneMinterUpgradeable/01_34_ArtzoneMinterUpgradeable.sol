// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./Helpers/BoringOwnableUpgradeable.sol";
import "./ArtzoneMinter.sol";

// Proxy Configurations:
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ArtzoneMinterUpgradeable is ERC1155Upgradeable, AccessControlUpgradeable, BoringOwnableUpgradeable,  ArtzoneMinter, UUPSUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public constant name = "Artzone Collections";
    string public constant symbol = "ARTZONE COLLECTIONS";


  /*///////////////////////////////////////////////////////////////
                            Modifiers
    //////////////////////////////////////////////////////////////*/

    /// @dev Checks for admin role.
    modifier isMinter(){
        require(hasRole(MINTER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Unauthorised role.");
        _;
    }

      /*///////////////////////////////////////////////////////////////
                            Initializer
    //////////////////////////////////////////////////////////////*/

      /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

      /**
     * Initializer
     */
    function initialize(address _minter) public initializer {
        __ERC1155_init("");
        __BoringOwnable_init();
        require(_minter != address(0), "null address.");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, _minter);
    
    }

      /*///////////////////////////////////////////////////////////////
                    Artzone Minter External Functions
    //////////////////////////////////////////////////////////////*/

     /**
     * @notice Token initialisation before minting is allowed. Only permissable to whitelisted admin wallets.
     */
    function initialiseToken(
    string memory _tokenURI, 
    uint256 _maxQuantity,
    address _royaltyRecipient,
    uint256 _royaltyValue,
    bool _accessToUpdateToken
    ) external isMinter {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();

        setURI(tokenId, _tokenURI);
        _tokenMaxSupply[tokenId] = _maxQuantity;
        _tokenUpdateAccess[tokenId] = _accessToUpdateToken;

        // Set Royalty Info if specified:
        if (_royaltyValue != 0) {
            setTokenRoyalty(tokenId, _royaltyRecipient, _royaltyValue);
        }

        emit TokenInitialisation(
            tokenId,
            _maxQuantity,
            _royaltyValue,
            _royaltyRecipient,
            _tokenURI
        );
    }

    /**
     * @notice Minting of a token to a receipient, permission only exclusive to whitelisted admin wallet.
     */
    function mintToken(
        uint256 _tokenId,
        uint256 _quantity,
        address _receiver
    ) external isMinter validateMint(_tokenId, _quantity) {

        // Update quantity count for tokenId created:
        _tokenSupply[_tokenId] += _quantity;
        _mint(_receiver, _tokenId, _quantity);
    }

    /**
     * @notice Batch minting of multiple tokenIds with varying respective quantities to a receipient, permission only exclusive to whitelisted admin wallet.
     */
    function batchMintToken(uint256[] memory _tokens, uint256[] memory _quantities, address _receiver) external isMinter validateBatchMint(_tokens, _quantities){
        _mintBatch(_receiver, _tokens, _quantities, "");
    }

     /**
     * @notice One way lock of locking up tokenURI update access, only permissable by admins.
     */
    function lockTokenUpdateAccess(uint256 _tokenId) external isMinter validateInitialisedToken(_tokenId) {
        _tokenUpdateAccess[_tokenId] = false;

        emit TokenAccessLock(_tokenId);
    }


    /**
     * @notice For admins to override existing tokenURI should it be allowed to.
     */
    function overrideExistingURI(
        uint256 _tokenId,
        string memory _newUri
    ) external isMinter validateInitialisedToken(_tokenId) {
        require(_tokenUpdateAccess[_tokenId], "Permissions to update denied");
        _tokenIdUri[_tokenId] = _newUri;
        emit URI(_newUri, _tokenId);
    }

     function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function burn(uint256 _id, uint256 _amount) external {
        uint256 balanceOfOwner = balanceOf(msg.sender, _id);

        require(balanceOfOwner != 0, "Invalid ownership balance");
        require(balanceOfOwner <= _amount, "invalid amount specified");
        _burn(msg.sender, _id, _amount);
    }

      /*///////////////////////////////////////////////////////////////
                        Internal/Private Functions
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) private {
        _mint(_to, _id, _amount, "");
    }

   

    function setURI(uint256 _id, string memory _uri) private {
        _tokenIdUri[_id] = _uri;
        emit URI(_uri, _id);
    }


    /*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return _tokenIdUri[_tokenId];
    }

    /**
     * @notice To query creator royalties info based on ERC2981 Implementation.
     */
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        public
        view
        override
        returns (address, uint256)
    {
        return super.royaltyInfo(_tokenId, _value);
    }

      /*///////////////////////////////////////////////////////////////
                                Proxy Upgrade Functions
    //////////////////////////////////////////////////////////////*/

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable,AccessControlUpgradeable, ArtzoneMinter)
        returns (bool)
    {
       
        return ERC1155Upgradeable.supportsInterface(interfaceId) || ArtzoneMinter.supportsInterface(interfaceId) || AccessControlUpgradeable.supportsInterface(interfaceId);
    }
}