// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./lib/ERC721A.sol";
import "./lib/rarible/royalties/contracts/LibPart.sol";
import "./lib/rarible/royalties/contracts/LibRoyaltiesV2.sol";
import "./lib/rarible/royalties/contracts/RoyaltiesV2.sol";

contract TokyoBraveHeroes is ERC721A, Ownable, ReentrancyGuard, RoyaltiesV2 {

    mapping(address => uint256) public _whiteLists;
    uint256 private _whiteListCount;

    uint256 public tokenAmount = 0;
    uint256 public wlmintPrice = 0.03 ether;
    uint256 public mintPrice = 0.04 ether;

    bool public startWhitelistSale = false;
    bool public startPublicSale = false;
    bool public changed = false;

    uint256 private maxMintsWL = 5;
    uint256 private maxMints = 10;
    uint256 private _totalSupply = 2222;
    string private _beforeTokenURI;
    string private _afterTokenPath;

    mapping(address => uint256) public wlMinted;
    mapping(address => uint256) public psMinted;

    // Royality management
    bytes4 public constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    address payable public defaultRoyaltiesReceipientAddress;  // This will be set in the constructor
    uint96 public defaultPercentageBasisPoints = 1000;  // 10%

    constructor () ERC721A ("TokyoBraveHeroes", "TBH", maxMints, _totalSupply) {
        defaultRoyaltiesReceipientAddress = payable(address(this));
    }

    function ownerMint(uint256 amount, address _address) public onlyOwner { 
        require((amount + tokenAmount) <= (_totalSupply), "mint failure");

        _safeMint(_address, amount);
        tokenAmount += amount;
    }

    function privateMint(uint256 amount) external payable nonReentrant {
        require(startWhitelistSale, "sale: Paused");
        require(_whiteLists[msg.sender] >= wlMinted[msg.sender] + amount, "You have no wl left");
        require(maxMintsWL >= amount, "sale: 5 max per tx");
        require(maxMintsWL >= wlMinted[msg.sender] + amount, "You have no mint left");
        require(msg.value == wlmintPrice * amount, "Value sent is not correct");
        require((amount + tokenAmount) <= (_totalSupply), "mint failure");

        wlMinted[msg.sender] += amount;
        _safeMint(msg.sender, amount);
        tokenAmount += amount;
    }

    function publicMint(uint256 amount) public payable nonReentrant {
        require(startPublicSale, "sale: Paused");
        require(maxMints >= amount, "sale: 10 maxper tx");
        require(maxMints >= psMinted[msg.sender] + amount, "You have no mint left");
        require(msg.value == mintPrice * amount, "Value sent is not correct");
        require((amount + tokenAmount) <= (_totalSupply), "mint failure");
         
        psMinted[msg.sender] += amount;
        _safeMint(msg.sender, amount);
        tokenAmount += amount;
    }

    function setwlPrice(uint256 newPrice) external onlyOwner {
        wlmintPrice = newPrice;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    function doChange() external onlyOwner {
        changed = true;
    }
    
    function setWhitelistSale(bool bool_) external onlyOwner {
        startWhitelistSale = bool_;
    }

    function setPublicSale(bool bool_) external onlyOwner {
        startPublicSale = bool_;
    }

    function setBeforeURI(string memory beforeTokenURI_) public onlyOwner {
        _beforeTokenURI = string(abi.encodePacked(beforeTokenURI_, "before.json"));
    }

    function setAfterURI(string memory afterTokenPath_) public onlyOwner {
        _afterTokenPath = afterTokenPath_;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(changed == false) {
            return _beforeTokenURI;
        } else {
            return string(abi.encodePacked(_afterTokenPath, Strings.toString(tokenId), ".json"));
        }
    }

    function deleteWL(address addr)
        public
        virtual
        onlyOwner
    {
        _whiteListCount = _whiteListCount - _whiteLists[addr];
        delete(_whiteLists[addr]);
    }

    function upsertWL(address addr, uint256 maxMint)
        public
        virtual
        onlyOwner
    {
        _whiteListCount = _whiteListCount - _whiteLists[addr];
        _whiteLists[addr] = maxMint;
        _whiteListCount = _whiteListCount + maxMint;
    }

    function pushMultiWL(address[] memory list)
        public
        virtual
        onlyOwner
    {
        for (uint i = 0; i < list.length; i++) {
            _whiteLists[list[i]] += 5;
            _whiteListCount += 5;
        }
    }

    function getWLCount()
        public
        view
        returns(uint256)
    {
        return _whiteListCount;
    }

    /**
     * @dev disable Ownerble renounceOwnership
     */
    function renounceOwnership() public onlyOwner override {}

    /**
     * @dev do withdraw eth.
     */
    function withdrawETH()
        external
        virtual
        onlyOwner
    {
        uint256 royalty = address(this).balance;

        Address.sendValue(payable(owner()), royalty);
    }

    // Copied from ForgottenRunesWarriorsGuild. Thank you dotta ;)
    /**
     * @dev ERC20s should not be sent to this contract, but if someone
     * does, it's nice to be able to recover them
     * @param token IERC20 the token address
     * @param amount uint256 the amount to send
     */
    function forwardERC20s(IERC20 token, uint256 amount) public onlyOwner {
        require(address(msg.sender) != address(0));
        token.transfer(msg.sender, amount);
    }

    // Royality management
    /**
     * @dev set defaultRoyaltiesReceipientAddress
     * @param _defaultRoyaltiesReceipientAddress address New royality receipient address
     */
    function setDefaultRoyaltiesReceipientAddress(address payable _defaultRoyaltiesReceipientAddress) public onlyOwner {
        defaultRoyaltiesReceipientAddress = _defaultRoyaltiesReceipientAddress;
    }

    /**
     * @dev set defaultPercentageBasisPoints
     * @param _defaultPercentageBasisPoints uint96 New royality percentagy basis points
     */
    function setDefaultPercentageBasisPoints(uint96 _defaultPercentageBasisPoints) public onlyOwner {
        defaultPercentageBasisPoints = _defaultPercentageBasisPoints;
    }

    /**
     * @dev return royality for Rarible
     */
    function getRaribleV2Royalties(uint256) external view override returns (LibPart.Part[] memory) {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = defaultPercentageBasisPoints;
        _royalties[0].account = defaultRoyaltiesReceipientAddress;
        return _royalties;
    }

    /**
     * @dev return royality in EIP-2981 standard
     * @param _salePrice uint256 sales price of the token royality is calculated
     */
    function royaltyInfo(uint256, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return (defaultRoyaltiesReceipientAddress, (_salePrice * defaultPercentageBasisPoints) / 10000);
    }

    /**
     * @dev Interface
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}