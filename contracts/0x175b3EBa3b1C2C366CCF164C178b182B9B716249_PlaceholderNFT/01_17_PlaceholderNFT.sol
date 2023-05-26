// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";

contract PlaceholderNFT is ERC721, Pausable, Ownable, DefaultOperatorFilterer {
    string private uri = "ipfs://bafybeigxbevgkmfstj6podhtyfuei7albldbjlvd3sdcfsd3yqr4pkohgm/";
    uint256 private _totalSupply = 0;
    address private _stakingContract;

    mapping (uint256 => uint256) public idToMetadataMapping;

    constructor() ERC721("Quirksville Questing", "QQ") {}

    // Mint an NFT with an incremental ID
    function mintNFT(address _user, uint256 assetId) external onlyStakingContract returns (uint256) {
        uint256 newTokenId = _totalSupply;
        _safeMint(_user, newTokenId);
        idToMetadataMapping[newTokenId] = assetId;
        _totalSupply++;

        return newTokenId;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = _baseURI();
        return string(abi.encodePacked(currentBaseURI, Strings.toString(idToMetadataMapping[_tokenId]), ".json"));
    }

    function _baseURI() internal view override returns (string memory) {
        return uri;
    }

    function setMetadata(string memory _uri) public onlyOwner {
        uri = _uri;
    }
    
    modifier onlyStakingContract() {
        require(msg.sender == _stakingContract, "NFTCollection: caller is not the staking contract");
        _;
    }

    function setStakingContract(address stakingContract) external onlyOwner {
        _stakingContract = stakingContract;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}