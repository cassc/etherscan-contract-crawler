//SPDX-License-Identifier: Unlicense
/*
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNNMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNSSYY  YSGMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNYYYYY       YGNNMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMGSSSNMNYY              YYMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMSYYYSSY                  YGMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMSYYY     YUUUUY           YUMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMGYY    YYY     YY          YMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMOYYY  YU          SY        YMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNYY     YN     Y    GGYYYY   YUMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMGYYY     YG          SY   YYYGNMMM
MMMMMMMMMMMMMMMMMMMMMMMNGGGGGGGGGGGGGY         OY      YY   Y   MMMMMM
MMMMMMMMMMMMMMMMMMMMNUUSSSSSSSSSOOOYYSGYYY      YYSSSSGN        MMMMMM
MMMMMMMMMMMMMMMMMNGGSSSSSSSSSSYYYYYYYYYGGUS           YYY     YSMMMMMM
MMMMMMMMMMMMMNNNSSSSSSSSSSSOYYYYYYYYYYYYYYOGYY           GNNNNMMMMMMMM
MMMMMMMMMMMMGSSSSSSSSSSSSSYYYYYYYYYYYYYYYYYYUUO   YU     GMMMMMMMMMMMM
MMMMMMMMMNGSSSSSSSSSSOSOOYYYYYYYYYYYYYYYYYYYYYSGYY YNNNNNMMMMMMMMMMMMM
MMMMMMMMMNNNNNNNNUSSSSSYYYYYYYYYYYYYYYYYYYYYYYYYUUGMMMMMMMMMMMMMMMMMMM
MMMMMMMMYYYYYYYYYUGGGSYYYYYYYYYYYYYYYYYYYYYYYYYYYUNMMMMMMMMMMMMMMMMMMM
MMMMMMNYY        YYYYNNGYYYYYYYYYYYYYYOSSUNYYYYYYYUMMMMMMMMMMMMMMMMMMM
MMMMMO              YYYYUUGUYYYYYYYYOSGNNGYYYYYYYYUMMMMMMMMMMMMMMMMMMM
MMMMMO      YYYY     YYYYYYYGSYYYYOSGNUSOYYYYYYYYYUMMMMMMMMMMMMMMMMMMM
MMMMGY    YYYYSY         YYYYSGUYYSNNGNGGGYYYYYYYUNMMMMMMMMMMMMMMMMMMM
MMMMY     YYNYYY            YYYSGUNYYYYYYYGUOYYYSNMMMMMMMMMMMMMMMMMMMM
MMMMGYYY  YYMYYY             YYYSMYYY      YGGOONMMMMMMMMMMMMMMMMMMMMM
MMMMMSYYYYYYGOYYY             YYSGYY        YYMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMNUYYYYYYGUYYYY          YYUGYYY     YGGGGMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMSYYYYYYGYYYYY      YYYYUOYY     OMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMNNNYYYYYGYYYYYYYYYYYGMSYYY     SMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMGYYYYYUSSSSSSSSSYNSYYY    NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMNGYYYYYMMMNYYYYYYUUYY    NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMNYYYYYMMMMUYYYYYUGYY    NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMNYYYYYYGMMMMGYYYYUYYY   NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMNYYYYYYGMMMMMNYYYYYUYY  YGMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMNYYYYYYGMMMMMNYYYYNYYY   SMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMNYYYYYYGMMMMMMMYYOMYYYYYSNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMSSSSNNNNNNUGNNNGSSNNGSNNGNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMNUNNNNSYYYYYYYYYYOSSSSSSSYYYYNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMNYGUSSGGGGGGGGSSSGNNNNNGGGGGUMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMGYUGGSOOSUGUUSYYYYSSSSSSSSYYYNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMNSSSGNGGGNNGGGGYYYSGGGGYYYYYONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMYSSOSOSSUGNNGNNNNGUUSOYYYYNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMNYYGUYYYYYNGNNUSSSSSYYYYYYSYYYGMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMNYYYSNNGGUYONMNGSSSYYSGGGYYYYYYNMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMGOYSOYYYYONMMMNNNSSYYYYYYYYYYYMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMNNNNNNNNNNNMMMMMMMNNNNNNNNNUGMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMGSOOOOOOOOOSGMMMMMGSOOOOOOOOUGMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
*/

pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MoonGuysNFT is ERC721A, Ownable, ReentrancyGuard {
    string public contractURI = "https://moonguys.xyz/contractmetadata.json"; //link to metadata.json for contract info
    uint96 public royaltyFeesInBips = 555; //royalty fee in bases points (100 = 1% 555 = 5.55%)
    address public royaltyReceiver; //address to deposit royalties
    string public hiddenMetadataUri =
        "ipfs://bafybeifa6sxhmmg6fkfyugkxcunj3mbed2746xgxnyuul2onlmz25davha/"; //default hidden metadata
    string private baseURI; //the reveal URI to be set a later time
    uint256 MAX_MINT_PER_WALLET = 2;
    uint256 public cost = 0.05 ether; //mint price
    uint256 public currentMaxSupply = 222; //project supply
    bool public mintEnabled = false; //disable and enable the mint
    bool public mintEnabledWL = true; //disable and enable the mint

    mapping(address => uint256) walletsMinted;
    bytes32 public merkleRoot;

    constructor() ERC721A("The Moon Guys NFT", "TMG") {
        royaltyReceiver = address(msg.sender);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        //check that there is enough supply left
        require(
            totalSupply() + _mintAmount <= currentMaxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    modifier WLmintEnabledCompliance() {
        //check that we enabled mint
        require(mintEnabledWL, "The WL mint sale is not enabled!");
        _;
    }

    modifier mintEnabledCompliance() {
        //check that we enabled mint
        require(mintEnabled, "The mint sale is not enabled!");
        _;
    }

    function WLMintMoonGuy(bytes32[] calldata _merkleProof, uint256 quantity)
        external
        payable
        WLmintEnabledCompliance
        mintCompliance(quantity)
        nonReentrant
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Not on the WL. Come back soon to mint from public"
        );


        require(
            walletsMinted[msg.sender] + quantity <= MAX_MINT_PER_WALLET,
            "Can only mint 2 per wallet. Mint more from public"
        );

        require(
            msg.value >= cost * quantity,
            "Please send 0.05 for each mint (0.05 x quantity) "
        );

        _safeMint(msg.sender, quantity); //bbbrrrrrr
        walletsMinted[msg.sender] += quantity;
    }

    function mintMoonGuy(uint256 quantity)
        external
        payable
        mintEnabledCompliance
        mintCompliance(quantity)
        nonReentrant
    {
        require(
            msg.value >= cost * quantity,
            "Please send 0.05 for each mint (0.05 x quantity) "
        );

        _safeMint(msg.sender, quantity); //bbbrrrrrr
        walletsMinted[msg.sender] += quantity;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        //override to return hidden URI instead until reveal
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (totalSupply() != currentMaxSupply) {
            return
                string(
                    abi.encodePacked(
                        hiddenMetadataUri,
                        Strings.toString((_tokenId)),
                        ".json"
                    )
                );
        }

        //pants go down
        string memory currentBaseURI = _baseURI();
        if (bytes(currentBaseURI).length == 0) {
            return "";
        }
        return
            string(
                abi.encodePacked(
                    currentBaseURI,
                    Strings.toString((_tokenId)),
                    ".json"
                )
            );
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

    function setWLMintEnable(bool _enableMint) public onlyOwner {
        mintEnabledWL = _enableMint;
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

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
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

    function airdrop(address[] memory _to, uint256[] memory quantity)
        external
        payable
        nonReentrant
        onlyOwner
    {
        for (uint256 i = 0; i < quantity.length; i++) {
            _safeMint(_to[i], quantity[i]); //bbbrrrrrr
        }
    }
}