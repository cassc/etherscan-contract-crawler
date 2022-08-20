//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract RoyaltiesPOC is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    string public constant ContractName = "RoyaltiesPOC.0.0.1";
    mapping(address=>bool) private authorizedApprovers; 
    Counters.Counter private _tokenIdCounter;
    address[] public authorizedApproverList;
    address private _creator;

    constructor() ERC721("Royalties POC", "RPC") {
        _creator = msg.sender;
    }

    modifier onlyCreator() {
        require(msg.sender==_creator, "only Creator");
        _;
    }

    modifier onlyCreatorOrOwner() {
        require(msg.sender==_creator || msg.sender==owner(), "only Creator or Owner");
        _;
    }

    function creator() public view returns (address) {
        return _creator;
    }

    function safeMint(address to) public onlyCreatorOrOwner {
        require (totalSupply()<1, "One-of-one is already minted");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        string memory uri = "https://g4ta3bbnolxxzaiopbmbszgidzglstdpgv4roegjo5nfraelconq.arweave.net/NyYNhC1y73yBDnhYGWTIHky5TG81eRcQyXdaWICLE5s";
        _setTokenURI(tokenId, uri);    
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }


    function transferCreator(address newCreator) public onlyCreator {
        _creator = newCreator;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function removeAuthorizedApprover(address approver) public onlyCreator {
        bool inList = authorizedApprovers[approver];
        if (!inList) return; // do nothing if not in list
        authorizedApprovers[approver] = false;
        uint index = findIndexOf(authorizedApproverList, approver);
        authorizedApproverList[uint(index)] = authorizedApproverList[authorizedApproverList.length -1 ];
        authorizedApproverList.pop();
    }

    function findIndexOf(address[] memory addresses, address value) private pure returns(uint) {
        for (uint i = 0; i < addresses.length; i++) {
            if (addresses[i] == value) {
                return i;
            }
        }       
    }

    function addAuthorizedApprover(address approver) public onlyCreator {
        authorizedApprovers[approver] = true;
        authorizedApproverList.push(approver);   
    }
    
    function isAuthorizedApprover(address op) public view returns(bool) {
        return authorizedApprovers[op];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        require(isAuthorizedApprover(operator), "operator not authorized");
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        
        require(to != owner, "ERC721: approval to current owner");
        
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );
        require(isAuthorizedApprover(to), "to not authorized approver");
        _approve(to, tokenId);
    }


    

}