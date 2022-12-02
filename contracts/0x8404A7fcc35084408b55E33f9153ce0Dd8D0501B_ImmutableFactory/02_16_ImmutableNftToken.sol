// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721r.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract ImmutableType is ERC721r, Pausable, ERC2981 {

    uint256 public cost;
    uint256 public mintTime;
    uint256 public freeMints;
    uint256 public startMint;
    uint256 public mintedNft;
    uint256 public maxPerWallet;
    string public baseURI;
    string public contractURI;
    address private withdrawAddress =
        0x518593679b0c0D91aF42f163Bc1253e5A2903B89;
    address public ImmutableTypeAdmin =
        0x518593679b0c0D91aF42f163Bc1253e5A2903B89; //TODO: update the admin
    mapping(address => uint) public mints;

    modifier timesUp() {
        require(
            mintTime >= block.timestamp || msg.sender == ImmutableTypeAdmin,
            "ImmutableType: Minting Time is over."
        );
        _;
    }
    modifier ImmmutableAdmin() {
        require(
            tx.origin == ImmutableTypeAdmin,
            "ImmutableType: Only Admin is allowed."
        );
        _;
    }

    modifier start() {
        require(
            block.timestamp > startMint || msg.sender == ImmutableTypeAdmin,
            "ImmutableType: Minting not Started or is not ImmutableTypeAdmin"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _contractURI,
        uint _cost,
        uint _maxSupplyy,
        uint _freeMints,
        uint _startDate,
        uint _endDate,
        uint _maxPerWallet,
        uint96 _royaltyFeesInBips
    ) ERC721r(_name, _symbol, (_maxSupplyy > 1440 ? 1440 : _maxSupplyy)) {
        baseURI = _initBaseURI;
        contractURI = _contractURI;
        cost = _cost;
        freeMints = _freeMints;
        startMint = _startDate;
        maxPerWallet = _maxPerWallet;
        mintTime = _endDate;
        setRoyaltyInfo(withdrawAddress, _royaltyFeesInBips);
    }

    function setRoyaltyInfo(
        address _receiver,
        uint96 _royaltyFeesInBips
    ) public ImmmutableAdmin {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    function mint(uint256 _quantity) public payable timesUp start {
        uint _mintedNft = mintedNft;
        require(_mintedNft + _quantity <= maxSupply(), "ImmutableType: Not enough NFTs left to mint");
        require(mints[msg.sender] + _quantity <= maxPerWallet, "ImmutableType: max mint per wallet reached");

        if (_mintedNft > freeMints) {
            require(msg.value == _quantity*cost, "ImmutableType: Not enough eth to mint");
            mints[msg.sender] += _quantity;
            _mintRandom(msg.sender, _quantity);
            mintedNft += _quantity;
            (bool success, ) = payable(withdrawAddress).call{
                value: address(this).balance
            }("");
            require(success);
        } else {
            mints[msg.sender] += _quantity;
            _mintRandom(msg.sender, _quantity);
            mintedNft += _quantity;
            (bool success, ) = payable(withdrawAddress).call{
                value: address(this).balance
            }("");
            require(success);
        }
    }
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721r, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setContractURI(string memory _contractURI) public ImmmutableAdmin {
        contractURI = _contractURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);
        return baseURI;
    }
    function setImmutableAdmin(address _newAdminAddress) public ImmmutableAdmin {
        ImmutableTypeAdmin = _newAdminAddress;
    }
}