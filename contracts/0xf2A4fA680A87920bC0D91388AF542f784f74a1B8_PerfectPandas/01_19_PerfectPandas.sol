//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

/*
P5?!!!!!7!!7!7777777!!!7!!!!!!!7777??7777!!!!77777!!!!7?77?777777!~!!!!!!!!77!!!7777777!7!!7!!!!!J5P
P5J!7!777!!!!!!7777777!!!!!!777777777777!!77777!7!!!^.^!77?77?7?777!7?77!!!!!!7777777!!!!!!77!!7!Y55
55J!7777!!!777!!7777!!!!!77??77!!!!!!7777777!!!!!~777~!77?JJJJJJJ7??~!77?77!!!!!777!!!!77!!7777!!Y55
55?7?777!!7777!!!7!!!!!7?7777777!!~!77777777!~!~!~???????JJJJYJJJJ??!~!~!7??7!!~!!7!!77777!!7777!J55
5577?777!!777777!!!!!??7!!!!!777!777777!!!!!!77777JJJJJJJJJJJJJJJY??!~!!7777??7!!!!!777777!!777?!?55
55?7?777!!7777!!!!!7??777!!!!777777!!!!!77????????JJJJJYYYYYYYYYYYY7~777777!!77?7!!7!77?77!!777?!J55
55J!7!!!!!7?7!7!!7!77777!!~!!7777!!!77????????????JJJJJJYY555555Y?!!77777!!!!777!77!!7!7?7!!7!!7!Y5P
PY!!7!!!!7!!!!7!?7!77~~7777?7!!!~!7??????????????JJJ?JJJJJJYYYYYJJ?7!7777!!!!!!77!??!7!!!777!!7?!75P
PY!!?7777!!!7!!?7!7!^..7??????!!??????????J????J??JJJ??JJJJJJJJJJJJJ?!!7777!!!!777!7?!!7!!77777?!75P
55J!777?7!77!!!!!77~?!7YJJJJJ?????????7?????77?JJ?JYY????JJJJJYYJJJJJ?!!777!7777777!7!!777!7?777!Y5P
P5Y!?77!!7777777JJ7!?JYYYYYY????J???J?!?J?7?7!?JYJ7?JYYJJJJJJ?JJYYYJJJ?!777777777?JJ777777!!!77?!55P
PPY!?77!77???77???7~JYYYY55J?JJ?J????7!?JJ???7?JYYY?7?JJYYJJYJJ??JJYYYJ7!77777777????77???77!77?!55P
PPY!?7?????????????7!JY5555??J??7?JJ!!!7JYJ????JYYJJ?????JYJJYYYYJJJJYY?~7777?????????????????7?!55P
PPY!7??????????7?????7?JYYJ??J?77?JY?777JJYJ???JYJ7~~!7?J?JYJJYYYYYYJJYJ!!7!7?????????7???????7?!55P
PPY!7?J?J?????77??JJJJ?7!!~????!77JYY???JYYY??5Y7^^~!!?!7J?JYYYYYYJYYYYYJ7!77JJJJ????77??JJ??J77!55P
PP577?J??????77???JJJJJ7!7~!7!J????YYJJJJYYJY5??J5PB55Y~^7JJYYY5YYJJYY5YYJ7~!JJ??????7???JJJJJ?!?55P
PP55?JJJ??77??7?JJJJJJJ?!7!~7??JJJJYY7??77~?Y?5J~G#P?^^^^!JJYYY55JJJJYY55JJ77JJ??777?77JJJ?JJJ?J555P
PP55?JJJJJ?77?77??777?J?!!7!~?JYJJJ5Y?J!^^^^~J5:7Y5?!~:^^~JJYYY55YJJ?JY55YJ?!?JJJJ?77?7??77??J?J555P
P555?JJJJJJJJ?????77?JY?!!!!~JJYJJ?7?YY5?^^^^^^^^^::....:^?JYY555Y?JJ?YY55YJJ!?JJJJJ?????777?J?J555P
PP5Y?JYYYYYYYYJJ7??JYYYJ!!~~!7?YY5Y5P7~GB!:::::::::::...:^?YY555YY??JJJY555Y5J!7YYYYYJJ77?JJYYJ?Y55P
PP55?YYYYYYYJ??JJJJYYYYJ77!7!!~7?JPBJ:!?!:^.:::::::::::::~JY555YY5J?JYJY555YYJJ!7YYYJ?JJJJYYYYJJ555P
PP55?YYYYYYYYJYYYYYYYYYJ???????7!!7J5J:..~^^^:...:::::::^7J55P5Y55Y?JYYY5555YJJJ!JYYJJYYYYYYYYJJ555P
P55J?YYYYYYYYYY5YYYYYY5J????7777?!!!J57.::::::^~~:::::::^!Y5PY55555??JY55P55YJJJ775YYYYYYYYYYYJ?Y55P
PPJ!7Y55555555555555555J?????777?!~!7Y57:.:::7YJ!:::::::~?5PY^?5555Y7JJY5P55YJYJJ!Y55555555555?7!Y5P
PPJ!?555555555555555555J7??????7?7!!!Y55Y!^:.:::::::::~!?YPY^:^55555??YJYPP5YY5JJ!J55555555555J?!Y5P
PPJ7??5PPPPPPPPPPPPPP5Y7?????????J7~!J55PP5J!^:..::~!~!J?YPJ:::755555?7YYYP5YY5YJ77GPPPPPPP55Y7J!YPP
PPJ7?7!J?YGGPYY5GGP???77777???????~~7Y555PP555Y??JYJJ^~J?J557!!!Y555Y7.^?JY55Y55J?!55YYPGGJ??!?J!YPP
PPJ7??77?7J??J5??J?????777?????J?~~!J5Y55PP555555557?^~75YY555YY5555P5?YYYJJJ5555J?!75????7J!???!YPP
PPJ7?7?!777!!?5!777JJ?????J????!~!7YYY55PP55555555YY7!~J555Y55555P55PPPP55YJJJ5555Y?!?7!!77!7J??!YPP
PPJ7?77?!!?77J5!7777YYJJJ7??7!!!7JYY5PPPPPPP555YYYYJ7~?YYY55Y5PP5J5555PPPP5YYYY55P55Y?7!!7?!7?7J!YPP
PPJ7?777?!!777Y!777!!?JY7~7?!!~7Y555YJ?!!??YYYJJJJ?7!~YYJJY5Y5P5?YPPP5555PP5Y5555PPPP55YY5J!777?!YPP
PPJ7?7777?7!??Y777777!!7!7!!!~7Y5Y7~^^^^^!?YYYJ?7~^:!~5JY5PPP5J?Y5P555PP55PP55P555JYPPP5Y?~7777?!YPP
PPJ7?7!!77?7!7Y77777777!!!JYYY5Y7^^^~~!7?J?7!~!:..::!7J55P5YJJYJJY5YY5PP5Y5PPPP55!^^~YP5J!!!!!7?!YPP
PPJ7?7!!777??7Y!77!!7777!~?~!!~^^~!7777!~^:.^!7~^^^^~?7Y5YYY5J~~Y5Y7J5PPPY5PPP55Y!~~^^5PY?!~!77?!Y5P
PPJ7?77777777?5!!!~~!!!!!?~^~~!!!!~^^:......!7!^^~~??J?755YY7^^^77~~YYPP55PPGP5YY!^~~^!P5J!!777?!Y5P
PP?7?7777!!77JG?77~7YJJJJ!^^^^:::....::::::~:^~^^!~!JJ7~755J^^?7^^~JYYP55PPPPPP5Y?^~~~^55J!!7?7J!YPP
PP?7?77777777J5?!!^:~^::......::::::::::::^7!~~~^^~?~^^^!75P7J5!^^J55PPYPPPP5Y5555!^~~^J5?!7777?!YPP
PP?7?77777777^^:........:::::::::::^~~~~^^^^~~~!!!!~^^^^:!?5P5Y~^!YY5P5YPPP5YYY555J~~~^7Y7!7777?!YPP
PP?7?777777!^ ...:::::::::::::::::::^~~~~^^^::::::::::::^:!75PJ^^!5J5GP5555PP55555Y!~~?!J7!?777J!YPP
PP?7?77777!~..:::::::::::::::::::::::..::::::::::::::::::^^77P5~^^J5555PPPPPP5YJJ?J?77J!77!77??J7YPP
PP?7?77777~..:::::::::::::::::..:::::::::::..........   .:^~??GJ^^~Y555PP5YJ?7!!!!!!~^^^7?!7???J7YPP
PP?7?7777!^.::::::::::::::::::::::::...::::::::::::::.   .:^7!PP?^^?55PGJJJ!~~~~~~~~~^::~Y?!!77J7YPP
PP?7?7777!^.:::::::::::::^^^^^^^^^^:::::::::::::::::::.  .:^!7YG5J~75PGGGPP?~~~~~~~~~~:::JY?!~!J7YPP
PP?7???7?!~::::::::^^^^^^^^^^^^^^^^^^^:::::::::::::::::::::^~7JGGP5Y5PP5PPPP7~~~~~~~~~^::^!777?J!YPP
GG5??????7!~^^^^^^^^^^^^^^^^^~~~~~^^^^^^^:::::::::::::::::^^~?5GGGGPPP?YPPPP5~~~~~~~~~~^:^!7????JPPP
GGGPPP5555?!!~~~~~~~~~~~~!!!!!!!!!!~~^^^^^^::::::::::::::^^^!YGPPPPGGJJGPPPPGJ~~~~~~~~~~::!7555PPPPG
GGGGPPP5555?!!!!!!!!!!!!!!!!!!!!!!!!!!~~^^^^^^^:::::::^^^^^^YPGPPPPGY?GPPPPGP5!~~~~~~~~~^:^7YPPPPGGG
BBGGGGPPPPPPY?!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~~^^^^^^^^^^^~~!YGGGPPPG57GGPPGPY??!~~~~~~~~~~^:!JPPGGGGG
BBBBGGGGPPPPPP5J?77!!!777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!75GGPGGGG57PGGPGY?Y5P7~~~~~~~~~~~:^?GGGGBBB
BBBBBGGGGGGGGGGPPP5557!~~~~~~~~!!!!!!!!!!!!!!!!!!!!!!!!7YGGGPPGGG57YP?YPP!5PPP5~~~~~~~~~~~^:7GGGGBBB
BBBBBGGGGGGGPPPPPPPPPJ^^::::^^^^^~!!77!!!!!!!!!!!!!!!?YPGGGGGGPP5!?G?JJ??!PPPPP7^~~~~~~~~~^:~PGGGBBB
*/

import "erc721a/contracts/ERC721A.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IGPC.sol";
import "./opensea/DefaultOperatorFilterer.sol";

contract PerfectPandas is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    bytes32 public merkleRoot =
        0x1e8f41a3cb9be14a53b24ba3134793a5a76fa6d0ce36df2277ec5c201c20ddc8; // root to be generated after full whitelist addresses are done;

    string public contractURI =
        "https://mint.goldpandaclub.com/contractmetadata_perfectpandas.json"; //link to metadata.json for contract info
    uint96 public royaltyFeesInBips = 999; //royalty fee in bases points (100 = 1% 999 = 9.99%)
    address public royaltyReceiver; //address to deposit royalties
    string public hiddenMetadataUri =
        "ipfs://bafkreidsbru7mmb46fnvnhfspnkkqqctz325bulipyhqoqpdu4efusvmxm/"; //default hidden metadata
    string public baseURI; //the reveal URI to be set a later time

    uint256 public cost = 0.069 ether; //mint price
    uint256 public currentMaxSupply = 200; //project supply
    bool public mintEnabled = true; //disable and enable the mint
    bool public revealed = false; //disable and enable reveal after baseURI is set

    mapping(address => uint256) public _claimed; //mapping of addresses that claimed and how much they have claimed

    constructor() ERC721A("Perfect Pandas", "GPC-PP") {
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
        return 1;
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