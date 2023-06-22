// SPDX-License-Identifier: MIT
// Creator: lohko.io

pragma solidity >=0.8.17;

import {ERC721A} from "ERC721A.sol";
import {ERC2981} from "ERC2981.sol";
import {Ownable} from "Ownable.sol";
import {Strings} from "Strings.sol";
import {PaymentSplitter} from "PaymentSplitter.sol";
import {MerkleProof} from "MerkleProof.sol";

contract Xyber is Ownable, ERC721A, ERC2981, PaymentSplitter {
    using Strings for uint256;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 public constant maxSupplyCap = 4444;
    uint256 public constant maxTokensPerTx = 3;
    uint256 public constant price = 0.012 ether;

    uint256 public constant agentListSupplyCap = 3333;
    uint256 public constant maxClaims = 3;
    uint256 public constant agentListPrice = 0.01 ether;

    /*//////////////////////////////////////////////////////////////
                                VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint32 public agentListSaleStart;
    uint32 public publicSaleStart;

    bytes32 public merkleRoot;

    bool public revealed;

    string private _baseTokenURI;
    string private notRevealedUri;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error SaleNotStarted();
    error ClaimClosed();
    error InvalidProof();
    error QuantityOffLimits();
    error MaxSupplyReached();
    error InsufficientFunds();
    error AlreadyClaimed();
    error InvalidInput();
    error NonExistentTokenURI();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _initNotRevealedUri,
        address[] memory payees_,
        uint256[] memory shares_
    ) ERC721A("Xyber", "XYBER") PaymentSplitter(payees_, shares_) {
        notRevealedUri = _initNotRevealedUri;
        _mint(msg.sender, 1);
    }

    /*//////////////////////////////////////////////////////////////
                            MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function agentListMint(
        uint256 quantity,
        bytes32[] memory proof
    ) external payable {
        // If minting has not started, revert.
        if (block.timestamp < agentListSaleStart) revert SaleNotStarted();

        // If provided proof is invalid, revert.
        if (
            !(
                MerkleProof.verify(
                    proof,
                    merkleRoot,
                    keccak256(abi.encodePacked(msg.sender))
                )
            )
        ) revert InvalidProof();

        // If the AgentList supply cap is reached, revert.
        if (_totalMinted() + quantity > agentListSupplyCap)
            revert MaxSupplyReached();

        // If provided value doesn't match with the price, revert.
        if (msg.value != agentListPrice * quantity) revert InsufficientFunds();

        // If provided quantity is outside of predefined limits, revert.
        if (quantity == 0 || quantity > maxTokensPerTx)
            revert QuantityOffLimits();

        // If the user has already claimed their tokens, revert.
        uint64 _mintSlotsUsed = _getAux(msg.sender) + uint64(quantity);
        if (_mintSlotsUsed > maxClaims) revert AlreadyClaimed();

        _setAux(msg.sender, _mintSlotsUsed);

        _mint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable {
        // If public minting has not started by reaching timestamp or AgentList supply cap, revert.
        if (
            _totalMinted() < agentListSupplyCap &&
            block.timestamp < publicSaleStart
        ) {
            revert SaleNotStarted();
        }

        // If provided value doesn't match with the price, revert.
        if (msg.value != price * quantity) revert InsufficientFunds();

        // If provided quantity is outside of predefined limits, revert.
        if (quantity == 0 || quantity > maxTokensPerTx)
            revert QuantityOffLimits();

        // If max supply cap is reached, revert.
        if (_totalMinted() + quantity > maxSupplyCap) revert MaxSupplyReached();

        _mint(msg.sender, quantity);
    }

    /*//////////////////////////////////////////////////////////////
                            FRONTEND HELPERS
    //////////////////////////////////////////////////////////////*/

    function isAgentListOpen() public view returns (bool) {
        return block.timestamp < agentListSaleStart ? false : true;
    }

    function isPublicOpen() public view returns (bool) {
        return block.timestamp < publicSaleStart ? false : true;
    }

    function agentsClaimed(address user) public view returns (uint256) {
        return _getAux(user);
    }

    function mintedByAddr(address addr) external view returns (uint256) {
        return _numberMinted(addr);
    }

    function totalMinted() external view virtual returns (uint256) {
        return _totalMinted();
    }

    /*//////////////////////////////////////////////////////////////
                                ADMIN
    //////////////////////////////////////////////////////////////*/

    function rewardCollaborators(
        address[] calldata receivers,
        uint256[] calldata amounts
    ) external onlyOwner {
        // If there is a mismatch between receivers and amounts lengths, revert.
        if (receivers.length != amounts.length || receivers.length == 0)
            revert InvalidInput();

        for (uint256 i; i < receivers.length; ) {
            // If the max supply cap is reached, revert.
            if (_totalMinted() + amounts[i] > maxSupplyCap)
                revert MaxSupplyReached();

            _mint(receivers[i], amounts[i]);

            unchecked {
                ++i;
            }
        }
    }

    function setSaleTimes(
        uint32 _agentListSaleStart,
        uint32 _publicSaleStart
    ) external onlyOwner {
        agentListSaleStart = _agentListSaleStart;
        publicSaleStart = _publicSaleStart;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /*//////////////////////////////////////////////////////////////
                                OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert NonExistentTokenURI();
        if (revealed == false) {
            return notRevealedUri;
        }
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}