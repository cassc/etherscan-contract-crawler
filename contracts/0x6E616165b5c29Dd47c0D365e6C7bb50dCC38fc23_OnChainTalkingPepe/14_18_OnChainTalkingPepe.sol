// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./OnChainTalkingPepeSvg.sol";

contract OnChainTalkingPepe is ERC721, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;
    bool public contractLive = true;
    mapping(uint256 => OnChainTalkingPepeSvg.ImageData) public imageToTokenId;
    uint256 public constant TEXTCHARACTERLIMIT = 10;
    uint256 public constant MAXSUPPLY = 999;
    uint256 public constant LASTCALLSUPPLYLIMIT = 950;
    uint256 public constant FREESUPPLY = 20;
    uint256 public constant MINTPRICE = 0.009 ether;
    uint256 public constant LASTCALLMINTPRICE = 0.05 ether;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string[] private colors = ['FFA555', 'ff0000', 'ffa500', 'ffff00', 'a113e8', '0000ff', '4b0082', 'ee82ee', '245ea4', '2acac5', 'cc0066'];
    string[] private pepeColors = ['68984c', 'ff99a8', '228B22', '006400', '3CB371', '20B2AA', '808000', '6B8E23', '556B2F', 'c175ff', 'fea95e'];

    constructor() ERC721("OnChainTalkingPepe", "OCN") {}

    function mint(string memory _userText1, string memory _userText2) public payable {

        require(contractLive, "Contract is not accepting mint anymore.");
        uint256 totalSupply = _tokenIdCounter.current() + 1;
        require(totalSupply <= MAXSUPPLY, "Minted out!");
        require(bytes(_userText1).length <= TEXTCHARACTERLIMIT, "Text input 1 exceeds limit.");
        require(bytes(_userText2).length <= TEXTCHARACTERLIMIT, "Text input 2 exceeds limit.");
        require(!startOrEndWithSpace(_userText1), "Text input 1 starts or ends with whitespace!");
        require(!startOrEndWithSpace(_userText2), "Text input 2 starts or ends with whitespace!");
        require(exists(_userText1, _userText2) != true, "Speech bubble text combination already exists!");        

        if (msg.sender != owner()) {
            require(msg.value >= getMintPrice(), "Not enough eth sent.");
        }

        uint random1 = randomNum(11, block.timestamp, totalSupply);
        uint random2 = randomNum(11, block.difficulty, totalSupply);

        OnChainTalkingPepeSvg.ImageData memory newImage = OnChainTalkingPepeSvg.ImageData(
            string(abi.encodePacked("OnChainTalkingPepe #", totalSupply.toString())),
            _userText1,
            _userText2,
            colors[random1],
            pepeColors[random1],
            colors[random2],
            string.concat((random1+2).toString(), ".", random2.toString()),
            string.concat((random2+2).toString(), ".", random1.toString()),
            "A52A2A"
        );

        _tokenIdCounter.increment();
        imageToTokenId[totalSupply] = newImage;
        _mint(msg.sender, totalSupply);
    }

    function startOrEndWithSpace(string memory _text) internal pure returns (bool) {
        if(bytes(_text).length==0)
            return false;
        return (bytes(_text)[0] == 0x20 || bytes(_text)[bytes(_text).length-1] == 0x20);
    }

    function exists(string memory _text, string memory _text2) public view returns (bool) {
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            if (
                keccak256(abi.encodePacked(imageToTokenId[i].speechBubbleText1)) == keccak256(abi.encodePacked(_text))
                && keccak256(abi.encodePacked(imageToTokenId[i].speechBubbleText2)) == keccak256(abi.encodePacked(_text2))
            ) {
                return true;
            }
        }
        return false;
    }

    function setCustomColor(uint256 _tokenId, string memory _pepeColor, string memory _eyeColor, string memory _textColor, string memory _mouthColor) public payable {

        require(_tokenId <= _tokenIdCounter.current(), "No such token id");
        require(msg.sender == ownerOf(_tokenId), "You are not the owner.");
        OnChainTalkingPepeSvg.ImageData memory updatedImage = imageToTokenId[_tokenId];

        if (bytes(_pepeColor).length == 6) {
            updatedImage.pepeColor = _pepeColor;
        }

        if (bytes(_eyeColor).length == 6) {
            updatedImage.eyeColor = _eyeColor;
        }

        if (bytes(_textColor).length == 6) {
            updatedImage.speechBubbleTextColor = _textColor;
        }

        if (bytes(_mouthColor).length == 6) {
            updatedImage.mouthColor = _mouthColor;
        }

        imageToTokenId[_tokenId] = updatedImage;
    }

    function randomNum(
        uint256 _mod,
        uint256 _seed,
        uint256 _salt
    ) public view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(block.timestamp, msg.sender, _seed, _salt)
            )
        ) % _mod;
    }

    function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return OnChainTalkingPepeSvg.buildMetadata(imageToTokenId[_tokenId]);
    }

    function disableMint() public onlyOwner {
        contractLive = false;
    }

    function getMintPrice() public view returns (uint256) {
        
        if(_tokenIdCounter.current()+1 <= FREESUPPLY){
            return 0 ether;
        }
        if(_tokenIdCounter.current()+1 >= LASTCALLSUPPLYLIMIT){
            return LASTCALLMINTPRICE;
        }
        else{
            return MINTPRICE;
        }
    }

    function getNumberOfMintedNfts() public view returns (string memory)  {
        return Strings.toString(_tokenIdCounter.current());
    }

    function withdraw() public payable onlyOwner {
        (bool success,) = payable(msg.sender).call{
        value : address(this).balance
        }("");
        require(success);
    }


    //Opensea contract overrides
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
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