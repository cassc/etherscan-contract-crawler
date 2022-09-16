//SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./Kumaleon.sol";

contract KumaleonMinter is Ownable, ReentrancyGuard {
    uint256 private constant OWNER_ALLOTMENT = 450;
    uint256 private _totalOwnerMinted;
    bytes32 public merkleRoot;
    bool public isAllowlistMintActive;
    bool public isPublicMintActive;
    mapping(bytes32 => bool) public isMinted;
    Kumaleon public kumaleon;

    function allowlistMint(
        uint8[] memory _grades,
        uint256[] memory _quantities,
        bytes32[][] calldata proofs
    ) external nonReentrant {
        require(isAllowlistMintActive, "KumaleonMinter: mint is not opened");
        require(_grades.length != 0, "KumaleonMinter: no mint is available");
        require(
            _grades.length == _quantities.length && _quantities.length == proofs.length,
            "KumaleonMinter: invalid length"
        );

        uint256 quantity;
        for (uint256 i = 0; i < _grades.length; i++) {
            bytes32 leaf = keccak256(abi.encode(msg.sender, _grades[i], _quantities[i]));
            require(
                MerkleProof.verify(proofs[i], merkleRoot, leaf),
                "KumaleonMinter: Invalid proof"
            );
            require(!isMinted[leaf], "KumaleonMinter: already minted");

            isMinted[leaf] = true;
            quantity += _quantities[i];
        }
        kumaleon.mint(msg.sender, quantity);
    }

    function publicMint() external nonReentrant {
        require(isPublicMintActive, "KumaleonMinter: mint is not opened");
        kumaleon.mint(msg.sender, 1);
    }

    function ownerMint(address _to, uint256 _quantity) external onlyOwner {
        require(
            _totalOwnerMinted + _quantity <= OWNER_ALLOTMENT,
            "KumaleonMinter: invalid quantity"
        );
        _totalOwnerMinted += _quantity;
        kumaleon.mint(_to, _quantity);
    }

    function setIsAllowlistMintActive(bool _isAllowlistMintActive) external onlyOwner {
        require(merkleRoot != 0, "KumaleonMinter: merkleRoot is not set");
        isAllowlistMintActive = _isAllowlistMintActive;
    }

    function setIsPublicMintActive(bool _isPublicMintActive) external onlyOwner {
        isPublicMintActive = _isPublicMintActive;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setKumaleonAddress(address _kumaleonAddress) external onlyOwner {
        kumaleon = Kumaleon(_kumaleonAddress);
    }
}