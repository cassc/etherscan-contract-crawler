// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721B.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract SpaceCraft is ERC721B, Ownable, Pausable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 10419;

    // must be in wei
    uint256 public paperTokensPerMint = 800 ether;

    // Token base URI
    string private baseTokenUri;

    // mapping to store all the claimed tokens
    mapping(uint256 => bool) public claimedTokens;

    // signer address for verification
    address public signerAddress = 0xA8e29A2566A9F7c485955B3267352663E6DB854f;

    // paper token address
    ERC20Burnable public paperTokenAddress;

    // Acrocalypse (ACROC) address
    IERC721 public nftTokenAddress;

    constructor(
        ERC20Burnable _paperTokenAddress,
        IERC721 _nftTokenAddress,
        string memory baseUri
    ) ERC721B("SpaceCraft", "SPACECRAFT") {

        baseTokenUri = baseUri;
        if (address(_paperTokenAddress) != address(0)) {
            paperTokenAddress = ERC20Burnable(_paperTokenAddress);
        }

        if (address(_nftTokenAddress) != address(0)) {
            nftTokenAddress = IERC721(_nftTokenAddress);
        }
    }

    function totalSupply() external view returns (uint256) {
        uint256 supply = _owners.length;
        return supply;
    }

    //external
    fallback() external payable {}

    receive() external payable {} // solhint-disable-line no-empty-blocks

    modifier callerIsUser() {
        // solhint-disable-next-line avoid-tx-origin
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }

    function verifySender(
        bytes memory signature,
        uint256 tokenId,
        uint256 quantity
    ) internal view returns (bool) {
        bytes32 hash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(msg.sender, tokenId, quantity)));
        return ECDSA.recover(hash, signature) == signerAddress;
    }

    function mint(
        uint256 quantity,
        bytes memory signature,
        uint256[] memory tokenIds
    ) external payable whenNotPaused callerIsUser {
        uint256 supply = _owners.length;
        require((supply + quantity) <= MAX_SUPPLY, "Beyond Max Supply");

        // verifying the signature
        require(verifySender(signature, tokenIds[0], quantity), "Invalid Access");

        // token validation
        for (uint256 i = 0; i < tokenIds.length; i++) {
            // validating the claimed token ids
            require(!claimedTokens[tokenIds[i]], "Token ID already claimed");

            // validating the token ownership
            require(nftTokenAddress.ownerOf(tokenIds[i]) == msg.sender, "Token owner mismatch");

            claimedTokens[tokenIds[i]] = true;
        }

        // check allowance
        uint256 neededPaperToken = paperTokensPerMint * quantity;
        uint256 allowance = paperTokenAddress.allowance(msg.sender, address(this));
        require(allowance >= neededPaperToken, "Insufficient Allowance");

        // Burning the $PAPER Tokens
        paperTokenAddress.burnFrom(msg.sender, neededPaperToken);

        // Minting
        _mintLoop(msg.sender, quantity);
    }

    // Owner
    function mintForAddress(uint256 quantity, address _receiver) public onlyOwner {
        uint256 supply = _owners.length;
        require((supply + quantity) <= MAX_SUPPLY, "Beyond Max Supply");
        _mintLoop(_receiver, quantity);
    }

    function _mintLoop(address _receiver, uint256 quantity) internal {
        uint256 supply = _owners.length;

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(_receiver, supply++, "");
        }
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 0;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        return
            bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, tokenId.toString(), ".json")) : "";
    }

    function checkTokensStatus(uint256[] memory tokenIds) external view returns (bool[] memory result) {
        require(tokenIds.length > 0, "Token Ids not set");
        bool[] memory unclaimedTokenIds = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (claimedTokens[tokenIds[i]]) {
                unclaimedTokenIds[i] = true;
            }
        }
        return unclaimedTokenIds;
    }

    function updateTokensClaimedStatus(uint256[] memory tokenIds, bool[] memory newClaimStatus) external onlyOwner {
        require(tokenIds.length > 0, "Token Ids not set");
        require(newClaimStatus.length > 0, "Claim status not set");
        require(tokenIds.length == newClaimStatus.length, "Data mismatch");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (claimedTokens[tokenIds[i]] != newClaimStatus[i]) {
                claimedTokens[tokenIds[i]] = newClaimStatus[i];
            }
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setTokenUri(string memory newBaseTokenUri) external onlyOwner {
        baseTokenUri = newBaseTokenUri;
    }

    function setSignerAddress(address newSignerAddress) external onlyOwner {
        if (address(newSignerAddress) != address(0)) {
            signerAddress = newSignerAddress;
        }
    }

    function setNFTAddress(IERC721 newAddress) external onlyOwner {
        if (address(newAddress) != address(0)) {
            nftTokenAddress = IERC721(newAddress);
        }
    }

    function setPaperTokenAddress(ERC20Burnable newAddress) external onlyOwner {
        if (address(newAddress) != address(0)) {
            paperTokenAddress = ERC20Burnable(newAddress);
        }
    }

    function setPaperTokensPerMint(uint256 newPaperTokensNeeded) external onlyOwner {
        if (paperTokensPerMint != newPaperTokensNeeded) {
            paperTokensPerMint = newPaperTokensNeeded;
        }
    }

    function withdraw(uint256 percentWithdrawl) external onlyOwner {
        require(address(this).balance > 0, "No funds available");
        require(percentWithdrawl > 0 && percentWithdrawl <= 100, "Invalid Withdrawl percent");

        Address.sendValue(payable(owner()), (address(this).balance * percentWithdrawl) / 100);
    }
}