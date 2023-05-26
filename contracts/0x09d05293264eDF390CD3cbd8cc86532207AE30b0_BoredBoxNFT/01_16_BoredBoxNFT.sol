// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

//          +--------------------------------------------------+
//         /|                                                 /|
//        / |                                                / |
//       *--+-----------------------------------------------*  |
//       |  |                                               |  |
//       |  |                                               |  |
//       |  |                                               |  |
//       |  |   ██████╗  ██████╗ ██████╗ ███████╗██████╗    |  |
//       |  |   ██╔══██╗██╔═══██╗██╔══██╗██╔════╝██╔══██╗   |  |
//       |  |   ██████╔╝██║   ██║██████╔╝█████╗  ██║  ██║   |  |
//       |  |   ██╔══██╗██║   ██║██╔══██╗██╔══╝  ██║  ██║   |  |
//       |  |   ██████╔╝╚██████╔╝██║  ██║███████╗██████╔╝   |  |
//       |  |   ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═════╝    |  |
//       |  |                                               |  |
//       |  |                                               |  |
//       |  |                                               |  |
//       |  +-----------------------------------------------+--+
//       | /                                                | /
//       |/                                                 |/
//       *--------------------------------------------------*

import { BoredBoxStorage } from "@boredbox-solidity-contracts/bored-box-storage/contracts/BoredBoxStorage.sol";
import { IBoredBoxNFT_Functions } from "@boredbox-solidity-contracts/interface-bored-box-nft/contracts/IBoredBoxNFT.sol";
import { IValidateMint } from "@boredbox-solidity-contracts/interface-validate-mint/contracts/IValidateMint.sol";
import { Ownable } from "@boredbox-solidity-contracts/ownable/contracts/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ERC721 } from "../contracts/token/ERC721/ERC721.sol";

/// @title Tracks BoredBox token ownership and coordinates minting
/// @author S0AndS0
/// @custom:link https://boredbox.io/
contract BoredBoxNFT is IBoredBoxNFT_Functions, BoredBoxStorage, ERC721, Ownable, ReentrancyGuard {
    uint256 public constant VALIDATE_STATUS__NA = 0;
    uint256 public constant VALIDATE_STATUS__PASS = 1;
    uint256 public constant VALIDATE_STATUS__FAIL = 2;

    /// Emitted after validateMint checks pass
    event Mint(address indexed to, uint256 indexed tokenId);

    /// Emitted after assets are fully distributed
    // @param tokenId pointer into `token__owner`, `token__opened_timestamp`, `token__status`, `token__generation`
    event Opened(uint256 indexed tokenId);

    /// Emitted when client requests a Box to be opened
    // @param from address of `msg.sender`
    // @param to address of `token__owner[tokenId]`
    // @param tokenId pointer into storage; `token__owner`, `token__opened_timestamp`, `token__status`, `token__generation`
    event RequestOpen(address indexed from, address indexed to, uint256 indexed tokenId);

    modifier onlyAuthorized() {
        require(
            msg.sender == this.owner() || (coordinator != address(0) && msg.sender == coordinator),
            "Not authorized"
        );
        _;
    }

    /// Called via `new BoredBoxNFT(/* ... */)`
    /// @param name_ NFT name to store in `name`
    /// @param symbol_ NFT symbol to pass to `ERC721` parent contract
    /// @param coordinator_ Address to store in `coordinator`
    /// @param uri_root string pointing to IPFS directory of JSON metadata files
    /// @param quantity Amount of tokens available for first generation
    /// @param price Exact `{ value: _price_ }` required by `mint()` function
    /// @param sale_time The `block.timestamp` to allow general requests to `mint()` function
    /// @param ref_validators List of addresses referencing `ValidateMint` contracts
    /// @param cool_down Time to add to current `block.timestamp` after `token__status` is set to `TOKEN_STATUS__OPENED`
    /// @custom:throw "Open time must be after sale time"
    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        address coordinator_,
        string memory uri_root,
        uint256 quantity,
        uint256 price,
        uint256 sale_time,
        uint256 open_time,
        address[] memory ref_validators,
        uint256 cool_down
    ) ERC721(name_, symbol_) Ownable(owner_) {
        require(open_time >= sale_time, "Open time must be after sale time");

        coordinator = coordinator_;

        box__uri_root[1] = uri_root;
        box__lower_bound[1] = 1;
        box__upper_bound[1] = quantity;
        box__quantity[1] = quantity;
        box__price[1] = price;
        box__sale_time[1] = sale_time;
        box__cool_down[1] = cool_down;
        box__open_time[1] = open_time;
        box__validators[1] = ref_validators;

        current_box = 1;
    }

    /// @dev See {IBoredBoxNFT_Functions-mint}
    function mint(uint256 boxId, bytes memory auth) external payable {
        require(msg.value == box__price[boxId], "Incorrect amount sent");
        return _mintBox(msg.sender, boxId, auth);
    }

    /// Mutates `token__status` storage if checks pass
    /// @dev See {IBoredBoxNFT_Functions-setPending}
    function setPending(uint256[] memory tokenIds) external payable onlyAuthorized {
        uint256 length = tokenIds.length;
        require(length > 0, "No token IDs provided");

        uint256 tokenId;
        uint256 current__token__status;
        uint256 boxId;
        for (uint256 i; i < length; ) {
            tokenId = tokenIds[i];
            require(tokenId > 0, "Invalid token ID");

            unchecked {
                ++i;
            }

            current__token__status = token__status[tokenId];
            if (current__token__status == TOKEN_STATUS__PENDING) {
                continue;
            }

            require(current__token__status != TOKEN_STATUS__OPENED, "Already opened");

            boxId = token__generation[tokenId];
            require(boxId > 0, "Box does not exist");
            require(block.timestamp >= box__open_time[boxId], "Not time yet");

            token__status[tokenId] = TOKEN_STATUS__PENDING;
            emit RequestOpen(msg.sender, token__owner[tokenId], tokenId);
        }
    }

    /// @dev See {IBoredBoxNFT_Functions-box__allValidators}
    function box__allValidators(uint256 boxId) external view virtual returns (address[] memory) {
        return box__validators[boxId];
    }

    /// @dev See {IBoredBoxNFT_Functions-setOpened}
    function setOpened(uint256[] memory tokenIds) external payable onlyAuthorized {
        uint256 length = tokenIds.length;
        require(length > 0, "No token IDs provided");

        uint256 tokenId;
        for (uint256 i; i < length; ) {
            tokenId = tokenIds[i];
            require(tokenId > 0, "Invalid token ID");

            require(token__generation[tokenId] > 0, "Box does not exist");

            require(token__status[tokenId] == TOKEN_STATUS__PENDING, "Not yet pending delivery");

            token__status[tokenId] = 1;
            token__opened_timestamp[tokenId] = block.timestamp;

            emit Opened(tokenId);

            unchecked {
                ++i;
            }
        }
    }

    /// @dev See {IBoredBoxNFT_Functions-setOpened}
    function setBoxURI(uint256 boxId, string memory uri_root) external payable onlyAuthorized {
        require(boxId > 0, "Box does not exist");
        box__uri_root[boxId] = uri_root;
    }

    /// @dev See {IBoredBoxNFT_Functions-setIsPaused}
    function setIsPaused(uint256 boxId, bool is_paused) external payable onlyAuthorized {
        box__is_paused[boxId] = is_paused;
    }

    /// @dev See {IBoredBoxNFT_Functions-setAllPaused}
    function setAllPaused(bool is_paused) external payable onlyAuthorized {
        all_paused = is_paused;
    }

    /// @dev See {IBoredBoxNFT_Functions-setAllPaused}
    function setCoordinator(address coordinator_) external payable onlyOwner {
        coordinator = coordinator_;
    }

    /// @dev See {IBoredBoxNFT_Functions-setValidator}
    function setValidator(
        uint256 boxId,
        uint256 index,
        address ref_validator
    ) external payable onlyOwner {
        require(all_paused || box__is_paused[boxId], "Not paused");
        box__validators[boxId][index] = ref_validator;
    }

    /// @dev See {IBoredBoxNFT_Functions-newBox}
    function newBox(
        string memory uri_root,
        uint256 quantity,
        uint256 price,
        uint256 sale_time,
        uint256 open_time,
        address[] memory ref_validators,
        uint256 cool_down
    ) external payable onlyOwner {
        require(!all_paused, "New boxes are paused");
        require(open_time >= sale_time, "Open time must be after sale time");

        uint256 last_boxId = current_box;
        uint256 next_boxId = 1 + last_boxId;
        uint256 last_upper_bound = box__upper_bound[last_boxId];

        box__lower_bound[next_boxId] += 1 + last_upper_bound;
        box__upper_bound[next_boxId] = last_upper_bound + quantity;
        box__quantity[next_boxId] = quantity;
        box__price[next_boxId] = price;
        box__uri_root[next_boxId] = uri_root;
        box__validators[next_boxId] = ref_validators;
        box__sale_time[next_boxId] = sale_time;
        box__open_time[next_boxId] = open_time;
        box__cool_down[next_boxId] = cool_down;

        current_box = next_boxId;
    }

    /// @dev See {IBoredBoxNFT_Functions-withdraw}
    function withdraw(address payable to, uint256 amount) external payable onlyOwner nonReentrant {
        (bool success, ) = to.call{ value: amount }("");
        require(success, "Transfer failed");
    }

    /// @dev See {IERC721Metadata-tokenURI}
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(token__owner[tokenId] != address(0), "ERC721Metadata: URI query for nonexistent token");

        uint256 boxId = token__generation[tokenId];

        string memory uri_root = box__uri_root[boxId];
        require(bytes(uri_root).length > 0, "URI not set");

        uint256 current__token__status = token__status[tokenId];
        string memory uri_path;

        if (current__token__status == TOKEN_STATUS__CLOSED) {
            uri_path = "closed";
        } else if (current__token__status == TOKEN_STATUS__OPENED) {
            uri_path = "opened";
        } else if (current__token__status == TOKEN_STATUS__PENDING) {
            uri_path = "pending";
        }

        return string(abi.encodePacked("ipfs://", uri_root, "/", uri_path, ".json"));
    }

    /// @dev See {ERC721-_beforeTokenTransfer}
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (from == address(0)) {
            return;
        }

        uint256 current__token__status = token__status[tokenId];
        require(current__token__status != TOKEN_STATUS__PENDING, "Pending delivery");

        if (to == address(0)) {
            require(current__token__status == TOKEN_STATUS__OPENED, "Cannot burn un-opened Box");
            return;
        }

        if (current__token__status == TOKEN_STATUS__OPENED) {
            uint256 boxId = token__generation[tokenId];
            require(
                block.timestamp >= token__opened_timestamp[tokenId] + box__cool_down[boxId],
                "Need to let things cool down"
            );
        }
    }

    function _mintBox(
        address to,
        uint256 boxId,
        bytes memory auth
    ) internal nonReentrant {
        require(boxId > 0, "validateMint: boxId must be greater than zero");
        require(!all_paused && !box__is_paused[boxId], "Minting is paused");

        bytes32 hash_of_auth = sha256(auth);
        require(hash__auth_token[hash_of_auth] == 0, "Auth already used");

        uint256 quantity = box__quantity[boxId];
        require(quantity > 0, "No more for this round");
        uint256 tokenId = (box__upper_bound[boxId] + 1) - quantity;

        uint256 original_owner = token__original_owner[boxId][to];
        require(
            original_owner < box__lower_bound[boxId] || original_owner > box__upper_bound[boxId],
            "Limited to one mint per address"
        );

        bool all_validators_passed;
        uint256 validate_status;
        address[] memory _ref_validators = box__validators[boxId];
        uint256 length = _ref_validators.length;

        for (uint256 i; i < length; ) {
            if (_ref_validators[i] == address(0)) {
                all_validators_passed = false;
                break;
            }

            validate_status = IValidateMint(_ref_validators[i]).validate(to, boxId, tokenId, auth);
            unchecked {
                ++i;
            }

            if (validate_status == VALIDATE_STATUS__NA) {
                continue;
            } else if (validate_status == VALIDATE_STATUS__FAIL) {
                all_validators_passed = false;
                break;
            } else if (validate_status == VALIDATE_STATUS__PASS && length == i + 1) {
                all_validators_passed = true;
            }
        }

        if (!all_validators_passed) {
            require(box__sale_time[boxId] <= block.timestamp, "Please wait till sale time");
        }

        super._safeMint(to, tokenId);
        box__quantity[boxId] -= 1;
        hash__auth_token[hash_of_auth] = tokenId;
        token__generation[tokenId] = boxId;
        token__original_owner[boxId][to] = tokenId;
        emit Mint(to, tokenId);
    }
}