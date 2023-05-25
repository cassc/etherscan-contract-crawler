//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

/*                  @@@@@@@@@@@@@             @@@@@@@@@@@@@@
                  @@@@@@@@@@@@@@                 @@@@@@@@@@@@@@
                @@@@@@@@@@@@@@                     @@@@@@@@@@@@@@
              @@@@@@@@@@@@@@@                       @@@@@@@@@@@@@@@
            @@@@@@@@@@@@@@@                           @@@@@@@@@@@@@@
           @@@@@@@@@@@@@@                               @@@@@@@@@@@@@@
         @@@@@@@@@@@@@@                                  @@@@@@@@@@@@@@@
       @@@@@@@@@@@@@@@                                     @@@@@@@@@@@@@@
      @@@@@@@@@@@@@@                                         @@@@@@@@@@@@@@
    @@@@@@@@@@@@@@                      @                     @@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@             @@       @@@       @@             @@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@                 @@@    @@@    @@@                 @@@@@@@@@@@@@@
                                 @@@@@@@@@@@@@@@
                                  @@@@@@@@@@@@@
                          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                                  @@@@@@@@@@@@@
                                 @@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@                 @@@    @@@    @@@                 @@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@             @@       @@@       @@             @@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@                      @                     @@@@@@@@@@@@@@@
      @@@@@@@@@@@@@@                                         @@@@@@@@@@@@@@
       @@@@@@@@@@@@@@@                                     @@@@@@@@@@@@@@
         @@@@@@@@@@@@@@@                                 @@@@@@@@@@@@@@@
           @@@@@@@@@@@@@@                               @@@@@@@@@@@@@@
             @@@@@@@@@@@@@@                           @@@@@@@@@@@@@@
              @@@@@@@@@@@@@@@                       @@@@@@@@@@@@@@@
                @@@@@@@@@@@@@@                     @@@@@@@@@@@@@@
                  @harry830622                   @@@@@@@@@@@@@@               */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

error NotEOA();
error NotStarted();
error Ended();
error TicketUsed();
error NotEnoughETH();
error NotEnoughQuota();
error PaperHand();
error MintTooManyAtOnce();
error ZeroQuantity();
error SoldOut();
error InvalidSignature();
error ShellNotSet();
error MigrateTooManyAtOnce();

interface IShell {
    function nextTokenId() external view returns (uint256);

    function mint(address to, uint256 quantity) external;
}

contract Code is Ownable, ERC1155, ERC1155Burnable, ERC2981 {
    using BitMaps for BitMaps.BitMap;

    uint256 public constant MAX_TOTAL_SUPPLY = 9999;
    uint256 public constant PRE_SALE_MAX_TOTAL_SUPPLY = 9999 - 1500 - 411;
    uint256 public constant MAX_NUM_MINTS_PER_TX = 3;
    uint256 public constant MAX_NUM_MIGRATIONS_PER_TX = 10;
    uint256 public constant PRICE_PER_TOKEN = 0.12 ether;

    uint256 public preSaleMintStartTime = 2**256 - 1;
    uint256 public publicMintStartTime = 2**256 - 1;
    uint256 public migrationStartTime = 2**256 - 1;

    uint256 public preSaleMintEndTime = 2**256 - 1;
    uint256 public publicMintEndTime = 2**256 - 1;
    uint256 public migrationEndTime = 2**256 - 1;

    mapping(address => uint256) public addressToNumMintedFrees;
    mapping(address => uint256) public addressToNumMintedWhitelists;
    mapping(address => uint256) public addressToNumMintedEmWhitelists;
    BitMaps.BitMap private _isPublicMintTicketUsed;

    uint256 public nextTokenId = 1;
    uint256 public totalNumMintedTokens;

    IERC1155 public immutable em;
    address private immutable _signer;
    IShell public shell;

    event Migrate(
        uint256 indexed startTokenId,
        uint256 quantity,
        address indexed from
    );

    modifier onlyEOA() {
        if (msg.sender != tx.origin) {
            revert NotEOA();
        }
        _;
    }

    constructor(address em_)
        ERC1155("ipfs://QmZzTWbeX8Tjn2uGtUuAGvh1kCcx4qgr5qTrTiCZEnivQ4")
    {
        em = IERC1155(em_);
        _signer = owner();

        _setDefaultRoyalty(address(0xd188Db484A78C147dCb14EC8F12b5ca1fcBC17f5), 750);

        uint256 reserveQuantity = 411;
        totalNumMintedTokens = reserveQuantity;
        _mint(address(0x6267e2cD575E5F602cD01e7a6E12c3DE08228eC5), nextTokenId, reserveQuantity, "");
        ++nextTokenId;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function isPublicMintTicketUsed(uint256 ticket)
        external
        view
        returns (bool)
    {
        return _isPublicMintTicketUsed.get(ticket);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setPreSaleMintTime(uint256 start, uint256 end) external onlyOwner {
        if (end <= start) {
            revert();
        }
        preSaleMintStartTime = start;
        preSaleMintEndTime = end;
    }

    function setPublicSaleMintTime(uint256 start, uint256 end)
        external
        onlyOwner
    {
        if (end <= start) {
            revert();
        }
        publicMintStartTime = start;
        publicMintEndTime = end;
    }

    function setMigrationTime(uint256 start, uint256 end) external onlyOwner {
        if (end <= start) {
            revert();
        }
        migrationStartTime = start;
        migrationEndTime = end;
    }

    function setShell(address addr) external onlyOwner {
        shell = IShell(addr);
    }

    function preSaleMint(
        uint256 freeMintQuantity,
        uint256 freeMintAllowedQuantity,
        uint256 whitelistMintQuantity,
        uint256 whitelistMintAllowedQuantity,
        uint256 emWhitelistMintQuantity,
        uint256 emWhitelistMintAllowedQuantity,
        uint256 snapshottedEmQuantity,
        bytes calldata signature
    ) external payable onlyEOA {
        uint256 blockTime = block.timestamp;
        if (blockTime < preSaleMintStartTime) {
            revert NotStarted();
        }
        if (blockTime >= preSaleMintEndTime) {
            revert Ended();
        }

        bytes32 hash = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    freeMintAllowedQuantity,
                    whitelistMintAllowedQuantity,
                    emWhitelistMintAllowedQuantity,
                    snapshottedEmQuantity
                )
            )
        );
        if (ECDSA.recover(hash, signature) != _signer) {
            revert InvalidSignature();
        }

        if (freeMintQuantity > 0) {
            if (
                addressToNumMintedFrees[msg.sender] + freeMintQuantity >
                freeMintAllowedQuantity
            ) {
                revert NotEnoughQuota();
            }
            addressToNumMintedFrees[msg.sender] += freeMintQuantity;
        }

        if (whitelistMintQuantity > 0) {
            if (
                addressToNumMintedWhitelists[msg.sender] +
                    whitelistMintQuantity >
                whitelistMintAllowedQuantity
            ) {
                revert NotEnoughQuota();
            }
            addressToNumMintedWhitelists[msg.sender] += whitelistMintQuantity;
        }

        if (emWhitelistMintQuantity > 0) {
            if (
                addressToNumMintedEmWhitelists[msg.sender] +
                    emWhitelistMintQuantity >
                emWhitelistMintAllowedQuantity
            ) {
                revert NotEnoughQuota();
            }
            addressToNumMintedEmWhitelists[
                msg.sender
            ] += emWhitelistMintQuantity;

            if (
                em.balanceOf(msg.sender, 0) + em.balanceOf(msg.sender, 1) <
                snapshottedEmQuantity
            ) {
                revert PaperHand();
            }
        }

        uint256 quantity = freeMintQuantity +
            whitelistMintQuantity +
            emWhitelistMintQuantity;
        if (quantity == 0) {
            revert ZeroQuantity();
        }
        if (totalNumMintedTokens + quantity > PRE_SALE_MAX_TOTAL_SUPPLY) {
            revert SoldOut();
        }
        totalNumMintedTokens += quantity;

        if (
            msg.value <
            (whitelistMintQuantity + emWhitelistMintQuantity) * PRICE_PER_TOKEN
        ) {
            revert NotEnoughETH();
        }

        _mint(msg.sender, nextTokenId, quantity, "");
        ++nextTokenId;
    }

    function publicSaleMint(
        uint256 quantity,
        uint256 ticket,
        bytes calldata signature
    ) external payable onlyEOA {
        uint256 blockTime = block.timestamp;
        if (blockTime < publicMintStartTime) {
            revert NotStarted();
        }
        if (blockTime >= publicMintEndTime) {
            revert Ended();
        }

        bytes32 hash = ECDSA.toEthSignedMessageHash(
            keccak256(abi.encodePacked(msg.sender, ticket))
        );
        if (ECDSA.recover(hash, signature) != _signer) {
            revert InvalidSignature();
        }

        if (_isPublicMintTicketUsed.get(ticket)) {
            revert TicketUsed();
        }
        _isPublicMintTicketUsed.set(ticket);

        if (quantity > MAX_NUM_MINTS_PER_TX) {
            revert MintTooManyAtOnce();
        }

        if (quantity == 0) {
            revert ZeroQuantity();
        }
        if (totalNumMintedTokens + quantity > MAX_TOTAL_SUPPLY) {
            revert SoldOut();
        }
        totalNumMintedTokens += quantity;

        if (msg.value < quantity * PRICE_PER_TOKEN) {
            revert NotEnoughETH();
        }

        _mint(msg.sender, nextTokenId, quantity, "");
        ++nextTokenId;
    }

    function migrate(uint256[] calldata ids, uint256[] calldata quantities)
        external
        onlyEOA
    {
        uint256 blockTime = block.timestamp;
        if (blockTime < migrationStartTime) {
            revert NotStarted();
        }
        if (blockTime >= migrationEndTime) {
            revert Ended();
        }

        if (address(shell) == address(0)) {
            revert ShellNotSet();
        }

        uint256 totalQuantity;
        uint256 numQuantities = quantities.length;
        for (uint256 i = 0; i < numQuantities; ++i) {
            totalQuantity += quantities[i];
        }
        if (totalQuantity > MAX_NUM_MIGRATIONS_PER_TX) {
            revert MigrateTooManyAtOnce();
        }

        burnBatch(msg.sender, ids, quantities);

        uint256 startTokenId = shell.nextTokenId();
        shell.mint(msg.sender, totalQuantity);

        emit Migrate(startTokenId, totalQuantity, msg.sender);
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        payable(to).transfer(amount);
    }
}