// SPDX-License-Identifier: Unlicense
// Creator: Mr. Masterchef

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*********************************************************************************************************************/
/*       ___           ___                       ___       ___                 ___           ___           ___       */
/*      /\  \         /\__\          ___        /\__\     /\  \               /\  \         /\__\         /\  \      */
/*     /::\  \       /:/  /         /\  \      /:/  /    /::\  \              \:\  \       /:/  /        /::\  \     */
/*    /:/\:\  \     /:/  /          \:\  \    /:/  /    /:/\:\  \              \:\  \     /:/__/        /:/\:\  \    */
/*   /::\~\:\__\   /:/  /  ___      /::\__\  /:/  /    /:/  \:\__\             /::\  \   /::\  \ ___   /::\~\:\  \   */
/*  /:/\:\ \:|__| /:/__/  /\__\  __/:/\/__/ /:/__/    /:/__/ \:|__|           /:/\:\__\ /:/\:\  /\__\ /:/\:\ \:\__\  */
/*  \:\~\:\/:/  / \:\  \ /:/  / /\/:/  /    \:\  \    \:\  \ /:/  /          /:/  \/__/ \/__\:\/:/  / \:\~\:\ \/__/  */
/*   \:\ \::/  /   \:\  /:/  /  \::/__/      \:\  \    \:\  /:/  /          /:/  /           \::/  /   \:\ \:\__\    */
/*    \:\/:/  /     \:\/:/  /    \:\__\       \:\  \    \:\/:/  /           \/__/            /:/  /     \:\ \/__/    */
/*     \::/__/       \::/  /      \/__/        \:\__\    \::/__/                            /:/  /       \:\__\      */
/*      ~~            \/__/                     \/__/     ~~                                \/__/         \/__/      */
/*                                                                                                                   */
/*         ___           ___       ___           ___           ___           ___           ___           ___         */
/*        /\  \         /\__\     /\  \         /\  \         /\  \         /\  \         /\  \         /\__\        */
/*       /::\  \       /:/  /    /::\  \        \:\  \       /::\  \       /::\  \       /::\  \       /::|  |       */
/*      /:/\:\  \     /:/  /    /:/\:\  \        \:\  \     /:/\:\  \     /:/\:\  \     /:/\:\  \     /:|:|  |       */
/*     /::\~\:\  \   /:/  /    /::\~\:\  \       /::\  \   /::\~\:\  \   /:/  \:\  \   /::\~\:\  \   /:/|:|__|__     */
/*    /:/\:\ \:\__\ /:/__/    /:/\:\ \:\__\     /:/\:\__\ /:/\:\ \:\__\ /:/__/ \:\__\ /:/\:\ \:\__\ /:/ |::::\__\    */
/*    \/__\:\/:/  / \:\  \    \/__\:\/:/  /    /:/  \/__/ \/__\:\ \/__/ \:\  \ /:/  / \/_|::\/:/  / \/__/~~/:/  /    */
/*         \::/  /   \:\  \        \::/  /    /:/  /           \:\__\    \:\  /:/  /     |:|::/  /        /:/  /     */
/*          \/__/     \:\  \       /:/  /     \/__/             \/__/     \:\/:/  /      |:|\/__/        /:/  /      */
/*                     \:\__\     /:/  /                                   \::/  /       |:|  |         /:/  /       */
/*                      \/__/     \/__/                                     \/__/         \|__|         \/__/        */
/*********************************************************************************************************************/

contract ERC721StorageLayer is Ownable {
    using Address for address;
    using Strings for uint256;

    //////////

    mapping(uint256 => address) private registeredContracts;
    mapping(address => uint256) private contractNumberings;
    mapping(address => bool) private isRegistered;
    uint256 numRegistered;

    modifier onlyRegistered() {
        _isRegistered();
        _;
    }
    function _isRegistered() internal view virtual {
        require(isRegistered[msg.sender], "r");
    }

    mapping(address => string) private _contractNames;
    mapping(address => string) private _contractSymbols;
    bool public canSetNameAndSymbol = true;

    mapping(address => string) private _contractDescriptions;
    mapping(address => string) private _contractImages;

    //////////

    address public mintingContract;

    modifier onlyMintingContract() {
        _isMintingContract();
        _;
    }
    function _isMintingContract() internal view virtual {
        require(msg.sender == mintingContract, "m");
    }

    //////////

    uint256 currentIndex;
    mapping(uint256 => address) _ownerships;
    mapping(address => uint256) _balances;

    address public immutable burnAddress = 0x000000000000000000000000000000000000dEaD;
    mapping(address => uint256) private _burnCounts;

    //////////

    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => mapping(address => bool))) private _operatorApprovals;

    ////////////////////

    function registerTopLevel(
        string memory name_,
        string memory symbol_,
        string memory description_,
        string memory image_
    ) public {
        require(numRegistered < 5, "mr");
        require(tx.origin == owner(), "a");

        registeredContracts[numRegistered] = msg.sender;
        contractNumberings[msg.sender] = numRegistered;

        _contractNames[msg.sender] = name_;
        _contractSymbols[msg.sender] = symbol_;
        _contractDescriptions[msg.sender] = description_;
        _contractImages[msg.sender] = image_;

        isRegistered[msg.sender] = true;
        numRegistered++;
    }

    function registerMintingContract() public {
        require(tx.origin == owner(), "a");
        mintingContract = msg.sender;
    }

    //////////

    function storage_totalSupply(address collection) public view returns (uint256) {
        require(isRegistered[collection], "r");
        return (currentIndex/5) - _burnCounts[collection];
    }

    function storage_tokenByIndex(
        address collection,
        uint256 index
    ) public view returns (uint256) {
        require(isRegistered[collection], "r");
        require(index < (currentIndex/5), "g");
        require(storage_ownerOf(collection, index) != burnAddress, "b");
        return index;
    }

    function storage_tokenOfOwnerByIndex(
        address collection,
        address owner,
        uint256 index
    ) public view returns (uint256) {
        require(isRegistered[collection], "r");
        require(index < storage_balanceOf(collection, owner), "b");
        uint256 numTokenIds = currentIndex;
        uint256 tokenIdsIdx = 0;
        address currOwnershipAddr = address(0);
        uint256 j;
        uint256 offset = contractNumberings[collection];
        for (uint256 i = 0; i < numTokenIds/5; i++) {
            j = i*5 + offset;
            address ownership = _ownerships[j];
            if (ownership != address(0)) {
                currOwnershipAddr = ownership;
            }
            if (currOwnershipAddr == owner) {
                if (tokenIdsIdx == index) {
                    return i;
                }
                tokenIdsIdx++;
            }
        }
        revert("u");
    }

    function storage_tokenOfOwnerByIndexStepped(
        address collection,
        address owner,
        uint256 index,
        uint256 lastToken,
        uint256 lastIndex
    ) public view returns (uint256) {
        require(isRegistered[collection], "r");
        require(index < storage_balanceOf(collection, owner), "b");
        uint256 numTokenIds = currentIndex;
        uint256 tokenIdsIdx = ((lastIndex == 0) ? 0 : (lastIndex + 1));
        address currOwnershipAddr = address(0);
        uint256 j;
        uint256 offset = contractNumberings[collection];
        for (uint256 i = ((lastToken == 0) ? 0 : (lastToken + 1)); i < numTokenIds/5; i++) {
            j = i*5 + offset;
            address ownership = _ownerships[j];
            if (ownership != address(0)) {
                currOwnershipAddr = ownership;
            }
            if (currOwnershipAddr == owner) {
                if (tokenIdsIdx == index) {
                    return i;
                }
                tokenIdsIdx++;
            }
        }
        revert("u");
    }

    function storage_balanceOf(
        address collection,
        address owner
    ) public view returns (uint256) {
        require(isRegistered[collection], "r");
        require(owner != address(0) || owner != burnAddress, "0/burn");
        return (_balances[owner] >> (14*contractNumberings[collection]))%(1<<14);
    }

    function storage_ownerOf(
        address collection,
        uint256 tokenId
    ) public view returns (address) {
        require(isRegistered[collection], "r");
        require(tokenId < currentIndex/5, "t");

        uint256 offset = contractNumberings[collection];
        for (uint256 i = tokenId*5 + offset; i >= 0; i--) {
            address ownership = _ownerships[i];
            if (ownership != address(0)) {
                return ownership;
            }
        }

        revert("o");
    }

    function storage_name(address collection) public view returns (string memory) {
        require(isRegistered[collection], "r");
        return _contractNames[collection];
    }

    function storage_setName(address collection, string memory newName) public onlyOwner {
        require(isRegistered[collection] && canSetNameAndSymbol, "r/cs");
        _contractNames[collection] = newName;
    }

    function storage_symbol(address collection) public view returns (string memory) {
        require(isRegistered[collection] && canSetNameAndSymbol, "r/cs");
        return _contractSymbols[collection];
    }

    function storage_setSymbol(address collection, string memory newSymbol) public onlyOwner {
        require(isRegistered[collection], "r");
        _contractSymbols[collection] = newSymbol;
    }

    function flipCanSetNameAndSymbol() public onlyOwner {
        require(canSetNameAndSymbol, "cs");
        canSetNameAndSymbol = false;
    }

    function storage_setDescription(
        address collection,
        string memory newDescription
    ) public onlyOwner {
        require(isRegistered[collection], "r");
        _contractDescriptions[collection] = newDescription;
    }

    function storage_setImage(
        address collection,
        string memory newImage
    ) public onlyOwner {
        require(isRegistered[collection], "r");
        _contractImages[collection] = newImage;
    }

    function storage_approve(address msgSender, address to, uint256 tokenId) public onlyRegistered {
        address owner = ERC721StorageLayer.storage_ownerOf(msg.sender, tokenId);
        require(to != owner, "o");

        require(
            msgSender == owner || storage_isApprovedForAll(msg.sender, owner, msgSender),
            "a"
        );

        _approve(to, tokenId*5 + contractNumberings[msg.sender], owner);
    }

    function storage_getApproved(
        address collection,
        uint256 tokenId
    ) public view returns (address) {
        require(isRegistered[collection], "r");

        uint256 mappedTokenId = tokenId*5 + contractNumberings[collection];
        require(_exists(mappedTokenId, tokenId), "a");

        return _tokenApprovals[mappedTokenId];
    }

    function storage_setApprovalForAll(
        address msgSender,
        address operator,
        bool approved
    ) public onlyRegistered {
        require(operator != msgSender, "a");

        _operatorApprovals[msg.sender][msgSender][operator] = approved;
        ERC721TopLevelProto(msg.sender).emitApprovalForAll(msgSender, operator, approved);
    }

    function storage_globalSetApprovalForAll(
        address operator,
        bool approved
    ) public {
        require(operator != msg.sender, "a");

        for (uint256 i = 0; i < 5; i++) {
            address topLevelContract = registeredContracts[i];
            require(!(ERC721TopLevelProto(topLevelContract).operatorRestrictions(operator)), "r");
            _operatorApprovals[topLevelContract][msg.sender][operator] = approved;
            ERC721TopLevelProto(topLevelContract).emitApprovalForAll(msg.sender, operator, approved);
        }
    }

    function storage_isApprovedForAll(
        address collection,
        address owner,
        address operator
    ) public view returns (bool) {
        require(isRegistered[collection], "r");
        return _operatorApprovals[collection][owner][operator];
    }

    function storage_transferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) public onlyRegistered {
        _transfer(msgSender, from, to, tokenId*5 + contractNumberings[msg.sender]);
        ERC721TopLevelProto(msg.sender).emitTransfer(from, to, tokenId);
    }

    function storage_safeTransferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) public onlyRegistered {
        storage_safeTransferFrom(msgSender, from, to, tokenId, "");
    }

    function storage_safeTransferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public onlyRegistered {
        _transfer(msgSender, from, to, tokenId*5 + contractNumberings[msg.sender]);
        ERC721TopLevelProto(msg.sender).emitTransfer(from, to, tokenId);
        require(
            _checkOnERC721Received(msgSender, from, to, tokenId, _data),
            "z"
        );
    }

    function storage_burnToken(address msgSender, uint256 tokenId) public onlyRegistered {
        _transfer(
            msgSender,
            storage_ownerOf(msg.sender, tokenId),
            burnAddress,
            tokenId*5 + contractNumberings[msg.sender]
        );
        _burnCounts[msg.sender] += 1;
        ERC721TopLevelProto(msg.sender).emitTransfer(msgSender, burnAddress, tokenId);
    }

    function storage_exists(
        address collection,
        uint256 tokenId
    ) public view returns (bool) {
        require(isRegistered[collection], "r");
        return _exists(tokenId*5 + contractNumberings[collection], tokenId);
    }

    function _exists(uint256 mappedTokenId, uint256 tokenId) private view returns (bool) {
        return (mappedTokenId < currentIndex && _ownerships[tokenId] != burnAddress);
    }

    function storage_safeMint(
        address msgSender,
        address to,
        uint256 quantity
    ) public onlyMintingContract {
        storage_safeMint(msgSender, to, quantity, "");
    }

    function storage_safeMint(
        address msgSender,
        address to,
        uint256 quantity,
        bytes memory _data
    ) public onlyMintingContract {
        storage_mint(to, quantity);
        require(_checkOnERC721Received(msgSender, address(0), to, (currentIndex/5) - 1, _data), "z");
    }

    function storage_mint(address to, uint256 quantity) private {
        uint256 startTokenId = currentIndex/5;
        require(to != address(0), "0");
        // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
        require(!_exists(currentIndex, startTokenId), "a");

        uint256 balanceQtyAdd = 0;
        for (uint256 i = 0; i < 5; i++) {
            balanceQtyAdd += (quantity << (i*14));
        }
        _balances[to] = _balances[to] + balanceQtyAdd;
        _ownerships[currentIndex] = to;

        uint256 updatedIndex = startTokenId;

        for (uint256 i = 0; i < quantity; i++) {
            for (uint256 j = 0; j < 5; j++) {
                ERC721TopLevelProto(registeredContracts[j]).emitTransfer(address(0), to, updatedIndex);
            }
            updatedIndex++;
        }

        currentIndex = updatedIndex*5;
    }

    function storage_contractURI(address collection) public view virtual returns (string memory) {
        require(isRegistered[collection], "r");
        return string(
            abi.encodePacked(
                "data:application/json;utf8,{\"name\":\"", storage_name(collection), "\",",
                "\"description\":\"", _contractDescriptions[collection], "\",",
                "\"image\":\"", _contractImages[collection], "\",",
                "\"external_link\":\"https://crudeborne.wtf\",",
                "\"seller_fee_basis_points\":500,\"fee_recipient\":\"",
                uint256(uint160(mintingContract)).toHexString(), "\"}"
            )
        );
    }

    //////////

    function _transfer(
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) private {
        uint256 collectionTokenId = tokenId/5;
        address prevOwnership = storage_ownerOf(msg.sender, collectionTokenId);

        bool isApprovedOrOwner = (msgSender == prevOwnership ||
        storage_getApproved(msg.sender, collectionTokenId) == msgSender ||
        storage_isApprovedForAll(msg.sender, prevOwnership, msgSender));

        require(isApprovedOrOwner && prevOwnership == from, "a");
        require(prevOwnership == from, "o");
        require(to != address(0), "0");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership);

        _balances[from] -= (1 << (contractNumberings[msg.sender]*14));
        _balances[to] += (1 << (contractNumberings[msg.sender]*14));
        _ownerships[tokenId] = to;

        // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
        // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
        uint256 nextTokenId = tokenId + 1;
        if (_ownerships[nextTokenId] == address(0)) {
            if (_exists(nextTokenId, nextTokenId/5)) {
                _ownerships[nextTokenId] = prevOwnership;
            }
        }
    }

    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        ERC721TopLevelProto(msg.sender).emitApproval(owner, to, tokenId/5);
    }

    function _checkOnERC721Received(
        address msgSender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msgSender, from, tokenId, _data) returns (bytes4 retVal) {
                return retVal == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("z");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    //////////

    receive() external payable {
        (bool success, ) = payable(mintingContract).call{value: msg.value}("");
        require(success, "F");
    }

    function withdrawTokens(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }
}

////////////////////

abstract contract ERC721TopLevelProto {
    mapping(address => bool) public operatorRestrictions;
    function emitTransfer(address from, address to, uint256 tokenId) public virtual;
    function emitApproval(address owner, address approved, uint256 tokenId) public virtual;
    function emitApprovalForAll(address owner, address operator, bool approved) public virtual;
}

////////////////////////////////////////