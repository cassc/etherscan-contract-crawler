// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract GardenTomb is ERC721A, Ownable{
    using ECDSA for bytes32;
    uint256 public constant MAX_SUPPLY = 4321;
    string public baseTokenURI;
    address public signAddress;
    mapping(uint256 => Metadata) metadata;
    mapping(uint256 => bool) holderProofs;

    struct Metadata {
        string imgUri;
        uint8 tombstone;
        uint8 goods;
    }

    event MintEvent(address to,uint256 holderProof);

    constructor(string memory _baseTokenUri,address _signAddress) ERC721A("Garden Tomb", "GT"){
        baseTokenURI = _baseTokenUri;
        signAddress=_signAddress;
    }

    function mint(address to, string calldata imgUri, uint8 tombstone, uint8 goods, uint256 holderProof,bytes calldata _singature) external {
        require(totalSupply() < MAX_SUPPLY, "sold out");
        require(!holderProofs[holderProof] , "The holderProof has already been used");
        require(hasProof(holderProof,_singature),"You don't have permission");
        holderProofs[holderProof] = true;
        metadata[_nextTokenId()] = Metadata(imgUri,tombstone,goods);
        emit MintEvent(_msgSender(),holderProof);
        _mint(to,1);
    }

    function hasProof(uint256 _holderProof,bytes calldata _singature) internal view returns(bool){
        bytes32 signedMessageHash=keccak256(abi.encodePacked(uint256(uint160(address(_msgSender()))),_holderProof));
        return signedMessageHash.toEthSignedMessageHash().recover(_singature) == signAddress;
    }

    function getMetadata(uint256 tokenId) internal view returns (string memory){
        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                           '{"name":"Garden Tomb #', Strings.toString(tokenId),
                            '","description":"APEs are bored, NFTs are bored and the whole space is bored, now the Garden Tomb has opened, let the party rock: [Garden Tomb](https://www.nftmeme.club/gardenTomb.html)","image": "',_baseURI(),metadata[tokenId].imgUri,
                            '","attributes":[{"trait_type": "Tombstone","value": "',_getTomb(metadata[tokenId].tombstone),'"}, {"trait_type": "Goods","value": "',_getProp(metadata[tokenId].goods),'"}]}'
                        )
                    )
                )
        );
    }

    function ownerMint(address to ,string calldata imgUri, uint8 tombstone, uint8 goods) external onlyOwner{
        require(totalSupply() < MAX_SUPPLY, "sold out");
        metadata[_nextTokenId()] = Metadata(imgUri,tombstone,goods);
        _mint(to,1);
    }

    function setMetadata(uint256 tokenId,string calldata imgUri, uint8 tombstone, uint8 goods) external onlyOwner{
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        metadata[tokenId] = Metadata(imgUri,tombstone,goods);
    }

    function setSignedAddress(address _signAddress)external onlyOwner{
         signAddress=_signAddress;
    }

    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory)
	{
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return getMetadata(tokenId);
	}

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _getTomb(uint256 id) internal pure returns (string memory name_) {
        if (id == 1)  name_ = "BlackCat";
        if (id == 2)  name_ = "Coffin";
        if (id == 3)  name_ = "Crystal";
        if (id == 4)  name_ = "Dryad";
        if (id == 5)  name_ = "Gargoyle";
        if (id == 6)  name_ = "Ghost";
        if (id == 7)  name_ = "Gold";
        if (id == 8)  name_ = "Lucifer";
        if (id == 9)  name_ = "Satan";
        if (id == 10) name_ = "Stormtrooper";
    }

    function _getProp(uint256 id) internal pure returns (string memory name_) {
        if (id == 1)  name_ = "Bear";
        if (id == 2)  name_ = "Boom";
        if (id == 3)  name_ = "Broken";
        if (id == 4)  name_ = "Candle";
        if (id == 5)  name_ = "Crown";
        if (id == 6)  name_ = "Cup";
        if (id == 7)  name_ = "Ethereum";
        if (id == 8)  name_ = "Flower";
        if (id == 9)  name_ = "Gold";
        if (id == 10) name_ = "Kitty";
        if (id == 11) name_ = "Poop";
        if (id == 12) name_ = "Rottenegg";
        if (id == 13) name_ = "Skeleton";
        if (id == 14) name_ = "Snake";
        if (id == 15) name_ = "TNT";
    }


}