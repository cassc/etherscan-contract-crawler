// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract NFT is ERC721, AccessControl {
    bytes32 public constant REDEEMER_ROLE = keccak256("REDEEMER_ROLE");

    string private _mediaURI;
    string private _tokenURI;

    address public royaltyReciever;
    uint256 public royalty;
    bool public redeemed = false;

    event Redeemed();

    constructor(string memory name_, string memory symbol_, string memory mediaURI_, string memory tokenURI_, address royaltyReciever_, address mintReceiver_) ERC721(name_, symbol_) {
        _grantRole(DEFAULT_ADMIN_ROLE, mintReceiver_);
        _grantRole(REDEEMER_ROLE, mintReceiver_);
        royaltyReciever = royaltyReciever_;
        _mediaURI = mediaURI_;
        _tokenURI = tokenURI_;
        _safeMint(mintReceiver_, 0);
    }

    ///@notice returns uri for token metadata
    function tokenURI(uint256) public view override returns(string memory) {
        return _tokenURI;
    }

    ///@notice returns uri for audio file for owner
    function mediaURI() public view returns(string memory) {
        return _mediaURI;
    }

    ///@notice sets redeem status. Called only by REDEEMER_ROLE
    function redeem() public onlyRole(REDEEMER_ROLE) {
        redeemed = true;
        emit Redeemed();
    }

    ///@notice change the roylaty receiver.
    function changeRoyaltiesReceiver(address royaltyReciever_) public onlyRole(DEFAULT_ADMIN_ROLE) { 
        royaltyReciever = royaltyReciever_;
    }

    ///@notice returns royalty amount and reciever
    ///@param _tokenId in our case allways 0
    ///@param _salePrice token price
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        return (royaltyReciever, _salePrice / 10);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId) || _interfaceId == 0x2a55205a;
    }
}