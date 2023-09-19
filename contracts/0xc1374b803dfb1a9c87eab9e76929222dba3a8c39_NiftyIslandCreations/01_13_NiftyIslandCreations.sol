// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { ERC1155 } from "./lib/base/ERC1155.sol";
import { TokenIdentifier } from "./lib/TokenIdentifier.sol";
import { ErrorsAndEvents } from "./lib/ErrorsAndEvents.sol";

contract NiftyIslandCreations is
    ERC1155,
    Ownable,
    ReentrancyGuard,
    ErrorsAndEvents
{
    using TokenIdentifier for uint256;

    string public name;
    string public symbol;
    mapping(address => bool) public approvedCallers;

    modifier onlyApprovedMintCallers(uint256 _id) {
        if (!approvedCallers[_msgSender()] && _msgSender() != getCreator(_id)) {
            revert UnapprovedCaller();
        }
        _;
    }

    modifier onlyApprovedBurnCallers(address _from) {
        if (_from != _msgSender() && !isApprovedForAll(_from, _msgSender())) {
            revert UnapprovedCaller();
        }
        _;
    }

    constructor(
        string memory _baseUri,
        string memory _name,
        string memory _symbol,
        address _seaport,
        address _conduit
    ) ERC1155(_baseUri) {
        name = _name;
        symbol = _symbol;
        approvedCallers[_seaport] = true;
        approvedCallers[_conduit] = true;
    }

    function setURI(string memory _newUri) external onlyOwner {
        _setURI(_newUri);
        emit BaseUriChanged(_newUri);
    }

    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) public nonReentrant onlyApprovedMintCallers(_id) {
        if (_quantity == 0) {
            revert InvalidQuantity();
        }
        _mint(_to, _id, _quantity, _data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory _data
    ) external nonReentrant {
        _mintBatch(to, ids, amounts, _data);
    }

    function burn(
        address _from,
        uint256 _id,
        uint256 _amount
    ) external onlyApprovedBurnCallers(_from) {
        _burn(_from, _id, _amount);
    }

    function burnBatch(
        address _from,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external onlyApprovedBurnCallers(_from) {
        _burnBatch(_from, _ids, _amounts);
    }

    /**
     * @notice Check whether a given token id has been minted
     * @param _id token id
     */
    function exists(uint256 _id) external view returns (bool) {
        return _supply[_id] > 0;
    }

    /**
     * @dev Allows owner to modify the state of an approved caller
     */
    function setApprovedCallerState(
        address _address,
        bool _enabled
    ) external onlyOwner {
        approvedCallers[_address] = _enabled;
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public override {
        if (_amount == 0) {
            revert InvalidQuantity();
        }

        uint256 mintedBalance = super.balanceOf(_from, _id);
        if (mintedBalance < _amount) {
            uint256 fromBalance = balanceOf(_from, _id);

            if (fromBalance < _amount) {
                revert InsufficientBalance();
            }

            // Only mints what _from doesn't already have
            mint(_to, _id, _amount - mintedBalance, _data);
            if (mintedBalance > 0) {
                super.safeTransferFrom(_from, _to, _id, mintedBalance, _data);
            }
        } else {
            super.safeTransferFrom(_from, _to, _id, _amount, _data);
        }
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public override {
        if (_ids.length != _amounts.length) {
            revert ArrayLengthMismatch();
        }

        for (uint256 i = 0; i < _ids.length; i++) {
            // Mint or transfer token depending on if it exists
            safeTransferFrom(_from, _to, _ids[i], _amounts[i], _data);
        }
    }

    function balanceOf(
        address _account,
        uint256 _id
    ) public view virtual override returns (uint256) {
        uint256 balance = super.balanceOf(_account, _id);
        return
            _account == getCreator(_id)
                ? balance + remainingSupply(_id)
                : balance;
    }

    /**
     * @notice Retrieve the max supply for a token id
     * @param _id token id
     */
    function getMaxSupply(uint256 _id) public pure returns (uint256) {
        return _id.tokenMaxSupply();
    }

    /**
     * @notice Retrieve the creator for a token id
     * @param _id token id
     */
    function getCreator(uint256 _id) public pure returns (address) {
        return _id.tokenCreator();
    }

    /**
     * @notice Retrieve the total supply for a token id
     * @param _id token id
     */
    function totalSupply(uint256 _id) public view returns (uint256) {
        return getMaxSupply(_id) - totalBurnedSupply(_id);
    }

    /**
     * @notice Retrieve the total burned supply for a token id
     * @param _id token id
     */
    function totalBurnedSupply(uint256 _id) public view returns (uint256) {
        return _burned[_id];
    }

    /**
     * @notice Retrieve the remaining supply for a token id
     * @param _id token id
     */
    function remainingSupply(uint256 _id) public view returns (uint256) {
        return getMaxSupply(_id) - _supply[_id] - totalBurnedSupply(_id);
    }

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        // Set from address as token creator
        address from = getCreator(id);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        _beforeMint(id, amount);

        unchecked {
            _balances[id][to] += amount;
            _supply[id] += amount;
        }

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        if (ids.length != amounts.length) {
            revert ArrayLengthMismatch();
        }

        require(to != address(0), "ERC1155: transfer to the zero address");

        // Set from address as token creator
        address from = _msgSender();
        address operator = _msgSender();
        uint256 amountOfTokens = ids.length;

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < amountOfTokens; ) {
            if (amounts[i] == 0) {
                revert InvalidQuantity();
            }

            // Caller must be the creator of each token id
            if (getCreator(ids[i]) != operator) {
                revert UnapprovedCaller();
            }

            _beforeMint(ids[i], amounts[i]);

            unchecked {
                _balances[ids[i]][to] += amounts[i];
                _supply[ids[i]] += amounts[i];
                ++i;
            }
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    function _beforeMint(uint256 _id, uint256 _quantity) internal view {
        if (_quantity > remainingSupply(_id)) {
            revert ExceedsSupply();
        }
    }
}