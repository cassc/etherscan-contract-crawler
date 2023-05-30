// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IFancyBears.sol";
import "./Tag.sol";

contract HoneyJars is Ownable, ERC721, ERC721Enumerable {

    using SafeMath for uint256;
    using MerkleProof for bytes32[];

    IFancyBears public fancyBears;

    mapping(uint256 => bool) public fancyBearsClaimed;
    mapping(address => uint256) public numberClaimedByGoldListAddress;

    string public baseURI;

    bytes32 public goldListRoot;
    bool public claimActive;

    modifier goldListSet() {
        require(goldListRoot!=0,"GoldList not set");
        _;
    }

    modifier whenAddressOnGoldList(bytes32[] memory _merkleproof, uint256 _maxClaim) {
        require(MerkleProof.verify(
            _merkleproof,
            goldListRoot,
            getLeaf(msg.sender, _maxClaim)
            ),
            "whenAddressOnGoldList: Not on white list or incorrect maxClaim"
        );
        _;
    }

    event BearsClaimedJars(address _address, uint256[] _tokenIds, uint256 _length);

    constructor(IFancyBears _fancyBearsToken) ERC721("Fancy Honey Jars", "FHJ") {
        fancyBears = _fancyBearsToken;
        claimActive = false;
        baseURI = "https://api-honeyjars.fancybearsmetaverse.com/";
    }

    function mint(uint256[] calldata _tokenIds) public {
        require(claimActive, "mint: Claim is not active");
        require(_tokenIds.length <= 20, "mint: Cannot claim more than 40 Honey Jars per transaction");
        uint256 supply = totalSupply();

        for(uint256 i = 0; i < _tokenIds.length; i++){
            require(fancyBears.ownerOf(_tokenIds[i]) == msg.sender,"mint: Caller must own all fancy bear tokens");
            require(!fancyBearsClaimed[_tokenIds[i]], "mint: Fancy Bear token already used for claim");
            fancyBearsClaimed[_tokenIds[i]] = true;
        }

        uint256 numberHoneyJars = 1;

        if(_tokenIds.length == 2){
            numberHoneyJars = 3;
        }
        else if(_tokenIds.length == 3){
            numberHoneyJars = 5;
        } 
        else if(_tokenIds.length == 4){
            numberHoneyJars = 7;
        } 
        else if(_tokenIds.length >= 5){
            numberHoneyJars = _tokenIds.length.mul(2);
        } 

        for(uint256 i = 0; i < numberHoneyJars; i++){
            _safeMint(msg.sender, supply.add(1).add(i));
        }

        emit BearsClaimedJars(msg.sender, _tokenIds, _tokenIds.length);
    }

    function mintGoldList(bytes32[] memory _merkleproof, uint256 _maxClaim, uint256 _claimAmount)
        public
        goldListSet()
        whenAddressOnGoldList(_merkleproof, _maxClaim) 
    {
        require(claimActive, "mintGoldList: Claim is not active");
        require(
            _claimAmount + numberClaimedByGoldListAddress[msg.sender] <= _maxClaim, 
            "mintGoldList: Caller attempting to claim too many tokens"
        );

        uint256 supply = totalSupply();

        for(uint256 i = 0; i < _claimAmount; i++){
            _safeMint(msg.sender, supply.add(1).add(i));
        }

        numberClaimedByGoldListAddress[msg.sender] += _claimAmount;

    }

    function setGoldList(bytes32 _root) public onlyOwner() {
        require(!claimActive, "setGoldList: Claim must be off");
        goldListRoot = _root;
    }

    function getLeaf(address _address, uint256 _maxClaim) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_address, _maxClaim));
    }

    function toggleClaimActive() public onlyOwner {
        claimActive = !claimActive;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    function fancyBearsClaimStatusByAddress(address _address) public view returns(bool[] memory, uint256[] memory) {
        uint256[] memory tokenIds = fancyBears.tokensInWallet(_address);

        bool[] memory tokensClaimStatus = new bool[](tokenIds.length);
        for(uint256 i; i < tokenIds.length; i++){
            tokensClaimStatus[i] = fancyBearsClaimed[tokenIds[i]];
        }
        return (tokensClaimStatus, tokenIds);
    }

    function tokensInWallet(address _address) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_address);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_address, i);
        }
        return tokensId;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}