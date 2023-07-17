//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IERC721ASGakuen.sol";

//
//  @@@@@%[email protected]@@@@[email protected]@@@%#: =%@@@#-           -#@@@%+  [email protected]@@@#  %@@[email protected]@#[email protected]@%.%@@:[email protected]@@@@.*%%- %%#
// .=*@@@:%@@*[email protected]@+:@@#*@@#[email protected]@@[email protected]@#-+#@@#:@@@[email protected]@@: %@@@@# [email protected]@%[email protected]@# [email protected]@.:@@@ %@*==+ @@@#[email protected]@+
//  [email protected]@@-.%@#=- %@#*=#@[email protected]@@[email protected]@* *@@[email protected]@* *@@* === [email protected]@[email protected]@# [email protected]@*%@#  %@@:[email protected]@*.%@#=- [email protected]@@@#@@:
// [email protected]@@- [email protected]@@@#[email protected]@@@@@*[email protected]@@ %@@-  [email protected]@@@+  @@@ @@@#[email protected]@@:@@# #@@@@@+ [email protected]@@[email protected]@[email protected]@@@#.*@@%@@@@
//[email protected]@@=  #@#=  [email protected]@%:@@%*@@*:@@@  .%@[email protected]%::@@@  %@=*@@@@@@#[email protected]@%-%@% [email protected]@%:%@@ #@#=   @@#[email protected]@@+
//%@@@@@[email protected]@@@@+%@@[email protected]@[email protected]@%%@@- :@@#-+#@@[email protected]@@@@@@[email protected]@@:*@@*[email protected]@=.*%@[email protected]@@@@@[email protected]@@@@[email protected]@=:@@@:
//
//
// ERC721AS is implemented based on ERC721A (Copyright (c) 2022 Chiru Labs)
// ERC721AS follow same license policy to ERC721A
//
// MIT License
//
// Copyright (c) 2022 OG Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
//
/// @title ERC721ASGakuen
/// ERC721ASGakuen for 'A'uto 'S'chooling & Zero x 'G'akuen NFT smart contract
/// @author MoeKun
/// @author JayB
contract ERC721ASGakuen is Context, ERC165, IERC721ASGakuen {
    using Address for address;
    using Strings for uint256;
   /*
     * @dev this contract use _schoolingPolicy.alpha & beta
     * - alpha : current index
     * - beta : number of checkpoint
     */
    // Presenting whether checkpoint is deleted or not.
    // "1" represent deleted.
    uint256 internal constant CHECKPOINT_DELETEDMASK = uint256(1);

    //0b1111111111111111111111111111111111111111111111111111111111111110
    uint256 internal constant CHECKPOINT_GENERATEDMASK =
        uint256(18446744073709551614);

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenStatus) internal _tokenStatus;

    // Mapping from address to total balance
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    SchoolingPolicy internal _schoolingPolicy;

    // Array to hold schooling checkpoint
    mapping(uint256 => uint256) internal _schoolingCheckpoint;

    // Array to hold URI based on schooling checkpoint
    mapping(uint256 => string) internal _schoolingURI;


    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * If want to change the Start TokenId, override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * Returns whether token is schooling or not.
     */
    function isTakingBreak(uint256 tokenId)
        external
        view
        override
        returns (bool)
    {
        if (!_exists(tokenId)) revert SchoolingQueryForNonexistentToken();
        return _isTakingBreak(tokenId);
    }

    /**
     * Returns latest change time of schooling status.
     */
    function schoolingTimestamp(uint256 tokenId)
        external
        view
        override
        returns (uint256)
    {
        if (!_exists(tokenId)) revert SchoolingQueryForNonexistentToken();
        return uint256(_tokenStatus[tokenId].schoolingTimestamp);
    }

    /**
     * Returns token's total time of shcooling.
     * Used for optimizing and readablilty.
     */
    function _schoolingTotal(
        uint40 currentTime,
        TokenStatus memory _status,
        SchoolingPolicy memory _policy
    ) internal pure returns (uint256) {
        // If schooling is on different phase, existing total = 0
        if (_status.schoolingId != _policy.schoolingId) {
            _status.schoolingTotal = 0;
        }

        // If schooling is not begun yet, total = 0
        if (_policy.schoolingBegin == 0 || currentTime < _policy.schoolingBegin) {
            return 0;
        }

        // If schooling is End, 
        if (_policy.schoolingEnd < currentTime) {
            if (_status.schoolingTimestamp < _policy.schoolingBegin) {
                return uint256(_policy.schoolingEnd - _policy.schoolingBegin);
            }
            if (_status.schoolingTimestamp + _policy.breaktime > _policy.schoolingEnd) {
                return uint256(_status.schoolingTotal);
            }
            return uint256(
                _status.schoolingTotal +
                _policy.schoolingEnd -
                _policy.breaktime -
                _status.schoolingTimestamp
            );
        }

        if (
            _status.schoolingTimestamp == 0 ||
            _status.schoolingTimestamp < _policy.schoolingBegin
        ) {
            return uint256(currentTime - _policy.schoolingBegin);
        }

        if (_status.schoolingTimestamp + _policy.breaktime > currentTime) {
            return uint256(_status.schoolingTotal);
        }

        return uint256(
            _status.schoolingTotal +
            currentTime -
            _status.schoolingTimestamp -
            _policy.breaktime
        );
    }

    /**
     * Returns token's total time of schooling.
     */
    function schoolingTotal(uint256 tokenId)
        external
        view
        override
        returns (uint256)
    {
        if (!_exists(tokenId)) revert SchoolingQueryForNonexistentToken();
        return
            _schoolingTotal(
                uint40(block.timestamp),
                _tokenStatus[tokenId],
                _schoolingPolicy
            );
    }

    /**
     * Returns whether token is taking break
     */
    function _isTakingBreak(uint256 tokenId) internal view returns (bool) {
        unchecked {
            return
                _schoolingPolicy.schoolingBegin != 0 &&
                block.timestamp >= _schoolingPolicy.schoolingBegin &&
                _tokenStatus[tokenId].schoolingTimestamp >=
                _schoolingPolicy.schoolingBegin &&
                ((_tokenStatus[tokenId].schoolingTimestamp +
                    _schoolingPolicy.breaktime) > block.timestamp);
        }
    }

    /**
     * @dev use this to get first custom data in schooling policy.
     */
    function _getSchoolingAlpha() internal view returns (uint256) {
        unchecked {
            return uint256(_schoolingPolicy.alpha);
        }
    }

    /**
     * @dev use this to set first custom data in schooling policy.
     */
    function _setSchoolingAlpha(uint64 _alpha) internal {
        unchecked {
            _schoolingPolicy.alpha = _alpha;
        }
    }

    /**
     * @dev use this to get second custom data in schooling policy.
     */
    function _getSchoolingBeta() internal view returns (uint256) {
        unchecked {
            return uint256(_schoolingPolicy.beta);
        }
    }

    /**
     * @dev use this to set second custom data in schooling policy.
     */
    function _setSchoolingBeta(uint64 _beta) internal {
        unchecked {
            _schoolingPolicy.beta = _beta;
        }
    }

    function _setSchoolingBreaktime(uint40 _breaktime) internal {
        unchecked {
            _schoolingPolicy.breaktime = _breaktime;
        }
    }

    /**
     * @dev set schooling begin manually
     * changing it manually could be resulted in unexpected result
     * please do not use it witout reasonable reason
     */
    function _setSchoolingBegin(uint40 _begin) internal {
        unchecked {
            _schoolingPolicy.schoolingBegin = _begin;
        }
    }

    /**
     * @dev set schooling end manually
     * changing it manually could be resulted in unexpected result
     * please do not use it witout reasonable reason
     */
    function _setSchoolingEnd(uint40 _end) internal {
        unchecked {
            _schoolingPolicy.schoolingEnd = _end;
        }
    }

    /**
     * @dev set schooling identifier manually
     * changing it manually could be resulted in unexpected result
     * please do not use it witout reasonable reason
     */
    function _setSchoolingId(uint8 _schoolingId) internal {
        unchecked {
            _schoolingPolicy.schoolingId = _schoolingId;
        }
    }

    /**
     * Returns period of timelock.
     */
    function schoolingBreaktime() external view override returns (uint256) {
        unchecked {
            return uint256(_schoolingPolicy.breaktime);
        }
    }

    /**
     * Returns when schooling begin in timestamp
     */
    function schoolingBegin() external view override returns (uint256) {
        unchecked {
            return uint256(_schoolingPolicy.schoolingBegin);
        }
    }

    /**
     * Returns when schooling end in timestamp
     */
    function schoolingEnd() external view override returns (uint256) {
        unchecked {
            return uint256(_schoolingPolicy.schoolingEnd);
        }
    }

    /**
     * Returns when schooling identifier
     */
    function schoolingId() external view override returns (uint256) {
        unchecked {
            return uint256(_schoolingPolicy.schoolingId);
        }
    }

    /**
     * Apply new schooling policy.
     * Please use this function to start new season.
     *
     * schoolingId will increase automatically.
     * If new schooling duration is duplicated to existing duration,
     * IT COULD BE ERROR
     */
    function _applyNewSchoolingPolicy(
        uint40 _begin,
        uint40 _end,
        uint40 _breaktime
    ) internal {
        _beforeApplyNewPolicy(_begin, _end, _breaktime);

        SchoolingPolicy memory _policy = _schoolingPolicy;
        if(_policy.schoolingEnd != 0) {
            _policy.schoolingId++;
        }
        _policy.schoolingBegin = _begin;
        _policy.schoolingEnd = _end;
        _policy.breaktime = _breaktime;

        _schoolingPolicy = _policy;

        _afterApplyNewPolicy(_begin, _end, _breaktime);
    }

    /**
     * @dev Adding new schooling checkpoint, schoolingURI and schoolingURI.
     */
    function _addCheckpoint(uint256 checkpoint, string memory schoolingURI)
        internal
        virtual
    {
        SchoolingPolicy memory _policy = _schoolingPolicy;
        _schoolingCheckpoint[_policy.alpha] = (checkpoint &
            CHECKPOINT_GENERATEDMASK);
        _schoolingURI[_policy.alpha] = schoolingURI;

        _policy.alpha++;
        _policy.beta++;
        // Update schoolingPolicy.
        _schoolingPolicy = _policy;
    }

    function _removeCheckpoint(uint256 index) internal virtual {
        uint256 i = 0;
        uint256 counter = 0;
        if (_schoolingPolicy.beta <= index) revert CheckpointOutOfArray();
        while (true) {
            if (_isExistingCheckpoint(_schoolingCheckpoint[i])) {
                counter++;
            }
            // Checkpoint deleting sequence.
            if (counter > index) {
                _schoolingCheckpoint[i] |= CHECKPOINT_DELETEDMASK;
                _schoolingPolicy.beta--;
                return;
            }
            i++;
        }
    }

    /**
     * Replacing certain checkpoint and uri.
     * index using for checking existence and designting certain checkpoint.
     */
    function _replaceCheckpoint(
        uint256 checkpoint,
        string memory schoolingURI,
        uint256 index
    ) internal virtual {
        uint256 i = 0;
        uint256 counter = 0;
        if (_schoolingPolicy.beta <= index) revert CheckpointOutOfArray();
        // counter always syncs with index+1.
        // After satisfying second "if" condition, it will return.
        // Therefore, while condition will never loops infinitely.
        while (true) {
            if (_isExistingCheckpoint(_schoolingCheckpoint[i])) {
                counter++;
            }
            // Checkpoint and uri replacing sequence.
            if (counter > index) {
                _schoolingCheckpoint[i] = checkpoint;
                _schoolingURI[i] = schoolingURI;
                return;
            }
            i++;
        }
    }

    /**
     * Retruns whether checkpoint is existing or not.
     * Used for optimizing and readability.
     */
    function _isExistingCheckpoint(uint256 _checkpoint)
        internal
        pure
        returns (bool)
    {
        return (_checkpoint & CHECKPOINT_DELETEDMASK) == 0;
    }

    /**
     * @dev Returns tokenURI of existing token.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        // Returns baseURI depending on schooling status.
        string memory baseURI = _getSchoolingURI(tokenId);
        if(_hasExtention()) {
          return
              bytes(baseURI).length != 0
                  ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                  : "";
        }
        else {
          return
              bytes(baseURI).length != 0
                  ? string(abi.encodePacked(baseURI, tokenId.toString()))
                  : "";
        }
    }

    /**
     * @dev Returns on schooling URI of 'tokenId'.
     * @dev Depending on total schooling time.
     */
    function _getSchoolingURI(uint256 tokenId)
        internal
        view
        virtual
        returns (string memory)
    {
        TokenStatus memory sData = _tokenStatus[tokenId];
        SchoolingPolicy memory _policy = _schoolingPolicy;
        uint256 total = uint256(
            _schoolingTotal(uint40(block.timestamp), sData, _policy)
        );
        uint256 index;
        uint256 counter = 0;
        for (uint256 i = 0; i < _policy.alpha; i++) {
            if (
                _isExistingCheckpoint(_schoolingCheckpoint[i]) &&
                _schoolingCheckpoint[i] <= total
            ) {
                index = i;
                counter++;
            }
        }

        //if satisfying 'no checkpoint' condition.
        if (index == 0 && counter == 0) {
            return _baseURI();
        }

        return _schoolingURI[index];
    }

    /**
     * Get URI at certain index.
     * index can be identified as schooling.
     */
    function uriAtIndex(uint256 index)
        external
        view
        override
        returns (string memory)
    {
        if (index >= _schoolingPolicy.beta) revert CheckpointOutOfArray();
        uint256 i = 0;
        uint256 counter = 0;
        while (true) {
            if (_isExistingCheckpoint(_schoolingCheckpoint[i])) {
                counter++;
            }
            if (counter > index) {
                return _schoolingURI[i];
            }
            i++;
        }
    }

    /**
     * Get Checkpoint at certain index.
     * index can be identified as schooling.
     */
    function checkpointAtIndex(uint256 index)
        external
        view
        override
        returns (uint256)
    {
        if (index >= _schoolingPolicy.beta) revert CheckpointOutOfArray();
        uint256 i = 0;
        uint256 counter = 0;
        while (true) {
            if (_isExistingCheckpoint(_schoolingCheckpoint[i])) {
                counter++;
            }
            if (counter > index) {
                return _schoolingCheckpoint[i];
            }
            i++;
        }
    }

    // returns number of checkpoints not deleted
    function numOfCheckpoints() external view override returns (uint256) {
        return _schoolingPolicy.beta;
    }
    /**
     * @dev Hook that is called before call applyNewSchoolingPolicy.
     *
     * _begin     - timestamp schooling begin
     * _end       - timestamp schooling end
     * _breaktime - breaktime in second
     */
    function _beforeApplyNewPolicy(
        uint40 _begin,
        uint40 _end,
        uint40 _breaktime
    ) internal virtual {
        SchoolingPolicy memory _policy = _schoolingPolicy;
        _policy.alpha = 0;
        _policy.beta = 0;

        _schoolingPolicy = _policy;
    }

 /**
     * @dev Hook that is called before call applyNewSchoolingPolicy.
     *
     * _begin     - timestamp schooling begin
     * _end       - timestamp schooling end
     * _breaktime - breaktime in second
     */
    function _afterApplyNewPolicy(
        uint40 _begin,
        uint40 _end,
        uint40 _breaktime
    ) internal virtual {
    }

    /**
     * Switching token's schooling status to off in forced way
     */

    function _recordSchoolingStatusChange(uint256 tokenId) internal {
        TokenStatus memory _status = _tokenStatus[tokenId];
        SchoolingPolicy memory _policy = _schoolingPolicy;
        uint40 currentTime = uint40(block.timestamp);
        _status.schoolingTotal = uint40(
            _schoolingTotal(currentTime, _status, _policy)
        );
        _status.schoolingId = _schoolingPolicy.schoolingId;
        _status.schoolingTimestamp = currentTime;
        _tokenStatus[tokenId] = _status;
    }

/*
*  ______ _____   _____ ______ ___  __          
* |  ____|  __ \ / ____|____  |__ \/_ |   /\    
* | |__  | |__) | |        / /   ) || |  /  \   
* |  __| |  _  /| |       / /   / / | | / /\ \  
* | |____| | \ \| |____  / /   / /_ | |/ ____ \ 
* |______|_|  \_\\_____|/_/   |____||_/_/    \_\
*
* ERC721A implementation below.
* - overrided _beforeTokenTransfers to support Auto Schooling
* - remove tracking & keeping it into TokenStatus features
*
*
*/                                               
                                            
    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _balances[owner];
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId)
        internal
        view
        returns (TokenStatus memory)
    {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenStatus memory ownership = _tokenStatus[curr];
                if (!ownership.burned) {
                    if (ownership.owner != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _tokenStatus[curr];
                        if (ownership.owner != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    // Boolean to toggle tokenURI's extension, ".json"
    function _hasExtention() internal view virtual returns (bool) {
        return false;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721ASGakuen.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (
            to.isContract() &&
            !_checkContractOnERC721Received(from, to, tokenId, _data)
        ) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex &&
            !_tokenStatus[tokenId].burned;
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, "");
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _balances[to] += quantity;

            _tokenStatus[startTokenId].owner = to;

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (
                        !_checkContractOnERC721Received(
                            address(0),
                            to,
                            updatedIndex++,
                            _data
                        )
                    ) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _balances[to] += quantity;

            _tokenStatus[startTokenId].owner = to;

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex < end);

            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenStatus memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.owner != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _balances[from] -= 1;
            _balances[to] += 1;

            TokenStatus storage currSlot = _tokenStatus[tokenId];
            currSlot.owner = to;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenStatus storage nextSlot = _tokenStatus[nextTokenId];
            if (nextSlot.owner == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.owner = from;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenStatus memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.owner;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _balances[from] -= 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenStatus storage currSlot = _tokenStatus[tokenId];
            currSlot.owner = from;
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenStatus storage nextSlot = _tokenStatus[nextTokenId];
            if (nextSlot.owner == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.owner = from;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try
            IERC721Receiver(to).onERC721Received(
                _msgSender(),
                from,
                tokenId,
                _data
            )
        returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     *
     * *** IT RECORDS SCHOOLING DATA ***
     *
     * IF YOU DON'T WANT IT, please override this funcion
     *
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {
        if (startTokenId == _currentIndex) return;
        uint256 updatedIndex = startTokenId;
        uint256 end = updatedIndex + quantity;
        do {
            _recordSchoolingStatusChange(updatedIndex++);
        } while (updatedIndex != end);
    }

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}