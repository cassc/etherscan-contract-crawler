// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DONUT3LOGY is ERC721A, Ownable {
    string public BASE_URI;

    bool public contractSealed = false;
    bool public mintActive = false;
    bool public limitedMintActive = true;
    bool public whitelistMintActive = true;

    uint208 public tokenPrice = 0.2 ether;
    uint256 public constant TOKEN_MAX_SUPPLY = 5204;

    uint256 public constant MAX_LIMITED_MINTERS = 524;
    uint16 public totalLimitedMinters;

    bytes32 public merkleRoot;
    address public immutable fundsRecipient;

    error InvalidCaller();
    error MintingDisabled();
    error NoMoreTokensLeft();
    error InvalidValueProvided();
    error MintLimitReached();
    error NotWhitelisted();
    error ContractSealed();

    constructor(
        string memory _baseUri,
        address _fundsRecipient)
        ERC721A("DONUT3LOGY", "DONUT3")
    {
        BASE_URI = _baseUri;
        fundsRecipient = _fundsRecipient;
    }

    function mint(uint256 quantity, bytes32[] calldata merkleProof)
        external
        payable
    {
        if (msg.sender != tx.origin) revert InvalidCaller();

        // Revert if mint is not active
        if (!mintActive) revert MintingDisabled();

        // Revert if total supply will exceed the limit
        if (_totalMinted() + quantity > TOKEN_MAX_SUPPLY) revert NoMoreTokensLeft();

        // Revert if not enough ETH is sent
        if (msg.value < tokenPrice * quantity) revert InvalidValueProvided();

        if (whitelistMintActive) {
             // Revert if merkle proof is not valid
            if (!MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender)))) revert NotWhitelisted();
        }

        if (limitedMintActive) {
            // Get the information from the owner auxiliary data if the owner has already minted
            uint256 minted = _getAux(msg.sender);

            if (minted == 0) {
                unchecked {
                    // Revert if total number of limited minters will exceed the limit
                    if (++totalLimitedMinters > MAX_LIMITED_MINTERS) revert MintLimitReached();
                }

                // Save number 1 into owner auxiliary data to mark that the owner minted
                _setAux(msg.sender, 1);
            }
        }

        _mint(msg.sender, quantity);
    }

    function airdrop(address[] calldata to, uint256[] calldata quantity)
        external
        onlyOwner
    {
        address[] memory recipients = to;

        for (uint256 i = 0; i < recipients.length; ) {
            _mint(recipients[i], quantity[i]);

            unchecked {
                ++i;
            }
        }

        if (_totalMinted() > TOKEN_MAX_SUPPLY) revert NoMoreTokensLeft();
    }

    function toggleMinting() external onlyOwner {
        mintActive = !mintActive;
    }

    function setMintConfig(bool _limitedMintActive, bool _whitelistMintActive)
        external
        onlyOwner
    {
        limitedMintActive = _limitedMintActive;
        whitelistMintActive = _whitelistMintActive;
    }

    function setTokenPrice(uint208 _tokenPrice) external onlyOwner {
        tokenPrice = _tokenPrice;
    }

    function reveal(string calldata newUri) external onlyOwner {
        if (contractSealed) revert ContractSealed();

        BASE_URI = newUri;
    }

    function sealContractPermanently() external onlyOwner {
        if (contractSealed) revert ContractSealed();

        contractSealed = true;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdrawAllFunds() external onlyOwner {
        payable(fundsRecipient).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}