// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "solmate/tokens/ERC1155.sol";
import "solmate/auth/Owned.sol";
import "solmate/utils/ReentrancyGuard.sol";
import "./IETHGobblers.sol";
import "oz/utils/Strings.sol";
import "./IERC20.sol";

/// @author The Eth Gobblers Team
/// @title 1st Goopen Editions - Homage to BK and PEPE

contract BK is ERC1155, Owned, ReentrancyGuard {

    using Strings for uint;

    string public name;
    string public symbol;

    mapping(uint => string) private _tokenURIs;
    
    /// @notice The address of the artist who's work is reporesented by this contract.
    address public artist;
    
    /// @notice The contract address of the ETH GOBBLERS(GOOEY) NFT collection.
    address public gooey = 0x0A8D311B99DdAA9EBb45FD606Eb0A1533004f26b;

    /// @notice The PEPE token contract
    address public pepe = 0x6982508145454Ce325dDbE47a25d4ec3d2311933;

    /// @notice The First Thread Receipt contract
    address public firstThread;
    
    /// @notice The current token ID that would be minted if the mint function is called.
    uint public currentToken;
    
    /// @notice The cost of minting the current token in wei.
    uint public mintCost = 0.0042 ether;

    /// @notice The cost of minting the current token in PEPE.
    uint public mintCostPepe = 25000000000000000000000000;
    
    /// @notice Whether or not minting is active for the current token.
    bool public mintActive;

    /// @notice A mapping of token IDs to a mapping of GOOEY IDs to a boolean indicating wether or not that Gooey has been used to mint that token.
    mapping (uint => mapping (uint => bool)) public gooeyMinted;
    
    constructor(
        string memory _name,
        string memory _symbol,
        address _artist,
        address _owner
    )Owned(_owner) {
        name = _name;
        symbol = _symbol;
        artist = _artist;
    }

    receive() external payable {
        if(mintCost == 0){
            mint(1);
        } else {
            uint amount = msg.value / mintCost;
            mint(amount);
        }
    }
    
    /// @notice Mint a specific amount of the currentToken.
    /// @param amount The amount of tokens to mint.
    function mint(uint amount) public payable nonReentrant {
        require(mintActive, "Minting is not active for this token");
        require(msg.value == mintCost * amount, "Insufficient ETH sent");
        _mint(msg.sender, currentToken, amount, "");
        payable(artist).transfer(msg.value);
    }

    /// @notice Mint a token using a Gooey.
    /// @param gooeyId The ID of the Gooey to use to mint the token.
    function mintWithGooey(uint gooeyId) external nonReentrant {
        require(mintActive, "Minting is not active for this token");
        require(gooeyMinted[currentToken][gooeyId] == false, "This Gooey has already been used to mint this token");
        require(IETHGobblers(gooey).ownerOf(gooeyId) == msg.sender, "You do not own this Gooey");
        _mint(msg.sender, currentToken, 1, "");
        gooeyMinted[currentToken][gooeyId] = true;
    }

    /// @notice Mint a token using a Pepe token.
    /// @param amount The amount of tokens to mint.
    /// @dev Must approve the token first
    function mintWithPEPE(uint256 amount) external nonReentrant {
        require(mintActive, "Minting is not active for this token");
        IERC20(pepe).transferFrom(msg.sender, artist, amount * mintCostPepe);
        _mint(msg.sender, currentToken, amount, "");
    }

    function uri(uint tokenId) public view override returns (string memory) {
        string memory tokenURI = _tokenURIs[tokenId];
        return tokenURI;
    }

    /// @notice Set the token URI for a specific token.
    /// @param tokenId The ID of the token to set the URI for.
    /// @param tokenURI The URI to set.
    function setURI(uint tokenId, string calldata tokenURI) external onlyOwner {
        _tokenURIs[tokenId] = tokenURI;    
    }

    /// @notice Deactivate minting on the contract and progress the currentTokenCounter.
    function deactivateMint() external onlyOwner {
        require (mintActive == true, "Minting is already inactive");
        mintActive = false;
        currentToken++;
    }

    /// @notice Activate minting on the contract.
    function activateMint() external onlyOwner {
        require (mintActive == false, "Minting is already active");
        mintActive = true;
    }

    /// @notice Update the gooey address.
    /// @param newGooey The new gooey address.
    function updateGooey(address newGooey) external onlyOwner {
        gooey = newGooey;
    }

    /// @notice Update the artist address.
    /// @param newArtist The new artist address.
    function updateArtist(address newArtist) external onlyOwner {
        artist = newArtist;
    }

    /// @notice Update the pepe address.
    /// @param newPepe The new pepe address.
    function updatePepe(address newPepe) external onlyOwner {
        pepe = newPepe;
    }

    /// @notice Update the PEPE mint cost.
    /// @param newPepeMintCost The new pepe address.
    function updatePepeMintCost(uint256 newPepeMintCost) external onlyOwner {
        mintCostPepe = newPepeMintCost;
    }
    
    /// @notice Update ETH mint cost in WEI
    /// @param newMintCost The cost of minting a token represented in wei.
    function updateMintCost(uint256 newMintCost) external onlyOwner {
        mintCost = newMintCost;
    }

    /// @notice Update the First Thread address.
    /// @param newFirstThread The new First Thread address.
    function updateFirstThread(address newFirstThread) external onlyOwner {
        firstThread = newFirstThread;
    }

    /// @notice Override safe transfer from to permission First Thread contract
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public override {
        require(msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == firstThread, "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /// @notice Override safe transfer from to permission First Thread contract
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public override {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == firstThread, "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

}