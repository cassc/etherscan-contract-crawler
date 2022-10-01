// SPDX-License-Identifier: MIT
// Contract created by nftfede.eth

pragma solidity > 0.8.9 < 0.9.0;

import "./ERC721A.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/utils/Strings.sol";


error Caller__NotOwner();

contract myContract is ReentrancyGuard, ERC721A{

    string constant _tokenName = "Twitterpfps";
    string constant _tokenSymbol = "TPFP";
    string public baseURI = "ipfs://QmUo8pz6iBE4qDALEW6dezTy6e4DHmU2PznNyarJFdJYrX/";
    address immutable owner;

    constructor()ERC721A(_tokenName, _tokenSymbol) {
        owner = msg.sender;
        mint(1);
    }

    modifier onlyOwner (){
        if (msg.sender != owner) revert Caller__NotOwner();
        _;
    }

    function mint(uint8 _mintAmount) public {
        if(msg.sender != owner){
            revert Caller__NotOwner();
        }
        _safeMint(msg.sender, _mintAmount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "The token you are querying is inexistent");
	    string memory currentBaseURI = _baseURI();
	    return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), ".json")) : "hello";
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseUri(string memory _newBaseUri) public onlyOwner {
        baseURI = _newBaseUri;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner).call{value: address(this).balance}('');
        require(os);
    }
}