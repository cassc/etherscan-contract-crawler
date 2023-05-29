//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


contract BudRoyalty is ERC721, AccessControl, Ownable, Pausable{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private _baseTokenURI;
    bool private _isUriFrozen;
    uint public TOTAL_SUPPLY;

    using Counters for Counters.Counter;
    Counters.Counter tokenid;
    

    constructor(
        string memory NFTName,
        string memory NFTSymbol,
        string memory collectibleURI,
        address minter,
        uint _totalSupply
    ) ERC721(NFTName, NFTSymbol)
    {
        _baseTokenURI = collectibleURI;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, minter);
        TOTAL_SUPPLY = _totalSupply;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Admin: Caller is not Admin"
        );
        _;
    }

    modifier onlyMinter() {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Admin: Caller is not Minter"
        );
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function totalSupply() public view returns(uint){
        return TOTAL_SUPPLY;
    }

    function setBaseURI(string memory _newBaseURI) public onlyAdmin{
        
        require(!_isUriFrozen, 'Token URI is frozen');
        _baseTokenURI = _newBaseURI;
    }

    function freezeTokenURI() public onlyAdmin{
        
        require(!_isUriFrozen, 'Token URI is frozen');
        _isUriFrozen = true;
    }

    function safeMint(
        address owner,
        uint qty
    ) public onlyMinter {

        require(tokenid.current() + qty < TOTAL_SUPPLY + 1, "Ran out of quantity" );
        for(uint i=0; i < qty; i++){
            super._safeMint(owner, tokenid.current());
            tokenid.increment();
        }
    }

    function currentCount() public view returns(uint) {
        return tokenid.current();
    }

    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() public onlyAdmin {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

     function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}