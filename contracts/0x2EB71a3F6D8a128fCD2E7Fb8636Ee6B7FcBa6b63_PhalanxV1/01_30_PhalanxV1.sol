// contracts/PhalanxV1.sol
// SPDX-License-Identifier: MIT

/**
Phalanx NFT v1
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract PhalanxV1 is Initializable, ERC1155URIStorageUpgradeable, OwnableUpgradeable, IERC1155ReceiverUpgradeable, IERC721ReceiverUpgradeable  {
    
    event TokenMinted(address indexed _by, uint256 indexed _id);

    enum MintType { DAO, OWNER, CONTRIBUTOR, MEMBER }
    enum DAOType { GNOSIS_SAFE }

    struct ValidationSignature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct DAOInfo {
        address _address;
        DAOType _daoType;
    }

	address                     private  _adminSigner;
    
    mapping(uint256 => DAOInfo) private _daoInfo;
    
    function initialize(address adminSigner)  
        public 
        initializer
    {
        __ERC1155_init("");
        __ERC1155URIStorage_init();
        __Ownable_init();

        _adminSigner          = adminSigner;
    }

    function mint(
        MintType mintType,
        string memory tokenURI,
        uint256 baseId,
        uint256 price, 
        address erc20PaymentToken,
        ValidationSignature memory validationSignature
    ) 
        external 
        payable
        returns (uint256)
    {
        // Verify that request is valid
		bytes32 digest = keccak256(
            abi.encode(mintType, tokenURI, baseId,  msg.sender, price, erc20PaymentToken)
        );
		require(_isValidSignature(digest, validationSignature), 'Invalid validation signature');

        if (erc20PaymentToken != address(0)) {
            // Transfer payment ERC20 tokens
            ERC20 erc20Token = ERC20(erc20PaymentToken);
            erc20Token.transferFrom(msg.sender, address(this), price);
        } else {
            // Validate ETH payment is correct
            require(msg.value == price, "Insufficient ETH supplied for transaction");
        }

        uint256 tokenId = _tokenIdFromType(baseId, mintType);
        
        require(balanceOf(msg.sender, tokenId) == 0, "Cannot mint more than one Phalanx token");
        
        if (mintType == MintType.DAO) {
            require(_daoInfo[baseId]._address == address(0), "ID already claimed.");

            _daoInfo[baseId] = DAOInfo(msg.sender, DAOType.GNOSIS_SAFE);
            _mint(msg.sender, tokenId, 1, "");
            _setURI(tokenId, tokenURI);
        } else {
            require(_daoInfo[baseId]._address != address(0), "DAO not listed yet.");

            _mint(msg.sender, tokenId, 1, "");
        } 

        // Emit for backend to pickup
        emit TokenMinted(msg.sender, tokenId);

        return tokenId;
    }

    function setAdminSigner(
        address adminSigner
    )
        external 
        onlyOwner 
    {
        _adminSigner = adminSigner;
    }

    function setURI(
        uint256 tokenId,
        string memory tokenURI
    ) 
        external 
        onlyOwner 
    {
        _setURI(tokenId, tokenURI);
    }    
    
    function name() external pure returns (string memory _name) {
        return "Phalanx";
    }

    function symbol() external pure returns (string memory _symbol) {
        return "PHNX";
    }

    // Internal methods

    function _isValidSignature(bytes32 digest, ValidationSignature memory validationSignature) 
        internal 
        view 
        returns (bool) 
    {
        address signer = ecrecover(digest, validationSignature.v, validationSignature.r, validationSignature.s);
        require(signer != address(0), 'ECDSA: invalid signature');
        return signer == _adminSigner;
    }

    function _tokenIdFromType(uint256 id, MintType mintType) 
        internal
        pure 
        returns (uint256) 
    {
        return (id << 8) | uint(mintType);
    }

    function _beforeTokenTransfer(
        address operator, 
        address from, 
        address to, 
        uint256[] memory ids, 
        uint256[] memory amounts, 
        bytes memory data
    ) internal override(ERC1155Upgradeable) {
        if (from == address(0)) {
            return super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        }

        return revert("Phalanx token cannot be transferred!");
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override(IERC721ReceiverUpgradeable) returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator, 
        address from, 
        uint256 id, 
        uint256 value, 
        bytes calldata data
    ) external override(IERC1155ReceiverUpgradeable) returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator, 
        address from, 
        uint256[] calldata ids, 
        uint256[] calldata values, 
        bytes calldata data
    ) external override(IERC1155ReceiverUpgradeable) returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }   
    
    function uri(
        uint256 tokenId
    ) public view virtual override(ERC1155URIStorageUpgradeable) returns (string memory) {
        return super.uri(_tokenIdFromType(tokenId >> 8, MintType.DAO));
    }
    
    function withdrawETH(
        address _to
    ) 
        external
        onlyOwner() 
    {
        (bool success, ) = _to.call{value: address(this).balance}('');
        require(
              success
            , "_transferEth: Eth transfer failed"
        );
    }

    function withdrawERC20(
          address _tokenAddress
        , address _to
    ) 
        external
        onlyOwner()
    { 
        IERC20(_tokenAddress).transfer(
              _to
            , IERC20(_tokenAddress).balanceOf(address(this))
        );
    }

    function withdrawERC721(
          address _tokenAddress
        , uint256[] calldata _tokenIds
        , address _to
    ) 
        external
        onlyOwner() 
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            IERC721(_tokenAddress).transferFrom(
                  address(this)
                , _to
                , _tokenIds[i]
            );
        }
    }

    function withdrawERC1155(
          address _tokenAddress
        , uint256[] calldata _tokenIds
        , uint256[] calldata _amounts
        , address _to
    ) 
        external 
        onlyOwner()
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            IERC1155(_tokenAddress).safeTransferFrom(
                  address(this)
                , _to
                , _tokenIds[i]
                , _amounts[i]
                , ""
            );
        }
    }

}