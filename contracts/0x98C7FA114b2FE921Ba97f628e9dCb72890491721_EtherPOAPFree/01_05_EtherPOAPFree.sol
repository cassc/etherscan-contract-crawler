// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EtherPOAPFree is ERC721A, Ownable {
    //the number of address in genesis block
    uint256 public genesisSupply = 8893;
    uint256 public supply = 10000;
    //phase 0: not active time to mint
    //phase 1: active time for mint
    uint256 public phase;
    string  public baseURI;
    address public signer;
    mapping(address => bool) public minted;
    //whilelist merkle
    bytes32 public root;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) ERC721A(name_, symbol_) {
        baseURI = baseURI_;
    }

    function setBaseURI(string memory baseUri) external onlyOwner {
        baseURI = baseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setPhase(uint256 phase_) external onlyOwner {
        phase = phase_;
    }

    function setSigner(address signer_) public onlyOwner {
        signer = signer_;
    }

    function setRoot(bytes32 root_) public onlyOwner {
        root = root_;
    }

    function mint(bytes memory evidence, bytes32[] memory proof) public {
        require(totalSupply() + 1 <= supply, "exceed supply");
        require(_validate(keccak256(abi.encodePacked(msg.sender)), evidence), "invalid evidence");
        require(verify(keccak256(abi.encodePacked(msg.sender)), proof), "user is not in the list this phase");
        require(!minted[msg.sender], "user has minted");
        require(phase == 1, "not in active time for mint");
        minted[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function batchMint(address[] memory addrs) public onlyOwner {
        require(totalSupply() + addrs.length <= genesisSupply, "exceed genesis supply");
        for (uint256 i = 0; i < addrs.length; i++) {
            _safeMint(addrs[i], 1);
        }
    }

    function tokensOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 balance = balanceOf(_owner);
        uint256[] memory tokens = new uint256[](balance);
        uint256 index;
        unchecked {
            uint256 totalSupply = totalSupply();
            for (uint256 i; i < totalSupply; i++) {
                if (ownerOf(i) == _owner) {
                    tokens[index] = uint256(i);
                    index++;
                }
            }
        }
        return tokens;
    }

    /// @dev validate signature msg
    function _validate(bytes32 message, bytes memory signature) internal view returns (bool) {
        require(signer != address(0) && signature.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v = uint8(signature[64]) + 27;
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
        }
        return ecrecover(message, v, r, s) == signer;
    }

    function verify(bytes32 leaf, bytes32[] memory proof) public view returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}