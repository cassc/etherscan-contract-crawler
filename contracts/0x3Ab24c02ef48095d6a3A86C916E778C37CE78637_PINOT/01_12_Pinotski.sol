/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 

/// @title Art for Pinot
/// @author iqbalsyamil.eth (github.com/2pai)
/// @notice This is a charity NFT for our beloved Pinot who’s currently in a condition of stroke. Any profit from this NFT will be donated to him and his family.
contract PINOT is ERC721A, ReentrancyGuard, ERC2981, Ownable {
    using Strings for uint256;
    
    string public baseURI;
    bool public isDonatePeriod;
    address public constant PINOTSKI = 0xf0136dEe223c9a303ae8863F9438a687C775a4a7; // pinotski.eth
    uint256 public constant PRICE = 0.05 ether;

    event Donate(uint256 indexed tokenId, address from, uint256 amount, string message);

    constructor(
            string memory _previewURI
        )
        ERC721A("Art for Pinot", "PINOT")
    {
        _mint(PINOTSKI, 1);
        _mint(msg.sender, 1);
        _setDefaultRoyalty(PINOTSKI, 500);
        baseURI = _previewURI;
        isDonatePeriod = true;
    }

    /// @dev override tokenId to start from 1
    function _startTokenId() internal pure override returns (uint256){
        return 1;
    }

    function mintForPinot(string calldata _message)
        external
        payable
        nonReentrant
    {
        require(isDonatePeriod, "PAUSED");
        require(msg.value >= PRICE, "INSUFFICIENT_FUND");

        sendValue(payable(PINOTSKI), msg.value); // Send all fund to pinotski.eth
        
        _mint(msg.sender, 1);
        emit Donate(_nextTokenId() - 1, msg.sender, msg.value, _message);
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

    /// @notice Set royalties for EIP 2981.  
    /// @param _recipient the recipient of royalty
    /// @param _amount the amount of royalty (use bps)
    function setRoyalties(address _recipient, uint96 _amount) 
        external 
        onlyOwner 
    {
        _setDefaultRoyalty(_recipient, _amount);
    }

    /// @notice Set state of donation (paused).  
    /// @param _state the state of donation (active/paused)
    function setState(bool _state) 
        external 
        onlyOwner 
    {
        isDonatePeriod = _state;
    }

    function sendValue(address payable recipient, uint256 amount) 
        internal
    {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function withdrawAll() 
        external 
        onlyOwner 
    {
        require(address(this).balance > 0, "BALANCE_ZERO");
        sendValue(payable(PINOTSKI), address(this).balance);
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