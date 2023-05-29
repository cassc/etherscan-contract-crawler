// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@erc721a/contracts/ERC721A.sol";

interface IERC721Like {
    function ownerOf(uint256) external view returns (address);

    function balanceOf(address) external view returns (uint256);
}

interface ICryptoPunks {
    function punkIndexToAddress(uint256) external returns (address);
}

contract HitchHikerOfStar is ERC721A, Ownable {
    uint256 public blocksPerHalfHour;

    uint256 public freeMintMaxAmount;
    uint256 public dutchAuctionMintMaxAmount;
    uint256 public whiteListMintMaxAmount;

    uint256 public remainingAmount;

    uint256 public preMintAmount;
    uint256 public preMintRemaining;

    uint256 public decayFactor;
    address[] public freeMintCriteria;
    address public cryptoPunksAddress;
    mapping(address => bool) public isFreeMintCriteria;

    mapping(bytes32 => bool) public freeMintClaimed;
    mapping(address => uint256) public totalClaimed;
    mapping(address => bool) public whiteListClaimed;
    mapping(address => bool) public isFreeWhiteList;

    uint256 public freeMinted;
    uint256 public dutchAuctionMinted;
    uint256 public whiteListMinted;

    bytes32 public merkleRoot;
    uint256 public whiteListMintPrice;

    uint256 public freeMintEndTime;
    uint256 public dutchAuctionMintEndTime;
    uint256 public whiteListMintEndTime;

    uint256 public dutchAuctionInitialPrice;
    uint256 public dutchAuctionFloorPrice;
    uint256 public dutchAuctionStartBlockNumber;

    string public placeholderTokenURI;
    string public freeMintBaseTokenURI;
    string public dutchAuctionBaseTokenURI;
    string public whiteListMintBaseTokenURI;

    ////////////////////////////////////////////////////////////
    ///           custom errors
    /////////////////////////////////////////////////////////////
    error Error_AlreadyClaimed();
    error Error_InvalidMintTime();
    error Error_InvalidMerkleProof();
    error Error_InsufficientFunds();
    error Error_MintExcessAllowance();
    error Error_MintCriteriaNotSet();
    error Error_InvalidAsset();
    error Error_NotOwner();

    constructor(string memory name, string memory symbol)
        ERC721A(name, symbol)
    {}

    function freeMint(address to, address asset, uint256 tokenId) external {
        if (freeMintEndTime == 0 || freeMintEndTime < block.timestamp) {
            revert Error_InvalidMintTime();
        }

        bytes32 key = keccak256(abi.encode(asset, tokenId));
        if (freeMintClaimed[key]) {
            revert Error_AlreadyClaimed();
        }

        if (freeMinted >= freeMintMaxAmount) {
            revert Error_MintExcessAllowance();
        }

        if (!isFreeMintCriteria[asset]) {
            revert Error_InvalidAsset();
        }

        if (asset == cryptoPunksAddress) {
            if (ICryptoPunks(asset).punkIndexToAddress(tokenId) != to) revert Error_NotOwner();
        } else {
            if (IERC721Like(asset).ownerOf(tokenId) != to) revert Error_NotOwner();
        }

        freeMinted += 1;
        totalClaimed[to] += 1;
        freeMintClaimed[key] = true;
        _safeMint(to, 1);
    }

    function dutchAuctionMint(address to, uint256 amount) external payable {
        if (dutchAuctionMintEndTime == 0 || dutchAuctionMintEndTime < block.timestamp) {
            revert Error_InvalidMintTime();
        }

        if (dutchAuctionMinted + amount > dutchAuctionMintMaxAmount) {
            revert Error_MintExcessAllowance();
        }

        uint256 mintPrice = getDutchMintPrice();

        uint256 expectedEther = mintPrice * amount;
        if (expectedEther > msg.value) {
            revert Error_InsufficientFunds();
        }

        if (expectedEther < msg.value) {
            payable(msg.sender).transfer(msg.value - expectedEther);
        }

        dutchAuctionMinted += amount;
        _safeMint(to, amount);
    }

    function whiteListMint(
        address to,
        uint256 amount,
        bytes32[] calldata merkleProof
    )
        external
        payable
    {
        if (whiteListMintEndTime == 0 || whiteListMintEndTime < block.timestamp) {
            revert Error_InvalidMintTime();
        }

        if (whiteListClaimed[to]) {
            revert Error_AlreadyClaimed();
        }

        if (whiteListMinted + amount > whiteListMintMaxAmount) {
            revert Error_MintExcessAllowance();
        }

        uint256 expectedEther;
        if (!isFreeWhiteList[to]) {
            expectedEther = amount * whiteListMintPrice;
        }

        if (expectedEther > msg.value) {
            revert Error_InsufficientFunds();
        }

        if (expectedEther < msg.value) {
            payable(msg.sender).transfer(msg.value - expectedEther);
        }

        bytes32 leaf = keccak256(abi.encode(to, amount));
        if (!MerkleProof.verify(merkleProof, merkleRoot, leaf)) {
            revert Error_InvalidMerkleProof();
        }

        whiteListClaimed[to] = true;
        whiteListMinted += amount;

        _safeMint(to, amount);
    }

    ////////////////////////////////////////////////////////////
    ///           admin functions
    /////////////////////////////////////////////////////////////
    function setFreeMintMaxAmount(uint256 amount) external onlyOwner {
        freeMintMaxAmount = amount;
    }

    function setDutchAuctionMintMaxAmount(uint256 amount)
        external
        onlyOwner
    {
        dutchAuctionMintMaxAmount = amount;
    }

    function setWhiteListMintMaxAmount(uint256 amount) external onlyOwner {
        whiteListMintMaxAmount = amount;
    }

    function setPreMintAmount(uint256 amount) public onlyOwner {
        preMintAmount = amount;
    }

    function preMint(address to, uint256 amount) public onlyOwner {
        if (preMintRemaining + amount > preMintAmount) {
            revert Error_MintExcessAllowance();
        }

        preMintRemaining += amount;
        _safeMint(to, amount);
    }

    // called when three phases have been finished.
    function mintRemaining(address to, uint256 amount) external onlyOwner {
        uint256 remaining = maxMintAmount() - totalMinted();

        if (remainingAmount + amount > remaining) {
            revert Error_MintExcessAllowance();
        }

        remainingAmount += amount;
        _safeMint(to, amount);
    }

    function setFreeWhiteList(address[] calldata list) external onlyOwner {
        for (uint256 i; i < list.length; ++i) {
            isFreeWhiteList[list[i]] = true;
        }
    }

    function setBlocksPerHalfHour(uint256 blocks) external onlyOwner {
        blocksPerHalfHour = blocks;
    }

    function setDecayFactor(uint256 factor) external onlyOwner {
        decayFactor = factor;
    }

    function startFreeMint(uint256 duration) external onlyOwner {
        freeMintEndTime = block.timestamp + duration;
    }

    function addFreeMintCriteria(address[] memory criteria)
        external
        onlyOwner
    {
        for (uint256 i; i < criteria.length; ++i) {
            freeMintCriteria.push(criteria[i]);
            isFreeMintCriteria[criteria[i]] = true;
        }
    }

    function delFreeMintCriteria(uint256 index) external onlyOwner {
        uint256 len = freeMintCriteria.length;
        for (uint256 i; i < len; ++i) {
            if (i == index) {
                freeMintCriteria[i] = freeMintCriteria[len - 1];
                isFreeMintCriteria[freeMintCriteria[i]] = false;
                freeMintCriteria.pop();
                break;
            }
        }
    }

    function setCryptoPunksAddress(address _cryptoPunksAddress)
        external
        onlyOwner
    {
        cryptoPunksAddress = _cryptoPunksAddress;
        freeMintCriteria.push(_cryptoPunksAddress);
        isFreeMintCriteria[_cryptoPunksAddress] = true;
    }

    function startDutchAuctionMint(
        uint256 duration,
        uint256 initialPrice,
        uint256 floorPrice
    )
        external
        onlyOwner
    {
        dutchAuctionMintEndTime = block.timestamp + duration;
        dutchAuctionStartBlockNumber = block.number;
        dutchAuctionInitialPrice = initialPrice;
        dutchAuctionFloorPrice = floorPrice;
    }

    function startWhiteListMint(
        uint256 duration,
        uint256 mintPrice,
        bytes32 _merkleRoot
    )
        external
        onlyOwner
    {
        whiteListMintEndTime = block.timestamp + duration;
        whiteListMintPrice = mintPrice;
        merkleRoot = _merkleRoot;
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        payable(to).transfer(amount);
    }

    function setPlaceholderTokenURI(string memory placeholder)
        public
        onlyOwner
    {
        placeholderTokenURI = placeholder;
    }

    function setFreeMintBaseTokenURI(string memory _baseUri)
        public
        onlyOwner
    {
        freeMintBaseTokenURI = _baseUri;
    }

    function setDutchAuctionBaseTokenURI(string memory _baseUri)
        public
        onlyOwner
    {
        dutchAuctionBaseTokenURI = _baseUri;
    }

    function setWhiteListMintBaseTokenURI(string memory _baseUri)
        public
        onlyOwner
    {
        whiteListMintBaseTokenURI = _baseUri;
    }

    ////////////////////////////////////////////////////////////
    ///           view functions
    /////////////////////////////////////////////////////////////
    function totalMinted() public view returns (uint256) {
        return freeMinted + dutchAuctionMinted + whiteListMinted;
    }

    function maxMintAmount() public view returns (uint256) {
        return freeMintMaxAmount + dutchAuctionMintMaxAmount + whiteListMintMaxAmount;
    }

    function getDutchMintPrice() public view returns (uint256 mintPrice) {
        uint256 declinedPrice = (block.number - dutchAuctionStartBlockNumber) /
            blocksPerHalfHour
            * decayFactor;
        if (dutchAuctionInitialPrice > declinedPrice) {
            mintPrice = dutchAuctionInitialPrice - declinedPrice;
        }

        if (mintPrice < dutchAuctionFloorPrice) {
            mintPrice = dutchAuctionFloorPrice;
        }
    }

    function getFreeMintCriteria() external view returns (address[] memory) {
        return freeMintCriteria;
    }

    function getFreeMintRemaining(address who)
        external
        view
        returns (uint256)
    {
        uint256 total;
        uint256 len = freeMintCriteria.length;
        for (uint256 i; i < len; ++i) {
            total += IERC721Like(freeMintCriteria[i]).balanceOf(who);
        }

        return total - totalClaimed[who];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseUri = getBaseURI(tokenId);
        return
            bytes(baseUri).length > 0
                ? string.concat(baseUri, Strings.toString(tokenId))
                : placeholderTokenURI;
    }

    ////////////////////////////////////////////////////////////
    ///           internal functions
    /////////////////////////////////////////////////////////////
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function getBaseURI(uint256 tokenId)
        internal
        view
        returns (string memory baseUri)
    {
        if (tokenId > 0 && tokenId <= preMintAmount) {
            return freeMintBaseTokenURI;
        }

        tokenId = tokenId - preMintAmount;

        if (tokenId > 0 && tokenId <= freeMinted) {
            baseUri = freeMintBaseTokenURI;
        } else if (tokenId > freeMinted && tokenId <= freeMinted + dutchAuctionMinted) {
            baseUri = dutchAuctionBaseTokenURI;
        } else if (
            tokenId > freeMinted + dutchAuctionMinted &&
            tokenId <= freeMinted + dutchAuctionMinted + whiteListMinted
        ) {
            baseUri = whiteListMintBaseTokenURI;
        } else {
            baseUri = "";
        }
    }

    ////////////////////////////////////////////////////////////
    ///           Used for test
    /////////////////////////////////////////////////////////////
    function setPhaseOneMinted(uint256 amount) internal {
        freeMinted = amount;
    }

    function setPhaseTwoMinted(uint256 amount) internal {
        dutchAuctionMinted = amount;
    }

    function setPhaseThreeMinted(uint256 amount) internal {
        whiteListMinted = amount;
    }
}