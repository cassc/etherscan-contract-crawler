// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


library MintUtil {
    using SafeMath for uint256;
    using ECDSA for bytes32;
    using Strings for uint256;

    function getDiscountedPrice(uint _startTime, uint256 _startPrice, uint256 _discountRate, uint256 _endPrice, 
    uint256 _duration) public view returns (uint256) {
        uint256 timeElapsed = block.timestamp.sub(_startTime);
        if(timeElapsed >= _duration){
            return _endPrice;
        }
        uint256 discount = timeElapsed.mul(_discountRate);
        uint256 discountedPrice = _startPrice.sub(discount);
        return discountedPrice.div(100000000000000).mul(100000000000000);
    }

    function inWhitelist(bytes32 _leaf, bytes32 _merkelRoot, bytes32[] calldata _merkleProof) public pure returns (bool){
        return MerkleProof.verify(_merkleProof, _merkelRoot, _leaf);
    }

    function canMint(uint _whitelistIndex, bool _voyagerCaptainMintActive, 
    bool _legacyMintActive, bool _privateMintActive, bool _publicSaleActive, 
    bool _addressMinted) public pure returns (bool, string memory) {

        if (!((_whitelistIndex == 0 && _voyagerCaptainMintActive) ||
        (_whitelistIndex == 1 && _legacyMintActive) ||
        (_whitelistIndex == 2 && _privateMintActive) || 
        (_whitelistIndex == 100 && _publicSaleActive))){
            return (false, "Your address is not yet qualified to mint, please read the FAQ and check back later.");
        }

        if (_addressMinted) {
            return (false, "You can only mint one per wallet");
        }

        return (true, "");
    }

    function canMint2(uint _whitelistIndex, uint256 _voyagerCaptainMintedAmount, uint256 _voyagerCaptainMintLimit, uint256 _legacyMintedAmount, uint256 _legacyMintLimit, uint256 _privateMintedAmount, 
    uint256 _privateMintLimit, uint256 _publicSaleMintedAmount, uint256 _publicSaleMintLimit) public pure returns (bool, string memory){
        if(_whitelistIndex == 0 && _voyagerCaptainMintedAmount.add(1) > _voyagerCaptainMintLimit){
            return(false,  "Can't mint more than voyager captain limit");
        } else if(_whitelistIndex == 1 && _legacyMintedAmount.add(1) > _legacyMintLimit){
            return(false,   "Can't mint more than legacy mint limit");
        } else if(_whitelistIndex == 2 && _privateMintedAmount.add(1) > _privateMintLimit){
            return(false, "Can't mint more than private mint limit");
        } else if(_whitelistIndex == 100 && _publicSaleMintedAmount.add(1) > _publicSaleMintLimit){
            return(false, "Can't mint more than public sale limit");
        }
        return (true, "");

    }

    function getTokenURI(uint256 _tokenId, bool _reveal, string memory _blindURI, string memory _baseURI) public pure returns (string memory) {
        if (!_reveal) {
            return string(abi.encodePacked(_blindURI, _tokenId.toString()));
        } else {
            return string(abi.encodePacked(_baseURI, _tokenId.toString()));
        }
    }
}


contract VoyagerPass is ERC721("Voyager Pass", "VOP"), ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    string private baseURI;
    string private blindURI;
    uint256 private constant TOTAL_NFT = 10000;
    // initial price for the auction
    uint256 public mintPrice = 1 ether;
    uint256 public endingPrice = 0.15 ether;
    uint256 public privatePrice = 0.1 ether;
    uint256 public auctionDuration = 5400 seconds;
    // 1.5 hours = 5400 seconds, so price decrease (1 - 0.1) * 10**18 / 5400 = 166_666_666_666_666 wei
    uint256 public discountRate = 166_666_666_666_666 wei;

    bool public reveal;

    bool public voyagerCaptainMintActive;
    bool public legacyMintActive;
    bool public privateMintActive;
    bool public publicSaleActive;
    bool public dutchAuctionActive;

    // save all three roots
    bytes32[3] public whitelistInfo;

    mapping (address => bool) public addressMinted;
    mapping (uint256 => bool) public isPaid;

    uint256 public voyagerCaptainMintLimit = 500;
    uint256 public legacyMintLimit = 1200;
    uint256 public privateMintLimit = 8300;
    uint256 public publicSaleMintLimit = 0;
    uint256 public voyagerCaptainMintedAmount;
    uint256 public legacyMintedAmount;
    uint256 public privateMintedAmount;
    uint256 public publicSaleMintedAmount;
    uint256 public dutchAuctionStartAt;

    function revealNow() external onlyOwner {
        reveal = true;
    }

    function setMintActive(bool _isActive, uint mintTypeIndex) external onlyOwner {
        if (mintTypeIndex == 0)
            voyagerCaptainMintActive = _isActive;
        else if (mintTypeIndex == 1)
            legacyMintActive = _isActive;
        else if (mintTypeIndex == 2)
            privateMintActive = _isActive;
        else if( mintTypeIndex == 3)
            publicSaleActive = _isActive;
    }

    function setDutchAuctionActive(bool _dutchAuctionActive) external onlyOwner {
        dutchAuctionActive = _dutchAuctionActive;
        dutchAuctionStartAt = block.timestamp;
    }

    function setPrivatePrice(uint256 _privatePrice) external onlyOwner {
        privatePrice = _privatePrice;
    }

    function setDutchAuctionInfo(uint256 _startPrice, uint256 _endPrice, uint256 _duration) external onlyOwner {
        mintPrice = _startPrice;
        endingPrice = _endPrice;
        auctionDuration = _duration;
        discountRate = (mintPrice.sub(endingPrice)).div(auctionDuration);
    }

    function setMintLimit(uint256 _voyagerCaptainMintLimit, uint256 _legacyMintLimit, uint256 _privateMintLimit) external onlyOwner {
        voyagerCaptainMintLimit = _voyagerCaptainMintLimit;
        legacyMintLimit = _legacyMintLimit;
        privateMintLimit = _privateMintLimit;
        publicSaleMintLimit = TOTAL_NFT.sub(voyagerCaptainMintLimit.add(legacyMintLimit).add(privateMintLimit)); 
    }

    function setURIs(string memory _blindURI, string memory _URI) external onlyOwner {
        blindURI = _blindURI;
        baseURI = _URI;
    }

    function setRoot(bytes32 _root, uint _whitelistIndex) external onlyOwner {
        whitelistInfo[_whitelistIndex] = _root;
    }

    function airdrop(address _target, uint _whitelistIndex) external onlyOwner {

        require(totalSupply().add(1) <= TOTAL_NFT, "Can't mint more than 10000 NFTs");

        addressMinted[_target] = true;

        uint256 tokenId = totalSupply() + 1;
        updateMintMaps(tokenId, _whitelistIndex);
        _safeMint(_target,tokenId);
    }

    function canMint(uint _whitelistIndex, address _address) public view returns (bool, string memory) {
        // check if user is authorized to mint / mint is active / user has already minted
        require(totalSupply().add(1) <= TOTAL_NFT, "Can't mint more than 10000 NFTs");
        return MintUtil.canMint(_whitelistIndex, voyagerCaptainMintActive, legacyMintActive, privateMintActive, publicSaleActive, 
        addressMinted[_address]);
    }

    function canMint2(uint _whitelistIndex) public view returns (bool, string memory) {
        // check if minted amount is greater than limit
        return MintUtil.canMint2(_whitelistIndex, voyagerCaptainMintedAmount, voyagerCaptainMintLimit, legacyMintedAmount,
         legacyMintLimit, privateMintedAmount, privateMintLimit,publicSaleMintedAmount, publicSaleMintLimit);
    }


    function getMintPriceByUser(uint _whitelistIndex) public view returns (uint256) {
        if(_whitelistIndex <= 1){
            return 0;
        }else if(_whitelistIndex == 2){
            return privatePrice;
        }else if(dutchAuctionActive){
            return MintUtil.getDiscountedPrice(dutchAuctionStartAt, mintPrice, discountRate, endingPrice, auctionDuration);
        }else{
            return endingPrice;
        }
    }

    function withdraw() public onlyOwner {
        payable(0xfA61b6E35613f014Bd4387898790E89572f63B57).transfer(address(this).balance);
    }

    function updateMintMaps(uint256 _tokenId, uint _whitelistIndex) private {
        // update minted amount for different tiers and the isPaid map
        if(_whitelistIndex == 0){
            voyagerCaptainMintedAmount = voyagerCaptainMintedAmount.add(1);
            isPaid[_tokenId] = false;
        }else if(_whitelistIndex == 1){
            legacyMintedAmount = legacyMintedAmount.add(1);
            isPaid[_tokenId] = false;
        }else if(_whitelistIndex == 2){
            privateMintedAmount = privateMintedAmount.add(1);
            isPaid[_tokenId] = true;
        }else{
            publicSaleMintedAmount = publicSaleMintedAmount.add(1);
            isPaid[_tokenId] = true;
        }
    }

    function getWhitelistIndex(bytes32[] calldata _merkleProof, bytes32 leaf) internal view returns(uint) {
        uint whitelistIndex = 100;
        if(MerkleProof.verify(_merkleProof, whitelistInfo[0], leaf)){
            whitelistIndex = 0;
        } else if(MerkleProof.verify(_merkleProof, whitelistInfo[1], leaf)){
            whitelistIndex = 1;
        } else if(MerkleProof.verify(_merkleProof, whitelistInfo[2], leaf)){
            whitelistIndex = 2;
        }
        return whitelistIndex;
    }

    function mintNFT(bytes32[] calldata _merkleProof) payable external nonReentrant{
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        uint whitelistIndex = getWhitelistIndex(_merkleProof, leaf);
        // apply 2 checks to make sure the mint request is valid
        (bool success, string memory reason) = canMint(whitelistIndex, msg.sender);
        (bool success2, string memory reason2) = canMint2(whitelistIndex);
        require(success, reason);
        require(success2, reason2);

        uint256 currentPrice = getMintPriceByUser(whitelistIndex);
        require(currentPrice <= msg.value, "Insufficient payable value");

        addressMinted[msg.sender] = true;

        uint256 tokenId = totalSupply() + 1;
        updateMintMaps(tokenId, whitelistIndex);
        _safeMint(msg.sender, tokenId);
        if(dutchAuctionActive){
            uint256 refund = msg.value.sub(currentPrice);
            if (refund > 0) {
                payable(msg.sender).transfer(refund);
            }
        }
    }

    function isTokenPaid(uint256 _tokenId) public view returns (bool) {
        return isPaid[_tokenId];
    }
    
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        return MintUtil.getTokenURI(_tokenId, reveal, blindURI, baseURI);
    }

    function supportsInterface(bytes4 _interfaceId) public view override (ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }
}