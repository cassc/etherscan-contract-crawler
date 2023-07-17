// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "open-zeppelin/contracts/access/Ownable.sol";
import "ERC721A/contracts/ERC721A.sol";
import "open-zeppelin/contracts/utils/cryptography/ECDSA.sol";
import "open-zeppelin/contracts/utils/Strings.sol";

contract Chimera is ERC721A("Chimera", "CHIMERA"), Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 3333;

    address public signer = 0x43964CbB3B67F4D47371A32A483280950b2ab9B8;

    string public baseURI =
        "ipfs://bafybeif6jiczoa2xhi3zgnpvapygzxjnr6wr44nvm26zwshvkx2ezlscda/";
    string private uriExtension = ".json";

    function claim(uint64 quantity, bytes memory signature) external payable {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Invalid quantity");
        require(_numberMinted(msg.sender) == 0, "Invalid quantity");
        require(
            _isValidSignature(signature, msg.sender, quantity),
            "Invalid signature"
        );
        _mint(msg.sender, quantity);
    }

    function adminMint(uint64 quantity, address to) external onlyOwner {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Invalid quantity");
        _mint(to, quantity);
    }

    function updateSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Invalid address");
        signer = _signer;
    }

    function updateExtension(string memory _ext) external onlyOwner {
        uriExtension = _ext;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    // ========== UTILITY ==========

    function _isValidSignature(
        bytes memory signature,
        address _address,
        uint64 quantity
    ) internal view returns (bool) {
        bytes32 data = keccak256(abi.encodePacked(_address, quantity));
        return signer == data.toEthSignedMessageHash().recover(signature);
    }

    ///@notice Function to return tokenURI.
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return
            string(
                abi.encodePacked(
                    baseURI,
                    Strings.toString(_tokenId),
                    uriExtension
                )
            );
    }

    ///@notice Overriding the default tokenID start to 1.
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}