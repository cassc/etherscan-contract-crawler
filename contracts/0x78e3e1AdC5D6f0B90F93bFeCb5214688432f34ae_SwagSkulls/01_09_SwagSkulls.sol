// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/*
kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxkkkkkkkkkkkkkkkkkkkkkk
kkkxxkkkkkkkkkkkxxxkkkxkkkkkkkkkkOOOOOOOkOOOkkkkkkkkxxkxxxkkxkkkkkkkkkkkkkkkxxkk
kkxkkxxkkkkkkkkxkkkkxxxkkkkOkkdlc:;,,,,,,,;:cloxkOkkkxxxxxkkkkkkkkkkkkkxxxkkkxkk
kkkkkkxxkkkkkkkkkkkkkkkkkxo:,..  ..'',,'''.    .';ldkkkkkkkkkkkkkkkkkkkkkxkxxkkk
kkkkkkkkkkkkkkkkkkkkkkxl;.  .;lddkXNWWWWNNx..co:'. .'cdkOkkkkxkkkkxxkkkkkkkkkkkk
kkkkkkkkkxkkkkkkkkkkxc.  'lxxxKNxkWMMMMMMK; 'oONN0d;. .;dkkkkkxxxxxxxkOkkkkkkkkk
kkkkkkxxxxxkkkkkkkkl.  ;xOd:,c0MMMMMMMMMMXkd,'kWMMMW0l. .;dkkkkxxxkxxkOkkkkkkkkk
kkkkkkxxkxxkkkxkkd,  ,k0l,;xXWMMMMMMMMMMMMWOdKMMMMMMMWKl. .ckOkkkkkkkkkkkkkkkkkk
kkkkkkkxkxxxkkkko. .oXk';kNMMMMMMMMMMMMMMMN0NMMMMMMMMMMWO,  :xkkkkkkxxkkkkkkkkkk
kkkkkkkkkkkkkkko. .xWWKONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:  :kOkkxkxxkkkkkkkkkk
kkkkkkkkkkkkkOd. .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;  ckkxxxkkxxkkkkkkkk
kkkxkkxxkkkkOk;  cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO. .dOkxxxkxxkkkkkkkk
kkxkkxxxkkxkOd. .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc  :kkkkkkkkkkkkkkkk
kkkkxxkkxxxkOl. ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx. ,kOkkkkkkkkkkxkkk
kkkkkkkkxkkkkc  cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXKK00XWk. 'xOkkkkkkkkkxxxkk
kkkkkkkkkkkkOl. :NMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kxooolcc:::xNx. 'xOkkkkkkxxxkkxkk
kkkkkkkkkkkkOo. '0MMMMMMMMMMMMWWNNNNNNNXXKOxoc'...,::::::l0No  ;kkkkkkkkkkkkkkkk
kkkkkkxkkkkkkk;  oWMMMWNXKOxxdodoooocoolcc:::,....;::::::lK0' .oOkkkkkkkkkkkkkkk
kkkkkkxxkkkxkOo. .kWXkdlc;....,:::::::lO0Odc:' ..':::::::l0o  ;kOkkxxkkkkkkkkkkk
kkkxkkkkxkkxkkkc. 'OXxc::' ..':::::::cOWWMNkl' ..':::::::dXd  'dOkkkkxkxxkxkkkkk
kkkkxkkkxkkkkkkkc. .xN0o:. ..':::::::oKX0kx0Kd;'.':::cldONMNl  ,xkxxkkkkkxkkkkkk
kkkkkkkkkkkkkkkkko. .c0Oc. ..,::::::l0Nl   .xNX0OkOO0KXWMMMMK, .oOkkkxxkkkkkkkkk
kkkkkkkkkkkkkkkkkkx;. 'kO:...,:::coxKW0'    .oNMMMMMMMMMMMMM0' .oOkkkkkkkkkkkkkk
kkkkkkkkkkxxkkkkxkOk:  lWXOxxxkO0KNWMMO.     ;KMMMMMMMMMMMW0;  :kkkkkkkkkkkkkkkk
kkkkkkkkkkxxxkxxxkkk:  oWMMMMMMMMMMMMMWOoc;:o0WMMMMMMMN0xo:. .cxkkkkkkxxxkxxxkkk
kkkkkkkkkkxxxxxkkkkOl. ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;     ,dkkkkkkkkxxxxxkkkkk
kkkkkkkkkkkkkxkkkkkkk:  ,xXMMMMMMMMMMMMMMMMMMMMMMMMMMx. ;c  cOkkkkkOkkkxxxkkkkkk
kkkkkxxkkkkkkkkkkkkkOkl.  .;cc:;:xNMMMMMMMMMMMMMWX0xc. .kO. ;kOkkkkkkkkkkkkkkkkk
kkxkkxxkkkxkOkkkkkkkkkkxo:,.  ..  c0XDGAPX0Oxdl:,.. .,lKWK, 'xOkkkkkxxxkkkkkkkkk
kkkxkxxkkkkkkkkxkkkxxkkkkkOx, .do. ........  ..';cokKWMMMWc .oOkkkkkxxkxxkkkkkkk
kkkkkkkkkkkOkkkxxkkkkxkkkkkOo. :X0ooloooddxkO0XNWMMMMMMMMWl  cOkkkkxxkkxkkkkkkkk
kkkkkkkkkkOkkkkkkkxxkkkkkkkkk: .dOdNVTQSWDHMMMMMMMMMMMMNk;. 'okkkkkkkkkkkOkkkkkk
kkkkkkkkkkkkkkkkkkxxkkkkkkkkOx' '0WOccoxkOKWMMMMMMMMWKd, .,okkkkkkkkkkkkkkkkkkkk
kkkkkkkkxxkkkkkkkkkkkkkkkkkkkOl. 'clcccc::dXMMMMMN0d:. .:dkkkkkkkkkkkkkxkkkxxkkk
kkOkxxkkkxxxkkkkkkkkkkkkkxxxkkkl;'.....,;:cooool:'. .,lxkkkkkxxkkkkkkkxxxkkkkkkk
kkkkxxxxxxkkxkkkkkkkkkkkxxxxxkkkOkkdoc:;,,'.....';coxkkkkkxxkxxxkkxkkkkxkkkkkkkk
kkkkkkxxxkkkkkkkkkkOkkkxxkkxxkkkkkkkkkOOOkkkkxkkkOOkkkkkkkxxxkxxxkkkkkkkkkkkkkkk
kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkkkkkkkkkkkkkklancexwasxherextookkkk
kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk
*/

/**
 * @title Swag Skulls
 * @author Swag Golf
 */
contract SwagSkulls is ERC721AQueryable, Ownable {

    using ECDSA for bytes32;

    uint public _maximumSupply = 8888;
    bool private _maximumSupplyLocked = false;
    uint256 private _mintingPrice;
    uint256 private _maxMintingBatchQuantity = 10;
    address private _mintingSigner;
    bool private _publicMintAllowed = false;
    mapping ( address => uint256 ) private privateMintAddressToQuantity;

    bool private _isRevealed = false;
    string public _revealUri;
    string public _prerevealUri;

    address public _withdrawalAddress;

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function startTokenId() external pure returns (uint256) {
        return _startTokenId();
    }

    function setMaximumSupply( 
        uint maximumSupply
    )
        external 
        onlyOwner 
    {
        require( !_maximumSupplyLocked, "Max supply is locked and cannot be changed" );
        _maximumSupply = maximumSupply;
    }

    function lockMaximumSupply(
        bool isLocked
    )
        external
        onlyOwner 
    {
        require( isLocked != _maximumSupplyLocked, "New value idential to old value" );
        require( !_maximumSupplyLocked, "Max supply is locked and cannot be changed" );

        _maximumSupplyLocked = isLocked;
    }

    function setMintingSigner(
        address mintingSigner 
    )
        external
        onlyOwner
    {
        _mintingSigner = mintingSigner;
    }

    function setPublicMintAllowed(
        bool publicMintAllowed
    )
        external
        onlyOwner 
    {
        _publicMintAllowed = publicMintAllowed;
    }

    function setMintingPrice(
        uint256 mintingPrice
    )
        external
        onlyOwner 
    {
        _mintingPrice = mintingPrice;
    }

    function setMaxMintingBatchQuantity(
        uint256 maxMintingBatchQuantity
    )
        external
        onlyOwner 
    {
        _maxMintingBatchQuantity = maxMintingBatchQuantity;
    }

        function setRevealUri(
        string memory revealUri
    )
        external 
        onlyOwner 
    {
        require( !_isRevealed, "Reveal has already been done" );
        _revealUri = revealUri;
    }

    function setIsRevealed(
        bool isRevealed
    )
        external 
        onlyOwner 
    {
        require( !_isRevealed, "Reveal has already been done" );
        _isRevealed = isRevealed;
    }

    constructor( 
        uint256 mintingPrice, 
        address mintingSigner,
        uint256 maxMintingBatchQuantity,
        string memory prerevealUri,
        address withdrawalAddress ) ERC721A( "Swag Skulls Collection", "SWAG" ) 
    {
        _mintingPrice = mintingPrice;
        _mintingSigner = mintingSigner;
        _maxMintingBatchQuantity = maxMintingBatchQuantity;
        _prerevealUri = prerevealUri;
        _withdrawalAddress = withdrawalAddress;
    }

    function hashMessage(
        address addressTo
    )
        public
        pure
        returns ( bytes32 ) 
    {
        return keccak256( abi.encodePacked( addressTo ) );
    }

    function mint(
        uint256 quantity, 
        bytes memory signedMessage) 
        external 
        payable
    {
        require( (totalSupply() + quantity) <= _maximumSupply, "Minting would exceed max supply" );
        require( quantity <= _maxMintingBatchQuantity, "Attempt to mint more than maximum allowed" );
        require( msg.value >= ( quantity * _mintingPrice ), "Invalid payment amount" );

        bytes32 recomputedHash = hashMessage( msg.sender );
        require( verifyMessageSigner( recomputedHash, signedMessage, _mintingSigner ), "Signature doesn't match");

        if( !_publicMintAllowed )
        {
            require( ( privateMintAddressToQuantity[ msg.sender ] + quantity ) <= _maxMintingBatchQuantity, "Mint request exceeds maximum during private minting period" );
            privateMintAddressToQuantity[ msg.sender ] += quantity;
        }
        
        _mint( msg.sender, quantity );
    } 

    function verifyMessageSigner(
        bytes32 hashedMessage, 
        bytes memory signedMessage,
        address expectedSigner) 
            private 
            pure 
            returns ( bool ) {
        
        return ECDSA.toEthSignedMessageHash( hashedMessage ).recover( signedMessage ) == expectedSigner;
    } 

    function ownerMint(
        address to,
        uint256 quantity )
        external
        onlyOwner 
    {
        require( (totalSupply() + quantity) <= _maximumSupply, "Minting would exceed max supply" );
        _mint( to, quantity );
    }

    function tokenURI(
        uint256 tokenId ) 
        public 
        view 
        override( ERC721A, IERC721A ) 
        returns ( string memory ) 
    {
        require( _exists( tokenId ), "URI query for nonexistent token" );

        if ( _isRevealed ) {
            return string( abi.encodePacked( _revealUri, _toString( tokenId ), ".json" ) );
        } else {
            return _prerevealUri;
        }
    }

    //reminder:  Never set to Lance's address!!
    function setWithdrawalAddress( address newAddress ) 
        external 
        onlyOwner 
    {
        _withdrawalAddress = newAddress;
    }

    function withdraw() 
        external 
        onlyOwner 
    {
        (bool success, ) = _withdrawalAddress.call{value: address(this).balance}("");
        require(success);
    }
}