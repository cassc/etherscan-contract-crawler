// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BeiBei is Ownable, ERC721AQueryable, ERC2981 {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint16 public ROYALTY_BASIS_POINT = 750;
    uint16 public constant MAX_SUPPLY = 500;
    uint16 public constant MAX_GENESIS_SUPPLY = 50;
    uint16 public constant MAX_ALPHA_SUPPLY = 450;

    uint8 public constant MAX_MINT_PUBLIC_GENESIS = 2;
    uint8 public constant MAX_MINT_PUBLIC_ALPHA = 2;
    uint8 public constant MAX_MINT_PRESALE_ALPHA = 1;
    uint8 public constant MAX_MINT_PRESALE_GENESIS = 1;

    uint8 public constant TEAM_MINT_GENESIS_AMOUNT = 20;
    uint8 public constant TEAM_MINT_ALPHA_AMOUNT = 50;

    uint256 public constant PUBLIC_SALE_GENESIS_PRICE = .1 ether;
    uint256 public constant PRESALE_GENESIS_PRICE = 0 ether;

    uint256 public constant PUBLIC_SALE_ALPHA_PRICE = .025 ether;
    uint256 public constant PRESALE_ALPHA_PRICE = 0 ether;

    string private baseTokenUri;
    uint16 public TOTAL_GENESIS_MINTED;
    uint16 public TOTAL_ALPHA_MINTED;

    //deploy smart contract, toggle WL, toggle WL when done, toggle isPublicSale
    //2 days later toggle reveal
    bool public isPublicSale;
    bool public isPresale;

    bytes32 private merkleRoot;

    mapping(address => uint16) public totalGenesisPresaleMinted;
    mapping(address => uint16) public totalGenesisPublicSaleMinted;
    mapping(address => uint16) public totalAlphaPresaleMinted;
    mapping(address => uint16) public totalAlphaPublicSaleMinted;
    mapping(uint256 => bool) public isGenesisMap;

    enum TierEnum {
        Genesis,
        Alpha
    }

    constructor(address payable royaltyReceiver)
        ERC721A("BeiBei Adventurers Guild", "BeiBei")
    {
        _setDefaultRoyalty(royaltyReceiver, ROYALTY_BASIS_POINT);
        _teamMint();
    }

    modifier callerIsUser() {
        require(
            tx.origin == msg.sender,
            "Bei Bei :: Cannot be called by a contract"
        );
        _;
    }

    function setIsGenesis(uint16 _quantity, bool isGenesis) internal {
        for (uint256 i = 0; i < _quantity; i++) {
            isGenesisMap[_tokenIds.current()] = isGenesis;
            _tokenIds.increment();
        }
    }

    function mintGenesisPublic(uint16 _quantity) external payable callerIsUser {
        require(isPublicSale, "Bei Bei :: Public Sale Not Yet Active.");
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "Bei Bei :: Cannot mint beyond max supply"
        );
        require(
            (TOTAL_GENESIS_MINTED + _quantity) <= MAX_GENESIS_SUPPLY,
            "Bei Bei :: Beyond Max Supply for Minting Genesis"
        );
        require(
            (totalGenesisPublicSaleMinted[msg.sender] + _quantity) <=
                MAX_MINT_PUBLIC_GENESIS,
            "Bei Bei :: Already minted max allowed amount!"
        );
        require(
            msg.value >= (PUBLIC_SALE_GENESIS_PRICE * _quantity),
            "Bei Bei :: Payment is below the price"
        );

        TOTAL_GENESIS_MINTED += _quantity;
        totalGenesisPublicSaleMinted[msg.sender] += _quantity;
        setIsGenesis(_quantity, true);
        _safeMint(msg.sender, _quantity);
        refundIfOver(PUBLIC_SALE_GENESIS_PRICE * _quantity);
    }

    function mintAlphaPublic(uint16 _quantity) external payable callerIsUser {
        require(isPublicSale, "Bei Bei :: Public Sale Not Yet Active.");
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "Bei Bei :: Cannot mint beyond max supply"
        );
        require(
            (TOTAL_ALPHA_MINTED + _quantity) <= MAX_ALPHA_SUPPLY,
            "Bei Bei :: Beyond Max Supply for Minting Alpha"
        );
        require(
            (totalAlphaPublicSaleMinted[msg.sender] + _quantity) <=
                MAX_MINT_PUBLIC_ALPHA,
            "Bei Bei :: Already minted max allowed amount!"
        );
        require(
            msg.value >= (PUBLIC_SALE_ALPHA_PRICE * _quantity),
            "Bei Bei :: Payment is below the price"
        );

        TOTAL_ALPHA_MINTED += _quantity;
        totalAlphaPublicSaleMinted[msg.sender] += _quantity;
        setIsGenesis(_quantity, false);
        _safeMint(msg.sender, _quantity);
        refundIfOver(PUBLIC_SALE_ALPHA_PRICE * _quantity);
    }

    function mintGenesisPresale(bytes32[] memory _merkleProof, uint16 _quantity)
        external
        payable
        callerIsUser
    {
        require(isPresale, "Bei Bei :: Presale Not Yet Active");
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "Bei Bei :: Cannot mint beyond max supply"
        );
        require(
            (TOTAL_GENESIS_MINTED + _quantity) <= MAX_GENESIS_SUPPLY,
            "Bei Bei :: Beyond Max Supply for Minting Genesis"
        );
        require(
            (totalGenesisPresaleMinted[msg.sender] + _quantity) <=
                MAX_MINT_PRESALE_GENESIS,
            "Bei Bei :: Cannot mint beyond presale max mint!"
        );
        require(
            msg.value >= (PRESALE_GENESIS_PRICE * _quantity),
            "Bei Bei :: Payment is below the price"
        );
        //create leaf node
        bytes32 sender = keccak256(abi.encode(TierEnum.Genesis, msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, sender),
            "Bei Bei :: You are not in whitelist"
        );

        TOTAL_GENESIS_MINTED += _quantity;
        totalGenesisPresaleMinted[msg.sender] += _quantity;
        setIsGenesis(_quantity, true);
        _safeMint(msg.sender, _quantity);
        refundIfOver(PRESALE_GENESIS_PRICE * _quantity);
    }

    function mintAlphaPresale(bytes32[] memory _merkleProof, uint16 _quantity)
        external
        payable
        callerIsUser
    {
        require(isPresale, "Bei Bei :: Presale Not Yet Active");
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "Bei Bei :: Cannot mint beyond max supply"
        );
        require(
            (TOTAL_ALPHA_MINTED + _quantity) <= MAX_ALPHA_SUPPLY,
            "Bei Bei :: Beyond Max Supply for Minting Alpha"
        );
        require(
            (totalAlphaPresaleMinted[msg.sender] + _quantity) <=
                MAX_MINT_PRESALE_ALPHA,
            "Bei Bei :: Cannot mint beyond presale max mint!"
        );
        require(
            msg.value >= (PRESALE_ALPHA_PRICE * _quantity),
            "Bei Bei :: Payment is below the price"
        );
        //create leaf node
        bytes32 sender = keccak256(abi.encode(TierEnum.Alpha, msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, sender),
            "Bei Bei :: You are not in whitelist"
        );

        TOTAL_ALPHA_MINTED += _quantity;
        totalAlphaPresaleMinted[msg.sender] += _quantity;
        setIsGenesis(_quantity, false);
        _safeMint(msg.sender, _quantity);
        refundIfOver(PRESALE_ALPHA_PRICE * _quantity);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function _teamMint() internal onlyOwner {
        TOTAL_GENESIS_MINTED += TEAM_MINT_GENESIS_AMOUNT;
        TOTAL_ALPHA_MINTED += TEAM_MINT_ALPHA_AMOUNT;
        setIsGenesis(TEAM_MINT_GENESIS_AMOUNT, true);
        setIsGenesis(TEAM_MINT_ALPHA_AMOUNT, false);
        _safeMint(msg.sender, TEAM_MINT_GENESIS_AMOUNT);
        _safeMint(msg.sender, TEAM_MINT_ALPHA_AMOUNT);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
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
        return
            string(
                abi.encodePacked(
                    isGenesisMap[tokenId]
                        ? "ipfs://Qmc9hcDdBMRCNDJYEJbWkFWLmw3prDMjP3yZnQCjUTQdwm"
                        : "ipfs://QmfVg8CpgYS7aGGbLQP6yJX8ERu8gUnMnpYMirNuT5v6AZ"
                )
            );
    }

    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function toggleIsPresale() external onlyOwner {
        isPresale = !isPresale;
    }

    function toggleIsPublicSale() external onlyOwner {
        isPublicSale = !isPublicSale;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}