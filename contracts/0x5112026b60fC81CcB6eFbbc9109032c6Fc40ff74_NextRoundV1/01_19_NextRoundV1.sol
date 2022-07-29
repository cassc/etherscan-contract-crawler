// contracts/NextRoundV1.sol
// SPDX-License-Identifier: MIT

/**
NextRound SAF3 NFT v1

MMMMMMMMMMMMMMMMMMMMMMMMNKOdl:,'..            ..',:ldOKNMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMN0dc,.                            .,cd0NMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMWXxc'.                                    .'cxXWMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMXk:.            ..,:cloooddooolc:,..            .:kXMMMMMMMMMMMMMM
MMMMMMMMMMMWKo'          .;ldOKNWWMMMMMMMMMMMMWWNKOdl;.          'oKWMMMMMMMMMMM
MMMMMMMMMW0l.        .,lkXWMMMMMMMMMMMMMMMMMMMMMMMMMMWXkl,.        .l0WMMMMMMMMM
MMMMMMMMKl.        ,o0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0o,        .lKMMMMMMMM
MMMMMMNx'       .:kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:.       'xNMMMMMM
MMMMMXc.      .:OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:.      .cXMMMMM
MMMW0;       ,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk,       ;0WMMM
MMMO'      .lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl.      'OMMM
MM0'      .xNMMMMMMMMMXdcccccccccccccccccllccccccccccldKWMMMMMMMMMMNx.      ,0MM
MK;      .xWMMMMMMMMMMO.                               .dNMMMMMMMMMMWx.      ;KM
Nl      .dWMMMMMMMMMMMO.                   .:c.         .OMMMMMMMMMMMWd.      lN
k.      lNMMMMMMMMMMMMk.               ..,okd,          .OMMMMMMMMMMMMNl      .k
c      ,0MMMMMMMMMMMMMKl,,,,,,,,,,,,,;lOKKx,            .OMMMMMMMMMMMMM0,      c
.      oWMMMMMMMMMMMMMMWWWWWWWWWWWWWWWXxc,              .OMMMMMMMMMMMMMWo      .
      .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMXx,                 .OMMMMMMMMMMMMMMO.      
      ,KMMMMMMMMMMMMMMMMMMMMMMMMMMXx,                   .OMMMMMMMMMMMMMMK,      
      ;KMMMMMMMMMMMMMMMMMMMMMMMMXx,           ,o;       .OMMMMMMMMMMMMMMK;      
      ,KMMMMMMMMMMMMMMMMMMMMMMXx,           'xXNc       .OMMMMMMMMMMMMMMK,      
      '0MMMMMMMMMMMMMMMMMMMMXx,           ,xXMMNc       .OMMMMMMMMMMMMMM0'      
.     .xMMMMMMMMMMMMMMMMMMXx,          ,cxXMMMMNc       .OMMMMMMMMMMMMMMx.     .
,      :XMMMMMMMMMMMMMMMXx,          ,xXMMMMMMMNc       .OMMMMMMMMMMMMMX:      ,
d.     .xWMMMMMMMMMMMMNx,          ,xXMMMMMMMMMNc       .OMMMMMMMMMMMMWx.     .d
K;      ,0MMMMMMMMMMMK:          'xXMMMMMMMMMMMNc       .OMMMMMMMMMMMM0,      ;K
Wk.      :KMMMMMMMMMMKc.       ,xXMMMMMMMMMMMMMNc       .OMMMMMMMMMMMK:      .kW
MWo.      :KMMMMMMMMMMWOc.   'xXMMMMMMMMMMMMMMMWd.......;0MMMMMMMMMMK:      .oWM
MMNl       ;0WMMMMMMMMMMWKxoxXMMMMMMMMMMMMMMMMMMWK0KKKKKXWMMMMMMMMW0;       lNMM
MMMNo.      .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.      .oNMMM
MMMMNx.       ;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;       .xNMMMM
MMMMMWO;       .:OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:.       ;OWMMMMM
MMMMMMMXd.       .;xXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXx;.       .dXMMMMMMM
MMMMMMMMWKl.        .cxXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc.        .lKWMMMMMMMM
MMMMMMMMMMW0l.         .;okKNWMMMMMMMMMMMMMMMMMMMMWNKko;.         .l0WMMMMMMMMMM
MMMMMMMMMMMMWKd,.          .':ldxO0KXXNNNNXXK0Oxdl:'.          .;dKWMMMMMMMMMMMM
MMMMMMMMMMMMMMMN0o,.              ............              .,oONMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMN0d:'.                                .':d0NMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMWN0xl:'..                    ..':lx0NWMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMWX0xl;'..          ..';lx0XWMMMMMMMMMMMMMMMMMMMMMMMMMM
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract NextRoundV1 is Initializable, ERC721URIStorageUpgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable  {
    
    event TokenMinted(address indexed _by, uint256 indexed _id);

    enum TokenTransferability { OPEN, TIME_LOCKED, OPERATOR, TIME_LOCKED_OPERATOR, CLOSED }

    struct ValidationSignature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    TokenTransferability        private  _tokenTransferability;
	address                     private  _adminSigner;
    mapping(uint256 => uint256) private  _tokenMintedAtTimestamps;
    mapping(uint256 => uint256) private  _lastTokenTransferAtTimestamps;
    
    function initialize(address adminSigner)  
        public 
        initializer
    {
        __ERC721_init("NextRound", "NXRD");
        __ERC721URIStorage_init();
        __ERC721Enumerable_init();
        __Ownable_init();

        _tokenTransferability = TokenTransferability.CLOSED;
        _adminSigner          = adminSigner;
    }

    function mintNFT(
        string memory _tokenURI,
        uint256 tokenId,
        address recipient,
        uint256 price, 
        address erc20PaymentToken,
        ValidationSignature memory validationSignature
    ) 
        external 
        returns (uint256)
    {
        // Verify that request is valid
		bytes32 digest = keccak256(
            abi.encode(_tokenURI, tokenId,  msg.sender, recipient, price, erc20PaymentToken)
        );
		require(_isValidSignature(digest, validationSignature), 'Invalid validation signature');

        // Transfer payment ERC20 tokens
        ERC20 erc20Token = ERC20(erc20PaymentToken);
        erc20Token.transferFrom(msg.sender, recipient, price);

        // Mint NFT, set tokenURI, set timestamps
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        _tokenMintedAtTimestamps[tokenId] = block.timestamp;
        _lastTokenTransferAtTimestamps[tokenId] = block.timestamp;

        // Emit for backend to pickup
        emit TokenMinted(msg.sender, tokenId);

        return tokenId;
    }

    function setTokenTransferability(
        TokenTransferability tokenTransferability
    ) 
        external 
        onlyOwner 
    {
        _tokenTransferability = tokenTransferability;
    }

    function setAdminSigner(
        address adminSigner
    )
        external 
        onlyOwner 
    {
        _adminSigner = adminSigner;
    }

    function setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    ) 
        external 
        onlyOwner 
    {
        _setTokenURI(tokenId, _tokenURI);
    }

    // Public & External View Methods

    function getTokenTransferability() 
        external 
        view 
        returns (TokenTransferability) 
    {
        return _tokenTransferability;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function tokenMintedAtTimestamp(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return _tokenMintedAtTimestamps[tokenId];
    }

    function lastTokenTransferAtTimestamps(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return _lastTokenTransferAtTimestamps[tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        if (from == address(0) || _tokenTransferability == TokenTransferability.OPEN) { 
            return super._beforeTokenTransfer(from, to, tokenId); 
        }
        
        return revert("Token transfer is CLOSED!");
    }

    function _burn(uint256 tokenId) 
        internal 
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable) 
    {
        super._burn(tokenId);
    }

}