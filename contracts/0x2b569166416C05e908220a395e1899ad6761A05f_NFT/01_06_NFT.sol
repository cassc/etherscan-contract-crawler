// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFT is ERC721A, Ownable {
    uint256 public MAX_SUPPLY = 8000;
    uint256 public MAX_WHITE_SUPPLY = 2000;
    bool public metadataFrozen = false;
    uint256 public NFT_PRICE_FOR_WL = 0.1 ether;
    uint256 public NFT_PRICE_FOR_1 = 0.14 ether;
    uint256 public NFT_PRICE_FOR_3 = 0.36 ether;
    uint256 public NFT_PRICE_FOR_9 = 0.9 ether;
    uint256 public NFT_PRICE_FOR_18 = 1.44 ether;
    string public ghostTokenURI = "https://respic.never-soft.com/shiny_girl_card/Mysterybox.json";
    string public baseTokenURI = "https://cumgun.never-soft.com/api/nft/metadata/";
    bool public isPublicSaleActive = false;
    bool public isWhiteListActive = false;
    bool public isRevealActive = false;
    bool public isBurnActive = false;
    string private _name = "Shiny Girl Card";
    string private _symbol = "SGC";
    string private _contractURI = "https://respic.never-soft.com/shiny_girl_card/Contract.json";
    mapping(address => uint8) private _whiteList;

    constructor() ERC721A(_name, _symbol) {}

    receive() external payable {}

    /** GETTERS **/

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory)
    {
        if (isRevealActive) {
            return
                string(
                    abi.encodePacked(
                        baseTokenURI,
                        Strings.toString(_tokenId),
                        ".json"
                    )
                );
        }
        return string(abi.encodePacked(ghostTokenURI));
    }

    function renounceOwnership() public view override onlyOwner {
        revert("can't renounceOwnership here");
    }

    /** SETTERS **/

    function freezeMetaData() public onlyOwner {
        metadataFrozen = true;
    }
    
    function setContractURI(string memory uri) public onlyOwner {
        _contractURI = uri;
    }

    function setGhostURI(string memory _uri) external onlyOwner notFrozenMetaData
    {
        ghostTokenURI = _uri;
    }

    function setBaseUri(string memory _uri) external onlyOwner notFrozenMetaData
    {
        baseTokenURI = _uri;
    }

    function setIsPublicSaleActive(bool _isPublicSaleActive) external onlyOwner
    {
        isPublicSaleActive = _isPublicSaleActive;
    }

    function setIsWhiteListActive(bool _isWhiteListActive) external onlyOwner {
        isWhiteListActive = _isWhiteListActive;
    }

    function setIsRevealActive(bool _isRevealActive) external onlyOwner {
        isRevealActive = _isRevealActive;
    }

    function setIsBurnActive(bool _isBurnActive) external onlyOwner {
        isBurnActive = _isBurnActive;
    }

    function setWhiteList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whiteList[addresses[i]] = numAllowedToMint;
        }
    }

    modifier notFrozenMetaData() {
        require(!metadataFrozen, "The metadata is already frozen");
        _;
    }

    /** WL MINT **/

    modifier mintHasStarted() {
        require(isPublicSaleActive, "It's not time yet");
        _;
    }

    function numAvailableToMint(address addr) external view returns (uint8) {
        return _whiteList[addr];
    }

    function mintWhiteList(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(isWhiteListActive, "Allow list is not active");
        require(
            numberOfTokens <= _whiteList[msg.sender],
            "Exceeded max available to purchase"
        );
        require(
            ts + numberOfTokens <= MAX_WHITE_SUPPLY,
            "Purchase would exceed whitelist max tokens"
        );
        require(
            NFT_PRICE_FOR_WL * numberOfTokens == msg.value,
            "Ether value sent is not correct"
        );

        _whiteList[msg.sender] -= numberOfTokens;
        buyAmount(numberOfTokens);
    }

     /** MINT **/

    function buyOne() external payable mintHasStarted {
        require(msg.value == NFT_PRICE_FOR_1, "Wrong amount for 1");
        buyAmount(1);
    }

    function buyThree() public payable mintHasStarted {
        require(msg.value == NFT_PRICE_FOR_3, "Wrong amount for 3");
        buyAmount(3);
    }

    function buyNine() public payable mintHasStarted {
        require(msg.value == NFT_PRICE_FOR_9, "Wrong amount for 9");
        buyAmount(9);
    }

    function buyEighteen() public payable mintHasStarted {
        require(msg.value == NFT_PRICE_FOR_18, "Wrong amount for 18");
        buyAmount(18);
    }

    function buyAmount(uint256 count) internal {
        require(
            totalSupply() + count < MAX_SUPPLY,
            "Max Public Supply Reached"
        );
        _safeMint(_msgSender(), count);
        uint256 fee = (msg.value * 2) / 10;
        payable(owner()).transfer(fee);
    }

    /** BURN **/
    function burn(uint256 tokenId) public returns (uint256) {
        require(isBurnActive, "Allow burn is not active");
        uint256 refund = address(this).balance / totalSupply();
        uint256 fee = (refund * 2) / 10;
        uint256 realRefund = refund - fee;
        _burn(tokenId, true);
        payable(owner()).transfer(fee);
        payable(msg.sender).transfer(realRefund);
        return realRefund;
    }
}