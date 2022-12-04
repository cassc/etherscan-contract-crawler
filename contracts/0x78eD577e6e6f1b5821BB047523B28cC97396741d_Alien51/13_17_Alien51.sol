// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// __________________________________   ________________
// ___    |__  /____  _/__  ____/__  | / /__  ____/_<  /
// __  /| |_  /  __  / __  __/  __   |/ /______ \ __  /
// _  ___ |  /____/ /  _  /___  _  /|  /  ____/ / _  /
// /_/  |_/_____/___/  /_____/  /_/ |_/  /_____/  /_/

import "./erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Alien51 is ERC721A, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;

    // settings
    uint256 public constant MAX_SUPPLY = 1500; // 1500 total
    uint256 public constant MAX_WHITELIST = 1075; // 1075 total whitelist
    uint256 public constant MAX_UFOLIST = 375; // 375 total whitelist
    uint256 public constant MAX_WHITELIST_MINT = 2; // 2 per wallet
    uint256 public constant MAX_UFO_MINT = 1; //  1 per wallet
    uint256 public constant MAX_PUBLIC_MINT = 5; // 5 per wallet
    uint256 public constant PUBLIC_SALE_PRICE = 0.0269 ether;
    uint256 public constant WHITELIST_SALE_PRICE = 0.0169 ether;

    // URI
    string private baseTokenUri;
    string public placeholderTokenUri;

    bool public isRevealed;
    bool public whitelistSale;
    bool public ufoSale;
    bool public teamSale;
    bool public publicSale;
    bool public pause;
    bool public teamMinted;

    bytes32 private merkleRoot;
    bytes32 private ufomerkleRoot;

    mapping(address => uint256) public totalWhitelistMint;
    mapping(address => uint256) public totalUFOMint;
    mapping(address => uint256) public totalPublicMint;

    constructor() ERC721A("Alien51", "A51") {}

    modifier callerIsUser() {
        require(
            tx.origin == msg.sender,
            "Alien51 :: Cannot be called by a contract"
        );
        _;
    }


    function whitelistMint(bytes32[] memory _merkleProof, uint256 _quantity)
        external
        payable
        callerIsUser
    {
        require(whitelistSale, "Alien51 :: Minting is on Pause");
        require(_quantity > 0, "Alien51 :: Must mint at least one alien");
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "Alien51 :: Sorry, mint is over"
        );
        require(
            (totalSupply() + _quantity) <= MAX_WHITELIST,
            "Alien51 :: Whitelist sold out!"
        );
        require(
            (totalWhitelistMint[msg.sender] + _quantity) <= MAX_WHITELIST_MINT,
            "Alien51 :: Cannot mint beyond whitelist max mint"
        );
        require(
            msg.value >= WHITELIST_SALE_PRICE * _quantity,
            "Alien51 :: Payment is below the price"
        );
        //create leaf node
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, sender),
            "Alien51 :: You are not whitelisted"
        );

        totalWhitelistMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function ufoMint(bytes32[] memory _ufomerkleProof, uint256 _quantity)
        external
        callerIsUser
    {
        require(ufoSale, "Alien51 :: Cannot mint right now");
        require(_quantity > 0, "Alien51 :: Must mint at least one alien");
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "Alien51 :: Ufo mint is over"
        );
        require(
            (totalSupply() + _quantity) <= MAX_UFOLIST,
            "Alien51 :: UFOlist sold out!"
        );
        require(
            (totalUFOMint[msg.sender] + _quantity) <= MAX_UFO_MINT,
            "Alien51 :: Cannot mint beyond ufo max mint"
        );
        //create leaf node
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_ufomerkleProof, ufomerkleRoot, sender),
            "Alien51 :: You are not on the UFO list"
        );

        totalUFOMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function teamMint(uint256 _quantity) external onlyOwner {
        require(teamSale, "Alien51 :: Team cannot mint right now");
        require(_quantity > 0, "Must mint at least one alien");
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "Alien51 :: SOLD OUT"
        );
        teamMinted = true;
        _safeMint(msg.sender, _quantity); // send 2 to team
    }

    function mint(uint256 _quantity) external payable callerIsUser {
        require(publicSale, "Alien51 :: Public sale not active");
        require(_quantity > 0, "Alien51 :: Must mint at least one alien");
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "Alien51 :: SOLD OUT!"
        );
        require(
            (totalPublicMint[msg.sender] + _quantity) <= MAX_PUBLIC_MINT,
            "Alien51:: Already minted 5 times"
        );
        require(
            msg.value >= PUBLIC_SALE_PRICE * _quantity,
            "Alien51 :: Below price"
        );

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
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

        uint256 trueId = tokenId;

        if (!isRevealed) {
            return placeholderTokenUri;
        }
        //string memory baseURI = _baseURI();
        return
            bytes(baseTokenUri).length > 0
                ? string(
                    abi.encodePacked(baseTokenUri, trueId.toString(), ".json")
                )
                : "";
    }

    /// @dev walletOf() function shouldn't be called on-chain due to gas consumption
    function walletOf() external view returns (uint256[] memory) {
        address _owner = msg.sender;
        uint256 numberOfOwnedNFT = balanceOf(_owner);
        uint256[] memory ownerIds = new uint256[](numberOfOwnedNFT);

        for (uint256 index = 0; index < numberOfOwnedNFT; index++) {
            ownerIds[index] = tokenOfOwnerByIndex(_owner, index);
        }

        return ownerIds;
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function setPlaceHolderUri(string memory _placeholderTokenUri)
        external
        onlyOwner
    {
        placeholderTokenUri = _placeholderTokenUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function getMerkleRoot() external view returns (bytes32) {
        return merkleRoot;
    }

    function setUfoMerkleRoot(bytes32 _ufomerkleRoot) external onlyOwner {
        ufomerkleRoot = _ufomerkleRoot;
    }

    function getUfoMerkleRoot() external view returns (bytes32) {
        return ufomerkleRoot;
    }

    // Toggle Functions

    function togglePause() external onlyOwner {
        pause = !pause;
    }

    function toggleWhiteListSale() external onlyOwner {
        whitelistSale = !whitelistSale;
    }

    function toggleTeamSale() external onlyOwner {
        teamSale = !teamSale;
    }

    function toggleUfoSale() external onlyOwner {
        ufoSale = !ufoSale;
    }

    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function withdraw() external onlyOwner {
        //5% to dev (post utility)
        uint256 withdrawAmount_5 = (address(this).balance * 5) / 100;
        //95% to investors wallet
        uint256 withdrawAmount_95 = ((address(this).balance -
            withdrawAmount_5) * 95) / 100;
        payable(0x32A8e0F6D3452e439Bd515F884B825ec95D33BD7).transfer(
            withdrawAmount_5
        );
        payable(0x538b816Acc6E9303cFA86221fD9Df90e680e1785).transfer(
            withdrawAmount_95
        );

        payable(msg.sender).transfer(address(this).balance);
    }

    // OperatorFilterer implementation for approval
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    // OperatorFilterer implementation for approval
    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    // OperatorFilterer implementation for transfer
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    // OperatorFilterer implementation for safeTransfer
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    // OperatorFilterer implementation for safeTransfer
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}