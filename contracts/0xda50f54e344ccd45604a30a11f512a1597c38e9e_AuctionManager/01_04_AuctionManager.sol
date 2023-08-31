// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AuctionManager is Ownable, ReentrancyGuard {

    struct Auction {
        string orderId;
        string buyerId;
        uint256 editionId;
        uint256 itemId;
        uint256 price;
        address payable ownerWallet;
        address payable artistWallet;
        uint256 artistRoyalty;
    }

    uint256 public constant FEEDOMINATOR = 10000;

    address payable public vaultWallet;
    uint32 public vaultFee = 500;
    
    address public signer;
    string public salt = "\x19Ethereum Signed Message:\n32";

    event BuyAuctionItem(
        string orderId,
        string buyerId, 
        uint256 editionId, 
        uint256 itemId,
        uint256 price,
        address ownerWallet,
        address artistWallet,
        uint256 artistRoyalty
    );

    constructor(address payable _vaultWallet, address _signer) {
        require(_vaultWallet != address(0), "Invalid vault address");
        vaultWallet = _vaultWallet;
        signer = _signer;
    }

    function buyAuctionItem(
        Auction calldata auction,
        bytes calldata signature,
        uint256 deadline
    ) external payable nonReentrant {
        require(block.timestamp < deadline, "Transaction is expired");

        require(msg.value == auction.price, "Wrong price");

        {
            bytes32 messageHash = keccak256(
                abi.encodePacked(
                    auction.orderId,
                    auction.buyerId,
                    auction.editionId,
                    auction.itemId,
                    auction.ownerWallet,
                    auction.artistWallet,
                    auction.artistRoyalty,
                    deadline
                )
            );
            bytes32 ethSignedMessageHash = keccak256(abi.encodePacked(salt, messageHash));
            bool verify = recoverSigner(ethSignedMessageHash, signature) == signer;

            require(verify == true, "Buy Auction: Invalid signature");
        }
        
        {
            uint256 vault = msg.value * vaultFee / FEEDOMINATOR;

            uint256 artist = 0;

            if (auction.artistRoyalty > 0 && auction.artistWallet != address(0)) {
                artist = msg.value * auction.artistRoyalty / FEEDOMINATOR;
            }

            uint256 payout = msg.value - vault - artist;
            require(payout >= 0, "Invalid vaultFee or ArtistRoyalty");

            auction.ownerWallet.transfer(payout);

            if (auction.artistRoyalty > 0 && auction.artistWallet != address(0)) {
                auction.artistWallet.transfer(artist);
            }

            vaultWallet.transfer(vault);
        }

        emit BuyAuctionItem(
            auction.orderId,
            auction.buyerId,
            auction.editionId,
            auction.itemId,
            auction.price,
            auction.ownerWallet,
            auction.artistWallet,
            auction.artistRoyalty
        );
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        internal pure returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal pure returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature
            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature
            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    function setVaultAddress(address payable _vaultWallet) external onlyOwner {
        require(_vaultWallet != address(0), "Invalid vault address");
        
        vaultWallet = _vaultWallet;
    }

    function setVaultFee(uint32 _fee) external onlyOwner {
        vaultFee = _fee;
    }

    function setSalt(string memory _salt) external onlyOwner {
        salt = _salt;
    }

    function setSignerAddress(address _signer) external onlyOwner {
        require(_signer != address(0), "Invalid address");
        
        signer = _signer;
    }
}