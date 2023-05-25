// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";

interface RuggedCommunityERC721Interface {
    function balanceOf(address owner) external view returns (uint256);
}

interface RuggedCommunityERC1155Interface {
    function balanceOf(address owner, uint256 id)
        external
        view
        returns (uint256);
}

contract ApeReunion is Ownable, ERC721A, ReentrancyGuard {
    string private _baseTokenURI;
    address public ruggedERC721ContractAddress;
    address public ruggedERC1155ContractAddress;
    uint256 public immutable maxPerWallet;
    uint256 public immutable maxSupply;
    uint256 public amountForDevs;
    uint256 public amountForPublic;
    uint256 public mintEndTime;
    mapping(address => uint256) public reunionList;

    constructor(
        uint256 maxPerWallet_,
        uint256 maxSupply_,
        uint256 amountForDevs_,
        uint256 amountForPublic_,
        string memory placeholderUri_
    ) ERC721A("Ape Reunion", "APE_REUNION") {
        maxPerWallet = maxPerWallet_;
        maxSupply = maxSupply_;
        amountForDevs = amountForDevs_;
        amountForPublic = amountForPublic_;
        _baseTokenURI = placeholderUri_;
    }

    modifier callerIsUser() {
        require(
            tx.origin == msg.sender,
            "Transaction origin is not the message sender"
        );
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // minting functions
    function reunionListMint(uint256 quantity) external callerIsUser {
        require(
            reunionList[msg.sender] >= quantity,
            "Not eligible for reunionlist mint"
        );
        require(
            totalSupply() + quantity + amountForDevs <= maxSupply,
            "Mint over max supply"
        );
        reunionList[msg.sender] = reunionList[msg.sender] - quantity;
        _safeMint(msg.sender, quantity);
    }

    // alternative allowList mint using erc721a aux data
    function reunionListMintAux(uint64 quantity) external callerIsUser {
        require(
            _getAux(msg.sender) >= quantity,
            "Not eligible for reunionlist aux mint"
        );
        require(
            totalSupply() + quantity + amountForDevs <= maxSupply,
            "Mint over max supply"
        );

        uint64 newQuantity = _getAux(msg.sender) - quantity;
        _setAux(msg.sender, newQuantity);
        _safeMint(msg.sender, quantity);
    }

    function rugVictimMintERC721(uint256 quantity) external callerIsUser {
        require(
            ownsRuggedERC721Token(),
            "Does not own rugged erc721 community token"
        );
        require(
            totalSupply() + quantity + amountForDevs + amountForPublic <=
                maxSupply,
            "Mint over max supply"
        );
        require(
            numberMinted(msg.sender) + quantity <= maxPerWallet,
            "Mint over max per wallet"
        );

        _safeMint(msg.sender, quantity);
    }

    function rugVictimMintERC1155(uint256 quantity, uint256 tokenId)
        external
        callerIsUser
    {
        require(
            ownsRuggedERC1155Token(tokenId),
            "Does not own rugged erc1155 community token"
        );
        require(
            totalSupply() + quantity + amountForDevs + amountForPublic <=
                maxSupply,
            "Mint over max supply"
        );
        require(
            numberMinted(msg.sender) + quantity <= maxPerWallet,
            "Mint over max per wallet"
        );

        _safeMint(msg.sender, quantity);
    }

    function mint(uint256 quantity) external callerIsUser {
        require(block.timestamp < mintEndTime, "Minting is not live");
        require(
            totalSupply() + quantity + amountForDevs <= maxSupply,
            "Mint over max supply"
        );
        require(
            numberMinted(msg.sender) + quantity <= maxPerWallet,
            "Mint over max per wallet"
        );

        _safeMint(msg.sender, quantity);
    }

    // ownerOnly contract interactions
    function ownerMint(uint256 quantity) external onlyOwner {
        require(quantity <= amountForDevs, "Mint over max for devs");
        require(totalSupply() + quantity <= maxSupply, "Mint over max supply");
        require(
            quantity % maxPerWallet == 0,
            "Can only mint a multiple of the maxBatchSize"
        );
        uint256 numChunks = quantity / maxPerWallet;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxPerWallet);
        }
    }

    function seedReunionList(
        address[] memory addresses,
        uint256[] memory numSlots
    ) external onlyOwner {
        require(
            addresses.length == numSlots.length,
            "Addresses does not match numSlots length"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            reunionList[addresses[i]] = numSlots[i];
        }
    }

    // alternate allowList implementation based on erc721a docs
    function seedReunionListAux(
        address[] memory addresses,
        uint64[] memory numSlots
    ) external onlyOwner {
        require(
            addresses.length == numSlots.length,
            "Addresses does not match numSlots length"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            _setAux(addresses[i], numSlots[i]);
        }
    }

    // erc721 and ownable specific
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    // ape reunion specific
    function setAmountForDevs(uint256 amount) external onlyOwner {
        amountForDevs = amount;
    }

    function setAmountForPublic(uint256 amount) external onlyOwner {
        amountForPublic = amount;
    }

    function updateRuggedERC721ContractAddress(address ruggedAddress)
        external
        onlyOwner
    {
        ruggedERC721ContractAddress = ruggedAddress;
    }

    function updateRuggedERC1155ContractAddress(address ruggedAddress)
        external
        onlyOwner
    {
        ruggedERC1155ContractAddress = ruggedAddress;
    }

    function setMintEndTime(uint32 timestamp) public onlyOwner {
        mintEndTime = timestamp;
    }

    function addMinutesToMintTime(uint32 n) public onlyOwner {
        mintEndTime = block.timestamp + (n * 60);
    }

    // helpers
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function reunionListMintsRemaining() public view returns (uint256) {
        return reunionList[msg.sender];
    }

    function reunionListAuxMintsRemaining() public view returns (uint64) {
        return _getAux(msg.sender);
    }

    function ownsRuggedERC721Token() public view returns (bool) {
        RuggedCommunityERC721Interface ruggedContract = RuggedCommunityERC721Interface(
                ruggedERC721ContractAddress
            );
        return ruggedContract.balanceOf(msg.sender) > 0;
    }

    function ownsRuggedERC1155Token(uint256 tokenId)
        public
        view
        returns (bool)
    {
        RuggedCommunityERC1155Interface ruggedContract = RuggedCommunityERC1155Interface(
                ruggedERC1155ContractAddress
            );

        return ruggedContract.balanceOf(msg.sender, tokenId) > 0;
    }
}