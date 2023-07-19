// SPDX-License-Identifier: MIT

/*

MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX000KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKKNXkxk0KKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKXWWN0xdxxkO0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0KWWWWKkxdoodkOO0XNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMNK00XWWWWNOddddoodkOOO0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMN00OKNWWWWW0ooodddoloxOOOOKWMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMWX00kOXWWWWWWXkxxxxxdolloxxldXMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMWK0K0OKWWWWWWWN0kkkkxxxdolllcdXMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMW0kOOO0KXNWWWWWKkkkxdolcc:cccxNMMMMMMMMMWWMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMN0kdodddxkO0XNXkdoc::;;;;cclkNMMMMMMWNX0OOKXNWMMMMMMMMMM
MMMMMMMMMMMWNNNWMMMMMMMMMNOxdooolllldxxoc:,,:cc::cllOWMMMMWXKXKkdodk0KKXNWMMMMMM
MMMMMMMMMMMX0kkkO0KXNWWMMWKxdolllccloooc:;''',;::ccl0WMWXXXXWWKxddddxO0KKKKKNMMM
MMMMMMMMMMN000xooooddxkOO0KKkoolcccclodlc:;,''',;cco0XKKXNWMMNOxdddddodxkdodKMMM
MMMMMMMMMWKOOOkocccllllld0NXxoolcccclodlccc::;,,;cclkKNWMMMMWKkxxddoooooc;:oKMMM
MMMMMMMMMN0OOkkxlccccllxKNNXkllccllllldl:;;;:::::ccdKWMMMMMMNOxddooooool:;:dXMMM
MMMMMMMMWKO0kkxkdc:::oOXXXNX0dlllcloollcc;',,,;:clxXWMMMMMMWKxddoooooool;,:dXMMM
MMMMMMMMN0OOkkkxxo:,:xKXXXNNKxddooooolccc;'''',,cxKWMMMMMMMNOdooooooooo:,,;xNMMM
MMMMMMMMX0Okkkkxxxl,;lxOKXNWKkdxdoolllccl:,'''';dOKWMMMMMWN0xollloooool;',:xNMMM
MMMMMMMW0Okkkkkxddoc:ccldk0KKkdoolllllc:l:,''';dkOXWMMMMNKkdlc;;;::cclc;',:kNMMM
MMMMMMMWKkxdddoollcc:::;:ldxkkdllllccc::c:,'':dkkOXWWWWXOdl:;;,,,,,,,;;:cclOWMMM
MMMMMMMMWNX0kollcc:::::;,,:oxkxolllc::::::;':xkkkOXWWNOdc:,,,,,,,,,,,,;:ldONMMMM
MMMMMMMMMMWXOocccccccc::;,',cdkkdllc::::::;cxkxxxOXN0d:;,,'',,,;,,,;:coxOXWMMMMM
MMMMMMMMMMXOdl:;;;;::::ccc:'.,lxxolc::::;coxkxxxkOOd:,'',,,,,,,;;:lxOKNWMMMMMMMM
MMMMMMMMMWK0XKOdc;,;;;;;cxx;'.':odlc:cc;,lkxxxxxoc;'',,,,,,;;:loodk0KXWMMMMMMMMM
MMMMMMMMMWK0WWWNXOdc:;;cOKo;,,',:oocclcccdkxxoc,'''',,;;:;;;;lkOOOkdlo0WMMMMMMMM
MMMMMMMMMW0KWWWWWWWXKkkkxl;'''',:loololdkkdc,''',,;:::;;,'',cdxxxdc;;lOWMMMMMMMM
MMMMMMMMMN0KNKKK0000000kc,;::clldk0KK0kol:,',,;:cc:;,'....';lddl:,,;dKWMMMMMMMMM
MMMMMMMMMN0K0dddooooooolc;;cxKXXNWMMMMWKOd:;:cldkkd:,'....';ll;'',lONMMMMMMMMMMM
MMMMMMMMMX0KOdddoooooooolllxXWMMMMMMMMMMWWK00KXWWWN0dc,..,:lc'.,lONWMMMMMMMMMMMM
MMMMMMMMMNK0kdddddddddddddkXWMMMMMMMMMMMMMMMMMMMMMMWN0dc:clol:lkXWMMMMMMMMMMMMMM
MMMMMMMMMMMWNNXXXXXXXXXXXXNWMMMMMMMMMMMMMMMMMMMMMMMMMWNK000KKXNWMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

*/

pragma solidity ^0.8.0;

import "ERC721A.sol";
import "DefaultOperatorFilterer.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "MerkleProof.sol";
import "Strings.sol";

contract THECRYSTALS is
    Ownable,
    ERC721A,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    uint256 public price = 0.111 * 10 ** 18;
    uint256 public maxSupply = 2222;
    uint256 public maxMintPerTx = 10;
    bytes32 public whitelistMerkleRoot =
        0x83bbc38a3b6ce0748086750ee1bacdddaf852c403fb5aca3265d2b3d15aa2683;
    bool public publicPaused = true;
    bool public revealed = false;
    string public baseURI;
    string public hiddenMetadataUri =
        "ipfs://QmVgWazC5yXaj62VghczWCkay37T6FrQSXp93kMZPdawos";

    constructor() ERC721A("THE CRYSTALS", "CRY") {}

    function mint(uint256 amount) external payable {
        uint256 ts = totalSupply();
        require(publicPaused == false, "Mint not open for public");
        require(ts + amount <= maxSupply, "Purchase would exceed max tokens");
        require(
            amount <= maxMintPerTx,
            "Amount should not exceed max mint number"
        );

        require(msg.value >= price * amount, "Please send the exact amount.");

        _safeMint(msg.sender, amount);
    }

    function openPublicMint(bool paused) external onlyOwner {
        publicPaused = paused;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function whitelistStop(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxPerTx(uint256 _maxMintPerTx) external onlyOwner {
        maxMintPerTx = _maxMintPerTx;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setApprovalForAlll(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function presaleMint(
        uint256 amount,
        bytes32[] calldata _merkleProof
    ) public payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        uint256 ts = totalSupply();
        require(ts + amount <= maxSupply, "Purchase would exceed max tokens");

        require(
            MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf),
            "Invalid proof!"
        );

        {
            _safeMint(msg.sender, amount);
        }
    }

    function setHiddenMetadataUri(
        string memory _hiddenMetadataUri
    ) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(currentBaseURI, Strings.toString(_tokenId))
                )
                : "";
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // OVERRIDDEN PUBLIC WRITE CONTRACT FUNCTIONS: OpenSea's Royalty Filterer Implementation. //

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
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

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }
}