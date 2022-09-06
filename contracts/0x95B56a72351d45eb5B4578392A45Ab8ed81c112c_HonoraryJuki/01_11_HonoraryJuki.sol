/**
SPDX-License-Identifier: MIT

YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
YYYYYYYYYYYYYYYYYYYYYPPPP5555PP5YYY5YYYYYYYYYYYYYY
YYYYYYYYYYYYYYYY55PPPGB&&&##BB###BPBB5YYYYYYYYYYYY
YYYYYYYYYYYYY5PGB#&&&&&&&&&&&&&&&&&#&BPPPGPYYYYYYY
YYYYYYYYYYYYY5PGB#&&&&&&&&&&&&&&&&&&&&#&&BPYYYYYYY
YYYYYYYYYYYPGBB&&&&&&&&&&##&&&&&&&#&&&&&&##G5YYYYY
YYYYYYYYYYY55GB#&&&#BBBP5PBB5JYY5YJP#&&&#55P5YYYYY
YYYYYYYYYYYYPPGBBJ~7YJ^~7J?:   .77?7&&&&GYYYYYYYYY
YYYYYYYYYYYYY5557~ .^?!.:?. :^^~J7Y5&GPB5YYYYYYYYY
YYYYYYYYYYYYYYY5::..^7J^:!!7!^^~7J?5J?7~PYYYYYYYYY
YYYYYYYYYYYYYYY5J7~!?Y77^.^!~~777!~7777J5YYYYYYYYY
YYYYYYYYYYYYYYPP5?^^^~~~:^^~~7?~~~!P#P55YYYYYYYYYY
YYYYYYYYYYYYYY555J!7J7!7J!!J!~^~!J5P55YYYYYYYYYYYY
YYYYYYYYYYYYYYYYY5YY!~~^^~~^~!?5PP555YYYYYYYYYYYYY
YYYYYYYYYYYYYYYYY55GGPPYJ77!~!5#GGGBBGP5YYYYYYYYYY
YYYYYYYYYYYYYYYY5BPGGPG7!~^~~JPGGGGGGGGGGP5YYYYYYY
YYYYYYYYYYYYYYYYGPPPPPPJ~~JPPGGGPPPGGGGGBBGYYYYYYY
YYYYYYYYYYYYYYYP555P5PPP!YGGG55555555PPPGBPYYYYYYY
YYYYYYYYYYYYYY55YPY555BG!JP5GPY5555555PPPGBYYYYYYY
YYYYYYYYYYYYYYPYPGY5YPGP!?PYPB5PPPGPY55PPPBPYYYYYY
YYYYYYYYYYYYY5PYPGJ55BPP!?GPGBGPPPPBYY5PPPBBYYYYYY
YYYYYYYYYYYYY5PYPGJ55PPP??GPPPPPPPPPGJ55PPGB5YYYYY
YYYYYYYYYYYYYP55PB5PPPGP??PGPPPPPPPPGYY5PPGBPYYYYY

██╗░░██╗░█████╗░███╗░░██╗░█████╗░██████╗░░█████╗░██████╗░██╗░░░██╗░░░░░██╗██╗░░░██╗██╗░░██╗██╗
██║░░██║██╔══██╗████╗░██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗╚██╗░██╔╝░░░░░██║██║░░░██║██║░██╔╝██║
███████║██║░░██║██╔██╗██║██║░░██║██████╔╝███████║██████╔╝░╚████╔╝░░░░░░██║██║░░░██║█████═╝░██║
██╔══██║██║░░██║██║╚████║██║░░██║██╔══██╗██╔══██║██╔══██╗░░╚██╔╝░░██╗░░██║██║░░░██║██╔═██╗░██║
██║░░██║╚█████╔╝██║░╚███║╚█████╔╝██║░░██║██║░░██║██║░░██║░░░██║░░░╚█████╔╝╚██████╔╝██║░╚██╗██║
╚═╝░░╚═╝░╚════╝░╚═╝░░╚══╝░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░░╚════╝░░╚═════╝░╚═╝░░╚═╝╚═╝                                                        
*/

pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 

/// @title The Watchers of Jukiverse
/// @author iqbalsyamil.eth (github.com/2pai)
/// @notice Every universe has their watcher. They are the eyes that observe the movements of the jukis from the mysterious side. They are observers whose form is enshrined in a personalized form in shrines of reverence.
contract HonoraryJuki is ERC721A, ERC2981, Ownable {
    using Strings for uint256;
    
    string public baseURI;

    constructor(
            string memory _previewURI
        )
        ERC721A("Honorary Juki", "HJUKI")
    {
        _mint(msg.sender, 1);
        _setDefaultRoyalty(msg.sender, 500);
        baseURI = _previewURI;
    }

    /// @dev override tokenId to start from 1
    function _startTokenId() internal pure override returns (uint256){
        return 1;
    }


    /// @notice Sent NFT Airdrop to an address
    /// @param _to list of address NFT recipient 
    /// @param _amount list of total amount for the recipient
    function gift(address[] calldata _to, uint256[] calldata _amount) 
        external 
        onlyOwner
    {
        for (uint256 i = 0; i < _to.length; i++) {
            _mint(_to[i], _amount[i]);
        }
    }

    /// @notice Set base URI for the NFT.  
    /// @param _uri base URI (can be ipfs/https)
    function setBaseURI(string calldata _uri) 
        external 
        onlyOwner 
    {
        baseURI = _uri;
    }


    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(ERC721A, ERC2981) 
        returns (bool) 
    {
        // IERC165: 0x01ffc9a7, IERC721: 0x80ac58cd, IERC721Metadata: 0x5b5e139f, IERC29081: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }


    function tokenURI(uint256 _id)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_id), "Token does not exist");

        return string(abi.encodePacked(baseURI, _id.toString()));
    }
    
}