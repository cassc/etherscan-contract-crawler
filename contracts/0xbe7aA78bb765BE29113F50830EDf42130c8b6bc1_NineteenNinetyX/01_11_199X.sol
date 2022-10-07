// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./SignatureChecker.sol";
import "./SignerManager.sol";

/*

   ^
  / \
 /   \
/     \
|  1  |
|  9  |
\  \  /
 \  \/
 /\  \
/  \  \
|  9  |
|  X  |
\     /
 \   /
  \ /
   v

*/

contract NineteenNinetyX is ERC721A, Ownable, SignerManager, ReentrancyGuard {
    uint256 public constant MINT_PRICE = 0.0199 ether;
    uint256 public constant MAX_SUPPLY = 1999;
    bytes32 public constant PRIORITY_MINT_STATE =
        keccak256(abi.encodePacked("priority"));
    bytes32 public constant PRESALE_MINT_STATE =
        keccak256(abi.encodePacked("presale"));
    bytes32 public constant PUBLIC_MINT_STATE =
        keccak256(abi.encodePacked("public"));
    bytes32 public constant CLOSED_MINT_STATE =
        keccak256(abi.encodePacked("closed"));
    uint256 public txnLimit = 5; // only relevant to public mint
    string public currentBaseURI;
    bytes32 public mintState = CLOSED_MINT_STATE; // start closed

    /**
    @dev Record of already-used signatures.
     */
    mapping(bytes32 => bool) public usedMessages;

    constructor() ERC721A("NineteenNinetyX", "199X") {}

    /**
     * @dev Dawnkey mint, can occur in any mint state, requires sig.
     */
    function mintDK(
        uint256 quantity,
        uint256 allocation,
        bytes calldata signature
    ) public payable nonReentrant {
        checkMintParams(quantity, allocation, "");
        mintWithSig(quantity, allocation, signature, "dawnkey");
    }

    /**
     * @dev Priority mint, only in priority state, requires sig.
     */
    function mintPriority(
        uint256 quantity,
        uint256 allocation,
        bytes calldata signature
    ) public payable nonReentrant {
        checkMintParams(quantity, allocation, PRIORITY_MINT_STATE);
        mintWithSig(quantity, allocation, signature, "priority");
    }

    /**
     * @dev Presale mint, only in presale state, requires sig.
     */
    function mintPresale(
        uint256 quantity,
        uint256 allocation,
        bytes calldata signature
    ) public payable nonReentrant {
        checkMintParams(quantity, allocation, PRESALE_MINT_STATE);
        mintWithSig(quantity, allocation, signature, "presale");
    }

    /**
     * @dev Public mint, only in public state, does not require sig.
     */
    function mintPublic(uint256 quantity) public payable nonReentrant {
        checkMintParams(quantity, txnLimit, PUBLIC_MINT_STATE);
        _safeMint(msg.sender, quantity);
    }

    /**
     * @dev Runs checks on mint parameters
     */
    function checkMintParams(
        uint256 quantity,
        uint256 allocation,
        bytes32 expectedMintState
    ) private {
        if (expectedMintState == "") {
            // check that the mint state is not closed, any other is ok
            require(mintState != CLOSED_MINT_STATE, "Minting is closed");
        } else {
            // check mint state is correct
            // dawnkey can mint in any state for free, so these checks dont matter
            require(mintState == expectedMintState, "Wrong mintState");
            // prevent txns that don't provide enough ether
            require(msg.value >= MINT_PRICE * quantity, "Insufficient value");
        }

        if (expectedMintState == PUBLIC_MINT_STATE) {
            // check txn limit
            require(quantity <= txnLimit, "Exceeds txnLimit");
        } else {
            // check allocation limit
            require(quantity <= allocation, "Exceeds allocation");
        }

        // prevent txns that would exceed the maxSupply
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max supply");
    }

    /** @dev Mint tokens with a signature
     * @param quantity The quantity of tokens to mint
     */
    function mintWithSig(
        uint256 quantity,
        uint256 allocation,
        bytes calldata signature,
        string memory expectedSigType
    ) internal {
        bytes memory data = abi.encode(
            this,
            msg.sender,
            expectedSigType,
            allocation
        );

        SignatureChecker.requireValidSignature(
            signers,
            data,
            signature,
            usedMessages
        );

        _safeMint(msg.sender, quantity);
    }

    function teamMint(uint256 quantity) public onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max supply");
        _safeMint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return currentBaseURI;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        currentBaseURI = baseURI_;
    }

    function setTxnLimit(uint256 txnLimit_) public onlyOwner {
        txnLimit = txnLimit_;
    }

    function setMintState(string memory mintState_) public onlyOwner {
        /* priority, presale, or public */
        mintState = keccak256(abi.encodePacked(mintState_));
    }

    /**
     * @dev Helper to check if a signature has been used
     * @param to The address to mint to
     * @param allocation The max number of tokens to mint
     * @param expectedSigType The expected signature type
     */
    function sigUsed(
        address to,
        uint256 allocation,
        string calldata expectedSigType
    ) public view returns (bool) {
        bytes memory data = abi.encode(this, to, expectedSigType, allocation);
        bytes32 message = SignatureChecker.generateMessage(data);
        return usedMessages[message];
    }

    /**
     * @dev override _startTokenId so tokens go from 1 -> 1999
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @dev Withdraw ether to owner's wallet
     */
    function withdrawEth() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Withdraw failed");
    }
}