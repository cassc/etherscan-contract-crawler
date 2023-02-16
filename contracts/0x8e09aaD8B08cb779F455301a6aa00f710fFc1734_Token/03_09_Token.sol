// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

interface TokenMetadataInterface {
    function tokenURI(uint256 token) external view returns (string memory);
}

interface IToken {
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function setApprovalForAll(address operator, bool approved) external;
}

contract Token is DefaultOperatorFilterer, ERC721A, Ownable {
    string private _name;
    string private _symbol;
    string private _metadataRoot;
    string private _contractMetadataRoot;
    uint256 private _maxSupply;
    address public _mintContract;
    address public _burnContract;
    address public _metadataContract;
	bool private _enforceRoyalties;

    event MetadataContractUpdated(address contractAddress);

    modifier onlyBurner() {
        require(
            msg.sender == _burnContract,
            "Only burning contract can burn tokens."
        );
        _;
    }

    modifier onlyMinter() {
        require(
            msg.sender == _mintContract,
            "Only mint contract can mint tokens."
        );
        _;
    }

	modifier onlyAllowedOperator(address from) override {
		if (_enforceRoyalties) {
			if (from != msg.sender) {
				_checkFilterOperator(msg.sender);
			}
		}
		_;
	}

	modifier onlyAllowedOperatorApproval(address operator) override {
		if (_enforceRoyalties) {
			_checkFilterOperator(operator);
		}
		_;
	}

    constructor(
        string memory name_,
        string memory symbol_,
        string memory metadataRoot_,
        string memory contractMetadataRoot_,
        uint256 maxSupply_
    ) ERC721A(name_, symbol_) {
        _name = name_;
        _symbol = symbol_;
        _metadataRoot = metadataRoot_;
        _contractMetadataRoot = contractMetadataRoot_;
        _maxSupply = maxSupply_;
		_enforceRoyalties = true;
    }

    function updateTokenInfo(
        string memory name_,
        string memory symbol_,
        string memory metadataRoot_,
        string memory contractMetadataRoot_,
		bool enforceRoyalties_
    ) public onlyOwner {
        _name = name_;
        _symbol = symbol_;
        _metadataRoot = metadataRoot_;
        _contractMetadataRoot = contractMetadataRoot_;
		_enforceRoyalties = enforceRoyalties_;
    }

    function setMintContract(address addr) public onlyOwner {
        _mintContract = addr;
    }

    function mintContract() public view returns (address) {
        return _mintContract;
    }

    function setBurnContract(address addr) public onlyOwner {
        _burnContract = addr;
    }

    function burnContract() public view returns (address) {
        return _burnContract;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function _baseURI() internal view override returns (string memory) {
        return _metadataRoot;
    }

    function tokenURI(uint256 token)
        public
        view
        override
        returns (string memory)
    {
        if (_metadataContract != address(0)) {
            return TokenMetadataInterface(_metadataContract).tokenURI(token);
        }

        return ERC721A.tokenURI(token);
    }

    function setMetadataContract(address c) public onlyOwner {
        _metadataContract = c;
        emit MetadataContractUpdated(c);
    }

    function contractURI() public view returns (string memory) {
        return _contractMetadataRoot;
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function batchSafeTransferFrom(
        address[] calldata from,
        address[] calldata to,
        uint64[] calldata tokens
    ) public {
        require(
            from.length == to.length && to.length == tokens.length,
            "Array mismatch"
        );
        for (uint256 i = 0; i < from.length; i++) {
            safeTransferFrom(from[i], to[i], tokens[i]);
        }
    }

    function mint(address to, uint256 quantity) public onlyMinter {
        require(
            quantity + _totalMinted() <= _maxSupply,
            "Quantity exceeds max supply."
        );

        _safeMint(to, quantity);
    }

    function burn(uint256 token) public onlyBurner {
        _burn(token, true);
    }

	function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) payable public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) payable public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) payable public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
		payable
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}