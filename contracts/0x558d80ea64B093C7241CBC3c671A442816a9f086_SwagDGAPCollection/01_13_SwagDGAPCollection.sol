// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

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
 * @title Swag DGAP Collection
 * @author Swag Golf
 */
contract SwagDGAPCollection is ERC721Enumerable, Ownable {

    // The tokenId of the next token to be minted.
    // starting at 1 saves on gas
    uint256 internal _currentIndex = 1;  

    mapping ( uint256 => string ) private tokenIdToUri;

    constructor() ERC721( "Swag DGAP Collection", "DGAP" ) {}

    function tokenURI( uint256 tokenId ) 
        public 
        view 
        virtual 
        override 
        returns ( string memory ) 
    {
        require( _exists( tokenId ), "URI query for nonexistent token" );
        return string( abi.encodePacked( tokenIdToUri[ tokenId ] ) );
    }


    /**
     * @notice Allow for minting of tokens by the contract owner.  Each new mint
     *          has a unique Uri associated with it since this is an ad-hoc collection
     */
    function mintNewToken(
        string memory newTokenUri,
        address to
    ) 
        external 
        onlyOwner  
    {
        tokenIdToUri[ _currentIndex ] = newTokenUri; 
        _safeMint( to, _currentIndex );
        unchecked {
            _currentIndex++;
        }
    }

}