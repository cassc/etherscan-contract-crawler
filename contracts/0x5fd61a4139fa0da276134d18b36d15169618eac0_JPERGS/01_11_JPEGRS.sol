/**
SPDX-License-Identifier: MIT

                                                           
     ,--. ,------.  ,------. ,------.   ,----.     ,---.   
     |  | |  .--. ' |  .---' |  .--. ' '  .-./    '   .-'  
,--. |  | |  '--' | |  `--,  |  '--'.' |  | .---. `.  `-.  
|  '-'  / |  | --'  |  `---. |  |\  \  '  '--'  | .-'    | 
 `-----'  `--'      `------' `--' '--'  `------'  `-----'  
                                                           
by JPG People
*/

pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 

/// @title JPERGS by JPG People
/// @author iqbalsyamil.eth (github.com/2pai)
/// @notice The JPG People Exclusive Rewards ’n Gifts Service a.k.a JPERGS is an initiative launched to handle bonus drops for the citizens of JPG Town.
contract JPERGS is ERC721A, ERC2981, Ownable {
    using Strings for uint256;
    
    string public baseURI;
    mapping(address => bool) public allowedContracts;
    constructor(
            string memory _previewURI,
            address _owner
        )
        ERC721A("JPERGS", "JPERGS")
    {
        _mint(_owner, 1);
        _setDefaultRoyalty(_owner, 0);
        _transferOwnership(_owner);
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

    /// @notice Allow contract to call burn function.  
    /// @param _contractAddr address of contract to call the burn function
    /// @param _state state of the contract (allowed/not)
    function setAllowedContract(address _contractAddr, bool _state) 
        external 
        onlyOwner 
    {
        allowedContracts[_contractAddr] = _state;
    }

    function burn(address _sender, uint256 _tokenId) 
        external  
    {
        require(allowedContracts[msg.sender], "!CALL");
        require(ownerOf(_tokenId) == _sender, "!OWNER");
        _burn(_tokenId, true);
    }
    /// @notice Set royalties for EIP 2981.  
    /// @param _recipient the recipient of royalty
    /// @param _amount the amount of royalty (use bps)
    function setRoyalties(address _recipient, uint96 _amount) 
        external 
        onlyOwner 
    {
        _setDefaultRoyalty(_recipient, _amount);
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