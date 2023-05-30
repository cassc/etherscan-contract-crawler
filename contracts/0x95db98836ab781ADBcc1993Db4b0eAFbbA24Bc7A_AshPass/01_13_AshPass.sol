//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract AshPass is ERC1155, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    uint256 public constant MINT_PRICE = 0.3333 ether;
    uint256 public constant MAX_TOTAL_SUPPLY = 2000;
    uint256 public constant MAX_PUBLIC_SUPPLY = 500;
    uint256 public constant RESERVED = 500;
    uint256 public constant TOKEN_ID = 0;

    uint256 public totalSupply;
    uint256 public publicSupply;
    bool public metadataFrozen;
    bool public saleActive;
    address public signer;
    mapping(address => bool) public addressMinted;

    constructor(string memory uri, address owner) ERC1155(uri) {
        _mint(owner, TOKEN_ID, RESERVED, "");
        totalSupply += RESERVED;
    }

    /**
     * @notice Set signature signing address
     * @param _signer address of account used to create mint signatures
     */
    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    /**
     * @notice Flip public sale state between active and inactive
     */
    function flipSaleActive() public onlyOwner {
        saleActive = !saleActive;
    }

    /**
     * @notice Set metadata URI
     * @dev More details in ERC1155 contract
     * @param _uri of token metadata
     */
    function setMetadata(string memory _uri) public onlyOwner {
        require(!metadataFrozen, "Metadata frozen");
        _setURI(_uri);
    }

    /**
     * @notice Freeze token metadata, making it immutable
     */
    function freezeMetadata() public onlyOwner {
        metadataFrozen = true;
    }

    /**
     * @notice Internal base mint function to be used by public and mintlist mint functions
     * @param sender account sending the mint transaction
     */
    function baseMint(address sender) internal {
        require(sender == tx.origin,                 "Contract minting not allowed");
        require(!addressMinted[sender],              "Address has already minted");
        require(msg.value == MINT_PRICE,             "Invalid Ether amount sent");
        require(totalSupply + 1 <= MAX_TOTAL_SUPPLY, "Exceeds maximum number of tokens");

        _mint(sender, TOKEN_ID, 1, "");

        addressMinted[sender] = true;
        totalSupply += 1;
    }

    /**
     * @notice Public mint accessible by anyone (contracts excluded)
     */
    function publicMint() public payable nonReentrant {
        require(saleActive,                            "Sale is not active");
        require(publicSupply + 1 <= MAX_PUBLIC_SUPPLY, "Exceeds maximum number of public tokens");

        baseMint(_msgSender());

        publicSupply += 1;
    }

    /**
     * @notice Mintlist mint accessible only to those with a signature
     * @param signature created by signer account
     */
    function mintlistMint(bytes memory signature) public payable nonReentrant {
        address _signer = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_msgSender()))),
            signature
        );
        require(signer == _signer, "Invalid signature");

        baseMint(_msgSender());
    }

    /**
     * @notice Withdraw all ETH transferred to the contract
     */
    function withdraw() external onlyOwner {
        Address.sendValue(payable(_msgSender()), address(this).balance);
    }
}