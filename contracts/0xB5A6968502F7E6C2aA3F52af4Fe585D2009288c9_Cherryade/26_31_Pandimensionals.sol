// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "./ERC721Base.sol";
import "./MerkleProof.sol";

/** -----------------------------
*   This contract was developed by DanTheDev(at)protonmail.com
*   If you have questions, (constructive) feedback or need a smart contract developer, please get in touch
*   -----------------------------
*/
contract Pandimensionals is ERC721Base {

    // Custom Errors
    error PresaleNotActive();
    error PublicSaleNotActive();
    error NotWhitelisted();

    // VARIABLES
    bytes32 public merkleRoot;
    uint8 public constant maxNoOfWhitelistMints = 1;
    uint8 public constant maxNoOfPublicMints = 10;
    uint256 public startOfPresale;
    uint256 public endOfPresale;
    uint256 public endOfPublicSale;

    mapping(address => uint256) public whitelistMinted;
    mapping(address => uint256) public publicMinted;

    // FUNCTIONS
    function __Pandimensionals_init(uint256 _maxTotalSupply) external initializer {
        __ERC721Base_init(
            "Pandimensionals",                                          // name
            "PAN",                                                      // symbol
            "ipfs://QmQSKBtJzag5eDSKNKJC6DGawLgMGGHaJ2gMofLxGTQ2H8/",    // initialBaseURI
            "https://pandimensionals.mypinata.cloud/ipfs/QmeKwCM1VVFFa9XJJeWJKqS8FqHshzmEZQv1JcaJq4aP9B",    // contractURI NEW
            5 * 10 ** 16,                                               // initial token (mint) price - 0.05 ether
            250,                                                        // team reserve
            _maxTotalSupply                                             // maxTotalSupply
        );
        endOfPublicSale = block.number;
        endOfPresale = block.number;
        address owner = address(0xE0A67B78555827b3758531c1Ff938199a3512F15);
        _setupRole(DEFAULT_ADMIN_ROLE,owner);
        _setupRole(MANAGE_COLLECTION_ROLE, owner);
        _setupRole(MANAGE_COLLECTION_ROLE, _msgSender());
        _setupRole(PAUSABILITY_ROLE, owner);
        _setupRole(MANAGE_UPGRADES_ROLE, owner);
    }

    function whitelistMint(bytes32[] calldata _merkleProof, uint256 _mintAmount) external payable ensurePayment(1) {
        if (!isWhitelisted(_merkleProof))
            revert NotWhitelisted();
        if (block.number < startOfPresale || block.number > endOfPresale)
            revert PresaleNotActive();
        if (whitelistMinted[_msgSender()] + _mintAmount > maxNoOfWhitelistMints)
            revert MaxMintsReached();
        whitelistMinted[_msgSender()] += _mintAmount;
        _batchMint(_msgSender(), _mintAmount * 3);      // buy 1, get 2 free
    }

    function publicMint(uint256 _mintAmount) external payable ensurePayment(_mintAmount)  {
        if (block.number < endOfPresale || block.number > endOfPublicSale) {
            revert PublicSaleNotActive();
        }
        if (publicMinted[_msgSender()] + _mintAmount > maxNoOfPublicMints) {
            revert MaxMintsReached();
        }
        publicMinted[_msgSender()] += _mintAmount;
        _batchMint(_msgSender(), _mintAmount);
    }

    function isWhitelisted(bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 merkleLeaf = keccak256(abi.encodePacked(_msgSender()));
        if (MerkleProof.verify(_merkleProof, merkleRoot, merkleLeaf)) {
            return true;
        } else {
            return false;
        }
    }

    function addNewWhitelist(bytes32 newMerkleRoot) external onlyRoleCustom(MANAGE_COLLECTION_ROLE) {
        merkleRoot = newMerkleRoot;
    }

    function manageSalesPeriods(
        uint256 _startOfPresale,
        uint256 _endOfPresale,
        uint256 _endOfPublicSale)
    external onlyRoleCustom(MANAGE_COLLECTION_ROLE) {
        startOfPresale = _startOfPresale;
        endOfPresale = _endOfPresale;
        endOfPublicSale = _endOfPublicSale;
    }
}