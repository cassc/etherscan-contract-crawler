// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

import "./ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Celebrate is ERC721A, ERC2981{
    using Strings for uint256;

    //------------------//
    //     VARIABLES    //
    //------------------//

    uint256 public maxSupply = 456;
    uint256 public royaltyFee = 450;
    
    address private _owner;

    string public baseURI;

    bool public frozen = false;

    //------------------//
    //    CONSTRUCTOR   //
    //------------------//

    constructor(string memory _name, string memory _symbol, string memory _uri) ERC721A(_name, _symbol){
	    _owner = msg.sender;
		baseURI = _uri;
        _safeMint(msg.sender, 1);
    }

    //------------------//
    //     MODIFIERS    //
    //------------------//

    modifier onlyOwner{
        require (msg.sender == _owner, "Unauthorized");
        _;
    }

    //------------------//
    //       MINT       //
    //------------------//

    function mint(address[] memory recipients) public onlyOwner{
        require(_totalMinted() + recipients.length <= maxSupply, "MaxSupply");

        for(uint i = 0; i < recipients.length;){
            _safeMint(recipients[i], 1);
            unchecked { i++; }
        }
    }

    //------------------//
    //      GETTERS     //
    //------------------//

	function _baseURI() internal view virtual override returns (string memory) {
	    return baseURI;
	}

    function owner() public view returns(address){
        return _owner;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) public override view returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        return (_owner, (salePrice * royaltyFee / 10000));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        if(interfaceId == 0x5b5e139f) { return true; }
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    	require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
    	string memory currentBaseURI = _baseURI();
    	return bytes(currentBaseURI).length > 0	?
         string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
	}
    
    //------------------//
    //      SETTERS     //
    //------------------//

    function freeze() public onlyOwner {
        frozen = true;
    }

	function setBaseURI(string memory _newBaseURI) public onlyOwner {
        require(frozen == false, "Frozen Metadata");
	    baseURI = _newBaseURI;
	}

    function setRoyaltyFee(uint256 fee) public onlyOwner {
        royaltyFee = fee;
    }
    
    //------------------//
    //       MISC       //
    //------------------//
    
    function withdraw()  public onlyOwner  {
        payable(_owner).transfer(address(this).balance);
    }

	function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}