// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./SignatureHelper.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract RektWTF is ERC721A, Pausable, Ownable, SignatureHelper {
    uint256 public immutable MAX_SUPPLY;

    string private baseURI;

    mapping(address => uint16) public nonces;

    event Mint(address indexed account, uint256 nonce, bytes signature);

    constructor(
        uint256 _maxSupply,
        string memory baseURI_,
        address _signer
    ) ERC721A("RektWTF", "REKT") SignatureHelper(_signer) {
        MAX_SUPPLY = _maxSupply;

        baseURI = baseURI_;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return string(abi.encodePacked(baseURI, _toString(tokenId), ".json"));
    }

    function _getMessageHash(address account, uint256 nonce)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, nonce));
    }

    function mint(bytes calldata signature) external payable whenNotPaused {
        require(totalSupply() < MAX_SUPPLY, "Out of supply");

        bytes32 messageHash = _getMessageHash(msg.sender, nonces[msg.sender]++);
        require(
            verify(messageHash, signature),
            "Invalid signature, please contact our support team"
        );

        _mint(_msgSender(), 1);

        emit Mint(msg.sender, nonces[msg.sender] - 1, signature);
    }

    function updateURI(string memory newURI) external onlyOwner {
        baseURI = newURI;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override whenNotPaused {
        super._beforeTokenTransfers(from, to, tokenId, batchSize);
    }

    function withdraw(address recipient) external onlyOwner {
        (bool success, ) = recipient.call{value: address(this).balance}("");

        require(success, "Unable to send value, recipient may have reverted");
    }

    receive() external payable {}
}