// Authored by NoahN w/ Metavate ✌️
pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract ElevenPedals is ERC721A, ReentrancyGuard, DefaultOperatorFilterer {
    using Strings for uint256;

    //------------------//
    //     VARIABLES    //
    //------------------//
    uint256 public cost = 0.057 ether;
    uint256 private _maxSupply = 180;
    uint256 public mintLimit = 11;
    uint256 public metadataURIrange = 45; 

    bool public sale = false;
    bool public frozen = false;

    string public baseURI;
    string public metadataExtension = ".json";

    address private _owner;
    address private ethRecipient = 0xB0065ccc521BBAF8E6c133A45EA0A1C268B77588;

    mapping(uint256 => string) public metadataURI; //metadata URI to be inserted in groups

    error Paused();
    error MaxSupply();
    error BadInput();
    error AccessDenied();
    error EthValue();
    error MintLimit();

    constructor(string memory _name, string memory _symbol)
        ERC721A(_name, _symbol)
    {
        _owner = msg.sender;
        _safeMint(_owner, 1);
    }

    //------------------//
    //     MODIFIERS    //
    //------------------//

    modifier onlyTeam() {
        if (msg.sender != _owner) {
            revert AccessDenied();
        }
        _;
    }

    //------------------//
    //       MINT       //
    //------------------//

    function mint(uint256 mintQty, address reciever) external payable {
        if (sale == false) revert Paused();
        if (mintQty * cost != msg.value) revert EthValue();
        if (mintQty > mintLimit) revert MintLimit();
        if (mintQty + _totalMinted() > _maxSupply) revert MaxSupply();

        _safeMint(reciever, mintQty);
    }

    function devMint(uint256 mintQty, address recipient) external onlyTeam {
        if (mintQty + _totalMinted() > _maxSupply) revert MaxSupply();
        _safeMint(recipient, mintQty);
    }

    function devMint(uint256[] calldata quantity, address[] calldata recipient)
        external
        onlyTeam
    {
        if (quantity.length != recipient.length) revert BadInput();
        uint256 totalQuantity = 0;
        for (uint256 i = 0; i < quantity.length; ++i) {
            totalQuantity += quantity[i];
        }

        if (totalQuantity + _totalMinted() > _maxSupply) revert MaxSupply();
        for (uint256 i = 0; i < recipient.length; ++i) {
            _safeMint(recipient[i], quantity[i]);
        }
    }

    //------------------//
    //      SETTERS     //
    //------------------//

    function setBaseURI(string memory _newBaseURI) external onlyTeam {
        if (frozen == true) {
            revert Paused();
        }
        baseURI = _newBaseURI;
    }

    function toggleSale() external onlyTeam {
        sale = !sale;
    }

    function setCost(uint256 _cost) external onlyTeam {
        cost = _cost;
    }

    function setMetadataExtension(string memory _newExtension) external onlyTeam {
        if (frozen == true) {
            revert Paused();
        }
        metadataExtension = _newExtension;
    }

    function setMetadataURI(uint256 group, string calldata _metadataURI)
        external
        onlyTeam
    {
        if (bytes(metadataURI[group]).length != 0 && frozen == true) {
            revert Paused();
        }
        metadataURI[group] = _metadataURI;
    }

    function freezeMetadata() external onlyTeam {
        frozen = true;
    }

    function setMintLimit(uint256 _mintLimit) external onlyTeam {
        mintLimit = _mintLimit;
    }


    //------------------//
    //      GETTERS     //
    //------------------//

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        // Groups into folders using integer division.
        // Each folder has a separate IPFS/arweave hash that is set by writing to the mapping metadataURI
        uint256 grouping = (tokenId - _startTokenId()) / metadataURIrange;
        if (bytes(metadataURI[grouping]).length == 0) {
            return
                string(
                    abi.encodePacked(baseURI, tokenId.toString(), metadataExtension)
                );
        } else {
            return
                string(
                    abi.encodePacked(
                        metadataURI[grouping],
                        tokenId.toString(),
                        metadataExtension
                    )
                );
        }
    }

    function maxSupply() external view returns (uint256) {
        return _maxSupply;
    }

    function owner() external view returns (address) {
        return _owner;
    }


    //------------------//
    //       MISC       //
    //------------------//

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1; 
    }

    function withdraw() external nonReentrant onlyTeam {
        payable(ethRecipient).transfer(address(this).balance);
    }

    /* Operator Filter */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public 
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    fallback() external payable {}

    receive() external payable {}
}