// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./erc721a/contracts/ERC721A.sol";
import "./operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Fatzuki is
    Ownable,
    ERC721A("Fatzuki", "Fatzuki"),
    DefaultOperatorFilterer,
    ReentrancyGuard
{
    /**
     * @dev Emitted when mint by public.
     */
    event PublicMint(address indexed accounts, uint16 indexed nums);

    /**
     * @dev Emitted when mint by whitelist.
     */
    event WhiteListMint(
        bytes indexed ticket,
        bytes indexed signature,
        uint16 indexed quantity
    );

    using ECDSA for bytes32;

    uint16 public constant MAX_AMOUNT = 10000;
    uint16 public constant TEAM_AMOUNT = 350;
    uint16 public constant WHITE_LIST_AMOUNT = 3000;
    uint16 public constant MAX_PUBLIC_MINT_AMOUNT = 5;
    uint16 public constant MAX_WHITE_LIST_MINT_AMOUNT = 3;

    uint16 public teamRemainCount = TEAM_AMOUNT;
    uint16 public publicAmount;
    uint16 public publicRemainCount;
    uint16 public whiteListRemainCount = WHITE_LIST_AMOUNT;

    address private signerAddress;
    mapping(bytes => bool) _ticketUsed;

    uint8 public mintStatus = 2;

    struct PublicMintConfig {
        uint32 startTime;
        uint32 endTime;
        uint256 price;
    }
    PublicMintConfig public publicMintConfig;

    struct WhitelistMintConfig {
        uint32 startTime;
        uint32 endTime;
        uint256 price;
    }
    WhitelistMintConfig public whitelistMintConfig;

    mapping(address => uint16) publicMintList;
    mapping(address => uint16) whiteListMintList;

    // Metadata URI
    string public baseTokenURI;
    string public notRevealedURI;
    string public baseExtension = ".json";
    bool public isRevealed = false;

    // -------
    // Owner Functions
    // -------
    function setBaseURI(string calldata _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setNotRevealedURI(string calldata _notRevealedURI)
        public
        onlyOwner
    {
        notRevealedURI = _notRevealedURI;
    }

    function setBaseExtension(string calldata _baseExtension) public onlyOwner {
        baseExtension = _baseExtension;
    }

    function setRevealed(bool _isRevealed) public onlyOwner {
        isRevealed = _isRevealed;
    }

    function updateMintStatus(uint8 status) public onlyOwner {
        mintStatus = status;
        if (mintStatus == 0) {
            publicAmount =
                MAX_AMOUNT -
                TEAM_AMOUNT -
                (WHITE_LIST_AMOUNT - whiteListRemainCount);

            publicRemainCount = publicAmount;
        }
    }

    function setSignerAddress(address addr) external onlyOwner {
        require(addr != address(0), "Invalid address");
        signerAddress = addr;
    }

    function setPublicMintConfig(
        uint32 startTimestamp,
        uint32 endTimestamp,
        uint256 price
    ) external onlyOwner {
        publicMintConfig = PublicMintConfig(
            startTimestamp,
            endTimestamp,
            price
        );
    }

    function setWhitelistMintConfig(
        uint32 startTimestamp,
        uint32 endTimestamp,
        uint256 price
    ) external onlyOwner {
        whitelistMintConfig = WhitelistMintConfig(
            startTimestamp,
            endTimestamp,
            price
        );
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }

    // -------
    // Mint function
    // -------
    function ownerMint(address[] memory accounts, uint16[] memory nums)
        public
        onlyOwner
    {
        require(
            accounts.length > 0 && accounts.length == nums.length,
            "Length not match"
        );

        uint16 mintNum = 0;
        for (uint256 i = 0; i < accounts.length; i++) {
            mintNum += nums[i];
        }

        require(teamRemainCount - mintNum >= 0, "No more NFT");

        teamRemainCount -= mintNum;
        for (uint256 i = 0; i < accounts.length; i++) {
            _safeMint(accounts[i], nums[i]);
        }
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function publicMint(address to, uint16 quantity)
        external
        payable
        callerIsUser
    {
        require(mintStatus == 0, "Invalid mint");

        require(to != address(0), "Invalid address");

        PublicMintConfig memory config = publicMintConfig;
        uint256 _startTime = uint256(config.startTime);
        require(
            _startTime != 0 && block.timestamp >= _startTime,
            "Mint has not started yet"
        );
        uint256 _EndTime = uint256(config.endTime);
        require(
            _EndTime != 0 && block.timestamp < _EndTime,
            "Mint has done yet"
        );

        uint16 _mintedNum = publicMintList[to];
        require(
            MAX_PUBLIC_MINT_AMOUNT - _mintedNum >= quantity,
            "No more NFT limit"
        );

        require(publicRemainCount >= quantity, "No more NFT");

        uint256 _price = uint256(config.price);
        require(msg.value >= _price * quantity, "Insufficient value");

        publicRemainCount -= quantity;
        addToPublicMintlist(to, quantity);
        _safeMint(to, quantity);

        emit PublicMint(to, quantity);
    }

    function addToPublicMintlist(address users, uint16 quantity) private {
        publicMintList[users] += quantity;
    }

    function whiteListMint(
        bytes memory ticket,
        bytes memory signature,
        uint16 quantity
    ) external payable callerIsUser {
        require(mintStatus == 1, "Invalid mint");

        WhitelistMintConfig memory config = whitelistMintConfig;
        uint256 _StartTime = uint256(config.startTime);
        require(
            _StartTime != 0 && block.timestamp >= _StartTime,
            "Mint has not started yet"
        );
        uint256 _EndTime = uint256(config.endTime);
        require(
            _EndTime != 0 && block.timestamp < _EndTime,
            "Mint has done yet"
        );

        require(!_ticketUsed[ticket], "Ticket has been used");

        require(isAuthorized(ticket, signature), "Invalid ticket");

        uint16 _mintedNum = getWhiteListMinted(_msgSender());
        require(
            MAX_WHITE_LIST_MINT_AMOUNT - _mintedNum >= quantity,
            "No more NFT limit"
        );

        require(whiteListRemainCount >= quantity, "No more NFT");

        uint256 _price = uint256(config.price);
        require(msg.value >= _price * quantity, "Insufficient value");

        whiteListRemainCount -= quantity;
        addToWhiteListMintlist(_msgSender(), quantity);
        _safeMint(_msgSender(), quantity);

        emit WhiteListMint(ticket, signature, quantity);
    }

    function isAuthorized(bytes memory ticket, bytes memory signature)
        private
        view
        returns (bool)
    {
        bytes32 _hash = keccak256(abi.encodePacked(ticket));
        bytes32 _ethSignedMessageHash = ECDSA.toEthSignedMessageHash(_hash);

        address addr = _ethSignedMessageHash.recover(signature);
        return signerAddress == addr;
    }

    function addToWhiteListMintlist(address users, uint16 quantity) private {
        whiteListMintList[users] += quantity;
    }

    function getWhiteListMinted(address addr) public view returns (uint16) {
        require(addr != address(0), "Invalid address");
        return whiteListMintList[addr];
    }

    // -------
    // Internal Overrides
    // -------
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // -------
    // Metadata Reveal Override
    // -------
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721aMetadata: URI query for nonexistent token"
        );
        if (!isRevealed) {
            return notRevealedURI;
        }
        return
            string(
                abi.encodePacked(
                    baseTokenURI,
                    _toString(_tokenId),
                    baseExtension
                )
            );
    }

    // -------
    // Opensea OperatorFilterer Overrides
    // -------
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}