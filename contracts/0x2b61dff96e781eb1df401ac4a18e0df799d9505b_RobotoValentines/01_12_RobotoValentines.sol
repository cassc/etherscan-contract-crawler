// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract RobotoValentines is ERC721, Ownable {
    using ECDSA for bytes32;

    uint256 public mintIndex = 1;
    uint256 public constant PRICE = 0.02 ether;

    bool public mintActive = true;

    string public _baseTokenURI;

    address private team = 0x03838BEb6AE40E4D48d8ECd874bbf855A94B311E;
    address private signer;

    event Mint(address purchaser);

    constructor(string memory baseURI, address _signer)
        ERC721("RobotoValentines", "RoboLove")
    {
        _baseTokenURI = baseURI;
        signer = _signer;
    }

    function mint(
        uint256 tokenId,
        address recipient,
        bytes memory signature
    ) external payable {
        require(mintActive, "MINTING_FINISHED");
        require(msg.value == PRICE, "INVALID_PRICE");
        require(
            _verify(
                keccak256(abi.encodePacked(msg.sender, tokenId)),
                signature
            ),
            "INVALID_SIGNATURE"
        );

        _mint(recipient, tokenId);

        unchecked {
            mintIndex++;
        }

        emit Mint(msg.sender);
    }

    function _verify(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        require(signer != address(0), "INVALID_SIGNER_ADDRESS");
        bytes32 signedHash = hash.toEthSignedMessageHash();
        return signedHash.recover(signature) == signer;
    }

    function totalSupply() public view virtual returns (uint256) {
        return mintIndex - 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /** @notice Permanently disables minting. Flag cannot be restored to active, thus capping the supply once called */
    function deactivateMint() external onlyOwner {
        mintActive = false;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = team.call{value: (address(this).balance)}("");

        require(success, "Transfer failed.");
    }
}