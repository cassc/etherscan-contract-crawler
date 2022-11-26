// SPDX-License-Identifier: MIT

/*
  


*/

pragma solidity ^0.8.17;

import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';


abstract contract LAPIXZERO {
    function mintMecha(address to, uint[] memory ids) public virtual;
}


contract LapixSukabenjaV2 is ERC721AQueryable, 
                        ERC721ABurnable,
                        ERC2981, 
                        Ownable, 
                        DefaultOperatorFilterer, 
                        ReentrancyGuard {

    event ComponentsClaimed(uint256 _totalClaimed, address _owner, uint256 _numOfComponents);
    event FuseMecha(address _address, uint[] _tokenIds);

    bool public publicMint = false;
    bool public fuseEnabled = false;

    string private _baseTokenURI;

    uint public minComponentsPerMecha = 5;
    uint public maxComponentsPerMecha = 7;
    uint public maxPerAddress = 12;
    uint public maxSupply = 3000;

    mapping (uint => uint) public componentType;
    

    LAPIXZERO lapixContract;
    
    constructor(string memory _metadataBaseURL) ERC721A("LapixSukabenja", "LPS") {
        _baseTokenURI = _metadataBaseURL;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(uint256 quantity) external {
        require(tx.origin == msg.sender, "Cannot mint from a contract");
        require(publicMint, "Cannot claim now");
        require(_numberMinted(msg.sender) + quantity <= maxPerAddress, "Tx will exceed max tokens per wallet");
        require(quantity > 0, "Invalid token count");
        require(totalSupply() + quantity <= maxSupply, "Tx will exceed max supply");
        

        _safeMint(msg.sender, quantity);

        emit ComponentsClaimed(totalSupply(), msg.sender, quantity);
    }

    function fuse(uint[] memory tokenIds) public {

        require(fuseEnabled, "Cannot fuse parts");
        require(tokenIds.length >= minComponentsPerMecha, "Not enough parts to form a mecha");
        require(tokenIds.length <= maxComponentsPerMecha, "Too many components to form a mecha");

        uint[] memory componentCount = new uint[](tokenIds.length);
        
        for (uint i=0; i<tokenIds.length; i++) {

            require(msg.sender == ownerOf(tokenIds[i]), "Must be part owner to fuse");

            uint _type = componentType[tokenIds[i]];
            componentCount[_type] = componentCount[_type] + 1;
        }

        for (uint i=0; i<tokenIds.length; i++)
            require(componentCount[i] == 1, "Cannot fuse with duplicate component types");
        
        lapixContract.mintMecha(msg.sender, tokenIds);

        for (uint i=0; i<tokenIds.length; i++)
            burn(tokenIds[i]);

        emit FuseMecha(msg.sender, tokenIds);
    }

    function mintToAddresses(address[] memory _addresses, uint[] memory _num) external onlyOwner {
        
        for (uint i=0; i<_addresses.length; i++) {
            address _to = address(_addresses[i]);
            _safeMint(_to, _num[i]);
        }
    }

    function mintToAddress(address _to, uint _num) external onlyOwner {
        _safeMint(_to, _num);
    }

    function setComponentType(uint[] memory tokenIds, uint[] memory _types) external onlyOwner {
        require(tokenIds.length == _types.length, "tokenIds and component types should be same length");
        for (uint i=0; i<tokenIds.length; i++)
            componentType[tokenIds[i]] = _types[i];
    }


    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function flipPublicMintState() external onlyOwner {
        publicMint = !publicMint;
    }

    function flipFuseEnabled() external onlyOwner {
        fuseEnabled = !fuseEnabled;
    }

    function setMaxSupply(uint _supply) external onlyOwner {
        maxSupply = _supply;
    }

    function setMaxPerAddress(uint _max) external onlyOwner {
        maxPerAddress = _max;
    }

    function setLapixContract(address _address) external onlyOwner {
        lapixContract = LAPIXZERO(_address);
    }

    function setComponentsPerMecha(uint _min, uint _max) external onlyOwner {
        minComponentsPerMecha = _min;
        maxComponentsPerMecha = _max;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, IERC721A, ERC2981) returns (bool) {
    // Supports the following `interfaceId`s:
    // - IERC165: 0x01ffc9a7
    // - IERC721: 0x80ac58cd
    // - IERC721Metadata: 0x5b5e139f
    // - IERC2981: 0x2a55205a
    return 
        ERC721A.supportsInterface(interfaceId) || 
        ERC2981.supportsInterface(interfaceId);
}


    function setApprovalForAll(address operator, bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}