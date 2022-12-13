// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Taac is  Ownable, ERC721A, ERC2981, DefaultOperatorFilterer, ERC721AQueryable {

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    enum MintState {
        Closed, 
        Public,
        AL,
        OG
    }

    MintState private mintState;
    string private baseTokenURI;

    bytes32 public merkleRootAL;
    bytes32 public merkleRootOG;
    uint256 public maxMintWL = 10;
    uint256 public maxBatchMintPublic = 10;
    uint256 public maxSupply = 3000;
    
    uint256 public WLPrice = 0.003 ether;
    uint256 public publicPrice = 0.005 ether;


    mapping(address => uint256) public ALMinted;
    mapping(address => uint256) public OGMinted;

    constructor(address payable royaltiesReceiver, bytes32 _merkleRootAL, bytes32 _merkleRootOG) ERC721A("The Anime Ape Club", "TAAC") {
        merkleRootAL = _merkleRootAL;
        merkleRootOG = _merkleRootOG;
        mintState = MintState.Closed;
        setRoyaltyInfo(royaltiesReceiver, 750);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable virtual override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setMintState(MintState _newState) external onlyOwner {
        mintState = _newState;
    }

    function airdrop(address _to, uint256 _quantity) external onlyOwner {
        require(
            _quantity + totalSupply() <= maxSupply,
            "TAAC: Mint has not started"
        );
        _mint(_to, _quantity);
    }

    function mintWL(uint256 _quantity, bytes32[] calldata _merkleProof) external payable callerIsUser {
        require(
            _quantity + totalSupply() <= maxSupply,
            "TAAC: Sold out"
        );
        require(mintState == MintState.AL || mintState == MintState.OG, "TAAC: HL/AL mint is closed");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        if(mintState == MintState.AL) {
            require(
            MerkleProof.verifyCalldata(_merkleProof, merkleRootAL, leaf),
            "TAAC: Address is not whitelisted"
            );

            require(_quantity + ALMinted[msg.sender] <= maxMintWL, "TAAC: Max mint for AL is exceeded");

            uint256 remainingFreeMint = ALMinted[msg.sender] > 0 ? 0 : 1;

            require(
                msg.value >= WLPrice * (_quantity - remainingFreeMint),
                "TAAC: Wrong ETH amount"
            );
            ALMinted[msg.sender] += _quantity;
            _mint(msg.sender, _quantity);
        } else if(mintState == MintState.OG) {
            require(
            MerkleProof.verifyCalldata(_merkleProof, merkleRootOG, leaf),
            "TAAC: Address is not OG"
            );

            require(_quantity + OGMinted[msg.sender] <= maxMintWL, "TAAC: Max mint for HL is exceeded");

            uint256 remainingFreeMint = 0;
            if(OGMinted[msg.sender] == 0) {
                remainingFreeMint = 2;
            } else if(OGMinted[msg.sender] == 1) {
                remainingFreeMint = 1;
            }

            require(
                msg.value >= WLPrice * (_quantity - remainingFreeMint),
                "TAAC: Wrong ETH amount"
            );
            OGMinted[msg.sender] += _quantity;
            _mint(msg.sender, _quantity);
        }
    }

    function mint(uint256 _quantity) external payable callerIsUser {
        require(_quantity + totalSupply() <= maxSupply, "TAAC: Sold out");
        require(mintState == MintState.Public, "TAAC: Mint is closed");
        require(
            _quantity <= maxBatchMintPublic,
            "TAAC: Exceeded batch number"
        );
        require(
            msg.value >= publicPrice * _quantity,
            "TAAC: Wrong ETH amount"
        );
        _mint(msg.sender, _quantity);
    }

    function getMintPrice() public view returns (uint256) {
        return mintState == MintState.Public ? publicPrice : WLPrice;
    }

    function getMintState() public view returns (MintState) {
        return mintState;
    }

    function setPrice(uint256 _publicPrice, uint256 _WLPrice) external onlyOwner {
        publicPrice = _publicPrice;
        WLPrice = _WLPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function setMerkleRoot(bytes32 _merkleRootAL, bytes32 _merkleRootOG) external onlyOwner {
        merkleRootAL = _merkleRootAL;
        merkleRootOG = _merkleRootOG;
    }

    function setMaxMint(uint256 _wlMint, uint256 _publicMint) external onlyOwner {
        maxMintWL = _wlMint;
        maxBatchMintPublic = _publicMint;
    }

    function setMaxSupply(uint256 supply) external onlyOwner {
        maxSupply = supply;
    }

    function setRoyaltyInfo(address payable receiver, uint96 numerator) public onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    } 
}