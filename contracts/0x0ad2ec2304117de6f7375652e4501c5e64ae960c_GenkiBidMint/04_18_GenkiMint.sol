// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./GenkiBase.sol";
import "./closedsea/src/OperatorFilterer.sol";
/**
 * @author @inetdave
 * @dev v.01.00.00
 */
contract GenkiMint is GenkiBase, ERC721A, OperatorFilterer {
    constructor() ERC721A("GenkiMint", "GENKI") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
    }
    bool public operatorFilteringEnabled;

    string public baseURI;

    bytes32 public merkleRootWL;
    bytes32 public merkleRootOG;

    mapping(address => uint256) internal _alreadyMinted;

    /**
     * @dev handles minting from airdrop.
     * @param _to address to mint tokens to.
     * @param _number number of tokens to mint.
     */
    function _airdropMint(address _to, uint256 _number) internal {
        require(_totalMinted() + _number <= MAX_SUPPLY, "Max exceeded");
        _safeMint(_to, _number);
    }

    function _internalMint(
        address _to,
        uint256 _quantity,
        uint256 _price
    ) internal {
        require(msg.value == _price * _quantity, "Incorrect amount");
        require(_totalMinted() + _quantity <= MAX_SUPPLY, "Total exceeded");
        _safeMint(_to, _quantity);
    }

    /**
    * @notice WL Mint for OGs
    * @dev merklerootog should be set
    */
    function _verifyOG(bytes32[] calldata _merkleProof, address _sender)
        internal
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_sender));
        return MerkleProof.processProof(_merkleProof, leaf) == merkleRootOG;
    }

    /**
    * @notice WL Mint
    * @dev merklerootWL should be set
    */
    function _verifyWL(bytes32[] calldata _merkleProof, address _sender)
        internal
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_sender));
        return MerkleProof.processProof(_merkleProof, leaf) == merkleRootWL;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice used to store the whitelist of who has already minted
     */
    function alreadyMinted(address addr) public view returns (uint256) {
        return _alreadyMinted[addr];
    }

    // Start tokenid at 1 instead of 0
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}