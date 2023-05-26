// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT721A is ERC721A, Ownable {
    using SafeMath for uint256;
    address public signer;
    mapping(string => bool) internal nonceMap;
    string public baseUri;
    uint256 public maxCount;

    constructor() ERC721A("Bzuki", "BZUKI") {}

    //******SET UP******

    function setMaxCount(uint256 _maxCount) public onlyOwner {
        require(_maxCount > 0, "the max id must be more than 0!");
        maxCount = _maxCount;
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseUri = _newURI;
    }

    //******END SET UP******/

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function withdraw() public payable onlyOwner {
        uint256 withdrawETH = address(this).balance;
        payable(msg.sender).transfer(withdrawETH);
    }

    function mint(
        uint256 quantity,
        bytes32 hash,
        bytes memory signature,
        uint256 blockHeight,
        string memory nonce
    ) external {
        require(quantity > 0, "The quantity is less than 0!");
        require(
            _currentIndex + quantity <= maxCount,
            "The quantity exceeds the stock!"
        );
        require(!nonceMap[nonce], "Nonce already exist!");
        require(hashMint(quantity, blockHeight, nonce) == hash, "Invalid hash!");
        require(matchAddressSigner(hash, signature), "Invalid signature!");

        _safeMint(msg.sender, quantity);
        nonceMap[nonce] = true;
    }

    function airdrop(address to, uint256 quantity) public onlyOwner {
        require(quantity > 0, "The quantity is less than 0!");
        require(
            _currentIndex + quantity <= maxCount,
            "The quantity exceeds the stock!"
        );
        _safeMint(to, quantity);
    }

    function hashMint(uint256 quantity, uint256 blockHeight, string memory nonce)
    private
    view
    returns (bytes32)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(msg.sender, quantity, blockHeight, nonce, "bzuki_mint")
                )
            )
        );
        return hash;
    }

    function matchAddressSigner(bytes32 hash, bytes memory signature)
    internal
    view
    returns (bool)
    {
        return signer == recoverSigner(hash, signature);
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
    internal
    pure
    returns (
        bytes32 r,
        bytes32 s,
        uint8 v
    )
    {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}