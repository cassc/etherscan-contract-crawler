// SPDX-License-Identifier: GPL-3.0

/**
 ________  ________  ________     
|\   ____\|\   __  \|\   __  \    
\ \  \___|\ \  \|\  \ \  \|\ /_   
 \ \  \  __\ \  \\\  \ \   __  \  
  \ \  \|\  \ \  \\\  \ \  \|\  \ 
   \ \_______\ \_______\ \_______\
    \|_______|\|_______|\|_______|                                                                   
 */
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./OperatorFilterer.sol";
import "./interfaces/IOperatorFilterRegistry.sol";

contract Gob is ERC721Enumerable, Ownable, OperatorFilterer {
    enum State {
        NOT_ACTIVE,
        MINT_ACTIVE,
        BURN_ACTIVE
    }
    enum BatchState {
        FIRST,
        SECOND
    }
    struct BurnRecord {
        address owner;
        uint256 timestamp;
        string btcReceiverAddress;
        string btcTransactionHash;
    }

    State public state;

    BatchState public batchState;

    uint256 public nextTokenId = 1;
    uint256 public maxPerWallet = 3;
    uint256 public maxSupply = 100;
    uint256 public price = 0.15 ether;

    string internal baseURI;

    uint256[] public burntTokenIds;

    mapping(address => uint256) public mintedByAddress;

    mapping(uint256 => BurnRecord) public burnRecords;

    constructor(string memory _baseURI)
        ERC721("Ghosts On Bitcoin", "GOB")
        OperatorFilterer(
            address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6),
            true
        )
    {
        baseURI = _baseURI;
    }

    modifier onlyEOA() {
        require(tx.origin == msg.sender);
        _;
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            SETTERS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    function setState(State _state) external onlyOwner {
        state = _state;
    }

    function openSecondBatch() external onlyOwner {
        batchState = BatchState.SECOND;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            MINT
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */

    function checkSupply(uint256 amount) private returns (uint256 _maxSupply) {
        if (batchState == BatchState.FIRST) {
            _maxSupply = 50;
        } else {
            _maxSupply = maxSupply;
        }
    }

    function mintOwner(uint256 amount) external onlyOwner {
        require(state == State.NOT_ACTIVE, "ALREADY_ACTIVE");
        require(totalSupply() + amount <= checkSupply(amount), "MAX_SUPPLY");
        uint256 _tokenId = nextTokenId;
        for (uint256 i; i < amount; ) {
            _mint(msg.sender, _tokenId++);

            unchecked {
                ++i;
            }
        }
        nextTokenId = _tokenId;
    }

    function mintOwnerReceiver(uint256 amount, address[] calldata addresses)
        external
        onlyOwner
    {
        require(state == State.NOT_ACTIVE, "ALREADY_ACTIVE");
        require(totalSupply() + amount <= checkSupply(amount), "MAX_SUPPLY");
        require(amount == addresses.length, "LENGTH");
        uint256 _tokenId = nextTokenId;
        for (uint256 i; i < amount; ) {
            _mint(addresses[i], _tokenId++);
            unchecked {
                ++i;
            }
        }
        nextTokenId = _tokenId;
    }

    function mintPublic(uint256 _mintAmount) external payable onlyEOA {
        require(state > State.NOT_ACTIVE, "MINT_NOT_ACTIVE");
        require(
            totalSupply() + _mintAmount <= checkSupply(_mintAmount),
            "MAX_SUPPLY"
        );
        require(
            mintedByAddress[msg.sender] + _mintAmount <= maxPerWallet,
            "MAX_PER_WALLET"
        );
        require(msg.value >= price * _mintAmount, "INSUFFICIENT_ETH");
        mintedByAddress[msg.sender] += _mintAmount;

        for (uint256 i; i < _mintAmount; ) {
            _mint(msg.sender, nextTokenId++);
            unchecked {
                ++i;
            }
        }
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            BURNS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */

    function burn(uint256 tokenId, string calldata btcReceiverAddress) public {
        require(state == State.BURN_ACTIVE, "BURN_NOT_ACTIVE");
        require(ownerOf(tokenId) == msg.sender, "NOT_OWNED");

        burnRecords[tokenId] = BurnRecord({
            owner: msg.sender,
            timestamp: uint128(block.timestamp),
            btcReceiverAddress: btcReceiverAddress,
            btcTransactionHash: ""
        });
        burntTokenIds.push(tokenId);
        _burn(tokenId);
    }

    function batchBurn(
        uint256[] calldata tokenIds,
        string[] calldata btcReceiverAddresses
    ) external {
        require(state == State.BURN_ACTIVE, "BURN_NOT_ACTIVE");
        require(
            tokenIds.length == btcReceiverAddresses.length,
            "Invalid input"
        );
        for (uint256 i; i < tokenIds.length; ) {
            burn(tokenIds[i], btcReceiverAddresses[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getBurntTokenIds() external view returns (uint256[] memory) {
        return burntTokenIds;
    }

    function getBurnRecord(uint256 tokenId)
        external
        view
        returns (BurnRecord memory)
    {
        return burnRecords[tokenId];
    }

    function getBurnRecords(uint256[] calldata tokenId)
        external
        view
        returns (BurnRecord[] memory records)
    {
        records = new BurnRecord[](tokenId.length);
        for (uint256 i; i < tokenId.length; ) {
            records[i] = burnRecords[tokenId[i]];
            unchecked {
                ++i;
            }
        }
    }

    function getBurnRecords()
        external
        view
        returns (BurnRecord[] memory records)
    {
        uint256 n = burntTokenIds.length;
        records = new BurnRecord[](n);
        for (uint256 i; i < n; ) {
            records[i] = burnRecords[burntTokenIds[i]];
            unchecked {
                ++i;
            }
        }
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                        ADMIN BURNS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */

    function adminBurnOverride(uint256 tokenId, BurnRecord calldata record)
        external
        onlyOwner
    {
        if (burnRecords[tokenId].timestamp == 0) {
            burntTokenIds.push(tokenId);
        }
        burnRecords[tokenId] = record;
    }

    function linkBtcTransactions(
        uint256[] calldata tokenIds,
        string[] calldata btcTransactionHash
    ) external onlyOwner {
        require(tokenIds.length == btcTransactionHash.length, "LENGTH");

        for (uint256 i; i < tokenIds.length; ) {
            burnRecords[tokenIds[i]].btcTransactionHash = btcTransactionHash[i];
            unchecked {
                ++i;
            }
        }
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                        ALLOWED OPERATOR
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            INTERNALS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            WITHDRAW
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "WITHDRAW_0");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success);
    }
}