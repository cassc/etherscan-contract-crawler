// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Sig.sol";

interface IToken {
    function balanceOf(address owner, uint256 id) external returns (uint256);

    function isApprovedForAll(
        address owner,
        address operator
    ) external returns (bool);

    function burnFT(address owner, uint256 tokenID, uint256 quantity) external;

    function mintFT(address to, uint256 tokenID, uint256 quantity) external;

    function mintNFT(address to, uint256 tokenID) external;

    function batchMintNFT(address to, uint256[] calldata ids) external;
}

contract Break is Ownable {
    address private _token;
    address private _signer;

    event SignatureConsumed(bytes32 indexed from, bytes32 indexed sigHash);

    mapping(bytes32 => bytes32) public lastSigUsed;

    function setTokenAddress(address addr) public onlyOwner {
        _token = addr;
    }

    function getToken() public view returns (address) {
        return _token;
    }

    function setSignerAddress(address addr) public onlyOwner {
        _signer = addr;
    }

    function getSigner() public view returns (address) {
        return _signer;
    }

    function mintFTs(
        bytes32 from,
        address to,
        uint256 id,
        uint256 qty,
        uint256 expiry,
        bytes32 prevSigHash,
        bytes calldata sig
    ) public {
        IToken token = IToken(_token);

        require(to != address(0), "Destination cannot be null address.");

        require(
            verify(
                sig,
                keccak256(abi.encode(from, id, qty, expiry, prevSigHash)),
                _signer
            ),
            "Signature mismatch."
        );

        require(
            lastSigUsed[from] == prevSigHash,
            "Wrong previous signature supplied."
        );

        require(block.timestamp < expiry, "Signature has expired.");

        lastSigUsed[from] = keccak256(sig);

        token.mintFT(to, id, qty);

        emit SignatureConsumed(from, keccak256(sig));
    }

    function mintNFTs(
        bytes32 from,
        address to,
        uint256 burn,
        uint256 burnQty,
        uint256[] calldata mints,
        uint256 expiry,
        bytes32 prevSigHash,
        bytes calldata sig
    ) public {
        IToken token = IToken(_token);

        require(to != address(0), "Destination cannot be null address.");

        if (burnQty > 0) {
            require(
                token.isApprovedForAll(_msgSender(), address(this)),
                "Approval required"
            );
        }

        require(
            verify(
                sig,
                keccak256(
                    abi.encode(
                        from,
                        burn,
                        burnQty,
                        keccak256(abi.encodePacked(mints)),
                        expiry,
                        prevSigHash
                    )
                ),
                _signer
            ),
            "Signature mismatch."
        );

        require(
            lastSigUsed[from] == prevSigHash,
            "Wrong previous signature supplied."
        );

        require(block.timestamp < expiry, "Signature has expired.");

        lastSigUsed[from] = keccak256(sig);

        if (burnQty > 0) {
            token.burnFT(_msgSender(), burn, burnQty);
        }

        token.batchMintNFT(to, mints);

        emit SignatureConsumed(from, keccak256(sig));
    }

    function verify(
        bytes memory sig,
        bytes32 hash,
        address signer
    ) internal pure returns (bool) {
        return Sig.verify(sig, hash, signer);
    }
}