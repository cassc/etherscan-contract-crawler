// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/ERC721A/contracts/ERC721A.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Miloverso is ERC721A, Ownable {
    using ECDSA for bytes32;

    uint256 public maxSupply;
    uint256 public tokenPrice;
    uint256 public status;
    bytes32 public whitelistMerkleRoot;
    string public baseURI;
    bool public revealed;
    address[] private payees;
    uint256[] private payeesShares;

    error WrongValueSent(uint256 weiSent, uint256 weiRequired);
    error InvalidNewSupply(uint256 desiredSupply, uint256 currentSupply);
    error NotWhitelisted();
    error MaxAmountPerUser();
    error MaxSupplyReached();
    error WhitelistMintNotStarted();
    error PublicMintNotStarted();
    error FailedToSendEther();
    error MismatchingLengths();

    constructor(
        string memory unrevealedURI,
        bytes32 initialMerkleRoot,
        address[] memory _payees,
        uint256[] memory _shares
    ) ERC721A("Miloverso", "MILO") {
        if (_payees.length != _shares.length) {
            revert MismatchingLengths();
        }
        payees = _payees;
        payeesShares = _shares;
        status = 0;
        baseURI = unrevealedURI;
        whitelistMerkleRoot = initialMerkleRoot;
        tokenPrice = 0.029 ether;
        maxSupply = 2_222;
    }

    // USER PUBLIC MINT
    function whitelistMint(uint256 amount, bytes32[] memory proof)
        public
        payable
    {
        if (_numberMinted(msg.sender) + amount > 3) {
            revert MaxAmountPerUser();
        }

        if (status != 1) {
            revert WhitelistMintNotStarted();
        }

        if (
            !MerkleProof.verify(
                proof,
                whitelistMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) {
            revert NotWhitelisted();
        }

        if (totalSupply() + amount > maxSupply) {
            revert MaxSupplyReached();
        }

        if (msg.value < amount * tokenPrice) {
            revert WrongValueSent(msg.value, amount * tokenPrice);
        }

        _safeMint(msg.sender, amount);
    }

    function publicMint(uint256 amount) public payable {
        if (status != 2) {
            revert PublicMintNotStarted();
        }

        if (totalSupply() + amount > maxSupply) {
            revert MaxSupplyReached();
        }

        if (_numberMinted(msg.sender) + amount > 5) {
            revert MaxAmountPerUser();
        }

        if (msg.value < amount * tokenPrice) {
            revert WrongValueSent(msg.value, amount * tokenPrice);
        }

        _safeMint(msg.sender, amount);
    }

    // OWNER ACTIONS
    function airdrop(address[] memory recipients, uint256[] calldata amounts)
        public
        onlyOwner
    {
        uint length = recipients.length;
        if (length != amounts.length) {
            revert MismatchingLengths();
        }
        for (uint i = 0; i < length; ) {
            if (totalSupply() + amounts[i] > maxSupply) {
                revert MaxSupplyReached();
            }
            _mint(recipients[i], amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function updateStatus(uint256 newStatus) public onlyOwner {
        status = newStatus;
    }

    function updateRevealStatus(bool _revealed, string memory _newBaseURI)
        public
        onlyOwner
    {
        revealed = _revealed;
        baseURI = _newBaseURI;
    }

    function increaseSupply(uint256 newSupply) public onlyOwner {
        maxSupply = newSupply;
    }

    function updatePrice(uint256 newPrice) public onlyOwner {
        tokenPrice = newPrice;
    }

    function withdraw(address recipient) public onlyOwner {
        (bool success, ) = recipient.call{value: address(this).balance}("");
        if (!success) {
            revert FailedToSendEther();
        }
    }

    function updateWhitelist(bytes32 newMerkleRoot) public onlyOwner {
        whitelistMerkleRoot = newMerkleRoot;
    }

    function pay() public onlyOwner {
        uint length = payees.length;
        uint256 balance = address(this).balance;

        for (uint i = 0; i < length; ) {
            uint256 ethToSend = (balance * payeesShares[i]) / 100;
            (bool success, ) = payees[i].call{value: ethToSend}("");

            if (!success) {
                revert FailedToSendEther();
            }

            unchecked {
                ++i;
            }
        }
    }

    // OVERRIDES
    function _baseURI()
        internal
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        return baseURI;
    }

    receive() external payable {}
}