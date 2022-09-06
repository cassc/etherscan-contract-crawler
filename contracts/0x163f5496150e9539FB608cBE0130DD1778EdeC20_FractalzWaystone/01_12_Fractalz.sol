// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./token/ERC1155.sol";

contract FractalzWaystone is ERC1155, IERC2981, Ownable {

    string public name = "Fractalz Waystone";
    string public symbol = "WAYSTONE";

    string private baseURI;

    bytes32 public whitelistMerkleRoot;
    uint256 public maxSupply = 1200;
    uint256 public defaultToken = 1;
    uint256 public minted;
    
    uint256 internal toll = 500;

    bool public publicActive  = false;
    bool public presaleActive = false;

    mapping(uint256 => string) private tokenURIs;
    mapping(address => uint) public addressClaimed;

    constructor(
        string memory _baseURI
    ) ERC1155(){
        baseURI = _baseURI;
    }

    // Public Functions
    function allowlistMint(bytes32[] calldata _merkleProof) external {
        require(presaleActive, "Sale has not started yet.");
        require(addressClaimed[_msgSender()] < 1, "Exceeds mint allocation");
        require(minted < maxSupply, "Exceeds max supply");

        // Verify merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf), "Invalid proof");
        minted++;
        addressClaimed[_msgSender()]++;
        _craftTokens(msg.sender,defaultToken,1,'');
    }

    function mint() external {
        require(publicActive, "Sale has not started yet.");
        require(addressClaimed[_msgSender()] < 1, "Exceeds mint allocation");
        require(minted < maxSupply, "Exceeds max supply");
        minted++;
        addressClaimed[_msgSender()]++;
        _craftTokens(msg.sender,defaultToken,1,'');
    }

    function uri(
        uint256 token
    ) public view virtual override returns (string memory) {
        string memory tokenURI = tokenURIs[token];
        return bytes(tokenURI).length > 0 ? tokenURI : baseURI;
    }


    // Team Functions
    function teamMint(
        uint256 _token,
        uint256 _quantity
    ) external onlyOwner {
        _craftTokens(msg.sender,_token,_quantity,'');
    }

    function airdropTokens(
        address[] memory _to,
        uint256 _token,
        uint256 _quantity
    ) external onlyOwner {
        for (uint256 i = 0; i < _to.length; i++) {
            _craftTokens(_to[i],_token,_quantity,'');
        }
    }

    function burn(
        address _from,
        uint256 _token,
        uint256 _quantity
    ) external onlyOwner {
        _burn(_from,_token,_quantity);
    }

    function setURI(
        uint256 _token,
        string memory _tokenURI
    ) external onlyOwner {
        tokenURIs[_token] = _tokenURI;
        emit URI(uri(_token), _token);
    }

    function setBaseURI(
        string memory _baseURI
    ) external onlyOwner {
        baseURI = _baseURI;
    }

    function enableMint(bool _publicActive) external onlyOwner {
        publicActive = _publicActive;
    }

    function enablePresale(bool _presaleActive) external onlyOwner {
        presaleActive = _presaleActive;
    }

    function setDefaultToken(
        uint256 _defaultToken
    ) external onlyOwner {
        defaultToken = _defaultToken;
    }

    function setRoyalty(uint256 _toll) external onlyOwner {
        require(_toll < 2500, "Royalty over 25%");
        toll = _toll;
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) external onlyOwner {
      whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(
        uint256,
        uint256 _salePrice
    ) public view virtual override returns (address, uint256) {
        uint256 royaltyAmount = (_salePrice * toll) / 10000;
        return (owner(), royaltyAmount);
    }

    /**
     * @dev {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, IERC165) returns (bool) {
        return
        interfaceId == type(IERC1155).interfaceId ||
        interfaceId == type(IERC1155MetadataURI).interfaceId ||
        interfaceId == type(IERC2981).interfaceId ||
        super.supportsInterface(interfaceId);
    }
}