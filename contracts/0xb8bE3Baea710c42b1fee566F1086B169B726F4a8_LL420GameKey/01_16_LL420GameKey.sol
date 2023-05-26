//
//  __   __      _____    ______
// /__/\/__/\   /_____/\ /_____/\
// \  \ \: \ \__\:::_:\ \\:::_ \ \
//  \::\_\::\/_/\   _\:\| \:\ \ \ \
//   \_:::   __\/  /::_/__ \:\ \ \ \
//        \::\ \   \:\____/\\:\_\ \ \
//         \__\/    \_____\/ \_____\/
//
// 420.game Game Key (Green Pass equivalent)
//
// by LOOK LABS
//
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "erc721a/contracts/ERC721A.sol";
import "./interfaces/ILL420GreenPass.sol";
import "./interfaces/ILL420Bud.sol";

contract LL420GameKey is Ownable, Pausable, ReentrancyGuard, ERC721A {
    address public constant GREENPASS_CONTRACT = 0xFe190723a465C99293c4f035045C0a6880D25DbE;
    address public BUD_CONTRACT;
    uint256 public constant GREENPASS_TOKEN_ID = 0;

    uint256 public startTimestamp;
    string private _baseTokenURI;

    // TODO: Check intervals and supplies on mainnet
    uint256 public constant TOTAL_SUPPLY = 10000;

    event FreeBudClaimed(address indexed _user, uint256 indexed _startTokenIndex, uint256 indexed _quantity);

    constructor(
        address _gpContract,
        address _budContract,
        uint256 _startTimestamp,
        string memory _baseuri
    ) ERC721A("LOOK LABS 420 Game Key", "GK") {
        // GREENPASS_CONTRACT = _gpContract;
        BUD_CONTRACT = _budContract;
        startTimestamp = _startTimestamp;
        _baseTokenURI = _baseuri;
    }

    // Before calling this method, sender should approve GreenPass token usage
    // through `ERC1155.setApprovalForAll` for burning the tokens
    function convert(uint256 _quantity) external whenNotPaused nonReentrant {
        require(block.timestamp >= startTimestamp, "LL420GameKey: not allowed time");
        require(_quantity > 0, "LL420GameKey: zero quantity not allowed");

        ILL420GreenPass greenPass = ILL420GreenPass(GREENPASS_CONTRACT);
        uint256 _balanace = greenPass.balanceOf(msg.sender, GREENPASS_TOKEN_ID);

        require(_quantity <= _balanace, "LL420GameKey: Bigger quantity than actual balance");
        require(_totalMinted() + _quantity <= TOTAL_SUPPLY, "LL420GameKey: Reached max supply");

        // Burn ERC1155 tokens (Green Passes only)
        greenPass.burn(msg.sender, GREENPASS_TOKEN_ID, _quantity);

        uint256 _startTokenIndex = _currentIndex;
        _safeMint(msg.sender, _quantity);

        // Free Buds mint
        mintFreeBuds(_quantity);

        emit FreeBudClaimed(msg.sender, _startTokenIndex, _quantity);
    }

    function mintFreeBuds(uint256 _quantity) private {
        require(BUD_CONTRACT != address(0), "LL420GameKey: Missing bud contract");

        ILL420Bud(BUD_CONTRACT).freeMint(msg.sender, _quantity);
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // Owner functions
    function setBaseURI(string memory _baseURIParam) external onlyOwner {
        _baseTokenURI = _baseURIParam;
    }

    function setBudContract(address _budContractAddress) external onlyOwner {
        BUD_CONTRACT = _budContractAddress;
    }

    function setStartTimestamp(uint256 _startTimestamp) external onlyOwner {
        startTimestamp = _startTimestamp;
    }

    function vaultMint(uint256 _quantity) external onlyOwner {
        require(_totalMinted() + _quantity <= TOTAL_SUPPLY, "LL420GameKey: Reached the max supply");

        _mint(msg.sender, _quantity, "", false);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function currentIndex() public view returns (uint256) {
        return _currentIndex;
    }

    // Verify ownership
    function verifyOwnershipBatch(address _user, uint256[] memory _ids) public view returns (bool) {
        require(_ids.length > 0, "LL420GameKey: IDs cannot be empty");

        // Prerequisities: Sort the ids.
        // Insertion sort is usually more efficient than Quick sort, because sorted `_ids` are sent
        _insertionSort(_ids, 0, _ids.length);

        address firstIdOwner = ownerOf(_ids[0]);

        if (_ids.length == 1) {
            return firstIdOwner == _user;
        }

        if (firstIdOwner != _user) {
            return false;
        }

        uint256 prevId = _ids[0];
        for (uint256 index = 1; index < _ids.length; index++) {
            uint256 curId = _ids[index];

            TokenOwnership memory ownership = _ownerships[curId];
            if (!ownership.burned) {
                if (ownership.addr != address(0)) {
                    if (ownership.addr != _user) {
                        return false;
                    }
                } else {
                    if (prevId + 1 != curId) {
                        return false;
                    }
                }
            } else {
                return false;
            }

            prevId = curId;
        }

        return true;
    }

    function _insertionSort(
        uint256[] memory array,
        uint256 i,
        uint256 j
    ) private pure {
        if (j - i < 2) return;

        uint256 p;
        for (uint256 k = i + 1; k < j; ++k) {
            p = k;
            while (p > i && array[p - 1] > array[p]) {
                _swap(array, p, p - 1);
                p--;
            }
        }
    }

    function _swap(
        uint256[] memory array,
        uint256 i,
        uint256 j
    ) private pure {
        (array[i], array[j]) = (array[j], array[i]);
    }
}