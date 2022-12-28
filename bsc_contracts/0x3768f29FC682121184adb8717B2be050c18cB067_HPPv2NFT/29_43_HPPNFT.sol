// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

interface IERC5192 {
  /// @notice Emitted when the locking status is changed to locked.
  /// @dev If a token is minted and the status is locked, this event should be emitted.
  /// @param tokenId The identifier for a token.
  event Locked(uint256 tokenId);

  /// @notice Emitted when the locking status is changed to unlocked.
  /// @dev If a token is minted and the status is unlocked, this event should be emitted.
  /// @param tokenId The identifier for a token.
  event Unlocked(uint256 tokenId);

  /// @notice Returns the locking status of an Soulbound Token
  /// @dev SBTs assigned to zero address are considered invalid, and queries
  /// about them do throw.
  /// @param tokenId The identifier for an SBT.
  function locked(uint256 tokenId) external view returns (bool);
}

contract HPPNFT is ERC721, Ownable, IERC5192 {

    bytes32 public constant MINT_HASH_TYPE = keccak256("mint");
    uint256 private _tokenIdCounter;
    address private _signer;
    string  private _tokenURI;

    constructor(address signer) ERC721("Hooked Party Pass", "HPP") {
        _signer = signer;
        _tokenURI = string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(string(abi.encodePacked('{"name": "Hooked Party Pass", "description": "Hooked Party Pass NFT is an exclusive entry pass for Hooked by BNBChain event series, co-hosted by Hooked Protocol and BNB Chain. Each user can claim only 1 Hooked Party Pass NFT. All holders of which will be considered as Hooked early community members.", "image": "ipfs://QmesfZd8CjmRhmWGm5rZBw9R7j4His1zcRrseibsgi5NwL"}'))))));
    }

    function setSigner(address signer) public onlyOwner {
        require(signer != address(0),"Invalid signer");
        _signer = signer;
    }

    function locked(uint256) external pure override returns (bool){
        return true;
    }

    function mint(bytes calldata signature) public {
        require(balanceOf(msg.sender) == 0, "PASS limit exceeded");
        bytes32 message = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(MINT_HASH_TYPE, msg.sender)));
        require(SignatureChecker.isValidSignatureNow(_signer, message, signature),"Invalid signature");
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter += 1;
        _mint(msg.sender, tokenId);
        emit Locked(tokenId);
    }

    function tokenURI(uint256) public view override returns (string memory) {
        return _tokenURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override
    {
        require(from == address(0),"NFT locked");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return interfaceId == type(IERC5192).interfaceId || super.supportsInterface(interfaceId);
    }
}