// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "./AltsTokenOperatorFilter.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {OperatorFilterer} from "./OperatorFilterer.sol";

abstract contract TokenHierarchy is
    ERC721A,
    ERC721Holder,
    ERC1155Holder,
    ERC2981,
    Ownable,
    OperatorFilterer
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IERC20;

    /// @dev Operator filter
    bool public operatorFilteringEnabled;
    /// @dev Minting/trading status
    bool public contractLocked = false;

    uint256 public waitDuration = 1 hours;

    address public altsTokenOperatorFilter;

    bool public contractFiltering = false;

    bool public childrenLocked = true;

    /// @dev
    mapping(uint256 => uint256) private waitStartTime;

    /// @dev tokenId => contract Addresses
    mapping(uint256 => EnumerableSet.AddressSet) private erc20TokenContracts;
    mapping(uint256 => EnumerableSet.AddressSet) private erc721TokenContracts;
    mapping(uint256 => EnumerableSet.AddressSet) private erc1155TokenContracts;

    /// @dev tokenId => (token contract => balance)
    mapping(uint256 => mapping(address => uint256)) private child20Balances;

    /// @dev tokenId => (token contract => tokenid => balance)
    mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
        private child1155Balances;

    /// @dev token contract => array tokenids
    mapping(address => EnumerableSet.UintSet) private uniqueChild1155TokenIds;

    /// @dev ERC-721 children
    mapping(uint256 => mapping(address => EnumerableSet.UintSet))
        private child721Tokens;
    mapping(uint256 => uint256) private total721Children;

    /// @dev child address => childId => tokenId
    mapping(address => mapping(uint256 => uint256)) private child721TokenOwner;

    function setWaitDuration(uint256 number) public onlyOwner {
        waitDuration = number;
    }

    /// @dev Mint status
    function setContractLocked(bool status) public onlyOwner {
        contractLocked = status;
    }

    /// @dev Mint status
    function setChildrenLocked(bool status) public onlyOwner {
        childrenLocked = status;
    }

    function setAltsTokenOperatorFilter(
        address _filterAddress
    ) public onlyOwner {
        altsTokenOperatorFilter = _filterAddress;
        contractFiltering = true;
    }

    /// @dev Royalties
    function setRoyalties(address recipient, uint96 value) public onlyOwner {
        _setDefaultRoyalty(recipient, value);
    }

    /// @dev Set contractFiltering
    function setContractFiltering(bool value) public onlyOwner {
        contractFiltering = value;
    }

    /// @dev Interface Support
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721A, ERC2981, ERC1155Receiver)
        returns (bool)
    {
        /**
         * @dev Supports the following interfaceIds:
         * IERC165: 0x01ffc9a7
         * IERC721: 0x80ac58cd
         * IERC721Metadata: 0x5b5e139f
         * IERC2981: 0x2a55205a
         */
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            ERC1155Receiver.supportsInterface(interfaceId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function _startTokenId() internal pure override(ERC721A) returns (uint256) {
        return 1;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        require(!contractLocked, "Contract is locked");
        require(
            waitStartTime[tokenId] + waitDuration < block.timestamp,
            "Transfer blocked for wait period"
        );
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function isContractApproved(
        address _childContract
    ) private view returns (bool) {
        if (contractFiltering) {
            return
                AltsTokenOperatorFilter(altsTokenOperatorFilter)
                    .isContractApproved(_childContract);
        } else {
            return false;
        }
    }

    /**
     * @dev childRescue is an OwnerOnly function in the case of lost children.
     * @param _tokenId where original child token was kept
     * @param _childContract contract of child token
     * @param _childTokenId tokenId of child token
     */
    function childRescue(
        uint256 _type,
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId
    ) public onlyOwner {
        if (_type == 0) {
            // ERC20 rescue
            uint256 balance = child20Balances[_tokenId][_childContract];
            _removeERC20Child(_tokenId, _childContract, balance);
            IERC20(_childContract).transfer(msg.sender, balance);
        } else if (_type == 1) {
            // ERC721 rescue
            child721Tokens[_tokenId][_childContract].remove(_childTokenId);
            if (child721Tokens[_tokenId][_childContract].length() == 0) {
                erc721TokenContracts[_tokenId].remove(_childContract);
            }
            total721Children[_tokenId]--;
            child721TokenOwner[_childContract][_childTokenId] = 0;
            ERC721A(_childContract).transferFrom(address(this), msg.sender, _childTokenId);
        } else {
            uint256 amount = child1155Balances[_tokenId][_childContract][
                _childTokenId
            ];
            _removeERC1155Child(_tokenId, _childContract, _childTokenId, amount);
            IERC1155(_childContract).safeTransferFrom(
                address(this),
                msg.sender,
                _childTokenId,
                amount,
                ""
            );
        }
    }

    /// @dev ERC721 children
    function transferERC721Child(
        uint256 _tokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId
    ) public {
        require(!childrenLocked, "Child addition/removal temporarily locked");
        require(_to != address(0), "Receiving address not valid");
        require(ownerOf(_tokenId) == msg.sender, "Not authorized owner");
        require(
            child721TokenOwner[_childContract][_childTokenId] == _tokenId,
            "Not a owner of child"
        );

        child721Tokens[_tokenId][_childContract].remove(_childTokenId);
        if (child721Tokens[_tokenId][_childContract].length() == 0) {
            erc721TokenContracts[_tokenId].remove(_childContract);
        }
        total721Children[_tokenId]--;
        child721TokenOwner[_childContract][_childTokenId] = 0;
        ERC721A(_childContract).transferFrom(address(this), _to, _childTokenId);
        waitStartTime[_tokenId] = block.timestamp;
    }

    function bulkTransferERC721Child(
        uint256 _tokenId,
        address _to,
        address[] calldata _childContracts,
        uint256[] calldata _childTokenIds
    ) public {
        require(
            _childContracts.length == _childTokenIds.length,
            "Contracts length doesn't match"
        );
        require(_childContracts.length > 0, "Missing contracts or tokenIds");
        unchecked {
            for (uint i = 0; i < _childTokenIds.length; i++) {
                transferERC721Child(
                    _tokenId,
                    _to,
                    _childContracts[i],
                    _childTokenIds[i]
                );
            }
        }
    }

    /// @dev Contract must be approved first in _childContract
    function addERC721Child(
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId
    ) public {
        require(!childrenLocked, "Child addition/removal temporarily locked");
        require(ownerOf(_tokenId) == msg.sender, "Not authorized owner");
        require(isContractApproved(_childContract), "Token not approved child");

        uint256 contractLimit = AltsTokenOperatorFilter(
            altsTokenOperatorFilter
        ).getContractLimit(_childContract);
        uint256 globalLimit = AltsTokenOperatorFilter(
            altsTokenOperatorFilter
        ).globalERC721ChildrenLimit();
        require(
            child721Tokens[_tokenId][_childContract].length() + 1 <=
                contractLimit,
            "Child contract limit reached"
        );
        require(
            total721Children[_tokenId] + 1 <= globalLimit,
            "Child contract limit reached"
        );

        erc721TokenContracts[_tokenId].add(_childContract);

        bool added = child721Tokens[_tokenId][_childContract].add(
            _childTokenId
        );
        if (!added) revert("Token may already be added");

        child721TokenOwner[_childContract][_childTokenId] = _tokenId;
        total721Children[_tokenId]++;

        ERC721A(_childContract).transferFrom(
            msg.sender,
            address(this),
            _childTokenId
        );
    }

    function bulkAddERC721Child(
        uint256 _tokenId,
        address[] calldata _childContracts,
        uint256[] calldata _childTokenIds
    ) public {
        require(
            _childContracts.length == _childTokenIds.length,
            "Contracts length doesn't match"
        );
        require(_childContracts.length > 0, "Missing contracts or tokenIds");
        unchecked {
            for (uint i = 0; i < _childTokenIds.length; i++) {
                addERC721Child(_tokenId, _childContracts[i], _childTokenIds[i]);
            }
        }
    }

    function ownerOf721Child(
        address _childContract,
        uint256 _childTokenId
    ) external view returns (address, uint256) {
        uint256 parentTokenId = child721TokenOwner[_childContract][
            _childTokenId
        ];
        return (ownerOf(parentTokenId), parentTokenId);
    }

    function child721Exists(
        address _childContract,
        uint256 _childTokenId
    ) external view returns (bool) {
        uint256 tokenId = child721TokenOwner[_childContract][_childTokenId];
        return tokenId != 0;
    }

    function total721ChildTokens(
        uint256 _tokenId,
        address _childContract
    ) external view returns (uint256) {
        return child721Tokens[_tokenId][_childContract].length();
    }

    /// @dev ERC20 children
    function balanceOfERC20Child(
        uint256 _tokenId,
        address _childContract
    ) public view returns (uint256) {
        return child20Balances[_tokenId][_childContract];
    }

    function _removeERC20Child(
        uint256 _tokenId,
        address _childContract,
        uint256 _value
    ) private {
        require(!childrenLocked, "Child addition/removal temporarily locked");
        require(_value > 0, "Value should be greater than 0");
        uint256 erc20Balance = child20Balances[_tokenId][_childContract];
        require(erc20Balance >= _value, "Insufficient tokens to remove");
        unchecked {
            uint256 newERC20Balance = erc20Balance - _value;
            child20Balances[_tokenId][_childContract] = newERC20Balance;
            if (newERC20Balance == 0) {
                erc20TokenContracts[_tokenId].remove(_childContract);
            }
        }

        waitStartTime[_tokenId] = block.timestamp;
    }

    function transferERC20Child(
        uint256 _tokenId,
        address _to,
        address _childContract,
        uint256 _value
    ) public {
        require(_to != address(0), "Receiving address not valid");
        require(ownerOf(_tokenId) == msg.sender, "Not authorized owner");
        _removeERC20Child(_tokenId, _childContract, _value);
        require(
            IERC20(_childContract).transfer(_to, _value),
            "ERC20 transfer failed"
        );
    }

    function bulkTransferERC20Child(
        uint256 _tokenId,
        address _to,
        address[] calldata _childContracts,
        uint256[] calldata _values
    ) public {
        require(
            _childContracts.length == _values.length,
            "Contracts length doesn't match"
        );
        require(_childContracts.length > 0, "Missing contracts or tokenIds");
        unchecked {
            for (uint i = 0; i < _childContracts.length; i++) {
                transferERC20Child(
                    _tokenId,
                    _to,
                    _childContracts[i],
                    _values[i]
                );
            }
        }
    }

    function transferSafeERC20Child(
        uint256 _tokenId,
        address _to,
        address _childContract,
        uint256 _value
    ) external {
        require(_to != address(0), "Receiving address not valid");
        require(ownerOf(_tokenId) == msg.sender, "Not authorized owner");
        _removeERC20Child(_tokenId, _childContract, _value);
        IERC20(_childContract).safeTransfer(_to, _value);
    }

    function addERC20Child(
        uint256 _tokenId,
        address _childContract,
        uint256 _value
    ) public {
        require(!childrenLocked, "Child addition/removal temporarily locked");
        require(isContractApproved(_childContract), "Token not approved child");
        require(ownerOf(_tokenId) == msg.sender, "Not authorized owner");
        uint256 contractLimit = AltsTokenOperatorFilter(
            altsTokenOperatorFilter
        ).getContractLimit(_childContract);
        require(
            child20Balances[_tokenId][_childContract] + _value <= contractLimit,
            "Child contract limit reached"
        );

        erc20TokenContracts[_tokenId].add(_childContract);

        unchecked {
            child20Balances[_tokenId][_childContract] += _value;
        }

        IERC20(_childContract).safeTransferFrom(
            msg.sender,
            address(this),
            _value
        );
    }

    function bulkAddERC20Child(
        uint256 _tokenId,
        address[] calldata _childContracts,
        uint256[] calldata _values
    ) public {
        require(
            _childContracts.length == _values.length,
            "Contracts length doesn't match"
        );
        require(_childContracts.length > 0, "Missing contracts or values");
        unchecked {
            for (uint i = 0; i < _childContracts.length; i++) {
                addERC20Child(_tokenId, _childContracts[i], _values[i]);
            }
        }
    }

    /// @dev ERC1155 children
    function balanceOfERC1155Child(
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId
    ) public view returns (uint256) {
        return child1155Balances[_tokenId][_childContract][_childTokenId];
    }

    function _removeERC1155Child(
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId,
        uint256 _value
    ) private {
        require(!childrenLocked, "Child addition/removal temporarily locked");
        require(_value > 0, "Value should be greater than 0");
        uint256 erc1155Balance = child1155Balances[_tokenId][_childContract][
            _childTokenId
        ];
        require(erc1155Balance >= _value, "Insufficient tokens to remove");
        unchecked {
            uint256 newERC1155Balance = erc1155Balance - _value;
            child1155Balances[_tokenId][_childContract][
                _childTokenId
            ] = newERC1155Balance;
        }

        bool hasOtherTokens = false;
        for (uint i=0; i < uniqueChild1155TokenIds[_childContract].length(); i++) {
            uint256 childId = uniqueChild1155TokenIds[_childContract].at(i);
            uint256 balance = child1155Balances[_tokenId][_childContract][childId];
            if (balance > 0) {
                hasOtherTokens = true;
                break;
            }
        }

        if (!hasOtherTokens) {
            erc1155TokenContracts[_tokenId].remove(_childContract);
        }

        waitStartTime[_tokenId] = block.timestamp;
    }

    function transferERC1155Child(
        uint256 _tokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId,
        uint256 _value
    ) public {
        require(_to != address(0), "Receiving address not valid");
        require(ownerOf(_tokenId) == msg.sender, "Not authorized owner");
        _removeERC1155Child(_tokenId, _childContract, _childTokenId, _value);
        IERC1155(_childContract).safeTransferFrom(
            address(this),
            _to,
            _childTokenId,
            _value,
            ""
        );
    }

    function bulkTransferERC1155Child(
        uint256 _tokenId,
        address _to,
        address[] calldata _childContracts,
        uint256[] calldata _childTokenIds,
        uint256[] calldata _values
    ) public {
        require(
            _childContracts.length == _values.length,
            "Contracts length doesn't match"
        );
        require(
            _values.length == _childTokenIds.length,
            "Values length doesn't match"
        );
        require(_childContracts.length > 0, "Missing contracts/ids/values");
        unchecked {
            for (uint i = 0; i < _childTokenIds.length; i++) {
                transferERC1155Child(
                    _tokenId,
                    _to,
                    _childContracts[i],
                    _childTokenIds[i],
                    _values[i]
                );
            }
        }
    }

    function addERC1155Child(
        uint256 _tokenId,
        address _childContract,
        uint256 _childTokenId,
        uint256 _value
    ) public {
        require(!childrenLocked, "Child addition/removal temporarily locked");
        require(isContractApproved(_childContract), "Token not approved child");
        require(ownerOf(_tokenId) == msg.sender, "Not authorized owner");

        if (!uniqueChild1155TokenIds[_childContract].contains(_childTokenId)) {
            uniqueChild1155TokenIds[_childContract].add(_childTokenId);
        }

        uint256 contractLimit = AltsTokenOperatorFilter(
            altsTokenOperatorFilter
        ).get1155ContractLimit(_childContract, _childTokenId);
        require(
            child1155Balances[_tokenId][_childContract][_childTokenId] +
                _value <=
                contractLimit,
            "Child contract limit reached"
        );

        child1155Balances[_tokenId][_childContract][_childTokenId] += _value;

        erc1155TokenContracts[_tokenId].add(_childContract);

        IERC1155(_childContract).safeTransferFrom(
            msg.sender,
            address(this),
            _childTokenId,
            _value,
            ""
        );
    }

    function bulkAddERC1155Child(
        uint256 _tokenId,
        address[] calldata _childContracts,
        uint256[] calldata _childTokenIds,
        uint256[] calldata _values
    ) public {
        require(
            _childContracts.length == _values.length,
            "Contracts length doesn't match"
        );
        require(
            _values.length == _childTokenIds.length,
            "Values length doesn't match"
        );
        require(_childContracts.length > 0, "Missing contracts/ids/values");
        unchecked {
            for (uint i = 0; i < _childTokenIds.length; i++) {
                addERC1155Child(
                    _tokenId,
                    _childContracts[i],
                    _childTokenIds[i],
                    _values[i]
                );
            }
        }
    }

    function tokenHasChildren(uint256 _tokenId) public view returns (bool) {
        /// @dev Step 1: checking ERC20 tokens
        address[] memory erc20Contracts = new address[](
            erc721TokenContracts[_tokenId].length()
        );
        unchecked {
            for (uint i = 0; i < erc721TokenContracts[_tokenId].length(); i++) {
                erc20Contracts[i] = erc721TokenContracts[_tokenId].at(i);
            }
        }

        unchecked {
            for (uint i = 0; i < erc20Contracts.length; i++) {
                address childContract = erc20Contracts[i];
                uint256 balance = balanceOfERC20Child(_tokenId, childContract);

                if (balance > 0) {
                    return true;
                }
            }
        }

        /// @dev Step 2: checking ERC721 tokens
        address[] memory erc721Contracts = getAllERC721ChildContracts(_tokenId);

        unchecked {
            for (uint i = 0; i < erc721Contracts.length; i++) {
                address childContract = erc721Contracts[i];

                if (child721Tokens[_tokenId][childContract].length() > 0) {
                    return true;
                }
            }
        }

        /// @dev Step 3: checking ERC1155 tokens
        address[] memory erc1155Contracts = getAllERC1155ChildContracts(
            _tokenId
        );

        unchecked {
            for (uint i = 0; i < erc1155Contracts.length; i++) {
                address childContract = erc1155Contracts[i];

                for (
                    uint j = 0;
                    j < uniqueChild1155TokenIds[childContract].length();
                    j++
                ) {
                    uint256 childTokenId = uniqueChild1155TokenIds[
                        childContract
                    ].at(j);
                    uint256 balance = child1155Balances[_tokenId][
                        childContract
                    ][childTokenId];
                    if (balance > 0) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    function getERC20Children(
        uint256 _tokenId
    ) public view returns (address[] memory, uint256[] memory) {
        address[] memory erc20Contracts = AltsTokenOperatorFilter(
            altsTokenOperatorFilter
        ).getTypeChildContracts(0);

        address[] memory erc20ChildrenContracts = new address[](
            erc20Contracts.length
        );
        uint256[] memory erc20ChildrenBalances = new uint256[](
            erc20Contracts.length
        );

        unchecked {
            for (uint i = 0; i < erc20Contracts.length; i++) {
                address childContract = erc20Contracts[i];
                uint256 balance = balanceOfERC20Child(_tokenId, childContract);
                erc20ChildrenContracts[i] = childContract;
                erc20ChildrenBalances[i] = balance;
            }
        }
        return (erc20ChildrenContracts, erc20ChildrenBalances);
    }

    function getAllERC721ChildContracts(
        uint256 _tokenId
    ) public view returns (address[] memory) {
        address[] memory erc721ChildrenContracts = new address[](
            erc721TokenContracts[_tokenId].length()
        );
        unchecked {
            for (uint i = 0; i < erc721TokenContracts[_tokenId].length(); i++) {
                erc721ChildrenContracts[i] = erc721TokenContracts[_tokenId].at(
                    i
                );
            }
        }

        return erc721ChildrenContracts;
    }

    function getERC721Children(
        uint256 _tokenId,
        address _childContract
    ) public view returns (uint256[] memory) {
        uint256[] memory erc721ChildrenTokenIds = new uint256[](
            child721Tokens[_tokenId][_childContract].length()
        );
        unchecked {
            for (
                uint i = 0;
                i < child721Tokens[_tokenId][_childContract].length();
                i++
            ) {
                erc721ChildrenTokenIds[i] = child721Tokens[_tokenId][
                    _childContract
                ].at(i);
            }
        }

        return erc721ChildrenTokenIds;
    }

    function getAllERC1155ChildContracts(
        uint256 _tokenId
    ) public view returns (address[] memory) {
        address[] memory erc1155ChildrenContracts = new address[](
            erc1155TokenContracts[_tokenId].length()
        );
        unchecked {
            for (
                uint i = 0;
                i < erc1155TokenContracts[_tokenId].length();
                i++
            ) {
                erc1155ChildrenContracts[i] = erc1155TokenContracts[_tokenId]
                    .at(i);
            }
        }

        return erc1155ChildrenContracts;
    }

    function getERC1155Children(
        uint256 _tokenId,
        address _childContract
    ) public view returns (uint256[] memory, uint256[] memory) {
        uint256 tokenIdsLength = uniqueChild1155TokenIds[_childContract]
            .length();
        uint256[] memory erc1155ChildrenTokenIds = new uint256[](
            tokenIdsLength
        );
        uint256[] memory erc1155ChildrenTokenBalance = new uint256[](
            tokenIdsLength
        );

        unchecked {
            for (uint i = 0; i < tokenIdsLength; i++) {
                uint256 childTokenId = uniqueChild1155TokenIds[_childContract]
                    .at(i);
                uint256 balance = child1155Balances[_tokenId][_childContract][
                    childTokenId
                ];
                erc1155ChildrenTokenIds[i] = childTokenId;
                erc1155ChildrenTokenBalance[i] = balance;
            }
        }
        return (erc1155ChildrenTokenIds, erc1155ChildrenTokenBalance);
    }

    /**
     * @param __owner address of queried owner
     * @param _startingIndex starting index range value
     * @param _endingIndex ending index range value
     * @return ownedTokenIds list of all tokenIds owned by the wallet
     */
    function walletOfOwner(
        address __owner,
        uint256 _startingIndex,
        uint256 _endingIndex
    ) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(__owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startingIndex;
        uint256 ownedTokenIndex = 0;

        if (ownerTokenCount > 0) {
            unchecked {
                while (
                    ownedTokenIndex < ownerTokenCount &&
                    currentTokenId < _endingIndex
                ) {
                    if (ownerOf(currentTokenId) == __owner) {
                        ownedTokenIds[ownedTokenIndex] = currentTokenId;
                        ownedTokenIndex++;
                    }
                    currentTokenId++;
                }
            }
        }
        return ownedTokenIds;
    }

    /// @dev Vectorized Operator Filter
    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(
        address operator
    ) internal pure override returns (bool) {
        /// @dev OpenSea Seaport Conduit:
        /// https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        /// https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}