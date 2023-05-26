//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BeaNFT is ERC721URIStorage, Ownable {
    address public signer;

    string _baseTokenURI;

    event SignerUpdated(address oldSigner, address newSigner);

    constructor(
        string memory tokenName,
        string memory symbol,
        address _signer
    ) ERC721(tokenName, symbol) {
        setBaseURI("https://gateway.pinata.cloud/ipfs/");
        signer = _signer;
    }

    function getSigner() external view returns (address) {
        return signer;
    }

    function setSigner(address newSigner) external onlyOwner {
        address oldSigner = signer;
        signer = newSigner;

        emit SignerUpdated(oldSigner, newSigner);
    }

    function mint(
        address account,
        uint256 tokenId,
        string memory ipfsHash,
        bytes calldata signature
    ) public {
        require(tokenId < 6001, "BeaNFT: max supply is 6000");
        require(!_exists(tokenId), "BeaNFT: token minted");

        bytes32 message = prefixed(
            keccak256(abi.encodePacked(account, tokenId, ipfsHash))
        );
        require(
            recoverSigner(message, signature) == signer,
            "BeaNFT: invalid signature"
        );

        _safeMint(account, tokenId);
        _setTokenURI(tokenId, ipfsHash);
    }

    function batchMint(
        address[] calldata accounts,
        uint256[] calldata tokenIds,
        string[] calldata ipfsHashes,
        bytes[] calldata signatures
    ) external {
        require(
            accounts.length == tokenIds.length &&  
            accounts.length == ipfsHashes.length &&
            accounts.length == signatures.length,
            "BeaNFT: length mismatch"
        );
        for (uint256 i = 0; i < accounts.length; i++) {
            mint(accounts[i], tokenIds[i], ipfsHashes[i], signatures[i]);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }
}