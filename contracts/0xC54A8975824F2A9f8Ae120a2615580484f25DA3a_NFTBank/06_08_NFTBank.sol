// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IPunks.sol";
import "./IERC721.sol"; 
import "./ReentrancyGuard.sol";

// Bank primitive that allows transfer of ETH or ERC-20 from NFT to NFT, NFT to (EOA or Contract), and (EOA or Contract) to NFT
contract NFTBank is ReentrancyGuard {
    using SafeERC20 for IERC20;

    IPunks public immutable punksAddress;

    // Token address (zero for ETH) => ERC721 NFT Contract Address => NFT Token Id => balance
    mapping(address => mapping(address => mapping(uint256 => uint256))) public balances;

    // Events
    event EtherDeposited(address indexed user, address nftContractAddress, uint256 tokenId, uint256 value);
    event EtherWithdrawn(address indexed user, address nftContractAddress, uint256 tokenId, uint256 value);
    event ERC20Deposited(address indexed user, address nftContractAddress, uint256 tokenId, address tokenAddress, uint256 value);
    event ERC20Withdrawn(address indexed user, address nftContractAddress, uint256 tokenId, address tokenAddress, uint256 value);
    event EtherSent(address indexed user, address fromNFTContractAddress, uint256 fromTokenId, address toNFTContractAddress, uint256 toTokenId, uint256 value);
    event ERC20Sent(address indexed user, address fromNFTContractAddress, uint256 fromTokenId, address toNFTContractAddress, uint256 toTokenId, address tokenAddress, uint256 value);    

    /**
     * @notice Constructor
     * @param _punksAddress address of the CryptoPunks contract
     */
    constructor (address _punksAddress) {
        punksAddress = IPunks(_punksAddress);
    }

    /**
     * @notice Deposit Ether into an NFT
     * @param nftContractAddress contract address of the NFT
     * @param tokenId id of the NFT
     */
    function depositEther(address nftContractAddress, uint256 tokenId) public payable nonReentrant {
        uint256 valueReceived = msg.value;
        balances[address(0)][nftContractAddress][tokenId] += valueReceived;

        emit EtherDeposited(msg.sender, nftContractAddress, tokenId, valueReceived);
    }

    /**
     * @notice Deposit ERC20s into an NFT
     * @param tokenAddress address of the ERC20
     * @param quantity amount of ERC20 to deposit
     * @param nftContractAddress contract address of the NFT
     * @param tokenId id of the NFT
     */
    function depositERC20(address tokenAddress, uint256 quantity, address nftContractAddress, uint256 tokenId) public nonReentrant {
        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), quantity);
        balances[tokenAddress][nftContractAddress][tokenId] += quantity;

        emit ERC20Deposited(msg.sender, nftContractAddress, tokenId, tokenAddress, quantity);
    }

    /**
     * @notice Deposit Ether into an NFT checking that the NFT is owned by the sender
     * @param nftContractAddress contract address of the NFT
     * @param tokenId id of the NFT
     */
    function depositEtherProtected(address nftContractAddress, uint256 tokenId) external payable {
        checkOwnership(nftContractAddress, tokenId);
        depositEther(nftContractAddress, tokenId);
    }

    /**
     * @notice Deposit ERC20s into an NFT checking that the NFT is owned by the sender
     * @param tokenAddress address of the ERC20
     * @param quantity amount of ERC20 to deposit
     * @param nftContractAddress contract address of the NFT
     * @param tokenId id of the NFT
     */
    function depositERC20Protected(address tokenAddress, uint256 quantity, address nftContractAddress, uint256 tokenId) external {
        checkOwnership(nftContractAddress, tokenId);        
        depositERC20(tokenAddress, quantity, nftContractAddress, tokenId);
    }    

    /**
     * @notice Send Ether from one NFT to another
     * @param fromNFTContractAddress contract address of the NFT sending Ether
     * @param fromTokenId token id of the NFT sending Ether
     * @param quantity quantity of Ether to be sent
     * @param toNFTContractAddress contract address of the NFT receiving Ether
     * @param toTokenId token id of the NFT receiving Ether
     */
    function nftSendEther(address fromNFTContractAddress, uint256 fromTokenId, uint256 quantity, address toNFTContractAddress, uint256 toTokenId) external nonReentrant {
        checkOwnership(fromNFTContractAddress, fromTokenId);
        require(balances[address(0)][fromNFTContractAddress][fromTokenId] >= quantity, "NFTBank: NFT doesn't have sufficient balance for that transfer");
        balances[address(0)][fromNFTContractAddress][fromTokenId] -= quantity;
        balances[address(0)][toNFTContractAddress][toTokenId] += quantity;

        emit EtherSent(msg.sender, fromNFTContractAddress, fromTokenId, toNFTContractAddress, toTokenId, quantity);
    }

    /**
     * @notice Send ERC20s from one NFT to another
     * @param fromNFTContractAddress contract address of the NFT sending the ERC20
     * @param fromTokenId token id of the NFT sending the ERC20
     * @param tokenAddress address of the ERC20 being sent
     * @param quantity quantity of ERC20 to be sent
     * @param toNFTContractAddress contract address of the NFT receiving the ERC20
     * @param toTokenId token id of the NFT receiving the ERC20
     */
    function nftSendERC20(address fromNFTContractAddress, uint256 fromTokenId, address tokenAddress, uint256 quantity, address toNFTContractAddress, uint256 toTokenId) external nonReentrant {
        checkOwnership(fromNFTContractAddress, fromTokenId);
        require(balances[tokenAddress][fromNFTContractAddress][fromTokenId] >= quantity, "NFTBank: NFT doesn't have sufficient balance for that transfer");
        balances[tokenAddress][fromNFTContractAddress][fromTokenId] -= quantity;
        balances[tokenAddress][toNFTContractAddress][toTokenId] += quantity;

        emit ERC20Sent(msg.sender, fromNFTContractAddress, fromTokenId, toNFTContractAddress, toTokenId, tokenAddress, quantity);
    }

    /**
     * @notice Pull Ether from an NFT to the owner's wallet
     * @param nftContractAddress contract address of the NFT
     * @param tokenId id of the NFT
     * @param quantity amount of Ether to be pulled
     */
    function pullEther(address nftContractAddress, uint256 tokenId, uint256 quantity) external nonReentrant {
        checkOwnership(nftContractAddress, tokenId);
        require(balances[address(0)][nftContractAddress][tokenId] >= quantity, "NFTBank: NFT has insufficient balance to satisfy the withdrawal");
        balances[address(0)][nftContractAddress][tokenId] -= quantity;
        (bool success, ) = msg.sender.call{value: quantity}("");
        require(success, "NFTBank: Withdraw failed");

        emit EtherWithdrawn(msg.sender, nftContractAddress, tokenId, quantity);
    }

    /**
     * @notice Pull ERC20s from an NFT to the owner's wallet
     * @param tokenAddress address of the ERC20 being pulled
     * @param quantity amount of ERC20 to be pulled
     * @param nftContractAddress contract address of the NFT
     * @param tokenId id of the NFT
     */
    function pullERC20(address tokenAddress, uint256 quantity, address nftContractAddress, uint256 tokenId) external nonReentrant {
        checkOwnership(nftContractAddress, tokenId);
        require(balances[tokenAddress][nftContractAddress][tokenId] >= quantity, "NFTBank: NFT has insufficient balance to satisfy the withdrawal");
        balances[tokenAddress][nftContractAddress][tokenId] -= quantity;
        IERC20(tokenAddress).safeTransfer(msg.sender, quantity);

        emit ERC20Withdrawn(msg.sender, nftContractAddress, tokenId, tokenAddress, quantity);
    }    

    /**
     * @notice Check if the message sender owns the NFT
     * @param nftAddress address of the NFT collection
     * @param tokenId token id of the NFT
     */
    function checkOwnership(address nftAddress, uint256 tokenId) internal view {
        require(msg.sender == getOwner(nftAddress, tokenId), "NFTBank: Caller is not the NFT owner");
    }

    /**
     * @notice Get NFT's owner
     * @param nftAddress address of the NFT collection
     * @param tokenId token id of the NFT
     */
    function getOwner(address nftAddress, uint256 tokenId)
        internal
        view
        returns (address)
    {
        if (nftAddress == address(punksAddress)) {
            return IPunks(punksAddress).punkIndexToAddress(tokenId);
        } else {
            return IERC721(nftAddress).ownerOf(tokenId);
        }
    }    


}