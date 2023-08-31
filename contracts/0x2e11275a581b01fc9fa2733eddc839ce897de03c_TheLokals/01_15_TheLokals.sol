// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error MintingDisabled();
error NoMoreTokensLeft();
error MintLimitReached();
error TransactionLimit();
error NotWhitelisted();
error InvalidCaller();
error InvalidValue();
error ContractSealed();

contract TheLokals is ERC721A, ERC2981, Ownable {
    string public s_baseURI;
    bool public s_contractSealed = false;

    enum MintPhase {
        FirstWhitelist,
        SecondWhitelist,
        Public
    }

    bool public s_mintActive = false;
    MintPhase public s_mintPhase = MintPhase.FirstWhitelist;
    uint256 public s_secondWhitelistLimit = 1;

    uint256 public constant TOKEN_PRICE = 0.1 ether;
    uint256 public constant TOKEN_MAX_SUPPLY = 5000;
    uint256 public constant TOKEN_MINT_LIMIT = 3;
    uint256 public constant TOKEN_LIMIT_PER_TRANSACTION = 3;

    mapping (address => uint256) private _amountMinted;

    bytes32 private constant FIRST_WHITELIST_MERKLE_ROOT =
        0x42dc45f12cf163ba6ba35014ea81560cea4feab4dd198e03bb9ad831c134048f;
    bytes32 private constant SECOND_WHITELIST_MERKLE_ROOT =
        0x393dc68ad65d9273bbda317e7a183035c71008727785a5c759b2d30eb3ad9225;

    uint96 public constant ROYALTY_PERCENTAGE = 600; // 6%
    address public constant ROYALTY_RECIPIENT =
        0xbd6b9a2C910F9bf50D9A6636C30597C58769EbCa;

    constructor(string memory initialURI) ERC721A("TheLokals", "LOKALS") {
        s_baseURI = initialURI;
        _setDefaultRoyalty(ROYALTY_RECIPIENT, ROYALTY_PERCENTAGE);
    }

    function mint(uint256 quantity, bytes32[] calldata merkleProof)
        external
        payable
    {
        if (msg.sender != tx.origin) revert InvalidCaller();
        if (!s_mintActive) revert MintingDisabled();
        if (_totalMinted() + quantity > TOKEN_MAX_SUPPLY)
            revert NoMoreTokensLeft();
        if (msg.value < TOKEN_PRICE * quantity) revert InvalidValue();
        if (quantity > TOKEN_LIMIT_PER_TRANSACTION) revert TransactionLimit();

        uint256 finalTokenBalance = _amountMinted[msg.sender] + quantity;
        if (finalTokenBalance > TOKEN_MINT_LIMIT) revert MintLimitReached();

        _amountMinted[msg.sender] = _amountMinted[msg.sender] + quantity;

        // Check if its the whitelist mint phase
        if (s_mintPhase != MintPhase.Public) {
            // Calculate leaf
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

            // Check if its the first whitelist mint phase
            if (s_mintPhase == MintPhase.FirstWhitelist) {
                // Check first whitelist access
                if (
                    !MerkleProof.verify(
                        merkleProof,
                        FIRST_WHITELIST_MERKLE_ROOT,
                        leaf
                    )
                ) revert NotWhitelisted();
            }
            // Otherwise its the second whitelist mint phase
            else {
                // Check second whitelist access
                if (
                    MerkleProof.verify(
                        merkleProof,
                        SECOND_WHITELIST_MERKLE_ROOT,
                        leaf
                    )
                ) {
                    // Check second whitelist mint limit
                    if (finalTokenBalance > s_secondWhitelistLimit)
                        revert MintLimitReached();
                }
                // Otherwise check first whitelist access
                else if (
                    !MerkleProof.verify(
                        merkleProof,
                        FIRST_WHITELIST_MERKLE_ROOT,
                        leaf
                    )
                ) revert NotWhitelisted();
            }
        }

        _safeMint(msg.sender, quantity);
    }

    function airdrop(address[] calldata to, uint256[] calldata quantity)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < to.length; ++i) {
            if (totalSupply() + quantity[i] > TOKEN_MAX_SUPPLY)
                revert NoMoreTokensLeft();
            _safeMint(to[i], quantity[i]);
        }
    }

    function toggleMinting() external onlyOwner {
        s_mintActive = !s_mintActive;
    }

    function setMintPhase(MintPhase mintPhase) external onlyOwner {
        s_mintPhase = mintPhase;
    }

    function setSecondWhitelistLimit(uint256 limit) external onlyOwner {
        s_secondWhitelistLimit = limit;
    }

    function reveal(string calldata newUri) external onlyOwner {
        if (s_contractSealed) revert ContractSealed();
        s_baseURI = newUri;
    }

    function sealContractPermanently() external onlyOwner {
        if (s_contractSealed) revert ContractSealed();
        s_contractSealed = true;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function withdrawAllFunds() external onlyOwner {
        payable(ROYALTY_RECIPIENT).transfer(address(this).balance);
    }

    function amountMinted(address user) public view returns (uint256) {
        return _amountMinted[user];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return s_baseURI;
    }

    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }
}