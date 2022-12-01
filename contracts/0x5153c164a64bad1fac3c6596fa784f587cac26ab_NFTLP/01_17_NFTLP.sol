// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.12 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./MerkleProof.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";

// ......................................................................................................................................................
// ......................................................................................................................................................
// ......................................................................................................................................................
// ............................................................,;;,......................................................................................
// ......':lc'................',;;;,,,;;,,,;,,,'..............cXWWk'.....................................................................................
// .....,OWMWKd,. ...........,ONNNNNNNNNNNNNNNNx.............'kMMNl......................................................................................
// .....oNMMMMMXx;...........,xkkkkONMMWKkkkkkx:.............cXMMO,......................................................................................
// ....,0MMMMMMMMNk:...............;KMMK:.....:lxkOOkd:.... .kWMNo. ..;lxkkOxol:......oOOkooxkOkxo:........;lxkOOkxl;lkOkc...:dxkOkxo:......:oxkkkxo:....
// ....oNMMMMMMMMMMNOc........... .dWMWx. .'l0NWNKKKNWW0:...:XMM0,.'o0WWNKKKNMMNO:...cXMMMWNXKXNWMWO;....:ONMWNKKXWWXNMMK:.:0WMN0O0XWW0c..:0WMN0O0XWW0c..
// ...,OMMMMMMMMMMMMMW0c..........,0MMK:..;OWWKo;'..;kWMK:..xWMNo.;0WW0l,..':ONWM0;..xWMMXd:'.';xNMMO,..dNMNkc,..,lKMMMWx.'kMMNd'..,oxd:.'kMMNd'..,oxd:..
// ...lNMMMMMMMMMMMMMMMNo.........oNMWx. 'kMMWKxxxxxx0NMWd.:KMM0;,OWMW0kxxxxx0NWMNl.:XMMK:....  'kMMX:.oNMNd..... .cNMMXc..oNMMXOxo:,.....oNMWXOxo:'.....
// ..'OMMMMMMMMMMMMMMMNk;........,0MMX:..;KMMXOOOOOkOkkOk:.dWMWd.cXMWKkkkkkkkkkkkx;.xWMWd. .....,0MM0,'OMMK:..... .oNMWk....:dOKNWMWXx,....:dOKNWMWXx,...
// ..cXMMMMMMMMMMMWXOo;..........lNMWk.  ,0MMO;.....cooc'.;KMMK;.:KMWk,....'cdol:..:KMMM0:.....:OWMXc..kMMNd'....,dXMMXc..,::,..,:kWMWx..,::,..,:kWMWd...
// .'kMMMMMMMMMWXkl,............'OMMXc.. .cKMWKxddx0NMNx,.dWMWd. .oXMWKxddxKWMWXd..dWMWWWNOxxk0NMNO:...;0WMWKkxxOXMMMMk'.cKWWKxolo0WMNl.cKWWKxllo0WMNl...
// .cXMMMMMMWXkl,...............cKNNk' ....,oOKNNNNXOd:..,OWN0:....;d0XNNNNKOoc;..;KMMKod0XNNNX0d:......'lOXNNNX0OKWWKc...:x0XNNNNX0x:...:x0XNNNNX0x:....
// .dWMMMWXkl'...................;;;..........',;;,'.. ...,;;,........',;;,.......dWMWd...',,,'............',;,'..,;;,.......',;;,'.........',;;,'.......
// .,d00xc'......................................................................;0MMK:..................................................................
// ..............................................................................c0XKd...................................................................
//  ..............................................................................'''....................................................................
// ......................................................................................................................................................
// ......................................................................................................................................................

contract NFTLP is ERC1155, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    using Strings for uint256;

    uint256 constant NUM_CATEGORIES = 5;
    uint256 internal constant MASK_SIZE = 12;
    uint256 internal constant MASK = (2**MASK_SIZE - 1);

    bytes32 _merkleRoot;
    uint256[5] internal _startTokenIds;
    uint256 internal _state;
    mapping(address => bool) internal _voucherTracker;

    uint256 public immutable _totalSupply;
    uint256 public _publicMintingStart;
    uint256 public _waitlistMintingStart;
    uint256 public _provenance;
    uint256 public _pricePublic;
    uint256 public _priceWaitlist;

    constructor(
        uint256 supplyPerCategory,
        uint256 priceWaitlist,
        uint256 pricePublic,
        uint256 waitlistMintingStart,
        uint256 publicMintingStart,
        string memory url
    ) ERC1155(url) {
        _totalSupply = supplyPerCategory * NUM_CATEGORIES;
        _priceWaitlist = priceWaitlist;
        _pricePublic = pricePublic;
        _waitlistMintingStart = waitlistMintingStart;
        _publicMintingStart = publicMintingStart;

        for (uint256 i = 0; i < NUM_CATEGORIES; i++) {
            _state |= ((i << 0) | (supplyPerCategory << 3)) << (MASK_SIZE * i);
        }

        _state |= NUM_CATEGORIES << (MASK_SIZE * NUM_CATEGORIES);
    }

    modifier withSupply() {
        require(
            _state >> (MASK_SIZE * NUM_CATEGORIES) > 0,
            "NFTLP: No more tokens"
        );
        _;
    }

    // Admin
    function setProvenance(uint256 aProvenance) external onlyOwner {
        _provenance = aProvenance;
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    function setURI(string memory url) external onlyOwner {
        _setURI(url);
    }

    function setPricePublic(uint256 pricePublic) external onlyOwner {
        _pricePublic = pricePublic;
    }

    function setPriceWaitlist(uint256 priceWaitlist) external onlyOwner {
        _priceWaitlist = priceWaitlist;
    }

    function setPublicMintingStart(uint256 publicMintinStart)
        external
        onlyOwner
    {
        _publicMintingStart = publicMintinStart;
    }

    function setWaitlistMintingStart(uint256 waitlistMintingStart)
        external
        onlyOwner
    {
        _waitlistMintingStart = waitlistMintingStart;
    }

    function mintPrivate(address[] calldata recipients)
        external
        onlyOwner
        withSupply
    {
        uint256 recipientLength = recipients.length;

        for (uint256 i = 0; i < recipientLength; ) {
            _mintRandom(recipients[i]);
            unchecked {
                i++;
            }
        }
    }

    function withdraw(address to) external onlyOwner {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "NFTLP: Transfer failed");
    }

    // Public write
    function mint(bytes32[] calldata proof)
        public
        payable
        withSupply
        nonReentrant
    {
        require(
            block.timestamp >= _waitlistMintingStart,
            "NFTLP: Minting not open"
        );
        uint256 price = _pricePublic;

        if (block.timestamp < _publicMintingStart) {
            require(
                _voucherTracker[msg.sender] == false,
                "NFTLP: Already redeemed"
            );
            require(
                MerkleProof.verify(
                    proof,
                    _merkleRoot,
                    keccak256(abi.encodePacked(msg.sender))
                ),
                "NFTLP: You need a valid proof to mint in this phase"
            );
            _voucherTracker[msg.sender] = true;
            price = _priceWaitlist;
        }

        require(msg.value >= price, "NFTLP: Not enough ether");
        _mintRandom(msg.sender);
    }

    // Public read
    function leftToTake() public view returns (uint256) {
        return
            (((_state >> (MASK_SIZE * 0)) & MASK) >> 3) +
            (((_state >> (MASK_SIZE * 1)) & MASK) >> 3) +
            (((_state >> (MASK_SIZE * 2)) & MASK) >> 3) +
            (((_state >> (MASK_SIZE * 3)) & MASK) >> 3) +
            (((_state >> (MASK_SIZE * 4)) & MASK) >> 3);
    }

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    super.uri(tokenId),
                    "/",
                    tokenId.toString(),
                    ".json"
                )
            );
    }

    // ERC1155 hooks
    function _beforeTokenTransfer(
        address,
        address,
        address to,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) internal virtual override {
        if (to != owner()) {
            require(
                balanceOf(to, 0) |
                    balanceOf(to, 1) |
                    balanceOf(to, 2) |
                    balanceOf(to, 3) |
                    balanceOf(to, 4) ==
                    0,
                "NFTLP: Max 1 token per wallet"
            );
        }
    }

    // Opensea Filters
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    // Internal
    function _mintRandom(address to) internal {
        uint256 categoriesLeft = _state >> (MASK_SIZE * NUM_CATEGORIES);
        uint256 randomIndex = uint256(
            keccak256(abi.encodePacked(block.difficulty, uint160(to)))
        ) % categoriesLeft;
        uint256 chunk = (_state >> (MASK_SIZE * randomIndex)) & MASK;
        uint256 currentId = chunk & (2**3 - 1);
        uint256 currentAmount = chunk >> 3;

        currentAmount -= 1;

        uint256 newChunk = (currentAmount << 3) | currentId;
        uint256 resetterCurrent = ~(MASK << (MASK_SIZE * randomIndex));

        _state =
            (newChunk << (MASK_SIZE * randomIndex)) |
            (_state & resetterCurrent);

        if (currentAmount == 0) {
            categoriesLeft--;
            uint256 lastChunk = (_state >> (MASK_SIZE * categoriesLeft)) & MASK;
            // zero currentChunk and last chunk
            uint256 resetterLast = ~(MASK << (MASK_SIZE * categoriesLeft));
            uint256 resetterCategories = 2**(MASK_SIZE * NUM_CATEGORIES) - 1;
            _state =
                (lastChunk << (MASK_SIZE * randomIndex)) |
                (categoriesLeft << (MASK_SIZE * NUM_CATEGORIES)) |
                (_state & resetterCategories & resetterLast & resetterCurrent);
        }

        _mint(to, currentId, 1, "");
    }
}