// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC721A, ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/*-----------------------------ERRORS---------------------------------*/
error IncorrectAmountSent();
error ExceedsTotalSupply();
error NotOnAllowlist();
error PublicMintInactive();
error AllowlistMintInactive();
error CallerIsContract();
error NoFundsToWithdraw();
error TransferFailed();

contract RafiLoungeMindful is ERC721AQueryable, Ownable {
    /*-----------------------------VARIABLES------------------------------*/
    uint256 public constant MAX_BATCH_SIZE = 5;
    uint256 public mintPrice = 4 ether;
    uint256 public maxSupply = 111;
    bool public isPublicMintActive = false;
    bool public isAllowlistMintActive = false;
    string public baseTokenURI;
    bytes32 public merkleRoot;

    /*-----------------------------MODIFIERS------------------------------*/
    /// @notice Requires that the minter is not a contract, and mint amount does not exceed maximum supply
    modifier validTxn(uint256 nMints) {
        if (msg.sender != tx.origin) revert CallerIsContract();
        if (totalSupply() + nMints > maxSupply) revert ExceedsTotalSupply();
        _;
    }

    /*--------------------------CONSTRUCTOR-------------------------------*/
    constructor() ERC721A("Rafi Lounge Mindful", "MINDFUL") {}

    /*--------------------------MINT FUNCTIONS----------------------------*/
    /// @notice Public mint
    function mint(address recipient, uint256 nMints)
        external
        payable
        validTxn(nMints)
    {
        if (!isPublicMintActive) revert PublicMintInactive();
        if (msg.value != mintPrice * nMints) revert IncorrectAmountSent();

        _mint(recipient, nMints);
    }

    /// @notice Allowlist mint
    /// @dev Uses a Merkle tree to verify if address is on allowlist
    function mintAllowlist(
        address recipient,
        bytes32[] calldata _proof,
        uint256 nMints
    ) external payable validTxn(nMints) {
        if (!isAllowlistMintActive) revert AllowlistMintInactive();
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_proof, merkleRoot, node))
            revert NotOnAllowlist();
        if (msg.value != mintPrice * nMints) revert IncorrectAmountSent();

        _mint(recipient, nMints);
    }

    /// @notice Reserved mints for owner
    /// @dev MAX_BATCH_SIZE enforces a fixed batch size when minting large quantities with ERC721A
    function mintReserve(uint256 nMints) external onlyOwner validTxn(nMints) {
        uint256 remainder = nMints % MAX_BATCH_SIZE;
        unchecked {
            uint256 nBatches = nMints / MAX_BATCH_SIZE;
            for (uint256 i; i < nBatches; ++i) {
                _mint(msg.sender, MAX_BATCH_SIZE);
            }
        }
        if (remainder != 0) {
            _mint(msg.sender, remainder);
        }
    }

    /*-------------------------------ADMIN--------------------------------*/
    /// @notice Airdrop token to accepted applicants
    function airdropApplicant(address recipient)
        external
        onlyOwner
        validTxn(1)
    {
        _mint(recipient, 1);
    }

    /// @notice Allows the owner to set the public mint price
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /// @notice Allows the owner to set the max supply
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /// @notice Allows the owner to update the allowlist Merkle root hash
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /// @notice Allows the owner to set the base URI
    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /// @notice Override view function to get the base URI
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /// @notice Allows the owner to flip the public mint state
    function togglePublicMintActive() external onlyOwner {
        isPublicMintActive = !isPublicMintActive;
    }

    /// @notice Allows the owner to flip the allowlist sale state
    function toggleAllowlistMintActive() external onlyOwner {
        isAllowlistMintActive = !isAllowlistMintActive;
    }

    /// @notice Allows contract to transfer and amount of funds to an address
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = payable(_address).call{value: _amount}("");
        if (!success) revert TransferFailed();
    }

    /// @notice Allows the owner to withdraw `amount` to `recipient`
    function withdrawTo(uint256 amount, address recipient) external onlyOwner {
        if (address(this).balance == 0) revert NoFundsToWithdraw();
        _withdraw(payable(recipient), amount);
    }

    /// @notice Allows the owner to withdraw and split contract funds
    function withdrawSplit() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        if (contractBalance == 0) revert NoFundsToWithdraw();

        _withdraw(
            address(0x628A5A2ab7D23cC3Ce35DBBDC40211Fb4A75d6D6),
            (contractBalance * 5) / 100
        );
        _withdraw(
            address(0x14355cDeB88aF8Eb089D84bbcFb604731bA76a1C),
            (contractBalance * 5) / 100
        );
        _withdraw(
            address(0x07907956be4647a110DD2c5E9CCCA01Be52c9024),
            (contractBalance * 5) / 100
        );

        _withdraw(
            address(0x872B2291f39636bB3A7C9087Ce2DBB002578FE15),
            (contractBalance * 75) / 1000
        );
        _withdraw(
            address(0xA0aB40897AaEaD41f8A6af38E6596B768dBcaBdb),
            (contractBalance * 75) / 1000
        );
        _withdraw(
            address(0xEC4D2003c05c48419448Cc0b3A46E330C5d725d3),
            address(this).balance
        );
    }

    /// @dev Allows contract to receive ETH
    receive() external payable {}
}