/*
    Copyright 2023, Abdullah Al-taheri عبدالله الطاهري (المُعلَّقَاتٌ - muallaqat.io - muallaqat.eth - معلقات.eth)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/// @title MuallaqatNFT Contract
/// @author Abdullah Al-taheri

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "../library/@rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "../library/@rarible/royalties/contracts/LibPart.sol";
import "../library/@rarible/royalties/contracts/LibRoyaltiesV2.sol";

contract MuallaqatNFT is ERC721URIStorage, PullPayment, Ownable,RoyaltiesV2Impl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    bytes4 constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint256 public constant fees = 0.5 ether;
    address public  MUALLAQAT_MARKETPLACE_ADDRESS;

    string private _contractURI;

    enum ScriptTypes{
        poem,
        song_lyrics,
        code,
        message,
        screenplay
    }

    struct Script {
        string script;
        ScriptTypes scriptType;
    }
    // on-chain script
    mapping(uint256 => Script) private token_script;

    event Minted (
        uint256 tokenId,
        address ownerId
    );

    string public baseTokenURI;
    constructor() ERC721("Muallaqat Digital Asset", "MDA") {
        baseTokenURI = "";
        _contractURI = 'https://ipfs.muallaqat.io/ipfs/QmbyjsQzXvDs3LmTcFrfMkoR2rfYYS1G7bqpRyK4v4Ghzd';
    }
   
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function createToken(string memory tokenURI, string memory _script,uint96 _script_type)  public payable returns (uint) {
        if(msg.sender != owner() && msg.sender != MUALLAQAT_MARKETPLACE_ADDRESS) {
            require(msg.value >= fees, "Not enough funds, please send at least 0.5 ether");
            // transfer funds to owner
            payable(owner()).transfer(msg.value);
        }
       


        // mint token
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
       
        // if _script_type != 100 means it's not script
        if(_script_type != 100) {
            // save script object on chain !
            token_script[newItemId] = Script(
                _script,
                ScriptTypes(_script_type)
            );
        } 
        
        _mint(msg.sender, newItemId);
    
        _setTokenURI(newItemId, tokenURI );

        emit Minted(
            newItemId,
            msg.sender
        );
        return newItemId;
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /// @dev Overridden in order to make it an onlyOwner function
    function withdrawPayments(address payable payee) public override onlyOwner virtual {
        super.withdrawPayments(payee);
    }

    function setMuallaqatMarketPlaceAddress(address muallaqatAddress) public onlyOwner{ 
        MUALLAQAT_MARKETPLACE_ADDRESS = muallaqatAddress;
    }
    function setRoyalties(uint _tokenId, address payable _royaltiesRecipientAddress, uint96 _precentageBasisPoints) public { 
        require(msg.sender == owner() || msg.sender == MUALLAQAT_MARKETPLACE_ADDRESS, "Only owner or marketplace can set royalties");
        require(_precentageBasisPoints > 0, "Percentage must be greater than 0");
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _precentageBasisPoints;
        _royalties[0].account = _royaltiesRecipientAddress;
        _saveRoyalties(_tokenId,_royalties);
    }
    
    //https://eips.ethereum.org/EIPS/eip-2981
     function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    ){
        LibPart.Part[] memory _royalties = royalties[_tokenId];
        if(_royalties.length > 0 ){
            return (_royalties[0].account, _royalties[0].value * _salePrice / 100);
        }
        return (address(0), 0);

    }
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool){
  
        if( interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES ){
            return true;
        } 
        if( interfaceId == _INTERFACE_ID_ERC2981 ){
            return true;
        }
  
        return super.supportsInterface(interfaceId);
    }
    function getTokenScript(uint256 _tokenId) public view virtual returns (Script memory){ 
        return token_script[_tokenId];
    }


}