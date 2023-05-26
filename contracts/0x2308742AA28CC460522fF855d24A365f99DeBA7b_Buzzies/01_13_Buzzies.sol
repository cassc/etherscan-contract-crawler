// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Buzzies is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    IERC721 public partyBearAssets;
    State public state;
    uint256 public maxSupply;
    address private signer;
    string public tokenUriBase;
    mapping(uint256 => bool) public tokenMinted;

    enum State {
        Setup,
        Open,
        Closed
    }

    event Minted(
        address indexed minter,
        uint256[] indexed fromTokenId,
        uint256 amount
    );

    constructor(
        address _signer,
        address _partyBearAsset,
        string memory _tokenUriBase,
        uint256 _maxSupply
    ) ERC721A("FLUF World: Buzzies", "BUZZIES") {
        tokenUriBase = _tokenUriBase;
        signer = _signer;
        partyBearAssets = IERC721(_partyBearAsset);
        maxSupply = _maxSupply;
        state = State.Setup;
    }

    /* @dev: Setter for signer of SALT
     * @param: Walletaddress that signs
     */
    function updateSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    /* @dev: Verify whether this hash was signed by the right signer
     * @param: Keccak256 hash, and the given token
     * @returns: Returns whether the signer was correct, boolean
     */
    function _verify(
        bytes memory message,
        bytes calldata signature,
        address account
    ) internal pure returns (bool) {
        return
            keccak256(message).toEthSignedMessageHash().recover(signature) ==
            account;
    }

    /* @dev: Sets Claim to Open
     */
    function setOpen() external onlyOwner {
        state = State.Open;
    }

    /* @dev: Sets Claim to Closed
     */
    function setClosed() external onlyOwner {
        state = State.Closed;
    }

    /* @dev: Setter for Max Suppoly
     */
    function updateMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /* @dev: Setter for Partybear ERC721
     */
    function updatePartyBear(IERC721 _partybear) external onlyOwner {
        partyBearAssets = _partybear;
    }

    function adminMint(uint256 _qty) external onlyOwner {
        _safeMint(msg.sender, _qty);
    }

    /* @dev: mint
     * @param: The ECDSA signature and the encoded ABI
     */
    function mint(bytes calldata token, bytes memory encoded)
        external
        nonReentrant
    {
        require(state == State.Open, "claim has not started yet");
        require(msg.sender == tx.origin, "contracts cant mint");
        require(
            !Address.isContract(msg.sender),
            "contracts are not allowed to mint"
        );

        (address wallet, uint256[] memory tokenIds, uint256 totalAmount) = abi
            .decode(encoded, (address, uint256[], uint256));

        require(
            totalSupply() + totalAmount <= maxSupply,
            "claim has reached max supply"
        );

        require(wallet == msg.sender, "invalid wallet");
        require(_verify(encoded, token, signer), "invalid token.");
        require(tokenIds.length <= 10, "You can mint maximum 10 tokens");
        require(totalAmount <= 38, "you cant mint more than 38 at once");

        unchecked {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                require(!tokenMinted[tokenIds[i]], "token has already minted");
                require(
                    partyBearAssets.ownerOf(tokenIds[i]) == msg.sender,
                    "you are not the owner"
                );
                tokenMinted[tokenIds[i]] = true;
            }
        }

        _safeMint(msg.sender, totalAmount);
        emit Minted(msg.sender, tokenIds, totalAmount);
    }

    /* @dev: View function to see if an Bear tokenId has already minted or not
     * @param: Array of tokenIds
     */
    function getTokensMintedStatus(uint256[] calldata tokenIds)
        public
        view
        returns (bool[] memory)
    {
        bool[] memory tokenStatus = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenStatus[i] = tokenMinted[tokenIds[i]];
        }
        return tokenStatus;
    }

    /* @dev: Returns the metadata API and appends the tokenId
     * @param: tokenId integer
     * @returns: A string of tokenURI + tokenId
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        return
            string(abi.encodePacked(tokenUriBase, Strings.toString(tokenId)));
    }

    /* @dev: Update the base URL of the metadata
     * @param: API URL as a string
     */
    function setTokenURI(string memory _tokenUriBase) public onlyOwner {
        tokenUriBase = _tokenUriBase;
    }
}