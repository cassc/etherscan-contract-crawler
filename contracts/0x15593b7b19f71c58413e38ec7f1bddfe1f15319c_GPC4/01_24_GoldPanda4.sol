//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

/*
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMFVVVVVVVVFIMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMVV**************:***VFMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMIMMMIV*:*V**VVVVVVVVVVVVVVVV****VMMMMIMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMV***:*:*:***VVVFFFFVFVFVVVFVFVFVVVV*::*******VMMMMMMMMMMMMMM
MMMMMMMMMMMMMF**VVVV***VVVVVVVFVFFVFFFFVVFFFVFVFIVVVV***VFV*:*IMMMMMMMMMMMM
MMMMMMMMMMMMV:VVVV****VVVFVVVFVVVFVVVVVVVVVVVVVFVFFVVVV**VVFV*:FMMMMMMMMMMM
MMMMMMMMMMMM:*VVV***VVVVFFFVVIFFFVVVVVVVVVVVVVVVVVVVVFFVV**FIV:*MMMMMMMMMMM
MMMMMMMMMMMM:*FV***V*VFVVVVVVVVVFVVVVVVVVVVVVVVVVVVVVFVFVV**VI**MMMMMMMMMMM
MMMMMMMMMMMMV:****VVVVVVVVVVVVVVVFVVVVVVFFVVFFVVVVVFFVVVMFV***:FMMMMMMMMMMM
MMMMMMMMMMMMM****VVVVVVVVVVV*VVVVVVVVVFVVVVFVVVVVVVVVVVVFVFV*:*MMMMMMMMMMMM
MMMMMMMMMMMM*:**VVVVVV**VVV*VVVVVVVV***V**VVVVVVVVVVVVFFVFFV**:VMMMMMMMMMMM
MMMMMMMMMMMV:**VVVVVVVV*VVV*V**************VVVVVVVVFVVVFVVVVVV*:FMMMMMMMMMM
MMMMMMMMMMM****VV*VVVVVVVVVV********:******VVVVVFVVVVVVVVVFFVV*:*MMMMMMMMMM
MMMMMMMMMMI:**VVVVVVVVVVV*V**V***********V*VVVVVFVVFVVVVFVVVVV**:MMMMMMMMMM
MMMMMMMMMMV:**VVVVVVVVVVVV*VVVVVVVVVVVVV*VVVVVVVVVFVFVVVVFFVVV**:MMMMMMMMMM
MMMMMMMMMMF:*VV*VVVVVVVVVVVV*VV*VVVVVVVVVVFVVVVVVVFVVVVVVVFVVV**:MMMMMMMMMM
MMMMMMMMMMM**VVVV*VVVVV*VV**VVVVVVVVVVVVVVVFVVVVVFFVIIVVVVVVVVV**MMMMMMMMMM
MMMMMMMMMMMV*VVVVVVVVVVVVVVVV*VVVVVFFVVVVVVFFVVFVVVFIIVIVVVVVV*:VMMMMMMMMMM
MMMMMMMMMMMM**VVVVVV*VVVVVVVVVVVVFVVVFFFIFVIVFVIVVVVMVVFVVVV****MMMMMMMMMMM
MMMMMMMMMMMMI**VVVVVVVVV*VVVVVVVVVVFFVVIMIIVIFFVIVVFIFVVVVVV***IMMMMMMMMMMM
MMMMMMMMMMMMMIVVVVVVVVV*V*VVVVVVVVVVVVVFIIIVVFVVIFFFVVFVVVV***MMMMMMMMMMMMM
MMMMMMMMMMMMMMMFVVVV*VVVVVVVVVFVVVVVVVVVVVVVFVVVVVVVVVVVV***FMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMFVVVVVVVVVVVVVVVVVVVVIVVVVVVVVFVVVVVVVV*VFMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMIVVIMIIFVFVIIFFIIIFIIFIFIVFFFIFMMMM*VIMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMFVVVVVV*VMIFIMMNMN$NNNNNMMMMMMMMMMNMIIMMMV*VVVVVVIMMMMMMMMMMMM
MMMMMMMMMMMF**VFIMMMVVVVVVFVFIIMMMMMMIIMMMMMIIFVFFVIMMVV$$NNMV**FMMMMMMMMMM
MMMMMMMMMI***VVFVVFMV*VVVVVVVVVVFFVVVFFFFFFFFFVVVFVIIMVV$IVVIIFV*VMMMMMMMMM
MMMMMMMMF**VVVVVV**IV*VVVVVVVVFIFIMMMNMMIMFFFFVFVVFFVVVIMVVVVVVV***IMMMMMMM
MMMMMMMV:**VV**VVVVIV*VVVVVVVIFIFIMIIIIIFIIFFIVVVVFVFV*VMIFV*VVVVV*:FMMMMMM
MMMMMMI:*VVVVVVVVIIF****VVVVVFFFVVVVVVVVVVVVVVFFVVVVVV**IIIFVVVVVVV**MMMMMM
MMMMMM*:*VV**VVVVVV****VVVVVVVVVVV**V**VVVVVVVVVVVVVVV**VVVFVVVVFVV***MMMMM
MMMMM*:*VV***VVVFFV****VVVV**VV************V**VVVVVVVV***VFFFVV*VVVV*:VMMMM
MMMMV:**V**VV*VFFV::**VVVV*V**V**********:*******VVV*VV***VVVVVV*VVVV*:IMMM
MMMM*:*VV*V**VVVV*:**VV*******V**V************VVVVVVV*V**:*VVVV**VVVV*:VMMM
MMMI:**VV****VVVV::*VVV**V*****VV*VV*V*VV**V*VVVVVV*VV***::VVVV**VVVV*:*MMM
MMMV.*VVV****VVVV*:**V*V*VVV*VVVVVFVVVVVVVVVVVVVV*VVVV****:VVVVV*VVVVV*:MMM
MMMV:**V*V*VVVVV*:****VVVVVVVVVVV*FVVVVVVV*VVVVVV*V**V****:*VVVV**VVV**:IMM
MMM*:**V****VVFVV**V*VVV*V*VVVVVVVVFVVVVVVV*VVVV*VV***V***:*FIV**VVVVV*:VMM
MMMV:***VVVVVVVV****VFVVV*VV*VIVIFVVMFVFVVVVVVV*****V*****:*VVVVVVVVV**:VMM
MMMM***VV*VVVFIIV***VVVVVVVVVVVVVVMVVFVIIVVVVVF*VVVVV*****:VIFVFIVVVV**:MMM
MMMM***VVVVVVFIMV****VVVVFFVVVVVVIIFVVFMVVFVVVV*VV*V**V***:VMMIIVF*VV*:*MMM
MMMMV*:*VVVVVVIMV****VVVVVVVFVVV*IMVVVVVVMVVVVVVVFV**V****:VMFVVVFVVV::VMMM
MMMMMV**VVVVVVMFV***VVVVVVVFVFIVVVVVVIFVVMV*VVVVVVFVVVVV*::*VFVVFFFV*:*MMMM
MMMMMMV***VVVVVVVV:*VVVVVVMIVIVIFIIVVIVVVVFVVVVFVVVFVV***:***VVVVV**:*MMMMM
MMMMMMMMFVVVVVVIMM*VVV*FVVVVVVVVVFVFIIIV*VV*****V*********IIVV*****VFMIMMMM
MMMMMMMMMMMMMMMMMF*FMMMIIMMMNMMFVVVVVMVVVVV*VIIIFVVVVVFMV*IIIIIIIIIIIIIIMMM
MMMMMMMMMMMMMMMMMV**VVVVVFVFVFIIVVVVFVVV*V**VVVV****V*VV*:VMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMV*VFV*VVVVVVFVF*VF*VFVVVV**VV***V**V**V*:FMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMV**VVV*VVVVVVVVV**V*VVVV**V*************:FMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMV:*VV***V***VV*VMVVVV*V*VVV*****V****VV*.VMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMV:*V*******V****VFFVMIVFVVV*****VVV***V*:FMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMV:*V*****VV*VVV*VVI*VV*V*VVVV****VV*VVV*:FMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMV:*****VVVV*V***VVV*VV*V*VVVVV*V*V******:VMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMV:**V*VVVVV**VV*VVF*VV****V******VV**V**:VMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMV:*VV*VVFVVVVV**VVI*V****VV*V*****VV****:VMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMM*:*V****VVVVV*VV**V*V**V*******V******V*:VMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMM******VVFVVVFFV*****VV**:**VVV*VVVVV**:::VMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMM*:**VVFIFV*VVVVVVV*:*V::*VVVVVV*VVVVVV*:.*MMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMM**VVVVFVVFVVVVVVVV*:**:*VVVV*VVVVVV*****:*MMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMI:*VVVVVV******VVVV*:**:**VV*******VV**VV::MMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMVVVVVFVVFVFVVVVVVVV*VV**V*VVVVVVVVVVVVVV*VMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMIVVVFIIIMIIFFIIMMIMMMMMIIMMIMMIMIMMMMMMMMMMMMMMMMMMMMMM
*/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IGPC.sol";
import "./opensea/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract GPC4 is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    bytes32 public merkleRoot =
        0xd786a49e5e8d5c6218d171025694b838d90af91901296c68d6de7cd5a261ed23; // root to be generated after full whitelist addresses are done;

    string public contractURI =
        "https://mint.goldpandaclub.com/contractmetadata_island4.json"; //link to metadata.json for contract info
    uint96 public royaltyFeesInBips = 999; //royalty fee in bases points (100 = 1% 999 = 9.99%)
    address public royaltyReceiver; //address to deposit royalties
    string public hiddenMetadataUri =
        "ipfs://bafkreichjqqovomqvfan7ymdz6kq67eyndtcjgz7qkyiczlv3usuupzndq/"; //default hidden metadata
    string public baseURI; //the reveal URI to be set a later time

    uint256 public cost = 0.059 ether; //mint price
    uint256 public currentMaxSupply = 500; //project supply
    bool public mintEnabled = false; //disable and enable the mint
    bool public revealed = false; //disable and enable reveal after baseURI is set

    mapping(address => uint256) public _claimed; //mapping of addresses that claimed and how much they have claimed

    constructor() ERC721A("Gold Panda Club 4", "GPC4") {
        royaltyReceiver = address(0x91153D6B02774f8Ae7faAd0ce0BDbA9Cfc14398B);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        //check that there is enough supply left
        require(
            totalSupply() + _mintAmount <= currentMaxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        //check the address has enough mula
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _;
    }
    modifier mintEnabledCompliance() {
        //check that we enabled mint
        require(mintEnabled, "The mint sale is not enabled!");
        _;
    }

    function mint(bytes32[] calldata _merkleProof, uint256 quantity)
        external
        payable
        mintEnabledCompliance
        mintCompliance(quantity)
        mintPriceCompliance(quantity)
        nonReentrant
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Not on the allowlist"
        ); //check that address is indeed on allowlist. No hacky hacky

        _claimed[msg.sender] = _claimed[msg.sender] + quantity; //add how many claimed in this transaction. maybe only claimed a poriton of max

        _safeMint(msg.sender, quantity); //bbbrrrrrr
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 2001;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : "";
    }

    function setCurrentMaxSupply(uint256 _supply) public onlyOwner {
        require(
            _supply >= totalSupply(),
            "Cannot set supply to lower than current total supply"
        );
        currentMaxSupply = _supply;
    }

    function setContractURI(string calldata _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function setRoyaltyReceiver(address _receiver) public onlyOwner {
        royaltyReceiver = _receiver;
    }

    function setRoyaltyBips(uint96 _royaltyFeesInBips) public onlyOwner {
        royaltyFeesInBips = _royaltyFeesInBips;
    }

    function setMintEnable(bool _enableMint) public onlyOwner {
        mintEnabled = _enableMint;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function reserve(uint32 _count)
        public
        virtual
        onlyOwner
        mintCompliance(_count)
    {
        _safeMint(msg.sender, _count); //bbbrrrrrr
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyReceiver, calculateRoyalty(_salePrice));
    }

    function calculateRoyalty(uint256 _salePrice)
        public
        view
        returns (uint256)
    {
        return (_salePrice / 10000) * royaltyFeesInBips;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}