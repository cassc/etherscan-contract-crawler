// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract TDCArtaThonLtdEd is ERC721, Ownable, AccessControl {
    using Strings for uint256;

    //Interface for royalties
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public _totalSupply;

    mapping(uint => address) public tokenArtists;

    address public royaltyRecipient;
    uint24 public royaltyAmount;

    string private _baseURIPrefix = "";

    // Opensea
    string public contractURI = "";

    constructor() ERC721("TDC Art-a-Thon - Limited Editions", "TDCArtaThonLtdEd") {
        // Initialize owner access control
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());

        royaltyRecipient = _msgSender();
        royaltyAmount = 500;
    }

    modifier onlyOwnerorAdmin() {
        require(
            _msgSender() == owner() ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Only addresses with admin role can perform this action"
        );
        _;
    }

    modifier onlyMinter() {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Only addresses with minter role can perform this action."
        );
        _;
    }

    function incrementTotalSupply(uint256 _addUnits) public onlyMinter {
        uint256 currentSupply = _totalSupply;
        address _owner = owner();
        for (uint256 index = currentSupply; index < currentSupply + _addUnits; index++) {
          emit Transfer(address(0), _owner, index);
        }
        _totalSupply = currentSupply + _addUnits;
    }

    function setTokenArtist(uint startToken, uint endToken, address artist) external onlyOwnerorAdmin {
        for (uint256 index = startToken; index <= endToken; index++) {
            require(index < _totalSupply, "Art-a-Thon Limited Edition token does not exist");
            tokenArtists[index] = artist;
        }
    }


    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function setBaseURI(string memory baseURIPrefix) external onlyOwner {
        _baseURIPrefix = baseURIPrefix;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(tokenId < _totalSupply, "Invalid token Id");
        return
            bytes(_baseURIPrefix).length > 0
                ? string(
                    abi.encodePacked(
                        _baseURIPrefix,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function supportsInterface(bytes4 interfaceID) public view override(ERC721, AccessControl)
        returns (bool)
    {
        //*** return super.supportsInterface(interfaceID);
        if(interfaceID == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return ERC721.supportsInterface(interfaceID);
    }

    // https://docs.opensea.io/docs/contract-level-metadata
    function setContractURI(string memory newContractURI) external onlyOwner {
        contractURI = newContractURI;
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(tokenId < _totalSupply, "Invalid token Id");

        address tokenOwner = _ownerOf(tokenId);
        if (tokenOwner != address(0)) {
            return tokenOwner;
        }
        return owner();
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(tokenId < _totalSupply, "Invalid token Id");

        if (_exists(tokenId)) {
            _transfer(from, to, tokenId);
            return;
        }
        require(
            _msgSender() == from || isApprovedForAll(from, _msgSender()),
            "Caller is not token owner or approved for all"
        );
        _mint(to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(tokenId < _totalSupply, "Invalid token Id");
        if (_exists(tokenId)) {
            _safeTransfer(from, to, tokenId, data);
            return;
        }
        require(
            _msgSender() == from || isApprovedForAll(from, _msgSender()),
            "Caller is not token owner or approved for all"
        );

        _safeMint(to, tokenId);
    }

    // EIP2981
    // Amount is percentage to two decimal points and should be between 0 and 10000, where 10000 = 100.00 percent
    function setRoyalty(address royaltyAddress, uint24 amount) external onlyOwnerorAdmin {
        royaltyRecipient = royaltyAddress;
        royaltyAmount = amount;
    }

    function royaltyInfo(uint256, uint256 value) external view
        returns (address receiver, uint256 amount)
    {
        receiver = royaltyRecipient;
        amount = (value * royaltyAmount) / 10000;
    }

}