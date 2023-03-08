// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IERC721.sol";

contract FarmersMarket is AccessControl {
    address public immutable token;
    string public tokenURI;
    bytes32 public merkleRoot;

    mapping(address => bool) public claimed;

    event Claim(address indexed claimer);

    constructor(address _token, string memory _tokenURI) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        token = _token;
        tokenURI = _tokenURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merkleRoot = _merkleRoot;
    }

    function claim(bytes32[] calldata merkleProof) external {
        require(
            canClaim(msg.sender, merkleProof),
            "FarmersMarket: Address is not a candidate for claim"
        );

        claimed[msg.sender] = true;

        IERC721(token).safeMint(msg.sender, tokenURI);

        emit Claim(msg.sender);
    }

    function canClaim(address claimer, bytes32[] calldata merkleProof)
        public
        view
        returns (bool) 
    {
        return 
            !claimed[claimer] &&
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(claimer))
            );
    }
}