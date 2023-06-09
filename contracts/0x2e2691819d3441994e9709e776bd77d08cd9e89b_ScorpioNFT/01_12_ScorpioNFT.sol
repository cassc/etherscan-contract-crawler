// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IScorpioNFT.sol";

// Proxy contracts for OpenSea compatibility
contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

// ERC721 supporting multiple token sets
contract ScorpioNFT is IScorpioNFT, ERC721 {
    using SafeMath for uint32;
    using SafeMath for uint;
    using Strings for uint;

    uint32 public constant MAX_ROYALTY_FEE = 1000; // 100.0%

    mapping(uint => uint) public override internalTokenToProjectId;
    mapping(uint => uint) public override internalTokenToProjectTokenId;
    mapping(uint => uint) public override projectToCurrentTokenId;
    mapping(uint => uint) public override projectToMaxTokenId;
    mapping(uint => uint) public override projectToMintPrice;
    mapping(uint => address) public override projectToRoyaltyAddress;
    mapping(uint => uint) public override projectToRoyaltyFee;
    mapping(uint => uint) public override projectToRoyalties;
    mapping(uint => uint) public override projectToProceeds;
    mapping(uint => bool) public override projectToPreMint;
    mapping(uint => string) private _baseURIs;
    mapping(uint => string) private _tokenURIs;

    address public override owner;
    address public override proxyRegistryAddress;
    uint private _internalTokenId = 0;

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    /**
    * @dev Create the NFT contract from name, symbol, owner
    */
    constructor(
        string memory name_,
        string memory symbol_,
        address owner_,
        address proxy_
    ) ERC721(name_, symbol_) {
        require(owner_ != address(0), "ZERO_OWNER");
        owner = owner_;
        proxyRegistryAddress = proxy_;
    }

    function totalSupply() external view override returns (uint) {
        return _internalTokenId;
    }

    function setupProject(
        uint projectId_,
        uint maxTokenId_,
        uint mintPrice_,
        uint royaltyFee_,
        address royaltyAddress_,
        string memory baseURI_
    ) onlyOwner external override {
        require(projectToMaxTokenId[projectId_] == 0, "PROJECT_ALREADY_SETUP");
        require(maxTokenId_ > 0, "ZERO_MAX_TOKEN_ID");
        require(royaltyFee_ <= MAX_ROYALTY_FEE, "MAX_ROYALTY_EXCEEDED");
        require(royaltyAddress_ != address(0), "ZERO_ROYALTY_ADDRESS");
        require(bytes(baseURI_).length > 0, "EMPTY_BASE_URI");
        projectToMaxTokenId[projectId_] = maxTokenId_;
        projectToMintPrice[projectId_] = mintPrice_;
        projectToRoyaltyFee[projectId_] = royaltyFee_;
        projectToRoyaltyAddress[projectId_] = royaltyAddress_;
        projectToPreMint[projectId_] = true;
        _baseURIs[projectId_] = baseURI_;
    }

    function disablePreMint(uint projectId_) onlyOwner external override {
        projectToPreMint[projectId_] = false;
    }

    function preMint(uint projectId_, uint amount_, address to_)
        onlyOwner external override {
        require(projectToMaxTokenId[projectId_] > 0, "INVALID_PROJECT");
        require(
            projectToCurrentTokenId[projectId_].add(amount_) <= projectToMaxTokenId[projectId_],
            "MAX_SUPPLY"
        );
        require(projectToPreMint[projectId_], "PREMINT_DISABLED");
        for (uint i = 0; i < amount_; i++) {
            uint newTokenId = _getNextTokenId();
            _mint(to_, newTokenId);
            _incrementTokenId(projectId_);
        }
        emit PreMint(projectId_, to_ , amount_);
    }

    /**
     * @dev calculates the next token ID based on value of _internalTokenId
     * @return uint for the next token ID
     */
    function _getNextTokenId() private view returns (uint) {
        return _internalTokenId.add(1);
    }

    /**
     * @dev increments the value of _internalTokenId and corresponding project token ID
     */
    function _incrementTokenId(uint projectId_) private {
        _internalTokenId = _internalTokenId.add(1);
        internalTokenToProjectId[_internalTokenId] = projectId_;
        internalTokenToProjectTokenId[_internalTokenId] = projectToCurrentTokenId[projectId_].add(1);
        projectToCurrentTokenId[projectId_] = internalTokenToProjectTokenId[_internalTokenId];
    }

    function tokenURI(uint tokenId_) public view override returns (string memory) {
        require(_exists(tokenId_), "ERC721Metadata: URI query for nonexistent token");

        if (bytes(_tokenURIs[tokenId_]).length > 0) {
            return _tokenURIs[tokenId_];
        }

        uint projectId = internalTokenToProjectId[tokenId_];
        uint tokenId = internalTokenToProjectTokenId[tokenId_];
        return string(abi.encodePacked(_baseURIs[projectId], tokenId.toString()));
    }

    function setTokenURI(uint tokenId_, string memory uri_) onlyOwner external {
        require(bytes(_tokenURIs[tokenId_]).length == 0, "URI_ALREADY_SET");
        require(bytes(uri_).length > 0, "URI_EMPTY");
        _tokenURIs[tokenId_] = uri_;
    }

    /**
     * Override isApprovedForAll to whitelist user"s OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner_, address operator_)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner_)) == operator_) {
            return true;
        }

        return super.isApprovedForAll(owner_, operator_);
    }

    /**
    * @dev Function to transfer sales proceeds to owner
    */
    function withdrawProceeds(uint projectId_) external override {
        payable(owner).transfer(projectToProceeds[projectId_]);
        emit WithdrawProceeds(projectId_, projectToProceeds[projectId_]);
        projectToProceeds[projectId_] = 0;
    }

    /**
    * @dev Function to transfer sales royalties to beneficiary
    */
    function withdrawRoyalties(uint projectId_) external override {
        payable(projectToRoyaltyAddress[projectId_]).transfer(projectToRoyalties[projectId_]);
        emit WithdrawRoyalties(projectId_, projectToRoyalties[projectId_]);
        projectToRoyalties[projectId_] = 0;
    }

    function mint(uint projectId_, address to_) external payable override returns (uint tokenId_) {
        require(projectToMaxTokenId[projectId_] > 0, "PROJECT_NOT_SETUP");
        require(projectToPreMint[projectId_] == false, "PREMINT_ENABLED");
        require(projectToCurrentTokenId[projectId_] < projectToMaxTokenId[projectId_], "MAX_SUPPLY_MINTED");
        uint mintPrice = projectToMintPrice[projectId_];
        require(msg.value >= mintPrice, "MINT_PRICE_NOT_MET");
        // Mint a new token to the recipient
        tokenId_ = _getNextTokenId();
        _mint(to_, tokenId_);
        _incrementTokenId(projectId_);
        // calculate royalties and tally up
        uint royaltyFee = mintPrice.mul(projectToRoyaltyFee[projectId_]).div(1000);
        projectToRoyalties[projectId_] = projectToRoyalties[projectId_].add(royaltyFee);
        // update proceeds
        projectToProceeds[projectId_] = projectToProceeds[projectId_].add(msg.value).sub(royaltyFee);
        emit Mint(projectId_, tokenId_, projectToCurrentTokenId[projectId_], mintPrice, to_);
    }
}