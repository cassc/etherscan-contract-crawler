// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract JigenGenesis is ERC721Enumerable, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;

    uint256 public supply;
    uint256 public maxTokens = 500;
    uint256 public metalockLockPeriod = 28 days;
    uint256 public redeemPrice = 0.03 ether;
    uint256 public maxAmountOwner;
    bool public isRedeemPeriod;
    bool public isRevealed;
    bool public isPaused = true;
    bool public isPublicMint;
    bool public isFrozenMetadata;
    string hiddenUri;
    string baseUri;

    mapping(address => bool) public whitelisted;
    mapping(address => bool) public hasMinted;
    mapping(uint256 => bool) public isRedeemed;
    mapping(uint256 => uint256) metalockStarted;
    mapping(uint256 => uint256) metalockTotal;
    mapping(address => uint256) public adminMint;

    event TokenRedeemed(uint256 tokenId, address redeemer);
    event MetalockStarted(uint256 tokenId);
    event MetalockEnded(uint256 tokenId);
    event TokenExpelled(uint256 tokenId);
    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    modifier onlyUnpaused() {
        require(!isPaused, "Contract is paused");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        string memory _hiddenUri,
        uint256 _maxAmountOwner
    ) ERC721(name_, symbol_) {
        hiddenUri = _hiddenUri;
        maxAmountOwner = _maxAmountOwner;
    }

    //owner-restricted function
    function addWhitelist(address[] memory whitelist) public onlyOwner {
        for (uint256 i = 0; i < whitelist.length; ) {
            whitelisted[whitelist[i]] = true;
            unchecked {
                i++;
            }
        }
    }

    function reveal(string memory _baseUri) public onlyOwner {
        require(!isRevealed, "Already revealed");
        baseUri = _baseUri;
        isRevealed = true;
        emit BatchMetadataUpdate(0, supply);
    }

    function startRedeemPeriod() public onlyOwner {
        isRedeemPeriod = true;
    }

    function endRedeemPeriod(string memory _baseUri) public onlyOwner {
        require(!isFrozenMetadata, "Metadata is frozen");
        isRedeemPeriod = false;
        baseUri = _baseUri;
        emit BatchMetadataUpdate(0, supply);
    }

    function freezeMetadata() public onlyOwner {
        isFrozenMetadata = true;
    }

    function changeUri(string memory _baseUri) public onlyOwner {
        require(!isFrozenMetadata, "Metadata is frozen");
        baseUri = _baseUri;
        emit BatchMetadataUpdate(0, supply);
    }

    function togglePause() public onlyOwner {
        isPaused = !isPaused;
    }

    function togglePublicMint() public onlyOwner {
        isPublicMint = !isPublicMint;
    }

    function withdraw(address payable to) public onlyOwner {
        to.transfer(address(this).balance);
    }

    function changeRedeemPrice(uint256 newPrice) public onlyOwner {
        redeemPrice = newPrice;
    }

    function changeMetalockLockPeriod(uint256 newMetalockLockPeriod) public onlyOwner {
        metalockLockPeriod = newMetalockLockPeriod;
    }

    function safeTransferMetalocked(
        address from,
        address to,
        uint256 tokenId
    ) public onlyOwner {
        super._safeTransfer(from, to, tokenId, "");
    }

    //function for owner to mint
    function ownerMint(uint256 amount) public onlyOwner returns (bool) {
        uint256 adminMintStore = adminMint[msg.sender] + amount;
        require(adminMintStore <= maxAmountOwner, "Admin mint limit exceeded");
        require(supply < maxTokens, "Maximum amount of tokens minted");
        adminMint[msg.sender] = adminMintStore;
        for (uint i = 0; i < amount; i++) {
            _mint(msg.sender, supply);
            supply++;
        }
        return true;
    }

    //public functions
    function mint() public returns (bool) {
        require(!isPaused, "Contract is paused");
        require(supply < maxTokens, "Maximum amount of tokens minted");
        require(!hasMinted[msg.sender], "One mint per address");

        if (!isPublicMint) {
            require(
                whitelisted[msg.sender],
                "Function restricted to whitelisted accounts"
            );
        }

        hasMinted[msg.sender] = true;
        _mint(msg.sender, supply);
        supply++;

        return true;
    }

    function toggleMetalock(uint256 tokenId) public onlyUnpaused {
        require(ownerOf(tokenId) == msg.sender, "Not owner of token");
        if (metalockStarted[tokenId] == 0) {
            metalockStarted[tokenId] = block.timestamp;
            emit MetalockStarted(tokenId);
        } else {
            metalockTotal[tokenId] +=
                block.timestamp -
                metalockStarted[tokenId];
            metalockStarted[tokenId] = 0;
            emit MetalockEnded(tokenId);
        }
    }

    function expel(uint256 tokenId) public onlyOwner {
        require(metalockStarted[tokenId] != 0, "Token not metalocked");
        metalockTotal[tokenId] += block.timestamp - metalockStarted[tokenId];
        metalockStarted[tokenId] = 0;
        emit TokenExpelled(tokenId);
    }

    function redeem(uint256 tokenId) public payable onlyUnpaused {
        require(isRedeemPeriod, "Can't redeem right now");
        require(
            block.timestamp - metalockStarted[tokenId] >= metalockLockPeriod,
            "Metalock period is not over"
        );
        require(
            ownerOf(tokenId) == msg.sender,
            "Function restricted to token owner"
        );
        require(metalockStarted[tokenId] != 0, "Token not metalocked");
        require(!isRedeemed[tokenId], "Token already redeemed");
        require(msg.value == redeemPrice, "Insufficient ETH provided");
        isRedeemed[tokenId] = true;
        emit TokenRedeemed(tokenId, msg.sender);
        emit MetadataUpdate(tokenId);
    }

    modifier isTransferable(uint256 tokenId) {
        require(metalockStarted[tokenId] == 0, "Token currently metalocked");
        _;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) isTransferable(tokenId) onlyAllowedOperator(from){
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) isTransferable(tokenId) onlyAllowedOperator(from){
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) isTransferable(tokenId) onlyAllowedOperator(from){
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    //view functions
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        //revealed
        if (isRevealed) {
            return _tokenURI(tokenId);
            //before reveal
        } else {
            return hiddenUri;
        }
    }

    function getTokensOfAddress(address account)
        public
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(account);
        uint256[] memory ids = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            ids[i] = tokenOfOwnerByIndex(account, i);
        }
        return ids;
    }

    function metalockPeriod(uint256 tokenId)
        external
        view
        returns (
            bool metalock,
            uint256 current,
            uint256 total
        )
    {
        uint256 start = metalockStarted[tokenId];
        if (start != 0) {
            metalock = true;
            current = block.timestamp - start;
        }
        total = current + metalockTotal[tokenId];
    }

    //internals
    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        //unlocked redeemed
        if (isRedeemed[tokenId] && !isRedeemPeriod) {
            return
                string(
                    abi.encodePacked(baseUri, "r", tokenId.toString(), ".json")
                );
            //censored redeemed
        } else if (isRedeemed[tokenId]) {
            return
                string(
                    abi.encodePacked(baseUri, "c", tokenId.toString(), ".json")
                );
            //revealed
        } else {
            return
                string(abi.encodePacked(baseUri, tokenId.toString(), ".json"));
        }
    }
}