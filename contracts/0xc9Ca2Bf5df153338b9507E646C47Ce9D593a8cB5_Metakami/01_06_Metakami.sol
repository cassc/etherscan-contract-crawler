// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { ERC721A } from "erc721a/contracts/ERC721A.sol";

/*-----------------------------ERRORS---------------------------------*/
error InsufficientAmountSent();
error ExceedsTxnLimit();
error ExceedsAllowlistLimit();
error ExceedsTotalSupply();
error NotOnAllowlist();
error PublicMintInactive();
error AllowlistMintInactive();
error CallerIsContract();
error NoFundsToWithdraw();
error TransferFailed();

contract Metakami is ERC721A, Ownable {
    /*-----------------------------VARIABLES------------------------------*/
    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public constant MAX_PUBLIC_MINTS = 5;
    uint256 public constant MAX_ALLOWLIST_MINTS = 2;
    uint256 public constant ALLOWLIST_MINT_PRICE = 0.05 ether;
    uint256 public constant MAX_BATCH_SIZE = 5;
    uint256 public publicMintPrice = 0.07 ether;
    bool public isPublicMintActive = false;
    bool public isAllowlistMintActive = false;
    string public baseTokenURI;
    bytes32 public merkleRoot;

    /*------------------------------EVENTS--------------------------------*/
    event Minted(address indexed receiver, uint256 amount);

    /*-----------------------------MODIFIERS------------------------------*/
    /// @notice Requires that the minter is not a contract, and mint amount does not exceed maximum supply
    modifier validTxn(uint256 nMints) {
        if (msg.sender != tx.origin) revert CallerIsContract();
        if (totalSupply() + nMints > MAX_SUPPLY) revert ExceedsTotalSupply();
        _;
    }

    /*--------------------------CONSTRUCTOR-------------------------------*/
    constructor() ERC721A("Metakami", "METAKAMI") {}

    /*--------------------------MINT FUNCTIONS----------------------------*/

    /// @notice Public mint when public sale is active
    function mintPublic(uint256 nMints) external payable validTxn(nMints) {
        if (!isPublicMintActive) revert PublicMintInactive();
        if (nMints > MAX_PUBLIC_MINTS) revert ExceedsTxnLimit();
        if (msg.value != publicMintPrice * nMints) revert InsufficientAmountSent();

        _mint(msg.sender, nMints);
        emit Minted(msg.sender, nMints);
    }

    /// @notice Allowlist mint when allowlist sale is active
    /// @dev Uses a Merkle tree to verify if address is on allowlist
    function mintAllowlist(bytes32[] calldata _proof, uint256 nMints) external payable validTxn(nMints) {
        if (!isAllowlistMintActive) revert AllowlistMintInactive();
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_proof, merkleRoot, node)) revert NotOnAllowlist();
        if (msg.value != ALLOWLIST_MINT_PRICE * nMints) revert InsufficientAmountSent();
        if (_numberMinted(msg.sender) + nMints > MAX_ALLOWLIST_MINTS) revert ExceedsAllowlistLimit();

        _mint(msg.sender, nMints);
        emit Minted(msg.sender, nMints);
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
        emit Minted(msg.sender, nMints);
    }

    /*-------------------------------ADMIN--------------------------------*/

    /// @notice Allows the owner to set the public mint price
    function setPublicMintPrice(uint256 _mintPrice) external onlyOwner {
        publicMintPrice = _mintPrice;
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
        (bool success, ) = payable(_address).call{ value: _amount }("");
        if (!success) revert TransferFailed();
    }

    /// @notice Allows the owner to withdraw and split contract funds
    function withdrawAll() external onlyOwner {
        uint256 contractBalance = address(this).balance;

        if (contractBalance == 0) revert NoFundsToWithdraw();

        _withdraw(address(0xD9db2f388BDC61C4f013452CAD5cd0845F22cC42), (contractBalance * 15) / 100);
        _withdraw(address(0xbC7693F4EeaB7DEafF3aD6CDD801aBCa283Fb4CF), (contractBalance * 15) / 100);
        _withdraw(address(0x69Be2B16673a74b0683e944eEfF154961d91c6Bd), address(this).balance);
    }

    /// @dev Allows contract to receive ETH
    receive() external payable {}
}