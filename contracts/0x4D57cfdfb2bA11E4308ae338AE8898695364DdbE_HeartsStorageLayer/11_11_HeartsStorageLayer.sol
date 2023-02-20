// SPDX-License-Identifier: MIT
/**
 * Creator: Virtue Labs
 * Authors:
 *** Code: 0xYeety, CTO - Virtue labs
 *** Concept: Church, CEO - Virtue Labs
**/

pragma solidity ^0.8.17;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./HeartColors.sol";

contract HeartsStorageLayer is Ownable, DefaultOperatorFilterer {
    using Address for address;

    error TransferError(bool approvedOrOwner, bool fromPrevOwnership);

    uint256 public _nextToMint = 0;
    uint256 private _lineageNonce = 0;

    mapping(uint256 => string) private _bases;

    struct TokenInfo {
        uint256 genome;
        address owner;
        uint64 lastShifted;
        HeartColor color;
        uint24 padding;
        address parent;
        uint48 numChildren;
        uint48 lineageDepth;
    }

    struct AddressInfo {
        uint128 inactiveBalance;
        uint128 activeBalance;
    }

    mapping(uint256 => TokenInfo) private _tokenData;
    mapping(address => AddressInfo) private _balances;
    mapping(address => mapping(uint256 => uint256)) private _ownershipOrderings;
    mapping(uint256 => uint256) private _orderPositions;

    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => uint256)) private _operatorApprovals;

    mapping(uint256 => uint256) private _activations;
    mapping(uint256 => uint256) private _burns;

    address public inactiveContract;
    address public activeContract;
    address public lbrContract;
    address public successorContract;

    modifier onlyHearts() {
        require(msg.sender == inactiveContract || msg.sender == activeContract, "nh");
        _;
    }

    modifier onlyInactive() {
        require(msg.sender == inactiveContract, "ni");
        _;
    }

    modifier onlyActive() {
        require(msg.sender == activeContract, "na");
        _;
    }

    modifier onlySuccessor() {
        require(msg.sender == successorContract, "na");
        _;
    }

    uint256 private _activeSupply;
    uint256 private _burnedSupply;

    /******************/

    bool public royaltySwitch = true;

    modifier storage_onlyAllowedOperator(address from, address msgSender) virtual {
        if (royaltySwitch) {
            if (from != msgSender) {
                _checkFilterOperator(msgSender);
            }
        }
        _;
    }

    modifier storage_onlyAllowedOperatorApproval(address operator) virtual {
        if (royaltySwitch) {
            _checkFilterOperator(operator);
        }
        _;
    }

    function flipRoyaltySwitch() public onlyOwner {
        royaltySwitch = !royaltySwitch;
    }

    constructor() {
        _bases[0] = "A";
        _bases[1] = "C";
        _bases[2] = "G";
        _bases[3] = "T";
    }

    function storage_balanceOf(bool active, address owner) public view returns (uint256) {
        require(owner != address(0), "0");
        return (active ? _balances[owner].activeBalance : _balances[owner].inactiveBalance);
    }

    function _totalBalance(address owner) private view returns (uint256) {
        return _balances[owner].activeBalance + _balances[owner].inactiveBalance;
    }

    function storage_ownerOf(bool active, uint256 tokenId) public view returns (address) {
        require(_exists(active, tokenId), "e");
        return _tokenData[tokenId].owner;
    }

    function storage_colorOf(bool active, uint256 tokenId) public view returns (HeartColor) {
        require(_exists(active, tokenId), "e");
        return _tokenData[tokenId].color;
    }

    function storage_parentOf(bool active, uint256 tokenId) public view returns (address) {
        require(_exists(active, tokenId), "e");
        return _tokenData[tokenId].parent;
    }

    function storage_lineageDepthOf(bool active, uint256 tokenId) public view returns (uint256) {
        require(_exists(active, tokenId), "e");
        return uint256(_tokenData[tokenId].lineageDepth);
    }

    function storage_numChildrenOf(bool active, uint256 tokenId) public view returns (uint256) {
        require(_exists(active, tokenId), "e");
        return uint256(_tokenData[tokenId].numChildren);
    }

    function storage_rawGenomeOf(bool active, uint256 tokenId) public view returns (uint256) {
        require(_exists(active, tokenId), "e");
        return _tokenData[tokenId].genome;
    }

    function storage_genomeOf(bool active, uint256 tokenId) public view returns (string memory) {
        require(_exists(active, tokenId), "e");
        uint256 rawGenome = storage_rawGenomeOf(active, tokenId);
        string memory toReturn = "";
        for (uint256 i = 0; i < 128; i++) {
            toReturn = string(abi.encodePacked(toReturn, _bases[(rawGenome>>(i*2))%4]));
        }
        return toReturn;
    }

    function storage_lastShifted(bool active, uint256 tokenId) public view returns (uint64) {
        require(_exists(active, tokenId), "e");
        return _tokenData[tokenId].lastShifted;
    }

    function storage_transferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) public onlyHearts storage_onlyAllowedOperator(from, msgSender) {
        _transfer(msgSender, msg.sender == activeContract, from, to, tokenId);
    }

    function storage_safeTransferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public onlyHearts storage_onlyAllowedOperator(from, msgSender) {
        storage_transferFrom(msgSender, from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "z");
    }

    function storage_safeTransferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) public onlyHearts storage_onlyAllowedOperator(from, msgSender) {
        storage_safeTransferFrom(msgSender, from, to, tokenId, "");
    }

    function storage_approve(
        address msgSender,
        address to,
        uint256 tokenId
    ) public onlyHearts storage_onlyAllowedOperatorApproval(to) {
        address owner = storage_ownerOf(msg.sender == activeContract, tokenId);
        require(
            msgSender == owner ||
            msgSender == storage_getApproved(msg.sender == activeContract, tokenId) ||
            storage_isApprovedForAll(msg.sender == activeContract, owner, msgSender),
                "a");
        _approve(to, tokenId, owner);
    }

    function storage_getApproved(bool active, uint256 tokenId) public view returns (address) {
        if (active != _isActive(tokenId)) {
            return address(0);
        }
        return _tokenApprovals[tokenId];
    }

    function storage_setApprovalForAll(
        address msgSender,
        address operator,
        bool _approved
    ) public onlyHearts storage_onlyAllowedOperatorApproval(operator) {
        uint256 operatorApproval = _operatorApprovals[msgSender][operator];

        if (msg.sender == activeContract) {
            operatorApproval = 2*(_approved ? 1 : 0) + operatorApproval%2;
        }
        else {
            operatorApproval = 2*(operatorApproval>>1) + (_approved ? 1 : 0);
        }

        _operatorApprovals[msgSender][operator] = operatorApproval;
        ERC721TopLevelProto(msg.sender).emitApprovalForAll(msgSender, operator, _approved);
    }

    function storage_isApprovedForAll(bool active, address owner, address operator) public view returns (bool) {
        return ((_operatorApprovals[owner][operator] >> (active ? 1 : 0))%2 == 1);
    }

    /********/

    function storage_totalSupply(bool active) public view returns (uint256) {
        if (active) {
            return _activeSupply;
        }
        else {
            return ((_nextToMint - _activeSupply) - _burnedSupply);
        }
    }

    function storage_tokenOfOwnerByIndex(
        bool active,
        address owner,
        uint256 index
    ) public view returns (uint256) {
        require(owner != address(0), "0");

        uint256 thisBalance = storage_balanceOf(active, owner);
        uint256 otherBalance = storage_balanceOf(!active, owner);
        require(index < thisBalance, "ind/bal");

        uint256 curIndex = 0;
        for (uint256 i = 0; i < (thisBalance + otherBalance); i++) {
            uint256 curToken = _ownershipOrderings[owner][i];
            if (_isActive(curToken) == active) {
                if (curIndex == index) {
                    return curToken;
                }
                curIndex++;
            }
        }

        revert("u");
    }

    function storage_tokenByIndex(bool active, uint256 index) public view returns (uint256) {
        require(_exists(active, index), "e");
        return index;
    }

    /********/

    function _generateRandomLineage(address to, bool mode) private view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    to,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - ((mode ? ((_lineageNonce>>128)%256) : ((_lineageNonce)%256)) + 1)),
                    (mode ? (_lineageNonce%(1<<128)) : (_lineageNonce>>128))
                )
            )
        );
    }

    function mint(
        address to,
        HeartColor color,
        uint256 lineageToken,
        uint256 lineageDepth,
        address parent
    ) public onlyHearts returns (uint256) {
        uint256 nextToMint = _nextToMint;
        TokenInfo memory newTokenData;

        newTokenData.owner = to;
        newTokenData.lastShifted = uint64(block.timestamp);
        newTokenData.color = color;
        newTokenData.parent = parent;

        uint256 newLineageData = _generateRandomLineage(to, true);
        _lineageNonce = _lineageNonce ^ newLineageData;
        if (msg.sender == activeContract) {
            uint256 lineageModifier = _generateRandomLineage(to, false);
            _lineageNonce = _lineageNonce ^ lineageModifier;
            uint256 tokenLineage = _tokenData[lineageToken].genome;

            uint256 newGenome = 0;
            for (uint256 i = 0; i < 256; i += 2) {
                if ((lineageModifier>>i)%4 == 0) {
                    newGenome += newLineageData & (3<<i);
                }
                else {
                    newGenome += tokenLineage & (3<<i);
                }
            }

            newTokenData.genome = newGenome;

            newTokenData.lineageDepth = (_tokenData[lineageToken].lineageDepth + 1);

            _tokenData[lineageToken].numChildren += 1;
        }
        else {
            newTokenData.genome = newLineageData;

            newTokenData.lineageDepth = uint48(lineageDepth);
        }

        _tokenData[nextToMint] = newTokenData;

        uint256 toTotalBalance = _totalBalance(to);
        _ownershipOrderings[to][toTotalBalance] = nextToMint;
        _orderPositions[nextToMint] = toTotalBalance;

        if (msg.sender == activeContract) {
            _activations[nextToMint/256] += 1<<(nextToMint%256);
            _balances[to].activeBalance += 1;
            _activeSupply++;
        }
        else {
            _balances[to].inactiveBalance += 1;
        }

        ERC721TopLevelProto(msg.sender).emitTransfer(address(0), to, _nextToMint);

        _nextToMint++;

        return nextToMint;
    }

    function _liquidate(uint256 tokenId) private {
        address tokenOwner = storage_ownerOf(true, tokenId);

        _tokenData[tokenId].lastShifted = uint64(block.timestamp);

        _activations[tokenId/256] -= 1<<(tokenId%256);

        ERC721TopLevelProto(activeContract).emitTransfer(tokenOwner, address(0), tokenId);
        ERC721TopLevelProto(inactiveContract).emitTransfer(address(0), tokenOwner, tokenId);

        _balances[tokenOwner].activeBalance -= 1;
        _balances[tokenOwner].inactiveBalance += 1;
        _activeSupply--;
    }

    function storage_liquidate(uint256 tokenId) public onlyActive {
        _liquidate(tokenId);
    }

    function _activate(uint256 tokenId) private {
        address tokenOwner = storage_ownerOf(false, tokenId);

        _tokenData[tokenId].lastShifted = uint64(block.timestamp);

        _activations[tokenId/256] += 1<<(tokenId%256);

        ERC721TopLevelProto(inactiveContract).emitTransfer(tokenOwner, address(0), tokenId);
        ERC721TopLevelProto(activeContract).emitTransfer(address(0), tokenOwner, tokenId);
        ActiveHearts(activeContract).initExpiryTime(tokenId);

        _balances[tokenOwner].activeBalance += 1;
        _balances[tokenOwner].inactiveBalance -= 1;
        _activeSupply++;
    }

    function storage_activate(uint256 tokenId) public onlyInactive {
        _activate(tokenId);
    }

    function _burn(uint256 tokenId) private {
        address prevOwnership = storage_ownerOf(false, tokenId);

        _balances[prevOwnership].inactiveBalance -= 1;

        _tokenData[tokenId].owner = address(0);

        uint256 fromBalanceTotal = _totalBalance(prevOwnership);
        uint256 curTokenOrder = _orderPositions[tokenId];
        uint256 lastFromTokenId = _ownershipOrderings[prevOwnership][fromBalanceTotal];
        if (tokenId != lastFromTokenId) {
            _ownershipOrderings[prevOwnership][curTokenOrder] = lastFromTokenId;
            _orderPositions[lastFromTokenId] = curTokenOrder;
            delete _ownershipOrderings[prevOwnership][fromBalanceTotal];
        }

        ERC721TopLevelProto(inactiveContract).emitTransfer(prevOwnership, address(0), tokenId);

        _burnedSupply++;
    }

    function storage_burn(uint256 tokenId) public onlyInactive {
        _burn(tokenId);
    }

    function _batchLiquidate(uint256[] memory tokenIds) private {
        address[] memory tokenOwners = new address[](tokenIds.length);
        address[] memory zeroAddresses = new address[](tokenIds.length);

        uint256 accumulator = 0;
        uint256 curSlot = 0;
        uint256 iterSlot;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            iterSlot = tokenId/256;
            if (iterSlot != curSlot) {
                _activations[curSlot] -= accumulator;
                curSlot = iterSlot;
                accumulator = 0;
            }

            accumulator += (1<<(tokenId%256));

            tokenOwners[i] = _tokenData[tokenId].owner;
            _balances[tokenOwners[i]].activeBalance -= 1;
            _balances[tokenOwners[i]].inactiveBalance += 1;
        }
        _activations[curSlot] -= accumulator;

        ERC721TopLevelProto(activeContract).batchEmitTransfers(tokenOwners, zeroAddresses, tokenIds);
        ERC721TopLevelProto(inactiveContract).batchEmitTransfers(zeroAddresses, tokenOwners, tokenIds);

        _activeSupply -= tokenIds.length;
    }

    function storage_batchLiquidate(uint256[] calldata tokenIds) public onlyActive {
        _batchLiquidate(tokenIds);
    }

    function _batchActivate(uint256[] calldata tokenIds) private {
        address[] memory tokenOwners = new address[](tokenIds.length);
        address[] memory zeroAddresses = new address[](tokenIds.length);

        uint256 accumulator = 0;
        uint256 curSlot = 0;
        uint256 iterSlot;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            iterSlot = tokenId/256;
            if (iterSlot != curSlot) {
                _activations[curSlot] += accumulator;
                curSlot = iterSlot;
                accumulator = 0;
            }

            accumulator += (1<<(tokenId%256));

            tokenOwners[i] = _tokenData[tokenId].owner;
            _balances[tokenOwners[i]].activeBalance += 1;
            _balances[tokenOwners[i]].inactiveBalance -= 1;
        }
        _activations[curSlot] += accumulator;

        ERC721TopLevelProto(activeContract).batchEmitTransfers(zeroAddresses, tokenOwners, tokenIds);
        ERC721TopLevelProto(inactiveContract).batchEmitTransfers(tokenOwners, zeroAddresses, tokenIds);
        ActiveHearts(activeContract).batchInitExpiryTime(tokenIds);

        _activeSupply += tokenIds.length;
    }

    function storage_batchActivate(uint256[] calldata tokenIds) public onlyInactive {
        _batchActivate(tokenIds);
    }

    function _batchBurn(uint256[] memory tokenIds) private {
        address[] memory tokenOwners = new address[](tokenIds.length);
        address[] memory zeroAddresses = new address[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            tokenOwners[i] = _tokenData[tokenId].owner;

            _balances[tokenOwners[i]].inactiveBalance -= 1;

            _tokenData[tokenId].owner = address(0);

            uint256 fromBalanceTotal = _totalBalance(tokenOwners[i]);
            uint256 curTokenOrder = _orderPositions[tokenId];
            uint256 lastFromTokenId = _ownershipOrderings[tokenOwners[i]][fromBalanceTotal];
            if (tokenId != lastFromTokenId) {
                _ownershipOrderings[tokenOwners[i]][curTokenOrder] = lastFromTokenId;
                _orderPositions[lastFromTokenId] = curTokenOrder;
                delete _ownershipOrderings[tokenOwners[i]][fromBalanceTotal];
            }
        }

        ERC721TopLevelProto(inactiveContract).batchEmitTransfers(tokenOwners, zeroAddresses, tokenIds);

        _burnedSupply += tokenIds.length;
    }

    function storage_batchBurn(uint256[] calldata tokenIds) public onlyInactive {
        _batchBurn(tokenIds);
    }

    /******************/

    function setSuccessor(address _successor) public onlyOwner {
        successorContract = _successor;
    }

    function storage_migrate(uint256 tokenId, address msgSender) public onlySuccessor {
        require(msgSender == tx.origin, "bad origin");
        if (_exists(true, tokenId)) {
            _liquidate(tokenId);
            _burn(tokenId);
            LiquidationBurnRewardsProto(lbrContract).disburseMigrationReward(tokenId, msgSender);
        }
        else if (_exists(false, tokenId)) {
            _burn(tokenId);
            LiquidationBurnRewardsProto(lbrContract).disburseMigrationReward(tokenId, msgSender);
        }
        else {
            revert("ne");
        }
    }

    function storage_batchMigrate(uint256[] calldata tokenIds, address msgSender) public onlySuccessor {
        require(msgSender == tx.origin, "bad origin");
        uint256[] memory existsActive = new uint256[](tokenIds.length);
        uint256[] memory existsInactive = new uint256[](tokenIds.length);
        uint256 numExistsActive = 0;
        uint256 numExistsInactive = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_exists(true, tokenIds[i])) {
                existsActive[numExistsActive] = tokenIds[i];
                existsInactive[numExistsInactive] = tokenIds[i];
                numExistsActive++;
                numExistsInactive++;
            }
            else if (_exists(false, tokenIds[i])) {
                existsInactive[numExistsInactive] = tokenIds[i];
                numExistsInactive++;
            }
            else {
                revert("ne");
            }
        }

        if (numExistsActive > 0) {
            uint256[] memory toLiquidate = new uint256[](numExistsActive);
            for (uint256 i = 0; i < numExistsActive; i++) {
                toLiquidate[i] = existsActive[i];
            }

            _batchLiquidate(toLiquidate);
        }

        if (numExistsActive > 0) {
            uint256[] memory toBurn = new uint256[](numExistsInactive);
            for (uint256 i = 0; i < numExistsInactive; i++) {
                toBurn[i] = existsInactive[i];
            }

            _batchBurn(toBurn);
        }

        LiquidationBurnRewardsProto(lbrContract).batchDisburseMigrationReward(tokenIds, msgSender);
    }

    /******************/

    function setActiveContract(address _activeContract) public onlyOwner {
        activeContract = _activeContract;
    }

    function setInactiveContract(address _inactiveContract) public onlyOwner {
        inactiveContract = _inactiveContract;
    }

    function setLBRContract(address _lbrContract) public onlyOwner {
        lbrContract = _lbrContract;
    }

    /******************/

    function _isActive(uint256 tokenId) private view returns (bool) {
        return (((_activations[tokenId/256])>>(tokenId%256))%2 == 1);
    }

    function _exists(bool active, uint256 tokenId) public view returns (bool) {
        return (((tokenId < _nextToMint) && (_tokenData[tokenId].owner != address(0))) && (_isActive(tokenId) == active));
    }

    function _approve(address to, uint256 tokenId, address owner) private {
        _tokenApprovals[tokenId] = to;
        ERC721TopLevelProto(msg.sender).emitApproval(owner, to, tokenId);
    }

    function _transfer(
        address msgSender,
        bool active,
        address from,
        address to,
        uint256 tokenId
    ) private {
        address prevOwnership = storage_ownerOf(active, tokenId);

        bool isApprovedOrOwner = (
            msgSender == prevOwnership ||
            msgSender == storage_getApproved(active, tokenId) ||
            storage_isApprovedForAll(active, prevOwnership, msgSender)
        );
        bool fromPrevOwnership = (prevOwnership == from);
        if (!(isApprovedOrOwner || fromPrevOwnership)) {
            revert TransferError(isApprovedOrOwner, fromPrevOwnership);
        }

        _approve(address(0), tokenId, prevOwnership);

        if (active) {
            _balances[from].activeBalance -= 1;
        }
        else {
            _balances[from].inactiveBalance -= 1;
        }

        _tokenData[tokenId].owner = to;

        uint256 fromBalanceTotal = _totalBalance(from);
        uint256 curTokenOrder = _orderPositions[tokenId];
        uint256 lastFromTokenId = _ownershipOrderings[from][fromBalanceTotal];
        if (tokenId != lastFromTokenId) {
            _ownershipOrderings[from][curTokenOrder] = lastFromTokenId;
            _orderPositions[lastFromTokenId] = curTokenOrder;
            delete _ownershipOrderings[from][fromBalanceTotal];
        }

        uint256 toBalanceTotal = _totalBalance(to);
        _ownershipOrderings[to][toBalanceTotal] = tokenId;
        _orderPositions[tokenId] = toBalanceTotal;

        if (active) {
            _balances[to].activeBalance += 1;
        }
        else {
            _balances[to].inactiveBalance += 1;
        }

        ERC721TopLevelProto(msg.sender).emitTransfer(from, to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
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

    /******************/

    receive() external payable {}

    function withdraw() public onlyOwner {
        (bool success, ) = payable(inactiveContract).call{value: address(this).balance}("");
        require(success, "Payment failed!");
    }

    function withdrawTokens(address tokenAddress) public onlyOwner {
        IERC20(tokenAddress).transfer(inactiveContract, IERC20(tokenAddress).balanceOf(address(this)));
    }
}

////////////////////

abstract contract ERC721TopLevelProto {
    function emitTransfer(address from, address to, uint256 tokenId) public virtual;
    function batchEmitTransfers(
        address[] calldata from,
        address[] calldata to,
        uint256[] calldata tokenIds
    ) public virtual;

    function emitApproval(address owner, address approved, uint256 tokenId) public virtual;

    function emitApprovalForAll(address owner, address operator, bool approved) public virtual;
}

//////////

abstract contract ActiveHearts is ERC721TopLevelProto {
    function initExpiryTime(uint256 heartId) public virtual;
    function batchInitExpiryTime(uint256[] calldata heartIds) public virtual;
}

//////////

abstract contract LiquidationBurnRewardsProto {
    function disburseMigrationReward(uint256 heartId, address to) public virtual;
    function batchDisburseMigrationReward(uint256[] calldata heartIds, address to) public virtual;
}

////////////////////////////////////////