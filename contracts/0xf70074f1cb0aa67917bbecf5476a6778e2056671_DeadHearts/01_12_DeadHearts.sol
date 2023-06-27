// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*

Deadfellaz 💀 x The Heart Project ❤️ presents...

><<<<<                             ><< ><<     ><<                             ><<         
><<   ><<                          ><< ><<     ><<                             ><<         
><<    ><<   ><<       ><<         ><< ><<     ><<   ><<       ><<    >< ><<<><>< >< ><<<< 
><<    ><< ><   ><<  ><<  ><<  ><< ><< ><<<<<< ><< ><   ><<  ><<  ><<  ><<     ><<  ><<    
><<    ><<><<<<< ><<><<   ><< ><   ><< ><<     ><<><<<<< ><<><<   ><<  ><<     ><<    ><<< 
><<   ><< ><        ><<   ><< ><   ><< ><<     ><<><        ><<   ><<  ><<     ><<      ><<
><<<<<      ><<<<     ><< ><<< ><< ><< ><<     ><<  ><<<<     ><< ><<<><<<      ><< ><< ><<

(Dead Hearts) 

dev by Luke Davis (luke.onl) & Fraser (@jalfrazi_)

*/

contract DeadHearts is Ownable, ERC1155 {
    using Strings for uint256;

    string private _baseTokenURI;

    bytes32 private _normalTierMerkleRoot;
    bytes32 private _rareTierMerkleRoot;

    mapping(address => bool) private hasClaimed;

    bool public isClaimEnabled = false;

    constructor() ERC1155("") {}

    modifier claimEnabledOnly() {
        require(isClaimEnabled, "Claim window is closed.");
        _;
    }

    function toggleClaimStatus() external onlyOwner {
        isClaimEnabled = !isClaimEnabled;
    }

    function claimDeadHeart(bytes32[] calldata _merkleProof)
        external
        claimEnabledOnly
    {
        require(
            !hasClaimed[msg.sender],
            "You have already claimed your Dead Heart."
        );

        if (_verify(_merkleProof, _rareTierMerkleRoot, msg.sender)) {
            _mint(msg.sender, 1, 1, "");
        } else if ((_verify(_merkleProof, _normalTierMerkleRoot, msg.sender))) {
            _mint(msg.sender, 0, 1, "");
        } else {
            revert("Not eligible for claiming.");
        }

        hasClaimed[msg.sender] = true;
    }

    function _verify(
        bytes32[] memory _merkleProof,
        bytes32 _merkleRoot,
        address _addr
    ) internal pure returns (bool) {
        return
            MerkleProof.verify(
                _merkleProof,
                _merkleRoot,
                keccak256(abi.encodePacked(_addr))
            );
    }

    function hasClaimedDeadHeart(address addr) public view returns (bool) {
        return hasClaimed[addr];
    }

    function setNormalTierMerkleRoot(bytes32 _newRoot) external onlyOwner {
        _normalTierMerkleRoot = _newRoot;
    }

    function setRareTierMerkleRoot(bytes32 _newRoot) external onlyOwner {
        _rareTierMerkleRoot = _newRoot;
    }

    function setURI(string memory _newURI) external onlyOwner {
        _baseTokenURI = _newURI;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}