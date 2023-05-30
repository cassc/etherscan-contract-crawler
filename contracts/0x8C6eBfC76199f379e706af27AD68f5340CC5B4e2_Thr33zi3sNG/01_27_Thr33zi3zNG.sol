// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "../structs/NiftyType.sol";
import "../utils/Signable.sol";
import "../utils/Withdrawable.sol";
import "../utils/Royalties.sol";

contract Thr33zi3sNG is ERC721, Royalties, Signable, Withdrawable {
    using Address for address;        

    address immutable defaultOwner;
    bool burnAndReplaceOpen;
    uint256 counter;
    uint256 extantSupply;

    constructor(address niftyRegistryContract_, address defaultOwner_) {
        initializeERC721("thr33zi3sNG", "333NG", "https://api.thr33zi3s.com/token/");
        initializeNiftyEntity(niftyRegistryContract_);
        defaultOwner = defaultOwner_;
        admin = msg.sender;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, Royalties, NiftyPermissions) returns (bool) {
        return          
        super.supportsInterface(interfaceId);
    }                                     

    function tokenURI(uint256 tokenId) public virtual view override returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function setBaseURI(string calldata uri) external {
        _requireOnlyValidSender();
        _setBaseURI(uri);        
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }    

    function burn(uint256 tokenId) public {
        _burn(tokenId);
        extantSupply -= 1;
    }

    function mint() public {
        _requireOnlyValidSender();
        uint256 tokenId = counter + 1001; //Start at 1001
        _mint(defaultOwner, tokenId);
        extantSupply += 1;
        counter += 1;
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), ERROR_TRANSFER_TO_ZERO_ADDRESS);
        require(!_exists(tokenId), ERROR_ALREADY_MINTED);
        require(extantSupply + 1 <= 100, "Exceeds Maximum Supply");
        balances[to] += 1;
        owners[tokenId] = to; 

        emit Transfer(address(0), to, tokenId);

    }

    function burnAndReplace(uint256 initialTokenId) public {
        require(burnAndReplaceOpen, "Burn Traits not yet available");
        burn(initialTokenId); // calls require(isApprovedOrOwner, ERROR_NOT_OWNER_NOR_APPROVED);
        uint256 newTokenId = counter + 1001;
        _mint(_msgSender(), newTokenId);
        require(_checkOnERC721Received(address(0), _msgSender(), newTokenId,""), ERROR_NOT_AN_ERC721_RECEIVER); //i.e. safe mint
        counter += 1;
        extantSupply += 1;
    }

    function toggleBurnWindow(bool active) public {
        _requireOnlyValidSender();
        burnAndReplaceOpen = active;
    }
    
    function totalSupply() public view returns (uint256) {
        return extantSupply;
    }
}